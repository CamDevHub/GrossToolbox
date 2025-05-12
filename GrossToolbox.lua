-- Core.lua

local addonName, GT = ...
if not GT then
    print("Error: GT table not found!"); return
end

-- Get Ace libraries using LibStub
local AceAddon = LibStub:GetLibrary("AceAddon-3.0")
local AceDB = LibStub:GetLibrary("AceDB-3.0")

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
        reminders = {},
        lastTab = "",
        uid = "",
        anchors = {}
    }
}

local Utils, Player, Character, GrossFrame, Dawn, Weekly, Reminders
function addon:OnInitialize()
    self.db = AceDB:New("GrossToolboxDB", defaults)

    -- Get Utils for debug logging
    Utils = GT.Core.Utils
    if not Utils then
        print(addonName .. ": Critical error - Utils module not found")
        return
    end

    Config = GT.Core.Config
    if not Config then
        print(addonName .. ": Critical error - Config module not found")
        return
    else
        Config:Init(self.db)
        LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 600, 500)
    end

    Character = GT.Core.Character
    if not Character then
        print(addonName .. ": Critical error - Character module not found")
        return
    else
        Character:Init(self.db)
    end

    Player = GT.Core.Player
    if not Player then
        print(addonName .. ": Critical error - Player module not found")
        return
    else
        Player:Init(self.db)
    end

    GrossFrame = GT.Modules.GrossFrame
    if not GrossFrame then
        print(addonName .. ": Critical error - GrossFrame module not found")
        return
    else
        GrossFrame:Init()
    end

    Dawn = GT.Modules.Dawn
    if not Dawn then
        print(addonName .. ": Critical error - Dawn module not found")
        return
    else
        Dawn:Init()
    end

    Weekly = GT.Modules.Weekly
    if not Weekly then
        print(addonName .. ": Critical error - Weekly module not found")
        return
    else
        Weekly:Init()
    end

    Reminders = GT.Modules.Reminders
    if not Reminders then
        print(addonName .. ": Critical error - Reminders module not found")
        return
    else
        Reminders:Init(self.db)
    end

    -- Register slash command
    self:RegisterChatCommand("gt", "SlashCommandHandler")

    -- Register events using AceEvent, modules can register their own handlers
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("READY_CHECK")
    self:RegisterEvent("READY_CHECK_FINISHED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_UPDATE_RESTING")

    -- Register messages for modules to listen to
    self:RegisterMessage("GROSSTOOLBOX_OPENED")
    self:RegisterMessage("GROSSTOOLBOX_CLOSED")

    Utils:DebugPrint("Initialization complete")
end

function addon:PLAYER_UPDATE_RESTING(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.PLAYER_UPDATE_RESTING) == "function" then
                mod:PLAYER_UPDATE_RESTING(event, ...)
            end
        end
    end
end

function addon:GROSSTOOLBOX_OPENED(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.GROSSTOOLBOX_OPENED) == "function" then
                mod:GROSSTOOLBOX_OPENED(event, ...)
            end
        end
    end
end

function addon:GROSSTOOLBOX_CLOSED(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.GROSSTOOLBOX_CLOSED) == "function" then
                mod:GROSSTOOLBOX_CLOSED(event, ...)
            end
        end
    end
end

function addon:BAG_UPDATE_DELAYED(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.BAG_UPDATE_DELAYED) == "function" then
                mod:BAG_UPDATE_DELAYED(event, ...)
            end
        end
    end
end

-- Called when PLAYER_ENTERING_WORLD fires
function addon:PLAYER_ENTERING_WORLD(event, ...)
    C_Timer.After(3, function()
        self:UpdateData()
    end)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.PLAYER_ENTERING_WORLD) == "function" then
                mod:PLAYER_ENTERING_WORLD(event, ...)
            end
        end
    end
end

-- Called when CHALLENGE_MODE_COMPLETED fires
function addon:CHALLENGE_MODE_COMPLETED(event, ...)
    if Config:GetScreenshotOnMPlusEnd() then
        C_Timer.After(2, function()
            Screenshot()
            self:UpdateData()
        end)
    end
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.CHALLENGE_MODE_COMPLETED) == "function" then
                mod:CHALLENGE_MODE_COMPLETED(event, ...)
            end
        end
    end
end

function addon:READY_CHECK(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.READY_CHECK) == "function" then
                mod:READY_CHECK(event, ...)
            end
        end
    end
end

function addon:READY_CHECK_FINISHED(event, ...)
    -- Dispatch to modules that registered for this event
    if GT.Modules then
        for _, mod in pairs(GT.Modules) do
            if type(mod.READY_CHECK_FINISHED) == "function" then
                mod:READY_CHECK_FINISHED(event, ...)
            end
        end
    end
end

local function UpdateCurrentCharacterInfo(uid, fullName)
    Player:SetDiscordTag(uid, Config:GetDiscordTag())
    Character:BuildCurrentCharacter(uid, fullName)
end

function addon:UpdateData()
    if not self.db then return end
    -- Check if we already have a UID, if not generate one
    if not self.db.global.uid or self.db.global.uid == "" then
        local playerName = UnitName("player")
        local identifier = playerName .. "-" .. time()

        self.db.global.uid = identifier
        Utils:DebugPrint("Generated new UID: " .. self.db.global.uid)
    end

    local fullName = Character:GetFullName("player")

    UpdateCurrentCharacterInfo(self.db.global.uid, fullName)
end

-- Function to get the unique identifier for the player
function addon:GetUID()
    if not self.db or not self.db.global then
        return nil
    end
    return self.db.global.uid
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
                    GrossFrame:ToggleMainFrame()
                    local grossFrame = GrossFrame:GetMainFrame()
                    if grossFrame and grossFrame:IsVisible() then
                        self:SendMessage("GROSSTOOLBOX_OPENED")
                    else
                        self:SendMessage("GROSSTOOLBOX_CLOSED")
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

    if command == "" then
        GT.Modules.GrossFrame:ToggleMainFrame()
    elseif command == "config" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    else
        self:Print("Unknown command '" .. command .. "'. Use '/gt' or '/gt config'.")
    end
end
