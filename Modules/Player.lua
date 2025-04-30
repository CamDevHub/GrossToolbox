local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Player = {}
GT.Modules.Player = Player

-- Define module name for initialization logging
Player.moduleName = "Player"

-- Define module dependencies
local db
local Utils

function Player:Init(database)
	-- Validate database parameter
	if not database then
		print(addonName .. ": Player module initialization failed - missing database")
		return false
	end
	
	-- Store database reference
	db = database
	
	-- Load Utils module
	Utils = GT.Modules.Utils
	if not Utils then
		print(addonName .. ": Player module initialization failed - Utils module not found")
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
	Utils:DebugPrint("Player module initialized successfully")
	return true
end

function Player:GetOrCreatePlayerData(bnet)
	-- Validate parameters
	if not bnet then
		Utils:DebugPrint("GetOrCreatePlayerData: Missing required parameter")
		return nil
	end
	
	-- Validate database
	if not db then
		Utils:DebugPrint("GetOrCreatePlayerData: Database not initialized")
		return nil
	end
	
	-- Ensure global.players table exists
	if not db.global then
		db.global = {}
	end
	
	if not db.global.players then
		db.global.players = {}
	end
	
	-- Create player entry if needed
	if not db.global.players[bnet] then
		db.global.players[bnet] = { 
			discordTag = "", 
			characters = {} 
		}
	end
	
	return db.global.players[bnet]
end

function Player:GetBNetTagForUnit(unit)
	-- Validate parameters
	if not unit then
		Utils:DebugPrint("GetBNetTagForUnit: Missing unit parameter")
		return nil
	end
	
	-- Check if unit exists
	if not UnitExists(unit) then
		return nil
	end
	
	-- Get unit GUID
	local guid = UnitGUID(unit)
	if not guid then
		return nil
	end
	
	-- Get BattleNet info
	local bnetData = C_BattleNet.GetAccountInfoByGUID(guid)
	if not bnetData then
		return nil
	end
	
	return bnetData.battleTag
end

function Player:GetBNetOfPartyMembers()
	-- Initialize results array
	local bnetTags = {}
	
	-- Get group members' BNet tags if in a group
	if IsInGroup() then
		local numMembers = GetNumGroupMembers()
		local isRaid = (LE_PARTY_CATEGORY_INSTANCE == GetInstanceInfo())
		
		-- Loop through group members
		for i = 1, numMembers do
			local unit = isRaid and ("raid" .. i) or ("party" .. i)
			
			-- Check if unit exists
			if UnitExists(unit) then
				local bnetTag = self:GetBNetTagForUnit(unit)
				if bnetTag then
					table.insert(bnetTags, bnetTag)
				end
			end
		end
	end
	
	-- Add player's own BNet tag
	local playerBnetTag = self:GetBNetTagForUnit("player")
	if playerBnetTag then
		table.insert(bnetTags, playerBnetTag)
	end
	
	return bnetTags
end

function Player:GetCharactersName(bnet)
	-- Validate parameters
	if not bnet then
		Utils:DebugPrint("GetCharactersName: Missing required parameter")
		return {}
	end
	
	-- Validate database
	if not db then
		Utils:DebugPrint("GetCharactersName: Database not initialized")
		return {}
	end
	
	-- Get player data
	local player = self:GetOrCreatePlayerData(bnet)
	if not player or not player.characters then
		return {}
	end
	
	-- Build list of character names
	local names = {}
	for name, _ in pairs(player.characters) do
		table.insert(names, name)
	end
	
	return names
end

function Player:SetDiscordTag(bnet, tag)
	-- Validate parameters
	if not bnet then
		Utils:DebugPrint("SetDiscordTag: Missing required parameter")
		return
	end
	
	-- Validate tag parameter
	if not tag then
		tag = ""
	end
	
	-- Validate database
	if not db then
		Utils:DebugPrint("SetDiscordTag: Database not initialized")
		return
	end
	
	-- Get player data and update discord tag
	local player = self:GetOrCreatePlayerData(bnet)
	if not player then
		return
	end
	
	player.discordTag = tag
end

function Player:GetDiscordTag(bnet)
	-- Validate parameters
	if not bnet then
		Utils:DebugPrint("GetDiscordTag: Missing required parameter")
		return ""
	end
	
	-- Validate database
	if not db then
		Utils:DebugPrint("GetDiscordTag: Database not initialized")
		return ""
	end
	
	-- Get player data and return discord tag
	local player = self:GetOrCreatePlayerData(bnet)
	if not player then
		return ""
	end
	
	return player.discordTag or ""
end

function Player:GetCharactersForPlayer(bnet)
	-- Validate parameters
	if not bnet then
		Utils:DebugPrint("GetCharactersForPlayer: Missing required parameter")
		return {}
	end
	
	-- Validate database
	if not db then
		Utils:DebugPrint("GetCharactersForPlayer: Database not initialized")
		return {}
	end
	
	-- Get player data
	local player = self:GetOrCreatePlayerData(bnet)
	if not player then
		return {}
	end
	
	-- Return characters table
	return player.characters or {}
end
