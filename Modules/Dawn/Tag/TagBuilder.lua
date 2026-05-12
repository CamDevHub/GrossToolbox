local AddonName, GT = ...

local Dawn = GT.Modules.Dawn

local DUNGEONS    = GT.Data.DUNGEONS
local CLASS_NAMES = GT.Data.CLASS_NAMES
local ARMOR_ORDER = GT.Data.ARMOR_ORDER

local function keystoneLabel(ks)
    if not ks or ks.level == 0 then return "No key" end
    local dungeon = DUNGEONS[ks.challengeId]
    return string.format("+%d %s", ks.level, dungeon and dungeon.short or "?")
end

-- ============================================================
-- Tag text
-- ============================================================

local function BuildTagText()
    GT.Core:DebugPrint("TagBuilder: BuildTagText()")
    local cachedPartyUIDs = Dawn.cachedPartyUIDs
    local players         = GT.DB.players or {}
    local myID            = GT.DB.uniqueID
    local lines           = {}
    local rendered        = {}
    local renderedCount   = 0

    local function renderPlayer(uid)
        if rendered[uid] then return end
        rendered[uid] = true
        renderedCount = renderedCount + 1

        local data = players[uid]
        if not data then return end

        if uid ~= myID then
            local discord = data.discordHandle or ""
            table.insert(lines, "<@" .. (discord ~= "" and discord .. ">" or "unknown"))
        end

        local sortedChars = {}
        for _, charData in pairs(data.chars or {}) do
            if not charData.hideFromTag then
                table.insert(sortedChars, charData)
            end
        end
        table.sort(sortedChars, function(a, b)
            return (a.mpRating or 0) > (b.mpRating or 0)
        end)

        for _, charData in ipairs(sortedChars) do
            local roleNames = {}
            local roles     = charData.roles or {}
            local ROLES     = GT.Data.ROLES
            if roles.tank then table.insert(roleNames, ROLES.TANK)    end
            if roles.heal then table.insert(roleNames, ROLES.HEALER)  end
            if roles.dps  then table.insert(roleNames, ROLES.DAMAGER) end
            local rolesStr  = #roleNames > 0 and table.concat(roleNames, " ") or "?"
            local className = CLASS_NAMES[charData.class] or charData.class or "?"
            local ks        = (not charData.forceNoKey) and charData.keystone or nil
            table.insert(lines, string.format(
                "%s %s | :%s: | :Raiderio: %d | :Keystone: %s | :Armor: %d iLvl",
                rolesStr,
                className,
                charData.faction  or "?",
                charData.mpRating or 0,
                keystoneLabel(ks),
                charData.ilvl     or 0
            ))
        end
        table.insert(lines, "")
    end

    -- Local player always first
    renderPlayer(myID)
    for uid in pairs(cachedPartyUIDs) do
        if uid ~= myID then renderPlayer(uid) end
    end

    local sign = GT.Data.NUMBER_SIGN[renderedCount]
    if sign then table.insert(lines, 1, "### " .. sign .. " Sign") end

    return table.concat(lines, "\n")
end

-- ============================================================
-- Team take text
-- ============================================================

local function BuildTeamTakeText()
    GT.Core:DebugPrint("TagBuilder: BuildTeamTakeText()")
    local cachedPartyUIDs = Dawn.cachedPartyUIDs
    local cachedByArmor   = Dawn.cachedByArmor
    local players = GT.DB.players or {}
    local myID    = GT.DB.uniqueID
    local used    = {}

    local mentions = {}
    for uid in pairs(cachedPartyUIDs) do
        if uid ~= myID then
            local data   = players[uid]
            local handle = data and data.discordHandle or ""
            if handle ~= "" then
                table.insert(mentions, "<@" .. handle .. ">")
            end
        end
    end

    local function pickRole(pool, role, usedUIDs)
        local best, bestScore = nil, math.huge
        for _, entry in ipairs(pool) do
            if not used[entry.charName] and not usedUIDs[entry.uid] then
                local roles = entry.charData.roles or {}
                if roles[role] then
                    local n = (roles.tank and 1 or 0) + (roles.heal and 1 or 0) + (roles.dps and 1 or 0)
                    if n < bestScore then best, bestScore = entry, n end
                end
            end
        end
        return best
    end

    local function formatChar(entry, roleSymbol)
        local cd        = entry.charData
        local className = CLASS_NAMES[cd.class] or cd.class or "?"
        local ks        = (not cd.forceNoKey) and cd.keystone or nil
        return string.format(
            "%s %s | :%s: | :Raiderio: %d | :Keystone: %s | :Armor: %d iLvl",
            roleSymbol,
            className,
            cd.faction  or "?",
            cd.mpRating or 0,
            keystoneLabel(ks),
            cd.ilvl     or 0
        )
    end

    local ROLES = GT.Data.ROLES
    local lines = {}

    for _, armor in ipairs(ARMOR_ORDER) do
        local pool     = cachedByArmor[armor]
        local usedUIDs = {}

        local function pick(role)
            local entry = pickRole(pool, role, usedUIDs)
            if entry then
                used[entry.charName] = true
                usedUIDs[entry.uid]  = true
            end
            return entry
        end

        local tank = pick("tank")
        local heal = pick("heal")
        local dps1 = pick("dps")
        local dps2 = pick("dps")

        if tank and heal and dps1 and dps2 then
            if #lines > 0 then table.insert(lines, "") end
            table.insert(lines, "### Team take")
            if #mentions > 0 then
                table.insert(lines, table.concat(mentions, " "))
            end
            table.insert(lines, "== " .. armor .. " ==")
            table.insert(lines, formatChar(tank, ROLES.TANK))
            table.insert(lines, formatChar(heal, ROLES.HEALER))
            table.insert(lines, formatChar(dps1, ROLES.DAMAGER))
            table.insert(lines, formatChar(dps2, ROLES.DAMAGER))
        end
    end

    return #lines > 0 and table.concat(lines, "\n") or "Not enough players to form parties."
end

Dawn.BuildTagText      = BuildTagText
Dawn.BuildTeamTakeText = BuildTeamTakeText
