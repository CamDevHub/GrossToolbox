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
local addon, Data, Utils, GrossFrame, Character, Player

function Weekly:Init(database)
  -- Validate database parameter
  if not database then
    print(addonName .. ": Weekly module initialization failed - missing database")
    return false
  end

  -- Store database reference
  db = database

  addon = GT.addon
  if not addon then
    print(addonName .. ": Weekly module initialization failed - addon not found")
    return false
  end

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

function Weekly:GetSparkData()
  local sparks = C_CurrencyInfo.GetCurrencyInfo(3132)
  if not sparks then return end
  return sparks
end

function Weekly:DrawFrame(container)
  if not container then return end

  if not container.weekly then
    container.weekly = {}
  end

  local weeklyTabContainer = AceGUI:Create("ScrollFrame")
  weeklyTabContainer:SetLayout("Flow")
  container:AddChild(weeklyTabContainer)

  local dungeonHeader = AceGUI:Create("Heading")
  dungeonHeader:SetText("Currencies")
  dungeonHeader:SetFullWidth(true)
  weeklyTabContainer:AddChild(dungeonHeader)

  local currenciesContainer = AceGUI:Create("SimpleGroup")
  currenciesContainer:SetLayout("Flow")
  currenciesContainer:SetFullWidth(true)
  currenciesContainer:SetHeight(40)
  currenciesContainer:SetAutoAdjustHeight(false)

  -- Create a header row for the table
  local dungeonsHeader = AceGUI:Create("SimpleGroup")
  dungeonsHeader:SetLayout("Flow")
  dungeonsHeader:SetFullWidth(true)
  dungeonsHeader:SetHeight(60)
  dungeonsHeader:SetAutoAdjustHeight(false)

  local currenciesHeader = AceGUI:Create("Heading")
  currenciesHeader:SetText("Dungeons")
  currenciesHeader:SetFullWidth(true)
  dungeonsHeader:AddChild(currenciesHeader)

  local nameHeader = AceGUI:Create("Label")
  nameHeader:SetText("Characters")
  nameHeader:SetWidth(300)
  nameHeader:SetFontObject(GameFontNormalHuge)
  dungeonsHeader:AddChild(nameHeader)

  local keysHeader = AceGUI:Create("Label")
  keysHeader:SetText("Keys")
  keysHeader:SetWidth(600)
  keysHeader:SetFontObject(GameFontNormalHuge)
  keysHeader:SetJustifyH("CENTER")
  dungeonsHeader:AddChild(keysHeader)

  local missingHeader = AceGUI:Create("Label")
  missingHeader:SetText("Missing")
  missingHeader:SetWidth(100)
  missingHeader:SetFontObject(GameFontNormalHuge)
  missingHeader:SetJustifyH("CENTER")
  dungeonsHeader:AddChild(missingHeader)

  weeklyTabContainer:AddChild(currenciesContainer)
  weeklyTabContainer:AddChild(dungeonsHeader)
  container.weekly.weeklyScroll = weeklyTabContainer
  container.weekly.currenciesContainer = currenciesContainer
end

function Weekly:PopulateFrame(container)
  if not container or not container.weekly or not container.weekly.weeklyScroll or not container.weekly.currenciesContainer then
    return
  end

  local sparks = self:GetSparkData()
  if not sparks then return end

  local uid = addon:GetUID()
  if not uid then return end

  local charactersName = Player:GetCharactersName(uid)
  if not charactersName then return end

  local sparksLabel = AceGUI:Create("Label")
  sparksLabel:SetText("Sparks: " .. sparks.quantity .. " / " .. sparks.maxQuantity)
  sparksLabel:SetFontObject(GameFontNormal)
  container.weekly.currenciesContainer:AddChild(sparksLabel)

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

    local weeklies = Character:GetWeeklyData(uid, fullName)
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
