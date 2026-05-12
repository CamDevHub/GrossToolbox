local AddonName, GT = ...
_G["GT"] = GT

GT.Core = {}
GT.Modules = {}
GT.Config = {}
GT.UI = {}
GT.DB    = {}
GT.Data  = {}
GT.Debug = false

SLASH_GROSSTOOLBOX1 = "/gtb"
SlashCmdList["GROSSTOOLBOX"] = function()
    local frame = GT.UI.frame
    if frame then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end
end

local function GenerateID()
    local function seg(n) return string.format("%0"..n.."X", math.random(0, 16^n - 1)) end
    return seg(4).."-"..seg(4).."-"..seg(4).."-"..seg(4)
end

local SCHEMA_VERSION = 1

local function MigrateDB()
    if (GT.DB.schemaVersion or 0) >= SCHEMA_VERSION then return end

    GT.DB.schemaVersion = SCHEMA_VERSION
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, _, name)
    if name ~= AddonName then return end
    GT.Core:DebugPrint("ADDON_LOADED: initializing DB for", name)
    GrossToolboxDB = GrossToolboxDB or {}
    GT.DB = GrossToolboxDB
    if not GT.DB.uniqueID then
        GT.DB.uniqueID = GenerateID()
    end
    GT.DB.players = GT.DB.players or {}
    GT.Debug = GT.DB.debugMode or false
    GT.Config.FONT_PATH = GT.DB.fontPath or "Fonts\\FRIZQT__.TTF"
    MigrateDB()

    -- One-time migration: move root-level discordHandle into the player entry
    if GT.DB.discordHandle and GT.DB.uniqueID then
        local entry = GT.DB.players[GT.DB.uniqueID]
        if entry and not entry.discordHandle then
            entry.discordHandle = GT.DB.discordHandle
        end
        GT.DB.discordHandle = nil
    end

    GT.UI:RefreshFonts()
    GT.loaded = true
end)
