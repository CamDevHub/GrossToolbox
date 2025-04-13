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

-- Create the main addon object using AceAddon
-- Include mixins for features you want (Events, Slash Commands)
local addon = AceAddon:NewAddon("GrossToolbox", "AceConsole-3.0", "AceEvent-3.0")
GT.addon = addon -- Store addon object reference if modules need it

GT.headers = {}
GT.headers.player = "CHAR_DATA:"
GT.headers.request = "REQ_DATA"
GT.COMM_PREFIX = "GTComm"

-- Define the default structure for your database
local defaults = {
    global = { -- AceDB profile scope "Account" uses 'account' as the root table key
		config = {},
		player = {}
    }
}

-- Called once when the addon initializes
function addon:OnInitialize()
    -- Create the AceDB object linked to your SavedVariables
    -- "GrossToolboxDB" MUST match ## SavedVariables in your .toc
    -- defaults defines the initial structure if the SavedVariables file is empty/new
    -- "Account" makes it save account-wide data
    self.db = AceDB:New("GrossToolboxDB", defaults)

    -- Initialize modules AFTER the DB is ready
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
	
	-- Register configuration options
    local options = {
        name = addonName,
        type = "group",
        args = {
            guildTag = {
                type = "input",
                name = "Discord Tag",
                desc = "Set your team or guild tag",
                width = "full",
                get = function() return self.db.global.config.discordTag or "" end,
                set = function(_, val)
					-- 1. Store in global config (as before)
					self.db.global.config.discordTag = val

					-- 2. ALSO store under the current player's GUID
					local guid = C_BattleNet.GetAccountInfoByGUID(UnitGUID("player")).battleTag
					if guid then
						GT.Modules.Player:UpdateDiscordTagForLocalPlayer(val)

						-- 3. Optional: Refresh the display if it's open
						local Dawn = GT.Modules and GT.Modules.Dawn
						if Dawn and Dawn.displayFrame and Dawn.displayFrame:IsShown() then
							Dawn:PopulateDisplayFrame()
						end
					end
				end
            }
        }
    }

    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, addonName)

    print(addonName .. " Initialized with AceDB.")
end

-- Called when PLAYER_ENTERING_WORLD  fires
function addon:PLAYER_ENTERING_WORLD (event, status)
	print(addonName .. ": Player logged in, updating data...")
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
	print(addonName .. ": M+ run completed, updating data...")
	local Dawn = GT.Modules and GT.Modules.Dawn
	if Dawn then
		Dawn:UpdateData()
	end
end


-- Slash command handler method
function addon:SlashCommandHandler(input)
    local command = string.lower(input or "")
    local Dawn = GT.Modules and GT.Modules.Dawn -- Get module reference

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

print(addonName .. " Core loaded.")