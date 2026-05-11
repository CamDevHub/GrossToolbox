local AddonName, GT = ...

local Core = GT.Core
local Modules = GT.Modules

function Core:DebugPrint(...)
    if not GT.Debug then return end
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    print("|cff00aaff[GT Debug]|r " .. table.concat(parts, "  "))
end

function Core:CreateModule(name)
    local f = CreateFrame("Frame", nil, GT.UI.contentArea)
    f:SetAllPoints(GT.UI.contentArea)
    f:Hide()
    f.Categories = {}
    f.categoryOrder = {}
    f.tabButtons = {}
    Modules[name] = f
    return f
end

function Core:AddCategory(moduleName, catName)
    local module = Modules[moduleName]
    if not module then return end

    local f = CreateFrame("Frame", nil, module)
    f:SetAllPoints(module)
    f:Hide()
    module.Categories[catName] = f
    table.insert(module.categoryOrder, catName)

    if #module.categoryOrder == 1 then
        module.defaultCategory = catName
    end

    -- Pre-create the tab button (hidden until this module is active)
    local btn = GT.UI:CreateTabButton(GT.UI.tabBar, catName)
    btn:Hide()

    local capturedModule = moduleName
    local capturedCat = catName
    btn:SetScript("OnClick", function()
        Core:SetCategory(capturedModule, capturedCat)
    end)

    module.tabButtons[catName] = btn
    return f
end

function Core:SetModule(moduleName)
    for name, module in pairs(Modules) do
        if name == moduleName then
            module:Show()
        else
            module:Hide()
        end
    end

    GT.UI:RebuildTabBar(moduleName)

    local module = Modules[moduleName]
    if module and module.defaultCategory then
        self:SetCategory(moduleName, module.defaultCategory)
    end
end

function Core:SetCategory(moduleName, catName)
    local module = Modules[moduleName]
    if not module then return end

    for name, frame in pairs(module.Categories) do
        if name == catName then
            frame:Show()
        else
            frame:Hide()
        end
    end

    for name, btn in pairs(module.tabButtons) do
        if name == catName then
            btn.isActive = true
            btn.activeLine:Show()
            btn.text:SetTextColor(1, 1, 1)
            btn.bg:Hide()
        else
            btn.isActive = false
            btn.activeLine:Hide()
            btn.text:SetTextColor(0.8, 0.8, 0.8)
            btn.bg:Hide()
        end
    end
end
