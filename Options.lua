local _, A = ...
function A.CreateOptions()
    local panel = CreateFrame("Frame")
    panel.name = "MobXPPlus"
    local checks, sliders = {}, {}
    local syncing = false
    local buffPanel = CreateFrame("Frame")
    buffPanel.name = "XP Buffs"
    local function heading(text, x, y)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", x, y)
        label:SetText(text)
    end
    heading("MobXPPlus - General", 16, -16)
    heading("Appearance", 260, -16)
    local function checkbox(key, label, x, y)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", x, y)
        local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("LEFT", check, "RIGHT", 2, 0)
        text:SetText(label)
        checks[key] = check
        check:SetScript("OnClick", function(self)
            A.db[key] = not not self:GetChecked()
            if sliders.above then
                sliders.above:SetEnabled(A.db.customRange)
                sliders.below:SetEnabled(A.db.customRange)
            end
            A.Refresh()
        end)
    end
    local left = {{"visible","Show XP table"},{"locked","Lock position"},
        {"buffs","Include XP buffs"},{"rested","Include rested XP"},
        {"diagnostics","Record XP messages"},{"customRange","Use custom level range"}}
    for i, item in ipairs(left) do checkbox(item[1], item[2], 16, -38-(i-1)*25) end
    local right = {{"showTitle","Show title"},{"colored","Difficulty colors"},
        {"highlight","Highlight player level"},{"targetHighlight","Highlight target level"},
        {"ascending","Lowest level first"}}
    for i, item in ipairs(right) do checkbox(item[1], item[2], 260, -38-(i-1)*25) end
    local function slider(key, label, x, y, low, high, step, suffix, factor)
        local control = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
        control:SetPoint("TOPLEFT", x, y)
        control:SetSize(195, 16)
        control:SetMinMaxValues(low, high)
        control:SetValueStep(step)
        control:SetObeyStepOnDrag(true)
        local caption = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        caption:SetPoint("BOTTOMLEFT", control, "TOPLEFT", 0, 2)
        local function update(value)
            caption:SetText(label .. ": " .. math.floor(value * factor + 0.5) .. suffix)
        end
        control:SetScript("OnValueChanged", function(_, value)
            update(value)
            if not syncing then
                A.db[key] = value
                A.Refresh()
            end
        end)
        sliders[key] = control
        control:SetValue(A.db[key])
        update(A.db[key])
    end
    slider("above","Levels above",24,-210,0,5,1,"",1)
    slider("below","Levels below",24,-250,0,15,1,"",1)
    slider("opacity","Background opacity",24,-290,0,1,0.05,"%",100)
    slider("scale","Scale",24,-330,60,150,5,"%",1)
    slider("fontSize","Font size",24,-370,9,20,1," pt",1)
    slider("columnGap","Column spacing",268,-190,0,70,1," px",1)
    slider("rowHeight","Row height",268,-230,14,30,1," px",1)
    slider("padX","Horizontal padding",268,-270,0,20,1," px",1)
    slider("padY","Vertical padding",268,-310,0,20,1," px",1)
    slider("titleGap","Title spacing",268,-350,0,16,1," px",1)
    local mainPanel = panel
    panel = buffPanel
    heading("XP buff indicators",16,-16)
    local buffChecks = {{"showBuffIcons","Show buff icons"},{"showInactiveBuffs","Show inactive icons"},{"showBuffStacks","Show stacks"},{"showBuffValues","Show bonus values"},{"showBuffTimers","Show countdowns"},{"flashBuffs","Flash expiring buffs"}}
    for i,item in ipairs(buffChecks) do checkbox(item[1],item[2],16,-38-(i-1)*25) end
    slider("iconSize","Icon size",268,-65,14,40,1," px",1)
    slider("iconGap","Icon spacing",268,-105,0,16,1," px",1)
    slider("warnSeconds","Warning threshold",268,-145,10,120,5," s",1)
    panel = mainPanel
    local function sync()
        syncing = true
        for key, check in pairs(checks) do check:SetChecked(A.db[key]) end
        for key, control in pairs(sliders) do control:SetValue(A.db[key]) end
        sliders.above:SetEnabled(A.db.customRange)
        sliders.below:SetEnabled(A.db.customRange)
        syncing = false
    end
    local function button(text, x, action)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(130, 24)
        b:SetPoint("TOPLEFT", x, -410)
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
    buffPanel:SetScript("OnShow", sync)
    panel:SetScript("OnShow", sync)
    sync()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        local sub = Settings.RegisterCanvasLayoutSubcategory(category,buffPanel,buffPanel.name)
        Settings.RegisterAddOnCategory(sub)
        A.OpenOptions = function() Settings.OpenToCategory(category:GetID()) end
    else
        InterfaceOptions_AddCategory(panel)
        buffPanel.parent = panel.name
        InterfaceOptions_AddCategory(buffPanel)
        A.OpenOptions = function() InterfaceOptionsFrame_OpenToCategory(panel) end
    end
end
