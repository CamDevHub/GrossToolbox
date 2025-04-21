local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Config = {}
GT.Modules.Config = Config

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local C_BattleNet = C_BattleNet -- For GUID lookup

local db
function Config:SetupOptions()
    if not db then
        return
    end

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
                desc = "Set your team or guild tag",
                width = "full",
                get = function()
                    return db.global.config.discordTag or ""
                end,
                set = function(_, val)
                    db.global.config.discordTag = val
                    local guid = C_BattleNet.GetAccountInfoByGUID(UnitGUID("player")).battleTag
                    if guid then
                        db.global.player = db.global.player or {}
                        db.global.player[guid] = db.global.player[guid] or { name = UnitName("player"), char = {} }
                        db.global.player[guid].discordTag = val
                    end
                end
            },
            screenshotOnMPlusEnd = {
                order = 12, -- Adjust order as needed
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
            -- Reset Button
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
    db = database
    self:SetupOptions()
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
