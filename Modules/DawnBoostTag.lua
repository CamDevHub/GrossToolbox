
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
    if not db then print(addonName, "Error: Dawn received nil database!"); return end
    print(addonName, "- Dawn Module Initialized with DB.")
    -- Create the frame when the module initializes
    self:GetOrCreateDisplayFrame()
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


-- Frame creation logic (no AceDB changes needed inside here)
function Dawn:GetOrCreateDisplayFrame()
	-- ... (Frame creation code remains the same as before) ...
	if Dawn.displayFrame then
		return Dawn.displayFrame
	end
	
	local frame = CreateFrame("Frame", "GrossToolboxDawnFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(850, 400)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("MEDIUM")
	frame:Hide()

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -5)
	title:SetText("GrossToolbox Dawn Tag Info")

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 10, -35)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(999999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(800)
	editBox:SetHeight(1000)
	editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
	editBox:SetScript("OnTextSet", function(self) self:HighlightText(0,0) self:ClearFocus() end)

	scrollFrame:SetScrollChild(editBox)
	frame.scrollFrame = scrollFrame
	frame.editBox = editBox
	Dawn.displayFrame = frame

	print(addonName, ": Dawn display frame created.")
	return frame
end

-- Populate frame using AceDB structure (db.global.char)
function Dawn:PopulateDisplayFrame()
    local frame = self:GetOrCreateDisplayFrame()
    if not frame or not frame.editBox or not db or not db.global or not db.global.player or not db.global.config.discordTag or db.global.config.discordTag == "" then
		frame.editBox:SetText("Discord handle not set bro !")
	else
		local fullOutputString = ""
		local players = GT.Modules.Player:GetAllPlayerData()
		for bnet, player in pairs(players) do
			if bnet ~= GT.Modules.Player:GetBNetTag() then
				fullOutputString = fullOutputString .. string.format("\n|cffffcc00== %s ==|r\n", player.discordTag)
			else 
				fullOutputString = fullOutputString .. string.format("\n\n")
			end

			local chars = player.char or {}
			local sortedChars = {}
			for charName, _ in pairs(chars) do table.insert(sortedChars, charName) end
			table.sort(sortedChars)

			for _, charName in ipairs(sortedChars) do
				local data = chars[charName]
				if data and data.keystone and data.keystone.hasKey then
					local roleIndicatorStr = ({
						HEALER = ":healer:",
						TANK = ":Tank:",
						DAMAGER = ":Damager:"
					})[data.role] or ":UnknownRole:"

					local specClassStr = string.format("%s %s", data.specName or "No Spec", data.className or "No Class")
					local scoreStr = " :Raiderio: " .. (data.rating or 0)
					local keyStr = " :Keystone: "
					if data.keystone.hasKey then
						keyStr = keyStr .. string.format("+%d %s", data.keystone.level or 0, data.keystone.mapName or "Unknown")
					else
						keyStr = keyStr .. "No Key"
					end
					local ilvlStr = string.format(" :Armor: %d iLvl", data.iLvl or 0)

					local line = string.format("%s %s / %s / %s / %s / Can trade all :gift:", roleIndicatorStr, specClassStr, scoreStr, keyStr, ilvlStr)
					fullOutputString = fullOutputString .. line .. "\n"
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

-- Toggle frame visibility (no AceDB changes needed)
function Dawn:ToggleFrame(forceShow)
	-- ... (Toggle frame logic remains the same as before) ...
	local frame = self:GetOrCreateDisplayFrame()
	if not frame then
		return
	end
	
	if forceShow then
		if not frame:IsShown() then
			self:PopulateDisplayFrame()
			frame:Show()
		end
	elseif frame:IsShown() then
		frame:Hide()
	else
		self:PopulateDisplayFrame()
		frame:Show()
	end
end
