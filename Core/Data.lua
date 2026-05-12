local AddonName, GT = ...

GT.Data.CLASS_TO_ARMOR = {
    MAGE        = "Cloth",
    PRIEST      = "Cloth",
    WARLOCK     = "Cloth",
    DRUID       = "Leather",
    DEMONHUNTER = "Leather",
    MONK        = "Leather",
    ROGUE       = "Leather",
    EVOKER      = "Mail",
    HUNTER      = "Mail",
    SHAMAN      = "Mail",
    DEATHKNIGHT = "Plate",
    PALADIN     = "Plate",
    WARRIOR     = "Plate",
}

GT.Data.ARMOR_ORDER = { "Cloth", "Leather", "Mail", "Plate" }

GT.Data.ROLES = {
    TANK    = ":Tank:",
    HEALER  = ":healer:",
    DAMAGER = ":DPS:",
}

GT.Data.CLASS_NAMES = {
    warrior     = "Warrior",
    paladin     = "Paladin",
    hunter      = "Hunter",
    rogue       = "Rogue",
    priest      = "Priest",
    deathknight = "Death Knight",
    shaman      = "Shaman",
    mage        = "Mage",
    warlock     = "Warlock",
    monk        = "Monk",
    druid       = "Druid",
    demonhunter = "Demon Hunter",
    evoker      = "Evoker",
}

GT.Data.NUMBER_SIGN = {
    [1] = "Solo",
    [2] = "Duo",
    [3] = "Trio",
    [4] = "Quad",
    [5] = "Penta",
}

GT.Data.DUNGEON_ORDER = { 239, 556, 161, 557, 558, 559, 560, 402 }
GT.Data.DUNGEONS = {
    -- Midnight Season 1
    [239]  = { iconId = 1711340, spellId = 1254551, short = "Seat", name = "Seat of the Triumvirat" },
    [556]  = { iconId = 343641, spellId = 1254555, short = "PoS",  name = "Pit of Saron"           },
    [161]  = { iconId = 1002596, spellId = 159898,  short = "Sky",  name = "Skyreach"               },
    [557]  = { iconId = 7266215, spellId = 1254400, short = "WS",   name = "Windrunner Spire"        },
    [558]  = { iconId = 7439625, spellId = 1254572, short = "MT",   name = "Magisters' Terrace"      },
    [559]  = { iconId = 7553062, spellId = 1254563, short = "NPX",  name = "Nexus Point Arena"       },
    [560]  = { iconId = 7322719, spellId = 1254559, short = "MC",   name = "Maisara Cavern"          },
    [402]  = { iconId = 4578414, spellId = 393273,  short = "AA",   name = "Algethar Academy"        },
}

-- Reads WoW API values and writes the current character into GT.DB.players.
local function UpdateCurrentCharacter()
    local uniqueID = GT.DB.uniqueID
    if not uniqueID then return end

    local charNameDisplay = UnitName("player")
    local charName        = charNameDisplay:lower()
    local server          = GetRealmName() or ""

    local _, race    = UnitRace("player")
    local _, class   = UnitClass("player")
    local _, faction = UnitFactionGroup("player")

    local specName = ""
    local specRole = ""
    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local _, name, _, _, role = GetSpecializationInfo(specIndex)
        specName = name and name:lower() or ""
        specRole = role or ""
    end

    local _, ilvlEquipped = GetAverageItemLevel()

    local mpRating = 0
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local mpInfo = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        mpRating = mpInfo and math.floor(mpInfo.currentSeasonScore or 0) or 0
    end

    if mpRating == 0 then return end

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
    local mapID         = C_MythicPlus.GetOwnedKeystoneChallengeMapID() or 0

    GT.DB.players[uniqueID]          = GT.DB.players[uniqueID]          or {}
    GT.DB.players[uniqueID].chars    = GT.DB.players[uniqueID].chars    or {}
    GT.DB.players[uniqueID].lastSeen = time()

    -- Preserve user-edited fields; only build defaults on first write
    local existing = GT.DB.players[uniqueID].chars[charName]
    local roles = (existing and existing.roles) or {
        tank = (specRole == "TANK"),
        heal = (specRole == "HEALER"),
        dps  = (specRole == "DAMAGER"),
    }

    GT.DB.players[uniqueID].chars[charName] = {
        name           = charNameDisplay,
        server         = server,
        ilvl           = math.floor(ilvlEquipped or 0),
        faction        = faction and faction:lower() or "",
        race           = race    and race:lower()    or "",
        class          = class   and class:lower()   or "",
        specialisation = specName,
        mpRating       = mpRating,
        keystone       = { level = keystoneLevel, challengeId = mapID },
        roles          = roles,
        hideFromTag    = existing and existing.hideFromTag or false,
        forceNoKey     = existing and existing.forceNoKey  or false,
    }
end

local PRUNE_DAYS = 30

local function PruneStaleEntries()
    local cutoff = time() - PRUNE_DAYS * 86400
    local myID   = GT.DB.uniqueID
    for uid, entry in pairs(GT.DB.players or {}) do
        if uid ~= myID and (entry.lastSeen or 0) < cutoff then
            GT.DB.players[uid] = nil
        end
    end
end

local function UpdateVaultData()
    local uniqueID = GT.DB.uniqueID
    if not uniqueID then return end

    local charName = UnitName("player"):lower()
    local entry = GT.DB.players[uniqueID]
    if not entry or not entry.chars or not entry.chars[charName] then return end

    local function extractSlots(actType)
        local slots = {}
        for _, act in ipairs(C_WeeklyRewards.GetActivities(actType) or {}) do
            table.insert(slots, { threshold = act.threshold, progress = act.progress })
        end
        return slots
    end

    local dungeons = extractSlots(Enum.WeeklyRewardChestThresholdType.Activities)
    local raid     = extractSlots(Enum.WeeklyRewardChestThresholdType.Raid)

    -- If both are empty the API data isn't ready yet; preserve existing vault
    if #dungeons == 0 and #raid == 0 then return end

    entry.chars[charName].vault = { dungeons = dungeons, raid = raid }
end

local dataFrame = CreateFrame("Frame")
dataFrame:RegisterEvent("PLAYER_LOGIN")
dataFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
dataFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
dataFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
dataFrame:SetScript("OnEvent", function(_, event)
    GT.Core:DebugPrint("Data: event fired:", event)
    if event == "PLAYER_LOGIN" then
        PruneStaleEntries()
        C_Timer.After(1, function()
            UpdateCurrentCharacter()
            UpdateVaultData()
        end)
    elseif event == "WEEKLY_REWARDS_UPDATE" then
        UpdateVaultData()
    else
        UpdateCurrentCharacter()
    end
end)
