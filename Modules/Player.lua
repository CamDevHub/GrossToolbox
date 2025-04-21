local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Player = {}
GT.Modules.Player = Player

local db
local Utils
function Player:Init(database)
	db = database
	if not db then return end

	Utils = GT.Modules.Utils
	if not Utils then return end
end

function Player:GetOrCreatePlayerData(bnet)
	if not db then return nil end
	if not db.global.players[bnet] then
		db.global.players[bnet] = { discordTag = "", characters = {} }
	end

	return db.global.players[bnet]
end

function Player:GetBNetTagForUnit(unit)
	local bnetData = C_BattleNet.GetAccountInfoByGUID(UnitGUID(unit))
	local bnetTag
	if bnetData then bnetTag = bnetData.battleTag end
	return bnetTag
end

function Player:GetBNetOfPartyMembers()
	local bnetTags = {}
	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local unit = (LE_PARTY_CATEGORY_INSTANCE == GetInstanceInfo()) and ("raid" .. i) or ("party" .. i)
			if UnitExists(unit) then
				local bnetTag = self:GetBNetTagForUnit(unit)
				if bnetTag then
					table.insert(bnetTags, bnetTag)
				end
			end
		end
	end
	local bnetTag = self:GetBNetTagForUnit("player")
	if bnetTag then
		table.insert(bnetTags, bnetTag)
	end

	return bnetTags
end

function Player:GetCharactersName(bnet)
	if not db then return end

	local player = self:GetOrCreatePlayerData(bnet)
	if not player then return end

	local names = {}
	for name, _ in pairs(player.characters) do
		table.insert(names, name)
	end
	return names
end

function Player:SetDiscordTag(bnet, tag)
	local player = self:GetOrCreatePlayerData(bnet)
	if not player then return end
	player.discordTag = tag
end

function Player:GetDiscordTag(bnet)
	if not db then return end

	local player = self:GetOrCreatePlayerData(bnet)
	if not player then return end
	return player.discordTag
end

function Player:GetCharactersForPlayer(bnet)
	if not db then return end

	local player = self:GetOrCreatePlayerData(bnet)
	if not player then return end
	return player.characters
end
