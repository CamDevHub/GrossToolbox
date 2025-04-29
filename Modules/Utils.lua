local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Utils = {}
GT.Modules.Utils = Utils

function Utils:TableContainsValue(tbl, item)
    -- Validate table parameter
    if type(tbl) ~= "table" then
        -- Gracefully handle non-table input
        return false
    end
    
    -- Handle nil item cases
    if item == nil then
        -- Some tables use nil as a valid value, check if nil is explicitly used as a key
        for key, value in pairs(tbl) do
            if value == nil then
                return true
            end
        end
        return false
    end
    
    -- Search through the table for the item
    for _, value in pairs(tbl) do
        if value == item then
            return true
        end
    end
    
    -- Item not found
    return false
end

function Utils:DebugPrint(...)
    -- Only process if debug mode is enabled
    if not GT or GT.debug ~= true then
        return
    end
    
    -- Handle no arguments case
    local args = { ... }
    if #args == 0 then
        print("|cFF00FF00[DEBUG]|r <empty message>")
        return
    end
    
    -- Convert all arguments to strings and concatenate
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            -- Convert tables to a string representation
            args[i] = "table:" .. tostring(arg)
        elseif type(arg) ~= "string" and type(arg) ~= "number" and type(arg) ~= "boolean" then
            -- Convert other types to their string representation
            args[i] = type(arg) .. ":" .. tostring(arg)
        end
    end
    
    -- Concatenate all arguments and print with debug prefix
    local message = table.concat(args, " ")
    print("|cFF00FF00[DEBUG]|r " .. message)
end
