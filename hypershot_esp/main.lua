--[[
  Hypershot ESP — run only via hypershot_esp/loader.lua
]]

local REPO, fetch = ...

if getgenv and getgenv().HypershotESP then
    pcall(function() getgenv().HypershotESP.Unload() end)
    task.wait(0.2)
end

local function loadModule(name)
    local src = fetch("hypershot_esp/modules/" .. name)
    if not src then
        warn("[HypershotESP] Missing module: " .. name)
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[HypershotESP] Syntax error in " .. name .. ": " .. tostring(err))
        return nil
    end
    return fn
end

local Config = loadModule("config.lua")()
local State = loadModule("state.lua")()
local Logger = loadModule("logger.lua")()
local Helpers = loadModule("helpers.lua")()

local Settings = Config.load()
State.init(Settings)
Logger.init(Settings)

local PlayerESP = loadModule("player_esp.lua")(Helpers, Logger)
local PlayerTracking = loadModule("player_tracking.lua")(PlayerESP, Logger)
local UI = loadModule("ui.lua")(Helpers, Config, PlayerESP, Logger)

local Window = UI.build(State, Settings)
if not Window then
    return
end

PlayerTracking.start(State, Settings)

if State.PlayerESP then
    PlayerESP.startRender(State, Settings)
end

local function fullUnload()
    State.PlayerESP = false
    PlayerESP.stopRender()
    PlayerESP.destroyAll()
    PlayerTracking.stop()
    State.disconnectCore()
    pcall(function() Window:Destroy() end)
    if getgenv then getgenv().HypershotESP = nil end
end

if getgenv then
    getgenv().HypershotESP = {
        State = State,
        Settings = Settings,
        Save = Config.save,
        Unload = fullUnload,
    }
end

Logger.info("Hypershot ESP loaded.")
