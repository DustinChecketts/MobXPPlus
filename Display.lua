local _, A = ...
local C,E = A.Compat,A.Experience
local frame = CreateFrame("Frame", "MobXPPlusFrame", UIParent)
frame:SetSize(100, 40)
frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", 0, -5)
local rows = {}
frame:SetScript("OnDragStart", function(self)
    if not A.db.locked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local cx, cy = UIParent:GetCenter()
    local ratio = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
    A.db.x, A.db.y = x * ratio - cx, y * ratio - cy
    A.ApplyPosition()
end)

function A.ApplyPosition()
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if type(A.db.x) ~= "number" or type(A.db.y) ~= "number" then
        A.db.x, A.db.y = nil, nil
    end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", (A.db.x or 200) / ratio, (A.db.y or 0) / ratio)
end

function A.ResetPosition()
    A.db.x, A.db.y = nil, nil
    A.ApplyPosition()
end

function A.Refresh()
    if not A.db then return end
    local p = C.Number(UnitLevel("player"))
    if not p or p < 1 then return end
    local bonus, rested, auras, modifierData = C.Modifiers()
    A.snapshot = { level = p, bonus = bonus, rested = rested, auras = auras,
        target = C.Number(UnitLevel("target")) }
    bonus = A.db.buffs and bonus or 0
    rested = A.db.rested and rested or 0
    A.UpdateNotifications(modifierData,p)
    title:SetText("Mob XP")
    bg:SetColorTexture(0, 0, 0, A.db.opacity)
    frame:EnableMouse(not A.db.locked)
    local db = A.db
    local scale = db.scale / 100
    if frame:GetScale() ~= scale then
        frame:SetScale(scale)
        A.ApplyPosition()
    end
    local font, _, flags = GameFontHighlightSmall:GetFont()
    title:SetFont(font, db.fontSize, flags)
    title:ClearAllPoints()
    title:SetPoint("TOP", 0, -db.padY)
    title:SetShown(db.showTitle and p<C.maxLevel)
    local capped = p >= C.maxLevel
    local rowHeight = math.max(db.rowHeight, db.fontSize + 2)
    local top = db.padY + (db.showTitle and not capped and (title:GetStringHeight() + db.titleGap) or 0)
    local buffWidth, buffHeight = A.LayoutBuffs(frame, modifierData, top, capped)
    top = top + buffHeight
    local low = math.max(1, E.Grey(p) + 1, db.customRange and p - db.below or 1)
    local high = math.min(C.maxLevel, p + (db.customRange and db.above or 5))
    local combined = db.combineCap and high >= p+4
    if combined then high=p+4 end
    local plus = combined or high == C.maxLevel
    if capped then low, high = E.Grey(p)+1, E.Grey(p)+1 end
    local remaining = db.showKills and not capped and A.Progression.Remaining() or nil
    local first, last, step = high, low, -1
    if db.ascending then first, last, step = low, high, 1 end
    local count, levelWidth, xpWidth, killsWidth = 0, 0, 0, 0
    for m = first, last, step do
        count = count + 1
        local row = rows[count]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.border = {}
            for _, edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
                local line = row:CreateTexture(nil,"ARTWORK")
                line:SetPoint(edge)
                if edge=="TOP" or edge=="BOTTOM" then line:SetHeight(1); line:SetPoint("LEFT"); line:SetPoint("RIGHT")
                else line:SetWidth(1); line:SetPoint("TOP"); line:SetPoint("BOTTOM") end
                row.border[#row.border+1]=line
            end
            row.kills = row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            row.kills:SetPoint("RIGHT")
            row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.level:SetPoint("LEFT")
            row.xp = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.xp:SetPoint("RIGHT")
            rows[count] = row
        end
        local r, g, b = C.Color(p, m)
        local dr,dg,dbb = r,g,b
        if not db.colored then r, g, b = 1, 1, 1 end
        row.level:SetFont(font, db.fontSize, flags)
        row.xp:SetFont(font, db.fontSize, flags)
        row.level:SetText(capped and ("Non-trivial: "..m.."+") or (plus and m==high and (m.."+") or m))
        row.level:SetTextColor(r, g, b)
        local base = E.Base(p,m,C.forever)
        row.xp:SetText(capped and "" or E.Modified(base,bonus,rested))
        row.kills:SetFont(font,db.fontSize,flags)
        local kills = remaining and A.Progression.Kills(remaining,base,bonus,rested)
        row.kills:SetText(db.showKills and not capped and (kills or "-") or "")
        row.kills:SetShown(db.showKills and not capped)
        killsWidth = math.max(killsWidth,row.kills:GetStringWidth())
        row.xp:SetTextColor(r, g, b)
        local own = not capped and db.highlight and m==p
        local target = not capped and db.targetHighlight and (m==A.snapshot.target or (plus and m==high and A.snapshot.target and A.snapshot.target>high))
        if own then row.highlight:SetColorTexture(1,1,1,db.playerAlpha/100)
        elseif target then row.highlight:SetColorTexture(dr,dg,dbb,db.targetAlpha/100) end
        row.highlight:SetShown(own or target)
        for _,line in ipairs(row.border) do
            line:SetColorTexture(dr,dg,dbb,1)
            line:SetShown(not not target)
        end
        levelWidth = math.max(levelWidth, row.level:GetStringWidth())
        xpWidth = math.max(xpWidth, row.xp:GetStringWidth())
        row:Show()
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    local extra = db.showKills and not capped and (killsWidth+db.killsGap) or 0
    local width = math.max(buffWidth, levelWidth + xpWidth + (capped and 0 or db.columnGap) + extra)
    if db.showTitle and not capped then width = math.max(width, title:GetStringWidth()) end
    for i = 1, count do
        local row = rows[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", db.padX, -top - (i - 1) * rowHeight)
        row:SetSize(width, rowHeight)
        row.xp:ClearAllPoints()
        row.xp:SetPoint("RIGHT",-extra,0)
    end
    frame:SetSize(math.max(1, width + 2 * db.padX), math.max(1, top + count * rowHeight + db.padY))
    local combat = UnitAffectingCombat("player")
    local inside = IsInInstance()
    frame:SetAlpha(db.overall/100 * (db.fadeIdle and not combat and db.idle/100 or 1))
    frame:SetShown((not capped or db.endgame) and db.visible and (not db.combatOnly or combat) and (not db.hideRest or not IsResting()) and (not db.hideInstance or not inside))
end

