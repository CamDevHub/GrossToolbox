local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Character = {}
GT.Modules.Character = Character

-- Keep MplusDungeonNames...
local MplusDungeonNames = {
	[2651] = "DFC",
	[2661] = "Brew",
	[2773] = "Flood",
	[2649] = "PSF",
	[2648] = "Rook",
	[1594] = "ML",
	[2293] = "TOP",
	[2097] = "WS"
}

local SPEC_ID_TO_ENGLISH_NAME = {
    -- Death Knight
    [250] = "Blood",
    [251] = "Frost",
    [252] = "UH",
    -- Demon Hunter
    [577] = "Havoc",
    [581] = "Veng",
    -- Druid
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Resto",
    -- Evoker
    [1467] = "Deva",
    [1468] = "Pres",
    [1473] = "Aug",
    -- Hunter
    [253] = "BM",
    [254] = "MM",
    [255] = "Surv",
    -- Mage
    [62] = "Arcane",
    [63] = "Fire",
    [64] = "Frost",
    -- Monk
    [268] = "Brew",
    [270] = "Mist",
    [269] = "WW",
    -- Paladin
    [65] = "Holy",
    [66] = "Prot",
    [70] = "Ret",
    -- Priest
    [256] = "Disc",
    [257] = "Holy",
    [258] = "Shadow",
    -- Rogue
    [259] = "Assa",
    [260] = "Outlaw",
    [261] = "Sub",
    -- Shaman
    [262] = "Elem",
    [263] = "EH",
    [264] = "Resto",
    -- Warlock
    [265] = "Affli",
    [266] = "Demono",
    [267] = "Destru",
    -- Warrior
    [71] = "Arms",
    [72] = "Fury",
    [73] = "Protect",
    -- Default / Unknown
    ["Unknown"] = "Unknown Spec"
}

local CLASS_ID_TO_ENGLISH_NAME = {
    [1] = "War",
    [2] = "Pal",
    [3] = "Hunt",
    [4] = "Rogue",
    [5] = "Priest",
    [6] = "DK",
    [7] = "Sham",
    [8] = "Mage",
    [9] = "Warlock",
    [10] = "Monk",
    [11] = "Druid",
    [12] = "DH",
    [13] = "Evo",
    ["Unknown"] = "Unknown Class"
}

local db
function Character:Init(database)
    db = database
    if not db then return end
end

function Character:GetFullName()
	local name = UnitName("player")
    local realm = GetRealmName()
    return realm .. "-" .. name
end

function Character:FetchCurrentCharacterStats()
	local charData = {}
    -- Update iLvl
    local avgItemLevel = GetAverageItemLevel()
    charData.iLvl = avgItemLevel and math.floor(avgItemLevel) or 0

    -- Update Spec & Class
    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local specID, specName, _, _, role = GetSpecializationInfo(specIndex)
        charData.specName = SPEC_ID_TO_ENGLISH_NAME[specID]
        charData.role = role
    else charData.specName, charData.role = "No Spec", nil end
    local className, _, classId = UnitClass("player")
    charData.className = CLASS_ID_TO_ENGLISH_NAME[classId]

	-- Update Rating
	local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	charData.rating = (ratingSummary and ratingSummary.currentSeasonScore) or 0

	-- Update Keystone info (pass the character's data table)
	self:UpdateKeystone(charData) -- Pass charData directly
	
	return charData
end

function Character:UpdateKeystone(charData) -- Receives charData table directly
    if not charData then return end
	charData.keystone = charData.keystone or {}
    local keyData = charData.keystone -- Shortcut

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
	keyData.hasKey = keystoneLevel and keystoneLevel >= 2

    if keyData.hasKey then
        keyData.level = keystoneLevel
        keyData.mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        keyData.mapName = keyData.mapID and MplusDungeonNames[keyData.mapID] or "Unknown"
    else keyData.level, keyData.mapID, keyData.mapName = nil, nil, nil end
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
	db.global.player[bnet].char[charFullName] = dataTable
end