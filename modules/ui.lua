local Helpers, Config, GenESP, KillerESP, Stamina, Logger = ...

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
        warn("[SorenWare] Failed to load Fluent UI (check HttpGet / network).")
        return nil
    end

    local Window = Fluent:CreateWindow({
        Title = "Generator Hub",
        SubTitle = "SorenWare",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl,
    })

    local GenTab = Window:AddTab({ Title = "Generators", Icon = "zap" })
    local KillerTab = Window:AddTab({ Title = "Killer ESP", Icon = "eye" })
    local PlayerTab = Window:AddTab({ Title = "Player", Icon = "user" })
    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    local function checkStaminaHook()
        if settings.InfStamina or settings.CustomDrain or settings.CustomMaxStamina then
            Stamina.enable(settings, state)
        else
            Stamina.disable()
        end
    end

    -- ========== GENERATORS ==========
    do
        local s = GenTab:AddSection("Auto Generator")
        s:AddToggle("GenAuto", {
            Title = "Enabled",
            Default = settings.AutoGen,
            Callback = function(v)
                state.AutoGen = v
                settings.AutoGen = v
                Config.save(settings)
            end,
        })
        s:AddSlider("GenCooldown", {
            Title = "Cooldown (x10 = seconds)",
            Description = "Display 0–50 → 0–5.0s delay between auto-completions",
            Default = settings.AutoGenCooldown * 10,
            Min = 0,
            Max = 50,
            Rounding = 0,
            Callback = function(v)
                settings.AutoGenCooldown = v / 10
                Config.save(settings)
            end,
        })
        GenTab:AddParagraph({
            Title = "How it works",
            Content = "Completes generators when the UI opens. Cooldown is seconds = value ÷ 10. 0 = instant.",
        })

        local s2 = GenTab:AddSection("Generator ESP")
        s2:AddToggle("GenEsp", {
            Title = "Enabled",
            Default = settings.GenESP,
            Callback = function(v)
                state.GenESP = v
                settings.GenESP = v
                Config.save(settings)
                if v then GenESP.enable(state, settings) else GenESP.disable(state) end
            end,
        })
    end

    local fillCp = GenTab:AddColorpicker("GenFillColor", {
        Title = "Fill Color",
        Default = Helpers.getFillColor(settings),
    })
    fillCp:OnChanged(function()
        local v = fillCp.Value
        settings.FillColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
        GenESP.refreshAll(state, settings)
    end)

    GenTab:AddSlider("GenFillTrans", {
        Title = "Fill Transparency %",
        Default = mathFloor(settings.FillTransparency * 100),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            settings.FillTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    local outlineCp = GenTab:AddColorpicker("GenOutlineColor", {
        Title = "Outline Color",
        Default = Helpers.getOutlineColor(settings),
    })
    outlineCp:OnChanged(function()
        local v = outlineCp.Value
        settings.OutlineColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
        GenESP.refreshAll(state, settings)
    end)

    GenTab:AddSlider("GenOutlineTrans", {
        Title = "Outline Transparency %",
        Default = mathFloor(settings.OutlineTransparency * 100),
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            settings.OutlineTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    -- ========== KILLER ESP ==========
    do
        local s = KillerTab:AddSection("Killer ESP")
        s:AddToggle("KillEsp", {
            Title = "Enabled",
            Default = settings.KillerESP,
            Callback = function(v)
                state.KillerESP = v
                settings.KillerESP = v
                Config.save(settings)
                if v then KillerESP.startRender(state, settings) else KillerESP.stopRender() end
            end,
        })
    end

    local killerCp = KillerTab:AddColorpicker("KillColor", {
        Title = "ESP Color",
        Default = Helpers.getKillerColor(settings),
    })
    killerCp:OnChanged(function()
        local v = killerCp.Value
        settings.KillerColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
    end)

    do
        local s = KillerTab:AddSection("Components")
        s:AddToggle("KillBox", {
            Title = "Box",
            Default = settings.KillerBox,
            Callback = function(v) settings.KillerBox = v; Config.save(settings) end,
        })
        s:AddSlider("KillBoxThick", {
            Title = "Box Thickness",
            Default = settings.KillerBoxThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.KillerBoxThickness = v; Config.save(settings) end,
        })
        s:AddToggle("KillName", {
            Title = "Name",
            Default = settings.KillerName,
            Callback = function(v) settings.KillerName = v; Config.save(settings) end,
        })
        s:AddToggle("KillDist", {
            Title = "Distance",
            Default = settings.KillerDistance,
            Callback = function(v) settings.KillerDistance = v; Config.save(settings) end,
        })
        s:AddToggle("KillTracer", {
            Title = "Tracer",
            Default = settings.KillerTracer,
            Callback = function(v) settings.KillerTracer = v; Config.save(settings) end,
        })
        s:AddSlider("KillTracerThick", {
            Title = "Tracer Thickness",
            Default = settings.KillerTracerThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.KillerTracerThickness = v; Config.save(settings) end,
        })
    end

    do
        local s = KillerTab:AddSection("Display")
        s:AddSlider("KillTextSz", {
            Title = "Text Size",
            Default = settings.KillerTextSize,
            Min = 10,
            Max = 24,
            Rounding = 0,
            Callback = function(v) settings.KillerTextSize = v; Config.save(settings) end,
        })
        s:AddSlider("KillMaxDist", {
            Title = "Max Distance (studs)",
            Default = settings.KillerMaxDistance,
            Min = 100,
            Max = 5000,
            Rounding = 0,
            Callback = function(v) settings.KillerMaxDistance = v; Config.save(settings) end,
        })
    end

    -- ========== PLAYER ==========
    do
        local s = PlayerTab:AddSection("Infinite Stamina")
        s:AddToggle("InfStam", {
            Title = "Enabled",
            Default = settings.InfStamina,
            Callback = function(v)
                settings.InfStamina = v
                Config.save(settings)
                checkStaminaHook()
            end,
        })
        PlayerTab:AddParagraph({
            Title = "How it works",
            Content = "Client-side stamina spoof. Sprint keeps going visually; server may still track real stamina.",
        })

        local s2 = PlayerTab:AddSection("Custom Drain Rate")
        s2:AddToggle("CustDrain", {
            Title = "Enabled",
            Default = settings.CustomDrain,
            Callback = function(v)
                settings.CustomDrain = v
                Config.save(settings)
                checkStaminaHook()
            end,
        })
        s2:AddSlider("DrainPct", {
            Title = "Drain Rate %",
            Default = settings.DrainRate,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Callback = function(v) settings.DrainRate = v; Config.save(settings) end,
        })
        PlayerTab:AddParagraph({
            Title = "Drain note",
            Content = "100% normal, 50% half, 0% none. Only when Infinite Stamina is OFF.",
        })

        local s3 = PlayerTab:AddSection("Custom Max Stamina")
        s3:AddToggle("CustMax", {
            Title = "Enabled",
            Default = settings.CustomMaxStamina,
            Callback = function(v)
                settings.CustomMaxStamina = v
                Config.save(settings)
                checkStaminaHook()
            end,
        })
        s3:AddSlider("MaxStamVal", {
            Title = "Max Stamina",
            Default = settings.MaxStaminaValue,
            Min = 50,
            Max = 500,
            Rounding = 0,
            Callback = function(v) settings.MaxStaminaValue = v; Config.save(settings) end,
        })
        PlayerTab:AddParagraph({
            Title = "Max note",
            Content = "Typical survivor max ~100, killer ~65–70.",
        })
    end

    -- ========== SETTINGS ==========
    do
        local s = SettingsTab:AddSection("General")
        s:AddToggle("DebugLog", {
            Title = "Debug Logging",
            Default = settings.Debug,
            Callback = function(v) settings.Debug = v; Config.save(settings) end,
        })
    end

    do
        local s = SettingsTab:AddSection("Data")
        s:AddButton({
            Title = "Reset All Settings",
            Description = "Restores defaults; re-execute to apply everything",
            Callback = function()
                Config.reset(settings)
                Fluent:Notify({
                    Title = "Generator Hub",
                    Content = "Settings reset. Re-execute to apply.",
                    Duration = 5,
                })
            end,
        })
    end

    do
        local s = SettingsTab:AddSection("Script")
        s:AddButton({
            Title = "Unload Hub",
            Callback = function()
                if getgenv and getgenv().GenHub then
                    getgenv().GenHub.Unload()
                end
            end,
        })
    end

    Window:SelectTab(1)

    Fluent:Notify({
        Title = "Generator Hub",
        Content = "Loaded (Fluent). Right Ctrl minimizes.",
        Duration = 5,
    })

    return Fluent
end

return UI
