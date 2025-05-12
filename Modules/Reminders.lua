local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Reminders = {}
GT.Modules.Reminders = Reminders

local AceGUI = LibStub("AceGUI-3.0")

GetItemInfo = C_Item.GetItemInfo
local Utils
local db
local iconFrameAnchor = { point = "CENTER", x = 0, y = 200 }

function Reminders:Init(database)
    local GrossFrame = GT.Modules.GrossFrame
    if not GrossFrame then
        print(addonName .. ": Reminders module initialization failed - GrossFrame module not found")
        return false
    end
    if not database or not database.global or not database.global.reminders then
        print(addonName .. ": Reminders module initialization failed - No database provided")
        return false
    end
    db = database.global.reminders

    if not database.global.anchors.reminder then
        database.global.anchors.reminder = iconFrameAnchor
    end
    self.reminderAnchor = database.global.anchors.reminder

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

-- Ready Check Icon Display
local readyCheckFrame
local function SaveIconFramePosition()
    if readyCheckFrame then
        local point, _, _, x, y = readyCheckFrame:GetPoint()
        Reminders.reminderAnchor.point = point
        Reminders.reminderAnchor.x = x
        Reminders.reminderAnchor.y = y
    end
end

local function LoadIconFramePosition()
    local anchor = Reminders.reminderAnchor
    return anchor.point, anchor.x, anchor.y
end

local function MakeDraggable(frame)
    frame.frame:SetMovable(true)
    frame.frame:EnableMouse(true)
    frame.frame:RegisterForDrag("LeftButton")
    frame.frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame.frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveIconFramePosition()
    end)
end

function Reminders:MustShowReminders()
    for _, entry in ipairs(db) do
        local qty = Reminders:GetItemCountInBags(entry.itemID)
        if entry.icon and qty <= (entry.threshold or 1) then
            return true -- Still missing something
        end
    end
    return false
end

local function ItemFieldEnterPressed(widget, event, text)
    Utils:DebugPrint("ItemFieldEnterPressed:", "Text entered:", text)
    local itemID = tonumber(text)
    if not itemID then
        -- Try to resolve by item link or name
        local idFromLink = text:match("item:(%d+)")
        if idFromLink then
            itemID = tonumber(idFromLink)
        else
            local name, _, _, _, _, _, _, _, _, itemIcon, id = GetItemInfo(text)
            if not name or not id then
                Utils:DebugPrint("ItemFieldEnterPressed:", "Please enter a valid item ID, item link, or a cached item name.")
                return
            end
            itemID = id
            text = tostring(id)
        end
    end
    local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
    if not itemName then
        Utils:DebugPrint("ItemFieldEnterPressed:", "Item not cached. Please search for the item in-game first or try again.")
        return
    end
    -- Use bag count as quantity
    local quantity = Reminders:GetItemCountInBags(itemID)
    local maxStack = select(8, GetItemInfo(itemID)) or 100
    local threshold = math.max(1, math.floor(maxStack * 0.1))
    local found = false
    for _, entry in ipairs(db) do
        if entry.itemID == itemID then
            entry.quantity = quantity
            entry.name = itemName
            entry.icon = itemIcon
            entry.threshold = entry.threshold or threshold
            found = true
            break
        end
    end
    Utils:DebugPrint("ItemFieldEnterPressed:", "Item ID:", itemID, "Name:", itemName, "Quantity:", quantity)
    if not found then
        table.insert(db, { itemID = itemID, name = itemName, quantity = quantity, icon = itemIcon, threshold = threshold })
    end
    Reminders:DrawReminderList()
end

local function ShowReminderIcons()
    Utils:DebugPrint("Reminders", "ShowReminderIcons called")
    -- Return early if in combat or in any instance
    if not Reminders:MustShowReminders() or InCombatLockdown() or IsInInstance() then
        Utils:DebugPrint("Reminders", "Not showing icons: In combat or in instance")
        return
    end

    if readyCheckFrame then
        readyCheckFrame:ReleaseChildren()
        Utils:DebugPrint("Reminders", "Ready Check Icons already displayed")
    else
        readyCheckFrame = AceGUI:Create("SimpleGroup")
        readyCheckFrame:SetWidth(32 * #db + 32)
        readyCheckFrame:SetLayout("Flow")

        -- Set position from saved anchor
        local point, x, y = LoadIconFramePosition()
        Utils:DebugPrint("Reminders", "Ready Check Icons position:", point, x, y)
        readyCheckFrame:ClearAllPoints()
        readyCheckFrame:SetPoint(point or "CENTER", UIParent, point or "CENTER", x or 0, y or 200)
        MakeDraggable(readyCheckFrame)
        Utils:DebugPrint("Reminders", "Ready Check Icons frame created")
    end

    for _, entry in ipairs(db) do
        if entry.icon and entry.quantity <= entry.threshold then
            Utils:DebugPrint("Reminders", "Ready Check Icon:", entry.icon, "Item ID:", entry.itemID, "Quantity:", entry.quantity)
            local iconWidget = AceGUI:Create("Label")
            iconWidget:SetImage(entry.icon)
            iconWidget:SetImageSize(32, 32)
            iconWidget:SetWidth(32)
            iconWidget:SetHeight(32)
            iconWidget:SetFontObject(GameFontNormal)
            iconWidget:SetJustifyH("CENTER")
            iconWidget:SetJustifyV("TOP")

            local qty = Reminders:GetItemCountInBags(entry.itemID)
            iconWidget:SetText("|cffffffff"..qty.."|r")

            readyCheckFrame:AddChild(iconWidget)
        end
    end
    Utils:DebugPrint("Reminders", "Ready Check Icons displayed")
end

local function HideReminderIcons()
    if readyCheckFrame then
        SaveIconFramePosition()
        readyCheckFrame:ReleaseChildren()
    end
end

local listFrame -- forward declaration for the list container
function Reminders:DrawFrame(container)
    container:ReleaseChildren() -- Clear previous widgets to prevent stacking

    -- Add a parent container to hold all Reminders UI
    local parentGroup = AceGUI:Create("SimpleGroup")
    parentGroup:SetLayout("Flow")
    parentGroup:SetFullWidth(true)
    container:AddChild(parentGroup)

    -- Input group for item ID only (full width)
    local inputGroup = AceGUI:Create("SimpleGroup")
    inputGroup:SetLayout("Flow")
    inputGroup:SetFullWidth(true)
    local inputItemID = AceGUI:Create("EditBox")
    inputItemID:SetLabel("Drag item here or ID")
    inputItemID:SetWidth(150)
    inputItemID:SetCallback("OnEnterPressed", ItemFieldEnterPressed)
    inputGroup:AddChild(inputItemID)
    parentGroup:AddChild(inputGroup)

    -- Reminder section (header + list) in a half-width group
    local reminderSection = AceGUI:Create("SimpleGroup")
    reminderSection:SetLayout("List")
    reminderSection:SetWidth(0.5)
    reminderSection:SetRelativeWidth(0.5)

    local heading = AceGUI:Create("Heading")
    heading:SetText("Reminder Items")
    heading:SetFullWidth(true)
    reminderSection:AddChild(heading)

    listFrame = AceGUI:Create("SimpleGroup")
    listFrame:SetLayout("List")
    listFrame:SetFullWidth(true)
    reminderSection:AddChild(listFrame)

    parentGroup:AddChild(reminderSection)

    parentGroup:DoLayout()
    self:DrawReminderList()

    if GT.debug then
        local debugButton = AceGUI:Create("Button")
        debugButton:SetText("Debug")
        debugButton:SetWidth(100)
        debugButton:SetCallback("OnClick", function()
            ShowReminderIcons()
            C_Timer.After(5, function()
                HideReminderIcons()
            end)
        end)
        parentGroup:AddChild(debugButton)
    end

    Utils:DebugPrint("Reminders: DrawFrame called")
end

function Reminders:DrawReminderList()
    if not listFrame then return end
    listFrame:ReleaseChildren()
    if #db == 0 then
        local label = AceGUI:Create("Label")
        label:SetText("No reminder items added.")
        listFrame:AddChild(label)
    else
        for idx, entry in ipairs(db) do
            entry.quantity = Reminders:GetItemCountInBags(entry.itemID)
            -- Add threshold field if not present
            if not entry.threshold then
                local maxStack = select(8, GetItemInfo(entry.itemID)) or 100
                entry.threshold = math.max(1, math.floor(maxStack * 0.2))
            end

            local group = AceGUI:Create("SimpleGroup")
            group:SetLayout("Flow")
            group:SetFullWidth(true)

            local iconWidget = AceGUI:Create("Icon")
            if entry.icon then
                iconWidget:SetImage(entry.icon)
                iconWidget:SetImageSize(24, 24)
            end
            iconWidget:SetWidth(30)
            group:AddChild(iconWidget)

            local nameLabel = AceGUI:Create("Label")
            nameLabel:SetText((entry.name or ("ItemID: "..entry.itemID)) .. " x" .. entry.quantity)
            nameLabel:SetWidth(200)
            group:AddChild(nameLabel)

            -- Threshold input
            local thresholdBox = AceGUI:Create("EditBox")
            thresholdBox:SetLabel("Threshold")
            thresholdBox:SetWidth(80)
            thresholdBox:SetText(tostring(entry.threshold))
            thresholdBox:SetCallback("OnEnterPressed", function(box, _, val)
                local num = tonumber(val)
                if num and num > 0 then
                    entry.threshold = num
                else
                    box:SetText(tostring(entry.threshold))
                end
            end)
            group:AddChild(thresholdBox)

            -- Remove button
            local removeBtn = AceGUI:Create("Button")
            removeBtn:SetText("X")
            removeBtn:SetWidth(70)
            removeBtn:SetCallback("OnClick", function()
                table.remove(db, idx)
                Reminders:DrawReminderList()
            end)
            group:AddChild(removeBtn)

            listFrame:AddChild(group)
        end
    end
    listFrame:DoLayout()
end

function Reminders:PopulateFrame(container)
    self:DrawReminderList()
    Utils:DebugPrint("Reminders: PopulateFrame called")
end

-- Returns the total count of an item (by itemID) in the player's bags
function Reminders:GetItemCountInBags(itemID)
    if not itemID then return 0 end
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.itemID == itemID then
                count = count + (itemInfo.stackCount or 1)
            end
        end
    end
    return count
end

function Reminders:GROSSTOOLBOX_OPENED()
    HideReminderIcons()
end

function Reminders:GROSSTOOLBOX_CLOSED()
    ShowReminderIcons()
end

-- Event handlers for ready check
function Reminders:READY_CHECK()
    ShowReminderIcons()
end

function Reminders:READY_CHECK_FINISHED()
    HideReminderIcons()
end

function Reminders:PLAYER_UPDATE_RESTING()
    if not self:MustShowReminders() then
        HideReminderIcons()
    else
        ShowReminderIcons()
    end
end

function Reminders:BAG_UPDATE_DELAYED()
    if not self:MustShowReminders() then
        HideReminderIcons()
    else
        ShowReminderIcons()
    end
end

function Reminders:PLAYER_LOGOUT()
    -- Save anchor to db
    if self.reminderAnchor and self.db then
        self.db.global.anchors.reminder = self.reminderAnchor
    end
end