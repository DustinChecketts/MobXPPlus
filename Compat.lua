local _, A = ...
local C = {}
A.Compat = C
local _, _, _, build = GetBuildInfo()
C.forever = build >= 16000 and build < 17000

function C.Readable(v)
    return not issecretvalue or not issecretvalue(v)
end

function C.Number(v)
    if C.Readable(v) and type(v) == "number" then return v end
end

function C.Modifiers()
    local rested = C.Number(GetXPExhaustion()) or 0
    local bonus, auras = 0, {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not C.Readable(aura) or not aura then break end
            local id, stacks = C.Number(aura.spellId), C.Number(aura.applications)
            if id then
                auras[#auras + 1] = id
                if id == 429959 then bonus = math.max(1, math.min(3, stacks or 1)) end
            end
        end
    end
    return bonus, rested, auras
end

function C.Color(p, m)
    if m <= A.Experience.Grey(p) then return 0.5, 0.5, 0.5 end
    if m >= p + 5 then return 1, 0.1, 0.1 end
    if m >= p + 3 then return 1, 0.5, 0.25 end
    if m >= p - 2 then return 1, 1, 0 end
    return 0.25, 0.75, 0.25
end
