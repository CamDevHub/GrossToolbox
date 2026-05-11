local AddonName, GT = ...

local Weekly     = GT.Modules.Weekly
local vaultFrame = Weekly.Categories["Vault"]

local PE_PAD    = 24
local ROW_H     = 36
local COL_ARROW = 40   -- space reserved for ▲▼ buttons
local COL_CHAR  = 220
local COL_SLOT  = 88

local SLOT_COLS = {
    { label = "×1", type = "dungeons", idx = 1 },
    { label = "×4", type = "dungeons", idx = 2 },
    { label = "×8", type = "dungeons", idx = 3 },
    { label = "×2", type = "raid",     idx = 1 },
    { label = "×4", type = "raid",     idx = 2 },
    { label = "×6", type = "raid",     idx = 3 },
}

-- [1] = char name, [2..7] = slot cols  (all offset past the arrow column)
local COL_X = { PE_PAD + COL_ARROW }
for i = 1, #SLOT_COLS do
    COL_X[i + 1] = PE_PAD + COL_ARROW + COL_CHAR + (i - 1) * COL_SLOT
end

local GROUP_HEADER_Y = -PE_PAD
local SLOT_HEADER_Y  = GROUP_HEADER_Y - 20
local SEP_Y          = SLOT_HEADER_Y  - 18
local FIRST_ROW_Y    = SEP_Y         - 10

-- Static headers
local charGroupLbl = vaultFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(charGroupLbl, 13, "")
charGroupLbl:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[1], GROUP_HEADER_Y)
charGroupLbl:SetWidth(COL_CHAR)
charGroupLbl:SetJustifyH("LEFT")
charGroupLbl:SetText("Character")
charGroupLbl:SetTextColor(0.6, 0.6, 0.6)

local dungeonGroupLbl = vaultFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(dungeonGroupLbl, 13, "")
dungeonGroupLbl:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[2], GROUP_HEADER_Y)
dungeonGroupLbl:SetWidth(COL_SLOT * 3)
dungeonGroupLbl:SetJustifyH("CENTER")
dungeonGroupLbl:SetText("Dungeons")
dungeonGroupLbl:SetTextColor(0.4, 0.7, 1)

local raidGroupLbl = vaultFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(raidGroupLbl, 13, "")
raidGroupLbl:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[5], GROUP_HEADER_Y)
raidGroupLbl:SetWidth(COL_SLOT * 3)
raidGroupLbl:SetJustifyH("CENTER")
raidGroupLbl:SetText("Raid")
raidGroupLbl:SetTextColor(1, 0.6, 0.2)

for i, col in ipairs(SLOT_COLS) do
    local lbl = vaultFrame:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(lbl, 12, "")
    lbl:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[i + 1], SLOT_HEADER_Y)
    lbl:SetWidth(COL_SLOT)
    lbl:SetJustifyH("CENTER")
    lbl:SetText(col.label)
    lbl:SetTextColor(0.5, 0.5, 0.5)
end

local sep = vaultFrame:CreateTexture(nil, "ARTWORK")
sep:SetPoint("TOPLEFT",  vaultFrame, "TOPLEFT",   PE_PAD, SEP_Y)
sep:SetPoint("TOPRIGHT", vaultFrame, "TOPRIGHT", -PE_PAD, SEP_Y)
sep:SetHeight(1)
sep:SetColorTexture(0.3, 0.3, 0.3, 1)

-- ============================================================
-- Order helpers
-- ============================================================

local function GetCharOrder(playerData)
    playerData.charOrder = playerData.charOrder or {}
    local order = playerData.charOrder
    local chars  = playerData.chars or {}

    -- Drop entries for deleted characters
    for i = #order, 1, -1 do
        if not chars[order[i]] then table.remove(order, i) end
    end

    -- Index existing entries for O(1) lookup
    local inOrder = {}
    for _, name in ipairs(order) do inOrder[name] = true end

    -- Append new characters at the end
    for charName in pairs(chars) do
        if not inOrder[charName] then
            table.insert(order, charName)
        end
    end

    return order
end

-- ============================================================
-- Data helpers
-- ============================================================

local function getSlotText(vault, colType, idx)
    if not vault then return "—" end
    local slots = vault[colType]
    if not slots or not slots[idx] then return "—" end
    local s = slots[idx]
    return string.format("%d / %d", math.min(s.progress, s.threshold), s.threshold)
end

local function getSlotColor(vault, colType, idx)
    if not vault then return 0.4, 0.4, 0.4 end
    local slots = vault[colType]
    if not slots or not slots[idx] then return 0.4, 0.4, 0.4 end
    local s = slots[idx]
    if s.progress >= s.threshold then return 0.2, 0.85, 0.2 end
    if s.progress > 0            then return 1.0,  0.8,  0.0 end
    return 0.45, 0.45, 0.45
end

-- ============================================================
-- Arrow button factory
-- ============================================================

local function CreateArrowButton(direction)
    local btn = CreateFrame("Button", nil, vaultFrame)
    btn:SetSize(18, 16)

    local normal = "Interface\\Buttons\\Arrow-" .. direction .. "-Up"
    local pushed = "Interface\\Buttons\\Arrow-" .. direction .. "-Down"
    btn:SetNormalTexture(normal)
    btn:SetPushedTexture(pushed)
    btn:SetHighlightTexture(normal)

    return btn
end

-- ============================================================
-- Row pool
-- ============================================================

local rowPool  = {}
local RefreshVault  -- forward declaration

local function makeSwapHandler(delta)
    return function(self)
        local myID = GT.DB.uniqueID
        local pd   = myID and GT.DB.players[myID]
        if not pd then return end
        local order = pd.charOrder or {}
        for i, name in ipairs(order) do
            if name == self._charName then
                local j = i + delta
                if j >= 1 and j <= #order then
                    order[i], order[j] = order[j], order[i]
                end
                break
            end
        end
        RefreshVault()
    end
end

RefreshVault = function()
    for _, row in ipairs(rowPool) do
        row.charLabel:Hide()
        row.upBtn:Hide()
        row.downBtn:Hide()
        for _, lbl in ipairs(row.slotLabels) do lbl:Hide() end
    end

    local myID       = GT.DB.uniqueID
    local playerData = myID and GT.DB.players[myID]
    if not playerData then return end

    local order = GetCharOrder(playerData)

    for rowIdx, charName in ipairs(order) do
        local charData = playerData.chars[charName]

        if not rowPool[rowIdx] then
            local newRow = { slotLabels = {} }

            newRow.charLabel = vaultFrame:CreateFontString(nil, "OVERLAY")
            GT.UI:SetFont(newRow.charLabel, 13, "")
            newRow.charLabel:SetWidth(COL_CHAR)
            newRow.charLabel:SetJustifyH("LEFT")

            newRow.upBtn   = CreateArrowButton("Up")
            newRow.downBtn = CreateArrowButton("Down")
            newRow.upBtn:SetScript("OnClick",   makeSwapHandler(-1))
            newRow.downBtn:SetScript("OnClick",  makeSwapHandler(1))

            for _ = 1, #SLOT_COLS do
                local lbl = vaultFrame:CreateFontString(nil, "OVERLAY")
                GT.UI:SetFont(lbl, 13, "")
                lbl:SetWidth(COL_SLOT)
                lbl:SetJustifyH("CENTER")
                table.insert(newRow.slotLabels, lbl)
            end

            rowPool[rowIdx] = newRow
        end

        local row  = rowPool[rowIdx]
        local rowY = FIRST_ROW_Y - (rowIdx - 1) * ROW_H

        -- Arrow buttons
        row.upBtn:ClearAllPoints()
        row.upBtn:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", PE_PAD, rowY - 2)
        row.upBtn._charName = charName
        if rowIdx > 1 then row.upBtn:Show() else row.upBtn:Hide() end

        row.downBtn:ClearAllPoints()
        row.downBtn:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", PE_PAD + 20, rowY - 2)
        row.downBtn._charName = charName
        if rowIdx < #order then row.downBtn:Show() else row.downBtn:Hide() end

        -- Character label
        row.charLabel:ClearAllPoints()
        row.charLabel:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[1], rowY)
        row.charLabel:SetText((charData.name or charName) .. "-" .. (charData.server or "?"))

        local classColor = charData.class and RAID_CLASS_COLORS[charData.class:upper()]
        if classColor then
            row.charLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            row.charLabel:SetTextColor(1, 1, 1)
        end
        row.charLabel:Show()

        -- Vault slot cells
        for i, col in ipairs(SLOT_COLS) do
            local lbl = row.slotLabels[i]
            lbl:ClearAllPoints()
            lbl:SetPoint("TOPLEFT", vaultFrame, "TOPLEFT", COL_X[i + 1], rowY)
            lbl:SetText(getSlotText(charData.vault, col.type, col.idx))
            lbl:SetTextColor(getSlotColor(charData.vault, col.type, col.idx))
            lbl:Show()
        end
    end
end

vaultFrame:SetScript("OnShow", RefreshVault)
