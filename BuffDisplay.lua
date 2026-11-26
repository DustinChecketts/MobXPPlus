local _, A = ...
local bar, buttons, ticker
local function tick()
    local timed = false
    for _, b in ipairs(buttons) do
        if b:IsShown() then
            local d = b.data
            local remaining = d.active and d.expires and d.expires > 0 and math.max(0,d.expires-GetTime())
            if remaining then
                if remaining == 0 then A.Refresh(); return end
                timed = true
            end
            b.timer:SetText(remaining and (remaining >= 60 and math.ceil(remaining/60).."m" or math.ceil(remaining).."s") or "")
            local warning = remaining and remaining <= A.db.warnSeconds and A.db.flashBuffs
            b.icon:SetAlpha(warning and (0.65+0.35*math.cos(GetTime()*5)) or 1)
            b.timer:SetTextColor(warning and 1 or 1,warning and 0.55 or 1,warning and 0.1 or 1)
        end
    end
    if not timed and ticker then ticker:Cancel(); ticker=nil end
end

function A.LayoutBuffs(parent, data, top, suppressed)
    local db=A.db
    if not bar then
        bar=CreateFrame("Frame",nil,parent)
        buttons={}
        for i=1,3 do
            local b=CreateFrame("Frame",nil,bar)
            b.icon=b:CreateTexture(nil,"ARTWORK")
            b.icon:SetPoint("TOP")
            b.stack=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            b.stack:SetPoint("TOPRIGHT",b.icon,"TOPRIGHT")
            b.value=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            b.value:SetPoint("TOP",b.icon,"BOTTOM",0,-1)
            b.timer=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            b.timer:SetPoint("TOP",b.value,"BOTTOM",0,-1)
            b:EnableMouse(true)
            b:SetScript("OnEnter",function(self)
                local d=self.data
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:AddLine(d.name)
                GameTooltip:AddLine(d.included and "Included in XP estimates" or "Not included in XP estimates",1,1,1)
                if d.pool then GameTooltip:AddLine("Remaining rested XP: "..d.pool) end
                if d.active then GameTooltip:AddLine("Bonus: +"..d.percent.."%") end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave",function() GameTooltip:Hide() end)
            buttons[i]=b
        end
        bar:SetScript("OnHide",function() if ticker then ticker:Cancel(); ticker=nil end end)
        bar:SetScript("OnShow",function()
            for _, b in ipairs(buttons) do
                if b:IsShown() and b.data and b.data.active and b.data.expires and b.data.expires>GetTime() then
                    if not ticker then ticker=C_Timer.NewTicker(0.25,tick) end
                    break
                end
            end
        end)
    end
    local count=0
    local cell=db.iconSize
    local hasTimer=false
    for _,d in ipairs(data) do
        if d.active and d.expires and d.expires>GetTime() then hasTimer=true end
    end
    local height=db.iconSize+(db.showBuffValues and 12 or 0)+(db.showBuffTimers and hasTimer and 12 or 0)
    for i,b in ipairs(buttons) do
        local d=data[i]
        d.included=d.active and (i==1 and db.rested or i~=1 and db.buffs)
        b.data=d
        local show=not suppressed and db.showBuffIcons and db.visible and (d.active or db.showInactiveBuffs)
        b:SetShown(show)
        if show then
            b:SetSize(cell,height)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT",count*(cell+db.iconGap),0)
            b.icon:SetSize(db.iconSize,db.iconSize)
            b.icon:SetTexture(d.icon)
            b.icon:SetDesaturated(not d.included)
            b.stack:SetText(db.showBuffStacks and d.active and d.stacks or "")
            b.value:SetText(d.active and (i==1 and "2x" or d.percent.."%") or "-")
            b.value:SetShown(db.showBuffValues)
            b.timer:ClearAllPoints()
            b.timer:SetPoint("TOP",db.showBuffValues and b.value or b.icon,"BOTTOM",0,-1)
            b.timer:SetShown(db.showBuffTimers and hasTimer)
            count=count+1
        end
    end
    local width=math.max(0,count*cell+(count-1)*db.iconGap)
    bar:ClearAllPoints()
    bar:SetPoint("TOP",parent,"TOP",0,-top)
    bar:SetSize(math.max(1,width),math.max(1,height))
    bar:SetShown(count>0)
    if count>0 then
        tick()
        if not ticker and bar:IsVisible() then
            for _,b in ipairs(buttons) do
                if b:IsShown() and b.data.active and b.data.expires and b.data.expires>GetTime() then
                    ticker=C_Timer.NewTicker(0.25,tick)
                    break
                end
            end
        end
    end
    return width,count>0 and height+db.buffGap or 0
end
