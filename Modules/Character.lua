local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

local db
function Character:Init(database)
    db = database
    if not db then return end
end

function Character:GetFullName()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function Character:FetchCurrentCharacterStats()
    local charData = {}

    local avgItemLevel = GetAverageItemLevel()
    charData.iLvl = avgItemLevel and math.floor(avgItemLevel) or 0
    local factionName, factionLocalized = UnitFactionGroup("player")
    charData.faction = factionName or "Neutral"


    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local specID, specName, _, _, role = GetSpecializationInfo(specIndex)
        charData.specName = GT.Modules.Data.SPEC_ID_TO_ENGLISH_NAME[specID]
        charData.role = role
    else
        charData.specName, charData.role = "No Spec", nil
    end
    local className, _, classId = UnitClass("player")
    charData.className = GT.Modules.Data.CLASS_ID_TO_ENGLISH_NAME[classId]
    charData.classId = classId

    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    charData.rating = (ratingSummary and ratingSummary.currentSeasonScore) or 0

    self:UpdateKeystone(charData)

    return charData
end

function Character:UpdateKeystone(charData)
    if not charData then return end
    charData.keystone = charData.keystone or {}
    local keyData = charData.keystone

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
	keyData.noKeyForBoostForBoost = false

    if keystoneLevel then
        keyData.level = keystoneLevel
        keyData.mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        keyData.mapName = keyData.mapID and GT.Modules.Data.DUNGEON_TABLE[keyData.mapID].name or "Unknown"
    else
        keyData.level, keyData.mapID, keyData.mapName = nil, nil, nil
    end
end

function Character:SetCharacterCustomRoles(bnet, charFullName, roles)
    if not db.global.player[bnet] then return end

    db.global.player[bnet].char = db.global.player[bnet].char or {}
    db.global.player[bnet].char[charFullName] = db.global.player[bnet].char[charFullName] or {}
    db.global.player[bnet].char[charFullName].customRoles = roles
end

function Character:SetCharacternoKeyForBoostStatus(bnet, charFullName, noKeyForBoost)
    if not db.global.player[bnet] or not db.global.player[bnet].char or not db.global.player[bnet].char[charFullName] or not db.global.player[bnet].char[charFullName].keystone then return end

    db.global.player[bnet].char[charFullName].keystone.noKeyForBoost = noKeyForBoost
end

function Character:GetCharacternoKeyForBoostStatus(bnet, charFullName)
    if not db.global.player[bnet] or not db.global.player[bnet].char or not db.global.player[bnet].char[charFullName] or not db.global.player[bnet].char[charFullName].keystone then return end

    return db.global.player[bnet].char[charFullName].keystone.noKeyForBoost
end

function Character:GetCharacterData(bnet, charFullName)
    if db.global.player[bnet] and db.global.player[bnet].char and db.global.player[bnet].char[charFullName] then
        return db.global.player[bnet].char[charFullName]
    end
end

function Character:GetAllCharactersForPlayer(bnet)
    return db.global.player[bnet].char or {}
end

function Character:SetCharacterData(bnet, charFullName, dataTable)
    if not db.global.player[bnet] then return end

    db.global.player[bnet].char = db.global.player[bnet].char or {}
	db.global.player[bnet].char[charFullName] = db.global.player[bnet].char[charFullName] or {}
    dataTable.customRoles = db.global.player[bnet].char[charFullName].customRoles or {}
    db.global.player[bnet].char[charFullName] = dataTable
end
