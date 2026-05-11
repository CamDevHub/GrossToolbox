local AddonName, GT = ...

local Settings  = GT.Modules.Settings
local infoFrame = Settings.Categories["Information"]

local PAD            = 24
local PLAYER_LIST_W  = 360
local CHAR_LIST_W    = 180
local LIST_H         = 220
local ROW_H    = 26
local BTN_H    = 28
local DATA_H   = 160

-- ============================================================
-- Helpers
-- ============================================================

local function makeLabel(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(label, 13, "")
    label:SetText(text)
    label:SetTextColor(0.8, 0.8, 0.8)
    return label
end

local function makeInputBox(parent, anchorFrame)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(260, 32)
    box:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -8)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlight")
    box:SetTextInsets(10, 10, 0, 0)
    box:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    box:SetBackdropColor(0.06, 0.06, 0.06, 1)
    box:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function makeScrollList(parent, anchorFrame, offsetY, width)
    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetSize(width, LIST_H)
    bg:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
    bg:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    bg:SetBackdropColor(0.06, 0.06, 0.06, 1)
    bg:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

    local scroll = CreateFrame("ScrollFrame", nil, bg, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     bg, "TOPLEFT",     2,   -2)
    scroll:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -20,  2)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(width - 22)
    scroll:SetScrollChild(child)

    return bg, child
end

local function makeActionBtn(parent, label, color)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(160, BTN_H)
    btn:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    local r, g, b = color[1], color[2], color[3]
    btn:SetBackdropColor(r * 0.5, g * 0.5, b * 0.5, 1)
    btn:SetBackdropBorderColor(r, g, b, 0.6)
    btn:SetScript("OnEnter", function(self) self:SetBackdropColor(r * 0.8, g * 0.8, b * 0.8, 1) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropColor(r * 0.5, g * 0.5, b * 0.5, 1) end)

    local txt = btn:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(txt, 12, "")
    txt:SetPoint("CENTER")
    txt:SetText(label)
    txt:SetTextColor(1, 1, 1)

    return btn
end

-- ============================================================
-- Discord handle & ID inputs
-- ============================================================

local discordLabel = makeLabel(infoFrame, "Discord Handle")
discordLabel:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", PAD, -PAD)

local discordInput = makeInputBox(infoFrame, discordLabel)
discordInput:SetMaxLetters(64)
discordInput:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(0, 0.5, 1, 1)
end)

local function saveDiscordHandle(handle)
    GT.DB.discordHandle = handle
    local myID = GT.DB.uniqueID
    if myID then
        GT.DB.players[myID] = GT.DB.players[myID] or {}
        GT.DB.players[myID].discordHandle = handle
    end
end

discordInput:SetScript("OnEditFocusLost", function(self)
    saveDiscordHandle(self:GetText())
    self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end)
discordInput:SetScript("OnEnterPressed", function(self)
    saveDiscordHandle(self:GetText())
    self:ClearFocus()
end)

local idLabel = makeLabel(infoFrame, "Your ID")
idLabel:SetPoint("TOPLEFT", discordInput, "BOTTOMLEFT", 0, -20)

local idInput = makeInputBox(infoFrame, idLabel)
local lockedID = ""
idInput:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(lockedID) end
end)
idInput:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end)

-- ============================================================
-- Player / Character browser section
-- ============================================================

-- Vertical separator between left inputs and right browser
local browserSep = infoFrame:CreateTexture(nil, "ARTWORK")
browserSep:SetPoint("TOPLEFT",    infoFrame, "TOPLEFT",    PAD + 260 + PAD * 0.5, -PAD * 0.5)
browserSep:SetPoint("BOTTOMLEFT", infoFrame, "BOTTOMLEFT", PAD + 260 + PAD * 0.5,  PAD * 0.5)
browserSep:SetWidth(1)
browserSep:SetColorTexture(0.3, 0.3, 0.3, 1)

local BROWSER_X = PAD + 260 + PAD

local playerListLabel = makeLabel(infoFrame, "Players")
playerListLabel:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", BROWSER_X, -PAD)

local charListLabel = makeLabel(infoFrame, "Characters")
charListLabel:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", BROWSER_X + PLAYER_LIST_W + PAD, -PAD)

local playerListBg, playerListChild = makeScrollList(infoFrame, playerListLabel, -4, PLAYER_LIST_W)
local charListBg,   charListChild   = makeScrollList(infoFrame, charListLabel,   -4, CHAR_LIST_W)
charListBg:SetPoint("TOPLEFT", playerListBg, "TOPRIGHT", PAD, 0)

-- ============================================================
-- Action buttons
-- ============================================================

local deletePlayerBtn = makeActionBtn(infoFrame, "Delete Player",    { 0.9, 0.1, 0.1 })
deletePlayerBtn:SetPoint("TOPLEFT", playerListBg, "BOTTOMLEFT", 0, -8)

local deleteCharBtn = makeActionBtn(infoFrame, "Delete Character", { 0.9, 0.3, 0.1 })
deleteCharBtn:SetPoint("TOPLEFT", charListBg, "BOTTOMLEFT", 0, -8)

-- ============================================================
-- Data panel (read-only text area below the lists)
-- ============================================================

local dataBg = CreateFrame("Frame", nil, infoFrame, "BackdropTemplate")
dataBg:SetPoint("TOPLEFT",  deletePlayerBtn, "BOTTOMLEFT",  0, -8)
dataBg:SetPoint("TOPRIGHT", charListBg, "BOTTOMRIGHT", 0,    -8)
dataBg:SetHeight(DATA_H)
dataBg:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
dataBg:SetBackdropColor(0.05, 0.05, 0.05, 1)
dataBg:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

local dataScroll = CreateFrame("ScrollFrame", nil, dataBg, "UIPanelScrollFrameTemplate")
dataScroll:SetPoint("TOPLEFT",     dataBg, "TOPLEFT",     4,   -4)
dataScroll:SetPoint("BOTTOMRIGHT", dataBg, "BOTTOMRIGHT", -20,  4)

local dataTextBox = CreateFrame("EditBox", nil, dataScroll)
dataTextBox:SetMultiLine(true)
dataTextBox:SetAutoFocus(false)
GT.UI:SetFont(dataTextBox, 12, "")
dataTextBox:SetMaxLetters(0)
dataTextBox:SetWidth(PLAYER_LIST_W + PAD + CHAR_LIST_W - 20)

local lockedDataText = ""
dataTextBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(lockedDataText) end
end)
dataTextBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
dataScroll:SetScrollChild(dataTextBox)

-- ============================================================
-- State
-- ============================================================

local selectedUID      = nil
local selectedCharName = nil
local playerRows       = {}
local charRows         = {}

local function setDataText(text)
    lockedDataText = text or ""
    dataTextBox:SetText(lockedDataText)
end

-- ============================================================
-- Highlight helpers
-- ============================================================

local function highlightRow(rows, key)
    for k, row in pairs(rows) do
        if k == key then
            row.bg:SetColorTexture(0, 0.5, 1, 0.25)
            row.bg:Show()
        else
            row.bg:Hide()
        end
    end
end

-- ============================================================
-- showCharData — builds and displays character info in the panel
-- ============================================================

local function showCharData(uid, charName)
    local playerData = uid and GT.DB.players[uid]
    local charData   = playerData and playerData.chars and playerData.chars[charName]
    if not charData then
        setDataText("")
        return
    end

    local lines = {}
    local pdDiscord = playerData.discordHandle or ""
    table.insert(lines, "Player:      " .. (pdDiscord ~= "" and pdDiscord or uid))
    table.insert(lines, "Character:   " .. (charData.name or charName) .. "-" .. (charData.server or "?"))
    table.insert(lines, "Class:       " .. (charData.class or "?"))
    table.insert(lines, "iLvl:        " .. (charData.ilvl or 0))
    table.insert(lines, "Rating:      " .. (charData.mpRating or 0))
    table.insert(lines, "Faction:     " .. (charData.faction or "?"))

    local roles = charData.roles or {}
    local roleList = {}
    if roles.tank then table.insert(roleList, "Tank") end
    if roles.heal then table.insert(roleList, "Heal") end
    if roles.dps  then table.insert(roleList, "DPS")  end
    table.insert(lines, "Roles:       " .. (#roleList > 0 and table.concat(roleList, ", ") or "none"))

    local ks = charData.keystone
    if ks and ks.level and ks.level > 0 then
        local dungeon = GT.Data.DUNGEONS[ks.challengeId]
        table.insert(lines, "Keystone:    +" .. ks.level .. " " .. (dungeon and dungeon.short or "?"))
    else
        table.insert(lines, "Keystone:    none")
    end

    table.insert(lines, "ForceNoKey:  " .. tostring(charData.forceNoKey or false))
    table.insert(lines, "HideFromTag: " .. tostring(charData.hideFromTag or false))

    local vault = charData.vault
    if vault then
        local function slotStr(slots)
            if not slots then return "—" end
            local parts = {}
            for _, s in ipairs(slots) do
                table.insert(parts, math.min(s.progress, s.threshold) .. "/" .. s.threshold)
            end
            return table.concat(parts, "  ")
        end
        table.insert(lines, "Vault M+:    " .. slotStr(vault.dungeons))
        table.insert(lines, "Vault Raid:  " .. slotStr(vault.raid))
    end

    if charData.lastSeen then
        table.insert(lines, "Last Seen:   " .. date("%Y-%m-%d %H:%M", charData.lastSeen))
    end

    setDataText(table.concat(lines, "\n"))
end

-- ============================================================
-- Character list
-- ============================================================

local function buildCharRow(charName, charData, idx)
    if not charRows[charName] then
        local btn = CreateFrame("Button", nil, charListChild)
        btn:SetSize(CHAR_LIST_W - 22, ROW_H)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0.5, 1, 0.25)
        bg:Hide()

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        GT.UI:SetFont(lbl, 12, "")
        lbl:SetPoint("LEFT", btn, "LEFT", 6, 0)
        lbl:SetWidth(CHAR_LIST_W - 34)
        lbl:SetJustifyH("LEFT")
        lbl:SetTextColor(1, 1, 1)

        charRows[charName] = { btn = btn, bg = bg, lbl = lbl }
    end

    local row = charRows[charName]
    row.btn:ClearAllPoints()
    row.btn:SetPoint("TOPLEFT", charListChild, "TOPLEFT", 0, -(idx - 1) * ROW_H)
    row.btn:Show()

    local displayName = (charData.name or charName) .. "-" .. (charData.server or "?")
    local classColor  = charData.class and RAID_CLASS_COLORS[charData.class:upper()]
    if classColor then
        row.lbl:SetTextColor(classColor.r, classColor.g, classColor.b)
    else
        row.lbl:SetTextColor(1, 1, 1)
    end
    row.lbl:SetText(displayName)

    row.btn:SetScript("OnClick", function()
        selectedCharName = charName
        highlightRow(charRows, charName)
        showCharData(selectedUID, charName)
    end)
end

local function RefreshCharList()
    for _, row in pairs(charRows) do row.btn:Hide() end

    local playerData = selectedUID and GT.DB.players[selectedUID]
    if not playerData then
        charListChild:SetHeight(ROW_H)
        return
    end

    local chars = playerData.chars or {}
    local sorted = {}
    for name in pairs(chars) do table.insert(sorted, name) end
    table.sort(sorted)

    charListChild:SetHeight(math.max(#sorted * ROW_H, ROW_H))

    for i, charName in ipairs(sorted) do
        buildCharRow(charName, chars[charName], i)
    end

    if selectedCharName and not chars[selectedCharName] then
        selectedCharName = nil
    end
    if selectedCharName then
        highlightRow(charRows, selectedCharName)
    end
end

-- ============================================================
-- Player list
-- ============================================================

local function buildPlayerRow(uid, playerData, idx)
    if not playerRows[uid] then
        local btn = CreateFrame("Button", nil, playerListChild)
        btn:SetSize(PLAYER_LIST_W - 22, ROW_H)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0.5, 1, 0.25)
        bg:Hide()

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        GT.UI:SetFont(lbl, 12, "")
        lbl:SetPoint("LEFT", btn, "LEFT", 6, 0)
        lbl:SetWidth(180)
        lbl:SetJustifyH("LEFT")
        lbl:SetTextColor(1, 1, 1)

        local charLbl = btn:CreateFontString(nil, "OVERLAY")
        GT.UI:SetFont(charLbl, 11, "")
        charLbl:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        charLbl:SetWidth(150)
        charLbl:SetJustifyH("RIGHT")
        charLbl:SetTextColor(0.6, 0.6, 0.6)

        playerRows[uid] = { btn = btn, bg = bg, lbl = lbl, charLbl = charLbl }
    end

    local row = playerRows[uid]
    row.btn:ClearAllPoints()
    row.btn:SetPoint("TOPLEFT", playerListChild, "TOPLEFT", 0, -(idx - 1) * ROW_H)
    row.btn:Show()

    local discord = playerData.discordHandle or ""
    row.lbl:SetText(discord ~= "" and discord or uid)

    if uid == GT.DB.uniqueID then
        row.lbl:SetTextColor(0.4, 0.8, 1)
    else
        row.lbl:SetTextColor(1, 1, 1)
    end

    local chars = playerData.chars or {}
    local firstName = nil
    for charName in pairs(chars) do
        if not firstName or charName < firstName then firstName = charName end
    end
    local firstData = firstName and chars[firstName]
    if firstData then
        local display    = (firstData.name or firstName) .. "-" .. (firstData.server or "?")
        local classColor = firstData.class and RAID_CLASS_COLORS[firstData.class:upper()]
        row.charLbl:SetText(display)
        if classColor then
            row.charLbl:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            row.charLbl:SetTextColor(0.6, 0.6, 0.6)
        end
    else
        row.charLbl:SetText("")
    end

    row.btn:SetScript("OnClick", function()
        if selectedUID == uid then return end
        selectedUID      = uid
        selectedCharName = nil
        highlightRow(playerRows, uid)
        setDataText("")
        RefreshCharList()
    end)
end

local function RefreshPlayerList()
    for _, row in pairs(playerRows) do row.btn:Hide() end

    local players = GT.DB.players or {}
    local sorted  = {}
    for uid in pairs(players) do table.insert(sorted, uid) end
    -- Local player first, then alphabetical by discord/uid
    table.sort(sorted, function(a, b)
        if a == GT.DB.uniqueID then return true end
        if b == GT.DB.uniqueID then return false end
        local da = players[a].discordHandle or a
        local db = players[b].discordHandle or b
        return da < db
    end)

    playerListChild:SetHeight(math.max(#sorted * ROW_H, ROW_H))

    for i, uid in ipairs(sorted) do
        buildPlayerRow(uid, players[uid], i)
    end

    if selectedUID and not players[selectedUID] then
        selectedUID      = nil
        selectedCharName = nil
        for _, row in pairs(charRows) do row.btn:Hide() end
        charListChild:SetHeight(ROW_H)
        setDataText("")
    end
    if selectedUID then
        highlightRow(playerRows, selectedUID)
    end
end

-- ============================================================
-- Button handlers
-- ============================================================

deleteCharBtn:SetScript("OnClick", function()
    if not selectedUID or not selectedCharName then return end
    local playerData = GT.DB.players[selectedUID]
    if not playerData or not playerData.chars then return end
    playerData.chars[selectedCharName] = nil
    -- prune from charOrder
    local order = playerData.charOrder or {}
    for i = #order, 1, -1 do
        if order[i] == selectedCharName then table.remove(order, i) end
    end
    selectedCharName = nil
    setDataText("")
    RefreshCharList()
    RefreshPlayerList()
end)

deletePlayerBtn:SetScript("OnClick", function()
    if not selectedUID then return end
    GT.DB.players[selectedUID] = nil
    selectedUID      = nil
    selectedCharName = nil
    setDataText("")
    for _, row in pairs(charRows) do row.btn:Hide() end
    charListChild:SetHeight(ROW_H)
    RefreshPlayerList()
end)

-- ============================================================
-- Show / login hooks
-- ============================================================

infoFrame:SetScript("OnShow", function()
    RefreshPlayerList()
    RefreshCharList()
end)

infoFrame:SetScript("OnHide", function()
    selectedUID      = nil
    selectedCharName = nil
    for _, row in pairs(playerRows) do row.bg:Hide() end
    for _, row in pairs(charRows)   do row.bg:Hide() end
    setDataText("")
end)

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
    GT.Core:DebugPrint("Information: PLAYER_LOGIN, discord =", GT.DB.discordHandle or "<not set>")
    if GT.DB.discordHandle then
        discordInput:SetText(GT.DB.discordHandle)
    end
    lockedID = GT.DB.uniqueID or ""
    idInput:SetText(lockedID)
end)
