local AddonName, GT = ...

local Dawn    = GT.Modules.Dawn
local tagFrame = Dawn.Categories["Tag"]

local cfg       = GT.Config
local CONTENT_W = cfg.MAIN_FRAME_WIDTH - cfg.SIDEBAR_WIDTH
local CONTENT_H = cfg.MAIN_FRAME_HEIGHT - cfg.TAB_BAR_HEIGHT - cfg.FOOTER_HEIGHT - 1
local PAD       = 8

local DUNGEONS = GT.Data.DUNGEONS

local function getSpellInfo(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info then return info.name, info.iconID end
    end
end

-- Dungeon icon column (right side, width set at PLAYER_LOGIN)
local spellBar = CreateFrame("Frame", nil, tagFrame, "BackdropTemplate")
spellBar:SetPoint("TOPRIGHT",    tagFrame, "TOPRIGHT")
spellBar:SetPoint("BOTTOMRIGHT", tagFrame, "BOTTOMRIGHT")
spellBar:SetBackdrop({ bgFile = GT.Config.WHITE8X8 })
spellBar:SetBackdropColor(unpack(GT.Config.COLOR_BG_CONTENT))

local spellIcons      = {}
local cellKeyLabels   = {}
local barChallengeIds = {}
local MAX_KEY_LABELS  = 3
local KL_H            = 20  -- px per key-level row

-- Controls bar (bottom of the left area)
local controlsBar = CreateFrame("Frame", nil, tagFrame)
controlsBar:SetHeight(40)
controlsBar:SetPoint("BOTTOMLEFT",  tagFrame, "BOTTOMLEFT",  0, 0)
controlsBar:SetPoint("BOTTOMRIGHT", spellBar, "BOTTOMLEFT",  0, 0)

local syncBtn = CreateFrame("Button", nil, controlsBar, "BackdropTemplate")
syncBtn:SetSize(90, 28)
syncBtn:SetPoint("LEFT", controlsBar, "LEFT", PAD, 0)
syncBtn:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
syncBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
syncBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
syncBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.22, 0.22, 0.22, 1) end)
syncBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.12, 0.12, 0.12, 1) end)

local syncLabel = syncBtn:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(syncLabel, 13, "")
syncLabel:SetPoint("CENTER")
syncLabel:SetText("Sync")
syncLabel:SetTextColor(1, 1, 1)

-- Expose for Sync.lua
Dawn.syncBtn   = syncBtn
Dawn.syncLabel = syncLabel

local teamTakeCB = CreateFrame("CheckButton", nil, controlsBar, "UICheckButtonTemplate")
teamTakeCB:SetSize(24, 24)
teamTakeCB:SetPoint("LEFT", syncBtn, "RIGHT", PAD * 2, 0)

local teamTakeLabel = controlsBar:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(teamTakeLabel, 13, "")
teamTakeLabel:SetPoint("LEFT", teamTakeCB, "RIGHT", 4, 0)
teamTakeLabel:SetText("Team Take")
teamTakeLabel:SetTextColor(0.8, 0.8, 0.8)

-- Read-only text area (top portion)
local scrollFrame = CreateFrame("ScrollFrame", nil, tagFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",     tagFrame,    "TOPLEFT",   PAD, -PAD)
scrollFrame:SetPoint("BOTTOMRIGHT", controlsBar, "TOPRIGHT", -PAD,  PAD)
scrollFrame.ScrollBar:Hide()

local textBox = CreateFrame("EditBox", nil, scrollFrame)
textBox:SetMultiLine(true)
textBox:SetAutoFocus(false)
GT.UI:SetFont(textBox, 16, "")
textBox:SetMaxLetters(0)
textBox:SetWidth(CONTENT_W - PAD * 2)

local lockedText = ""
textBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(lockedText) end
end)
textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

scrollFrame:SetScrollChild(textBox)

-- ============================================================
-- Tag text builder
-- ============================================================

local CLASS_NAMES = GT.Data.CLASS_NAMES

local ARMOR_ORDER = { "Cloth", "Leather", "Mail", "Plate" }

local CLASS_TO_ARMOR = {
    MAGE        = "Cloth",
    PRIEST      = "Cloth",
    WARLOCK     = "Cloth",
    DRUID       = "Leather",
    DEMONHUNTER = "Leather",
    MONK        = "Leather",
    ROGUE       = "Leather",
    EVOKER      = "Mail",
    HUNTER      = "Mail",
    SHAMAN      = "Mail",
    DEATHKNIGHT = "Plate",
    PALADIN     = "Plate",
    WARRIOR     = "Plate",
}

local function keystoneLabel(ks)
    if not ks or ks.level == 0 then return "no key" end
    local dungeon = DUNGEONS[ks.challengeId]
    return string.format("+%d %s", ks.level, dungeon and dungeon.short or "?")
end

-- ============================================================
-- Party cache
-- Rebuilt on GROUP_ROSTER_UPDATE (and once on PLAYER_LOGIN).
-- cachedGroupNames : charName(lower) -> true   (WoW API, fast to query)
-- cachedPartyUIDs  : uid -> true               (DB lookup, cached here)
-- ============================================================

local cachedGroupNames = {}
local cachedPartyUIDs  = {}

local function RefreshPartyCache()
    GT.Core:DebugPrint("TagCategory: RefreshPartyCache fired")
    local names  = {}
    names[UnitName("player"):lower()] = true
    if IsInGroup() and not IsInRaid() then
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party" .. i)
            if name then names[name:lower()] = true end
        end
    end
    cachedGroupNames = names

    local players = GT.DB.players or {}
    local myID    = GT.DB.uniqueID
    local uids    = { [myID] = true }
    for uid, data in pairs(players) do
        if uid ~= myID then
            for charName in pairs(data.chars or {}) do
                if cachedGroupNames[charName] then
                    uids[uid] = true
                    break
                end
            end
        end
    end
    cachedPartyUIDs = uids
end

local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:SetScript("OnEvent", RefreshPartyCache)

local function BuildTagText()
    local players       = GT.DB.players or {}
    local myID          = GT.DB.uniqueID
    local lines         = {}
    local rendered      = {}
    local renderedCount = 0

    local function renderPlayer(uid)
        if rendered[uid] then return end
        rendered[uid] = true
        renderedCount = renderedCount + 1

        local data = players[uid]
        if not data then return end

        if uid ~= myID then
            local discord = data.discordHandle or ""
            table.insert(lines, "<@" .. (discord ~= "" and discord .. ">" or "unknown"))
        end

        local sortedChars = {}
        for _, charData in pairs(data.chars or {}) do
            if not charData.hideFromTag then
                table.insert(sortedChars, charData)
            end
        end
        table.sort(sortedChars, function(a, b)
            return (a.mpRating or 0) > (b.mpRating or 0)
        end)

        for _, charData in ipairs(sortedChars) do
            local roleNames = {}
            local roles = charData.roles or {}
            local ROLES = GT.Data.ROLES
            if roles.tank then table.insert(roleNames, ROLES.TANK)    end
            if roles.heal then table.insert(roleNames, ROLES.HEALER)  end
            if roles.dps  then table.insert(roleNames, ROLES.DAMAGER) end
            local rolesStr  = #roleNames > 0 and table.concat(roleNames, " ") or "?"
            local className = CLASS_NAMES[charData.class] or charData.class or "?"
            local ks        = (not charData.forceNoKey) and charData.keystone or nil
            table.insert(lines, string.format(
                "%s %s | :%s: | :Raiderio: %d | :Keystone: %s | :Armor: %d iLvl",
                rolesStr,
                className,
                charData.faction  or "?",
                charData.mpRating or 0,
                keystoneLabel(ks),
                charData.ilvl     or 0
            ))
        end
        table.insert(lines, "")
    end

    local inGroup = IsInGroup()
    -- Local player always at top
    renderPlayer(myID)

    -- All other party players — all their characters, not just the one in group
    for uid in pairs(cachedPartyUIDs) do
        if uid ~= myID then
            renderPlayer(uid)
        end
    end

    local sign = GT.Data.NUMBER_SIGN[renderedCount]
    if sign then table.insert(lines, 1,"### " ..  sign .. " Sign") end

    return table.concat(lines, "\n")
end

local function BuildTeamTakeText()
    local players = GT.DB.players or {}
    local myID    = GT.DB.uniqueID
    local used    = {}

    -- Discord mentions line for all party members (excluding self)
    local mentions = {}
    for uid in pairs(cachedPartyUIDs) do
        if uid ~= myID then
            local data = players[uid]
            local handle = data and data.discordHandle or ""
            if handle ~= "" then
                table.insert(mentions, "<@" .. handle .. ">")
            end
        end
    end

    -- Collect eligible characters grouped by armor type
    local byArmor = {}
    for _, armor in ipairs(ARMOR_ORDER) do byArmor[armor] = {} end

    for uid in pairs(cachedPartyUIDs) do
        local data = players[uid]
        if data then
            for charName, charData in pairs(data.chars or {}) do
                if not charData.hideFromTag then
                    local armor = CLASS_TO_ARMOR[(charData.class or ""):upper()]
                    if armor then
                        table.insert(byArmor[armor], { charName = charName, charData = charData })
                    end
                end
            end
        end
    end

    -- Pick the best candidate for a role from a pool.
    -- Prefers characters with fewer total roles to preserve flexibility for others.
    local function pickRole(pool, role)
        local best, bestScore = nil, math.huge
        for _, entry in ipairs(pool) do
            if not used[entry.charName] then
                local roles = entry.charData.roles or {}
                if roles[role] then
                    local n = (roles.tank and 1 or 0) + (roles.heal and 1 or 0) + (roles.dps and 1 or 0)
                    if n < bestScore then best, bestScore = entry, n end
                end
            end
        end
        return best
    end

    local function formatChar(entry, roleSymbol)
        local cd        = entry.charData
        local className = CLASS_NAMES[cd.class] or cd.class or "?"
        local ks        = (not cd.forceNoKey) and cd.keystone or nil
        return string.format(
            "%s %s | :%s: | :Raiderio: %d | :Keystone: %s | :Armor: %d iLvl",
            roleSymbol,
            className,
            cd.faction  or "?",
            cd.mpRating or 0,
            keystoneLabel(ks),
            cd.ilvl     or 0
        )
    end

    local ROLES = GT.Data.ROLES
    local lines = {}

    for _, armor in ipairs(ARMOR_ORDER) do
        local pool = byArmor[armor]

        local tank = pickRole(pool, "tank")
        if tank then used[tank.charName] = true end

        local heal = pickRole(pool, "heal")
        if heal then used[heal.charName] = true end

        local dps1 = pickRole(pool, "dps")
        if dps1 then used[dps1.charName] = true end

        local dps2 = pickRole(pool, "dps")
        if dps2 then used[dps2.charName] = true end

        if tank or heal or dps1 then
            if #lines > 0 then table.insert(lines, "") end
            table.insert(lines, "### Team take")
            if #mentions > 0 then
                table.insert(lines, table.concat(mentions, " "))
            end
            table.insert(lines, "== " .. armor .. " ==")
            if tank then table.insert(lines, formatChar(tank, ROLES.TANK))    end
            if heal then table.insert(lines, formatChar(heal, ROLES.HEALER))  end
            if dps1 then table.insert(lines, formatChar(dps1, ROLES.DAMAGER)) end
            if dps2 then table.insert(lines, formatChar(dps2, ROLES.DAMAGER)) end
        end
    end

    return #lines > 0 and table.concat(lines, "\n") or "Not enough players to form parties."
end

local function RefreshKeyOverlays()
    local players     = GT.DB.players or {}
    local dungeonKeys = {}

    local function addKey(charData)
        local ks = charData.keystone
        if ks and ks.level > 0 and ks.challengeId and ks.challengeId ~= 0 then
            dungeonKeys[ks.challengeId] = dungeonKeys[ks.challengeId] or {}
            table.insert(dungeonKeys[ks.challengeId], ks.level)
        end
    end

    -- All characters of every player in the party (same pool as tag text)
    for uid in pairs(cachedPartyUIDs) do
        local data = players[uid]
        if data then
            for _, charData in pairs(data.chars or {}) do
                if not charData.forceNoKey then addKey(charData) end
            end
        end
    end

    for i, challengeId in ipairs(barChallengeIds) do
        local levels = dungeonKeys[challengeId]
        spellIcons[i]:SetDesaturated(not (levels and #levels > 0))

        local labels = cellKeyLabels[i]
        if labels then
            if levels then
                table.sort(levels)  -- ascending: lowest at bottom, highest at top
            end
            for k = 1, MAX_KEY_LABELS do
                local kl = labels[k]
                if levels and levels[k] then
                    kl:SetText("+" .. levels[k])
                    kl:Show()
                else
                    kl:Hide()
                end
            end
        end
    end
end

local function RefreshTagText()
    if teamTakeCB:GetChecked() then
        Dawn:SetTagText(BuildTeamTakeText())
    else
        Dawn:SetTagText(BuildTagText())
    end
    RefreshKeyOverlays()
end

teamTakeCB:SetScript("OnClick", function() RefreshTagText() end)

-- Expose for Sync.lua
Dawn.RefreshTagText    = RefreshTagText
Dawn.RefreshPartyCache = RefreshPartyCache

function Dawn:SetTagText(text)
    lockedText = text or ""
    textBox:SetText(lockedText)
    if textBox:HasFocus() then
        textBox:HighlightText()
    end
end

tagFrame:SetScript("OnShow", function()
    RefreshTagText()
    textBox:SetFocus()
    textBox:HighlightText()
end)

-- Build icon bar once APIs are ready
local barFrame = CreateFrame("Frame")
barFrame:RegisterEvent("PLAYER_LOGIN")
barFrame:SetScript("OnEvent", function()
    GT.Core:DebugPrint("TagCategory: PLAYER_LOGIN, building dungeon icon bar")
    RefreshPartyCache()
    local maps  = C_ChallengeMode.GetMapTable() or {}
    local count = #maps
    if count > 0 then
        local iconSize = math.floor(CONTENT_H / count)
        spellBar:SetWidth(iconSize)
        for i, challengeId in ipairs(maps) do
            barChallengeIds[i] = challengeId
            local cell = CreateFrame("Frame", nil, spellBar, "BackdropTemplate")
            cell:SetPoint("TOPLEFT", spellBar, "TOPLEFT", 0, -(i - 1) * iconSize)
            cell:SetSize(iconSize, iconSize)
            cell:SetBackdrop({
                bgFile   = GT.Config.WHITE8X8,
                edgeFile = GT.Config.WHITE8X8,
                edgeSize = 1,
            })
            cell:SetBackdropColor(0, 0, 0, 1)
            cell:SetBackdropBorderColor(0.22, 0.22, 0.22, 1)

            local icon = cell:CreateTexture(nil, "ARTWORK")
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            icon:SetSize(iconSize - 2, iconSize - 2)
            icon:SetPoint("CENTER", cell, "CENTER")

            local dungeon = DUNGEONS[challengeId]
            if dungeon and dungeon.spellId then
                local _, iconId = getSpellInfo(dungeon.spellId)
                if iconId then icon:SetTexture(iconId) end
            end

            local label = cell:CreateFontString(nil, "OVERLAY")
            GT.UI:SetFont(label, 20, "OUTLINE")
            label:SetPoint("TOPLEFT", cell, "TOPLEFT", 4, -4)
            label:SetText(dungeon and dungeon.short or "?")
            label:SetTextColor(1, 1, 1)

            cellKeyLabels[i] = {}
            for k = 1, MAX_KEY_LABELS do
                local kl = cell:CreateFontString(nil, "OVERLAY")
                GT.UI:SetFont(kl, 16, "OUTLINE")
                kl:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -4, 4 + (k - 1) * KL_H)
                kl:SetTextColor(1, 0.85, 0.2)
                kl:Hide()
                cellKeyLabels[i][k] = kl
            end

            spellIcons[i] = icon

            cell:EnableMouse(true)
            cell:SetScript("OnEnter", function(self)
                local players = GT.DB.players or {}
                local holders = {}
                for uid in pairs(cachedPartyUIDs) do
                    local data = players[uid]
                    if data then
                        for _, charData in pairs(data.chars or {}) do
                            if not charData.forceNoKey then
                                local ks = charData.keystone
                                if ks and ks.challengeId == challengeId and ks.level and ks.level > 0 then
                                    table.insert(holders, {
                                        name  = (charData.name or "?") .. "-" .. (charData.server or "?"),
                                        level = ks.level,
                                        class = charData.class,
                                    })
                                end
                            end
                        end
                    end
                end
                table.sort(holders, function(a, b) return a.level > b.level end)

                local dungeon = DUNGEONS[challengeId]
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(dungeon and dungeon.name or "?", 1, 1, 1)
                if #holders == 0 then
                    GameTooltip:AddLine("No keys in party", 0.5, 0.5, 0.5)
                else
                    for _, h in ipairs(holders) do
                        local r, g, b = 1, 1, 1
                        if h.class then
                            local cc = RAID_CLASS_COLORS[h.class:upper()]
                            if cc then r, g, b = cc.r, cc.g, cc.b end
                        end
                        GameTooltip:AddDoubleLine(h.name, "+" .. h.level, r, g, b, 1, 0.85, 0.2)
                    end
                end
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
    C_Timer.After(2, RefreshTagText)
end)
