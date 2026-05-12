local AddonName, GT = ...

local UI = GT.UI

-- Creates a styled modal popup with a title bar, content area, and close button.
-- Returns the popup frame plus the inner content frame for callers to populate.
--
-- Usage:
--   local popup, content = GT.UI:CreatePopup("My Title", 400, 300)
--   popup:Show()
function UI:CreatePopup(title, width, height)
    local TITLE_H = 28
    local CLOSE_W = TITLE_H

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

-- Creates an informational popup with a message and a single OK button.
-- Use this for one-way notices where no action is needed from the user.
--
-- Usage:
--   local alert = GT.UI:CreateAlertPopup("Missing Discord Handle", "Please fill in your handle.")
--   alert:Show()
function UI:CreateAlertPopup(title, message)
    local BTN_H = 28
    local BTN_W = 80
    local PAD   = 16

    local popup, content = self:CreatePopup(title, 340, 120)

    local msgLabel = content:CreateFontString(nil, "OVERLAY")
    self:SetFont(msgLabel, 13, "")
    msgLabel:SetPoint("TOPLEFT",  content, "TOPLEFT",  PAD, -PAD)
    msgLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, -PAD)
    msgLabel:SetJustifyH("LEFT")
    msgLabel:SetText(message)
    msgLabel:SetTextColor(0.9, 0.9, 0.9)

    local okBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    okBtn:SetSize(BTN_W, BTN_H)
    okBtn:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", PAD, PAD)
    okBtn:SetBackdrop({
        bgFile   = GT.Config.WHITE8X8,
        edgeFile = GT.Config.WHITE8X8,
        edgeSize = 1,
    })
    okBtn:SetBackdropColor(0.25, 0.25, 0.25, 1)
    okBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    okBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.35, 0.35, 0.35, 1) end)
    okBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.25, 0.25, 0.25, 1) end)
    okBtn:SetScript("OnClick", function() popup:Hide() end)

    local okText = okBtn:CreateFontString(nil, "OVERLAY")
    self:SetFont(okText, 13, "")
    okText:SetPoint("CENTER")
    okText:SetText("OK")
    okText:SetTextColor(1, 1, 1)

    return popup
end
