local Helpers, Config, GenESP, KillerESP, Stamina, Logger = ...

local mathFloor = Helpers.mathFloor

local UI = {}

local function LoadOrion()
    local sources = {
        "https://raw.githubusercontent.com/shlexware/Orion/main/source",
        "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
    }
    for _, url in ipairs(sources) do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and lib then return lib end
    end
    return nil
end

function UI.build(state, settings)
    local OrionLib = LoadOrion()
    if not OrionLib then
        warn("[SorenWare] Failed to load Orion UI library.")
        return nil
    end

    local Window = OrionLib:MakeWindow({
        Name = "Generator Hub",
        HidePremium = true,
        IntroText = "Generator Hub",
        SaveConfig = false,
        IntroEnabled = true,
    })

    -- ========== GENERATORS TAB ==========
    local GenTab = Window:MakeTab({
        Name = "Generators",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false,
    })

    GenTab:AddSection({ Name = "Auto Generator" })

    GenTab:AddToggle({
        Name = "Enabled",
        Default = settings.AutoGen,
        Save = false,
        Flag = "AutoGenToggle",
        Callback = function(v)
            state.AutoGen = v
            settings.AutoGen = v
            Config.save(settings)
        end,
    })

    GenTab:AddSlider({
        Name = "Cooldown (seconds)",
        Min = 0, Max = 50,
        Default = settings.AutoGenCooldown * 10,
        Color = Color3.fromRGB(0, 170, 255),
        Increment = 1,
        Save = false,
        Flag = "CooldownSlider",
        Callback = function(v)
            settings.AutoGenCooldown = v / 10
            Config.save(settings)
        end,
    })

    GenTab:AddParagraph("How it works", "Completes generators automatically when you interact. Cooldown adds a delay between completions. 0 = instant.")

    GenTab:AddSection({ Name = "Generator ESP" })

    GenTab:AddToggle({
        Name = "Enabled",
        Default = settings.GenESP,
        Save = false,
        Flag = "GenESPToggle",
        Callback = function(v)
            state.GenESP = v
            settings.GenESP = v
            Config.save(settings)
            if v then GenESP.enable(state, settings) else GenESP.disable(state) end
        end,
    })

    GenTab:AddColorpicker({
        Name = "Fill Color",
        Default = Helpers.getFillColor(settings),
        Save = false,
        Flag = "FillColorPicker",
        Callback = function(v)
            settings.FillColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    GenTab:AddSlider({
        Name = "Fill Transparency",
        Min = 0, Max = 100,
        Default = mathFloor(settings.FillTransparency * 100),
        Color = Color3.fromRGB(255, 0, 0),
        Increment = 5,
        Save = false,
        Flag = "FillTransSlider",
        Callback = function(v)
            settings.FillTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    GenTab:AddColorpicker({
        Name = "Outline Color",
        Default = Helpers.getOutlineColor(settings),
        Save = false,
        Flag = "OutlineColorPicker",
        Callback = function(v)
            settings.OutlineColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    GenTab:AddSlider({
        Name = "Outline Transparency",
        Min = 0, Max = 100,
        Default = mathFloor(settings.OutlineTransparency * 100),
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 5,
        Save = false,
        Flag = "OutlineTransSlider",
        Callback = function(v)
            settings.OutlineTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    -- ========== KILLER ESP TAB ==========
    local KillerTab = Window:MakeTab({
        Name = "Killer ESP",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false,
    })

    KillerTab:AddSection({ Name = "Killer ESP" })

    KillerTab:AddToggle({
        Name = "Enabled",
        Default = settings.KillerESP,
        Save = false,
        Flag = "KillerESPToggle",
        Callback = function(v)
            state.KillerESP = v
            settings.KillerESP = v
            Config.save(settings)
            if v then KillerESP.startRender(state, settings) else KillerESP.stopRender() end
        end,
    })

    KillerTab:AddColorpicker({
        Name = "ESP Color",
        Default = Helpers.getKillerColor(settings),
        Save = false,
        Flag = "KillerColorPicker",
        Callback = function(v)
            settings.KillerColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
        end,
    })

    KillerTab:AddSection({ Name = "Components" })

    KillerTab:AddToggle({
        Name = "Box",
        Default = settings.KillerBox,
        Save = false,
        Flag = "KillerBoxToggle",
        Callback = function(v) settings.KillerBox = v; Config.save(settings) end,
    })

    KillerTab:AddSlider({
        Name = "Box Thickness",
        Min = 1, Max = 5,
        Default = settings.KillerBoxThickness,
        Color = Color3.fromRGB(255, 0, 0),
        Increment = 1,
        Save = false,
        Flag = "KillerBoxThickSlider",
        Callback = function(v) settings.KillerBoxThickness = v; Config.save(settings) end,
    })

    KillerTab:AddToggle({
        Name = "Name",
        Default = settings.KillerName,
        Save = false,
        Flag = "KillerNameToggle",
        Callback = function(v) settings.KillerName = v; Config.save(settings) end,
    })

    KillerTab:AddToggle({
        Name = "Distance",
        Default = settings.KillerDistance,
        Save = false,
        Flag = "KillerDistToggle",
        Callback = function(v) settings.KillerDistance = v; Config.save(settings) end,
    })

    KillerTab:AddToggle({
        Name = "Tracer",
        Default = settings.KillerTracer,
        Save = false,
        Flag = "KillerTracerToggle",
        Callback = function(v) settings.KillerTracer = v; Config.save(settings) end,
    })

    KillerTab:AddSlider({
        Name = "Tracer Thickness",
        Min = 1, Max = 5,
        Default = settings.KillerTracerThickness,
        Color = Color3.fromRGB(255, 0, 0),
        Increment = 1,
        Save = false,
        Flag = "KillerTracerThickSlider",
        Callback = function(v) settings.KillerTracerThickness = v; Config.save(settings) end,
    })

    KillerTab:AddSection({ Name = "Display" })

    KillerTab:AddSlider({
        Name = "Text Size",
        Min = 10, Max = 24,
        Default = settings.KillerTextSize,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 1,
        Save = false,
        Flag = "KillerTextSizeSlider",
        Callback = function(v) settings.KillerTextSize = v; Config.save(settings) end,
    })

    KillerTab:AddSlider({
        Name = "Max Distance (studs)",
        Min = 100, Max = 5000,
        Default = settings.KillerMaxDistance,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 100,
        Save = false,
        Flag = "KillerMaxDistSlider",
        Callback = function(v) settings.KillerMaxDistance = v; Config.save(settings) end,
    })

    -- ========== PLAYER TAB ==========
    local PlayerTab = Window:MakeTab({
        Name = "Player",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false,
    })

    local function checkStaminaHook()
        if settings.InfStamina or settings.CustomDrain or settings.CustomMaxStamina then
            Stamina.enable(settings, state)
        else
            Stamina.disable()
        end
    end

    PlayerTab:AddSection({ Name = "Infinite Stamina" })

    PlayerTab:AddToggle({
        Name = "Enabled",
        Default = settings.InfStamina,
        Save = false,
        Flag = "InfStaminaToggle",
        Callback = function(v)
            settings.InfStamina = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    PlayerTab:AddParagraph("How it works", "Spoofs stamina on the client so your character always thinks it has full stamina. Sprint will never stop. Server still drains real stamina but your client ignores it.")

    PlayerTab:AddSection({ Name = "Custom Drain Rate" })

    PlayerTab:AddToggle({
        Name = "Enabled",
        Default = settings.CustomDrain,
        Save = false,
        Flag = "CustomDrainToggle",
        Callback = function(v)
            settings.CustomDrain = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    PlayerTab:AddSlider({
        Name = "Drain Rate (%)",
        Min = 0, Max = 100,
        Default = settings.DrainRate,
        Color = Color3.fromRGB(0, 255, 100),
        Increment = 5,
        Save = false,
        Flag = "DrainRateSlider",
        Callback = function(v) settings.DrainRate = v; Config.save(settings) end,
    })

    PlayerTab:AddParagraph("How it works", "Controls how fast stamina drains relative to normal. 100% = normal drain, 50% = half drain, 0% = no drain (same as infinite). Only works when Infinite Stamina is OFF.")

    PlayerTab:AddSection({ Name = "Custom Max Stamina" })

    PlayerTab:AddToggle({
        Name = "Enabled",
        Default = settings.CustomMaxStamina,
        Save = false,
        Flag = "CustomMaxToggle",
        Callback = function(v)
            settings.CustomMaxStamina = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    PlayerTab:AddSlider({
        Name = "Max Stamina",
        Min = 50, Max = 500,
        Default = settings.MaxStaminaValue,
        Color = Color3.fromRGB(0, 170, 255),
        Increment = 10,
        Save = false,
        Flag = "MaxStaminaSlider",
        Callback = function(v) settings.MaxStaminaValue = v; Config.save(settings) end,
    })

    PlayerTab:AddParagraph("How it works", "Spoofs your max stamina value on the client. Higher max = longer sprint duration with custom drain. Normal max is 100 for survivors, 65-70 for killers.")

    -- ========== SETTINGS TAB ==========
    local SettingsTab = Window:MakeTab({
        Name = "Settings",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false,
    })

    SettingsTab:AddSection({ Name = "General" })

    SettingsTab:AddToggle({
        Name = "Debug Logging",
        Default = settings.Debug,
        Save = false,
        Flag = "DebugToggle",
        Callback = function(v) settings.Debug = v; Config.save(settings) end,
    })

    SettingsTab:AddSection({ Name = "Data" })

    SettingsTab:AddButton({
        Name = "Reset All Settings",
        Callback = function()
            Config.reset(settings)
            OrionLib:MakeNotification({
                Name = "Generator Hub",
                Content = "Settings reset. Re-execute to apply.",
                Image = "rbxassetid://4483345998",
                Time = 5,
            })
        end,
    })

    SettingsTab:AddSection({ Name = "Script" })

    SettingsTab:AddButton({
        Name = "Unload Hub",
        Callback = function()
            if getgenv and getgenv().GenHub then
                getgenv().GenHub.Unload()
            end
        end,
    })

    OrionLib:MakeNotification({
        Name = "Generator Hub",
        Content = "Loaded! Toggle features in the menu.",
        Image = "rbxassetid://4483345998",
        Time = 5,
    })

    OrionLib:Init()

    return OrionLib
end

return UI
