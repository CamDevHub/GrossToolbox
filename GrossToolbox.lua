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
GT.debug = true

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

    if GT.Modules and GT.Modules.Config and GT.Modules.Config.Init then
        GT.Modules.Config:Init(self.db)
    end

    if GT.Modules and GT.Modules.Player and GT.Modules.Player.Init then
        GT.Modules.Player:Init(self.db)
    end

    if GT.Modules and GT.Modules.Character and GT.Modules.Character.Init then
        GT.Modules.Character:Init(self.db)
    end

    if GT.Modules and GT.Modules.Dungeon and GT.Modules.Dungeon.Init then
        GT.Modules.Dungeon:Init(self.db)
    end

    if GT.Modules and GT.Modules.Dawn and GT.Modules.Dawn.Init then
        GT.Modules.Dawn:Init(self.db)
    end

    self:RegisterChatCommand("gt", "SlashCommandHandler")

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
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
    self:UpdateData()

    if GT.Modules.Config:GetScreenshotOnMPlusEnd() then
        C_Timer.After(2, function()
            Screenshot()
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
                    addon:UpdateData()
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
