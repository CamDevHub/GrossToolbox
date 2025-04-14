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
    playersEditBox:SetHeight(450) -- Adjust height
    dataTabContainer:AddChild(playersEditBox)
    frame.playersEditBox = playersEditBox -- Store reference

    local keysEditBox = AceGUI:Create("MultiLineEditBox")
    keysEditBox:SetLabel("Keystone List")
    keysEditBox:DisableButton(true)
    keysEditBox:SetWidth(250)
    keysEditBox:SetHeight(450)
    dataTabContainer:AddChild(keysEditBox)
    frame.keysEditBox = keysEditBox -- Store reference

    local requestButton = AceGUI:Create("Button")
    requestButton:SetText("Request Party Data")
    requestButton:SetWidth(200) -- Adjust width
    requestButton:SetCallback("OnClick", Dawn.RequestData)
    dataTabContainer:AddChild(requestButton)
    frame.requestButton = requestButton
end

function Dawn:DrawRoleEditorFrame(frame, container)
	 -- === Tab 2: Role Editor ===
	 local roleTabContainer = AceGUI:Create("ScrollFrame") -- Use ScrollFrame directly as the tab container
	 roleTabContainer:SetLayout("Flow") -- Items flow downwards inside the scroll frame
	 container:AddChild(roleTabContainer) -- Add container to the tab group for the "roles" tab value
	 frame.roleEditorScroll = roleTabContainer -- Store reference to the scroll frame itself
end

function Dawn:GetOrCreateMainFrame() -- Renamed from GetOrCreateDisplayFrames
    if Dawn.mainFrame then
        return Dawn.mainFrame
    end

    -- Create the main AceGUI Frame container
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("GrossToolbox") -- More general title
    frame:SetLayout("Fill")    -- TabGroup will fill the frame
    frame:SetWidth(1000)        -- Adjust width as needed
    frame:SetHeight(600)       -- Adjust height as needed
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); Dawn.mainFrame = nil end)

    -- Create the TabGroup
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill") -- Content of selected tab fills the group
    tabGroup:SetTabs({
        {text = "Data", value = "data"},
        {text = "Role Editor", value = "roles"}
    })
    frame:AddChild(tabGroup)
    frame.tabGroup = tabGroup -- Store reference

	tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
		widget:ReleaseChildren()
		if group == "data" then
			self:DrawDataFrame(frame, widget)
			self:PopulateDisplayFrame()
			self:PopulateKeyListFrame()
			frame.playersEditBox:SetFocus()
		elseif group == "roles" then
			self:DrawRoleEditorFrame(frame, widget)
			self:PopulateRoleEditorFrame()
		end
    end)

    tabGroup:SelectTab("data")

    Dawn.mainFrame = frame
    print(addonName, ": AceGUI Main Frame created.")
    return frame
end

function Dawn:PopulateRoleEditorFrame()
	local frame = Dawn.mainFrame
	if not db or not frame.roleEditorScroll then
		print(addonName, "Error: PopulateRoleEditorFrame - scroll widget or DB missing.")
		return
	end
	local scroll = frame.roleEditorScroll -- Use the stored reference to the scroll frame
	-- Use the passed-in scroll widget directly
	scroll:ReleaseChildren() -- Clear previous content
	scroll:SetScroll(0)      -- Reset scroll position

	local sortedBnets = {}
	for bnet, _ in pairs(db.global.player) do table.insert(sortedBnets, bnet) end
	table.sort(sortedBnets)

	local totalContentHeight = 0
	local verticalPadding = 3

	for _, bnet in ipairs(sortedBnets) do
		local player = db.global.player[bnet]

		local playerHeader = AceGUI:Create("Heading")
		playerHeader:SetText(player.discordTag or bnet)
		playerHeader:SetFullWidth(true)
		scroll:AddChild(playerHeader)
		totalContentHeight = totalContentHeight + (playerHeader.frame:GetHeight() or 18) + verticalPadding -- Use header.frame:GetHeight()

		if player.char then
			local sortedChars = {}
			for charName, _ in pairs(player.char) do table.insert(sortedChars, charName) end
			table.sort(sortedChars)

			for _, charFullName in ipairs(sortedChars) do
				local charData = player.char[charFullName]
				if charData then
					local charGroup = AceGUI:Create("SimpleGroup")
					charGroup:SetLayout("Flow")
					charGroup:SetFullWidth(true)

					local nameLabel = AceGUI:Create("Label")
					nameLabel:SetText(string.format("%s", charFullName))
					-- Add class coloring if desired (requires getting class info)
					-- local className, _, classId = UnitClass("player") -- Need correct unit for this char
					-- if classId and RAID_CLASS_COLORS[className] then nameLabel:SetColor(unpack(RAID_CLASS_COLORS[className])) end
					nameLabel:SetWidth(180)
					charGroup:AddChild(nameLabel)

					local roles = {"TANK", "HEALER", "DAMAGER"}
					local checkBoxes = {} -- Keep checkboxes scoped to the character group
					for i, role in ipairs(roles) do
						local checkbox = AceGUI:Create("CheckBox")
						checkbox:SetLabel(string.sub(role, 1, 1));
						checkbox:SetType("radio"); -- Changed to radio as per original code logic
						if charData.customRoles then
						   checkbox:SetValue(GT.Modules.Utils:TableContains(charData.customRoles, role))
						else
						   checkbox:SetValue(charData.role == role) -- Fallback to single role if no customRoles
						end
						checkbox:SetUserData("bnet", bnet);
						checkbox:SetUserData("charFullName", charFullName);
						checkbox:SetUserData("role", role);
						checkbox:SetUserData("checkBoxes", checkBoxes); -- Pass the local checkboxes table
						checkbox:SetWidth(35);
						checkbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
						   local cbBnet = widget:GetUserData("bnet")
						   local cbCharFullName = widget:GetUserData("charFullName")
						   local otherCheckBoxes = widget:GetUserData("checkBoxes") -- Get checkboxes for *this character*
						   local rolesToSet = {}
						   for roleValue, cb in pairs(otherCheckBoxes) do
							   -- Check the current state of the checkbox in the UI
							   if cb:GetValue() then
								   table.insert(rolesToSet, roleValue) -- Use roleValue (TANK, HEALER, DAMAGER)
							   end
						   end
						   -- Persist the changes to the database
						   GT.Modules.Character:SetCharacterCustomRoles(cbBnet, cbCharFullName, rolesToSet)
						   print(addonName, "Set roles for", cbCharFullName, "to", table.concat(rolesToSet, ", "))
					   end);
					   charGroup:AddChild(checkbox)
					   checkBoxes[role] = checkbox -- Store checkbox using role as key
					end

					-- Do layout for the inner group AFTER adding all children
					charGroup:DoLayout()
					scroll:AddChild(charGroup) -- Add the populated group to the scroll frame
					totalContentHeight = totalContentHeight + (charGroup.frame:GetHeight() or 20) + verticalPadding -- Use charGroup.frame:GetHeight()
				end
			end
		end
		totalContentHeight = totalContentHeight + 5 -- Extra padding between players
	end

	-- Manually Set Content Height for the ScrollFrame's content pane
	if scroll.content then
		scroll.content:SetHeight(totalContentHeight)
		-- print(addonName .. ": Manually set role scroll content height to:", totalContentHeight)
	else
		print(addonName .. ": ERROR - Could not find scroll.content to set height!")
	end

	-- Final Layout Calls (might not be strictly necessary after setting content height, but good practice)
	scroll:DoLayout()
	-- print(addonName .. ": Role Editor Population finished.")
end

function Dawn:PopulateDisplayFrame()
    local frame = Dawn.mainFrame -- Use the main frame property
    if not frame or not frame.playersEditBox then
        -- print(addonName, "Debug: PopulateDisplayFrame - Frame or playersEditBox missing.")
        return
    end
     -- ... (Keep the existing logic to generate fullOutputString) ...
     if not db.global.config.discordTag or db.global.config.discordTag == "" then
		frame.playersEditBox:SetText("Discord handle not set bro !")
	else
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
							break
						end
					end
				end
			end
			if includePlayer then
				fullOutputString = fullOutputString .. self:GeneratePlayerString(player, bnet, true) .. "\n"
			end
		end
		frame.playersEditBox:SetText(fullOutputString)
		frame.playersEditBox:HighlightText(0, 9999)
	end
end

function Dawn:PopulateKeyListFrame()
    local frame = Dawn.mainFrame -- Use the main frame property
    if not frame or not frame.keysEditBox then
        -- Frame might exist but widget doesn't, or frame doesn't exist
        -- print(addonName, "Debug: PopulateKeyListFrame - Frame or keysEditBox missing.")
        return
    end
    -- ... (Keep the existing logic to generate and format outputString) ...
    local keyDataList = {}
	for bnet, player in pairs(db.global.player) do
		if player.char then
			for charFullName, charData in pairs(player.char) do
				if charData and charData.keystone and charData.keystone.hasKey then
					table.insert(keyDataList, {
						charName = charFullName,
						classId = charData.classId,
						level = charData.keystone.level or 0,
						mapID = charData.keystone.mapID,
						mapName = charData.keystone.mapID and
							GT.Modules.Data.DUNGEON_ID_TO_ENGLISH_NAME[charData.keystone.mapID] or "Unknown Map"
					})
				end
			end
		end
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
				HEALER = ":healer: ",
				TANK = ":Tank: ",
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
			local tradeStr = ":gift: Can trade all"
			local playerOutput = string.format("%s %s %s / %s / %s / %s / %s",
				factionStr,
				roleIndicatorStr,
				classStr,
				scoreStr,
				keyStr,
				ilvlStr,
				tradeStr
			)
			fullOutputString = fullOutputString .. playerOutput .. "\n"
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
		if not UnitIsUnit("player", sender) then -- Don't respond to your own request if leader sends too
			print(addonName, ": Received data request from", sender, ". Sending data.")
			self:SendCharacterData()
		end
	elseif string.sub(message, 1, 10) == GT.headers.player then
		local success, data = AceSerializer:Deserialize(string.sub(message, 11)) -- Corrected deserialize

		if not success or type(data) ~= "table" or not data.bnet or not data.char then
			print(addonName, ": Invalid or malformed data from", sender)
			return
		end

		local bnet = data.bnet
		local incomingChars = data.char
		local senderDiscordTag = data.discordTag or "" -- Get discord tag from payload

		-- Ensure player entry exists or create it
		local localPlayerEntry = GT.Modules.Player:GetOrCreatePlayerData(bnet)
		localPlayerEntry.discordTag = senderDiscordTag -- Update discord tag from received data

		-- Merge character data (only if incoming data is a table)
        if type(incomingChars) == "table" then
            localPlayerEntry.char = localPlayerEntry.char or {} -- Ensure char table exists
            for charName, charData in pairs(incomingChars) do
                -- Basic validation/merge - might need deep merge if charData has nested tables
                 if type(charData) == "table" then
                      localPlayerEntry.char[charName] = charData -- Replace/add char data
                 end
            end
        end

		-- Optional: track who sent what (use sender name if available)
		localPlayerEntry.name = localPlayerEntry.name or sender

		print(addonName, ": Received and processed data from", sender)

        -- Repopulate the frame ONLY if it's currently visible
        local frame = Dawn.mainFrame
        if frame and frame:IsVisible() then
			print(addonName, "Repopulating visible frame...")
			self:PopulateDisplayFrame()
			self:PopulateKeyListFrame()
			self:PopulateRoleEditorFrame()
        end
	end
end

function Dawn:ToggleFrame()
    local frame = Dawn.mainFrame -- Use the main frame property
    if not frame then
		frame = self:GetOrCreateMainFrame()
		if not frame then
			print(addonName, "Error: Could not get or create main display frame.")
			return
		end
		self:PopulateDisplayFrame()
		self:PopulateKeyListFrame()
        frame:Show()
    else
        frame:Release() -- Release the frame and its children
        Dawn.mainFrame = nil -- Ensure it's recreated next time
    end
end
