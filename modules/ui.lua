local SorenUI, Helpers, Config, GenESP, KillerESP, Stamina, Logger = ...

local mathFloor = Helpers.mathFloor

local UI = {}

function UI.build(state, settings)
    local window = SorenUI:CreateWindow({
        Title = "Generator Hub",
        Size = UDim2.fromOffset(560, 420),
        CloseCallback = function()
            if getgenv and getgenv().GenHub then
                getgenv().GenHub.Unload()
            end
        end,
    })

    -- ═════════════════════════════════════════
    -- GENERATORS TAB
    -- ═════════════════════════════════════════
    local genTab = window:CreateTab({ Name = "Generators", Icon = "rbxassetid://4483345998" })

    genTab:CreateSection("Auto Generator")

    genTab:CreateToggle({
        Name = "Enabled",
        Default = settings.AutoGen,
        Callback = function(v)
            state.AutoGen = v
            settings.AutoGen = v
            Config.save(settings)
        end,
    })

    genTab:CreateSlider({
        Name = "Cooldown",
        Min = 0, Max = 50,
        Default = settings.AutoGenCooldown * 10,
        Increment = 1,
        Suffix = "",
        Callback = function(v)
            settings.AutoGenCooldown = v / 10
            Config.save(settings)
        end,
    })

    genTab:CreateParagraph({
        Title = "How it works",
        Content = "Completes generators automatically when you interact. Cooldown adds a delay between completions (value / 10 = seconds). 0 = instant.",
    })

    genTab:CreateSection("Generator ESP")

    genTab:CreateToggle({
        Name = "Enabled",
        Default = settings.GenESP,
        Callback = function(v)
            state.GenESP = v
            settings.GenESP = v
            Config.save(settings)
            if v then GenESP.enable(state, settings) else GenESP.disable(state) end
        end,
    })

    genTab:CreateColorpicker({
        Name = "Fill Color",
        Default = Helpers.getFillColor(settings),
        Callback = function(v)
            settings.FillColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    genTab:CreateSlider({
        Name = "Fill Transparency",
        Min = 0, Max = 100,
        Default = mathFloor(settings.FillTransparency * 100),
        Increment = 5,
        Suffix = "%",
        Callback = function(v)
            settings.FillTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    genTab:CreateColorpicker({
        Name = "Outline Color",
        Default = Helpers.getOutlineColor(settings),
        Callback = function(v)
            settings.OutlineColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    genTab:CreateSlider({
        Name = "Outline Transparency",
        Min = 0, Max = 100,
        Default = mathFloor(settings.OutlineTransparency * 100),
        Increment = 5,
        Suffix = "%",
        Callback = function(v)
            settings.OutlineTransparency = v / 100
            Config.save(settings)
            GenESP.refreshAll(state, settings)
        end,
    })

    -- ═════════════════════════════════════════
    -- KILLER ESP TAB
    -- ═════════════════════════════════════════
    local killerTab = window:CreateTab({ Name = "Killer ESP", Icon = "rbxassetid://4483345998" })

    killerTab:CreateSection("Killer ESP")

    killerTab:CreateToggle({
        Name = "Enabled",
        Default = settings.KillerESP,
        Callback = function(v)
            state.KillerESP = v
            settings.KillerESP = v
            Config.save(settings)
            if v then KillerESP.startRender(state, settings) else KillerESP.stopRender() end
        end,
    })

    killerTab:CreateColorpicker({
        Name = "ESP Color",
        Default = Helpers.getKillerColor(settings),
        Callback = function(v)
            settings.KillerColor = { R = mathFloor(v.R * 255), G = mathFloor(v.G * 255), B = mathFloor(v.B * 255) }
            Config.save(settings)
        end,
    })

    killerTab:CreateSection("Components")

    killerTab:CreateToggle({
        Name = "Box",
        Default = settings.KillerBox,
        Callback = function(v) settings.KillerBox = v; Config.save(settings) end,
    })

    killerTab:CreateSlider({
        Name = "Box Thickness",
        Min = 1, Max = 5,
        Default = settings.KillerBoxThickness,
        Increment = 1,
        Callback = function(v) settings.KillerBoxThickness = v; Config.save(settings) end,
    })

    killerTab:CreateToggle({
        Name = "Name",
        Default = settings.KillerName,
        Callback = function(v) settings.KillerName = v; Config.save(settings) end,
    })

    killerTab:CreateToggle({
        Name = "Distance",
        Default = settings.KillerDistance,
        Callback = function(v) settings.KillerDistance = v; Config.save(settings) end,
    })

    killerTab:CreateToggle({
        Name = "Tracer",
        Default = settings.KillerTracer,
        Callback = function(v) settings.KillerTracer = v; Config.save(settings) end,
    })

    killerTab:CreateSlider({
        Name = "Tracer Thickness",
        Min = 1, Max = 5,
        Default = settings.KillerTracerThickness,
        Increment = 1,
        Callback = function(v) settings.KillerTracerThickness = v; Config.save(settings) end,
    })

    killerTab:CreateSection("Display")

    killerTab:CreateSlider({
        Name = "Text Size",
        Min = 10, Max = 24,
        Default = settings.KillerTextSize,
        Increment = 1,
        Callback = function(v) settings.KillerTextSize = v; Config.save(settings) end,
    })

    killerTab:CreateSlider({
        Name = "Max Distance",
        Min = 100, Max = 5000,
        Default = settings.KillerMaxDistance,
        Increment = 100,
        Suffix = " studs",
        Callback = function(v) settings.KillerMaxDistance = v; Config.save(settings) end,
    })

    -- ═════════════════════════════════════════
    -- PLAYER TAB
    -- ═════════════════════════════════════════
    local playerTab = window:CreateTab({ Name = "Player", Icon = "rbxassetid://4483345998" })

    local function checkStaminaHook()
        if settings.InfStamina or settings.CustomDrain or settings.CustomMaxStamina then
            Stamina.enable(settings, state)
        else
            Stamina.disable()
        end
    end

    playerTab:CreateSection("Infinite Stamina")

    playerTab:CreateToggle({
        Name = "Enabled",
        Default = settings.InfStamina,
        Callback = function(v)
            settings.InfStamina = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    playerTab:CreateParagraph({
        Title = "How it works",
        Content = "Spoofs stamina on the client so your character always thinks it has full stamina. Sprint will never stop. Server still drains real stamina but your client ignores it.",
    })

    playerTab:CreateSection("Custom Drain Rate")

    playerTab:CreateToggle({
        Name = "Enabled",
        Default = settings.CustomDrain,
        Callback = function(v)
            settings.CustomDrain = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    playerTab:CreateSlider({
        Name = "Drain Rate",
        Min = 0, Max = 100,
        Default = settings.DrainRate,
        Increment = 5,
        Suffix = "%",
        Callback = function(v) settings.DrainRate = v; Config.save(settings) end,
    })

    playerTab:CreateParagraph({
        Title = "How it works",
        Content = "Controls how fast stamina drains relative to normal. 100% = normal, 50% = half, 0% = none. Only works when Infinite Stamina is OFF.",
    })

    playerTab:CreateSection("Custom Max Stamina")

    playerTab:CreateToggle({
        Name = "Enabled",
        Default = settings.CustomMaxStamina,
        Callback = function(v)
            settings.CustomMaxStamina = v
            Config.save(settings)
            checkStaminaHook()
        end,
    })

    playerTab:CreateSlider({
        Name = "Max Stamina",
        Min = 50, Max = 500,
        Default = settings.MaxStaminaValue,
        Increment = 10,
        Callback = function(v) settings.MaxStaminaValue = v; Config.save(settings) end,
    })

    playerTab:CreateParagraph({
        Title = "How it works",
        Content = "Spoofs your max stamina value on the client. Higher max = longer sprint. Normal max is 100 for survivors, 65-70 for killers.",
    })

    -- ═════════════════════════════════════════
    -- SETTINGS TAB
    -- ═════════════════════════════════════════
    local settingsTab = window:CreateTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })

    settingsTab:CreateSection("General")

    settingsTab:CreateToggle({
        Name = "Debug Logging",
        Default = settings.Debug,
        Callback = function(v) settings.Debug = v; Config.save(settings) end,
    })

    settingsTab:CreateSection("Profiles")

    local profileDropdown
    local function refreshProfiles()
        local list = Config.listProfiles()
        if #list == 0 then list = { "(none)" } end
        if profileDropdown then
            profileDropdown:SetOptions(list)
        end
    end

    profileDropdown = settingsTab:CreateDropdown({
        Name = "Profile",
        Options = { "(none)" },
        Default = "(none)",
        Callback = function() end,
    })
    refreshProfiles()

    settingsTab:CreateTextbox({
        Name = "Save As",
        Placeholder = "profile name",
        Callback = function(text, enter)
            if enter and text ~= "" then
                Config.saveProfile(text, settings)
                refreshProfiles()
                window:CreateNotification({
                    Title = "Profile Saved",
                    Content = 'Saved as "' .. text .. '"',
                    Duration = 3,
                    Type = "success",
                })
            end
        end,
    })

    settingsTab:CreateButton({
        Name = "Load Selected Profile",
        Callback = function()
            local sel = profileDropdown:Get()
            if sel == "(none)" then return end
            local data = Config.loadProfile(sel)
            if data then
                for k, v in next, data do settings[k] = v end
                Config.save(settings)
                window:CreateNotification({
                    Title = "Profile Loaded",
                    Content = 'Loaded "' .. sel .. '". Re-execute to fully apply.',
                    Duration = 4,
                    Type = "info",
                })
            end
        end,
    })

    settingsTab:CreateButton({
        Name = "Delete Selected Profile",
        Callback = function()
            local sel = profileDropdown:Get()
            if sel == "(none)" then return end
            Config.deleteProfile(sel)
            refreshProfiles()
            window:CreateNotification({
                Title = "Profile Deleted",
                Content = 'Deleted "' .. sel .. '"',
                Duration = 3,
                Type = "warning",
            })
        end,
    })

    settingsTab:CreateSection("Data")

    settingsTab:CreateButton({
        Name = "Reset All Settings",
        Callback = function()
            Config.reset(settings)
            window:CreateNotification({
                Title = "Settings Reset",
                Content = "All settings reset to defaults. Re-execute to apply.",
                Duration = 4,
                Type = "warning",
            })
        end,
    })

    settingsTab:CreateSection("Script")

    settingsTab:CreateButton({
        Name = "Unload Hub",
        Callback = function()
            if getgenv and getgenv().GenHub then
                getgenv().GenHub.Unload()
            end
        end,
    })

    settingsTab:CreateParagraph({
        Title = "Toggle Key",
        Content = "Press Right Control to minimize/restore the window.",
    })

    -- initial notification
    window:CreateNotification({
        Title = "Generator Hub",
        Content = "Loaded! Toggle features in the menu.",
        Duration = 4,
        Type = "success",
    })

    return window
end

return UI
