local AddonName, GT = ...

local Settings        = GT.Modules.Settings
local customizeFrame  = Settings.Categories["Customize"]

local PAD         = 24
local LIST_W      = 280
local LIST_H      = 320
local FONT_ROW_H  = 30
local DROPDOWN_H  = 32

local DEFAULT_FONTS = {
    { name = "Friz Quadrata (Default)", path = "Fonts\\FRIZQT__.TTF"  },
    { name = "Arial Narrow",            path = "Fonts\\ARIALN.TTF"    },
    { name = "Morpheus",                path = "Fonts\\MORPHEUS.TTF"  },
    { name = "Skurri",                  path = "Fonts\\SKURRI.TTF"    },
}

local fontHeaderLbl = customizeFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(fontHeaderLbl, 13, "")
fontHeaderLbl:SetPoint("TOPLEFT", customizeFrame, "TOPLEFT", PAD, -PAD)
fontHeaderLbl:SetText("Font")
fontHeaderLbl:SetTextColor(0.8, 0.8, 0.8)

-- Collapsed dropdown button
local dropdownBtn = CreateFrame("Button", nil, customizeFrame, "BackdropTemplate")
dropdownBtn:SetSize(LIST_W, DROPDOWN_H)
dropdownBtn:SetPoint("TOPLEFT", fontHeaderLbl, "BOTTOMLEFT", 0, -8)
dropdownBtn:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
dropdownBtn:SetBackdropColor(0.10, 0.10, 0.10, 1)
dropdownBtn:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
dropdownBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0, 0.5, 1, 0.9) end)
dropdownBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1) end)

local selectedLbl = dropdownBtn:CreateFontString(nil, "OVERLAY")
selectedLbl:SetPoint("LEFT",  dropdownBtn, "LEFT",  10, 0)
selectedLbl:SetPoint("RIGHT", dropdownBtn, "RIGHT", -28, 0)
selectedLbl:SetJustifyH("LEFT")
selectedLbl:SetTextColor(1, 1, 1)

local arrowTex = dropdownBtn:CreateTexture(nil, "OVERLAY")
arrowTex:SetSize(14, 12)
arrowTex:SetPoint("RIGHT", dropdownBtn, "RIGHT", -8, 0)
arrowTex:SetTexture("Interface\\Buttons\\Arrow-Down-Up")

-- Expanded list (hidden by default, floats over other content)
local listBg = CreateFrame("Frame", nil, customizeFrame, "BackdropTemplate")
listBg:SetSize(LIST_W, LIST_H)
listBg:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
listBg:SetFrameLevel(dropdownBtn:GetFrameLevel() + 20)
listBg:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
listBg:SetBackdropColor(0.06, 0.06, 0.06, 1)
listBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
listBg:Hide()

local listScroll = CreateFrame("ScrollFrame", nil, listBg, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT",     listBg, "TOPLEFT",     2,   -2)
listScroll:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -20,  2)
listScroll:SetFrameLevel(listBg:GetFrameLevel())

local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetWidth(LIST_W - 22)
listScroll:SetScrollChild(listChild)

local fontRows  = {}
local listBuilt = false

local function UpdateFontHighlights()
    for _, row in ipairs(fontRows) do
        if row.path == GT.Config.FONT_PATH then
            row.bg:Show()
        else
            row.bg:Hide()
        end
    end
end

local function UpdateDropdown()
    local name = GT.DB.fontName or DEFAULT_FONTS[1].name
    local path = GT.Config.FONT_PATH or DEFAULT_FONTS[1].path
    selectedLbl:SetFont(path, 14, "")
    selectedLbl:SetText(name)
end

local function CloseList()
    listBg:Hide()
    arrowTex:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
end

local function SelectFont(name, path)
    GT.Config.FONT_PATH = path
    GT.DB.fontPath      = path
    GT.DB.fontName      = name
    GT.UI:RefreshFonts()
    UpdateFontHighlights()
    UpdateDropdown()
    CloseList()
end

local function BuildFontList()
    if listBuilt then
        UpdateFontHighlights()
        return
    end
    listBuilt = true

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fonts
    if LSM then
        fonts = {}
        for _, name in ipairs(LSM:List("font")) do
            table.insert(fonts, { name = name, path = LSM:Fetch("font", name) })
        end
    else
        fonts = DEFAULT_FONTS
    end

    listChild:SetHeight(#fonts * FONT_ROW_H)

    for i, font in ipairs(fonts) do
        local btn = CreateFrame("Button", nil, listChild)
        btn:SetSize(LIST_W - 22, FONT_ROW_H)
        btn:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -(i - 1) * FONT_ROW_H)
        btn:SetFrameLevel(listBg:GetFrameLevel() + 1)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0.5, 1, 0.3)
        if GT.Config.FONT_PATH == font.path then bg:Show() else bg:Hide() end

        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetPoint("LEFT", btn, "LEFT", 8, 0)
        lbl:SetWidth(LIST_W - 38)
        lbl:SetJustifyH("LEFT")
        lbl:SetFont(font.path, 14, "")  -- intentionally not in registry: each row shows its own font
        lbl:SetText(font.name)
        lbl:SetTextColor(1, 1, 1)

        local capturedFont = font
        btn:SetScript("OnEnter", function()
            if GT.Config.FONT_PATH ~= capturedFont.path then
                bg:SetColorTexture(1, 1, 1, 0.08)
                bg:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            if GT.Config.FONT_PATH ~= capturedFont.path then
                bg:Hide()
            end
        end)
        btn:SetScript("OnClick", function()
            SelectFont(capturedFont.name, capturedFont.path)
        end)

        table.insert(fontRows, { bg = bg, path = font.path })
    end

    UpdateFontHighlights()
end

dropdownBtn:SetScript("OnClick", function()
    if listBg:IsShown() then
        CloseList()
    else
        BuildFontList()
        listBg:Show()
        arrowTex:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    end
end)

customizeFrame:SetScript("OnShow", function()
    UpdateDropdown()
    CloseList()
end)

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
    UpdateDropdown()
end)
