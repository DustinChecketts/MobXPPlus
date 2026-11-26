local A = {}
assert(loadfile("Experience.lua"))("MobXPPlus", A)
assert(loadfile("Progression.lua"))("MobXPPlus", A)
local P = A.Progression
assert(P.Kills(1000,100,0,0)==10)
assert(P.Kills(1000,100,0,1000)==5)
assert(P.Kills(1000,100,0,250)==8)
assert(P.Kills(1000,100,5,250)==8)
assert(P.Kills(0,100,0,0)==0)
assert(P.Kills(1000,0,0,0)==nil)
