--[[
    SorenWare - Generator Hub Loader
    Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/Proxo123/SorenWare/main/loader.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/Proxo123/SorenWare/main/"

-- Cache-bust so HttpGet does not keep serving an old main.lua / modules (GitHub + some executors cache aggressively).
local function fetch(path)
    local url = REPO .. path .. "?t=" .. tostring(tick()) .. "_" .. tostring(math.random(1, 1e9))
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not result or #result == 0 then
        warn("[SorenWare] Failed to fetch: " .. path)
        return nil
    end
    return result
end

local mainSource = fetch("main.lua")
if not mainSource then
    warn("[SorenWare] Could not load main.lua — aborting.")
    return
end

local mainFn, err = loadstring(mainSource)
if not mainFn then
    warn("[SorenWare] Syntax error in main.lua: " .. tostring(err))
    return
end

mainFn(REPO, fetch)
