local name, A = ...
local C, E = A.Compat, A.Experience
A.defaults = { visible = true, locked = true, opacity = 0.8, buffs = true, rested = true, diagnostics = false }
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
    A.db.x, A.db.y = x - cx, y - cy
end)

function A.ResetPosition()
    A.db.x, A.db.y = nil, nil
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
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
    local count = 0
    for m = p + 4, math.max(1, E.Grey(p) + 1), -1 do
        count = count + 1
        local row = rows[count]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row:SetSize(88, 14)
            row:SetPoint("TOPLEFT", 6, -19 - (count - 1) * 14)
            row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.level:SetPoint("LEFT")
            row.xp = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.xp:SetPoint("RIGHT")
            rows[count] = row
        end
        local r, g, b = C.Color(p, m)
        row.level:SetText(m)
        row.level:SetTextColor(r, g, b)
        row.xp:SetText(E.Modified(E.Base(p, m, C.forever), bonus, rested))
        row.xp:SetTextColor(r, g, b)
        row:Show()
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    frame:SetHeight(24 + count * 14)
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
        if type(A.db.x) == "number" and type(A.db.y) == "number" then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", A.db.x, A.db.y)
        end
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
