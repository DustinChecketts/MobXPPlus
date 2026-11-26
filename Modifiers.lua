local _, A = ...
local C = A.Compat
-- Verified Forever Well Fed: +5% kill XP, +22 spell damage.
local foodSpells = { [1249520] = true }
function C.Modifiers()
    local rested = C.Number(GetXPExhaustion()) or 0
    local bonus, auras = 0, {}
    local data = {
        {name="Rested XP", icon="Interface\\Icons\\Spell_Nature_Sleep", active=rested>0, pool=rested, percent=100, key="rest"},
        {name="Sleeping Bag", icon="Interface\\Icons\\INV_Misc_Bag_10", percent=0, key="bag"},
        {name="XP Food", icon=133943, percent=5, key="food"},
    }
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i=1,40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex,"player",i,"HELPFUL")
            if not ok or not C.Readable(aura) or not aura then break end
            local id = C.Number(aura.spellId)
            if id then
                auras[#auras+1] = id
                local entry = id==429959 and data[2] or ((foodSpells[id] or (A.db and A.db.foodSpellID==id)) and data[3])
                if entry then
                    local stacks = math.max(1,C.Number(aura.applications) or 1)
                    entry.active = true
                    entry.stacks = stacks
                    entry.icon = C.Number(aura.icon) or entry.icon
                    entry.expires = C.Number(aura.expirationTime)
                    if entry.key=="bag" then entry.percent=math.min(3,stacks) else entry.name="XP Food" end
                end
            end
        end
    end
    for i=2,3 do
        local d=data[i]
        if d.active and (not d.expires or d.expires==0 or d.expires>GetTime()) then
            bonus=bonus+d.percent
        else d.active=false end
    end
    return bonus, rested, auras, data
end
