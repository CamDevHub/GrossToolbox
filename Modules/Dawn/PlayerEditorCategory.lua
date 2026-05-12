local AddonName, GT = ...

local Dawn              = GT.Modules.Dawn
local playerEditorFrame = Dawn.Categories["Player Editor"]

local PE_PAD   = 24
local COL_NAME = 220
local COL_CB   = 100
local ROW_H    = 40
local HEADER_Y = -PE_PAD

local COLUMNS = {
    { label = "Hide",      key = "hideFromTag"                },
    { label = "Character"                                     },
    { label = "Tank",      key = "tank",       src = "roles"  },
    { label = "Heal",      key = "heal",       src = "roles"  },
    { label = "DPS",       key = "dps",        src = "roles"  },
    { label = "No Key",    key = "forceNoKey"                 },
}

-- col 1 = COL_CB, col 2 = COL_NAME, rest = COL_CB
local COL_X = { PE_PAD }
for i = 2, #COLUMNS do
    COL_X[i] = COL_X[i - 1] + (i == 2 and COL_CB or i == 3 and COL_NAME or COL_CB)
end

-- Static header labels
for i, col in ipairs(COLUMNS) do
    local lbl = playerEditorFrame:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(lbl, 14, "")
    lbl:SetPoint("TOPLEFT", playerEditorFrame, "TOPLEFT", COL_X[i], HEADER_Y)
    lbl:SetWidth(i == 2 and COL_NAME or COL_CB)
    lbl:SetJustifyH(i == 2 and "LEFT" or "CENTER")
    lbl:SetText(col.label)
    lbl:SetTextColor(0.6, 0.6, 0.6)
end

local headerSep = playerEditorFrame:CreateTexture(nil, "ARTWORK")
headerSep:SetPoint("TOPLEFT",  playerEditorFrame, "TOPLEFT",   PE_PAD, HEADER_Y - 22)
headerSep:SetPoint("TOPRIGHT", playerEditorFrame, "TOPRIGHT", -PE_PAD, HEADER_Y - 22)
headerSep:SetHeight(1)
headerSep:SetColorTexture(0.3, 0.3, 0.3, 1)

local function getVal(charData, col)
    if col.src == "roles" then
        return charData.roles and charData.roles[col.key] or false
    end
    return charData[col.key] or false
end

local function setVal(charData, col, value)
    if col.src == "roles" then
        charData.roles = charData.roles or {}
        charData.roles[col.key] = value
    else
        charData[col.key] = value
    end
end

-- Row widget pool — widgets are created once and reused across refreshes
local rowPool = {}

local function RefreshPlayerEditor()
    for _, row in ipairs(rowPool) do
        row.label:Hide()
        for _, cb in pairs(row.cbs) do cb:Hide() end
    end

    local myID       = GT.DB.uniqueID
    local playerData = myID and GT.DB.players[myID]
    if not playerData then return end

    local rowIdx = 0
    for charName, charData in pairs(playerData.chars or {}) do
        rowIdx = rowIdx + 1

        if not rowPool[rowIdx] then
            local newRow = { cbs = {} }

            newRow.label = playerEditorFrame:CreateFontString(nil, "OVERLAY")
            GT.UI:SetFont(newRow.label, 14, "")

            for ci = 1, #COLUMNS do
                if COLUMNS[ci].key then
                    local cb  = CreateFrame("CheckButton", nil, playerEditorFrame, "UICheckButtonTemplate")
                    local col = COLUMNS[ci]
                    cb:SetSize(26, 26)
                    cb:SetScript("OnClick", function(self)
                        local entry = GT.DB.players[GT.DB.uniqueID]
                        if entry and entry.chars and self._charName then
                            setVal(entry.chars[self._charName], col, self:GetChecked())
                            GT.Modules.Dawn.InvalidateTagCache()
                        end
                    end)
                    newRow.cbs[ci] = cb
                end
            end

            rowPool[rowIdx] = newRow
        end

        local row  = rowPool[rowIdx]
        local rowY = HEADER_Y - 30 - (rowIdx - 1) * ROW_H

        row.label:ClearAllPoints()
        row.label:SetPoint("TOPLEFT", playerEditorFrame, "TOPLEFT", COL_X[2], rowY)
        row.label:SetText((charData.name or charName) .. "-" .. (charData.server or "?"))

        local classColor = charData.class and RAID_CLASS_COLORS[charData.class:upper()]
        if classColor then
            row.label:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            row.label:SetTextColor(1, 1, 1)
        end
        row.label:Show()

        for ci = 1, #COLUMNS do
            if COLUMNS[ci].key then
                local cb = row.cbs[ci]
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", playerEditorFrame, "TOPLEFT", COL_X[ci] + COL_CB / 2 - 13, rowY + 4)
                cb._charName = charName
                cb:SetChecked(getVal(charData, COLUMNS[ci]))
                cb:Show()
            end
        end
    end
end

playerEditorFrame:SetScript("OnShow", RefreshPlayerEditor)
