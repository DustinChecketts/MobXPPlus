local _, A = ...
local C = {}
A.Compat = C
local _, _, _, build = GetBuildInfo()
C.forever = build >= 16000 and build < 17000
C.maxLevel = 60 -- Forever prototype target; revisit for other clients.

function C.Readable(v)
    return not issecretvalue or not issecretvalue(v)
end

function C.Number(v)
    if C.Readable(v) and type(v) == "number" then return v end
end


function C.Color(p, m)
    if m <= A.Experience.Grey(p) then return 0.5, 0.5, 0.5 end
    if m >= p + 5 then return 1, 0.1, 0.1 end
    if m >= p + 3 then return 1, 0.5, 0.25 end
    if m >= p - 2 then return 1, 1, 0 end
    return 0.25, 0.75, 0.25
end
