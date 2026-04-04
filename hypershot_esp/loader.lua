--[[
  Hypershot player ESP (SorenWare-style loader).
  loadstring(game:HttpGet("https://raw.githubusercontent.com/Proxo123/SorenWare/main/hypershot_esp/loader.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/Proxo123/SorenWare/main/"

local function fetch(path)
    local url = REPO .. path .. "?t=" .. tostring(tick()) .. "_" .. tostring(math.random(1, 1e9))
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not result or #result == 0 then
        warn("[HypershotESP] Failed to fetch: " .. path)
        return nil
    end
    return result
end

local mainSource = fetch("hypershot_esp/main.lua")
if not mainSource then
    warn("[HypershotESP] Could not load main.lua.")
    return
end

local mainFn, err = loadstring(mainSource)
if not mainFn then
    warn("[HypershotESP] Syntax error in main.lua: " .. tostring(err))
    return
end

mainFn(REPO, fetch)
