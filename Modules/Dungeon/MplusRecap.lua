local AddonName, GT = ...

local Screenshot = Screenshot

local Dungeon = GT.Modules.Dungeon

local PAD = 16

-- ============================================================
-- Damage meter session constants
-- ============================================================

local SESSION_CURRENT = Enum.DamageMeterSessionType.Current   -- 1
local SESSION_EXPIRED = Enum.DamageMeterSessionType.Expired   -- 2
local TYPE_DPS        = Enum.DamageMeterType.Dps              -- 1
local TYPE_HPS        = Enum.DamageMeterType.Hps              -- 3
local TYPE_INTERRUPTS = Enum.DamageMeterType.Interrupts       -- 5
local TYPE_DEATHS     = Enum.DamageMeterType.Deaths           -- 9

-- ============================================================
-- Shared table (read/written by MplusCategory.lua)
-- ============================================================

local Recap = {}
Dungeon.Recap = Recap

Recap.recapEnabled      = false
Recap.screenshotEnabled = false

-- ============================================================
-- Run state
-- ============================================================

local runStart        = 0
local activeMapID     = 0
local activeLevel     = 0
local activeTimeLimit = 0   -- seconds; from C_ChallengeMode.GetMapUIInfo
local partyData       = {}  -- [guid] = { guid, name, class, role, spec, unitToken }

-- ============================================================
-- Helpers
-- ============================================================

local ROLE_LABEL = { TANK = "Tank", HEALER = "Healer", DAMAGER = "DPS", NONE = "—" }
local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }

local function fmtTime(s)
    s = math.floor(s)
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

-- Returns "elapsed  (±delta)" with colour; timeLimit=0 → no delta suffix.
local function fmtElapsed(elapsed, timeLimit)
    local base = fmtTime(elapsed)
    if not timeLimit or timeLimit == 0 then return base end
    local delta = elapsed - timeLimit
    if delta <= 0 then
        return base .. string.format("  |cff44ff44(-%s)|r", fmtTime(-delta))
    else
        return base .. string.format("  |cffff4444(+%s)|r", fmtTime(delta))
    end
end

local function fmtNum(n)
    n = n or 0
    if n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 1000  then return string.format("%.1fK", n / 1000)
    end
    return string.format("%d", n)
end

-- Try the current session; fall back to the most recently expired one.
local function getSessionAmount(guid, dataType)
    local data = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_CURRENT, dataType, guid)
    if not data or (data.totalAmount or 0) == 0 then
        data = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_EXPIRED, dataType, guid)
    end
    return data and (data.totalAmount or 0) or 0
end

-- ============================================================
-- Party data collection
-- ============================================================

local function collectPartyData()
    wipe(partyData)

    local units = { "player" }
    if IsInGroup() and not IsInRaid() then
        for i = 1, GetNumGroupMembers() - 1 do
            table.insert(units, "party" .. i)
        end
    end

    for _, unit in ipairs(units) do
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            local role     = UnitGroupRolesAssigned(unit) or "NONE"
            local guid     = UnitGUID(unit)

            partyData[guid] = {
                guid      = guid,
                name      = name,
                class     = class and class:lower(),
                role      = role,
                spec      = nil,  -- filled by INSPECT_READY
                unitToken = unit,
            }

            if unit == "player" then
                local specIndex = GetSpecialization()
                if specIndex and specIndex > 0 then
                    local _, specName = GetSpecializationInfo(specIndex)
                    partyData[guid].spec = specName
                end
            else
                NotifyInspect(unit)
            end
        end
    end
end

-- ============================================================
-- Recap popup
-- ============================================================

local COL_NAME = 170
local COL_DATA = 85
local ROW_H    = 38
local MAX_ROWS = 5

local COLS    = { "DPS", "HPS", "Int.", "Deaths" }
local POPUP_W = PAD + COL_NAME + #COLS * COL_DATA + PAD
local POPUP_H = 28 + 24 + 24 + MAX_ROWS * ROW_H + PAD

local popup, content = GT.UI:CreatePopup("M+ Recap", POPUP_W, POPUP_H)
Recap.popup = popup

-- Subtitle
local subtitle = content:CreateFontString(nil, "OVERLAY")
GT.UI:SetFont(subtitle, 12, "")
subtitle:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -8)
subtitle:SetTextColor(0.6, 0.6, 0.6)

-- Column headers
for i, label in ipairs(COLS) do
    local lbl = content:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(lbl, 12, "")
    lbl:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + COL_NAME + (i - 1) * COL_DATA, -8 - 20)
    lbl:SetWidth(COL_DATA)
    lbl:SetJustifyH("CENTER")
    lbl:SetText(label)
    lbl:SetTextColor(0.5, 0.5, 0.5)
end

-- Separator under column headers
local headerSep = content:CreateTexture(nil, "ARTWORK")
headerSep:SetPoint("TOPLEFT",  content, "TOPLEFT",  PAD,  -8 - 20 - 18)
headerSep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, -8 - 20 - 18)
headerSep:SetHeight(1)
headerSep:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Row pool
local rows = {}
for i = 1, MAX_ROWS do
    local rowY = -(8 + 24 + (i - 1) * ROW_H)

    local nameLbl = content:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(nameLbl, 13, "")
    nameLbl:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, rowY)
    nameLbl:SetWidth(COL_NAME - 8)
    nameLbl:SetJustifyH("LEFT")
    nameLbl:Hide()

    local specLbl = content:CreateFontString(nil, "OVERLAY")
    GT.UI:SetFont(specLbl, 11, "")
    specLbl:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, rowY - 16)
    specLbl:SetWidth(COL_NAME - 8)
    specLbl:SetJustifyH("LEFT")
    specLbl:SetTextColor(0.55, 0.55, 0.55)
    specLbl:Hide()

    local dataLbls = {}
    for j = 1, #COLS do
        local lbl = content:CreateFontString(nil, "OVERLAY")
        GT.UI:SetFont(lbl, 12, "")
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", PAD + COL_NAME + (j - 1) * COL_DATA, rowY - 8)
        lbl:SetWidth(COL_DATA)
        lbl:SetJustifyH("CENTER")
        lbl:Hide()
        dataLbls[j] = lbl
    end

    rows[i] = { nameLbl = nameLbl, specLbl = specLbl, dataLbls = dataLbls }
end

-- ============================================================
-- Row fill (shared by ShowPreview and ShowRecap)
-- ============================================================

local function fillRows(players)
    for i = 1, MAX_ROWS do
        local row   = rows[i]
        local entry = players[i]

        if entry then
            local classColor = entry.classColor
            if classColor then
                row.nameLbl:SetTextColor(classColor.r, classColor.g, classColor.b)
            else
                row.nameLbl:SetTextColor(1, 1, 1)
            end
            row.nameLbl:SetText(entry.name)
            row.nameLbl:Show()

            row.specLbl:SetText(entry.specLine)
            row.specLbl:Show()

            row.dataLbls[1]:SetText(entry.dpsStr)
            row.dataLbls[2]:SetText(entry.hpsStr)
            row.dataLbls[3]:SetText(entry.intsStr)
            row.dataLbls[4]:SetText(entry.deathsStr)

            for _, lbl in ipairs(row.dataLbls) do
                lbl:SetTextColor(1, 1, 1)
                lbl:Show()
            end
        else
            row.nameLbl:Hide()
            row.specLbl:Hide()
            for _, lbl in ipairs(row.dataLbls) do lbl:Hide() end
        end
    end
end

-- ============================================================
-- Preview (fake data)
-- ============================================================

local PREVIEW_PLAYERS = {
    { name = "Grosstartine", class = "DEATHKNIGHT", role = "TANK",    spec = "Blood",        dps = 312400,  hps = 18200,  ints = 4, deaths = 0 },
    { name = "Luminara",     class = "PRIEST",      role = "HEALER",  spec = "Holy",         dps = 48000,   hps = 892000, ints = 1, deaths = 1 },
    { name = "Kaerath",      class = "MAGE",        role = "DAMAGER", spec = "Frost",        dps = 1240000, hps = 0,      ints = 6, deaths = 2 },
    { name = "Vyndrel",      class = "HUNTER",      role = "DAMAGER", spec = "Marksmanship", dps = 980000,  hps = 0,      ints = 3, deaths = 0 },
    { name = "Torshka",      class = "SHAMAN",      role = "DAMAGER", spec = "Enhancement",  dps = 1105000, hps = 22000,  ints = 8, deaths = 1 },
}

local function ShowPreview()
    subtitle:SetText(string.format("+%d  %s  —  %s", 12, "Windrunner Spire", fmtElapsed(1823, 1800)))

    local players = {}
    for _, e in ipairs(PREVIEW_PLAYERS) do
        local roleLabel = ROLE_LABEL[e.role] or "—"
        table.insert(players, {
            name       = e.name,
            classColor = RAID_CLASS_COLORS[e.class],
            specLine   = roleLabel .. "  •  " .. e.spec,
            dpsStr     = fmtNum(e.dps),
            hpsStr     = fmtNum(e.hps),
            intsStr    = tostring(e.ints),
            deathsStr  = tostring(e.deaths),
        })
    end

    fillRows(players)
    popup:Show()
end
Recap.ShowPreview = ShowPreview

-- ============================================================
-- Recap
-- ============================================================

local function ShowRecap(elapsed)
    local dungeonData = GT.Data.DUNGEONS[activeMapID]
    local dungeonName = dungeonData and dungeonData.name or "Unknown"
    subtitle:SetText(string.format("+%d  %s  —  %s", activeLevel, dungeonName, fmtElapsed(elapsed, activeTimeLimit)))

    -- Fetch meter data and build sortable list
    local raw = {}
    for guid, p in pairs(partyData) do
        table.insert(raw, {
            p      = p,
            dps    = getSessionAmount(guid, TYPE_DPS),
            hps    = getSessionAmount(guid, TYPE_HPS),
            ints   = getSessionAmount(guid, TYPE_INTERRUPTS),
            deaths = getSessionAmount(guid, TYPE_DEATHS),
        })
    end

    -- Sort: tank → healer → DPS (desc by output) → no role
    table.sort(raw, function(a, b)
        local ra = ROLE_ORDER[a.p.role] or 4
        local rb = ROLE_ORDER[b.p.role] or 4
        if ra ~= rb then return ra < rb end
        return (a.dps + a.hps) > (b.dps + b.hps)
    end)

    local players = {}
    for _, e in ipairs(raw) do
        local p         = e.p
        local roleLabel = ROLE_LABEL[p.role] or "—"
        table.insert(players, {
            name       = p.name,
            classColor = p.class and RAID_CLASS_COLORS[p.class:upper()],
            specLine   = p.spec and (roleLabel .. "  •  " .. p.spec) or roleLabel,
            dpsStr     = fmtNum(e.dps),
            hpsStr     = fmtNum(e.hps),
            intsStr    = tostring(math.floor(e.ints)),
            deathsStr  = tostring(math.floor(e.deaths)),
        })
    end

    fillRows(players)
    popup:Show()
end

-- ============================================================
-- Run lifecycle
-- ============================================================

local lifecycleFrame = CreateFrame("Frame")
lifecycleFrame:RegisterEvent("CHALLENGE_MODE_START")
lifecycleFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
lifecycleFrame:RegisterEvent("INSPECT_READY")

lifecycleFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHALLENGE_MODE_START" then
        activeMapID = C_ChallengeMode.GetActiveChallengeMapID() or 0
        activeLevel = C_ChallengeMode.GetActiveKeystoneInfo() or 0
        runStart    = GetTime()
        local _, _, tl = C_ChallengeMode.GetMapUIInfo(activeMapID)
        activeTimeLimit = tl or 0
        collectPartyData()

    elseif event == "INSPECT_READY" then
        local guid = ...
        local data = partyData[guid]
        if data then
            local specID = GetInspectSpecialization(data.unitToken)
            if specID and specID > 0 then
                local _, specName = GetSpecializationInfoByID(specID)
                data.spec = specName
            end
        end

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local elapsed = GetTime() - runStart
        if Recap.recapEnabled then
            -- Small delay so the damage meter session data settles, then show
            -- the recap. If screenshot is also enabled, wait one extra tick
            -- after the popup is visible before capturing.
            C_Timer.After(1, function()
                ShowRecap(elapsed)
                if Recap.screenshotEnabled and Screenshot then
                    C_Timer.After(0.1, Screenshot)
                end
            end)
        elseif Recap.screenshotEnabled then
            -- No recap popup; give the native completion UI a moment to appear.
            if Screenshot then C_Timer.After(1, Screenshot) end
        end
    end
end)
