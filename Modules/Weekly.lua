local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Weekly = {}
GT.Modules.Weekly = Weekly

local AceGUI = LibStub("AceGUI-3.0")
local AceHook = LibStub("AceHook-3.0")

-- Define module name for initialization logging
Weekly.moduleName = "Weekly"

-- Define module dependencies
local db
local Data, Utils, GrossFrame, Character, Player

function Weekly:Init(database)
  -- Validate database parameter
  if not database then
    print(addonName .. ": Weekly module initialization failed - missing database")
    return false
  end
  
  -- Store database reference
  db = database
  
  -- Load required modules
  Data = GT.Modules.Data
  if not Data then
    print(addonName .. ": Weekly module initialization failed - Data module not found")
    return false
  end
  
  Utils = GT.Modules.Utils
  if not Utils then
    print(addonName .. ": Weekly module initialization failed - Utils module not found")
    return false
  end
  
  Character = GT.Modules.Character
  if not Character then
    print(addonName .. ": Weekly module initialization failed - Character module not found")
    return false
  end
  
  Player = GT.Modules.Player
  if not Player then
    print(addonName .. ": Weekly module initialization failed - Player module not found")
    return false
  end
  
  GrossFrame = GT.Modules.GrossFrame
  if not GrossFrame then
    print(addonName .. ": Weekly module initialization failed - GrossFrame module not found")
    return false
  end
  
  -- Register UI tab
  local signupTab = {
    text = "Weekly",
    value = "weeklyTab",
    drawFunc = function(container) self:DrawFrame(container) end,
    populateFunc = function(container) self:PopulateFrame(container) end,
    module = Weekly
  }
  
  GrossFrame:RegisterTab(signupTab)
  
  -- Log successful initialization
  Utils:DebugPrint("Weekly module initialized successfully")
  return true
end

function Weekly:DrawFrame(container)
  if not container then return end

	if not container.weekly then
		container.weekly = {}
	end

  local weeklyTabContainer = AceGUI:Create("ScrollFrame")
	weeklyTabContainer:SetLayout("Flow")
	container:AddChild(weeklyTabContainer)

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

  weeklyTabContainer:AddChild(headerRow)
  container.weekly.weeklyScroll = weeklyTabContainer
end

function Weekly:PopulateFrame(container)
  if not container or not container.weekly or not container.weekly.weeklyScroll then
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

    container.weekly.weeklyScroll:AddChild(characterFrame)
  end
  
  -- Final layout update
  container.weekly.weeklyScroll:DoLayout()
end