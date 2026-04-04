local Helpers = {}

Helpers.V2New = Vector2.new
Helpers.V3New = Vector3.new
Helpers.mathFloor = math.floor

function Helpers.getEnemyColor(settings)
    local c = settings.EnemyColor or { R = 255, G = 64, B = 64 }
    return Color3.fromRGB(c.R, c.G, c.B)
end

function Helpers.getTeammateColor(settings)
    local c = settings.TeammateColor or { R = 64, G = 200, B = 255 }
    return Color3.fromRGB(c.R, c.G, c.B)
end

function Helpers.sameTeam(pA, pB)
    if not pA or not pB then return false end
    local ta, tb = pA.Team, pB.Team
    if not ta or not tb then return false end
    return ta == tb
end

return Helpers
