local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

Dawn.data = {}
local db
local Character, Player, Data, Utils, Config
function Dawn:Init(database)
	db = database
	if not db then
		print(addonName, "Error: Dawn received nil database!"); return
	end
	print(addonName, "- Dawn Module Initialized with DB.")

	Utils = GT.Modules.Utils
	if not Utils then return end

	Character = GT.Modules.Character
	if not Character then return end

	Player = GT.Modules.Player
	if not Player then return end

	Data = GT.Modules.Data
	if not Data then return end

	Config = GT.Modules.Config
	if not Config then return end
end

-- Update data using AceDB structure (db.global.char)
function Dawn:UpdateData()
	local bnet = Player:GetBNetTagForUnit("player")
	local fullName = Character:GetFullName("player")

	Player:SetDiscordTag(bnet, Config:GetDiscordTag())
	Character:BuildCurrentCharacter(bnet, fullName)
end

function Dawn:DrawDataFrame(frame, container)
	-- === Tab 1: Data (Players) ===
    local dataTabContainer = AceGUI:Create("SimpleGroup")
    dataTabContainer:SetLayout("Flow")
    dataTabContainer:SetAutoAdjustHeight(false)
    container:AddChild(dataTabContainer)

    local playersEditBox = AceGUI:Create("MultiLineEditBox")
    playersEditBox:SetLabel("Player Data")
    playersEditBox:DisableButton(true)
    playersEditBox:SetWidth(650)
    playersEditBox:SetHeight(500)
    dataTabContainer:AddChild(playersEditBox)
    frame.playersEditBox = playersEditBox

    local keysEditBox = AceGUI:Create("MultiLineEditBox")
    keysEditBox:SetLabel("Keystone List")
    keysEditBox:DisableButton(true)
    keysEditBox:SetWidth(250)
    keysEditBox:SetHeight(500)
    dataTabContainer:AddChild(keysEditBox)
    frame.keysEditBox = keysEditBox

	local dungeonsContainer = AceGUI:Create("SimpleGroup")
	dungeonsContainer:SetLayout("Flow")
	dungeonsContainer:SetWidth(160)
	dataTabContainer:AddChild(dungeonsContainer)
	frame.dungeonsContainer = dungeonsContainer

    local requestButton = AceGUI:Create("Button")
    requestButton:SetText("Request Party Data")
    requestButton:SetWidth(200)
    requestButton:SetCallback("OnClick", Dawn.RequestData)
    dataTabContainer:AddChild(requestButton)
    frame.requestButton = requestButton
end

function Dawn:DrawPlayerEditorFrame(frame, container)
	 -- === Tab 2: Player Editor ===
	 local playerEditorTabContainer = AceGUI:Create("ScrollFrame")
	 playerEditorTabContainer:SetLayout("Flow")
	 container:AddChild(playerEditorTabContainer)
	 frame.playerEditorScroll = playerEditorTabContainer
end

function Dawn:GetOrCreateMainFrame()
    if Dawn.mainFrame then
        return Dawn.mainFrame
    end


    local frame = AceGUI:Create("Frame")
    frame:SetTitle("GrossToolbox")
    frame:SetLayout("Fill")
    frame:SetWidth(1120)
    frame:SetHeight(650)
    frame:EnableResize(false)
	frame:SetStatusText("GrossToolbox - Dawn Module")

	local function CloseFrame()
        AceGUI:Release(frame)
        Dawn.mainFrame = nil
    end
    frame:SetCallback("OnClose", function(widget) CloseFrame() end)

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
        {text = "Data", value = "data"},
        {text = "Player Editor", value = "players"}
    })
    frame:AddChild(tabGroup)
    frame.tabGroup = tabGroup

	tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
		widget:ReleaseChildren()
		if group == "data" then
			self:DrawDataFrame(frame, widget)
			self:PopulateDataFrame()
			frame.playersEditBox:SetFocus()
		elseif group == "players" then
			self:DrawPlayerEditorFrame(frame, widget)
			self:PopulatePlayerEditorFrame()
		end
    end)

    tabGroup:SelectTab("data")

    Dawn.mainFrame = frame
    return frame
end

function Dawn:PopulateDataFrame()
	self:PopulateDisplayFrame()
	self:PopulateKeyListFrame()
	self:PopulateDungeonFrame()
end

function Dawn:PopulatePlayerEditorFrame()
	local frame = Dawn.mainFrame
	if not frame.playerEditorScroll then
		return
	end

	local bnets = Player:GetBNetOfPartyMembers()
	if not bnets or next(bnets) == nil then
		return
	end

	local scroll = frame.playerEditorScroll
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

function Dawn:PopulateDisplayFrame()
    local frame = Dawn.mainFrame 
    if not frame or not frame.playersEditBox then
        return
    end

	local localDiscordTag = Config:GetDiscordTag()
    if not localDiscordTag or localDiscordTag == "" then
		frame.playersEditBox:SetText("Discord handle not set bro !")
	else

		local numberOfPlayers = 1
		local localBnet = Player:GetBNetTagForUnit("player")
		local fullOutputString = self:GeneratePlayerString(localBnet, false) .. "\n"
		if IsInGroup() then
			for _, bnet in ipairs(Player:GetBNetOfPartyMembers()) do
				if bnet ~= localBnet then
					local charactersName = Player:GetCharactersName(bnet)
					if #charactersName > 0 then
						fullOutputString = fullOutputString .. self:GeneratePlayerString(bnet, true) .. "\n"
						numberOfPlayers = numberOfPlayers + 1
					end
				end
			end
		end
		if numberOfPlayers > 1 then
			fullOutputString = "### " .. Data.DAWN_SIGN[numberOfPlayers] .. " sign:\n" .. fullOutputString
		end
		frame.playersEditBox:SetText(fullOutputString:sub(1, -3))
		frame.playersEditBox:HighlightText(0, 9999)
	end
end

function Dawn:PopulateKeyListFrame()
    local frame = Dawn.mainFrame
    if not frame or not frame.keysEditBox then
        return
    end

	local bnets = Player:GetBNetOfPartyMembers()
	if not bnets or next(bnets) == nil then
		return
	end

	local keyDataList = {}
	for _, bnet in ipairs(bnets) do
		local characters = Player:GetCharactersName(bnet)
		for _, charName in ipairs(characters) do
			local keystone = Character:GetCharacterKeystone(bnet, charName)
			if keystone and keystone.level and keystone.level > 0 then
				table.insert(keyDataList, {
					charName = charName,
					level = keystone.level or 0,
					mapName = keystone.mapName or "Unknown",
					hasKey = Character:GetCharacterHasKey(bnet, charName),
					isHidden = Character:GetCharacterIsHidden(bnet, charName)
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
		if keyInfo.hasKey and not keyInfo.isHidden then
			outputString = outputString .. string.format("%s: +%d %s\n",
				keyInfo.charName,
				keyInfo.level,
				keyInfo.mapName
			)
		end
    end

    frame.keysEditBox:SetText(outputString)
end

function Dawn:PopulateDungeonFrame()
	local frame = Dawn.mainFrame
	if not frame or not frame.keysEditBox then
		return
	end

	local iconSize = 75
	local dungeonsContainer = frame.dungeonsContainer
	dungeonsContainer:ReleaseChildren()

	for key, dungeon in pairs(Data.DUNGEON_TABLE) do
		local maxKeyLevel = 0
		local minKeyLevel = 99999

		local partyBnets = Player:GetBNetOfPartyMembers()
		for _, bnet in ipairs(partyBnets) do
			local charactersName = Player:GetCharactersName(bnet)
			for _, charName in ipairs(charactersName) do
				local keystone = Character:GetCharacterKeystone(bnet, charName)
				local hasKey = Character:GetCharacterHasKey(bnet, charName)
				local isHidden = Character:GetCharacterIsHidden(bnet, charName)
				if keystone and keystone.mapID == key and hasKey and not isHidden then
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
		local isHidden = Character:GetCharacterIsHidden(bnet, name)
		local keystone = Character:GetCharacterKeystone(bnet, name)
		if not isHidden and keystone and keystone.level and keystone.level > 0 then
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
		characters = characters,
	}

	local AceSerializer = LibStub("AceSerializer-3.0")
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

function Dawn:ToggleFrame()
    local frame = Dawn.mainFrame
    if not frame then
		frame = self:GetOrCreateMainFrame()
		if not frame then
			print(addonName, "Error: Could not get or create main display frame.")
			return
		end
		self:PopulateDataFrame()
        frame:Show()
    else
        frame:Release()
        Dawn.mainFrame = nil
    end
end
