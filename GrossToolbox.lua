-- Core.lua

local addonName, GT = ... -- GT is global from init.lua
if not GT then print("Error: GT table not found!"); return end

-- Get Ace libraries using LibStub
local AceAddon = LibStub:GetLibrary("AceAddon-3.0")
local AceDB = LibStub:GetLibrary("AceDB-3.0")
local AceEvent = LibStub:GetLibrary("AceEvent-3.0")
local AceConsole = LibStub:GetLibrary("AceConsole-3.0")
local AceComm = LibStub:GetLibrary("AceComm-3.0")
local AceConfig = LibStub:GetLibrary("AceConfig-3.0")
local AceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0")

local addon = AceAddon:NewAddon("GrossToolbox", "AceConsole-3.0", "AceEvent-3.0")
GT.addon = addon

-- Define the default structure for your database
local defaults = {
    global = {
		config = {},
		player = {}
    }
}

function addon:OnInitialize()
    -- Create the AceDB object linked to your SavedVariables
    -- "GrossToolboxDB" MUST match ## SavedVariables in your .toc
    -- defaults defines the initial structure if the SavedVariables file is empty/new
    -- "Account" makes it save account-wide data
    self.db = AceDB:New("GrossToolboxDB", defaults)

    -- Initialize modules AFTER the DB is ready
	if GT.Modules and GT.Modules.Config and GT.Modules.Config.Init then
        GT.Modules.Config:Init(self.db)
    end
	
    if GT.Modules and GT.Modules.Dawn and GT.Modules.Dawn.Init then
        GT.Modules.Dawn:Init(self.db)
    end

	if GT.Modules and GT.Modules.Player and GT.Modules.Player.Init then
        GT.Modules.Player:Init(self.db)
    end
	
	if GT.Modules and GT.Modules.Character and GT.Modules.Character.Init then
        GT.Modules.Character:Init(self.db)
    end

    -- Register slash command
    self:RegisterChatCommand("gt", "SlashCommandHandler")

    -- Register events using AceEvent (if using mixin)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
end

-- Called when PLAYER_ENTERING_WORLD  fires
function addon:PLAYER_ENTERING_WORLD (event, status)
	local Dawn = GT.Modules and GT.Modules.Dawn
	if Dawn then
		-- No timer needed usually, data should be available
		C_Timer.After(2, function()
			Dawn:UpdateData()
		end)
	end
end

-- Called when CHALLENGE_MODE_COMPLETED  fires
function addon:CHALLENGE_MODE_COMPLETED (event, status)
	local Dawn = GT.Modules and GT.Modules.Dawn
	if Dawn then
		Dawn:UpdateData()
	end
end


-- Slash command handler method
function addon:SlashCommandHandler(input)
    local command = string.lower(input or "")
    local Dawn = GT.Modules and GT.Modules.Dawn

    if not Dawn then print(addonName .. ": Dawn module not loaded!"); return end

    if command == "refresh" then
         print(addonName..": Manually refreshing character info...")
         Dawn:UpdateData()
		 Dawn:SendCharacterData()
         Dawn:ToggleFrame(true) -- Force show after refresh
    elseif command == "" or command == "dawn" then -- Handle empty command and "dawn"
         Dawn:ToggleFrame() -- Toggle visibility
	elseif command == "config" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
	elseif command == "request" then
		if IsInGroup() then
			local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
			LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, "REQ_DATA", channel)
			self:Print("Requesting data from party members...")
		else
			self:Print("You must be in a party to request data")
		end
    else
         self:Print("Unknown command '"..command.."'. Use '/gt' to toggle display, or '/gt refresh' to update.") -- Use AceConsole Print
    end
end

AceComm:RegisterComm(GT.COMM_PREFIX, function(prefix, message, distribution, sender)
    GT.Modules.Dawn:OnCommReceived(prefix, message, distribution, sender)
end)