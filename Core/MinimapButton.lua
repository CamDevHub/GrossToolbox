local AddonName, GT = ...

local RADIUS = 82
local angle = 225 -- degrees, starting position on the minimap ring

local btn = CreateFrame("Button", "GrossToolboxMinimapBtn", Minimap)
btn:SetSize(32, 32)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)

-- Circular mask so it matches the minimap shape
local mask = btn:CreateMaskTexture()
mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints()

local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\Icons\\INV_Misc_Wrench_01")
icon:SetAllPoints()
icon:AddMaskTexture(mask)

-- Thin circular border
local border = btn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(56, 56)
border:SetPoint("CENTER")

local function updatePosition()
    local rad = math.rad(angle)
    btn:SetPoint("CENTER", Minimap, "CENTER", RADIUS * math.cos(rad), RADIUS * math.sin(rad))
end

updatePosition()

-- Drag around the minimap edge
btn:EnableMouse(true)
btn:RegisterForDrag("LeftButton")

btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        angle = math.deg(math.atan2(cy - my, cx - mx))
        updatePosition()
    end)
end)

btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    GT.DB.minimapAngle = angle
end)

-- Restore saved angle on login
local minimapInitFrame = CreateFrame("Frame")
minimapInitFrame:RegisterEvent("PLAYER_LOGIN")
minimapInitFrame:SetScript("OnEvent", function()
    angle = GT.DB.minimapAngle or 225
    GT.Core:DebugPrint("MinimapButton: PLAYER_LOGIN, restoring angle =", angle)
    updatePosition()
end)

-- Toggle main frame
btn:SetScript("OnClick", function()
    local frame = GT.UI.frame
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end)

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("GrossToolbox", 1, 1, 1)
    GameTooltip:Show()
end)

btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
