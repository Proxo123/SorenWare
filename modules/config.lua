local HttpService = game:GetService("HttpService")

local CONFIG_FILE = "GenHub_settings.json"

local Defaults = {
    AutoGen = false,
    AutoGenCooldown = 0,

    GenESP = false,
    FillColor = { R = 255, G = 0, B = 0 },
    FillTransparency = 0.5,
    OutlineColor = { R = 255, G = 255, B = 255 },
    OutlineTransparency = 0,

    KillerESP = false,
    KillerBox = true,
    KillerName = true,
    KillerDistance = true,
    KillerTracer = true,
    KillerColor = { R = 255, G = 0, B = 0 },
    KillerBoxThickness = 1,
    KillerTracerThickness = 1,
    KillerTextSize = 14,
    KillerMaxDistance = 5000,

    InfStamina = false,
    CustomDrain = false,
    DrainRate = 100,
    CustomMaxStamina = false,
    MaxStaminaValue = 100,

    Debug = false,
}

local Config = {}
Config.Defaults = Defaults

function Config.load()
    local ok, data = pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end
    end)
    if ok and data then
        for key, val in next, Defaults do
            if data[key] == nil then data[key] = val end
        end
        return data
    end
    local copy = {}
    for k, v in next, Defaults do
        if typeof(v) == "table" then
            copy[k] = {}
            for k2, v2 in next, v do copy[k][k2] = v2 end
        else
            copy[k] = v
        end
    end
    return copy
end

function Config.save(cfg)
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(cfg))
        end
    end)
end

function Config.reset(settings)
    for k, v in next, Defaults do
        if typeof(v) == "table" then
            settings[k] = {}
            for k2, v2 in next, v do settings[k][k2] = v2 end
        else
            settings[k] = v
        end
    end
    Config.save(settings)
end

return Config
