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
        players = {}
    }
}

function addon:OnInitialize()
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

    self:RegisterChatCommand("gt", "SlashCommandHandler")

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

-- Called when PLAYER_ENTERING_WORLD  fires
function addon:PLAYER_ENTERING_WORLD(event, status)
    local Dawn = GT.Modules and GT.Modules.Dawn
    if Dawn then
        C_Timer.After(3, function()
            Dawn:UpdateData()
        end)
    end
end

-- Called when GROUP_ROSTER_UPDATE  fires
function addon:GROUP_ROSTER_UPDATE(event, status)
    local Dawn = GT.Modules and GT.Modules.Dawn
    if Dawn then
        Dawn:UpdateData()
    end
end

-- Called when CHALLENGE_MODE_COMPLETED  fires
function addon:CHALLENGE_MODE_COMPLETED(event, status)
    local Dawn = GT.Modules and GT.Modules.Dawn
    if Dawn then
        Dawn:UpdateData()
    end

    if GT.Modules.Config:GetScreenshotOnMPlusEnd() then
        C_Timer.After(2, function()
            Screenshot()
        end)
    end
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
                    local Dawn = GT.Modules and GT.Modules.Dawn
                    if Dawn then
                        Dawn:UpdateData()
                        Dawn:ToggleFrame()
                    end
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
    local Dawn = GT.Modules and GT.Modules.Dawn

    if not Dawn then
        print(addonName .. ": Dawn module not loaded!"); return
    end

    if command == "refresh" then
        Dawn:UpdateData()
        Dawn:SendCharacterData()
        Dawn:ToggleFrame(true)
    elseif command == "" or command == "dawn" then
        Dawn:ToggleFrame()
    elseif command == "config" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    else
        self:Print("Unknown command '" .. command .. "'. Use '/gt' to toggle display, or '/gt refresh' to update.")
    end
end

AceComm:RegisterComm(GT.COMM_PREFIX, function(prefix, message, distribution, sender)
    GT.Modules.Dawn:OnCommReceived(prefix, message, distribution, sender)
end)
