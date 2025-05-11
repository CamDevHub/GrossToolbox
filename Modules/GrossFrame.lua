local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local GrossFrame = {}
GT.Modules.GrossFrame = GrossFrame

local AceGUI = LibStub("AceGUI-3.0")

-- Internal state
local registeredTabs = {} -- Table to hold tab definitions: { [value] = { text, value, drawFunc, populateFunc, module } }
local mainFrame = nil

local Utils, Config
function GrossFrame:Init()
    Utils = GT.Core.Utils
    Config = GT.Core.Config

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
    frame:SetWidth(1150)
    frame:SetHeight(700)

    local function CloseFrame(widget)
        AceGUI:Release(widget)
        mainFrame = nil
    end
    frame:SetCallback("OnClose", function(widget) CloseFrame(widget) end)

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")

    local tabs = {}
    local firstTabValue = Config:GetLastOpenedTabValue()
    for value, definition in pairs(registeredTabs) do
        table.insert(tabs, { text = definition.text, value = value })
        if not firstTabValue or firstTabValue == "" then firstTabValue = value end
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
