local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Utils = {}
GT.Modules.Utils = Utils

function Utils:TableContainsValue(tbl, item)
	if type(tbl) ~= "table" then return false end
	for _, value in pairs(tbl) do
		if value == item then
			return true
		end
	end
	return false
end

function Utils:DebugPrint(...)
    if GT.debug then
        local args = {...}
        local message = table.concat(args, " ")
        print("|cFF00FF00[DEBUG]|r " .. message)
    end
end