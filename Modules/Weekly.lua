local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"

local Weekly = {}
GT.Modules.Weekly = Weekly

local AceGUI = LibStub("AceGUI-3.0")

-- Define module name for initialization logging
Weekly.moduleName = "Weekly"

-- Define module dependencies
local addon, Utils, GrossFrame, Character, Player
function Weekly:Init()

  addon = GT.addon
  Utils = GT.Modules.Utils
  Character = GT.Modules.Character
  Player = GT.Modules.Player
  GrossFrame = GT.Modules.GrossFrame

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

local function CreateRaidVaultLabel(raidProgress)
  local group = AceGUI:Create("SimpleGroup")
  group:SetLayout("Flow")
  group:SetWidth(180)
  -- If no raid progress, show three dashes in red
  if not raidProgress or #raidProgress == 0 then
    for _ = 1, 3 do
      local label = AceGUI:Create("InteractiveLabel")
      label:SetWidth(60)
      label:SetFontObject(GameFontNormal)
      label:SetJustifyH("CENTER")
      label:SetText("|cffff0000-|r")
      group:AddChild(label)
    end
    return group
  end
  
  for _, info in ipairs(raidProgress) do
    local label = AceGUI:Create("InteractiveLabel")
    label:SetWidth(60)
    label:SetFontObject(GameFontNormal)
    label:SetJustifyH("CENTER")

    local diffName = (info.level == 14 and "N") or (info.level == 15 and "H") or (info.level == 16 and "M") or tostring(info.level)
    if info.unlocked then
      label:SetText(diffName)
      label:SetColor(0, 1, 0) -- Green
    else
      label:SetText("-")
      label:SetColor(1, 0, 0) -- Red
    end
    
    label:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      GameTooltip:ClearLines()
      GameTooltip:AddLine(string.format("Raid Reward (%s)", diffName))
      if info.progress >= info.threshold then
        GameTooltip:AddLine(string.format("Progress: %d/%d", info.threshold, info.threshold))
      else
        GameTooltip:AddLine(string.format("Progress: %d/%d", info.progress, info.threshold))
      end
      GameTooltip:AddLine(string.format("Difficulty: %s", diffName))
      GameTooltip:Show()
    end)
    label:SetCallback("OnLeave", function(widget) GameTooltip:Hide() end)
    group:AddChild(label)
  end
  return group
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

  local nameHeader = AceGUI:Create("Label")
  nameHeader:SetText("Characters")
  nameHeader:SetWidth(200)
  nameHeader:SetFontObject(GameFontNormalHuge)
  weeklyTable:AddChild(nameHeader)

  local keysHeader = AceGUI:Create("Label")
  keysHeader:SetText("Keys")
  keysHeader:SetWidth(120)
  keysHeader:SetFontObject(GameFontNormalHuge)
  keysHeader:SetJustifyH("CENTER")
  weeklyTable:AddChild(keysHeader)

  local sparksHeader = AceGUI:Create("Label")
  sparksHeader:SetText("Raid")
  sparksHeader:SetWidth(180)
  sparksHeader:SetFontObject(GameFontNormalHuge)
  sparksHeader:SetJustifyH("CENTER")
  weeklyTable:AddChild(sparksHeader)

  local raidHeader = AceGUI:Create("Label")
  raidHeader:SetText("Sparks")
  raidHeader:SetWidth(120)
  raidHeader:SetFontObject(GameFontNormalHuge)
  raidHeader:SetJustifyH("CENTER")
  weeklyTable:AddChild(raidHeader)

  weeklyTabContainer:AddChild(weeklyTable)
  container.weekly.weeklyScroll = weeklyTabContainer
end

local function CreateSparksLabel(nbSparks, maxSparks)
  local label = AceGUI:Create("Label")
  label:SetWidth(120)
  label:SetFontObject(GameFontNormal)
  label:SetJustifyH("CENTER")
  label:SetText(tostring(nbSparks) .. "/" .. tostring(maxSparks))
  return label
end

local function CreateDungeonVaultLabel(count, threshold, weeklies)
  local vaultLabel = AceGUI:Create("InteractiveLabel")
  vaultLabel:SetWidth(40)
  vaultLabel:SetFontObject(GameFontNormal)
  vaultLabel:SetJustifyH("CENTER")
  vaultLabel:SetText(string.format("%d/%d", count, threshold))
  if count < threshold then
    vaultLabel:SetColor(1, 0, 0) -- Red
  else
    vaultLabel:SetColor(0, 1, 0) -- Green
  end
  vaultLabel:SetCallback("OnEnter", function(widget)
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Weekly Key Levels:")
    for k = 1, 8 do
      local level = weeklies[k] and weeklies[k].level or 0
      GameTooltip:AddLine(string.format("Key %d: %d", k, level), 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  vaultLabel:SetCallback("OnLeave", function(widget)
    GameTooltip:Hide()
  end)
  return vaultLabel
end

local function AddCharacterWeeklyRow(container, uid, fullName)
  local characterFrame = AceGUI:Create("SimpleGroup")
  characterFrame:SetLayout("Flow")
  characterFrame:SetFullWidth(true)

  local nameLabel = AceGUI:Create("Label")
  nameLabel:SetText(fullName)
  nameLabel:SetWidth(200)
  nameLabel:SetFontObject(GameFontNormal)
  characterFrame:AddChild(nameLabel)

  -- Use new weekly structure from Character.lua
  local dungeons = Character:GetWeeklyDungeons(uid, fullName) or {}
  local raid = Character:GetWeeklyRaid(uid, fullName) or {}
  local nbSparks = Character:GetSparksData(uid, fullName)

  -- Vault thresholds: 1, 4, 8
  for i, threshold in ipairs({1, 4, 8}) do
    local count = 0
    for j = 1, threshold do
      local level = dungeons[j] and dungeons[j].level or 0
      if level >= 10 then count = count + 1 end
    end
    local vaultLabel = CreateDungeonVaultLabel(count, threshold, dungeons)
    characterFrame:AddChild(vaultLabel)
  end

  -- Raid weekly reward
  local raidLabel = CreateRaidVaultLabel(raid)
  characterFrame:AddChild(raidLabel)

  local sparksLabel = CreateSparksLabel(nbSparks, Weekly:GetSparkData())
  characterFrame:AddChild(sparksLabel)

  container.weekly.weeklyScroll:AddChild(characterFrame)

  -- Add a blank label for margin between rows
  local margin = AceGUI:Create("Label")
  margin:SetFullWidth(true)
  margin:SetText(" ")
  margin:SetHeight(6)
  container.weekly.weeklyScroll:AddChild(margin)
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
    AddCharacterWeeklyRow(container, uid, fullName)
  end

  -- Final layout update
  container.weekly.weeklyScroll:DoLayout()
end
