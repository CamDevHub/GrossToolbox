local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

Dawn.data = {}
local db
function Dawn:Init(database)
	db = database
	if not db then
		print(addonName, "Error: Dawn received nil database!"); return
	end
	print(addonName, "- Dawn Module Initialized with DB.")
end

function Dawn:loadDawnDataTable()
	local partyBnets = GT.Modules.Utils:FetchPartyMembersBNet(GT.Modules.Player:GetAllPlayerData())
	if not partyBnets then
		return
	end
	if #partyBnets == 0 then
		partyBnets = { GT.Modules.Player:GetBNetTag() }
	end
	self.data = {
		keys={},
		players={}
	}
	for _, bnet in ipairs(partyBnets) do
		local player = GT.Modules.Player:GetOrCreatePlayerData(bnet)
		if not player or not player.char then
			return
		end
		if player.char then
			local charsWithKey = {}
			for charFullName, charData in pairs(player.char) do
				if charData and charData.keystone and charData.keystone.level and charData.keystone.level > 2 then
					table.insert(self.data.keys, {
						charName = charFullName,
						classId = charData.classId,
						className = charData.className,
						level = charData.keystone.level or 0,
						mapID = charData.keystone.mapID,
						mapName = charData.keystone.mapID and
							GT.Modules.Data.DUNGEON_TABLE[charData.keystone.mapID].name or "Unknown Map"
					})
					charsWithKey[charFullName] = charData
				end
			end
			if next(charsWithKey) ~= nil then
				self.data.players[bnet] = {char = charsWithKey, discordTag = player.discordTag}
			end
		end
	end
end

-- Update data using AceDB structure (db.global.char)
function Dawn:UpdateData()
	local bnet = GT.Modules.Player:GetBNetTag()
	local fullName = GT.Modules.Character:GetFullName()

	GT.Modules.Player:GetOrCreatePlayerData(bnet)

	local charTable = GT.Modules.Character:FetchCurrentCharacterStats()
	GT.Modules.Character:SetCharacterData(bnet, fullName, charTable)
	self:loadDawnDataTable()
end

function Dawn:DrawDataFrame(frame, container)
	-- === Tab 1: Data (Players) ===
    local dataTabContainer = AceGUI:Create("SimpleGroup") -- Use SimpleGroup for Flow layout
    dataTabContainer:SetLayout("Flow")
    dataTabContainer:SetAutoAdjustHeight(false) -- Important for scroll within tab if needed, but Flow might suffice
    container:AddChild(dataTabContainer) -- Add container to the tab group for the "data" tab value

    local playersEditBox = AceGUI:Create("MultiLineEditBox")
    playersEditBox:SetLabel("Player Data")
    playersEditBox:DisableButton(true)
    playersEditBox:SetWidth(650) -- Adjust width within tab
    playersEditBox:SetHeight(500) -- Adjust height
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
	if not db or not frame.playerEditorScroll then
		print(addonName, "Error: PopulatePlayerEditorFrame - scroll widget or DB missing.")
		return
	end
	local scroll = frame.playerEditorScroll

	scroll:ReleaseChildren()
	scroll:SetScroll(0)

	for bnet, player in pairs(self.data.players) do
		local playerHeader = AceGUI:Create("Heading")
		playerHeader:SetText(player.discordTag or bnet)
		playerHeader:SetFullWidth(true)
		scroll:AddChild(playerHeader)
		if player.char then
			local sortedChars = {}
			for charName, _ in pairs(player.char) do table.insert(sortedChars, charName) end
			table.sort(sortedChars)

			for _, charFullName in ipairs(sortedChars) do
				local charData = player.char[charFullName]
				if charData and charData.rating > 0 then
					local charGroup = AceGUI:Create("SimpleGroup")
					charGroup:SetLayout("Flow")
					charGroup:SetFullWidth(true)

					local nameLabel = AceGUI:Create("Label")
					nameLabel:SetText(string.format("%s", charFullName))
					nameLabel:SetWidth(180)
					charGroup:AddChild(nameLabel)

					local ratingLabel = AceGUI:Create("Label")
					ratingLabel:SetText(string.format("Rating: %d", charData.rating or 0))
					ratingLabel:SetWidth(180)
					charGroup:AddChild(ratingLabel)

					local classLabel = AceGUI:Create("Label")
					classLabel:SetText(string.format("%s", GT.Modules.Data.CLASS_ID_TO_ENGLISH_NAME[charData.classId] or "Unknown Class"))
					classLabel:SetWidth(180)
					charGroup:AddChild(classLabel)
					
					local noKeyForBoostCheckbox = AceGUI:Create("CheckBox")
					noKeyForBoostCheckbox:SetLabel("No Key");
					noKeyForBoostCheckbox:SetType("radio");
					noKeyForBoostCheckbox:SetUserData("bnet", bnet);
					noKeyForBoostCheckbox:SetUserData("charFullName", charFullName);
					noKeyForBoostCheckbox:SetValue(GT.Modules.Character:GetCharacternoKeyForBoostStatus(bnet, charFullName))
					noKeyForBoostCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
						local cbBnet = widget:GetUserData("bnet")
						local cbCharFullName = widget:GetUserData("charFullName")
						GT.Modules.Character:SetCharacternoKeyForBoostStatus(cbBnet, cbCharFullName, isChecked)
					end)
					charGroup:AddChild(noKeyForBoostCheckbox)

					local checkBoxes = {}
					for role, _ in pairs(GT.Modules.Data.ROLES) do
						local checkbox = AceGUI:Create("CheckBox")
						checkbox:SetLabel(role);
						checkbox:SetType("radio");
						if charData.customRoles then
						   checkbox:SetValue(GT.Modules.Utils:TableContains(charData.customRoles, role))
						else
						   checkbox:SetValue(charData.role == role)
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
							GT.Modules.Character:SetCharacterCustomRoles(cbBnet, cbCharFullName, rolesToSet)
					   end);
					   charGroup:AddChild(checkbox)
					   checkBoxes[role] = checkbox 
					end


					charGroup:DoLayout()
					scroll:AddChild(charGroup)
				end
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
     if not db.global.config.discordTag or db.global.config.discordTag == "" then
		frame.playersEditBox:SetText("Discord handle not set bro !")
	else

		local maxClassNameLength = 0
		for _, keystoneData in ipairs(self.data.keys) do
			if keystoneData.className and #keystoneData.className > maxClassNameLength then
				maxClassNameLength = #keystoneData.className
			end
		end

		local numberOfPlayers = 1
		local partyMembers = GT.Modules.Utils:FetchPartyMembersFullName()
		local fullOutputString = self:GeneratePlayerString(self.data.players[GT.Modules.Player:GetBNetTag()], GT.Modules.Player:GetBNetTag(), false) .. "\n"
		if IsInGroup() then
			for bnet, player in pairs(self.data.players) do
				if bnet ~= GT.Modules.Player:GetBNetTag() then
					fullOutputString = fullOutputString .. self:GeneratePlayerString(player, bnet, true) .. "\n"
					numberOfPlayers = numberOfPlayers + 1
				end
			end
		end
		if numberOfPlayers > 1 then
			fullOutputString = "### " .. GT.Modules.Data.DAWN_SIGN[numberOfPlayers] .. " sign:\n" .. fullOutputString
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
    local keyDataList = self.data.keys
	table.sort(keyDataList, function(a, b)
		local mapNameA = a.mapName or ""
		local mapNameB = b.mapName or ""

		if mapNameA ~= mapNameB then
			return mapNameA < mapNameB
		else
			return a.level > b.level
		end
	end)

    local outputString = ""
    for _, keyInfo in ipairs(keyDataList) do
        outputString = outputString .. string.format("%s: +%d %s\n",
            keyInfo.charName,
            keyInfo.level,
            keyInfo.mapName
        )
    end
	if outputString == "" then	outputString = "No keystones found in database." end

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
	for key, dungeon in pairs(GT.Modules.Data.DUNGEON_TABLE) do
		local maxKeyLevel = 0
		local minKeyLevel = 0
		for _, keyData in pairs(self.data.keys) do
			if keyData.mapID == key then
				maxKeyLevel = math.max(maxKeyLevel, keyData.level or 0)
				if minKeyLevel == 0 then
					minKeyLevel = keyData.level or 0
				else 
					minKeyLevel = math.min(minKeyLevel, keyData.level or 0)
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


function Dawn:GeneratePlayerString(player, bnet, addDiscordTag)
	local fullOutputString = ""
	if addDiscordTag and player.discordTag and player.discordTag ~= "" then
		fullOutputString = fullOutputString .. string.format("|cffffcc00%s|r\n", player.discordTag)
	end

	local chars = player.char or {}
	table.sort(chars, function(a, b)
		local aRoles = a.customRoles or {a.role}
		local bRoles = b.customRoles or {b.role}
        if #aRoles ~= #bRoles then
            return #aRoles > #bRoles
        end
        return a.name < b.name
    end)

	for charName, data in pairs(chars) do
		if data and data.keystone then
			local roleIndicatorStr = ""
			if data.customRoles and #data.customRoles > 0 then
				for _, role in ipairs(data.customRoles) do
					roleIndicatorStr = roleIndicatorStr .. (GT.Modules.Data.ROLES[role] or ":Unknown:")
				end
			else
				roleIndicatorStr = "" .. (GT.Modules.Data.ROLES[data.role] or ":Unknown:")
			end
			local factionStr = ""
			if data.faction and data.faction ~= "Neutral" then
				factionStr = ":" .. string.lower(data.faction) .. ":"
			end
			
			local classStr = data.className or "No Class"
			local scoreStr = ":Raiderio: " .. (data.rating or 0)
			local keyStr = ":Keystone: "
			if data.keystone then
				if data.keystone.noKeyForBoost then
					keyStr = keyStr ..
						string.format("No key")
				else
					keyStr = keyStr ..
						string.format("+%d %s", data.keystone.level or 0, data.keystone.mapName or "Unknown")
				end
			else
				keyStr = keyStr .. "No Key"
			end
			local ilvlStr = string.format(":Armor: %d iLvl", data.iLvl or 0)
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
			fullOutputString = fullOutputString .. "** " .. charOutput .. " **\n"
		end
	end

	return fullOutputString
end

function Dawn:SendCharacterData()
	local bnet = GT.Modules.Player:GetBNetTag()
	local playerChars = GT.Modules.Character:GetAllCharactersForPlayer(bnet)
	if not playerChars or not db.global.config.discordTag then return end

	local payload = {
		bnet = bnet,
		discordTag = db.global.config.discordTag,
		char = playerChars,
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

		if not success or type(data) ~= "table" or not data.bnet or not data.char then
			print(addonName, ": Invalid or malformed data from", sender)
			return
		end

		local bnet = data.bnet
		local incomingChars = data.char
		local senderDiscordTag = data.discordTag or "" 


		local localPlayerEntry = GT.Modules.Player:GetOrCreatePlayerData(bnet)
		localPlayerEntry.discordTag = senderDiscordTag

        if type(incomingChars) == "table" then
            localPlayerEntry.char = localPlayerEntry.char or {} 
            for charName, charData in pairs(incomingChars) do
                 if type(charData) == "table" then
					localPlayerEntry.char[charName] = localPlayerEntry.char[charName] or {}
					charData.customRoles = localPlayerEntry.char[charName].customRoles or {}
                    localPlayerEntry.char[charName] = charData
                 end
            end
        end

		localPlayerEntry.name = localPlayerEntry.name or sender

		print(addonName, ": Received and processed data from", sender)

		self:loadDawnDataTable()
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
