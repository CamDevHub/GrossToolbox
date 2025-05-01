local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Config = {}
GT.Modules.Config = Config

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local Player = GT.Modules.Player

local db
function Config:SetupOptions()
    if not db then
        return
    end

    -- Initial character list at load time
    local characters = {}
    local selectedChar = nil
    local battleTag = Player:GetBNetTagForUnit("player")
    local options = {
        name = addonName,
        type = "group",
        args = {
            keystoneHeader = {
                order = 10,
                type = "header",
                name = "Keystone Options",
            },
            guildTag = {
                order = 11,
                type = "input",
                name = "Discord Tag",
                desc = "Set your discord tag",
                width = "full",
                get = function()
                    return db.global.config.discordTag or ""
                end,
                set = function(_, val)
                    db.global.config.discordTag = val
                    local bnet = Player:GetBNetTagForUnit("player")
                    if bnet then
                        db.global.player = db.global.player or {}
                        db.global.player[bnet] = db.global.player[bnet] or { name = UnitName("player"), char = {} }
                        db.global.player[bnet].discordTag = val
                    end
                end
            },
            screenshotOnMPlusEnd = {
                order = 12,
                type = "toggle",
                name = "Screenshot on M+ End",
                desc = "Take a screenshot automatically at the end of a Mythic+ dungeon.",
                get = function()
                    return db.global.config.screenshotOnMPlusEnd
                end,
                set = function(_, val)
                    db.global.config.screenshotOnMPlusEnd = val
                end
            },

            -- Character Management Section
            characterHeader = {
                order = 60,
                type = "header",
                name = "Character Management",
            },
            characterDesc = {
                order = 61,
                type = "description",
                name = "Select a character to remove from the database.",
                fontSize = "medium",
            },
            characterSelect = {
                order = 62,
                type = "select",
                name = "Select Character",
                desc = "Choose a character to delete",
                values = function()
                    -- Refresh character list each time dropdown is opened
                    battleTag = Player:GetBNetTagForUnit("player")
                    characters = Player:GetCharactersForPlayer(battleTag)

                    -- Format list for dropdown
                    local charDropdown = {}
                    for charName, _ in pairs(characters) do
                        charDropdown[charName] = charName
                    end

                    if not next(charDropdown) then
                        charDropdown[""] = "No characters found"
                    end

                    return charDropdown
                end,
                get = function() return selectedChar end,
                set = function(_, val) selectedChar = val end,
                width = 1.5,
            },
            deleteChar = {
                order = 63,
                type = "execute",
                name = "Delete Character",
                desc = "Delete this character and all associated data",
                func = function()
                    print("|cFFFF0000Deleting character: " .. selectedChar .. "|r")
                    if selectedChar and selectedChar ~= "" then
                            if db.global.players and db.global.players[battleTag] and
                                db.global.players[battleTag].characters and
                                db.global.players[battleTag].characters[selectedChar] then
                                -- Remove character data
                                db.global.players[battleTag].characters[selectedChar] = nil

                                -- Show confirmation message
                                print("|cFF00FF00" .. selectedChar .. " has been deleted from GrossToolbox.|r")

                                -- Reset selected character
                                selectedChar = nil
                            end
                    else
                        print("|cFFFF0000Please select a character first.|r")
                    end
                end,
                width = 1.5,
                disabled = function()
                    return selectedChar == nil or selectedChar == ""
                end,
                confirm = true,
                confirmText = "Are you sure you want to delete " ..
                    (selectedChar or "this character") .. "? This cannot be undone!",
            },
            refreshCharList = {
                order = 64,
                type = "execute",
                name = "Refresh Character List",
                desc = "Refresh the list of available characters",
                func = function()
                    battleTag = Player:GetBNetTagForUnit("player")
                    -- Refresh character list
                    characters = Player:GetCharactersForPlayer(battleTag)
                    -- Force options refresh
                    AceConfigRegistry:NotifyChange(addonName)
                    print("|cFF00FF00Character list refreshed.|r")
                end,
                width = 3,
            },

            -- Danger Zone Header
            resetHeader = {
                order = 90,
                type = "header",
                name = "Danger Zone",
            },
            resetDesc = {
                order = 91,
                type = "description",
                name =
                "Warning: Resetting the database will clear ALL stored player and character data for GrossToolbox.",
                fontSize = "medium",
            },
            resetDB = {
                order = 92,
                type = "execute",
                name = "Reset Database",
                desc = "Completely wipes all stored GrossToolbox data.",
                func = function()
                    db:ResetDB(true)
                    local CharInfo = GT.Modules and GT.Modules.CharacterInfo
                    if CharInfo and CharInfo.displayFrame and CharInfo.displayFrame:IsShown() then
                        CharInfo:PopulateDisplayFrame()
                    end
                end,
                confirm = true,
                confirmText = "Are you absolutely sure you want to wipe ALL GrossToolbox data? This cannot be undone!"
            }
        }
    }

    -- Register the options within this module
    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, addonName)
end

function Config:Init(database)
    -- Validate database parameter
    if not database then
        print(addonName .. ": Config module initialization failed - missing database")
        return false
    end

    -- Store database reference
    db = database

    -- Initialize config structure if needed
    if not db.global then
        db.global = {}
    end

    if not db.global.config then
        db.global.config = {}
    end

    -- Setup options
    self:SetupOptions()

    -- Load Utils module if available
    local Utils = GT.Modules.Utils
    if Utils then
        Utils:DebugPrint("Config module initialized successfully")
    else
        print(addonName .. ": Config module initialized successfully")
    end

    return true
end

function Config:GetDiscordTag()
    if db and db.global and db.global.config and db.global.config.discordTag then
        return db.global.config.discordTag
    end
    return nil
end

function Config:GetScreenshotOnMPlusEnd()
    if db and db.global and db.global.config and db.global.config.screenshotOnMPlusEnd then
        return db.global.config.screenshotOnMPlusEnd
    end
    return false
end

function Config:GetLastOpenedTabValue()
    if db and db.global and db.global.lastTab then
        return db.global.config.lastTab
    end
    return false
end

function Config:SetLastOpenedTabValue(tabValue)
    if db and db.global and db.global.lastTab then
        db.global.config.lastTab = tabValue
    end
end
