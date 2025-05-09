local GT = _G.GT
local Dawn = GT.Modules.Dawn
local addon = GT.addon
local db = addon and addon.db
local Player = GT.Modules.Player
local Character = GT.Modules.Character
local Utils = GT.Modules.Utils
local AceSerializer = LibStub("AceSerializer-3.0")
local addonName = GT.addonName or "GrossToolbox"

function Dawn:SendCharacterData()
    local uid = addon:GetUID()
    if not uid then return end
    local characters = Player:GetCharactersForPlayer(uid)
    if not characters or not db.global.config.discordTag then return end
    local payload = {
        uid = uid,
        discordTag = db.global.config.discordTag,
        characters = {}
    }
    for charName, charData in pairs(characters) do
        if type(charData) == "table" then
            payload.characters[charName] = {}
            for key, value in pairs(charData) do
                if key ~= "custom" and key ~= "weeklies" then
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

function Dawn:SendUIDData()
    local uid = addon:GetUID()
    if not uid then return end
    local payload = { uid = uid }
    local serialized = AceSerializer:Serialize(payload)
    local messageToSend = GT.headers.uid .. serialized
    if IsInGroup() then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, messageToSend, channel)
    end
end

function Dawn:RequestData()
    if IsInGroup() then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, GT.headers.request, channel)
        print(addonName, ": Requesting data from party members...")
    else
        Utils:DebugPrint(addonName, ": You must be in a party to request data.")
    end
end

function Dawn:RequestUIDs()
    if IsInGroup() then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, GT.headers.uids, channel)
    else
        Utils:DebugPrint(addonName, ": You must be in a party to request UID.")
    end
end

function Dawn:ProcessPlayerData(message, sender)
    local success, data = AceSerializer:Deserialize(string.sub(message, 11))
    if not success or type(data) ~= "table" or not data.uid or not data.characters then
        print(addonName, ": Invalid or malformed data from", sender)
        return
    end
    local localUID = addon:GetUID()
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
end

function Dawn:ProcessUIDData(message, sender)
    if not message or not sender then
        Utils:DebugPrint("ProcessUIDData: Missing message or sender parameters")
        return
    end
    local success, data = AceSerializer:Deserialize(string.sub(message, 5))
    if not success then
        Utils:DebugPrint("ProcessUIDData: Failed to deserialize message from " .. sender)
        return
    end
    if type(data) ~= "table" then
        Utils:DebugPrint("ProcessUIDData: Data is not a table from " .. sender)
        return
    end
    if not data.uid then
        Utils:DebugPrint("ProcessUIDData: Missing UID in data from " .. sender)
        return
    end
    local uid = data.uid
    Utils:DebugPrint("ProcessUIDData: Received UID " .. uid .. " from " .. sender)
    self:addUID(uid)
    Player:GetOrCreatePlayerData(uid)
    Utils:DebugPrint("ProcessUIDData: UID " .. uid .. " added successfully")
end

function Dawn:OnCommReceived(_, message, _, sender)
    if type(message) ~= "string" or UnitIsUnit("player", sender) then return end
    Utils:DebugPrint("OnCommReceived: Received message from " .. sender)
    if message == GT.headers.request then
        self:SendCharacterData()
    elseif message == GT.headers.uids then
        self:SendUIDData()
    elseif string.sub(message, 1, 10) == GT.headers.player then
        self:ProcessPlayerData(message, sender)
    elseif string.sub(message, 1, 4) == GT.headers.uid then
        self:ProcessUIDData(message, sender)
    end
end
