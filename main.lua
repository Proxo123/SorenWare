--[[
    SorenWare - Generator Hub v5 (Modular)
    Orchestrator: loads all modules and wires them together.
    Do not execute this file directly — use loader.lua.
]]

local REPO, fetch = ...

-------------------------------------------------
-- MUTEX
-------------------------------------------------
if getgenv and getgenv().GenHub then
    pcall(function() getgenv().GenHub.Unload() end)
    task.wait(0.3)
end

-------------------------------------------------
-- MODULE LOADER
-------------------------------------------------
local function loadModule(path)
    local source = fetch("modules/" .. path)
    if not source then
        warn("[SorenWare] Failed to load module: " .. path)
        return nil
    end
    local fn, err = loadstring(source)
    if not fn then
        warn("[SorenWare] Syntax error in " .. path .. ": " .. tostring(err))
        return nil
    end
    return fn
end

-------------------------------------------------
-- LOAD MODULES
-------------------------------------------------
local Config   = loadModule("config.lua")()
local State    = loadModule("state.lua")()
local Logger   = loadModule("logger.lua")()
local Helpers  = loadModule("helpers.lua")()

local Settings = Config.load()
State.init(Settings)
Logger.init(Settings)

local GenESP         = loadModule("gen_esp.lua")(Helpers)
local KillerESP      = loadModule("killer_esp.lua")(Helpers, Logger)
local AutoGen        = loadModule("auto_gen.lua")(Logger)
local Stamina        = loadModule("stamina.lua")(Logger)
local GenTracking    = loadModule("gen_tracking.lua")(GenESP)
local KillerTracking = loadModule("killer_tracking.lua")(KillerESP, Logger)
local RoundManager   = loadModule("round_manager.lua")(GenTracking, KillerTracking, KillerESP, Logger)
local UI             = loadModule("ui.lua")(Helpers, Config, GenESP, KillerESP, Stamina, Logger)

-------------------------------------------------
-- BUILD UI
-------------------------------------------------
local FluentLib = UI.build(State, Settings)
if not FluentLib then return end

-------------------------------------------------
-- FULL UNLOAD
-------------------------------------------------
local function fullUnload()
    State.AutoGen = false
    State.GenESP = false
    State.KillerESP = false

    GenESP.disable(State)
    KillerESP.stopRender()
    KillerESP.destroyAll()
    Stamina.disable()

    State.disconnectCore()
    State.disconnectRound()
    GenTracking.untrackAll(State)
    GenESP.cleanup(State)

    pcall(function() FluentLib:Destroy() end)

    if getgenv then getgenv().GenHub = nil end
end

-------------------------------------------------
-- GLOBAL ACCESS
-------------------------------------------------
if getgenv then
    getgenv().GenHub = {
        State = State,
        Settings = Settings,
        Save = Config.save,
        Unload = fullUnload,
    }
end

-------------------------------------------------
-- INIT
-------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

RoundManager.init(State, Settings)
AutoGen.initWatcher(State, Settings, PlayerGui)

if State.GenESP then GenESP.enable(State, Settings) end
if State.KillerESP then KillerESP.startRender(State, Settings) end
if Settings.InfStamina or Settings.CustomDrain or Settings.CustomMaxStamina then
    Stamina.enable(Settings, State)
end
