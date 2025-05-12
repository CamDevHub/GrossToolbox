local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Player = {}
GT.Core.Player = Player

-- Define module name for initialization logging
Player.moduleName = "Player"

-- Define module dependencies
local db
local Utils
function Player:Init(database)
	-- Validate database parameter
	if not database or not database.global or not database.global.players then
		print(addonName .. ": Player module initialization failed - missing database")
		return false
	end

	-- Store database reference
	db = database.global.players

	-- Load Utils module
	Utils = GT.Core.Utils
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

	-- Create player entry if needed
	if not db[uid] then
		db[uid] = {
			discordTag = "",
			characters = {}
		}
	end

	return db[uid]
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

-- Delete a player and all associated data from the database
function Player:DeletePlayer(uid)
	if not uid then
		Utils:DebugPrint("DeletePlayer: No UID provided")
		return false
	end

	-- Check if the player exists in database
	if not db[uid] then
		Utils:DebugPrint("DeletePlayer: Player with UID " .. uid .. " not found in database")
		return false
	end

	-- Delete the player and all associated data
	db[uid] = nil

	-- Log deletion
	Utils:DebugPrint(string.format("Deleted player: %s",
		uid))

	return true
end
