--[[
    SorenWare - Generator Hub Loader
    Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/Proxo123/SorenWare/main/loader.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/Proxo123/SorenWare/main/"
-- Bust CDN / executor HTTP cache so a re-run pulls the latest main + modules (not an old copy).
local CACHE_TAG = tostring(math.floor(tick() * 1000))

local function fetch(path)
    local sep = (path:find("?", 1, true) and "&" or "?")
    local url = REPO .. path .. sep .. "z=" .. CACHE_TAG
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
