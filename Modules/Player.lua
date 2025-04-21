local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Player = {}
GT.Modules.Player = Player

local db
function Player:Init(database)
	db = database
	if not db then return end
end

local function GetOrCreatePlayerData(bnet)
	if not db or not db.global.players then return nil end
	if not db.global.players[bnet] then
		db.global.players[bnet] = { discordTag = "", char = {} }
	end
	return db.global.players[bnet]
end

function Player:GetBNetTagForUnit(unit)
	local bnetData = C_BattleNet.GetAccountInfoByGUID(UnitGUID(unit))
	local bnetTag
	if bnetData then bnetTag = bnetData.battleTag end
	return bnetTag
end

function Player:FetchPartyMembersBnet()
    local bnets = {}
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = (LE_PARTY_CATEGORY_INSTANCE == GetInstanceInfo()) and ("raid" .. i) or
                ("party" .. i)
			local bnet = self:GetBNetTagForUnit(unit)
            if bnet then
                bnets.insert(self:GetBNetTagForUnit(unit))
            end
        end
    end

    return bnets
end

function Player:SetDiscordTag(bnet, tag)
	local playerData = GetOrCreatePlayerData(bnet)
	if playerData then
		playerData.discordTag = tag
	end
end

function Player:GetDiscordTag(bnet)
	local playerData = GetOrCreatePlayerData(bnet)
	if playerData then
		return playerData.discordTag
	end
end

function Player:GetAllCharactersForPlayer(bnet)
    local player = GetOrCreatePlayerData(bnet)
    if player and player.characters then
        local characters = {}
        for fullName, charData in pairs(player.characters) do
            if charData then
                table.insert(characters, fullName)
            end
        end
        return characters
    end
end
