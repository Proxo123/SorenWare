local Helpers, Config, PlayerESP, Logger = ...

local mathFloor = Helpers.mathFloor

local UI = {}

local FLUENT_SOURCES = {
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
}

local function httpGetBody(url)
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok and res and res.StatusCode == 200 and type(res.Body) == "string" and #res.Body > 0 then
            return res.Body
        end
    end
    if request then
        local ok, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok and res and res.StatusCode == 200 and type(res.Body) == "string" and #res.Body > 0 then
            return res.Body
        end
    end
    return game:HttpGet(url)
end

local function loadFluent()
    for _, url in ipairs(FLUENT_SOURCES) do
        local ok, lib = pcall(function()
            return loadstring(httpGetBody(url))()
        end)
        if ok and lib and type(lib.CreateWindow) == "function" then
            return lib
        end
    end
    return nil
end

function UI.build(state, settings)
    local Fluent = loadFluent()
    if not Fluent then
        warn("[HypershotESP] Fluent failed to load.")
        return nil
    end

    local winW = math.clamp(math.floor(settings.FluentWindowW or 520), 380, 900)
    local winH = math.clamp(math.floor(settings.FluentWindowH or 420), 280, 800)

    local Window = Fluent:CreateWindow({
        Title = "Hypershot",
        SubTitle = "Player ESP",
        TabWidth = 140,
        Size = UDim2.fromOffset(winW, winH),
        Acrylic = true,
        Theme = settings.FluentTheme or "Dark",
        MinimizeKey = Enum.KeyCode.RightControl,
    })

    task.defer(function()
        pcall(function()
            Fluent:ToggleAcrylic(settings.FluentAcrylic == true)
            Fluent:ToggleTransparency(settings.FluentTransparency == true)
        end)
    end)

    local EspTab = Window:AddTab({ Title = "Player ESP", Icon = "eye" })
    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    do
        local s = EspTab:AddSection("ESP")
        s:AddToggle("EspOn", {
            Title = "Enabled",
            Default = settings.PlayerESP == true,
            Callback = function(v)
                state.PlayerESP = v
                settings.PlayerESP = v
                Config.save(settings)
                if v then PlayerESP.startRender(state, settings) else PlayerESP.stopRender() end
            end,
        })
        s:AddToggle("TeamChk", {
            Title = "Team check",
            Description = "Hide Roblox teammates (same Team); enemies use enemy color",
            Default = settings.TeamCheck ~= false,
            Callback = function(v)
                settings.TeamCheck = v
                Config.save(settings)
            end,
        })
        s:AddToggle("ShowSelf", {
            Title = "Show local player",
            Default = settings.ShowSelf == true,
            Callback = function(v)
                settings.ShowSelf = v
                Config.save(settings)
            end,
        })
        s:AddToggle("HideDead", {
            Title = "Hide dead",
            Default = settings.HideDead ~= false,
            Callback = function(v)
                settings.HideDead = v
                Config.save(settings)
            end,
        })
    end

    do
        local s = EspTab:AddSection("Components")
        s:AddToggle("Box", {
            Title = "Box",
            Default = settings.Box ~= false,
            Callback = function(v) settings.Box = v; Config.save(settings) end,
        })
        s:AddSlider("BoxThick", {
            Title = "Box thickness",
            Default = settings.BoxThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.BoxThickness = v; Config.save(settings) end,
        })
        s:AddToggle("Name", {
            Title = "Name",
            Default = settings.Name ~= false,
            Callback = function(v) settings.Name = v; Config.save(settings) end,
        })
        s:AddToggle("Health", {
            Title = "Health text",
            Default = settings.HealthText ~= false,
            Callback = function(v) settings.HealthText = v; Config.save(settings) end,
        })
        s:AddToggle("Dist", {
            Title = "Distance",
            Default = settings.Distance ~= false,
            Callback = function(v) settings.Distance = v; Config.save(settings) end,
        })
        s:AddToggle("Tracer", {
            Title = "Tracer",
            Default = settings.Tracer ~= false,
            Callback = function(v) settings.Tracer = v; Config.save(settings) end,
        })
        s:AddSlider("TracerThick", {
            Title = "Tracer thickness",
            Default = settings.TracerThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.TracerThickness = v; Config.save(settings) end,
        })
    end

    do
        local s = EspTab:AddSection("Display")
        s:AddSlider("TextSz", {
            Title = "Text size",
            Default = settings.TextSize,
            Min = 10,
            Max = 22,
            Rounding = 0,
            Callback = function(v) settings.TextSize = v; Config.save(settings) end,
        })
        s:AddSlider("MaxDist", {
            Title = "Max distance (studs)",
            Default = math.clamp(settings.MaxDistance, 100, 20000),
            Min = 100,
            Max = 20000,
            Rounding = 0,
            Callback = function(v) settings.MaxDistance = v; Config.save(settings) end,
        })
    end

    local enemyCp = EspTab:AddColorpicker("EnemyCol", {
        Title = "Enemy color",
        Default = Helpers.getEnemyColor(settings),
    })
    enemyCp:OnChanged(function()
        local v = enemyCp.Value
        settings.EnemyColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
    end)

    local mateCp = EspTab:AddColorpicker("TeamCol", {
        Title = "Teammate color",
        Description = "Only when team check is OFF",
        Default = Helpers.getTeammateColor(settings),
    })
    mateCp:OnChanged(function()
        local v = mateCp.Value
        settings.TeammateColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
    end)

    do
        local s = SettingsTab:AddSection("Fluent")
        local themes = Fluent.Themes or { "Dark" }
        local themeIdx = 1
        for i, name in ipairs(themes) do
            if name == settings.FluentTheme then themeIdx = i break end
        end
        s:AddDropdown("Theme", {
            Title = "Theme",
            Values = themes,
            Default = themeIdx,
            Callback = function(Value)
                settings.FluentTheme = Value
                Config.save(settings)
                pcall(function() Fluent:SetTheme(Value) end)
            end,
        })
        if Fluent.UseAcrylic then
            s:AddToggle("Acrylic", {
                Title = "Acrylic",
                Default = settings.FluentAcrylic == true,
                Callback = function(v)
                    settings.FluentAcrylic = v
                    Config.save(settings)
                    pcall(function() Fluent:ToggleAcrylic(v) end)
                end,
            })
        end
        s:AddToggle("Trans", {
            Title = "Transparent panels",
            Default = settings.FluentTransparency == true,
            Callback = function(v)
                settings.FluentTransparency = v
                Config.save(settings)
                pcall(function() Fluent:ToggleTransparency(v) end)
            end,
        })
    end

    SettingsTab:AddToggle("Debug", {
        Title = "Debug prints",
        Default = settings.Debug == true,
        Callback = function(v) settings.Debug = v; Config.save(settings) end,
    })

    SettingsTab:AddButton({
        Title = "Unload",
        Callback = function()
            if getgenv and getgenv().HypershotESP then getgenv().HypershotESP.Unload() end
        end,
    })

    Window:SelectTab(1)
    Fluent:Notify({ Title = "Hypershot ESP", Content = "Right Ctrl minimizes.", Duration = 4 })

    return Window
end

return UI
