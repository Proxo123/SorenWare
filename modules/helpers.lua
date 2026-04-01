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

return Helpers
