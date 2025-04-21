local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

local db
local Utils
function Character:Init(database)
    db = database
    if not db then return end

    Utils = GT.Modules.Utils
    if not Utils then return end
end

local function GetOrCreateCharacterData(bnet, fullName)
    if not db or not db.global.players then return nil end

    db.global.players[bnet] = db.global.players[bnet] or {}
    db.global.players[bnet].characters = db.global.players[bnet].characters or {}
    db.global.players[bnet].characters[fullName] = db.global.players[bnet].characters[fullName] or {}
    return db.global.players[bnet].characters[fullName]
end

local function GetOrCreateCharacterCustomData(bnet, charFullName)
    local charData = GetOrCreateCharacterData(bnet, charFullName)
    if not charData then return nil end
    charData.custom = charData.custom or {}
    return charData.custom
end

local function UpdateKeystone(charData)
    if not charData then return end
    charData.keystone = charData.keystone or {}
    local keyData = charData.keystone

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()

    if keystoneLevel then
        keyData.level = keystoneLevel
        keyData.mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        keyData.mapName = keyData.mapID and GT.Modules.Data.DUNGEON_TABLE[keyData.mapID].name or "Unknown"
    else
        keyData.level, keyData.mapID, keyData.mapName = nil, nil, nil
    end
end

function Character:GetFullName(unit)
    local fullName = nil
    if UnitExists(unit) then
        local name, realm = UnitName(unit)
        if name then
            if not (realm and realm ~= "") then
                realm = GetRealmName()
            end
            fullName = name .. "-" .. realm
        end
    end
    return fullName
end

function Character:FetchCurrentCharacterStats()
    local charData = {}

    local avgItemLevel = GetAverageItemLevel()
    charData.iLvl = avgItemLevel and math.floor(avgItemLevel) or 0
    local factionName, _ = UnitFactionGroup("player")
    charData.faction = factionName or "Neutral"


    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local specID, _, _, _, role = GetSpecializationInfo(specIndex)
        charData.specId = specID
        charData.role = role
    else
        charData.specId, charData.role = nil, nil
    end
    local _, _, classId = UnitClass("player")
    charData.classId = classId

    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    charData.rating = (ratingSummary and ratingSummary.currentSeasonScore) or 0

    UpdateKeystone(charData)

    return charData
end

function Character:SetCharacterData(bnet, fullName, dataTable)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        for key, value in pairs(dataTable) do
            if key ~= "custom" then
                character[key] = value
            end
        end
    end
end

function Character:GetCharacterCustomRoles(bnet, fullName)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        return customData.roles or {}
    end
    return {}
end

function Character:SetCharacterCustomRoles(bnet, fullName, roles)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.roles = roles
    end
end

function Character:SetCharacterHasKey(bnet, fullName, hasKey)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.hasKey = hasKey
        Utils:DebugPrint("SetCharacterHasKey", bnet, fullName, tostring(hasKey))
    end
end

function Character:GetCharacterHasKey(bnet, fullName)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        return customData.hasKey or false
    end
    return true
end

function Character:SetCharacterIsHidden(bnet, fullName, isHidden)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.isHidden = isHidden
    end
end

function Character:GetCharacterIsHidden(bnet, fullName)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        return customData.isHidden or false
    end
    return false
end

function Character:GetCharacterKeystone(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    local keystone = {
        level = nil,
        mapID = nil,
        mapName = nil
    }
    if character and character.keystone then
        keystone.level = character.keystone.level
        keystone.mapID = character.keystone.mapID
        keystone.mapName = character.keystone.mapName
    end
    return keystone
end

function Character:GetCharacterRating(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.rating or 0
    end
    return 0
end

function Character:SetCharacterRating(bnet, fullName, rating)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.rating = rating
    end
end

function Character:GetCharacterClassId(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.classId or nil
    end
    return nil
end

function Character:SetCharacterClassId(bnet, fullName, classId)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.classId = classId
    end
end

function Character:GetCharacterSpecId(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.specId or nil
    end
    return nil
end

function Character:SetCharacterSpecId(bnet, fullName, specId)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.specId = specId
    end
end

function Character:GetCharacterRole(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.role or nil
    end
    return nil
end

function Character:SetCharacterRole(bnet, fullName, role)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.role = role
    end
end

function Character:GetCharacterFaction(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.faction or nil
    end
    return nil
end

function Character:SetCharacterFaction(bnet, fullName, faction)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.faction = faction
    end
end

function Character:GetCharacterIlvl(bnet, fullName)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        return character.iLvl or 0
    end
    return 0
end

function Character:SetCharacterIlvl(bnet, fullName, ilvl)
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.iLvl = ilvl
    end
end