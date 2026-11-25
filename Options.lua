local _, A = ...
function A.CreateOptions()
    local panel = CreateFrame("Frame")
    panel.name = "MobXPPlus"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MobXPPlus")
    local checks = {}
    local opts = {{"visible", "Show XP table"}, {"locked", "Lock position"},
        {"buffs", "Include recognized XP buffs"}, {"rested", "Include rested XP"},
        {"diagnostics", "Record last 10 XP messages"}}
    for i, option in ipairs(opts) do
        local key, label = option[1], option[2]
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 16, -42 - (i - 1) * 30)
        local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", check, "RIGHT", 4, 0)
        text:SetText(label)
        check:SetScript("OnClick", function(self)
            A.db[key] = not not self:GetChecked()
            A.Refresh()
        end)
        checks[key] = check
    end
    local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 24, -220)
    slider:SetSize(200, 16)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 3)
    slider:SetScript("OnValueChanged", function(_, value)
        A.db.opacity = value
        label:SetText("Background opacity: " .. math.floor(value * 100 + 0.5) .. "%")
        A.Refresh()
    end)
    local function sync()
        for key, check in pairs(checks) do check:SetChecked(A.db[key]) end
        slider:SetValue(A.db.opacity)
        label:SetText("Background opacity: " .. math.floor(A.db.opacity * 100 + 0.5) .. "%")
    end
    local function button(text, x, action)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(130, 24)
        b:SetPoint("TOPLEFT", x, -265)
        b:SetText(text)
        b:SetScript("OnClick", action)
    end
    button("Reset Position", 16, function() A.ResetPosition() end)
    button("Defaults", 154, function()
        for k, v in pairs(A.defaults) do A.db[k] = v end
        A.ResetPosition()
        sync()
        A.Refresh()
    end)
    panel:SetScript("OnShow", sync)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        A.OpenOptions = function() Settings.OpenToCategory(category:GetID()) end
    else
        InterfaceOptions_AddCategory(panel)
        A.OpenOptions = function() InterfaceOptionsFrame_OpenToCategory(panel) end
    end
end
