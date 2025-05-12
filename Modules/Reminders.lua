local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Reminders = {}
GT.Modules.Reminders = Reminders

local AceGUI = LibStub("AceGUI-3.0")

GetItemInfo = C_Item.GetItemInfo
local Utils
local db -- reference to the addon database
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

-- Ready Check Icon Display
local readyCheckFrame

local function ShowReminderIcons()
    if readyCheckFrame then
        readyCheckFrame:Hide()
        readyCheckFrame:SetParent(nil)
    end

    readyCheckFrame = CreateFrame("Frame", "GrossToolbox_ReminderIcons", UIParent)
    readyCheckFrame:SetSize(60 * #db, 60)
    readyCheckFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    readyCheckFrame:Show()
    readyCheckFrame.icons = {}
    readyCheckFrame.labels = {}

    local x = 0
    for _, entry in ipairs(db) do
        if entry.icon then
            local icon = readyCheckFrame:CreateTexture(nil, "OVERLAY")
            icon:SetSize(48, 48)
            icon:SetPoint("LEFT", readyCheckFrame, "LEFT", x, 0)
            icon:SetTexture(entry.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            readyCheckFrame.icons[#readyCheckFrame.icons+1] = icon

            -- Quantity label below the icon
            local qty = Reminders:GetItemCountInBags(entry.itemID)
            local label = readyCheckFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            label:SetPoint("TOP", icon, "BOTTOM", 0, -2)
            label:SetText(tostring(qty))
            readyCheckFrame.labels[#readyCheckFrame.labels+1] = label

            x = x + 52
        end
    end
end

local function HideReminderIcons()
    if readyCheckFrame then
        readyCheckFrame:Hide()
        readyCheckFrame:SetParent(nil)
        readyCheckFrame = nil
    end
end

-- Register for ready check events
local f = CreateFrame("Frame")
f:RegisterEvent("READY_CHECK")
f:RegisterEvent("READY_CHECK_FINISHED")
f:SetScript("OnEvent", function(self, event)
    if event == "READY_CHECK" then
        ShowReminderIcons()
    elseif event == "READY_CHECK_FINISHED" then
        HideReminderIcons()
    end
end)
