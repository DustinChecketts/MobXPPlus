local _, A = ...
function A.CreateOptions()
    local root = CreateFrame("Frame")
    root.name = "MobXPPlus"
    local panel = root
    local checks, sliders = {}, {}
    local syncing = false
    local pages = {}
    local function page(name,index)
        local p=CreateFrame("Frame",nil,root)
        p:SetPoint("TOPLEFT",0,-38)
        p:SetPoint("BOTTOMRIGHT",0,50)
        p:Hide()
        pages[index]=p
        local tab=CreateFrame("Button",nil,root,"UIPanelButtonTemplate")
        tab:SetSize(100,24)
        tab:SetPoint("TOPLEFT",16+(index-1)*104,-8)
        tab:SetText(name)
        tab:SetScript("OnClick",function()
            for i,v in ipairs(pages) do v:SetShown(i==index) end
        end)
        panel=p
    end
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

    local function group(items,x,y)
        for i,item in ipairs(items) do checkbox(item[1],item[2],x,y-(i-1)*25) end
    end
    page("General",1)
    group({{"visible","Show XP table"},{"locked","Lock position"},{"combatOnly","Show only in combat"},{"hideRest","Hide in resting areas"},{"hideInstance","Hide in instances"},{"fadeIdle","Fade out of combat"}},16,-15)
    group({{"customRange","Use custom level range"},{"combineCap","Combine capped XP rows"},{"ascending","Lowest level first"},{"endgame","Show non-trivial level at max"},{"showKills","Show kills to level"}},260,-15)
    slider("above","Levels above",268,-160,0,5,1,"",1)
    slider("below","Levels below",268,-200,0,15,1,"",1)
    slider("idle","Idle opacity",24,-190,0,100,5,"%",1)
    page("Appearance",2)
    group({{"showTitle","Show title"},{"colored","Difficulty colors"},{"highlight","Highlight player level"},{"targetHighlight","Highlight target level"}},16,-15)
    slider("overall","Overall opacity",24,-145,10,100,5,"%",1)
    slider("opacity","Background opacity",24,-185,0,1,0.05,"%",100)
    slider("scale","Scale",24,-225,60,150,5,"%",1)
    slider("fontSize","Font size",24,-265,8,20,1," pt",1)
    slider("columnGap","Column spacing",268,-35,0,70,1," px",1)
    slider("rowHeight","Row height",268,-75,14,30,1," px",1)
    slider("padX","Horizontal padding",268,-115,0,20,1," px",1)
    slider("padY","Vertical padding",268,-155,0,20,1," px",1)
    slider("titleGap","Title spacing",268,-195,0,16,1," px",1)
    slider("killsGap","Kills column spacing",268,-235,0,40,1," px",1)
    slider("playerAlpha","Player highlight opacity",24,-305,10,80,5,"%",1)
    slider("targetAlpha","Target highlight opacity",268,-275,10,80,5,"%",1)
    page("XP Buffs",3)
    group({{"buffs","Include XP buffs"},{"rested","Include rested XP"},{"showBuffIcons","Show buff icons"},{"showInactiveBuffs","Show inactive icons"},{"showBuffStacks","Show stacks"},{"showBuffValues","Show bonus values"},{"showBuffTimers","Show countdowns"},{"flashBuffs","Flash expiring buffs"}},16,-15)
    slider("iconSize","Icon size",268,-35,12,40,1," px",1)
    slider("iconGap","Icon spacing",268,-75,0,16,1," px",1)
    slider("buffGap","Buff-to-table spacing",268,-115,0,20,1," px",1)
    slider("warnSeconds","Warning threshold",268,-155,10,300,5," s",1)
    page("Advanced",4)
    group({{"notifySoon","Warn before expiration"},{"notifyExpired","Notify on expiration"},{"notifyChat","Local chat message"},{"notifyScreen","Center-screen message"},{"notifySound","Play sound"},{"diagnostics","Record XP messages"}},16,-15)
    group({{"monitor_bag","Monitor Sleeping Bag"},{"monitor_food","Monitor XP food"},{"monitor_rest","Monitor rested XP"},{"warnRest","Warn when rested XP low"},{"expireRest","Notify when rested XP depleted"}},260,-15)
    slider("restKills","Rested kills remaining",268,-165,1,20,1,"",1)
    local preview=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    preview:SetSize(160,24)
    preview:SetPoint("TOPLEFT",16,-190)
    preview:SetText("Test notification")
    preview:SetScript("OnClick",A.PreviewNotification)
    panel=root
    pages[1]:Show()
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
        b:SetPoint("BOTTOMLEFT", x, 16)
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
    sync()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        A.OpenOptions = function() Settings.OpenToCategory(category:GetID()) end
    else
        InterfaceOptions_AddCategory(panel)
        A.OpenOptions = function() InterfaceOptionsFrame_OpenToCategory(panel) end
    end
end

