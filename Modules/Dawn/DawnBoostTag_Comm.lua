local GT = _G.GT
local Dawn = GT.Modules.Dawn
local AceSerializer = LibStub("AceSerializer-3.0")
local addonName = GT.addonName or "GrossToolbox"

local Config, Utils, Player, Character
function Dawn:InitComm()
    Config = GT.Modules.Config
    Utils = GT.Modules.Utils
    Player = GT.Modules.Player
    Character = GT.Modules.Character
end

function Dawn:SendCharacterData()
    local uid = GT.addon:GetUID()
    if not uid then return end
    local characters = Player:GetCharactersForPlayer(uid)
    local discordTag = Config:GetDiscordTag()
    if not characters or not discordTag then return end
    local payload = {
        uid = uid,
        discordTag = discordTag,
        characters = {}
    }
    for charName, charData in pairs(characters) do
        if type(charData) == "table" then
            payload.characters[charName] = {}
            for key, value in pairs(charData) do
                if key ~= "custom" and key ~= "weekly" and key ~= "sparks" then
                    payload.characters[charName][key] = value
                end
            end
        end
    end
    local serialized = AceSerializer:Serialize(payload)
    local messageToSend = GT.headers.player .. serialized
    if IsInGroup() then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, messageToSend, channel)
    end
end

function Dawn:RequestData()
    self:ClearPartyUIDs()
    if IsInGroup() then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, GT.headers.request, channel)
        print(addonName, ": Requesting data from party members...")
    else
        Utils:DebugPrint(addonName, ": You must be in a party to request data.")
    end
end

function Dawn:ProcessPlayerData(message, sender)
    local success, data = AceSerializer:Deserialize(string.sub(message, 11))
    if not success or type(data) ~= "table" or not data.uid or not data.characters then
        print(addonName, ": Invalid or malformed data from", sender)
        return
    end
    local localUID = GT.addon:GetUID()
    Utils:DebugPrint("localUID: " .. localUID)
    local uid = data.uid
    if not data.uid then
        Utils:DebugPrint("ProcessUIDData: Missing UID in data from " .. sender)
        return
    end
    local incomingChars = data.characters
    local senderDiscordTag = data.discordTag or ""
    local localPlayerEntry = Player:GetOrCreatePlayerData(uid)
    localPlayerEntry.discordTag = senderDiscordTag
    if localUID ~= uid and type(incomingChars) == "table" then
        print(addonName, ": Processing data from", sender, "for UID:", uid)
        self:addUID(uid)
        Player:DeleteCharactersForPlayer(uid)
        for charName, charData in pairs(incomingChars) do
            if type(charData) == "table" then
                Character:SetCharacterData(uid, charName, charData)
            end
        end
    end
    if self.dawnContainer then
        Dawn:PopulateDawnFrame(self.dawnContainer)
    end
end

function Dawn:OnCommReceived(_, message, _, sender)
    if type(message) ~= "string" or UnitIsUnit("player", sender) then return end
    Utils:DebugPrint("OnCommReceived: Received message from " .. sender)
    if message == GT.headers.request then
        self:SendCharacterData()
    elseif string.sub(message, 1, 10) == GT.headers.player then
        self:ProcessPlayerData(message, sender)
    end
end

local AceComm = LibStub:GetLibrary("AceComm-3.0")
AceComm:RegisterComm(GT.COMM_PREFIX, function(prefix, message, distribution, sender)
    Dawn:OnCommReceived(prefix, message, distribution, sender)
end)