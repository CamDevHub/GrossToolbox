local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

-- Define module name for initialization logging
Character.moduleName = "Character"

-- Define module dependencies
local db
local Data, Utils

function Character:Init(database)
    -- Validate database parameter
    if not database then
        print(addonName .. ": Character module initialization failed - missing database")
        return false
    end
    
    -- Store database reference
    db = database
    
    -- Load Data module
    Data = GT.Modules.Data
    if not Data then
        print(addonName .. ": Character module initialization failed - Data module not found")
        return false
    end
    
    -- Load Utils module
    Utils = GT.Modules.Utils
    if not Utils then
        print(addonName .. ": Character module initialization failed - Utils module not found")
        return false
    end
    
    -- Initialize database structure if needed
    if not db.global then
        db.global = {}
    end
    
    if not db.global.players then
        db.global.players = {}
    end
    
    -- Log successful initialization
    Utils:DebugPrint("Character module initialized successfully")
    return true
end

local function GetOrCreateCharacterData(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetOrCreateCharacterData: Missing required parameters")
        return nil
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("GetOrCreateCharacterData: Database not initialized")
        return nil
    end
    
    -- Ensure global.players table exists
    if not db.global then
        db.global = {}
    end
    
    if not db.global.players then
        db.global.players = {}
    end
    
    -- Create bnet entry if needed
    if not db.global.players[bnet] then
        db.global.players[bnet] = {}
    end
    
    -- Create characters table if needed
    if not db.global.players[bnet].characters then
        db.global.players[bnet].characters = {}
    end
    
    -- Create or return character data
    if not db.global.players[bnet].characters[fullName] then
        db.global.players[bnet].characters[fullName] = {}
    end
    
    return db.global.players[bnet].characters[fullName]
end

local function GetOrCreateCharacterCustomData(bnet, charFullName)
    -- Validate parameters
    if not bnet or not charFullName then
        Utils:DebugPrint("GetOrCreateCharacterCustomData: Missing required parameters")
        return nil
    end
    
    -- Get character data
    local charData = GetOrCreateCharacterData(bnet, charFullName)
    if not charData then
        return nil
    end
    
    -- Create custom data if needed
    if not charData.custom then
        charData.custom = {
            roles = {},
            hasKey = true,
            isHidden = false
        }
    end
    
    -- Ensure all fields exist
    if not charData.custom.roles then
        charData.custom.roles = {}
    end
    
    if charData.custom.hasKey == nil then
        charData.custom.hasKey = true
    end
    
    if charData.custom.isHidden == nil then
        charData.custom.isHidden = false
    end
    
    return charData.custom
end

local function GetKeystone()
    -- Create keystone table with default values
    local keystone = {
        level = nil,
        mapID = nil,
        mapName = nil
    }
    
    -- Get keystone level with API
    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if not keystoneLevel then
        return keystone
    end
    
    keystone.level = keystoneLevel
    
    -- Get keystone map ID
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if not mapID then
        return keystone
    end
    
    keystone.mapID = mapID
    
    -- Get map name from dungeon data
    if Data and Data.DUNGEON_TABLE and Data.DUNGEON_TABLE[mapID] then
        keystone.mapName = Data.DUNGEON_TABLE[mapID].name
    else
        keystone.mapName = "Unknown"
    end
    
    return keystone
end

function Character:GetFullName(unit)
    -- Input validation
    if not unit then
        Utils:DebugPrint("GetFullName: Missing unit parameter")
        return nil
    end
    
    -- Check if unit exists
    if not UnitExists(unit) then
        return nil
    end
    
    -- Get character name and realm
    local name, realm = UnitName(unit)
    if not name then
        return nil
    end
    
    -- If realm is empty or nil, use current realm
    if not (realm and realm ~= "") then
        realm = GetRealmName()
    end
    
    -- Format full name as Name-Realm
    return name .. "-" .. realm
end

function Character:BuildCurrentCharacter(bnet, fullName)
    if not bnet or not fullName then
        Utils:DebugPrint("BuildCurrentCharacter: Missing required parameters")
        return
    end
    
    -- Initialize character data object
    local charData = {}
    
    -- Get item level with error handling
    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    charData.iLvl = avgItemLevel and math.floor(avgItemLevel) or 0
    
    -- Get faction information
    local factionName = UnitFactionGroup("player")
    charData.faction = factionName or "Neutral"
    
    -- Get specialization and class information
    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local specID, _, _, _, role = GetSpecializationInfo(specIndex)
        charData.specId = specID
        charData.role = role
    end
    
    -- Get class information
    local _, _, classId = UnitClass("player")
    charData.classId = classId
    
    -- Get Mythic+ rating
    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    charData.rating = (ratingSummary and ratingSummary.currentSeasonScore) or 0
    
    -- Get Mythic+ run history
    C_MythicPlus.RequestMapInfo()
    local runs = C_MythicPlus.GetRunHistory(false, true)
    
    -- Process run history data
    if runs and #runs > 0 then
        table.sort(runs, function(a, b)
            return a.level > b.level
        end)
        
        -- Store top runs (up to 8)
        local topRuns = {}
        for i = 1, math.min(8, #runs) do
            topRuns[i] = runs[i]
        end
        charData.weeklies = topRuns
    else
        charData.weeklies = {}
    end
    
    -- Save character data and keystone information
    self:SetCharacterData(bnet, fullName, charData)
    self:SetCharacterKeystone(bnet, fullName, GetKeystone())
end

function Character:GetWeeklyData(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetWeeklyData: Missing required parameters")
        return {}
    end
    
    -- Validate database
    if not db then
        return {}
    end
    
    -- Initialize results
    local weeklies = {}
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character or not character.weeklies then
        return weeklies
    end
    
    -- Copy weekly data with fallback values
    for i = 1, 8 do
        weeklies[i] = character.weeklies[i] or { level = 0 }
    end
    
    return weeklies
end

function Character:SetCharacterData(bnet, fullName, dataTable)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterData: Missing required parameters")
        return
    end
    
    -- Validate data table
    if not dataTable or type(dataTable) ~= "table" then
        Utils:DebugPrint("SetCharacterData: Invalid data table")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterData: Database not initialized")
        return
    end
    
    -- Get character data and update fields
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Copy all data fields
    for key, value in pairs(dataTable) do
        character[key] = value
    end
end

function Character:GetCharacterCustomRoles(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterCustomRoles: Missing required parameters")
        return {}
    end
    
    -- Validate database
    if not db then
        return {}
    end
    
    -- Initialize result
    local roles = {}
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData or not customData.roles then
        return roles
    end
    
    -- Create a deep copy of roles
    roles = { unpack(customData.roles) }
    
    return roles
end

function Character:SetCharacterCustomRoles(bnet, fullName, roles)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterCustomRoles: Missing required parameters")
        return
    end
    
    -- Validate roles parameter
    if not roles or type(roles) ~= "table" then
        Utils:DebugPrint("SetCharacterCustomRoles: Invalid roles table")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterCustomRoles: Database not initialized")
        return
    end
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData then
        return
    end
    
    -- Update roles
    customData.roles = roles
end

function Character:SetCharacterHasKey(bnet, fullName, hasKey)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterHasKey: Missing required parameters")
        return
    end
    
    -- Validate hasKey parameter
    if type(hasKey) ~= "boolean" then
        Utils:DebugPrint("SetCharacterHasKey: hasKey must be a boolean")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterHasKey: Database not initialized")
        return
    end
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData then
        return
    end
    
    -- Update hasKey flag
    customData.hasKey = hasKey
end

function Character:GetCharacterHasKey(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterHasKey: Missing required parameters")
        return false
    end
    
    -- Validate database
    if not db then
        return false
    end
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData then
        return false
    end
    
    -- Return hasKey with fallback
    return customData.hasKey or false
end

function Character:SetCharacterIsHidden(bnet, fullName, isHidden)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterIsHidden: Missing required parameters")
        return
    end
    
    -- Validate isHidden parameter
    if type(isHidden) ~= "boolean" then
        Utils:DebugPrint("SetCharacterIsHidden: isHidden must be a boolean")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterIsHidden: Database not initialized")
        return
    end
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData then
        return
    end
    
    -- Update isHidden flag
    customData.isHidden = isHidden
end

function Character:GetCharacterIsHidden(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterIsHidden: Missing required parameters")
        return false
    end
    
    -- Validate database
    if not db then
        return false
    end
    
    -- Get custom data
    local customData = GetOrCreateCharacterCustomData(bnet, fullName)
    if not customData then
        return false
    end
    
    -- Return isHidden with fallback
    return customData.isHidden or false
end

function Character:GetCharacterKeystone(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterKeystone: Missing required parameters")
        return nil
    end
    
    -- Validate database
    if not db then
        return nil
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character or not character.keystone then
        return nil
    end
    
    -- Create a deep copy of keystone data to prevent modification of the original
    local keystone = {}
    keystone.level = character.keystone.level
    keystone.mapID = character.keystone.mapID
    keystone.mapName = character.keystone.mapName
    
    return keystone
end

function Character:SetCharacterKeystone(bnet, fullName, keystone)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterKeystone: Missing required parameters")
        return
    end
    
    -- Validate keystone parameter
    if not keystone then
        Utils:DebugPrint("SetCharacterKeystone: Missing keystone data")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterKeystone: Database not initialized")
        return
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Create a deep copy of keystone data
    character.keystone = {
        level = keystone.level,
        mapID = keystone.mapID,
        mapName = keystone.mapName
    }
end

function Character:GetCharacterRating(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterRating: Missing required parameters")
        return 0
    end
    
    -- Validate database
    if not db then
        return 0
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return 0
    end
    
    -- Return rating with fallback value
    return character.rating or 0
end

function Character:SetCharacterRating(bnet, fullName, rating)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterRating: Missing required parameters")
        return
    end
    
    -- Validate rating parameter
    if type(rating) ~= "number" then
        Utils:DebugPrint("SetCharacterRating: Rating must be a number")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterRating: Database not initialized")
        return
    end
    
    -- Get character data and update rating
    local character = GetOrCreateCharacterData(bnet, fullName)
    if character then
        character.rating = rating
    end
end

function Character:GetCharacterClassId(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterClassId: Missing required parameters")
        return 0
    end
    
    -- Validate database
    if not db then
        return 0
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return 0
    end
    
    -- Return classId with fallback
    return character.classId or 0
end

function Character:SetCharacterClassId(bnet, fullName, classId)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterClassId: Missing required parameters")
        return
    end
    
    -- Validate classId parameter
    if type(classId) ~= "number" then
        Utils:DebugPrint("SetCharacterClassId: ClassId must be a number")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterClassId: Database not initialized")
        return
    end
    
    -- Get character data and update classId
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Update classId
    character.classId = classId
end

function Character:GetCharacterSpecId(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterSpecId: Missing required parameters")
        return 0
    end
    
    -- Validate database
    if not db then
        return 0
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return 0
    end
    
    -- Return specId with fallback
    return character.specId or 0
end

function Character:SetCharacterSpecId(bnet, fullName, specId)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterSpecId: Missing required parameters")
        return
    end
    
    -- Validate specId parameter
    if type(specId) ~= "number" then
        Utils:DebugPrint("SetCharacterSpecId: SpecId must be a number")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterSpecId: Database not initialized")
        return
    end
    
    -- Get character data and update specId
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Update specId
    character.specId = specId
end

function Character:GetCharacterRole(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterRole: Missing required parameters")
        return nil
    end
    
    -- Validate database
    if not db then
        return nil
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return nil
    end
    
    -- Return role
    return character.role
end

function Character:SetCharacterRole(bnet, fullName, role)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterRole: Missing required parameters")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterRole: Database not initialized")
        return
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Update role
    character.role = role
end

function Character:GetCharacterFaction(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterFaction: Missing required parameters")
        return nil
    end
    
    -- Validate database
    if not db then
        return nil
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return nil
    end
    
    -- Return faction
    return character.faction
end

function Character:SetCharacterFaction(bnet, fullName, faction)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterFaction: Missing required parameters")
        return
    end
    
    -- Validate faction parameter
    if type(faction) ~= "string" then
        Utils:DebugPrint("SetCharacterFaction: Faction must be a string")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterFaction: Database not initialized")
        return
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Update faction
    character.faction = faction
end

function Character:GetCharacterIlvl(bnet, fullName)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("GetCharacterIlvl: Missing required parameters")
        return 0
    end
    
    -- Validate database
    if not db then
        return 0
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return 0
    end
    
    -- Return ilvl with fallback
    return character.iLvl or 0
end

function Character:SetCharacterIlvl(bnet, fullName, ilvl)
    -- Validate parameters
    if not bnet or not fullName then
        Utils:DebugPrint("SetCharacterIlvl: Missing required parameters")
        return
    end
    
    -- Validate ilvl parameter
    if type(ilvl) ~= "number" then
        Utils:DebugPrint("SetCharacterIlvl: Item level must be a number")
        return
    end
    
    -- Validate database
    if not db then
        Utils:DebugPrint("SetCharacterIlvl: Database not initialized")
        return
    end
    
    -- Get character data
    local character = GetOrCreateCharacterData(bnet, fullName)
    if not character then
        return
    end
    
    -- Update ilvl
    character.iLvl = ilvl
end
