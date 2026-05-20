local AddonName, GT = ...

local Settings         = GT.Modules.Settings
local maintenanceFrame = Settings.Categories["Maintenance"]

local PAD = 24

local resetBtn = CreateFrame("Button", nil, maintenanceFrame, "BackdropTemplate")
resetBtn:SetSize(180, 36)
resetBtn:SetPoint("TOPLEFT", maintenanceFrame, "TOPLEFT", PAD, -PAD)
resetBtn:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
resetBtn:SetBackdropColor(0.4, 0.08, 0.08, 1)
resetBtn:SetBackdropBorderColor(0.6, 0.1, 0.1, 1)

local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(resetText, 13, "")
resetText:SetPoint("CENTER")
resetText:SetText("Reset Database")
resetText:SetTextColor(1, 1, 1)

local resetConfirm = GT.UI:CreateConfirmPopup(
    "This will wipe all saved data and reload the UI.\nAre you sure?",
    function()
        GrossToolboxDB = nil
        ReloadUI()
    end
)

resetBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.6, 0.1, 0.1, 1) end)
resetBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.4, 0.08, 0.08, 1) end)
resetBtn:SetScript("OnClick", function() resetConfirm:Show() end)

local debugToggle = CreateFrame("Button", nil, maintenanceFrame, "BackdropTemplate")
debugToggle:SetSize(180, 36)
debugToggle:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -12)
debugToggle:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})

local debugToggleText = debugToggle:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(debugToggleText, 13, "")
debugToggleText:SetPoint("CENTER")
debugToggleText:SetTextColor(1, 1, 1)

local function applyDebugToggleState()
    if GT.Debug then
        debugToggle:SetBackdropColor(0.08, 0.4, 0.08, 1)
        debugToggle:SetBackdropBorderColor(0.1, 0.6, 0.1, 1)
        debugToggleText:SetText("Debug Mode: ON")
    else
        debugToggle:SetBackdropColor(0.15, 0.15, 0.15, 1)
        debugToggle:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        debugToggleText:SetText("Debug Mode: OFF")
    end
end

debugToggle:SetScript("OnClick", function()
    GT.Debug = not GT.Debug
    GT.DB.debugMode = GT.Debug
    applyDebugToggleState()
end)
debugToggle:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0, 0.5, 1, 0.9)
end)
debugToggle:SetScript("OnLeave", function(self)
    applyDebugToggleState()
end)

local clearSyncBtn = CreateFrame("Button", nil, maintenanceFrame, "BackdropTemplate")
clearSyncBtn:SetSize(180, 36)
clearSyncBtn:SetPoint("TOPLEFT", debugToggle, "BOTTOMLEFT", 0, -12)
clearSyncBtn:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
clearSyncBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
clearSyncBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local clearSyncText = clearSyncBtn:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(clearSyncText, 13, "")
clearSyncText:SetPoint("CENTER")
clearSyncText:SetText("Clear Synced Players")
clearSyncText:SetTextColor(1, 1, 1)

clearSyncBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0, 0.5, 1, 0.9)
end)
clearSyncBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end)
local clearSyncConfirm = GT.UI:CreateConfirmPopup(
    "This will remove all synced player data.\nAre you sure?",
    function()
        local myID = GT.DB.uniqueID
        for uid in pairs(GT.DB.players or {}) do
            if uid ~= myID then GT.DB.players[uid] = nil end
        end
    end
)

clearSyncBtn:SetScript("OnClick", function() clearSyncConfirm:Show() end)

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
    GT.Core:DebugPrint("Maintenance: PLAYER_LOGIN, debug mode =", tostring(GT.Debug))
    applyDebugToggleState()
end)
