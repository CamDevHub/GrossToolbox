local GT = _G.GT
local Dawn = GT.Modules.Dawn
local AceSerializer = LibStub("AceSerializer-3.0")
local addonName = GT.addonName or "GrossToolbox"

function Dawn:SendCharacterData()
    local uid = GT.addon:GetUID()
    if not uid then return end
    local characters = GT.Modules.Player:GetCharactersForPlayer(uid)
    local discordTag = GT.Modules.Config:GetDiscordTag()
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
                if key ~= "custom" and key ~= "weekly" then
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
        GT.Modules.Utils:DebugPrint(addonName, ": You must be in a party to request data.")
    end
end

function Dawn:ProcessPlayerData(message, sender)
    local success, data = AceSerializer:Deserialize(string.sub(message, 11))
    if not success or type(data) ~= "table" or not data.uid or not data.characters then
        print(addonName, ": Invalid or malformed data from", sender)
        return
    end
    local localUID = GT.addon:GetUID()
    GT.Modules.Utils:DebugPrint("localUID: " .. localUID)
    local uid = data.uid
    if not data.uid then
        GT.Modules.Utils:DebugPrint("ProcessUIDData: Missing UID in data from " .. sender)
        return
    end
    local incomingChars = data.characters
    local senderDiscordTag = data.discordTag or ""
    local localPlayerEntry = GT.Modules.Player:GetOrCreatePlayerData(uid)
    localPlayerEntry.discordTag = senderDiscordTag
    if localUID ~= uid and type(incomingChars) == "table" then
        print(addonName, ": Processing data from", sender, "for UID:", uid)
        self:addUID(uid)
        GT.Modules.Player:DeleteCharactersForPlayer(uid)
        for charName, charData in pairs(incomingChars) do
            if type(charData) == "table" then
                GT.Modules.Character:SetCharacterData(uid, charName, charData)
            end
        end
    end
    if self.dawnContainer then
        Dawn:PopulateDawnFrame(self.dawnContainer)
    end
end

function Dawn:OnCommReceived(_, message, _, sender)
    if type(message) ~= "string" or UnitIsUnit("player", sender) then return end
    GT.Modules.Utils:DebugPrint("OnCommReceived: Received message from " .. sender)
    if message == GT.headers.request then
        self:SendCharacterData()
    elseif string.sub(message, 1, 10) == GT.headers.player then
        self:ProcessPlayerData(message, sender)
    end
end
