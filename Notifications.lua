local _, A = ...
local previous, timer = {}, nil
local function notify(message)
    local db = A.db
    if db.notifyChat then print("|cff80ccffMobXPPlus:|r "..message) end
    if db.notifyScreen and UIErrorsFrame then UIErrorsFrame:AddMessage(message,1,0.8,0.2) end
    if db.notifySound and PlaySound and SOUNDKIT then
        local sound = SOUNDKIT.READY_CHECK or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
        if sound then PlaySound(sound,"Master") end
    end
end
function A.PreviewNotification()
    notify("XP buff notification test")
end
function A.UpdateNotifications(data, level)
    local db, now = A.db, GetTime()
    local nextDelay
    if timer then timer:Cancel(); timer=nil end
    for _, d in ipairs(data) do
        local old = previous[d.key]
        local enabled = db["monitor_"..d.key]
        local expires = d.active and d.expires and d.expires > 0 and d.expires or nil
        local warned = old and old.expires == expires and old.warned
        if d.key == "rest" then
            local low = d.active and d.pool <= db.restKills * A.Experience.Base(level,level,A.Compat.forever)
            if enabled and db.warnRest and low and old and not old.low then notify("Rested XP running low.") end
            if enabled and db.expireRest and old and old.active and not d.active then notify("Rested XP depleted.") end
            previous[d.key]={active=d.active,low=low}
        else
            if enabled and db.notifyExpired and old and old.active and not d.active and old.expires and now >= old.expires-1 then
                notify(d.name.." expired.")
            end
            if expires then
                local remaining=expires-now
                if enabled and db.notifySoon and remaining <= db.warnSeconds and not warned then
                    notify(d.name.." expires in "..math.ceil(remaining).." seconds.")
                    warned=true
                end
                local delay=remaining
                if enabled and db.notifySoon and not warned then delay=math.min(delay,remaining-db.warnSeconds) end
                nextDelay=math.min(nextDelay or delay,delay)
            end
            previous[d.key]={active=d.active,expires=expires,warned=warned}
        end
    end
    if nextDelay then timer=C_Timer.NewTimer(math.max(0.1,nextDelay+0.05),function() timer=nil; A.Refresh() end) end
end
