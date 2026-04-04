local HttpService = game:GetService("HttpService")

local CONFIG_FILE = "HypershotESP_settings.json"

local Defaults = {
    PlayerESP = false,
    TeamCheck = true,
    ShowSelf = false,
    HideDead = true,

    Box = true,
    Name = true,
    Distance = true,
    Tracer = true,
    HealthText = true,

    BoxThickness = 1,
    TracerThickness = 1,
    TextSize = 14,
    MaxDistance = 8000,

    EnemyColor = { R = 255, G = 64, B = 64 },
    TeammateColor = { R = 64, G = 200, B = 255 },

    Debug = false,

    FluentTheme = "Dark",
    FluentAcrylic = false,
    FluentTransparency = false,
    FluentWindowW = 520,
    FluentWindowH = 420,
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
        for k, v in next, Defaults do
            if data[k] == nil then data[k] = v end
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

return Config
