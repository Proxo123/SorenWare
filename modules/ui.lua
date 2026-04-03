local Helpers, Config, GenESP, KillerESP, Stamina, Logger, SurvivorESP, ProxHold = ...

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
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local Fluent = loadFluent()
    if not Fluent then
        warn("[SorenWare] Failed to load Fluent UI (check HttpGet / network).")
        return nil
    end

    local winW = math.clamp(math.floor(settings.FluentWindowW or 580), 400, 1000)
    local winH = math.clamp(math.floor(settings.FluentWindowH or 460), 300, 900)

    local Window = Fluent:CreateWindow({
        Title = "Generator Hub",
        SubTitle = "SorenWare",
        TabWidth = 160,
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

    local GenTab = Window:AddTab({ Title = "Generators", Icon = "zap" })
    local KillerTab = Window:AddTab({ Title = "Killer ESP", Icon = "eye" })
    local SurvivorTab = Window:AddTab({ Title = "Survivor ESP", Icon = "users" })
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
            Description = "Delay before the next generator UI can auto-fire (0–5s)",
            Default = settings.AutoGenCooldown * 10,
            Min = 0,
            Max = 50,
            Rounding = 0,
            Callback = function(v)
                settings.AutoGenCooldown = v / 10
                Config.save(settings)
            end,
        })
        s:AddSlider("GenBurstN", {
            Title = "Puzzle passes (burst count)",
            Description = "How many Event fires per generator UI (multi-stage puzzles)",
            Default = settings.AutoGenBurstCount,
            Min = 1,
            Max = 24,
            Rounding = 0,
            Callback = function(v)
                settings.AutoGenBurstCount = v
                Config.save(settings)
            end,
        })
        s:AddSlider("GenBurstDelay", {
            Title = "Burst delay (ms)",
            Description = "Wait between each FireServer in one generator",
            Default = math.floor((settings.AutoGenBurstDelay or 0.03) * 1000 + 0.5),
            Min = 10,
            Max = 350,
            Rounding = 0,
            Callback = function(v)
                settings.AutoGenBurstDelay = v / 1000
                Config.save(settings)
            end,
        })
        s:AddToggle("GenWave", {
            Title = "Wave mode",
            Description = "Fire Wires → Switches → Lever → full each round (try if burst-only fails)",
            Default = settings.AutoGenWaveMode == true,
            Callback = function(v)
                settings.AutoGenWaveMode = v
                Config.save(settings)
            end,
        })
        GenTab:AddParagraph({
            Title = "How auto-gen works",
            Content = "Each generator has several puzzle stages. The script fires the completion Event multiple times quickly. Raise burst count or lower ms delay if it still feels slow. Wave mode alternates single-part payloads. Adjust Interface tab for Fluent look.",
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
        s2:AddSlider("GenMaxDist", {
            Title = "Max highlight distance (studs)",
            Description = "Incomplete generators stay highlighted within this range",
            Default = math.clamp(settings.GenMaxDistance or 10000, 100, 20000),
            Min = 100,
            Max = 20000,
            Rounding = 0,
            Callback = function(v)
                settings.GenMaxDistance = v
                Config.save(settings)
                GenESP.refreshAll(state, settings)
                GenESP.reconcileHighlights(state, settings)
            end,
        })
        s2:AddToggle("InstantProx", {
            Title = "Instant proximity hold",
            Description = "Sets HoldDuration to 0 on prompts under the map (client-side; game may still validate)",
            Default = settings.InstantProximity == true,
            Callback = function(v)
                settings.InstantProximity = v
                Config.save(settings)
                if v then ProxHold.start(state, settings) else ProxHold.stop() end
            end,
        })
        local sObj = GenTab:AddSection("Objectives")
        sObj:AddToggle("BatEsp", {
            Title = "Battery ESP",
            Default = settings.BatteryESP == true,
            Callback = function(v)
                settings.BatteryESP = v
                Config.save(settings)
            end,
        })
        sObj:AddToggle("FuseEsp", {
            Title = "Fusebox ESP",
            Description = "When 'Require battery equipped' is on, fusebox only highlights if you hold a battery tool",
            Default = settings.FuseboxESP == true,
            Callback = function(v)
                settings.FuseboxESP = v
                Config.save(settings)
            end,
        })
        sObj:AddToggle("FuseNeedBat", {
            Title = "Fusebox requires battery equipped",
            Default = settings.FuseboxOnlyWithBattery ~= false,
            Callback = function(v)
                settings.FuseboxOnlyWithBattery = v
                Config.save(settings)
            end,
        })
        sObj:AddSlider("ObjMaxDist", {
            Title = "Objective ESP max distance",
            Default = math.clamp(settings.ObjectiveMaxDistance or 8000, 100, 20000),
            Min = 100,
            Max = 20000,
            Rounding = 0,
            Callback = function(v)
                settings.ObjectiveMaxDistance = v
                Config.save(settings)
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
            Default = math.clamp(settings.KillerMaxDistance, 100, 20000),
            Min = 100,
            Max = 20000,
            Rounding = 0,
            Callback = function(v) settings.KillerMaxDistance = v; Config.save(settings) end,
        })
    end

    -- ========== SURVIVOR ESP ==========
    do
        local s = SurvivorTab:AddSection("Survivor ESP")
        s:AddToggle("SurvEsp", {
            Title = "Enabled",
            Default = settings.SurvivorESP == true,
            Callback = function(v)
                state.SurvivorESP = v
                settings.SurvivorESP = v
                Config.save(settings)
                if v then SurvivorESP.startRender(state, settings) else SurvivorESP.stopRender() end
            end,
        })
        s:AddToggle("SurvSidebar", {
            Title = "Health sidebar",
            Description = "Left panel listing ALIVE survivors (cheat-style list)",
            Default = settings.SurvivorSidebar ~= false,
            Callback = function(v)
                settings.SurvivorSidebar = v
                Config.save(settings)
            end,
        })
        s:AddToggle("SurvShowSelf", {
            Title = "Show local player ESP",
            Default = settings.SurvivorShowSelf == true,
            Callback = function(v)
                settings.SurvivorShowSelf = v
                Config.save(settings)
                local ch = LocalPlayer.Character
                if ch then
                    if v then SurvivorESP.createDrawings(ch, settings) else SurvivorESP.destroyDrawings(ch) end
                end
            end,
        })
    end

    local survCp = SurvivorTab:AddColorpicker("SurvColor", {
        Title = "ESP Color",
        Default = Helpers.getSurvivorColor(settings),
    })
    survCp:OnChanged(function()
        local v = survCp.Value
        settings.SurvivorColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
        Config.save(settings)
    end)

    do
        local s = SurvivorTab:AddSection("Components")
        s:AddToggle("SurvBox", {
            Title = "Box",
            Default = settings.SurvivorBox ~= false,
            Callback = function(v) settings.SurvivorBox = v; Config.save(settings) end,
        })
        s:AddSlider("SurvBoxThick", {
            Title = "Box Thickness",
            Default = settings.SurvivorBoxThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.SurvivorBoxThickness = v; Config.save(settings) end,
        })
        s:AddToggle("SurvName", {
            Title = "Name",
            Default = settings.SurvivorName ~= false,
            Callback = function(v) settings.SurvivorName = v; Config.save(settings) end,
        })
        s:AddToggle("SurvHpText", {
            Title = "Health numbers (world)",
            Default = settings.SurvivorHealthText ~= false,
            Callback = function(v) settings.SurvivorHealthText = v; Config.save(settings) end,
        })
        s:AddToggle("SurvDist", {
            Title = "Distance",
            Default = settings.SurvivorDistance ~= false,
            Callback = function(v) settings.SurvivorDistance = v; Config.save(settings) end,
        })
        s:AddToggle("SurvTracer", {
            Title = "Tracer",
            Default = settings.SurvivorTracer ~= false,
            Callback = function(v) settings.SurvivorTracer = v; Config.save(settings) end,
        })
        s:AddSlider("SurvTracerThick", {
            Title = "Tracer Thickness",
            Default = settings.SurvivorTracerThickness,
            Min = 1,
            Max = 5,
            Rounding = 0,
            Callback = function(v) settings.SurvivorTracerThickness = v; Config.save(settings) end,
        })
    end

    do
        local s = SurvivorTab:AddSection("Display")
        s:AddSlider("SurvTextSz", {
            Title = "Text Size",
            Default = settings.SurvivorTextSize,
            Min = 10,
            Max = 24,
            Rounding = 0,
            Callback = function(v) settings.SurvivorTextSize = v; Config.save(settings) end,
        })
        s:AddSlider("SurvMaxDist", {
            Title = "Max Distance (studs)",
            Default = math.clamp(settings.SurvivorMaxDistance, 100, 20000),
            Min = 100,
            Max = 20000,
            Rounding = 0,
            Callback = function(v) settings.SurvivorMaxDistance = v; Config.save(settings) end,
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
        local iface = SettingsTab:AddSection("Interface (Fluent)")
        local themes = Fluent.Themes or { "Dark" }
        local themeIdx = 1
        for i, name in ipairs(themes) do
            if name == settings.FluentTheme then
                themeIdx = i
                break
            end
        end

        iface:AddDropdown("FluentThemePick", {
            Title = "Theme",
            Description = "Fluent built-in themes",
            Values = themes,
            Default = themeIdx,
            Callback = function(Value)
                settings.FluentTheme = Value
                Config.save(settings)
                pcall(function() Fluent:SetTheme(Value) end)
            end,
        })

        if Fluent.UseAcrylic then
            iface:AddToggle("FluentAcrylicTgl", {
                Title = "Acrylic blur",
                Description = "Frosted background (needs higher graphics quality in some clients)",
                Default = settings.FluentAcrylic == true,
                Callback = function(v)
                    settings.FluentAcrylic = v
                    Config.save(settings)
                    pcall(function() Fluent:ToggleAcrylic(v) end)
                end,
            })
        end

        iface:AddToggle("FluentTransTgl", {
            Title = "Transparent panels",
            Description = "More see-through window chrome",
            Default = settings.FluentTransparency == true,
            Callback = function(v)
                settings.FluentTransparency = v
                Config.save(settings)
                pcall(function() Fluent:ToggleTransparency(v) end)
            end,
        })

        iface:AddSlider("FluentWinW", {
            Title = "Window width",
            Description = "Saved now; apply on next execute",
            Default = math.clamp(settings.FluentWindowW or 580, 400, 1000),
            Min = 400,
            Max = 1000,
            Rounding = 0,
            Callback = function(v)
                settings.FluentWindowW = v
                Config.save(settings)
            end,
        })

        iface:AddSlider("FluentWinH", {
            Title = "Window height",
            Description = "Saved now; apply on next execute",
            Default = math.clamp(settings.FluentWindowH or 460, 300, 900),
            Min = 300,
            Max = 900,
            Rounding = 0,
            Callback = function(v)
                settings.FluentWindowH = v
                Config.save(settings)
            end,
        })

        local minKb = iface:AddKeybind("FluentMinKB", {
            Title = "Minimize key",
            Description = "Toggle hub visibility (Fluent bind)",
            Default = settings.FluentMinimizeKey or "RightControl",
        })
        Fluent.MinimizeKeybind = Fluent.Options.FluentMinKB
        minKb:OnChanged(function()
            local opt = Fluent.Options.FluentMinKB
            if opt and opt.Value ~= nil then
                settings.FluentMinimizeKey = tostring(opt.Value)
                Config.save(settings)
            end
        end)
    end

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
