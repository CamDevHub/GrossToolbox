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

function Player:GetOrCreatePlayerData(uid)
	-- Validate parameters
	if not uid then
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
	if not db.global.players[uid] then
		db.global.players[uid] = {
			discordTag = "",
			characters = {}
		}
	end

	return db.global.players[uid]
end

function Player:GetCharactersName(uid)
	-- Validate parameters
	if not uid then
		Utils:DebugPrint("GetCharactersName: Missing required parameter")
		return {}
	end

	-- Validate database
	if not db then
		Utils:DebugPrint("GetCharactersName: Database not initialized")
		return {}
	end

	-- Get player data
	local player = self:GetOrCreatePlayerData(uid)
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

function Player:SetDiscordTag(uid, tag)
	-- Validate parameters
	if not uid then
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
	local player = self:GetOrCreatePlayerData(uid)
	if not player then
		return
	end

	player.discordTag = tag
end

function Player:GetDiscordTag(uid)
	-- Validate parameters
	if not uid then
		Utils:DebugPrint("GetDiscordTag: Missing required parameter")
		return ""
	end

	-- Validate database
	if not db then
		Utils:DebugPrint("GetDiscordTag: Database not initialized")
		return ""
	end

	-- Get player data and return discord tag
	local player = self:GetOrCreatePlayerData(uid)
	if not player then
		return ""
	end

	return player.discordTag or ""
end

function Player:DeleteCharactersForPlayer(uid)
	-- Validate parameters
	if not uid then
		Utils:DebugPrint("DeleteCharactersForPlayer: Missing required parameter")
		return
	end

	-- Validate database
	if not db then
		Utils:DebugPrint("DeleteCharactersForPlayer: Database not initialized")
		return
	end

	-- Get player data and delete characters
	local player = self:GetOrCreatePlayerData(uid)
	if not player then
		return
	end

	player.characters = {}
end

function Player:GetCharactersForPlayer(uid)
	-- Validate parameters
	if not uid then
		Utils:DebugPrint("GetCharactersForPlayer: Missing required parameter")
		return {}
	end

	-- Validate database
	if not db then
		Utils:DebugPrint("GetCharactersForPlayer: Database not initialized")
		return {}
	end

	-- Get player data
	local player = self:GetOrCreatePlayerData(uid)
	if not player then
		return {}
	end

	-- Return characters table
	return player.characters or {}
end
