local GT = _G.GT
local addonName = GT.addonName or "GrossToolbox"
local Data = {}
GT.Modules.Data = Data

GT.headers = {
    player = "CHAR_DATA:",
    request = "REQ_DATA"
}
GT.COMM_PREFIX = "GTComm"

Data.CLASS_ID_TO_ENGLISH_NAME = {
    [1] = "Warrior",
    [2] = "Paladin",
    [3] = "Hunter",
    [4] = "Rogue",
    [5] = "Priest",
    [6] = "Death Knight",
    [7] = "Shaman",
    [8] = "Mage",
    [9] = "Warlock",
    [10] = "Monk",
    [11] = "Druid",
    [12] = "Demon Hunter",
    [13] = "Evoker",
    ["Unknown"] = "Unknown Class"
}

Data.SPEC_ID_TO_ENGLISH_NAME = {
    -- Death Knight
    [250] = "Blood",
    [251] = "Frost",
    [252] = "UH",
    -- Demon Hunter
    [577] = "Havoc",
    [581] = "Veng",
    -- Druid
    [102] = "Balance",
    [103] = "Feral",
    [104] = "Guardian",
    [105] = "Resto",
    -- Evoker
    [1467] = "Deva",
    [1468] = "Pres",
    [1473] = "Aug",
    -- Hunter
    [253] = "BM",
    [254] = "MM",
    [255] = "Surv",
    -- Mage
    [62] = "Arcane",
    [63] = "Fire",
    [64] = "Frost",
    -- Monk
    [268] = "Brew",
    [270] = "Mist",
    [269] = "WW",
    -- Paladin
    [65] = "Holy",
    [66] = "Prot",
    [70] = "Ret",
    -- Priest
    [256] = "Disc",
    [257] = "Holy",
    [258] = "Shadow",
    -- Rogue
    [259] = "Assa",
    [260] = "Outlaw",
    [261] = "Sub",
    -- Shaman
    [262] = "Elem",
    [263] = "EH",
    [264] = "Resto",
    -- Warlock
    [265] = "Affli",
    [266] = "Demono",
    [267] = "Destru",
    -- Warrior
    [71] = "Arms",
    [72] = "Fury",
    [73] = "Protect",
    -- Default / Unknown
    ["Unknown"] = "Unknown Spec"
}

Data.DUNGEON_ID_TO_ENGLISH_NAME = {
    [2651] = "DFC",
    [2661] = "Brew",
    [2773] = "Flood",
    [2649] = "PSF",
    [2648] = "Rook",
    [1594] = "ML",
    [2293] = "TOP",
    [2097] = "WS"
}
