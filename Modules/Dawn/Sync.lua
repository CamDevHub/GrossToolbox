local AddonName, GT = ...

local Dawn = GT.Modules.Dawn

local ADDON_PREFIX     = "GrossToolbox"
local PROTOCOL_VERSION = "1"

C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

local function GetGroupChannel()
    if IsInGroup() then return "PARTY" end
end

local function SendCharacterData(channel)
    local myID   = GT.DB.uniqueID
    local myData = myID and GT.DB.players[myID]
    if not myData then return end

    -- Discord handle sent once per player in its own message type
    local handle = (myData.discordHandle ~= "" and myData.discordHandle) or GT.DB.discordHandle or ""
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, table.concat({
        "DAWN_DISCORD",
        PROTOCOL_VERSION,
        myID,
        handle,
    }, "|"), channel)

    for charName, charData in pairs(myData.chars or {}) do
        local ks    = charData.keystone or {}
        local roles = charData.roles    or {}
        local msg   = table.concat({
            "DAWN_RES",
            PROTOCOL_VERSION,
            myID,
            charName,
            charData.name           or "",
            charData.server         or "",
            tostring(charData.ilvl  or 0),
            charData.faction        or "",
            charData.race           or "",
            charData.class          or "",
            charData.specialisation or "",
            tostring(charData.mpRating  or 0),
            tostring(ks.level           or 0),
            tostring(ks.challengeId     or 0),
            roles.tank and "1" or "0",
            roles.heal and "1" or "0",
            roles.dps  and "1" or "0",
            charData.hideFromTag and "1" or "0",
            charData.forceNoKey  and "1" or "0",
        }, "|")
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, msg, channel)
    end
end

local function HandleDiscordSync(parts)
    -- DAWN_DISCORD | version | uid | handle
    local uid    = parts[3]
    local handle = parts[4]
    if not uid or uid == GT.DB.uniqueID then return end
    GT.DB.players[uid] = GT.DB.players[uid] or {}
    if handle and handle ~= "" then
        GT.DB.players[uid].discordHandle = handle
    end
end

local function HandleSyncResponse(parts)
    -- DAWN_RES | version | uid | charName | name | server | ilvl | faction | race | class | spec | mpRating | ks.level | ks.challengeId | tank | heal | dps
    local uid      = parts[3]
    local charName = parts[4]
    if not uid or not charName then return end
    if uid == GT.DB.uniqueID   then return end

    GT.Core:DebugPrint("Dawn: processing uid", uid, "char", charName)

    GT.DB.players[uid]          = GT.DB.players[uid]          or {}
    GT.DB.players[uid].chars    = GT.DB.players[uid].chars    or {}
    GT.DB.players[uid].lastSeen = time()

    GT.DB.players[uid].chars[charName] = {
        name           = parts[5],
        server         = parts[6],
        ilvl           = tonumber(parts[7])  or 0,
        faction        = parts[8],
        race           = parts[9],
        class          = parts[10],
        specialisation = parts[11],
        mpRating       = tonumber(parts[12]) or 0,
        keystone = {
            level       = tonumber(parts[13]) or 0,
            challengeId = tonumber(parts[14]) or 0,
        },
        roles = {
            tank = parts[15] == "1",
            heal = parts[16] == "1",
            dps  = parts[17] == "1",
        },
        hideFromTag = parts[18] == "1",
        forceNoKey  = parts[19] == "1",
    }


end

local syncListenFrame = CreateFrame("Frame")
syncListenFrame:RegisterEvent("CHAT_MSG_ADDON")
syncListenFrame:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end
    GT.Core:DebugPrint("Sync: CHAT_MSG_ADDON from", sender, "->", (message:match("^[^|]+") or message))
    local parts = {}
    for part in message:gmatch("[^|]+") do parts[#parts + 1] = part end
    local msgType = parts[1]
    if msgType == "DAWN_REQ" then
        GT.Core:DebugPrint("Dawn: sync requested by", sender)
        local handle = GT.DB.discordHandle or ""
        if handle == "" then return end
        local channel = GetGroupChannel()
        if channel then SendCharacterData(channel) end
    elseif msgType == "DAWN_RES" then
        HandleSyncResponse(parts)
    elseif msgType == "DAWN_DISCORD" then
        HandleDiscordSync(parts)
    end
end)

-- Wire up the sync button (Dawn.syncBtn is set by TagCategory.lua which loads first)
local syncCooldown = false
local syncBtn      = Dawn.syncBtn
local syncLabel    = Dawn.syncLabel

local noDiscordPopup, noDiscordContent = GT.UI:CreatePopup("Missing Discord Handle", 340, 110)

local noDiscordMsg = noDiscordContent:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(noDiscordMsg, 13, "")
noDiscordMsg:SetPoint("TOPLEFT",  noDiscordContent, "TOPLEFT",  16, -16)
noDiscordMsg:SetPoint("TOPRIGHT", noDiscordContent, "TOPRIGHT", -16, -16)
noDiscordMsg:SetJustifyH("LEFT")
noDiscordMsg:SetText("Your Discord handle is not set.\nPlease fill it in the Settings > Information tab.")
noDiscordMsg:SetTextColor(0.9, 0.9, 0.9)

local noDiscordOk = CreateFrame("Button", nil, noDiscordContent, "BackdropTemplate")
noDiscordOk:SetSize(80, 26)
noDiscordOk:SetPoint("BOTTOMLEFT", noDiscordContent, "BOTTOMLEFT", 16, 10)
noDiscordOk:SetBackdrop({
    bgFile   = GT.Config.WHITE8X8,
    edgeFile = GT.Config.WHITE8X8,
    edgeSize = 1,
})
noDiscordOk:SetBackdropColor(0.25, 0.25, 0.25, 1)
noDiscordOk:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
noDiscordOk:SetScript("OnEnter", function(self) self:SetBackdropColor(0.35, 0.35, 0.35, 1) end)
noDiscordOk:SetScript("OnLeave", function(self) self:SetBackdropColor(0.25, 0.25, 0.25, 1) end)
noDiscordOk:SetScript("OnClick", function() noDiscordPopup:Hide() end)

local noDiscordOkText = noDiscordOk:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(noDiscordOkText, 13, "")
noDiscordOkText:SetPoint("CENTER")
noDiscordOkText:SetText("OK")
noDiscordOkText:SetTextColor(1, 1, 1)

syncBtn:SetScript("OnClick", function()
    if syncCooldown then return end

    Dawn.RefreshPartyCache()

    local handle = GT.DB.discordHandle or ""
    if handle == "" then
        noDiscordPopup:Show()
        return
    end

    local channel = GetGroupChannel()
    if not channel then return end

    syncCooldown = true
    syncLabel:SetText("Refreshing")
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, table.concat({ "DAWN_REQ", PROTOCOL_VERSION }, "|"), channel)

    C_Timer.After(3, function()
        syncCooldown = false
        syncLabel:SetText("Sync")
        Dawn.RefreshTagText()
    end)
end)
