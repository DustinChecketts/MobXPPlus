local _, A = ...
local E = {}
A.Experience = E

function E.Grey(p)
    if p <= 5 then return 0 end
    if p < 40 then return p - 5 - math.floor(p / 10) end
    return p - 1 - math.floor(p / 5)
end

function E.ZD(p)
    local bounds = {8, 10, 12, 16, 20, 30, 40, 45, 50, 55, 60}
    local values = {5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16}
    for i, bound in ipairs(bounds) do
        if p < bound then return values[i] end
    end
    return 17
end

-- Provisional nearest-even rule, using integer ratios to avoid half-tie drift.
function E.Round(n, d)
    local q = math.floor(n / d)
    local r = n - q * d
    if r * 2 > d or (r * 2 == d and q % 2 == 1) then return q + 1 end
    return q
end

function E.Base(p, m, forever)
    if m <= E.Grey(p) then return 0 end
    if m >= p then
        return E.Round((45 + 5 * p) * (100 + 5 * math.min(m - p, 4)), 100)
    end
    local zd = E.ZD(p)
    return E.Round((45 + 5 * (forever and m or p)) * math.max(0, zd + m - p), zd)
end

function E.Modified(base, percent, rested)
    return E.Round(base * (100 + percent), 100) + math.min(base, rested)
end
