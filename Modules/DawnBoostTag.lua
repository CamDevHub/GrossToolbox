local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- Local reference to the AceDB database object (set by Init)
local db


-- Initialize the module, receive the DB object from Core
function Dawn:Init(database)
	db = database -- Store the passed AceDB object reference
	if not db then
		print(addonName, "Error: Dawn received nil database!"); return
	end
	print(addonName, "- Dawn Module Initialized with DB.")
	-- Create the frame when the module initializes
	self:GetOrCreateDisplayFrames()
end

-- Update data using AceDB structure (db.global.char)
function Dawn:UpdateData()
	local bnet = GT.Modules.Player:GetBNetTag()
	local fullName = GT.Modules.Character:GetFullName()

	GT.Modules.Player:GetOrCreatePlayerData(bnet)
	local charTable = GT.Modules.Character:FetchCurrentCharacterStats()
	GT.Modules.Character:SetCharacterData(bnet, fullName, charTable)

	self:PopulateDisplayFrame()
end

function Dawn:CreatePlayersFrame()
	local playersFrame = CreateFrame("Frame", "GrossToolboxDawnFrame", UIParent, "BasicFrameTemplateWithInset")
	playersFrame:SetSize(750, 400)
	playersFrame:SetPoint("CENTER")
	playersFrame:SetMovable(true)
	playersFrame:EnableMouse(true)
	playersFrame:RegisterForDrag("LeftButton")
	playersFrame:SetScript("OnDragStart", playersFrame.StartMoving)
	playersFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Optional: Update position of keyListFrame relative to this frame if needed
        if Dawn.keyListFrame then
			Dawn.keyListFrame:ClearAllPoints()
			Dawn.keyListFrame:SetPoint("LEFT", self, "RIGHT", 10, 0)
        end
    end)
	playersFrame:SetClampedToScreen(true)
	playersFrame:SetFrameStrata("MEDIUM")
	playersFrame:Hide()

	playersFrame:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			Dawn:ToggleFrame()
			self:SetPropagateKeyboardInput(false)
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	playersFrame:SetScript("OnKeyUp", function(self, key)
		if key ~= "ESCAPE" then
			self:SetPropagateKeyboardInput(true)
		end
	end)

	local playersTitle = playersFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	playersTitle:SetPoint("TOP", 0, -5)
	playersTitle:SetText("GrossToolbox Dawn Tag Info")

	local playersScrollFrame = CreateFrame("ScrollFrame", nil, playersFrame, "UIPanelScrollFrameTemplate")
	playersScrollFrame:SetPoint("TOPLEFT", 10, -35)
	playersScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

	local playersEditBox = CreateFrame("EditBox", nil, playersScrollFrame)
	playersEditBox:SetMultiLine(true)
	playersEditBox:SetMaxLetters(999999)
	playersEditBox:EnableMouse(true)
	playersEditBox:SetAutoFocus(false)
	playersEditBox:SetFontObject(ChatFontNormal)
	playersEditBox:SetWidth(700)
	playersEditBox:SetHeight(1000)
	playersEditBox:SetScript("OnEscapePressed", function() Dawn:ToggleFrame() end)
	playersEditBox:SetScript("OnTextSet", function(self)
		self:HighlightText(0, 0)
		self:ClearFocus()
	end)
	playersEditBox:SetScript("OnEditFocusGained", function(self)
		self:ClearFocus()
	end)

	playersScrollFrame:SetScrollChild(playersEditBox)
	playersFrame.scrollFrame = playersScrollFrame
	playersFrame.editBox = playersEditBox


	local requestButton = CreateFrame("Button", "GTRequestButton", playersFrame, "UIPanelButtonTemplate")
	requestButton:SetText("Request Party Data")
	requestButton:SetHeight(22)
	requestButton:ClearAllPoints()
	requestButton:SetPoint("BOTTOMLEFT", playersFrame, "BOTTOMLEFT", 10, 10)
	requestButton:SetPoint("BOTTOMRIGHT", playersFrame, "BOTTOMRIGHT", -10, 10)
	requestButton:SetScript("OnClick", Dawn.RequestData)
	playersEditBox.requestButton = requestButton
	playersScrollFrame:SetPoint("BOTTOMLEFT", playersFrame, "BOTTOMLEFT", 10, 35)
	playersScrollFrame:SetPoint("BOTTOMRIGHT", playersFrame, "BOTTOMRIGHT", -30, 35)

	Dawn.playersFrame = playersFrame

	return playersFrame
end

function Dawn:CreateKeystonesFrame()
	if not Dawn.playersFrame then return end

	local keystonesFrame = CreateFrame("Frame", "GrossToolboxKeyListFrame", UIParent, "BasicFrameTemplateWithInset")
    keystonesFrame:SetSize(350, 400) -- Adjust size as needed
    keystonesFrame:SetPoint("LEFT", Dawn.playersFrame, "RIGHT", 10, 0) -- Anchor to the right of frame1
    keystonesFrame:SetMovable(true)
    keystonesFrame:EnableMouse(true)
    keystonesFrame:RegisterForDrag("LeftButton")
    keystonesFrame:SetScript("OnDragStart", keystonesFrame.StartMoving)
    keystonesFrame:SetScript("OnDragStop", keystonesFrame.StopMovingOrSizing)
    keystonesFrame:SetClampedToScreen(true)
    keystonesFrame:SetFrameStrata("MEDIUM")
    keystonesFrame:Hide()

    local keystonesTitle = keystonesFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    keystonesTitle:SetPoint("TOP", 0, -5)
    keystonesTitle:SetText("Keystone List")

    local keystonesScrollFrame = CreateFrame("ScrollFrame", "GTKeyScrollFrame", keystonesFrame, "UIPanelScrollFrameTemplate")
    keystonesScrollFrame:SetPoint("TOPLEFT", 10, -35)
    keystonesScrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local keystonesEditBox = CreateFrame("EditBox", "GTKeyEditBox", keystonesScrollFrame)
    keystonesEditBox:SetMultiLine(true)
    keystonesEditBox:SetMaxLetters(999999)
    keystonesEditBox:EnableMouse(true)
    keystonesEditBox:SetAutoFocus(false)
    keystonesEditBox:SetFontObject(ChatFontNormal)
    keystonesEditBox:SetWidth(300) -- Adjust width
    keystonesEditBox:SetHeight(1000)
    keystonesEditBox:SetScript("OnEscapePressed", function() Dawn:ToggleFrame() end) -- Close both frames
    keystonesEditBox:SetScript("OnTextSet", function(self) self:HighlightText(0,0) self:ClearFocus() end)
	keystonesEditBox:SetScript("OnEditFocusGained", function(self)
		self:ClearFocus()
	end)

    keystonesScrollFrame:SetScrollChild(keystonesEditBox)
    keystonesFrame.scrollFrame = keystonesScrollFrame
    keystonesFrame.editBox = keystonesEditBox
    Dawn.keyListFrame = keystonesFrame

	return keystonesFrame
end

function Dawn:GetOrCreateDisplayFrames()
	local playersFrame = Dawn.playersFrame
	local keystonesFrame = Dawn.keyListFrame

	if not playersFrame then
		playersFrame = Dawn:CreatePlayersFrame()
		if not keystonesFrame then
			keystonesFrame = Dawn:CreateKeystonesFrame()
		end
	end

    return playersFrame, keystonesFrame
end

function Dawn:PopulateKeyListFrame()
    local _, frame = self:GetOrCreateDisplayFrames()
    if not frame or not frame.editBox then
        if frame and frame.editBox then frame.editBox:SetText("Error: Database not fully initialized.") end
        return
    end

    local keyDataList = {}
    for guid, player in pairs(db.global.player) do
        if player.char then
            for charFullName, charData in pairs(player.char) do
                if charData and charData.keystone and charData.keystone.hasKey then
                    table.insert(keyDataList, {
                        charName = charFullName,
                        level = charData.keystone.level or 0,
                        mapID = charData.keystone.mapID,
                        mapName = charData.keystone.mapID and GT.Modules.Data.DUNGEON_ID_TO_ENGLISH_NAME[charData.keystone.mapID] or "Unknown Map"
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

    -- Format the output string
    local outputString = ""
    for _, keyInfo in ipairs(keyDataList) do
        outputString = outputString .. string.format("|cffeda55f%s|r: +%d %s\n",
            keyInfo.charName,
            keyInfo.level,
            keyInfo.mapName
        )
    end

    if outputString == "" then
        outputString = "No keystones found in database."
    end

    -- Set the text in the key list frame
    frame.editBox:SetText(outputString)
    frame.editBox:SetCursorPosition(0)
    frame.editBox:ClearFocus()
end

function Dawn:PopulateDisplayFrame()
	local frame = self:GetOrCreateDisplayFrames()
	if not frame or not frame.editBox then return end
	if not db.global.config.discordTag or db.global.config.discordTag == "" then
		frame.editBox:SetText("Discord handle not set bro !")
	else
		local fullOutputString = ""
		local players = GT.Modules.Player:GetAllPlayerData()
		local partyMembers = GT.Modules.Utils:fetchPartyMembersFullName()
		for bnet, player in pairs(players) do
			local includePlayer = false;
			if bnet ~= GT.Modules.Player:GetBNetTag() and IsInGroup() then
				if player.char then
					for charFullName, _ in pairs(player.char) do
						print(charFullName)
						if partyMembers[charFullName] then
							print(charFullName)
							includePlayer = true
							break
						end
					end
				end
			elseif bnet == GT.Modules.Player:GetBNetTag() then
				includePlayer = true
			end

			local chars = player.char or {}
			local sortedChars = {}
			for charName, _ in pairs(chars) do
				table.insert(sortedChars, charName)
			end
			table.sort(sortedChars)

			if includePlayer then
				if bnet ~= GT.Modules.Player:GetBNetTag() then
					fullOutputString = fullOutputString .. string.format("\n|cffffcc00== %s ==|r\n", player.discordTag)
				else
					fullOutputString = fullOutputString .. string.format("\n")
				end

				for _, charName in ipairs(sortedChars) do
					local data = chars[charName]
					if data and data.keystone and data.keystone.hasKey then
						local roleIndicatorStr = ({
							HEALER = ":healer:",
							TANK = ":Tank:",
							DAMAGER = ":Damager:"
						})[data.role] or ":UnknownRole:"

						local specClassStr = string.format("%s %s", data.specName or "No Spec",
							data.className or "No Class")
						local scoreStr = " :Raiderio: " .. (data.rating or 0)
						local keyStr = " :Keystone: "
						if data.keystone.hasKey then
							keyStr = keyStr ..
							string.format("+%d %s", data.keystone.level or 0, data.keystone.mapName or "Unknown")
						else
							keyStr = keyStr .. "No Key"
						end
						local ilvlStr = string.format(" :Armor: %d iLvl", data.iLvl or 0)

						local line = string.format("%s %s / %s / %s / %s / :gift: Can trade all", roleIndicatorStr,
							specClassStr, scoreStr, keyStr, ilvlStr)
						fullOutputString = fullOutputString .. line .. "\n"
					end
				end
			end
		end

		frame.editBox:SetText(fullOutputString)
	end
	frame.editBox:SetCursorPosition(0)
	frame.editBox:ClearFocus()
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

function Dawn:OnCommReceived(_, message, _, sender)
	if type(message) ~= "string" then return end

	if message == GT.headers.request then
		if not UnitIsUnit("player", sender) then -- Don't respond to your own request if leader sends too
			print(addonName, ": Received data request from", sender, ". Sending data.")
			self:SendCharacterData()
		end
	elseif string.sub(message, 1, 10) == GT.headers.player then
		local AceSerializer = LibStub("AceSerializer-3.0")
		local success, data = AceSerializer:Deserialize(message)

		if not success or type(data) ~= "table" or not data.bnet or not data.char then
			print(addonName, ": Invalid or malformed data from", sender)
			return
		end

		local bnet = data.bnet
		local incomingChars = data.char

		print("process character from " .. bnet)
		-- Ensure existing player entry exists
		local localPlayerEntry = GT.Modules.Player:GetOrCreatePlayerData(bnet)

		localPlayerEntry.discordTag = data.discordTag
		-- Merge character data
		for charName, charData in pairs(incomingChars) do
			localPlayerEntry.char[charName] = charData
		end

		-- Optional: track who sent what
		localPlayerEntry.name = data.name or localPlayerEntry.name or sender

		print(addonName, ": Received data from", localPlayerEntry.name)
		self:PopulateDisplayFrame()
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

-- Toggle frame visibility (no AceDB changes needed)
function Dawn:ToggleFrame(forceShow)
	local playersFrame, keystonesFrame = self:GetOrCreateDisplayFrames() -- Get both frames
    if not playersFrame or not keystonesFrame then
        print(addonName, "Error: Could not get display frames.")
        return
    end

    local shouldShow
    if forceShow ~= nil then
        shouldShow = forceShow
    else
        shouldShow = not playersFrame:IsShown() -- Toggle based on the first frame's visibility
    end

    if shouldShow then
        print(addonName, "Populating frames...")
        self:PopulateDisplayFrame()  -- Populate the main frame
        self:PopulateKeyListFrame()  -- Populate the new key frame
        playersFrame:Show()
        keystonesFrame:Show()
    else
        playersFrame:Hide()
        keystonesFrame:Hide()
    end
end
