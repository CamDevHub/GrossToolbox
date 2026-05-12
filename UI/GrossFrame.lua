local AddonName, GT = ...

local Core = GT.Core
local Config = GT.Config
local UI = GT.UI

Config.MAIN_FRAME_WIDTH = 1200
Config.MAIN_FRAME_HEIGHT = 600
Config.SIDEBAR_WIDTH = Config.MAIN_FRAME_WIDTH * 0.20
Config.TAB_BAR_HEIGHT  = 36
Config.FOOTER_HEIGHT   = 24

Config.WHITE8X8 = "Interface\\Buttons\\WHITE8X8"

Config.COLOR_BG_CONTENT = { 0.1,  0.1,  0.1,  0.95 }
Config.COLOR_BG_SIDEBAR  = { 0.05, 0.05, 0.05, 1    }
Config.COLOR_BG_TABBAR   = { 0.07, 0.07, 0.07, 1    }
Config.COLOR_BG_FOOTER   = { 0.03, 0.03, 0.03, 1    }

-- Main frame
UI.frame = CreateFrame("Frame", "GrossToolboxMain", UIParent, "BackdropTemplate")
local frame = UI.frame
frame:SetSize(Config.MAIN_FRAME_WIDTH, Config.MAIN_FRAME_HEIGHT)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetBackdrop({
    bgFile   = Config.WHITE8X8,
    edgeFile = Config.WHITE8X8,
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
})
frame:SetBackdropColor(unpack(Config.COLOR_BG_CONTENT))
frame:SetBackdropBorderColor(0, 0, 0, 1)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()
tinsert(UISpecialFrames, "GrossToolboxMain")

-- Close button
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(Config.TAB_BAR_HEIGHT, Config.TAB_BAR_HEIGHT)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
closeBtn:SetFrameLevel(frame:GetFrameLevel() + 10)

local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
closeBg:SetAllPoints()
closeBg:SetColorTexture(0.6, 0.1, 0.1, 1)

local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(closeText, 13, "")
closeText:SetPoint("CENTER")
closeText:SetText("X")
closeText:SetTextColor(1, 1, 1)

closeBtn:SetScript("OnEnter", function()
    closeBg:SetColorTexture(0.9, 0.1, 0.1, 1)
end)
closeBtn:SetScript("OnLeave", function()
    closeBg:SetColorTexture(0.6, 0.1, 0.1, 1)
end)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

-- Footer bar
local Footer = CreateFrame("Frame", "GrossToolboxFooter", frame, "BackdropTemplate")
Footer:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT")
Footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
Footer:SetHeight(24)
Footer:SetBackdrop({ bgFile = Config.WHITE8X8 })
Footer:SetBackdropColor(unpack(Config.COLOR_BG_FOOTER))

local footerAuthor = Footer:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(footerAuthor, 11, "")
footerAuthor:SetPoint("LEFT", Footer, "LEFT", 12, 0)
footerAuthor:SetText("by Grosstartine")
footerAuthor:SetTextColor(0.5, 0.5, 0.5)

local footerVersion = Footer:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(footerVersion, 11, "")
footerVersion:SetPoint("RIGHT", Footer, "RIGHT", -12, 0)
footerVersion:SetTextColor(0.5, 0.5, 0.5)

-- Filled once the addon metadata is available
local footerInitFrame = CreateFrame("Frame")
footerInitFrame:RegisterEvent("ADDON_LOADED")
footerInitFrame:SetScript("OnEvent", function(self, _, name)
    if name ~= AddonName then return end
    local version = C_AddOns.GetAddOnMetadata(AddonName, "Version") or ""
    GT.Core:DebugPrint("GrossFrame: ADDON_LOADED, version =", version)
    footerVersion:SetText("v" .. version)
    self:UnregisterAllEvents()
end)

-- Sidebar
local Sidebar = CreateFrame("Frame", "GrossToolboxSidebar", frame, "BackdropTemplate")
Sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT")
Sidebar:SetPoint("BOTTOMLEFT", Footer, "TOPLEFT")
Sidebar:SetWidth(Config.SIDEBAR_WIDTH)
Sidebar:SetBackdrop({ bgFile = Config.WHITE8X8 })
Sidebar:SetBackdropColor(unpack(Config.COLOR_BG_SIDEBAR))
UI.sidebar = Sidebar

-- Right side wrapper
local ContentWrapper = CreateFrame("Frame", "GrossToolboxContentWrapper", frame)
ContentWrapper:SetPoint("TOPLEFT",     Sidebar, "TOPRIGHT")
ContentWrapper:SetPoint("BOTTOMRIGHT", Footer,  "TOPRIGHT")

-- Tab bar (top strip)
local TabBar = CreateFrame("Frame", "GrossToolboxTabBar", ContentWrapper, "BackdropTemplate")
TabBar:SetPoint("TOPLEFT", ContentWrapper, "TOPLEFT")
TabBar:SetPoint("TOPRIGHT", ContentWrapper, "TOPRIGHT")
TabBar:SetHeight(Config.TAB_BAR_HEIGHT)
TabBar:SetBackdrop({ bgFile = Config.WHITE8X8 })
TabBar:SetBackdropColor(unpack(Config.COLOR_BG_TABBAR))
UI.tabBar = TabBar

-- 1px separator under tab bar (visual only — ContentArea anchors to TabBar, not this texture)
local TabBorder = ContentWrapper:CreateTexture(nil, "ARTWORK")
TabBorder:SetPoint("TOPLEFT", TabBar, "BOTTOMLEFT")
TabBorder:SetPoint("TOPRIGHT", TabBar, "BOTTOMRIGHT")
TabBorder:SetHeight(1)
TabBorder:SetColorTexture(0, 0, 0, 0.8)

-- Content area (below tab bar)
local ContentArea = CreateFrame("Frame", "GrossToolboxContentArea", ContentWrapper)
ContentArea:SetPoint("TOPLEFT",     TabBar,          "BOTTOMLEFT",  0, -1)  -- -1 clears the separator
ContentArea:SetPoint("BOTTOMRIGHT", ContentWrapper,  "BOTTOMRIGHT")
UI.contentArea = ContentArea

-- Create modules now that contentArea exists (order here defines GT.Core.moduleOrder)
Core:CreateModule("Dawn")
Core:CreateModule("Weekly")
Core:CreateModule("Settings")

-- Sidebar buttons
local sidebarBtns = {}

local function activateSidebarBtn(btn)
    for _, b in pairs(sidebarBtns) do
        b.isActive = false
        b.bg:Hide()
        b.text:SetTextColor(0.8, 0.8, 0.8)
    end
    btn.isActive = true
    btn.bg:SetColorTexture(0, 0.5, 1, 0.2)
    btn.bg:Show()
    btn.text:SetTextColor(1, 1, 1)
end

for i, moduleName in ipairs(Core.moduleOrder) do
    local btn = UI:CreateSidebarButton(Sidebar, moduleName)

    if i == 1 then
        btn:SetPoint("TOP", Sidebar, "TOP", 0, -1)
    else
        btn:SetPoint("TOP", sidebarBtns[i - 1], "BOTTOM", 0, -5)
    end

    local capturedModule = moduleName
    btn:SetScript("OnClick", function(self)
        activateSidebarBtn(self)
        Core:SetModule(capturedModule)
    end)

    sidebarBtns[i] = btn
end

-- Activate the first module after all files are loaded
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        GT.Core:DebugPrint("GrossFrame: PLAYER_LOGIN, activating module =", Core.moduleOrder[1])
        activateSidebarBtn(sidebarBtns[1])
        Core:SetModule(Core.moduleOrder[1])
    end
end)

frame:SetScript("OnShow", function()
    activateSidebarBtn(sidebarBtns[1])
    Core:SetModule(Core.moduleOrder[1])
end)
