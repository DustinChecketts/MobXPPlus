local name, A = ...
local C, E = A.Compat, A.Experience
A.defaults = { visible = true, locked = true, opacity = 0.8, buffs = true, rested = true, diagnostics = false,
    customRange = false, above = 2, below = 5, columnGap = 40, scale = 100,
    fontSize = 12, rowHeight = 14, padX = 6, padY = 6, titleGap = 4,
    showTitle = true, colored = true, highlight = false, targetHighlight = false, ascending = false,
    showBuffIcons=true, showInactiveBuffs=true, showBuffStacks=true, showBuffValues=false,
    showBuffTimers=true, flashBuffs=true, warnSeconds=30, iconSize=20, iconGap=4, foodSpellID=0, overall=100, idle=30, fadeIdle=false, combatOnly=false, hideRest=false, hideInstance=false, combineCap=true, buffGap=3,
    notifySoon=true, notifyExpired=false, notifyChat=false, notifyScreen=false, notifySound=false, monitor_rest=true, monitor_bag=true, monitor_food=true, warnRest=false, expireRest=false, restKills=5, endgame=false, showKills=false, killsGap=8, playerAlpha=35, targetAlpha=35 }
A.ranges = {above={0,5}, below={0,15}, columnGap={0,70}, scale={60,150},
    fontSize={8,20}, rowHeight={14,30}, padX={0,20}, padY={0,20}, titleGap={0,16}, warnSeconds={10,300}, iconSize={12,40}, iconGap={0,16}, overall={10,100}, idle={0,100}, buffGap={0,20}, restKills={1,20}, killsGap={0,40}, playerAlpha={10,80}, targetAlpha={10,80}}

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
        A.ApplyPosition()
        A.db.samples = type(A.db.samples) == "table" and A.db.samples or {}
        self:UnregisterEvent(event)
        for _, e in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "UNIT_AURA",
            "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "ZONE_CHANGED_NEW_AREA", "UPDATE_EXHAUSTION", "PLAYER_TARGET_CHANGED", "CHAT_MSG_COMBAT_XP_GAIN"}) do
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
    elseif msg:match("^food %d+$") then
        A.db.foodSpellID = tonumber(msg:match("%d+"))
        A.Refresh()
        print("MobXPPlus food aura ID:", A.db.foodSpellID)
    elseif msg == "clear" then A.db.samples = {}
    else A.OpenOptions() end
end
