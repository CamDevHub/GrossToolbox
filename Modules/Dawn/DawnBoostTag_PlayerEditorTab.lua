local GT = _G.GT
local Dawn = GT.Modules.Dawn
local AceGUI = LibStub("AceGUI-3.0")

-- Player editor tab drawing and logic for DawnBoostTag

local Player, Character, Utils, Data
function Dawn:InitPlayerEditorTab()
    Player = GT.Modules.Player
    Character = GT.Modules.Character
    Utils = GT.Modules.Utils
    Data = GT.Modules.Data
end

function Dawn:DrawPlayerEditorFrame(container)
    if not container then return end

    if not container.editor then
        container.editor = {}
    end
    -- === Tab 2: Player Editor ===
    local playerEditorTabContainer = AceGUI:Create("ScrollFrame")
    playerEditorTabContainer:SetFullWidth(true)
    playerEditorTabContainer:SetLayout("Flow")
    container:AddChild(playerEditorTabContainer)
    container.editor.playerEditorScroll = playerEditorTabContainer
end

function Dawn:PopulatePlayerEditorFrame(container)
    if not container or not container.editor or not container.editor.playerEditorScroll then
        return
    end
    local uids = self:GetPartyUIDs()
    if not uids or next(uids) == nil then
        return
    end
    
    local scroll = container.editor.playerEditorScroll
    scroll:ReleaseChildren()
    scroll:SetScroll(0)
    for _, uid in ipairs(uids) do
        local discordTag = Player:GetDiscordTag(uid)
        if discordTag and discordTag ~= "" then
            local playerHeader = AceGUI:Create("Heading")
            playerHeader:SetText(discordTag)
            playerHeader:SetFullWidth(true)
            scroll:AddChild(playerHeader)
            local charactersName = Player:GetCharactersName(uid)
            for _, charFullName in ipairs(charactersName) do
                local keystone = Character:GetCharacterKeystone(uid, charFullName)
                local rating = Character:GetCharacterRating(uid, charFullName)
                local classId = Character:GetCharacterClassId(uid, charFullName)
                local charGroup = AceGUI:Create("SimpleGroup")
                local hasKey = Character:GetCharacterHasKey(uid, charFullName)
                local isHidden = Character:GetCharacterIsHidden(uid, charFullName)
                if keystone and keystone.level and keystone.level > 0 then
                    charGroup:SetLayout("Flow")
                    charGroup:SetFullWidth(true)
                    local nameLabel = AceGUI:Create("Label")
                    nameLabel:SetText(string.format("%s", charFullName))
                    nameLabel:SetWidth(180)
                    nameLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(nameLabel)
                    local ratingLabel = AceGUI:Create("Label")
                    local ratingColor = C_ChallengeMode.GetDungeonScoreRarityColor(rating) or { r = 1, g = 1, b = 1 }
                    local coloredRatingText = string.format("|cff%02x%02x%02x %d|r",
                        ratingColor.r * 255,
                        ratingColor.g * 255,
                        ratingColor.b * 255,
                        rating)
                    ratingLabel:SetText(coloredRatingText)
                    ratingLabel:SetWidth(120)
                    ratingLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(ratingLabel)
                    local classLabel = AceGUI:Create("Label")
                    local className = Data.CLASS_ID_TO_ENGLISH_NAME[classId] or "Unknown Class"
                    local classColorCode = Utils:GetClassColorFromID(classId)
                    classLabel:SetText(string.format("%s%s|r", classColorCode, className))
                    classLabel:SetWidth(120)
                    classLabel:SetFontObject(GameFontHighlight)
                    charGroup:AddChild(classLabel)
                    local noKeyForBoostCheckbox = AceGUI:Create("CheckBox")
                    noKeyForBoostCheckbox:SetLabel("No Key");
                    noKeyForBoostCheckbox:SetType("checkbox");
                    noKeyForBoostCheckbox:SetWidth(100);
                    noKeyForBoostCheckbox:SetUserData("uid", uid);
                    noKeyForBoostCheckbox:SetUserData("charFullName", charFullName);
                    noKeyForBoostCheckbox:SetValue(not hasKey)
                    noKeyForBoostCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                        local cbUID = widget:GetUserData("uid")
                        local cbCharFullName = widget:GetUserData("charFullName")
                        Character:SetCharacterHasKey(cbUID, cbCharFullName, not isChecked)
                    end)
                    charGroup:AddChild(noKeyForBoostCheckbox)
                    local hideCharCheckbox = AceGUI:Create("CheckBox")
                    hideCharCheckbox:SetLabel("Hide");
                    hideCharCheckbox:SetType("checkbox");
                    hideCharCheckbox:SetWidth(80);
                    hideCharCheckbox:SetUserData("uid", uid);
                    hideCharCheckbox:SetUserData("charFullName", charFullName);
                    hideCharCheckbox:SetValue(isHidden)
                    hideCharCheckbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                        local cbUID = widget:GetUserData("uid")
                        local cbCharFullName = widget:GetUserData("charFullName")
                        Character:SetCharacterIsHidden(cbUID, cbCharFullName, isChecked)
                    end)
                    charGroup:AddChild(hideCharCheckbox)
                    -- Role icons mapping using built-in game icons
                    local role_tex_file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp"
                    local role_t = "|T" .. role_tex_file .. ":%d:%d:"
                    local roleIcons = {
                        TANK = role_t .. "0:0:64:64:0:19:22:41|t",
                        HEALER = role_t .. "0:0:64:64:20:39:1:20|t",
                        DAMAGER = role_t .. "0:0:64:64:20:39:22:41|t"
                    }
                    local roleGroup = AceGUI:Create("SimpleGroup")
                    roleGroup:SetLayout("Flow")
                    roleGroup:SetWidth(300)
                    charGroup:AddChild(roleGroup)
                    local checkBoxes = {}
                    for role, _ in pairs(Data.ROLES) do
                        local checkbox = AceGUI:Create("CheckBox")
                        checkbox:SetLabel(string.format(roleIcons[role], 15, 15))
                        checkbox:SetType("checkbox")
                        checkbox:SetWidth(50)
                        local customRoles = Character:GetCharacterCustomRoles(uid, charFullName)
                        if customRoles and #customRoles > 0 then
                            checkbox:SetValue(Utils:TableContainsValue(customRoles, role))
                        end
                        checkbox:SetUserData("uid", uid)
                        checkbox:SetUserData("charFullName", charFullName)
                        checkbox:SetUserData("role", role)
                        checkbox:SetUserData("checkBoxes", checkBoxes)
                        checkbox:SetCallback("OnValueChanged", function(widget, event, isChecked)
                            local cbUID = widget:GetUserData("uid")
                            local cbCharFullName = widget:GetUserData("charFullName")
                            local otherCheckBoxes = widget:GetUserData("checkBoxes")
                            local rolesToSet = {}
                            for roleValue, cb in pairs(otherCheckBoxes) do
                                if cb:GetValue() then
                                    table.insert(rolesToSet, roleValue)
                                end
                            end
                            table.sort(rolesToSet, function(a, b)
                                return a > b
                            end)
                            Character:SetCharacterCustomRoles(cbUID, cbCharFullName, rolesToSet)
                        end)
                        roleGroup:AddChild(checkbox)
                        checkBoxes[role] = checkbox
                    end
                end
                charGroup:DoLayout()
                scroll:AddChild(charGroup)
            end
        end
    end
    scroll:DoLayout()
end

-- Add any other player editor tab related functions here
