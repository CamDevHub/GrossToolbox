local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

Dawn.partyUIDs = {}

-- Add these variables at the module level
Dawn.currentHoveredDungeon = nil
Dawn.originalKeysText = nil

-- Define module name for initialization logging
Dawn.moduleName = "Dawn"

-- Define module dependencies
local db
local addon, Character, Player, Data, Utils, Config, GrossFrame

function Dawn:Init(database, frame)
    -- Validate database parameter
    if not database then
        print(addonName .. ": Dawn module initialization failed - missing database")
        return false
    end

    -- Store database reference
    db = database

    addon = GT.addon
    if not addon then
        print(addonName .. ": Dawn module initialization failed - addon reference not found")
        return false
    end

    -- Load required modules
    Utils = GT.Modules.Utils
    if not Utils then
        print(addonName .. ": Dawn module initialization failed - Utils module not found")
        return false
    end

    Character = GT.Modules.Character
    if not Character then
        print(addonName .. ": Dawn module initialization failed - Character module not found")
        return false
    end

    Player = GT.Modules.Player
    if not Player then
        print(addonName .. ": Dawn module initialization failed - Player module not found")
        return false
    end

    Data = GT.Modules.Data
    if not Data then
        print(addonName .. ": Dawn module initialization failed - Data module not found")
        return false
    end

    Config = GT.Modules.Config
    if not Config then
        print(addonName .. ": Dawn module initialization failed - Config module not found")
        return false
    end

    GrossFrame = GT.Modules.GrossFrame
    if not GrossFrame then
        print(addonName .. ": Dawn module initialization failed - GrossFrame module not found")
        return false
    end

    -- Register UI tabs
    local signupTab = {
        text = "Signup",
        value = "signup",
        drawFunc = function(container) self:DrawDataFrame(container) end,
        populateFunc = function(container) self:PopulateDataFrame(container) end,
        module = Dawn
    }

    local playerEditorTab = {
        text = "Player Editor",
        value = "playerEditor",
        drawFunc = function(container) self:DrawPlayerEditorFrame(container) end,
        populateFunc = function(container) self:PopulatePlayerEditorFrame(container) end,
        module = Dawn
    }

    GrossFrame:RegisterTab(playerEditorTab)
    GrossFrame:RegisterTab(signupTab)

    -- Log successful initialization
    Utils:DebugPrint("Dawn module initialized successfully")
    return true
end

function Dawn:GetPartyUIDs()
    if not self.partyUIDs then
        self.partyUIDs = {}
    end
    -- Get local player's UID and add it to partyUIDs if it exists
    local localUID = GT.addon:GetUID()
    if localUID then
        self:addUID(localUID)
    end

    return self.partyUIDs
end

function Dawn:addUID(uid)
    if not self.partyUIDs then
        self.partyUIDs = {}
    end
    if not Utils:TableContainsValue(self.partyUIDs, uid) then
        table.insert(self.partyUIDs, uid)
    end
end

function Dawn:RemoveUID(uid)
    if not self.partyUIDs then return end
    for i, v in ipairs(self.partyUIDs) do
        if v == uid then
            table.remove(self.partyUIDs, i)
            break
        end
    end
end

function Dawn:ClearPartyUIDs()
    self.partyUIDs = {}
end

function Dawn:DrawDataFrame(container)
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
    requestButton:SetCallback("OnClick", Dawn.RequestData)
    dataTabContainer:AddChild(requestButton)

    local teamTakeCheckbox = AceGUI:Create("CheckBox")
    teamTakeCheckbox:SetLabel("Team Take")
    teamTakeCheckbox:SetWidth(200)
    teamTakeCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        Dawn:PopulateDataFrame(container)
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

function Dawn:PopulateDataFrame(container)
    Dawn:PopulateSignupFrame(container)
    Dawn:PopulateKeyListFrame(container)
    Dawn:PopulateDungeonFrame(container)
end

function Dawn:PopulatePlayerEditorFrame(container)
    if not container or not container.signup or not container.signup.playerEditorScroll then
        return
    end

    local uids = self:GetPartyUIDs()
    if not uids or next(uids) == nil then
        return
    end

    local scroll = container.signup.playerEditorScroll
    scroll:ReleaseChildren()
    scroll:SetScroll(0)

    for _, uid in ipairs(uids) do
        local discordTag = Player:GetDiscordTag(uid)
        if discordTag and discordTag ~= "" then
            local playerHeader = AceGUI:Create("Heading")
            playerHeader:SetText(discordTag)
            playerHeader:SetFullWidth(true)
            scroll:AddChild(playerHeader)

            local charactersName = Player:GetCharactersName(uid)
            for _, charFullName in ipairs(charactersName) do
                local keystone = Character:GetCharacterKeystone(uid, charFullName)
                local rating = Character:GetCharacterRating(uid, charFullName)
                local classId = Character:GetCharacterClassId(uid, charFullName)
                local charGroup = AceGUI:Create("SimpleGroup")
                local hasKey = Character:GetCharacterHasKey(uid, charFullName)
                local isHidden = Character:GetCharacterIsHidden(uid, charFullName)

                if keystone and keystone.level and keystone.level > 0 then
                    charGroup:SetLayout("Flow")
                    charGroup:SetFullWidth(true)

                    local nameLabel = AceGUI:Create("Label")
                    nameLabel:SetText(string.format("%s", charFullName))
                    nameLabel:SetWidth(180)
                    nameLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(nameLabel)

                    local ratingLabel = AceGUI:Create("Label")
                    local ratingColor = C_ChallengeMode.GetDungeonScoreRarityColor(rating) or { r = 1, g = 1, b = 1 }
                    local coloredRatingText = string.format("|cff%02x%02x%02x %d|r",
                        ratingColor.r * 255,
                        ratingColor.g * 255,
                        ratingColor.b * 255,
                        rating)
                    ratingLabel:SetText(coloredRatingText)
                    ratingLabel:SetWidth(120)
                    ratingLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(ratingLabel)

                    local classLabel = AceGUI:Create("Label")
                    local className = Data.CLASS_ID_TO_ENGLISH_NAME[classId] or "Unknown Class"
                    local classColorCode = Utils:GetClassColorFromID(classId)
                    classLabel:SetText(string.format("%s%s|r", classColorCode, className))
                    classLabel:SetWidth(120)
                    classLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(classLabel)

                    local noKeyForBoostCheckbox = AceGUI:Create("CheckBox")
                    noKeyForBoostCheckbox:SetLabel("No Key");
                    noKeyForBoostCheckbox:SetType("checkbox");
                    noKeyForBoostCheckbox:SetWidth(100);
                    noKeyForBoostCheckbox:SetUserData("uid", uid);
                    noKeyForBoostCheckbox:SetUserData("charFullName", charFullName);
                    noKeyForBoostCheckbox:SetValue(not hasKey)
                    noKeyForBoostCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                        local cbUID = widget:GetUserData("uid")
                        local cbCharFullName = widget:GetUserData("charFullName")
                        Character:SetCharacterHasKey(cbUID, cbCharFullName, not isChecked)
                    end)
                    charGroup:AddChild(noKeyForBoostCheckbox)

                    local hideCharCheckbox = AceGUI:Create("CheckBox")
                    hideCharCheckbox:SetLabel("Hide");
                    hideCharCheckbox:SetType("checkbox");
                    hideCharCheckbox:SetWidth(80);
                    hideCharCheckbox:SetUserData("uid", uid);
                    hideCharCheckbox:SetUserData("charFullName", charFullName);
                    hideCharCheckbox:SetValue(isHidden)
                    hideCharCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                        local cbUID = widget:GetUserData("uid")
                        local cbCharFullName = widget:GetUserData("charFullName")
                        Character:SetCharacterIsHidden(cbUID, cbCharFullName, isChecked)
                    end)
                    charGroup:AddChild(hideCharCheckbox)

                    -- Role icons mapping using built-in game icons
                    local role_tex_file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp"
                    local role_t = "\124T" .. role_tex_file .. ":%d:%d:"
                    local roleIcons = {
                        TANK = role_t .. "0:0:64:64:0:19:22:41\124t",
                        HEALER = role_t .. "0:0:64:64:20:39:1:20\124t",
                        DAMAGER = role_t .. "0:0:64:64:20:39:22:41\124t"
                    }

                    local roleGroup = AceGUI:Create("SimpleGroup")
                    roleGroup:SetLayout("Flow")
                    roleGroup:SetWidth(300) -- Adjust width as needed
                    charGroup:AddChild(roleGroup)

                    local checkBoxes = {}
                    for role, _ in pairs(Data.ROLES) do
                        local checkbox = AceGUI:Create("CheckBox")
                        -- Use an empty label since we'll display the icon
                        checkbox:SetLabel(roleIcons[role])
                        checkbox:SetType("checkbox")
                        checkbox:SetWidth(40) -- Make it more compact

                        local customRoles = Character:GetCharacterCustomRoles(uid, charFullName)
                        if customRoles and #customRoles > 0 then
                            checkbox:SetValue(Utils:TableContainsValue(customRoles, role))
                        end

                        checkbox:SetUserData("uid", uid)
                        checkbox:SetUserData("charFullName", charFullName)
                        checkbox:SetUserData("role", role)
                        checkbox:SetUserData("checkBoxes", checkBoxes)

                        checkbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                            local cbUID = widget:GetUserData("uid")
                            local cbCharFullName = widget:GetUserData("charFullName")
                            local otherCheckBoxes = widget:GetUserData("checkBoxes")
                            local rolesToSet = {}
                            for roleValue, cb in pairs(otherCheckBoxes) do
                                if cb:GetValue() then
                                    table.insert(rolesToSet, roleValue)
                                end
                            end
                            table.sort(rolesToSet, function(a, b)
                                return a > b
                            end)
                            Character:SetCharacterCustomRoles(cbUID, cbCharFullName, rolesToSet)
                        end)

                        roleGroup:AddChild(checkbox)
                        checkBoxes[role] = checkbox
                    end
                end

                charGroup:DoLayout()
                scroll:AddChild(charGroup)
            end
        end
    end

    scroll:DoLayout()
end

function Dawn:PopulateSignupFrame(container)
    -- Validate container and required UI elements
    if not container or not container.signup or not container.signup.playersEditBox then
        Utils:DebugPrint("PopulateDisplayFrame: Missing required UI elements")
        return
    end

    local playersEditBox = container.signup.playersEditBox
    local teamTakeCheckbox = container.signup.teamTakeCheckbox

    -- Get local discord tag
    local localDiscordTag = Config:GetDiscordTag()
    if not localDiscordTag or localDiscordTag == "" then
        playersEditBox:SetText("Discord handle not set bro !")
        return
    end

    -- Get local player's UID
    local localUID = addon:GetUID()
    if not localUID then
        Utils:DebugPrint("PopulateDisplayFrame: Could not get local player's UID")
        playersEditBox:SetText("Could not get your UID")
        return
    end

    -- Generate appropriate content based on checkbox state
    local fullOutputString = ""
    if teamTakeCheckbox:GetValue() then
        fullOutputString = self:GenerateTeamTakeContent(localUID)
    else
        fullOutputString = self:GenerateNormalSignupContent(localUID)
    end

    -- Set and highlight text in edit box
    playersEditBox:SetText(fullOutputString)
    playersEditBox:HighlightText(0, 9999)
end

-- Generate content for team take mode
function Dawn:GenerateTeamTakeContent(localUID)
    local output = "### Team Take\n"

    -- Add local player's discord tag
    local localDiscordTag = Player:GetDiscordTag(localUID)
    if localDiscordTag and localDiscordTag ~= "" then
        output = output .. localDiscordTag .. " "
    end

    -- Add group members' discord tags
    output = output .. self:GetPartyMembersDiscordTags(localUID)

    -- Add armor type distribution
    output = output .. self:GetArmorDistribution()

    return output
end

-- Get all party members' discord tags (excluding local player)
function Dawn:GetPartyMembersDiscordTags(localUID)
    local output = ""

    -- Only process if in a group
    if not IsInGroup() then
        return output
    end

    local partyMembers = self:GetPartyUIDs()
    for _, uid in ipairs(partyMembers) do
        -- Skip local player (already processed)
        if uid and uid ~= localUID then
            local discordTag = Player:GetDiscordTag(uid)
            if discordTag and discordTag ~= "" then
                output = output .. discordTag
            end
        end
    end

    return output
end

-- Calculate and format armor type distribution
function Dawn:GetArmorDistribution()
    local output = "\n\nArmor Distribution:"
    local armorCounts = {
        Plate = 0,
        Mail = 0,
        Leather = 0,
        Cloth = 0
    }

    -- Count all characters (local and party members)
    -- Track armor types already counted per player
    local playerArmorCounted = {}

    local allPlayers = self:GetPartyUIDs()
    for _, uid in ipairs(allPlayers) do
        -- Initialize tracking for this player
        playerArmorCounted[uid] = {}

        local charNames = Player:GetCharactersName(uid)
        if charNames then
            for _, charName in ipairs(charNames) do
                if self:IsValidCharacter(uid, charName, true) then
                    local classId = Character:GetCharacterClassId(uid, charName)
                    local className = Data.CLASS_ID_TO_ENGLISH_NAME[classId]
                    local armorType = Data.CLASS_TO_ARMOR_TYPE[className]

                    -- Only count each armor type once per player
                    if armorType and not playerArmorCounted[uid][armorType] then
                        armorCounts[armorType] = armorCounts[armorType] + 1
                        playerArmorCounted[uid][armorType] = true
                    end
                end
            end
        end
    end

    -- Add armor counts to output
    for armorType, count in pairs(armorCounts) do
        if count > 0 then
            output = output .. string.format("\n%s: %d", armorType, count)
        end
    end

    return output
end

-- Check if a character is valid for display and counting
-- Determines if a character has a valid keystone and isn't hidden
function Dawn:IsValidCharacter(uid, charName, checkHasKey)
    -- Get character data
    local keystone = Character:GetCharacterKeystone(uid, charName)
    local isHidden = Character:GetCharacterIsHidden(uid, charName)

    -- Optionally check if character has a key for boosting
    if checkHasKey then
        local hasKey = Character:GetCharacterHasKey(uid, charName)
        return keystone and keystone.level and keystone.level > 0 and hasKey and not isHidden
    end

    -- Standard validation: has keystone and not hidden
    return keystone and keystone.level and keystone.level > 0 and not isHidden
end

-- Generate content for normal signup mode
function Dawn:GenerateNormalSignupContent(localUID)
    -- Initialize output variables
    local output = ""
    local uids = self:GetPartyUIDs()
    -- Add group members' info if in a group
    local numberOfPlayers = #uids
    output = output .. self:GetPartyMembersInfo(uids, localUID)
    -- Add header with appropriate sign based on group size
    local signText = Data.DAWN_SIGN[numberOfPlayers] or "Unknown"
    output = "### " .. signText .. " sign:\n" .. output

    -- Remove trailing newline if present
    if output:sub(-1) == "\n" then
        output = output:sub(1, -2)
    end

    return output
end

-- Get all party members' character information
function Dawn:GetPartyMembersInfo(uids, localUID)
    local output = ""
    -- Process each group member
    for _, uid in ipairs(uids) do
        -- Skip local player (already processed)
        if uid then
            local charactersName = Player:GetCharactersName(uid)

            -- Only add players with characters
            if charactersName and #charactersName > 0 then
                local playerString = self:GeneratePlayerString(uid, uid ~= localUID)

                -- Add to output if player has valid data
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

            -- Use our validation method with hasKey check
            if self:IsValidCharacter(uid, charName, true) then
                table.insert(keyDataList, {
                    charName = charName,
                    level = keystone.level or 0,
                    mapName = keystone.mapName or "Unknown",
                    hasKey = hasKey,
                    isHidden = false -- Already filtered by IsValidCharacter
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
        -- Find character's class for coloring
        local classColor = "|cFFFFFFFF" -- Default to white
        for _, uid in ipairs(uids) do
            local classId = Character:GetCharacterClassId(uid, keyInfo.charName)
            if classId then
                classColor = Utils:GetClassColorFromID(classId)
                break
            end
        end

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

-- New function to filter the keystone list
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
                    level = keystone.level or 0,
                    hasKey = Character:GetCharacterHasKey(uid, charName)
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
            local classId
            for _, uid in ipairs(uids) do
                local tempClassId = Character:GetCharacterClassId(uid, keyInfo.charName)
                if tempClassId then
                    classId = tempClassId
                    break
                end
            end

            local classColor = Utils:GetClassColorFromID(classId)

            outputString = outputString .. string.format("%s%s|r: +%d\n",
                classColor,
                keyInfo.charName,
                keyInfo.level
            )
        end
    end

    keysEditBox:SetText(outputString)
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

    local payload = {
        uid = uid,
    }

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
        print(addonName, ": You must be in a party to request UID.")
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
