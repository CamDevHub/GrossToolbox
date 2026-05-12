local AddonName, GT = ...

local UI = GT.UI

-- Default font; overridden from GT.DB.fontPath on ADDON_LOADED
GT.Config.FONT_PATH = "Fonts\\FRIZQT__.TTF"

-- Weak-key table: the FontString is the key and is held weakly.
-- When a FontString's parent frame is GC'd the entry vanishes automatically,
-- so the registry never accumulates dead references.
UI.fontRegistry = setmetatable({}, { __mode = "k" })

function UI:SetFont(fontString, size, flags)
    flags = flags or ""
    fontString:SetFont(GT.Config.FONT_PATH, size, flags)
    self.fontRegistry[fontString] = { size = size, flags = flags }
end

function UI:RefreshFonts()
    for fs, entry in pairs(self.fontRegistry) do
        fs:SetFont(GT.Config.FONT_PATH, entry.size, entry.flags)
    end
end

function UI:CreateButton(parent, label, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)

    btn.text = btn:CreateFontString(nil, "OVERLAY")
    self:SetFont(btn.text, 21, "")
    btn.text:SetPoint("LEFT", btn, "LEFT", 15, 0)
    btn.text:SetText(label)
    btn.text:SetTextColor(0.8, 0.8, 0.8)

    return btn
end

function UI:CreateSidebarButton(parent, label)
    local btn = self:CreateButton(parent, label, parent:GetWidth(), 50)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(1, 1, 1, 0.05)
    btn.bg:Hide()

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self.bg:Show()
            self.text:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self.bg:Hide()
            self.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end)

    return btn
end

function UI:CreateTabButton(parent, label)
    local btn = CreateFrame("Button", nil, parent)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(1, 1, 1, 0.06)
    btn.bg:Hide()

    btn.text = btn:CreateFontString(nil, "OVERLAY")
    self:SetFont(btn.text, 18, "")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(label)
    btn.text:SetTextColor(0.8, 0.8, 0.8)

    btn.activeLine = btn:CreateTexture(nil, "OVERLAY")
    btn.activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
    btn.activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.activeLine:SetHeight(2)
    btn.activeLine:SetColorTexture(0, 0.5, 1, 1)
    btn.activeLine:Hide()

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self.bg:Show()
            self.text:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self.bg:Hide()
            self.text:SetTextColor(0.8, 0.8, 0.8)
        end
    end)

    return btn
end

-- Creates a styled single-line EditBox. Caller is responsible for positioning.
-- OnEscapePressed → ClearFocus is wired automatically.
function UI:CreateInputBox(parent, width, height, fontSize)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, height)
    box:SetAutoFocus(false)
    self:SetFont(box, fontSize, "")
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

-- Creates a styled backdrop button with proportional colour hover effect.
-- color = { r, g, b }. Caller is responsible for positioning.
function UI:CreateActionButton(parent, label, width, height, fontSize, color)
    local r, g, b = color[1], color[2], color[3]
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    btn:SetBackdropColor(r * 0.5, g * 0.5, b * 0.5, 1)
    btn:SetBackdropBorderColor(r, g, b, 0.6)
    btn:SetScript("OnEnter", function(self) self:SetBackdropColor(r * 0.8, g * 0.8, b * 0.8, 1) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropColor(r * 0.5, g * 0.5, b * 0.5, 1) end)

    local txt = btn:CreateFontString(nil, "OVERLAY")
    self:SetFont(txt, fontSize, "")
    txt:SetPoint("CENTER")
    txt:SetText(label)
    txt:SetTextColor(1, 1, 1)
    btn.text = txt

    return btn
end

function UI:RebuildTabBar(moduleName)
    local tabBar = self.tabBar

    for _, module in pairs(GT.Modules) do
        if module.tabButtons then
            for _, btn in pairs(module.tabButtons) do
                btn:Hide()
            end
        end
    end

    local module = GT.Modules[moduleName]
    if not module or not module.categoryOrder or #module.categoryOrder == 0 then
        return
    end

    local TAB_WIDTH = 150
    local TAB_GAP   = 2
    local x         = 8

    for _, catName in ipairs(module.categoryOrder) do
        local btn = module.tabButtons[catName]
        if btn then
            btn:ClearAllPoints()
            btn:SetSize(TAB_WIDTH, tabBar:GetHeight())
            btn:SetPoint("LEFT", tabBar, "LEFT", x, 0)
            btn:Show()
            x = x + TAB_WIDTH + TAB_GAP
        end
    end
end
