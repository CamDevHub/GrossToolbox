local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Utils = {}
GT.Modules.Utils = Utils

function Utils:FetchPartyMembersFullName()
    local partyMemberFullNames = {}
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = (LE_PARTY_CATEGORY_INSTANCE == GetInstanceInfo()) and ("raid" .. i) or
                ("party" .. i)
            if UnitExists(unit) then
                local name, realm = UnitName(unit)
                if name then
                    if realm and realm ~= "" then
                        partyMemberFullNames[name .. "-" .. realm] = true
                    else
                        local localRealm = GetRealmName()
                        partyMemberFullNames[name .. "-" .. localRealm] = true
                    end
                end
            end
        end
    end

    local localName, localRealm = UnitName("player")
    if localName and localRealm and localRealm ~= "" then
        partyMemberFullNames[localName .. "-" .. localRealm] = true
    elseif localName then
        partyMemberFullNames[localName .. "-" .. GetRealmName()] = true
    end

    return partyMemberFullNames
end

function Utils:TableContains(tbl, item)
	if type(tbl) ~= "table" then return false end
	for _, value in ipairs(tbl) do
		if value == item then
			return true
		end
	end
	return false
end