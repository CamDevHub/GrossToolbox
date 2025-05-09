local GT = _G.GT
local addon = GT.addon
local Dawn = GT.Modules.Dawn
local Player = GT.Modules.Player
local Character = GT.Modules.Character
local Utils = GT.Modules.Utils
local Data = GT.Modules.Data
local Config = GT.Modules.Config
local AceGUI = LibStub("AceGUI-3.0")

function Dawn:PopulateDawnFrame(container)
    self:PopulateSignupFrame(container)
    self:PopulateKeyListFrame(container)
    self:PopulateDungeonFrame(container)
end

function Dawn:DrawSignupFrame(container)
    if not container then return end

    if not container.signup then
        container.signup = {}
    end
    -- === Tab 1: Data (Players) ===
    local dataTabContainer = AceGUI:Create("SimpleGroup")
    dataTabContainer:SetLayout("Flow")
    dataTabContainer:SetAutoAdjustHeight(false)
    container:AddChild(dataTabContainer)

    local playersEditBox = AceGUI:Create("MultiLineEditBox")
    playersEditBox:SetLabel("Players Data")
    playersEditBox:DisableButton(true)
    playersEditBox:SetWidth(650)
    playersEditBox:SetHeight(500)
    dataTabContainer:AddChild(playersEditBox)
    container.signup.playersEditBox = playersEditBox

    local keysEditBox = AceGUI:Create("MultiLineEditBox")
    keysEditBox:SetLabel("Keystone List")
    keysEditBox:DisableButton(true)
    keysEditBox:SetWidth(250)
    keysEditBox:SetHeight(500)
    dataTabContainer:AddChild(keysEditBox)
    container.signup.keysEditBox = keysEditBox

    local dungeonsContainer = AceGUI:Create("SimpleGroup")
    dungeonsContainer:SetLayout("Flow")
    dungeonsContainer:SetWidth(160)
    dungeonsContainer:SetHeight(500)
    dataTabContainer:AddChild(dungeonsContainer)
    container.signup.dungeonsContainer = dungeonsContainer

    local requestButton = AceGUI:Create("Button")
    requestButton:SetText("Request Party Data")
    requestButton:SetWidth(200)
    requestButton:SetCallback("OnClick", function ()
        Dawn:RequestData()
        C_Timer.After(3, function()
            Dawn:PopulateDawnFrame(container)
        end)
    end)
    dataTabContainer:AddChild(requestButton)

    local teamTakeCheckbox = AceGUI:Create("CheckBox")
    teamTakeCheckbox:SetLabel("Team Take")
    teamTakeCheckbox:SetWidth(200)
    teamTakeCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        Dawn:PopulateDawnFrame(container)
    end)
    dataTabContainer:AddChild(teamTakeCheckbox)
    dataTabContainer:DoLayout()
    container.signup.teamTakeCheckbox = teamTakeCheckbox
end

function Dawn:DrawPlayerEditorFrame(container)
    if not container then return end

    if not container.signup then
        container.signup = {}
    end
    -- === Tab 2: Player Editor ===
    local playerEditorTabContainer = AceGUI:Create("ScrollFrame")
    playerEditorTabContainer:SetLayout("Flow")
    container:AddChild(playerEditorTabContainer)
    container.signup.playerEditorScroll = playerEditorTabContainer
end

function Dawn:PopulateSignupFrame(container)
    -- Validate container and required UI elements
    if not container or not container.signup or not container.signup.playersEditBox then
        Utils:DebugPrint("PopulateDisplayFrame: Missing required UI elements")
        return
    end
    local playersEditBox = container.signup.playersEditBox
    local teamTakeCheckbox = container.signup.teamTakeCheckbox
    local localDiscordTag = Config:GetDiscordTag()
    if not localDiscordTag or localDiscordTag == "" then
        playersEditBox:SetText("Discord handle not set bro !")
        return
    end
    local localUID = addon:GetUID()
    if not localUID then
        Utils:DebugPrint("PopulateDisplayFrame: Could not get local player's UID")
        playersEditBox:SetText("Could not get your UID")
        return
    end
    local fullOutputString = ""
    if teamTakeCheckbox:GetValue() then
        fullOutputString = self:GenerateTeamTakeContent(localUID)
    else
        fullOutputString = self:GenerateNormalSignupContent(localUID)
    end
    playersEditBox:SetText(fullOutputString)
    playersEditBox:HighlightText(0, 9999)
end

function Dawn:GenerateTeamTakeContent(localUID)
    local output = "### Team Take\n"
    local localDiscordTag = Player:GetDiscordTag(localUID)
    if localDiscordTag and localDiscordTag ~= "" then
        output = output .. localDiscordTag .. " "
    end
    output = output .. self:GetPartyMembersDiscordTags(localUID)
    output = output .. self:GetArmorDistribution()
    return output
end

function Dawn:GetPartyMembersDiscordTags(localUID)
    local output = ""
    if not IsInGroup() then
        return output
    end
    local partyMembers = self:GetPartyUIDs()
    for _, uid in ipairs(partyMembers) do
        if uid and uid ~= localUID then
            local discordTag = Player:GetDiscordTag(uid)
            if discordTag and discordTag ~= "" then
                output = output .. discordTag
            end
        end
    end
    return output
end

function Dawn:GetArmorDistribution()
    local output = "\n\nArmor Distribution:"
    local armorCounts = { Plate = 0, Mail = 0, Leather = 0, Cloth = 0 }
    local playerArmorCounted = {}
    local allPlayers = self:GetPartyUIDs()
    for _, uid in ipairs(allPlayers) do
        playerArmorCounted[uid] = {}
        local charNames = Player:GetCharactersName(uid)
        if charNames then
            for _, charName in ipairs(charNames) do
                if self:IsValidCharacter(uid, charName, true) then
                    local classId = Character:GetCharacterClassId(uid, charName)
                    local className = Data.CLASS_ID_TO_ENGLISH_NAME[classId]
                    local armorType = Data.CLASS_TO_ARMOR_TYPE[className]
                    if armorType and not playerArmorCounted[uid][armorType] then
                        armorCounts[armorType] = armorCounts[armorType] + 1
                        playerArmorCounted[uid][armorType] = true
                    end
                end
            end
        end
    end
    for armorType, count in pairs(armorCounts) do
        if count > 0 then
            output = output .. string.format("\n%s: %d", armorType, count)
        end
    end
    return output
end

function Dawn:FilterKeystoneList(container, dungeonKey)
    if not container or not container.signup or not container.signup.keysEditBox then
        return
    end

    local keysEditBox = container.signup.keysEditBox
    local uids = self:GetPartyUIDs()
    if not uids or next(uids) == nil then
        return
    end

    local keyDataList = {}
    for _, uid in ipairs(uids) do
        local characters = Player:GetCharactersName(uid)
        for _, charName in ipairs(characters) do
            local keystone = Character:GetCharacterKeystone(uid, charName)

            -- Only include keys for the hovered dungeon
            if self:IsValidCharacter(uid, charName, true) and keystone.mapID == dungeonKey then
                table.insert(keyDataList, {
                    charName = charName,
                    classId = Character:GetCharacterClassId(uid, charName),
                    level = keystone.level
                })
            end
        end
    end

    local outputString = ""
    if #keyDataList == 0 then
        outputString = "No keystones found for this dungeon."
    else
        -- Sort by level (highest first)
        table.sort(keyDataList, function(a, b)
            return a.level > b.level
        end)

        -- Format the filtered list with highlight
        outputString = "|cFFFFD700Keystones for " .. Data.DUNGEON_TABLE[dungeonKey].name .. ":|r\n\n"
        for _, keyInfo in ipairs(keyDataList) do
            local classColor = Utils:GetClassColorFromID(keyInfo.classId)
            outputString = outputString .. string.format("%s%s|r: +%d\n",
                classColor,
                keyInfo.charName,
                keyInfo.level
            )
        end
    end

    keysEditBox:SetText(outputString)
end


function Dawn:IsValidCharacter(uid, charName, checkHasKey)
    local keystone = Character:GetCharacterKeystone(uid, charName)
    local isHidden = Character:GetCharacterIsHidden(uid, charName)
    if checkHasKey then
        local hasKey = Character:GetCharacterHasKey(uid, charName)
        return keystone and keystone.level and keystone.level > 0 and hasKey and not isHidden
    end
    return keystone and keystone.level and keystone.level > 0 and not isHidden
end

function Dawn:GenerateNormalSignupContent(localUID)
    local output = ""
    local uids = self:GetPartyUIDs()
    local numberOfPlayers = #uids
    output = output .. self:GetPartyMembersInfo(uids, localUID)
    local signText = Data.DAWN_SIGN[numberOfPlayers] or "Unknown"
    output = "### " .. signText .. " sign:\n" .. output
    if output:sub(-1) == "\n" then
        output = output:sub(1, -2)
    end
    return output
end

function Dawn:GetPartyMembersInfo(uids, localUID)
    local output = ""
    for _, uid in ipairs(uids) do
        if uid then
            local charactersName = Player:GetCharactersName(uid)
            if charactersName and #charactersName > 0 then
                local playerString = self:GeneratePlayerString(uid, uid ~= localUID)
                if playerString and playerString ~= "" then
                    if uid == localUID then
                        output = playerString .. output
                    else
                        output = output .. playerString
                    end
                end
            end
        end
    end
    return output
end

function Dawn:GeneratePlayerString(uid, addDiscordTag)
    local fullOutputString = ""

    local nbChar = 0
    local characterNames = Player:GetCharactersName(uid)
    for _, name in ipairs(characterNames) do
        local keystone = Character:GetCharacterKeystone(uid, name)

        -- Use our validation method, but don't require hasKey for display
        if self:IsValidCharacter(uid, name, false) then
            local roleIndicatorStr = ""
            local customRoles = Character:GetCharacterCustomRoles(uid, name)
            local mainRole = Character:GetCharacterRole(uid, name)
            if customRoles and #customRoles > 0 then
                for _, role in ipairs(customRoles) do
                    roleIndicatorStr = roleIndicatorStr .. Data.ROLES[role]
                end
            elseif mainRole and mainRole ~= "" then
                roleIndicatorStr = Data.ROLES[mainRole]
            end

            local factionStr = ""
            local faction = Character:GetCharacterFaction(uid, name)
            if faction and faction ~= "" then
                factionStr = ":" .. string.lower(faction) .. ":"
            end

            local classStr = Data.CLASS_ID_TO_ENGLISH_NAME[Character:GetCharacterClassId(uid, name)] or "No Class"
            local scoreStr = ":Raiderio: " .. Character:GetCharacterRating(uid, name)
            local keyStr = ":Keystone: "
            if keystone.level and keystone.level > 0 then
                if Character:GetCharacterHasKey(uid, name) then
                    keyStr = keyStr ..
                        string.format("+%d %s", keystone.level, keystone.mapName or "Unknown")
                else
                    keyStr = keyStr ..
                        string.format("No key")
                end
            else
                keyStr = keyStr .. "No Key"
            end
            local ilvlStr = string.format(":Armor: %d iLvl", Character:GetCharacterIlvl(uid, name))
            local tradeStr = "Can trade all :gift:"
            local charOutput = string.format("%s %s | %s | %s | %s | %s | %s",
                roleIndicatorStr,
                classStr,
                factionStr,
                scoreStr,
                keyStr,
                ilvlStr,
                tradeStr
            )

            nbChar = nbChar + 1
            fullOutputString = fullOutputString .. "** " .. charOutput .. " **\n"
        end
    end

    local discordTag = Player:GetDiscordTag(uid)
    if addDiscordTag and discordTag and discordTag ~= "" and nbChar > 0 then
        fullOutputString = string.format("|cffffcc00%s|r\n", discordTag) .. fullOutputString
    end
    return fullOutputString
end

function Dawn:PopulateKeyListFrame(container)
    if not container or not container.signup or not container.signup.keysEditBox then
        return
    end
    local keysEditBox = container.signup.keysEditBox
    local uids = self:GetPartyUIDs()
    if not uids or next(uids) == nil then
        return
    end
    local keyDataList = {}
    for _, uid in ipairs(uids) do
        local characters = Player:GetCharactersName(uid)
        for _, charName in ipairs(characters) do
            local keystone = Character:GetCharacterKeystone(uid, charName)
            local hasKey = Character:GetCharacterHasKey(uid, charName)
            if self:IsValidCharacter(uid, charName, true) then
                table.insert(keyDataList, {
                    charName = charName,
                    classId = Character:GetCharacterClassId(uid, charName),
                    level = keystone.level,
                    mapName = keystone.mapName,
                    hasKey = hasKey,
                    isHidden = false
                })
            end
        end
    end
    local outputString = ""
    if #keyDataList == 0 then
        outputString = "No keystones found in database."
    end
    table.sort(keyDataList, function(a, b)
        local mapNameA = a.mapName or ""
        local mapNameB = b.mapName or ""
        if mapNameA ~= mapNameB then
            return mapNameA < mapNameB
        else
            return a.level > b.level
        end
    end)
    for _, keyInfo in ipairs(keyDataList) do
        local classColor = Utils:GetClassColorFromID(keyInfo.classId)
        outputString = outputString .. string.format("%s%s|r: +%d %s\n",
            classColor,
            keyInfo.charName,
            keyInfo.level,
            keyInfo.mapName
        )
    end
    keysEditBox:SetText(outputString)
end

function Dawn:PopulateDungeonFrame(container)
    if not container or not container.signup or not container.signup.dungeonsContainer then
        return
    end

    local iconSize = 75
    local dungeonsContainer = container.signup.dungeonsContainer
    dungeonsContainer:ReleaseChildren()

    local cooldownContainer = AceGUI:Create("SimpleGroup")
    cooldownContainer:SetLayout("Fill")
    cooldownContainer:SetFullWidth(true)
    cooldownContainer:SetHeight(iconSize)

    local cooldownLabel = AceGUI:Create("Label")
    cooldownLabel:SetFontObject(SystemFont_Shadow_Large_Outline)
    cooldownLabel:SetFullWidth(true)
    cooldownLabel:SetJustifyH("CENTER") -- Center horizontally
    cooldownLabel:SetJustifyV("MIDDLE") -- Center vertically

    -- Use the spell ID of the first dungeon in the data table as they share the same cooldown
    local spellID
    for _, dungeon in pairs(Data.DUNGEON_TABLE) do
        spellID = dungeon.spellId
        break
    end
    if spellID then
        local spellCooldown = C_Spell.GetSpellCooldown(spellID)
        if spellCooldown and spellCooldown.isEnabled and spellCooldown.duration > 0 then
            local remaining = math.ceil(spellCooldown.duration - (GetTime() - spellCooldown.startTime))
            local hour = remaining / 3600
            local minute = (remaining % 3600) / 60
            cooldownLabel:SetText(string.format("CD: %dh %dm", hour, minute))
            cooldownLabel:SetWidth(iconSize)
        elseif spellCooldown.isEnabled then
            cooldownLabel:SetText("CD: Ready")
        end
    end
    cooldownContainer:AddChild(cooldownLabel)
    dungeonsContainer:AddChild(cooldownContainer)

    for key, dungeon in pairs(Data.DUNGEON_TABLE) do
        local maxKeyLevel = 0
        local minKeyLevel = 99999

        local uids = self:GetPartyUIDs()
        for _, uid in ipairs(uids) do
            local charactersName = Player:GetCharactersName(uid)
            for _, charName in ipairs(charactersName) do
                local keystone = Character:GetCharacterKeystone(uid, charName)

                -- Use our validation method
                if self:IsValidCharacter(uid, charName, true) and keystone.mapID == key then
                    maxKeyLevel = math.max(maxKeyLevel, keystone.level or 0)
                    minKeyLevel = math.min(minKeyLevel, keystone.level or 0)
                end
            end
        end

        local iconContainer = AceGUI:Create("SimpleGroup")
        iconContainer:SetLayout("Flow")
        iconContainer:SetWidth(iconSize + 5)
        iconContainer:SetHeight(iconSize + 5)

        local icon = AceGUI:Create("InsecureIcon")
        icon:SetImage(dungeon.icon)
        icon:SetImageSize(iconSize, iconSize)
        icon:SetBottomLabel(dungeon.name)
        icon:SetSecureAction("spell", dungeon.spellId, "player")

        -- Store dungeon info in the icon's user data
        icon:SetUserData("dungeonKey", key)
        icon:SetUserData("dungeonName", dungeon.name)

        -- Add hover functionality to filter keystone list
        icon:SetCallback("OnEnter", function()
            -- Save current dungeon key for filtering
            self.currentHoveredDungeon = key
            -- Store original text if we haven't already
            if not self.originalKeysText and container.signup.keysEditBox then
                self.originalKeysText = container.signup.keysEditBox:GetText()
            end

            -- Filter the keystone list to show only this dungeon's keys
            self:FilterKeystoneList(container, key)
        end)

        icon:SetCallback("OnLeave", function()
            -- Clear current hover state
            self.currentHoveredDungeon = nil

            -- Restore original keystone list
            if self.originalKeysText and container.signup.keysEditBox then
                container.signup.keysEditBox:SetText(self.originalKeysText)
                self.originalKeysText = nil
            end
        end)

        iconContainer:AddChild(icon)

        local keyRangeLevelStr = ""
        if minKeyLevel == maxKeyLevel then
            keyRangeLevelStr = tostring(minKeyLevel)
        else
            keyRangeLevelStr = tostring(minKeyLevel) .. " - " .. tostring(maxKeyLevel)
        end

        if maxKeyLevel > 0 then
            icon:SetTopLabel(keyRangeLevelStr)
        end

        dungeonsContainer:AddChild(iconContainer)
    end
    dungeonsContainer:DoLayout()
end
