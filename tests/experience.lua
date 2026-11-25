local A = {}
assert(loadfile("Experience.lua"))("MobXPPlus", A)
local E = A.Experience
for _, r in ipairs({{53,57,372},{53,56,356},{54,58,378},{54,57,362},{54,55,331},{54,54,315},{54,53,289},{53,42,0}}) do
    assert(E.Base(r[1], r[2], true) == r[3])
end
assert(E.Modified(310, 3, 0) == 319)
assert(E.Modified(310, 8, 0) == 335)
assert(E.Modified(356, 3, 0) == 367)
assert(E.Modified(310, 0, 100) == 410)
-- Known unresolved observation: level 53 vs 54 at 3% awarded 336, model 335.
print("XP regression checks passed")
