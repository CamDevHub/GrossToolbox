local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Dungeon = {}
GT.Modules.Dungeon = Dungeon

local AceGUI = LibStub("AceGUI-3.0")

local db
local Data, Utils, GrossFrame, Character, Player
function Dungeon:Init(database)
  db = database
  if not db then return end

  Data = GT.Modules.Data
  if not Data then return end

  Utils = GT.Modules.Utils
  if not Utils then return end

  Character = GT.Modules.Character
	if not Character then return end

	Player = GT.Modules.Player
	if not Player then return end

  GrossFrame = GT.Modules.GrossFrame
  if not GrossFrame then return end

  local signupTab = {
    text = "M+ Display",
    value = "DungeonTab",
    drawFunc = function(container) self:DrawFrame(container) end,
    populateFunc = function(container) self:PopulateFrame(container) end,
    module = Dungeon
	}

  GrossFrame:RegisterTab(signupTab)
end

function Dungeon:DrawFrame(container)
  if not container then return end

	if not container.dungeon then
		container.dungeon = {}
	end

  local DungeonTabContainer = AceGUI:Create("ScrollFrame")
	DungeonTabContainer:SetLayout("Flow")
	container:AddChild(DungeonTabContainer)

  -- Create a header row for the table
  local headerRow = AceGUI:Create("SimpleGroup")
  headerRow:SetLayout("Flow")
  headerRow:SetFullWidth(true)
  headerRow:SetHeight(40)
  headerRow:SetAutoAdjustHeight(false)

  local nameHeader = AceGUI:Create("Label")
  nameHeader:SetText("Character")
  nameHeader:SetWidth(300)
  nameHeader:SetFontObject(GameFontNormalHuge)
  headerRow:AddChild(nameHeader)

  local keysHeader = AceGUI:Create("Label")
  keysHeader:SetText("Keys")
  keysHeader:SetWidth(600)
  keysHeader:SetFontObject(GameFontNormalHuge)
  keysHeader:SetJustifyH("CENTER")
  headerRow:AddChild(keysHeader)

  local missingHeader = AceGUI:Create("Label")
  missingHeader:SetText("Missing")
  missingHeader:SetWidth(100)
  missingHeader:SetFontObject(GameFontNormalHuge)
  missingHeader:SetJustifyH("CENTER")
  headerRow:AddChild(missingHeader)

  DungeonTabContainer:AddChild(headerRow)
  container.dungeon.dungeonScroll = DungeonTabContainer
end

function Dungeon:PopulateFrame(container)
  if not container or not container.dungeon or not container.dungeon.dungeonScroll then
    return
  end

  local bnet = Player:GetBNetTagForUnit("player")
  if not bnet then return end

  local charactersName = Player:GetCharactersName(bnet)
  if not charactersName then return end

  for _, fullName in pairs(charactersName) do
    local characterFrame = AceGUI:Create("SimpleGroup")
    characterFrame:SetLayout("Flow")
    characterFrame:SetFullWidth(true)
    characterFrame:SetHeight(40)
    characterFrame:SetAutoAdjustHeight(false)

    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(fullName)
    nameLabel:SetWidth(300)
    nameLabel:SetFontObject(GameFontNormal)
    characterFrame:AddChild(nameLabel)

    local weeklies = Character:GetWeeklyData(bnet, fullName)
    local nbMissingWeekly = 0

    for i = 1, 8 do
      weeklies[i] = weeklies[i] or { level = 0 }
      if weeklies[i].level < 10 then
        nbMissingWeekly = nbMissingWeekly + 1
      end
    end

    for i = 1, 8 do
      local levelLabel = AceGUI:Create("Label")
      levelLabel:SetWidth(75)
      levelLabel:SetFontObject(GameFontNormal)
      levelLabel:SetText(weeklies[i].level)
      if weeklies[i].level >= 10 then
        levelLabel:SetColor(0, 1, 0)
      else
        levelLabel:SetColor(1, 0, 0)
      end
      characterFrame:AddChild(levelLabel)
    end

    local missingLabel = AceGUI:Create("Label")
    missingLabel:SetWidth(100)
    missingLabel:SetFontObject(GameFontNormal)
    missingLabel:SetText(tostring(nbMissingWeekly))
    missingLabel:SetJustifyH("CENTER")
    characterFrame:AddChild(missingLabel)

    container.dungeon.dungeonScroll:AddChild(characterFrame)
  end
  container.dungeon.dungeonScroll:DoLayout()
end