local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

local db

local function GetOrCreateCharacterData(bnet, fullName)
    if not db or not db.global.players then return nil end
    db.global.player[bnet] = db.global.player[bnet] or {}
    db.global.player[bnet].characters = db.global.player[bnet].characters or {}
    db.global.player[bnet].characters[fullName] = db.global.player[bnet].characters[fullName] or {}
    return db.global.player[bnet].characters[fullName]
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

function Character:Init(database)
    db = database
    if not db then return end
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
        charData.specName = GT.Modules.Data.SPEC_ID_TO_ENGLISH_NAME[specID]
        charData.role = role
    else
        charData.specName, charData.role = "No Spec", nil
    end
    local _, _, classId = UnitClass("player")
    charData.className = GT.Modules.Data.CLASS_ID_TO_ENGLISH_NAME[classId]
    charData.classId = classId

    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    charData.rating = (ratingSummary and ratingSummary.currentSeasonScore) or 0

    UpdateKeystone(charData)

    return charData
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

function Character:SetCharacterNoKeyForBoostStatus(bnet, fullName, isNoKey)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.noKey = isNoKey
    end
end

function Character:GetCharacterNoKeyForBoostStatus(bnet, fullName)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        return customData.noKey or false
    end
    return false
end

function Character:SetCharacterHideStatus(bnet, fullName, isHidden)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.hidden = isHidden
    end
end

function Character:GetCharacterHideStatus(bnet, fullName)
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        return customData.hidden or false
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
