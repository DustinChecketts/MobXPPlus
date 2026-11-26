local _, A = ...
local P = {}
A.Progression = P

function P.Kills(remaining, base, percent, rested)
    if not remaining or base <= 0 then return nil end
    local normal = A.Experience.Modified(base, percent, 0)
    if normal <= 0 then return nil end
    local low, high = 0, math.ceil(remaining / normal)
    while low < high do
        local mid = math.floor((low + high) / 2)
        if mid * normal + math.min(rested, mid * base) >= remaining then
            high = mid
        else
            low = mid + 1
        end
    end
    return low
end

function P.Remaining()
    local current = A.Compat.Number(UnitXP("player"))
    local maximum = A.Compat.Number(UnitXPMax("player"))
    if current and maximum and maximum > 0 then
        return math.max(0, maximum - current)
    end
end
