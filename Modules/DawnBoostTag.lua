local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local db
function Dawn:Init(database)
	db = database -- Store the database reference passed from the core addon file
	if not db then
		print(addonName, "Error: Dawn received nil database!"); return
	end
	-- No longer need to call GetOrCreateDisplayFrames here,
	-- as the frame is created on demand by ToggleFrame/GetOrCreateMainFrame.
	print(addonName, "- Dawn Module Initialized with DB.")
end

Dawn.keys = {}
function Dawn:loadKeyList()
	local partyBnets = GT.Modules.Utils:FetchPartyMembersBNet(GT.Modules.Player:GetAllPlayerData())
	if not partyBnets or #partyBnets == 0 then
		return
	end
	self.keys = {}
	for _, bnet in ipairs(partyBnets) do
		local player = GT.Modules.Player:GetOrCreatePlayerData(bnet)
		if not player or not player.char then
			return
		end
		if player.char then
			for charFullName, charData in pairs(player.char) do
				if charData and charData.keystone and charData.keystone.hasKey then
					table.insert(self.keys, {
						charName = charFullName,
						classId = charData.classId,
						level = charData.keystone.level or 0,
						mapID = charData.keystone.mapID,
						mapName = charData.keystone.mapID and
							GT.Modules.Data.DUNGEON_TABLE[charData.keystone.mapID].name or "Unknown Map"
					})
				end
			end
		end
	end
end

-- Update data using AceDB structure (db.global.char)
function Dawn:UpdateData()
	-- Fetch character stats and update the database (using Player and Character modules)
	local bnet = GT.Modules.Player:GetBNetTag()
	local fullName = GT.Modules.Character:GetFullName()

	-- Ensure player data exists before trying to set character data
	GT.Modules.Player:GetOrCreatePlayerData(bnet) -- Creates player entry if needed

	-- Fetch current stats and store them
	local charTable = GT.Modules.Character:FetchCurrentCharacterStats()
	GT.Modules.Character:SetCharacterData(bnet, fullName, charTable)
	self:loadKeyList()
	print(addonName, ": Updated data for", fullName)
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

function Dawn:DrawRoleEditorFrame(frame, container)
	 -- === Tab 2: Role Editor ===
	 local roleTabContainer = AceGUI:Create("ScrollFrame")
	 roleTabContainer:SetLayout("Flow")
	 container:AddChild(roleTabContainer)
	 frame.roleEditorScroll = roleTabContainer
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
        {text = "Role Editor", value = "roles"}
    })
    frame:AddChild(tabGroup)
    frame.tabGroup = tabGroup

	tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
		widget:ReleaseChildren()
		if group == "data" then
			self:DrawDataFrame(frame, widget)
			self:PopulateDataFrame()
			frame.playersEditBox:SetFocus()
		elseif group == "roles" then
			self:DrawRoleEditorFrame(frame, widget)
			self:PopulateRoleEditorFrame()
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

function Dawn:PopulateRoleEditorFrame()
	local frame = Dawn.mainFrame
	if not db or not frame.roleEditorScroll then
		print(addonName, "Error: PopulateRoleEditorFrame - scroll widget or DB missing.")
		return
	end
	local scroll = frame.roleEditorScroll

	scroll:ReleaseChildren()
	scroll:SetScroll(0)

	local sortedBnets = {}
	for bnet, _ in pairs(db.global.player) do table.insert(sortedBnets, bnet) end
	table.sort(sortedBnets)

	for _, bnet in ipairs(sortedBnets) do
		local player = db.global.player[bnet]

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

					local roles = {"TANK", "HEALER", "DAMAGER"}
					local checkBoxes = {}
					for i, role in ipairs(roles) do
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
		local numberOfPlayers = 1
		local fullOutputString = ""
		local players = GT.Modules.Player:GetAllPlayerData()
		local partyMembers = GT.Modules.Utils:FetchPartyMembersFullName()
		fullOutputString = fullOutputString ..
			self:GeneratePlayerString(players[GT.Modules.Player:GetBNetTag()], GT.Modules.Player:GetBNetTag(), false) .. "\n"
		for bnet, player in pairs(players) do
			local includePlayer = false;
			if bnet ~= GT.Modules.Player:GetBNetTag() and IsInGroup() then
				if player.char then
					for charFullName, _ in pairs(player.char) do
						if partyMembers[charFullName] then
							includePlayer = true
							numberOfPlayers = numberOfPlayers + 1
							break
						end
					end
				end
			end
			if includePlayer then
				fullOutputString = fullOutputString .. self:GeneratePlayerString(player, bnet, true) .. "\n"
			end
		end
		if numberOfPlayers > 1 then
			fullOutputString = "###" .. GT.Modules.Data.DAWN_SIGN[numberOfPlayers] .. " sign:\n" .. fullOutputString
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
    local keyDataList = Dawn.keys
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
		for _, keyData in pairs(Dawn.keys) do
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
	local sortedChars = {}
	for charName, _ in pairs(chars) do
		table.insert(sortedChars, charName)
	end
	table.sort(sortedChars)

	for _, charName in ipairs(sortedChars) do
		local data = chars[charName]
		if data and data.keystone and data.keystone.hasKey then
			local roleIndicator = {
				TANK = ":Tank: ",
				HEALER = ":healer: ",
				DAMAGER = ":DPS: "
			}
			local roleIndicatorStr = ""
			if data.customRoles then
				for _, role in ipairs(data.customRoles) do
					roleIndicatorStr = roleIndicatorStr .. (roleIndicator[role] or ":Unknown:")
				end
			else
				roleIndicatorStr = roleIndicator[data.role] or ":Unknown:"
			end

			local factionStr = ""
			if data.faction and data.faction ~= "Neutral" then
				factionStr = ":" .. string.lower(data.faction) .. ":"
			end
			local classStr = string.format("%s", data.className or "No Class")
			local scoreStr = ":Raiderio: " .. (data.rating or 0)
			local keyStr = ":Keystone: "
			if data.keystone.hasKey then
				keyStr = keyStr ..
					string.format("+%d %s", data.keystone.level or 0, data.keystone.mapName or "Unknown")
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
			fullOutputString = fullOutputString .. "**" .. charOutput .. "**\n"
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
                      localPlayerEntry.char[charName] = charData 
                 end
            end
        end

		localPlayerEntry.name = localPlayerEntry.name or sender

		print(addonName, ": Received and processed data from", sender)

		self:loadKeyList()
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
