local Helpers = {}

Helpers.V2New = Vector2.new
Helpers.V3New = Vector3.new
Helpers.mathFloor = math.floor
Helpers.mathClamp = math.clamp

function Helpers.getFillColor(settings)
    return Color3.fromRGB(settings.FillColor.R, settings.FillColor.G, settings.FillColor.B)
end

function Helpers.getOutlineColor(settings)
    return Color3.fromRGB(settings.OutlineColor.R, settings.OutlineColor.G, settings.OutlineColor.B)
end

function Helpers.getKillerColor(settings)
    return Color3.fromRGB(settings.KillerColor.R, settings.KillerColor.G, settings.KillerColor.B)
end

function Helpers.getSurvivorColor(settings)
    local c = settings.SurvivorColor or { R = 0, G = 255, B = 0 }
    return Color3.fromRGB(c.R, c.G, c.B)
end

return Helpers
