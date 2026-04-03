local HttpService = game:GetService("HttpService")

local CONFIG_FILE = "GenHub_settings.json"

local Defaults = {
    AutoGen = false,
    AutoGenCooldown = 0,
    -- Multi-puzzle generators: rapid FireServer bursts (see auto_gen.lua)
    AutoGenBurstCount = 8,
    AutoGenBurstDelay = 0.03,
    AutoGenWaveMode = false,

    GenESP = false,
    GenMaxDistance = 10000,
    InstantProximity = false,

    BatteryESP = false,
    FuseboxESP = false,
    FuseboxOnlyWithBattery = true,
    ObjectiveMaxDistance = 8000,

    SurvivorESP = false,
    SurvivorShowSelf = false,
    SurvivorBox = true,
    SurvivorName = true,
    SurvivorDistance = true,
    SurvivorTracer = true,
    SurvivorHealthText = true,
    SurvivorSidebar = true,
    SurvivorColor = { R = 0, G = 255, B = 0 },
    SurvivorBoxThickness = 1,
    SurvivorTracerThickness = 1,
    SurvivorTextSize = 14,
    SurvivorMaxDistance = 5000,

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

    -- Fluent UI (applied on load; some options need re-execute)
    FluentTheme = "Dark",
    FluentAcrylic = false,
    FluentTransparency = false,
    FluentMinimizeKey = "RightControl",
    FluentWindowW = 580,
    FluentWindowH = 460,
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

local PROFILE_PREFIX = "SorenWare_profile_"

function Config.listProfiles()
    local profiles = {}
    pcall(function()
        if listfiles then
            for _, file in next, listfiles("") do
                local name = file:match("SorenWare_profile_(.+)%.json$")
                if name then table.insert(profiles, name) end
            end
        end
    end)
    return profiles
end

function Config.saveProfile(name, settings)
    pcall(function()
        if writefile then
            writefile(PROFILE_PREFIX .. name .. ".json", HttpService:JSONEncode(settings))
        end
    end)
end

function Config.loadProfile(name)
    local ok, data = pcall(function()
        local path = PROFILE_PREFIX .. name .. ".json"
        if isfile and isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
    end)
    if ok and data then
        for key, val in next, Defaults do
            if data[key] == nil then data[key] = val end
        end
        return data
    end
    return nil
end

function Config.deleteProfile(name)
    pcall(function()
        if delfile then
            delfile(PROFILE_PREFIX .. name .. ".json")
        end
    end)
end

return Config
