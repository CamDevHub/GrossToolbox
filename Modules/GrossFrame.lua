local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local GrossFrame = {}
GT.Modules.GrossFrame = GrossFrame

local AceGUI = LibStub("AceGUI-3.0")

-- Internal state
local registeredTabs = {} -- Table to hold tab definitions: { [value] = { text, value, drawFunc, populateFunc, module } }
local mainFrame = nil

local addon, Utils, Config
function GrossFrame:Init()
    Utils = GT.Core.Utils
    Config = GT.Core.Config
    addon = GT.addon

    Utils:DebugPrint("GrossFrame module initialized successfully")
    return true
end

function GrossFrame:RegisterTab(tabDefinition)
    if type(tabDefinition) == "table" and tabDefinition.value and tabDefinition.text and tabDefinition.drawFunc and type(tabDefinition.drawFunc) == 'function' and tabDefinition.populateFunc and type(tabDefinition.populateFunc) == 'function' then
        registeredTabs[tabDefinition.value] = tabDefinition
    end
end

function GrossFrame:GetOrCreateMainFrame()
    if mainFrame then
        return mainFrame
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(addonName)
    frame:SetLayout("Fill")
    frame:EnableResize(false)
    frame:SetStatusText(addonName)
    frame:SetWidth(1170)
    frame:SetHeight(700)

    local function CloseFrame(widget)
        AceGUI:Release(widget)
        mainFrame = nil
    end
    frame:SetCallback("OnClose", function(widget)
        CloseFrame(widget)
        addon:SendMessage("GROSSTOOLBOX_CLOSED")
    end)

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")

    local tabs = {}
    local firstTabValue = Config:GetLastOpenedTabValue()
    -- Sort tabs by 'order' field if present, otherwise by insertion order
    local sortedTabDefs = {}
    for value, definition in pairs(registeredTabs) do
        table.insert(sortedTabDefs, { value = value, definition = definition })
    end
    table.sort(sortedTabDefs, function(a, b)
        local orderA = a.definition.order or 9999
        local orderB = b.definition.order or 9999
        if orderA == orderB then
            return a.value < b.value
        end
        return orderA < orderB
    end)
    for _, tab in ipairs(sortedTabDefs) do
        table.insert(tabs, { text = tab.definition.text, value = tab.value })
        if not firstTabValue or firstTabValue == "" then firstTabValue = tab.value end
    end

    tabGroup:SetTabs(tabs)
    frame:AddChild(tabGroup)
    frame.tabGroup = tabGroup

    tabGroup:SetCallback("OnGroupSelected", function(widget, event, groupValue)
        widget:ReleaseChildren()
        local definition = registeredTabs[groupValue]
        if definition then
            local containerWidget = AceGUI:Create("SimpleGroup")
            containerWidget:SetLayout("Fill")

            widget:AddChild(containerWidget)

            Utils:DebugPrint("Selected tab: " .. groupValue)
            definition.drawFunc(containerWidget)
            definition.populateFunc(containerWidget)

            Config:SetLastOpenedTabValue(groupValue)
        end
    end)

    tabGroup:SelectTab(firstTabValue)
    mainFrame = frame
    return mainFrame
end

function GrossFrame:ToggleMainFrame()
    if not mainFrame then
        mainFrame = self:GetOrCreateMainFrame()
        return
    end

    mainFrame:Hide()
end

function GrossFrame:GetMainFrame()
    return mainFrame
end
