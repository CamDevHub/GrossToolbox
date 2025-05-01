-- Core.lua

local addonName, GT = ... 
if not GT then
    print("Error: GT table not found!"); return
end

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
GT.debug = false

-- Define the default structure for your database
local defaults = {
    global = {
        config = {},
        minimap = {
            hide = false,
        },
        players = {},
        lastTab = ""
    }
}

function addon:OnInitialize()
    self.db = AceDB:New("GrossToolboxDB", defaults)
    
    -- Define modules to initialize in the correct dependency order
    local modulesToInitialize = {
        "Config",
        "Character",
        "Player",
        "Dawn",
        "Weekly"
    }
    
    -- Get Utils for debug logging
    local Utils = GT.Modules.Utils
    if not Utils then
        print(addonName .. ": Critical error - Utils module not found")
        return
    end
    
    -- Now initialize the modules with proper debug logging
    for i = 1, #modulesToInitialize do
        local moduleName = modulesToInitialize[i]
        local module = GT.Modules[moduleName]
        if module and type(module.Init) == "function" then
            local success = module:Init(self.db)
            if not success then
                Utils:DebugPrint("Warning - " .. moduleName .. " module initialization failed")
            end
        else
            if not module then
                Utils:DebugPrint("Warning - " .. moduleName .. " module not found")
            elseif type(module.Init) ~= "function" then
                Utils:DebugPrint("Warning - " .. moduleName .. " module missing Init function")
            end
        end
    end
    
    -- Register slash command
    self:RegisterChatCommand("gt", "SlashCommandHandler")
    
    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    Utils:DebugPrint("Initialization complete")
end

-- Called when PLAYER_ENTERING_WORLD  fires
function addon:PLAYER_ENTERING_WORLD(event, status)
    C_Timer.After(3, function()
        self:UpdateData()
    end)
end

-- Called when GROUP_ROSTER_UPDATE  fires
function addon:GROUP_ROSTER_UPDATE(event, status)
    self:UpdateData()
end

-- Called when CHALLENGE_MODE_COMPLETED  fires
function addon:CHALLENGE_MODE_COMPLETED(event, status)
    if GT.Modules.Config:GetScreenshotOnMPlusEnd() then
        C_Timer.After(2, function()
            Screenshot()
            self:UpdateData()
        end)
    end
end

local function UpdateCurrentCharacterInfo(bnet, fullName)
	GT.Modules.Player:SetDiscordTag(bnet, GT.Modules.Config:GetDiscordTag())
	GT.Modules.Character:BuildCurrentCharacter(bnet, fullName)
end

function addon:UpdateData()
    if not self.db then return end

    local bnet = GT.Modules.Player:GetBNetTagForUnit("player")
	local fullName = GT.Modules.Character:GetFullName("player")

    UpdateCurrentCharacterInfo(bnet, fullName)
end

function addon:OnEnable()
    self.icon = self.icon or LibStub("LibDBIcon-1.0")

    if not self.icon:IsRegistered("GrossToolboxIcon") then
        self.icon:Register("GrossToolboxIcon", {
            type = "launcher",
            icon = "Interface\\Icons\\INV_Misc_EngGizmos_17",

            tooltip = "GrossToolbox",
            OnClick = function(frame, button)
                if button == "LeftButton" then
                    self:UpdateData()
                    GT.Modules.GrossFrame:ToggleMainFrame()
                elseif button == "RightButton" then
                    LibStub("AceConfigDialog-3.0"):Open(addonName)
                end
            end,
        }, self.db.global.minimap)
    end
end

-- Slash command handler method
function addon:SlashCommandHandler(input)
    local command = string.lower(input or "")

    if command == ""  then
        GT.Modules.GrossFrame:ToggleMainFrame()
    elseif command == "config" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    else
        self:Print("Unknown command '" .. command .. "'. Use '/gt' or '/gt config'.")
    end
end

AceComm:RegisterComm(GT.COMM_PREFIX, function(prefix, message, distribution, sender)
    GT.Modules.Dawn:OnCommReceived(prefix, message, distribution, sender)
end)
