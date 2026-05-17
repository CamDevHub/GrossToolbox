local AddonName, GT = ...

local Dungeon = GT.Modules.Dungeon
local mpFrame = Dungeon.Categories["M+"]
local Recap   = Dungeon.Recap   -- populated by MplusRecap.lua (loads first)

local PAD = 16

-- ============================================================
-- Recap toggle
-- ============================================================

local toggleCB = CreateFrame("CheckButton", nil, mpFrame, "UICheckButtonTemplate")
toggleCB:SetSize(24, 24)
toggleCB:SetPoint("TOPLEFT", mpFrame, "TOPLEFT", PAD, -PAD)

local toggleLabel = mpFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(toggleLabel, 13, "")
toggleLabel:SetPoint("LEFT", toggleCB, "RIGHT", 6, 0)
toggleLabel:SetText("Show recap popup after M+ completion")
toggleLabel:SetTextColor(0.8, 0.8, 0.8)

toggleCB:SetScript("OnClick", function(self)
    Recap.recapEnabled = self:GetChecked()
    if GT.loaded then GT.DB.dungeonRecapEnabled = Recap.recapEnabled end
end)

-- ============================================================
-- Preview toggle
-- ============================================================

local previewCB = CreateFrame("CheckButton", nil, mpFrame, "UICheckButtonTemplate")
previewCB:SetSize(24, 24)
previewCB:SetPoint("TOPLEFT", toggleCB, "BOTTOMLEFT", 0, -8)

local previewLabel = mpFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(previewLabel, 13, "")
previewLabel:SetPoint("LEFT", previewCB, "RIGHT", 6, 0)
previewLabel:SetText("Preview recap popup")
previewLabel:SetTextColor(0.8, 0.8, 0.8)

previewCB:SetScript("OnClick", function(self)
    if self:GetChecked() then
        Recap.ShowPreview()
    else
        Recap.popup:Hide()
    end
end)

-- Uncheck when the popup is closed externally (Esc, close button, real recap)
Recap.popup:HookScript("OnHide", function()
    previewCB:SetChecked(false)
end)

-- ============================================================
-- Screenshot toggle
-- ============================================================

local screenshotCB = CreateFrame("CheckButton", nil, mpFrame, "UICheckButtonTemplate")
screenshotCB:SetSize(24, 24)
screenshotCB:SetPoint("TOPLEFT", previewCB, "BOTTOMLEFT", 0, -8)

local screenshotLabel = mpFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(screenshotLabel, 13, "")
screenshotLabel:SetPoint("LEFT", screenshotCB, "RIGHT", 6, 0)
screenshotLabel:SetText("Take screenshot on completion")
screenshotLabel:SetTextColor(0.8, 0.8, 0.8)

screenshotCB:SetScript("OnClick", function(self)
    Recap.screenshotEnabled = self:GetChecked()
    if GT.loaded then GT.DB.dungeonScreenshotEnabled = Recap.screenshotEnabled end
end)

-- ============================================================
-- Auto-slot keystone
-- ============================================================

local autoKeyEnabled = false

local autoKeyCB = CreateFrame("CheckButton", nil, mpFrame, "UICheckButtonTemplate")
autoKeyCB:SetSize(24, 24)
autoKeyCB:SetPoint("TOPLEFT", screenshotCB, "BOTTOMLEFT", 0, -8)

local autoKeyLabel = mpFrame:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(autoKeyLabel, 13, "")
autoKeyLabel:SetPoint("LEFT", autoKeyCB, "RIGHT", 6, 0)
autoKeyLabel:SetText("Auto-slot keystone on Font of Power")
autoKeyLabel:SetTextColor(0.8, 0.8, 0.8)

autoKeyCB:SetScript("OnClick", function(self)
    autoKeyEnabled = self:GetChecked()
    if GT.loaded then GT.DB.dungeonAutoKeyEnabled = autoKeyEnabled end
end)

-- Fires when the Font of Power interaction frame opens.
local autoKeyFrame = CreateFrame("Frame")
autoKeyFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
autoKeyFrame:SetScript("OnEvent", function(_, _, interactionType)
    if not autoKeyEnabled then return end
    if interactionType ~= Enum.PlayerInteractionType.MythicKeystone then return end
    C_MythicPlus.InsertKeystoneIntoFont()
end)

-- ============================================================
-- Persist / restore
-- ============================================================

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    Recap.recapEnabled      = GT.DB.dungeonRecapEnabled      or false
    Recap.screenshotEnabled = GT.DB.dungeonScreenshotEnabled or false
    autoKeyEnabled          = GT.DB.dungeonAutoKeyEnabled    or false
    toggleCB:SetChecked(Recap.recapEnabled)
    screenshotCB:SetChecked(Recap.screenshotEnabled)
    autoKeyCB:SetChecked(autoKeyEnabled)
end)
