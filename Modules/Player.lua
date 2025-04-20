local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Player = {}
GT.Modules.Player = Player

local db
function Player:Init(database)
	db = database
	if not db then return end
end

function Player:GetBNetTag()
	local bnetData = C_BattleNet.GetAccountInfoByGUID(UnitGUID("player"))
	local bnetTag
	if bnetData then bnetTag = bnetData.battleTag end
	return bnetTag
end

function Player:UpdateDiscordTagForLocalPlayer(tag)
	local bnet = self:GetBNetTag()
	if db.global.player[bnet] then
		db.global.player[bnet].discordTag = tag
	end
end

function Player:GetOrCreatePlayerData(bnet)
	if not db.global.player[bnet] then
		db.global.player[bnet] = { discordTag = "", char = {} }
	end

	for _, charData in pairs(db.global.player[bnet].char) do
		if not charData.custom then
			charData.custom = {}
		end
		if not charData.custom.noKeyForBoost then
			charData.custom.noKeyForBoost = false
		end
		if not charData.custom.hide then
			charData.custom.hide = false
		end
		if not charData.custom.roles then
			charData.custom.roles = {}
		end
	end
	return db.global.player[bnet]
end

function Player:SetDiscordTag(bnet, tag)
	if db.global.player[bnet] then
		db.global.player[bnet].discordTag = tag
	end
end

function Player:GetDiscordTag(bnet)
	if db.global.player[bnet] then
		return db.global.player[bnet].discordTag
	end
end

function Player:GetAllPlayerData()
	if db.global.player then
		return db.global.player
	end
end
