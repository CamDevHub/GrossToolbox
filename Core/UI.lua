local AddonName, GT = ...

local UI = GT.UI

-- Default font; overridden from GT.DB.fontPath on ADDON_LOADED
GT.Config.FONT_PATH = "Fonts\\FRIZQT__.TTF"
UI.fontRegistry = {}

function UI:SetFont(fontString, size, flags)
    flags = flags or ""
    fontString:SetFont(GT.Config.FONT_PATH, size, flags)
    table.insert(self.fontRegistry, { fs = fontString, size = size, flags = flags })
end

function UI:RefreshFonts()
    for _, entry in ipairs(self.fontRegistry) do
        entry.fs:SetFont(GT.Config.FONT_PATH, entry.size, entry.flags)
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

-- ============================================================
-- Popup helpers
-- ============================================================

-- Creates a styled modal popup with a title bar, content area, and close button.
-- Returns the popup frame plus the inner content frame for callers to populate.
--
-- Usage:
--   local popup, content = GT.UI:CreatePopup("My Title", 400, 300)
--   popup:Show()
function UI:CreatePopup(title, width, height)
    local TITLE_H  = 28
    local CLOSE_W  = TITLE_H
    local PAD      = 1   -- border width

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(width, height)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    popup:SetBackdropColor(unpack(GT.Config.COLOR_BG_CONTENT))
    popup:SetBackdropBorderColor(0, 0, 0, 1)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop",  popup.StopMovingOrSizing)
    popup:Hide()

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  popup, "TOPLEFT")
    titleBar:SetPoint("TOPRIGHT", popup, "TOPRIGHT")
    titleBar:SetHeight(TITLE_H)
    titleBar:SetBackdrop({ bgFile = GT.Config.WHITE8X8 })
    titleBar:SetBackdropColor(unpack(GT.Config.COLOR_BG_TABBAR))

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY")
    self:SetFont(titleLabel, 13, "")
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleLabel:SetText(title)
    titleLabel:SetTextColor(0.9, 0.9, 0.9)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, popup)
    closeBtn:SetSize(CLOSE_W, TITLE_H)
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT")
    closeBtn:SetFrameLevel(popup:GetFrameLevel() + 10)

    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.6, 0.1, 0.1, 1)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    self:SetFont(closeText, 13, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(1, 1, 1)

    closeBtn:SetScript("OnEnter", function() closeBg:SetColorTexture(0.9, 0.1, 0.1, 1) end)
    closeBtn:SetScript("OnLeave", function() closeBg:SetColorTexture(0.6, 0.1, 0.1, 1) end)
    closeBtn:SetScript("OnClick", function() popup:Hide() end)

    -- Separator under title bar
    local sep = popup:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT",  titleBar, "BOTTOMLEFT")
    sep:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT")
    sep:SetHeight(1)
    sep:SetColorTexture(0, 0, 0, 0.8)

    -- Content area (below title bar)
    local content = CreateFrame("Frame", nil, popup)
    content:SetPoint("TOPLEFT",     titleBar, "BOTTOMLEFT",  0, -1)
    content:SetPoint("BOTTOMRIGHT", popup,    "BOTTOMRIGHT")

    popup.content  = content
    popup.titleBar = titleBar

    return popup, content
end

-- Creates a confirmation popup with a message, a confirm button, and a cancel button.
-- onConfirm and onCancel are optional callbacks; both close the popup automatically.
--
-- Usage:
--   local confirm = GT.UI:CreateConfirmPopup("Are you sure?", function() doThing() end)
--   confirm:Show()
function UI:CreateConfirmPopup(message, onConfirm, onCancel)
    local BTN_H = 28
    local BTN_W = 110
    local PAD   = 16

    local popup, content = self:CreatePopup("Confirm", 340, 130)

    local msgLabel = content:CreateFontString(nil, "OVERLAY")
    self:SetFont(msgLabel, 13, "")
    msgLabel:SetPoint("TOPLEFT",  content, "TOPLEFT",  PAD, -PAD)
    msgLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, -PAD)
    msgLabel:SetJustifyH("LEFT")
    msgLabel:SetText(message)
    msgLabel:SetTextColor(0.9, 0.9, 0.9)

    -- Confirm button
    local confirmBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    confirmBtn:SetSize(BTN_W, BTN_H)
    confirmBtn:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", PAD, PAD)
    confirmBtn:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    confirmBtn:SetBackdropColor(0.08, 0.4, 0.08, 1)
    confirmBtn:SetBackdropBorderColor(0.1, 0.6, 0.1, 1)
    confirmBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.12, 0.55, 0.12, 1) end)
    confirmBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.08, 0.4,  0.08, 1) end)
    confirmBtn:SetScript("OnClick", function()
        popup:Hide()
        if onConfirm then onConfirm() end
    end)

    local confirmText = confirmBtn:CreateFontString(nil, "OVERLAY")
    self:SetFont(confirmText, 13, "")
    confirmText:SetPoint("CENTER")
    confirmText:SetText("Confirm")
    confirmText:SetTextColor(1, 1, 1)

    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    cancelBtn:SetSize(BTN_W, BTN_H)
    cancelBtn:SetPoint("LEFT", confirmBtn, "RIGHT", 8, 0)
    cancelBtn:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    cancelBtn:SetBackdropColor(0.25, 0.25, 0.25, 1)
    cancelBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    cancelBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.35, 0.35, 0.35, 1) end)
    cancelBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.25, 0.25, 0.25, 1) end)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
        if onCancel then onCancel() end
    end)

    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    self:SetFont(cancelText, 13, "")
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    cancelText:SetTextColor(1, 1, 1)

    -- Allow callers to update the message after creation
    popup.SetMessage = function(self, text) msgLabel:SetText(text) end

    return popup
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
