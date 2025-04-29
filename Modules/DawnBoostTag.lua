local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

Dawn.data = {}
local db
local Character, Player, Data, Utils, Config, GrossFrame
function Dawn:Init(database, frame)
	-- Validate database parameter
	if not database then
		print(addonName .. ": Error: Dawn module initialization failed - missing database")
		return false
	end
	
	-- Store database reference
	db = database
	
	-- Validate GT.Modules exists
	if not GT or not GT.Modules then
		print(addonName .. ": Error: Dawn module initialization failed - GT.Modules not found")
		return false
	end
	
	-- Define required modules and their local variable references
	local requiredModules = {
		{ name = "Utils", ref = function(module) Utils = module end },
		{ name = "Character", ref = function(module) Character = module end },
		{ name = "Player", ref = function(module) Player = module end },
		{ name = "Data", ref = function(module) Data = module end },
		{ name = "Config", ref = function(module) Config = module end },
		{ name = "GrossFrame", ref = function(module) GrossFrame = module end }
	}
	
	-- Load all required modules
	for _, moduleInfo in ipairs(requiredModules) do
		local module = GT.Modules[moduleInfo.name]
		if not module then
			print(addonName .. ": Error: Dawn module initialization failed - " .. moduleInfo.name .. " module not found")
			return false
		end
		-- Set the local reference to the module
		moduleInfo.ref(module)
	end
	
	-- Register UI tabs
	self:RegisterTabs()
	
	-- Report successful initialization
	Utils:DebugPrint("Dawn module initialized successfully")
	return true
end

-- Register UI tabs with GrossFrame
function Dawn:RegisterTabs()
	-- Signup tab configuration
	local signupTab = {
		text = "Signup",
		value = "signup",
		drawFunc = function(container) self:DrawDataFrame(container) end,
		populateFunc = function(container) self:PopulateDataFrame(container) end,
		module = Dawn
	}
	
	-- Player Editor tab configuration
	local playerEditorTab = {
		text = "Player Editor",
		value = "playerEditor",
		drawFunc = function(container) self:DrawPlayerEditorFrame(container) end,
		populateFunc = function(container) self:PopulatePlayerEditorFrame(container) end,
		module = Dawn
	}
	
	-- Register tabs with GrossFrame
	GrossFrame:RegisterTab(playerEditorTab)
	GrossFrame:RegisterTab(signupTab)
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
	Dawn:PopulateDisplayFrame(container)
	Dawn:PopulateKeyListFrame(container)
	Dawn:PopulateDungeonFrame(container)
end

function Dawn:PopulatePlayerEditorFrame(container)
	if not container or not container.signup or not container.signup.playerEditorScroll then
		return
	end

	local bnets = Player:GetBNetOfPartyMembers()
	if not bnets or next(bnets) == nil then
		return
	end

	local scroll = container.signup.playerEditorScroll
	scroll:ReleaseChildren()
	scroll:SetScroll(0)

	for _, bnet in ipairs(bnets) do
		local discordTag = Player:GetDiscordTag(bnet)
		if discordTag and discordTag ~= "" then
			
			local playerHeader = AceGUI:Create("Heading")
			playerHeader:SetText(discordTag)
			playerHeader:SetFullWidth(true)
			scroll:AddChild(playerHeader)

			local charactersName = Player:GetCharactersName(bnet)
			for _, charFullName in ipairs(charactersName) do
				local keystone = Character:GetCharacterKeystone(bnet, charFullName)
				local rating = Character:GetCharacterRating(bnet, charFullName)
				local classId = Character:GetCharacterClassId(bnet, charFullName)
				local charGroup = AceGUI:Create("SimpleGroup")
				local hasKey = Character:GetCharacterHasKey(bnet, charFullName)
				local isHidden = Character:GetCharacterIsHidden(bnet, charFullName)

				if keystone and keystone.level and keystone.level > 0 then
					charGroup:SetLayout("Flow")
					charGroup:SetFullWidth(true)

					local nameLabel = AceGUI:Create("Label")
					nameLabel:SetText(string.format("%s", charFullName))
					nameLabel:SetWidth(140)
					charGroup:AddChild(nameLabel)

					local ratingLabel = AceGUI:Create("Label")
					ratingLabel:SetText(string.format("Rating: %d", rating))
					ratingLabel:SetWidth(140)
					charGroup:AddChild(ratingLabel)

					local classLabel = AceGUI:Create("Label")
					classLabel:SetText(string.format("%s", Data.CLASS_ID_TO_ENGLISH_NAME[classId] or "Unknown Class"))
					classLabel:SetWidth(140)
					charGroup:AddChild(classLabel)
					
					local noKeyForBoostCheckbox = AceGUI:Create("CheckBox")
					noKeyForBoostCheckbox:SetLabel("No Key");
					noKeyForBoostCheckbox:SetType("checkbox");
					noKeyForBoostCheckbox:SetWidth(100);
					noKeyForBoostCheckbox:SetUserData("bnet", bnet);
					noKeyForBoostCheckbox:SetUserData("charFullName", charFullName);
					noKeyForBoostCheckbox:SetValue(not hasKey)
					noKeyForBoostCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
						local cbBnet = widget:GetUserData("bnet")
						local cbCharFullName = widget:GetUserData("charFullName")
						Character:SetCharacterHasKey(cbBnet, cbCharFullName, not isChecked)
					end)
					charGroup:AddChild(noKeyForBoostCheckbox)

					local hideCharCheckbox = AceGUI:Create("CheckBox")
					hideCharCheckbox:SetLabel("Hide");
					hideCharCheckbox:SetType("checkbox");
					hideCharCheckbox:SetWidth(100);
					hideCharCheckbox:SetUserData("bnet", bnet);
					hideCharCheckbox:SetUserData("charFullName", charFullName);
					hideCharCheckbox:SetValue(isHidden)
					hideCharCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
						local cbBnet = widget:GetUserData("bnet")
						local cbCharFullName = widget:GetUserData("charFullName")
						Character:SetCharacterIsHidden(cbBnet, cbCharFullName, isChecked)
					end)
					charGroup:AddChild(hideCharCheckbox)

					local checkBoxes = {}
					for role, _ in pairs(Data.ROLES) do
						local checkbox = AceGUI:Create("CheckBox")
						checkbox:SetLabel(role);
						checkbox:SetType("checkbox");

						local customRoles = Character:GetCharacterCustomRoles(bnet, charFullName)
						if customRoles and #customRoles > 0 then
							checkbox:SetValue(Utils:TableContainsValue(customRoles, role))
						end
						checkbox:SetUserData("bnet", bnet);
						checkbox:SetUserData("charFullName", charFullName);
						checkbox:SetUserData("role", role);
						checkbox:SetUserData("checkBoxes", checkBoxes);
						checkbox:SetWidth(100);
						checkbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
							local cbBnet = widget:GetUserData("bnet")
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
							Character:SetCharacterCustomRoles(cbBnet, cbCharFullName, rolesToSet)
						end);
						charGroup:AddChild(checkbox)
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

function Dawn:PopulateDisplayFrame(container)
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
    
    -- Get local player's BNet tag
    local localBnet = Player:GetBNetTagForUnit("player")
    if not localBnet then
        Utils:DebugPrint("PopulateDisplayFrame: Could not get local player's BNet tag")
        playersEditBox:SetText("Could not get your BattleNet tag")
        return
    end
    
    -- Generate appropriate content based on checkbox state
    local fullOutputString = ""
    if teamTakeCheckbox:GetValue() then
        fullOutputString = self:GenerateTeamTakeContent(localBnet)
    else
        fullOutputString = self:GenerateNormalSignupContent(localBnet)
    end
    
    -- Set and highlight text in edit box
    playersEditBox:SetText(fullOutputString)
    playersEditBox:HighlightText(0, 9999)
end

-- Generate content for team take mode
function Dawn:GenerateTeamTakeContent(localBnet)
    local output = "### Team Take\n"
    
    -- Add local player's discord tag
    local localDiscordTag = Player:GetDiscordTag(localBnet)
    if localDiscordTag and localDiscordTag ~= "" then
        output = output .. localDiscordTag .. "\n"
    end
    
    -- Add group members' discord tags
    output = output .. self:GetPartyMembersDiscordTags(localBnet)
    
    -- Add armor type distribution
    output = output .. self:GetArmorDistribution()
    
    return output
end

-- Get all party members' discord tags (excluding local player)
function Dawn:GetPartyMembersDiscordTags(localBnet)
    local output = ""
    
    -- Only process if in a group
    if not IsInGroup() then
        return output
    end
    
    local partyMembers = Player:GetBNetOfPartyMembers()
    for _, bnet in ipairs(partyMembers) do
        -- Skip local player (already processed)
        if bnet and bnet ~= localBnet then
            local discordTag = Player:GetDiscordTag(bnet)
            if discordTag and discordTag ~= "" then
                output = output .. discordTag .. "\n"
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
    local allPlayers = Player:GetBNetOfPartyMembers()
    for _, bnet in ipairs(allPlayers) do
        local charNames = Player:GetCharactersName(bnet)
        if charNames then
            for _, charName in ipairs(charNames) do
                if self:IsValidCharacter(bnet, charName, true) then
                    local classId = Character:GetCharacterClassId(bnet, charName)
                    local className = Data.CLASS_ID_TO_ENGLISH_NAME[classId]
                    local armorType = Data.CLASS_TO_ARMOR_TYPE[className]
                    if armorType then
                        armorCounts[armorType] = armorCounts[armorType] + 1
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
function Dawn:IsValidCharacter(bnet, charName, checkHasKey)
    -- Get character data
    local keystone = Character:GetCharacterKeystone(bnet, charName)
    local isHidden = Character:GetCharacterIsHidden(bnet, charName)
    
    -- Optionally check if character has a key for boosting
    if checkHasKey then
        local hasKey = Character:GetCharacterHasKey(bnet, charName)
        return keystone and keystone.level and keystone.level > 0 and hasKey and not isHidden
    end
    
    -- Standard validation: has keystone and not hidden
    return keystone and keystone.level and keystone.level > 0 and not isHidden
end

-- Generate content for normal signup mode
function Dawn:GenerateNormalSignupContent(localBnet)
    -- Initialize output variables
    local numberOfPlayers = 1
    local output = ""
    
    -- Add local player's info
    local localPlayerString = self:GeneratePlayerString(localBnet, false)
    if localPlayerString and localPlayerString ~= "" then
        output = localPlayerString .. "\n"
    end
    
    -- Add group members' info if in a group
    if IsInGroup() then
        output = output .. self:GetPartyMembersInfo(localBnet, numberOfPlayers)
    end
    
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
function Dawn:GetPartyMembersInfo(localBnet, numberOfPlayers)
    local output = ""
    local partyMembers = Player:GetBNetOfPartyMembers()
    
    -- Process each group member
    for _, bnet in ipairs(partyMembers) do
        -- Skip local player (already processed)
        if bnet and bnet ~= localBnet then
            local charactersName = Player:GetCharactersName(bnet)
            
            -- Only add players with characters
            if charactersName and #charactersName > 0 then
                local playerString = self:GeneratePlayerString(bnet, true)
                
                -- Add to output if player has valid data
                if playerString and playerString ~= "" then
                    output = output .. playerString .. "\n"
                    numberOfPlayers = numberOfPlayers + 1
                end
            end
        end
    end
    
    return output, numberOfPlayers
end

function Dawn:PopulateKeyListFrame(container)
    if not container or not container.signup or not container.signup.keysEditBox then
        return
    end

    local keysEditBox = container.signup.keysEditBox
    local bnets = Player:GetBNetOfPartyMembers()
    if not bnets or next(bnets) == nil then
        return
    end

    local keyDataList = {}
    for _, bnet in ipairs(bnets) do
        local characters = Player:GetCharactersName(bnet)
        for _, charName in ipairs(characters) do
            local keystone = Character:GetCharacterKeystone(bnet, charName)
            local hasKey = Character:GetCharacterHasKey(bnet, charName)
            
            -- Use our validation method with hasKey check
            if self:IsValidCharacter(bnet, charName, true) then
                table.insert(keyDataList, {
                    charName = charName,
                    level = keystone.level or 0,
                    mapName = keystone.mapName or "Unknown",
                    hasKey = hasKey,
                    isHidden = false  -- Already filtered by IsValidCharacter
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
        outputString = outputString .. string.format("%s: +%d %s\n",
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

    for key, dungeon in pairs(Data.DUNGEON_TABLE) do
        local maxKeyLevel = 0
        local minKeyLevel = 99999

        local partyBnets = Player:GetBNetOfPartyMembers()
        for _, bnet in ipairs(partyBnets) do
            local charactersName = Player:GetCharactersName(bnet)
            for _, charName in ipairs(charactersName) do
                local keystone = Character:GetCharacterKeystone(bnet, charName)
                
                -- Use our validation method
                if self:IsValidCharacter(bnet, charName, true) and keystone.mapID == key then
                    maxKeyLevel = math.max(maxKeyLevel, keystone.level or 0)
                    minKeyLevel = math.min(minKeyLevel, keystone.level or 0)
                end
            end
        end

        if maxKeyLevel > 0 then
            local iconContainer = AceGUI:Create("SimpleGroup")
            iconContainer:SetLayout("Fill")
            iconContainer:SetWidth(iconSize + 5)
            iconContainer:SetHeight(iconSize + 5)

            local icon = AceGUI:Create("Icon")
            icon:SetImage(dungeon.icon)
            icon:SetImageSize(iconSize, iconSize)
            icon:SetLabel(dungeon.name)
            icon:SetUserData("spellId", dungeon.spellId)
            iconContainer:AddChild(icon)

            local keyRangeLevelStr = ""
            if minKeyLevel == maxKeyLevel then
                keyRangeLevelStr = tostring(minKeyLevel)
            else
                keyRangeLevelStr = tostring(minKeyLevel) .. " - " .. tostring(maxKeyLevel)
            end

            local levelLabel = AceGUI:Create("Label")
            levelLabel:SetText(keyRangeLevelStr)
            levelLabel:SetFontObject(GameFontNormalHuge)
            levelLabel:SetColor(0, 1, 0)
            levelLabel:SetJustifyH("CENTER")
            levelLabel:SetJustifyV("MIDDLE")
            levelLabel:SetWidth(iconSize)
            levelLabel:SetHeight(15)
            levelLabel.frame:SetPoint("CENTER", icon.frame, "TOP", 0, -20)
            iconContainer:AddChild(levelLabel)

            dungeonsContainer:AddChild(iconContainer)
        end
    end
    dungeonsContainer:DoLayout()
end

function Dawn:GeneratePlayerString(bnet, addDiscordTag)
    local fullOutputString = ""

    local nbChar = 0
    local characterNames = Player:GetCharactersName(bnet)
    for _, name in ipairs(characterNames) do
        local keystone = Character:GetCharacterKeystone(bnet, name)
        
        -- Use our validation method, but don't require hasKey for display
        if self:IsValidCharacter(bnet, name, false) then
            local roleIndicatorStr = ""
            local customRoles = Character:GetCharacterCustomRoles(bnet, name)
            local mainRole = Character:GetCharacterRole(bnet, name)
            if customRoles and #customRoles > 0 then
                for _, role in ipairs(customRoles) do
                    roleIndicatorStr = roleIndicatorStr .. Data.ROLES[role]
                end
            elseif mainRole and mainRole ~= "" then
                roleIndicatorStr = Data.ROLES[mainRole]
            end

            local factionStr = ""
            local faction = Character:GetCharacterFaction(bnet, name)
            if faction and faction ~= "" then
                factionStr = ":" .. string.lower(faction) .. ":"
            end

            local classStr = Data.CLASS_ID_TO_ENGLISH_NAME[Character:GetCharacterClassId(bnet, name)] or "No Class"
            local scoreStr = ":Raiderio: " .. Character:GetCharacterRating(bnet, name)
            local keyStr = ":Keystone: "
            if keystone.level and keystone.level > 0 then
                if Character:GetCharacterHasKey(bnet, name) then
                    keyStr = keyStr ..
                    string.format("+%d %s", keystone.level, keystone.mapName or "Unknown")
                else
                    keyStr = keyStr ..
                    string.format("No key")
                end
            else
                keyStr = keyStr .. "No Key"
            end
            local ilvlStr = string.format(":Armor: %d iLvl", Character:GetCharacterIlvl(bnet, name))
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

    local discordTag = Player:GetDiscordTag(bnet)
    if addDiscordTag and discordTag and discordTag ~= "" and nbChar > 0 then
        fullOutputString = string.format("|cffffcc00%s|r\n", discordTag) .. fullOutputString
    end
    return fullOutputString
end

function Dawn:SendCharacterData()
	local bnet = Player:GetBNetTagForUnit("player")
	if not bnet then return end

	local characters = Player:GetCharactersForPlayer(bnet)
	if not characters or not db.global.config.discordTag then return end

	local payload = {
		bnet = bnet,
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

function Dawn:RequestData()
	if IsInGroup() then
		local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
		LibStub("AceComm-3.0"):SendCommMessage(GT.COMM_PREFIX, GT.headers.request, channel)
		print(addonName, ": Requesting data from party members...")
	else
		print(addonName, ": You must be in a party to request data.")
	end
end

function Dawn:OnCommReceived(_, message, _, sender)
	if type(message) ~= "string" then return end

	if message == GT.headers.request then
		if not UnitIsUnit("player", sender) then 
			print(addonName, ": Received data request from", sender, ". Sending data.")
			self:SendCharacterData()
		end
	elseif string.sub(message, 1, 10) == GT.headers.player then
		local success, data = AceSerializer:Deserialize(string.sub(message, 11))

		if not success or type(data) ~= "table" or not data.bnet or not data.characters then
			print(addonName, ": Invalid or malformed data from", sender)
			return
		end

		local bnet = data.bnet
		local incomingChars = data.characters
		local senderDiscordTag = data.discordTag or "" 


		local localPlayerEntry = Player:GetOrCreatePlayerData(bnet)
		localPlayerEntry.discordTag = senderDiscordTag

        if type(incomingChars) == "table" then
            for charName, charData in pairs(incomingChars) do
                 if type(charData) == "table" then
					Character:SetCharacterData(bnet, charName, charData)
                 end
            end
        end

		print(addonName, ": Received and processed data from", sender)

        local frame = Dawn.mainFrame
        if frame and frame:IsVisible() then
			print(addonName, "Repopulating visible frame...")
			self:PopulateDataFrame()
        end
	end
end
