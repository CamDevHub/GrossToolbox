local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

local db
local Data, Utils
function Character:Init(database)
    db = database
    if not db then return end

    Data = GT.Modules.Data
    if not Data then return end

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
    charData.custom = charData.custom or {
        roles = {},
        hasKey = true,
        isHidden = false
    }
    return charData.custom
end

local function GetKeystone()
    local keystone = {}
    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if keystoneLevel then
        keystone.level = keystoneLevel
        keystone.mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        keystone.mapName = keystone.mapID and Data.DUNGEON_TABLE[keystone.mapID].name or "Unknown"
    else
        keystone.level, keystone.mapID, keystone.mapName = nil, nil, nil
    end

    return keystone
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

function Character:BuildCurrentCharacter(bnet, fullName)
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

    self:SetCharacterData(bnet, fullName, charData)
    self:SetCharacterKeystone(bnet, fullName, GetKeystone())
end

function Character:SetCharacterData(bnet, fullName, dataTable)
    if not db then return end

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
    local roles = {}
    if not db then return roles end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData and customData.roles then
        roles = { unpack(customData.roles) }
    end
    return roles
end

function Character:SetCharacterCustomRoles(bnet, fullName, roles)
    if not db then return end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.roles = roles
    end
end

function Character:SetCharacterHasKey(bnet, fullName, hasKey)
    if not db then return end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.hasKey = hasKey
    end
end

function Character:GetCharacterHasKey(bnet, fullName)
    local hasKey = false
    if not db then return hasKey end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        hasKey = customData.hasKey or false
    end
    return hasKey
end

function Character:SetCharacterIsHidden(bnet, fullName, isHidden)
    if not db then return end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        customData.isHidden = isHidden
    end
end

function Character:GetCharacterIsHidden(bnet, fullName)
    local isHidden = false
    if not db then return isHidden end

    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if customData then
        isHidden = customData.isHidden or false
    end
    return isHidden
end

function Character:GetCharacterKeystone(bnet, fullName)
    local keystone = nil
    if not db then return keystone end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character and character.keystone then
        keystone = {}
        keystone.level = character.keystone.level
        keystone.mapID = character.keystone.mapID
        keystone.mapName = character.keystone.mapName
    end
    return keystone
end

function Character:SetCharacterKeystone(bnet, fullName, keystone)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.keystone = {
            level = keystone.level,
            mapID = keystone.mapID,
            mapName = keystone.mapName
        }
    end
end

function Character:GetCharacterRating(bnet, fullName)
    local rating = 0
    if not db then return rating end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        rating = character.rating or 0
    end
    return rating
end

function Character:SetCharacterRating(bnet, fullName, rating)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.rating = rating
    end
end

function Character:GetCharacterClassId(bnet, fullName)
    local classId = 0
    if not db then return classId end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        classId = character.classId
    end
    return classId
end

function Character:SetCharacterClassId(bnet, fullName, classId)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.classId = classId
    end
end

function Character:GetCharacterSpecId(bnet, fullName)
    local specId = 0
    if not db then return specId end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        specId = character.specId or 0
    end
    return specId
end

function Character:SetCharacterSpecId(bnet, fullName, specId)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.specId = specId
    end
end

function Character:GetCharacterRole(bnet, fullName)
    local role = nil
    if not db then return role end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        role = character.role or nil
    end
    return role
end

function Character:SetCharacterRole(bnet, fullName, role)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.role = role
    end
end

function Character:GetCharacterFaction(bnet, fullName)
    local faction = nil
    if not db then return faction end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        faction = character.faction or nil
    end
    return faction
end

function Character:SetCharacterFaction(bnet, fullName, faction)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.faction = faction
    end
end

function Character:GetCharacterIlvl(bnet, fullName)
    local ilvl = 0
    if not db then return ilvl end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        ilvl = character.iLvl or 0
    end
    return ilvl
end

function Character:SetCharacterIlvl(bnet, fullName, ilvl)
    if not db then return end

    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.iLvl = ilvl
    end
end
