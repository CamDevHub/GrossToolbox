local GT = _G.GT
local Dawn = {}
GT.Modules.Dawn = Dawn

-- Only keep shared state and initialization logic here.
Dawn.partyUIDs = {}
Dawn.currentHoveredDungeon = nil
Dawn.originalKeysText = nil
Dawn.moduleName = "Dawn"

local addon, Utils, Player, Character, GrossFrame
function Dawn:Init()

    addon = GT.addon
    Utils = GT.Core.Utils
    Player = GT.Core.Player
    Character = GT.Core.Character
    GrossFrame = GT.Modules.GrossFrame
    -- Register only one main tab container for Dawn
    local dawnTab = {
        text = "Dawn",
        value = "dawn",
        drawFunc = function(container) Dawn:DrawTabContainer(container) end,
        populateFunc = function(container) end,
        module = Dawn,
        order = 1
    }
    GrossFrame:RegisterTab(dawnTab)

    self:InitComm()
    self:InitPlayerEditorTab()
    self:InitSignupTab()

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

function Dawn:PLAYER_ENTERING_WORLD()
    C_Timer.After(3, function()
        local uid = GT.addon:GetUID()
        Player:SetDiscordTag(uid, Config:GetDiscordTag())
        Character:BuildCurrentCharacter(uid)
    end)
end