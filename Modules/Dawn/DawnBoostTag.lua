local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Dawn = {}
GT.Modules.Dawn = Dawn

-- Only keep shared state and initialization logic here.
Dawn.partyUIDs = {}
Dawn.currentHoveredDungeon = nil
Dawn.originalKeysText = nil
Dawn.moduleName = "Dawn"

local addon, Character, Player, Data, Utils, Config, GrossFrame

function Dawn:Init(database)
    if not database then
        print(addonName .. ": Dawn module initialization failed - missing database")
        return false
    end
    addon = GT.addon
    if not addon then
        print(addonName .. ": Dawn module initialization failed - addon reference not found")
        return false
    end
    Utils = GT.Modules.Utils
    if not Utils then
        print(addonName .. ": Dawn module initialization failed - Utils module not found")
        return false
    end
    Character = GT.Modules.Character
    if not Character then
        print(addonName .. ": Dawn module initialization failed - Character module not found")
        return false
    end
    Player = GT.Modules.Player
    if not Player then
        print(addonName .. ": Dawn module initialization failed - Player module not found")
        return false
    end
    Data = GT.Modules.Data
    if not Data then
        print(addonName .. ": Dawn module initialization failed - Data module not found")
        return false
    end
    Config = GT.Modules.Config
    if not Config then
        print(addonName .. ": Dawn module initialization failed - Config module not found")
        return false
    end
    GrossFrame = GT.Modules.GrossFrame
    if not GrossFrame then
        print(addonName .. ": Dawn module initialization failed - GrossFrame module not found")
        return false
    end
    -- Register only one main tab container for Dawn
    local dawnTab = {
        text = "Dawn",
        value = "dawn",
        drawFunc = function(container) Dawn:DrawTabContainer(container) end,
        populateFunc = function(container) end,
        module = Dawn
    }
    GrossFrame:RegisterTab(dawnTab)
    Utils:DebugPrint("Dawn module initialized successfully")
    return true
end

function Dawn:DrawTabContainer(container)
    -- This will create a TabGroup and add the Signup and Player Editor tabs inside it
    local AceGUI = LibStub("AceGUI-3.0")
    container:ReleaseChildren()
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetTabs({
        { text = "Signup", value = "signup" },
        { text = "Player Editor", value = "playerEditor" },
    })
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, group)
        widget:ReleaseChildren()
        if group == "signup" then
            Dawn:DrawSignupFrame(widget)
            Dawn:PopulateDawnFrame(widget)
        elseif group == "playerEditor" then
            Dawn:DrawPlayerEditorFrame(widget)
            Dawn:PopulatePlayerEditorFrame(widget)
        end
    end)
    tabGroup:SelectTab("signup")
    container:AddChild(tabGroup)
end

function Dawn:GetPartyUIDs()
    if not self.partyUIDs then self.partyUIDs = {} end
    local localUID = GT.addon:GetUID()
    if localUID then self:addUID(localUID) end
    return self.partyUIDs
end
function Dawn:addUID(uid)
    if not self.partyUIDs then self.partyUIDs = {} end
    if not Utils:TableContainsValue(self.partyUIDs, uid) then
        table.insert(self.partyUIDs, uid)
    end
end
function Dawn:RemoveUID(uid)
    if not self.partyUIDs or uid == addon:GetUID() then return end
    for i, v in ipairs(self.partyUIDs) do
        if v == uid then
            table.remove(self.partyUIDs, i)
            Player:DeletePlayer(v)
            break
        end
    end
end
function Dawn:ClearPartyUIDs()
    if self.partyUIDs then
        for _, uid in ipairs(self.partyUIDs) do
            self:RemoveUID(uid)
        end
    end
    self.partyUIDs = {}
end
