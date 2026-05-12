local AddonName, GT = ...

local Dawn = GT.Modules.Dawn

-- Both tables are mutated in place (never replaced) so that Dawn.cachedPartyUIDs
-- and Dawn.cachedByArmor remain valid live references for all consumers without
-- coupling them to this file's upvalue.
local cachedPartyUIDs = {}
Dawn.cachedPartyUIDs  = cachedPartyUIDs

local cachedByArmor = {}
Dawn.cachedByArmor  = cachedByArmor

local function RefreshPartyCache()
    GT.Core:DebugPrint("PartyCache: RefreshPartyCache fired")

    -- Build party name set (local — only needed to resolve UIDs below)
    local names = {}
    names[UnitName("player"):lower()] = true
    if IsInGroup() and not IsInRaid() then
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party" .. i)
            if name then names[name:lower()] = true end
        end
    end

    local players    = GT.DB.players or {}
    local myID       = GT.DB.uniqueID
    local ARMOR_ORDER    = GT.Data.ARMOR_ORDER
    local CLASS_TO_ARMOR = GT.Data.CLASS_TO_ARMOR

    -- Rebuild cachedPartyUIDs
    wipe(cachedPartyUIDs)
    cachedPartyUIDs[myID] = true
    for uid, data in pairs(players) do
        if uid ~= myID then
            for charName in pairs(data.chars or {}) do
                if names[charName] then
                    cachedPartyUIDs[uid] = true
                    break
                end
            end
        end
    end

    -- Rebuild cachedByArmor from the now-current cachedPartyUIDs
    wipe(cachedByArmor)
    for _, armor in ipairs(ARMOR_ORDER) do
        cachedByArmor[armor] = {}
    end
    for uid in pairs(cachedPartyUIDs) do
        local data = players[uid]
        if data then
            for charName, charData in pairs(data.chars or {}) do
                if not charData.hideFromTag then
                    local armor = CLASS_TO_ARMOR[(charData.class or ""):upper()]
                    if armor then
                        table.insert(cachedByArmor[armor], { uid = uid, charName = charName, charData = charData })
                    end
                end
            end
        end
    end
end

Dawn.RefreshPartyCache = RefreshPartyCache
