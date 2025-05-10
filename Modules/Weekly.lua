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
  return sparks.maxQuantity
end

function Weekly:DrawFrame(container)
  if not container then return end

  if not container.weekly then
    container.weekly = {}
  end

  local weeklyTabContainer = AceGUI:Create("ScrollFrame")
  weeklyTabContainer:SetFullWidth(true)
  weeklyTabContainer:SetLayout("Flow")
  container:AddChild(weeklyTabContainer)

  -- Create a header row for the table
  local weeklyTable = AceGUI:Create("SimpleGroup")
  weeklyTable:SetLayout("Flow")
  weeklyTable:SetFullWidth(true)
  weeklyTable:SetHeight(60)
  weeklyTable:SetAutoAdjustHeight(false)

  local nameHeader = AceGUI:Create("Label")
  nameHeader:SetText("Characters")
  nameHeader:SetWidth(200)
  nameHeader:SetFontObject(GameFontNormalHuge)
  weeklyTable:AddChild(nameHeader)

  local keysHeader = AceGUI:Create("Label")
  keysHeader:SetText("Keys")
  keysHeader:SetWidth(100)
  keysHeader:SetFontObject(GameFontNormalHuge)
  keysHeader:SetJustifyH("CENTER")
  weeklyTable:AddChild(keysHeader)

  local sparksHeader = AceGUI:Create("Label")
  sparksHeader:SetText("Sparks")
  sparksHeader:SetWidth(100)
  sparksHeader:SetFontObject(GameFontNormalHuge)
  sparksHeader:SetJustifyH("CENTER")
  weeklyTable:AddChild(sparksHeader)

  weeklyTabContainer:AddChild(weeklyTable)
  container.weekly.weeklyScroll = weeklyTabContainer
end

function Weekly:PopulateFrame(container)
  if not container or not container.weekly or not container.weekly.weeklyScroll then
    return
  end

  local uid = addon:GetUID()
  if not uid then return end

  local charactersName = Player:GetCharactersName(uid)
  if not charactersName then return end

  for _, fullName in pairs(charactersName) do
    local characterFrame = AceGUI:Create("SimpleGroup")
    characterFrame:SetLayout("Flow")
    characterFrame:SetFullWidth(true)
    characterFrame:SetHeight(40)
    characterFrame:SetAutoAdjustHeight(false)

    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(fullName)
    nameLabel:SetWidth(200)
    nameLabel:SetFontObject(GameFontNormal)
    characterFrame:AddChild(nameLabel)

    local weeklies = Character:GetWeeklyData(uid, fullName)
    local nbSparks = Character:GetSparksData(uid, fullName)
    -- Calculate weekly summary
    local weeklyDone = 0
    local hasBelow8 = false
    local allAtLeast10 = true
    for i = 1, 8 do
      local level = weeklies[i].level or 0
      if level >= 10 then
        weeklyDone = weeklyDone + 1
      end
      if level < 8 then
        hasBelow8 = true
      end
      if level < 10 then
        allAtLeast10 = false
      end
    end

    local weeklyLabel = AceGUI:Create("InteractiveLabel")
    weeklyLabel:SetWidth(100)
    weeklyLabel:SetFontObject(GameFontNormal)
    weeklyLabel:SetJustifyH("CENTER")
    weeklyLabel:SetText(string.format("%d / 8", weeklyDone))
    if weeklyDone < 8 then
      weeklyLabel:SetColor(1, 0, 0) -- Red
    elseif hasBelow8 then
      weeklyLabel:SetColor(1, 0.5, 0) -- Orange
    elseif allAtLeast10 then
      weeklyLabel:SetColor(0, 1, 0) -- Green
    end
    -- Tooltip for weekly levels
    weeklyLabel:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      GameTooltip:ClearLines()
      GameTooltip:AddLine("Weekly Key Levels:")
      for i = 1, 8 do
        local level = weeklies[i].level or 0
        GameTooltip:AddLine(string.format("Key %d: %d", i, level), 1, 1, 1)
      end
      GameTooltip:Show()
    end)
    weeklyLabel:SetCallback("OnLeave", function(widget)
      GameTooltip:Hide()
    end)
    characterFrame:AddChild(weeklyLabel)

    -- Add sparks label (no coloring)
    local sparksLabel = AceGUI:Create("Label")
    sparksLabel:SetWidth(100)
    sparksLabel:SetFontObject(GameFontNormal)
    sparksLabel:SetJustifyH("CENTER")
    sparksLabel:SetText(tostring(nbSparks) .. "/" .. self:GetSparkData())
    characterFrame:AddChild(sparksLabel)

    container.weekly.weeklyScroll:AddChild(characterFrame)
  end

  -- Final layout update
  container.weekly.weeklyScroll:DoLayout()
end
