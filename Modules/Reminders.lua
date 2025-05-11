local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Reminders = {}
GT.Modules.Reminders = Reminders

local AceGUI = LibStub("AceGUI-3.0")

local Utils
function Reminders:Init()
    local GrossFrame = GT.Modules.GrossFrame
    if not GrossFrame then
        print(addonName .. ": Reminders module initialization failed - GrossFrame module not found")
        return false
    end

    Utils = GT.Core.Utils

    -- Register the Reminders tab
    local remindersTab = {
        text = "Reminders",
        value = "remindersTab",
        drawFunc = function(container) self:DrawFrame(container) end,
        populateFunc = function(container) self:PopulateFrame(container) end,
        module = Reminders,
        order = 3
    }
    GrossFrame:RegisterTab(remindersTab)
    return true
end

function Reminders:DrawFrame(container)
    container:ReleaseChildren()
    local mainGroup = AceGUI:Create("SimpleGroup")
    mainGroup:SetFullWidth(true)
    mainGroup:SetLayout("Flow")

    -- Left: Reminders List
    local leftGroup = AceGUI:Create("SimpleGroup")
    leftGroup:SetWidth(250)
    leftGroup:SetLayout("List")
    local remindersLabel = AceGUI:Create("Heading")
    remindersLabel:SetText("Reminders Setup")
    leftGroup:AddChild(remindersLabel)
    -- Placeholder for reminders list
    local remindersList = AceGUI:Create("Label")
    remindersList:SetText("(Reminders setup UI to be defined)")
    leftGroup:AddChild(remindersList)

    -- Right: Todo List
    local rightGroup = AceGUI:Create("SimpleGroup")
    rightGroup:SetFullWidth(true)
    rightGroup:SetLayout("List")
    local todoLabel = AceGUI:Create("Heading")
    todoLabel:SetText("Todo List")
    rightGroup:AddChild(todoLabel)
    -- Placeholder for todo list
    local todoList = AceGUI:Create("Label")
    todoList:SetText("(Todo list UI to be implemented)")
    rightGroup:AddChild(todoList)

    -- Add left and right columns to main group
    mainGroup:AddChild(leftGroup)
    mainGroup:AddChild(rightGroup)
    container:AddChild(mainGroup)
    Utils:DebugPrint("Reminders: DrawFrame called")
end

function Reminders:PopulateFrame(container)
    -- For now, nothing to populate
    Utils:DebugPrint("Reminders: PopulateFrame called, but no data to populate.")
end
