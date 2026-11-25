local name, A = ...
local C, E = A.Compat, A.Experience
A.defaults = { visible = true, locked = true, opacity = 0.8, buffs = true, rested = true, diagnostics = false,
    customRange = false, above = 2, below = 5, columnGap = 40, scale = 100,
    fontSize = 12, rowHeight = 14, padX = 6, padY = 6, titleGap = 4,
    showTitle = true, colored = true, highlight = false, targetHighlight = false, ascending = false }
A.ranges = {above={0,5}, below={0,15}, columnGap={0,70}, scale={60,150},
    fontSize={9,20}, rowHeight={14,30}, padX={0,20}, padY={0,20}, titleGap={0,16}}
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
    local bonus, rested, auras = C.Modifiers()
    A.snapshot = { level = p, bonus = bonus, rested = rested, auras = auras,
        target = C.Number(UnitLevel("target")) }
    bonus = A.db.buffs and bonus or 0
    rested = A.db.rested and rested or 0
    local label = "Mob XP"
    if bonus > 0 then label = label .. " +" .. bonus .. "%" end
    if rested > 0 then label = label .. " R" end
    title:SetText(label)
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
    title:SetShown(db.showTitle)
    local rowHeight = math.max(db.rowHeight, db.fontSize + 2)
    local top = db.padY + (db.showTitle and (title:GetStringHeight() + db.titleGap) or 0)
    local low = math.max(1, E.Grey(p) + 1, db.customRange and p - db.below or 1)
    local high = p + (db.customRange and db.above or 5)
    local first, last, step = high, low, -1
    if db.ascending then first, last, step = low, high, 1 end
    local count, levelWidth, xpWidth = 0, 0, 0
    for m = first, last, step do
        count = count + 1
        local row = rows[count]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(1, 1, 1, 0.12)
            row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.level:SetPoint("LEFT")
            row.xp = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.xp:SetPoint("RIGHT")
            rows[count] = row
        end
        local r, g, b = C.Color(p, m)
        if not db.colored then r, g, b = 1, 1, 1 end
        row.level:SetFont(font, db.fontSize, flags)
        row.xp:SetFont(font, db.fontSize, flags)
        row.level:SetText(m)
        row.level:SetTextColor(r, g, b)
        row.xp:SetText(E.Modified(E.Base(p, m, C.forever), bonus, rested))
        row.xp:SetTextColor(r, g, b)
        row.highlight:SetShown((db.highlight and m == p) or (db.targetHighlight and m == A.snapshot.target))
        levelWidth = math.max(levelWidth, row.level:GetStringWidth())
        xpWidth = math.max(xpWidth, row.xp:GetStringWidth())
        row:Show()
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    local width = levelWidth + xpWidth + db.columnGap
    if db.showTitle then width = math.max(width, title:GetStringWidth()) end
    for i = 1, count do
        local row = rows[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", db.padX, -top - (i - 1) * rowHeight)
        row:SetSize(width, rowHeight)
    end
    frame:SetSize(math.max(1, width + 2 * db.padX), math.max(1, top + count * rowHeight + db.padY))
    frame:SetShown(A.db.visible)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= name then return end
        MobXPPlusDB = type(MobXPPlusDB) == "table" and MobXPPlusDB or {}
        A.db = MobXPPlusDB
        for k, v in pairs(A.defaults) do
            if type(A.db[k]) ~= type(v) then A.db[k] = v end
        end
        A.db.opacity = math.max(0, math.min(1, A.db.opacity))
        for key, range in pairs(A.ranges) do
            A.db[key] = math.max(range[1], math.min(range[2], math.floor(A.db[key])))
        end
        frame:SetScale(A.db.scale / 100)
        A.ApplyPosition()
        A.db.samples = type(A.db.samples) == "table" and A.db.samples or {}
        self:UnregisterEvent(event)
        for _, e in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "UNIT_AURA",
            "UPDATE_EXHAUSTION", "PLAYER_TARGET_CHANGED", "CHAT_MSG_COMBAT_XP_GAIN"}) do
            self:RegisterEvent(e)
        end
        A.CreateOptions()
    elseif event == "UNIT_AURA" and arg ~= "player" then return
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        if A.db.diagnostics and C.Readable(arg) and type(arg) == "string" then
            local s = A.snapshot or {}
            local sample = { message = arg, player = s.level, target = s.target,
                bonus = s.bonus, rested = s.rested, auras = s.auras }
            if s.level and s.target and s.target > 0 then
                sample.estimate = E.Modified(E.Base(s.level, s.target, C.forever), s.bonus, s.rested)
            end
            table.insert(A.db.samples, sample)
            while #A.db.samples > 10 do table.remove(A.db.samples, 1) end
        end
    end
    A.Refresh()
end)

SLASH_MOBXPPLUS1 = "/mxp"
SLASH_MOBXPPLUS2 = "/mobxp"
SlashCmdList.MOBXPPLUS = function(msg)
    if not A.db then return end
    if msg == "dump" then
        for _, s in ipairs(A.db.samples) do
            print("MobXPPlus", s.player, s.target, s.bonus, s.rested, s.estimate, s.message,
                table.concat(s.auras or {}, ","))
        end
    elseif msg == "auras" then
        local b, r, ids = C.Modifiers()
        print("MobXPPlus bonus:", b, "rested:", r, "auras:", table.concat(ids, ","))
    elseif msg == "clear" then A.db.samples = {}
    else A.OpenOptions() end
end
