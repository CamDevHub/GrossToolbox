--[[-----------------------------------------------------------------------------
Icon Widget
-------------------------------------------------------------------------------]]
local Type, Version = "InsecureIcon", 21
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs, print = select, pairs, print

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetHeight(110)
		self:SetWidth(110)
		self:SetBottomLabel()
		self:SetTopLabel()
		self:SetImage(nil)
		self:SetImageSize(64, 64)
		self:SetDisabled(false)
	end,

	-- ["OnRelease"] = nil,

	["SetBottomLabel"] = function(self, text)
		if text and text ~= "" then
			self.bottomLabel:Show()
			self.bottomLabel:SetText(text)
			self:SetHeight(self.image:GetHeight() + 25)
		else
			self.bottomLabel:Hide()
			self:SetHeight(self.image:GetHeight() + 10)
		end
	end,

	["SetTopLabel"] = function(self, text)
		if text and text ~= "" then
			self.topLabel:Show()
			self.topLabel:SetText(text)
			self:SetHeight(self.image:GetHeight() + 25)
		else
			self.topLabel:Hide()
			self:SetHeight(self.image:GetHeight() + 10)
		end
	end,

	["SetImage"] = function(self, path, ...)
		local image = self.image
		image:SetTexture(path)

		if image:GetTexture() then
			local n = select("#", ...)
			if n == 4 or n == 8 then
				image:SetTexCoord(...)
			else
				image:SetTexCoord(0, 1, 0, 1)
			end
		end
	end,

	["SetImageSize"] = function(self, width, height)
		self.image:SetWidth(width)
		self.image:SetHeight(height)
		--self.frame:SetWidth(width + 30)
		if self.bottomLabel:IsShown() then
			self:SetHeight(height + 25)
		else
			self:SetHeight(height + 10)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
			self.bottomLabel:SetTextColor(0.5, 0.5, 0.5)
			self.topLabel:SetTextColor(0.5, 0.5, 0.5)
			self.image:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		else
			self.frame:Enable()
			self.bottomLabel:SetTextColor(1, 1, 1)
			self.topLabel:SetTextColor(1, 1, 1)
			self.image:SetVertexColor(1, 1, 1, 1)
		end
	end,

	["SetSecureAction"] = function(self, actionType, actionData, unit)
		self.frame:SetAttribute("type", actionType)
		self.frame:SetAttribute("unit", unit)
		if actionType == "spell" then
			self.frame:SetAttribute("spell", actionData)
		elseif actionType == "item" then
			self.frame:SetAttribute("item", actionData)
		end
	end,

	["SetScript"] = function(self, script, func)
		self.frame:SetScript(script, func)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AceGUI30SecureButton" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent, "InsecureActionButtonTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:RegisterForClicks("AnyUp", "AnyDown")

	local topLabel = frame:CreateFontString(nil, "BACKGROUND", "SystemFont_Shadow_Large_Outline")
	topLabel:SetPoint("TOPLEFT")
	topLabel:SetPoint("TOPRIGHT")
	topLabel:SetJustifyH("CENTER")
	topLabel:SetJustifyV("BOTTOM")
	topLabel:SetHeight(25)

	local bottomLabel = frame:CreateFontString(nil, "BACKGROUND", "SystemFont_Shadow_Large_Outline")
	bottomLabel:SetPoint("BOTTOMLEFT")
	bottomLabel:SetPoint("BOTTOMRIGHT")
	bottomLabel:SetJustifyH("CENTER")
	bottomLabel:SetJustifyV("TOP")
	bottomLabel:SetHeight(18)

	local image = frame:CreateTexture(nil, "BACKGROUND")
	image:SetWidth(64)
	image:SetHeight(64)
	image:SetPoint("TOP", 0, -5)

	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(image)
	highlight:SetTexture(136580) -- Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight
	highlight:SetTexCoord(0, 1, 0.23, 0.77)
	highlight:SetBlendMode("ADD")

	local widget = {
		bottomLabel = bottomLabel,
		topLabel = topLabel,
		image = image,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	widget.SetText = function(self, ...) print("AceGUI-3.0-Icon: SetText is deprecated! Use SetLabel instead!"); self:SetLabel(...) end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
