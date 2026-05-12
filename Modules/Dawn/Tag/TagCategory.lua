local AddonName, GT = ...

local Dawn     = GT.Modules.Dawn
local tagFrame = Dawn.Categories["Tag"]

local cfg       = GT.Config
local CONTENT_W = cfg.MAIN_FRAME_WIDTH - cfg.SIDEBAR_WIDTH
local CONTENT_H = cfg.MAIN_FRAME_HEIGHT - cfg.TAB_BAR_HEIGHT - cfg.FOOTER_HEIGHT - 1
local PAD       = 8

local DUNGEONS      = GT.Data.DUNGEONS
local DUNGEON_ORDER = GT.Data.DUNGEON_ORDER

-- ============================================================
-- Dungeon icon column (right side)
-- ============================================================

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

do
    local count    = #DUNGEON_ORDER
    local iconSize = math.floor(CONTENT_H / count)
    spellBar:SetWidth(iconSize)

    for i, challengeId in ipairs(DUNGEON_ORDER) do
        barChallengeIds[i] = challengeId
        local dungeon = DUNGEONS[challengeId]

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
        icon:SetSize(iconSize - 2, iconSize - 2)
        icon:SetPoint("CENTER", cell, "CENTER")
        icon:SetTexture(dungeon and dungeon.iconId or "Interface\\Icons\\INV_Misc_QuestionMark")

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
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cell:SetScript("OnEnter", function(self)
            local players = GT.DB.players or {}
            local holders = {}
            for uid in pairs(Dawn.cachedPartyUIDs) do
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
    end
end

-- ============================================================
-- Controls bar (bottom of the left area)
-- ============================================================

local controlsBar = CreateFrame("Frame", nil, tagFrame)
controlsBar:SetHeight(40)
controlsBar:SetPoint("BOTTOMLEFT",  tagFrame, "BOTTOMLEFT",  0, 0)
controlsBar:SetPoint("BOTTOMRIGHT", spellBar, "BOTTOMLEFT",  0, 0)

local syncBtn = GT.UI:CreateActionButton(controlsBar, "Sync", 90, 28, 13, { 0.3, 0.3, 0.3 })
syncBtn:SetPoint("LEFT", controlsBar, "LEFT", PAD, 0)

-- Expose for Sync.lua
Dawn.syncBtn   = syncBtn
Dawn.syncLabel = syncBtn.text

local teamTakeCB = CreateFrame("CheckButton", nil, controlsBar, "UICheckButtonTemplate")
teamTakeCB:SetSize(24, 24)
teamTakeCB:SetPoint("LEFT", syncBtn, "RIGHT", PAD * 2, 0)

local teamTakeLabel = controlsBar:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(teamTakeLabel, 13, "")
teamTakeLabel:SetPoint("LEFT", teamTakeCB, "RIGHT", 4, 0)
teamTakeLabel:SetText("Team Take")
teamTakeLabel:SetTextColor(0.8, 0.8, 0.8)

-- ============================================================
-- Read-only tag text area
-- ============================================================

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

local lockedText         = ""
local cachedTagText      = ""
local cachedTeamTakeText = ""
local cacheBuilt         = false

textBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(lockedText) end
end)
textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

scrollFrame:SetScrollChild(textBox)

-- ============================================================
-- Key overlays (updated alongside the cache)
-- ============================================================

local function RefreshKeyOverlays()
    GT.Core:DebugPrint("TagCategory: RefreshKeyOverlays()")
    local players     = GT.DB.players or {}
    local dungeonKeys = {}

    local function addKey(charData)
        local ks = charData.keystone
        if ks and ks.level > 0 and ks.challengeId and ks.challengeId ~= 0 then
            dungeonKeys[ks.challengeId] = dungeonKeys[ks.challengeId] or {}
            table.insert(dungeonKeys[ks.challengeId], ks.level)
        end
    end

    for uid in pairs(Dawn.cachedPartyUIDs) do
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
            if levels then table.sort(levels) end  -- ascending: lowest at bottom
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

-- ============================================================
-- Cache lifecycle
-- ============================================================

-- Forward declarations: both are called by rosterFrame before their definitions.
local RebuildCache
local ApplyTagText

RebuildCache = function()
    cachedTagText      = Dawn.BuildTagText()
    cachedTeamTakeText = Dawn.BuildTeamTakeText()
    RefreshKeyOverlays()
    cacheBuilt = true
end

ApplyTagText = function()
    if teamTakeCB:GetChecked() then
        Dawn:SetTagText(cachedTeamTakeText)
    else
        Dawn:SetTagText(cachedTagText)
    end
end

local function RefreshTagText()
    Dawn.RefreshPartyCache()
    RebuildCache()
    ApplyTagText()
end

-- ============================================================
-- Event wiring
-- ============================================================

local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:SetScript("OnEvent", function()
    GT.Core:DebugPrint("TagCategory: GROUP_ROSTER_UPDATE fired")
    Dawn.RefreshPartyCache()
    RebuildCache()
    ApplyTagText()
end)

-- Checkbox only swaps which cached text is shown — no rebuild
teamTakeCB:SetScript("OnClick", function() ApplyTagText() end)

-- ============================================================
-- Public API
-- ============================================================

-- Expose for Sync.lua
Dawn.RefreshTagText = RefreshTagText
-- InvalidateTagCache: marks cache stale so the next OnShow triggers a full rebuild
Dawn.InvalidateTagCache = function() cacheBuilt = false end

function Dawn:SetTagText(text)
    lockedText = text or ""
    textBox:SetText(lockedText)
    if textBox:HasFocus() then
        textBox:HighlightText()
    end
end

tagFrame:SetScript("OnShow", function()
    GT.Core:DebugPrint("TagCategory: OnShow()")
    if not cacheBuilt then
        RefreshTagText()
    else
        ApplyTagText()
    end
    textBox:SetFocus()
    textBox:HighlightText()
end)
