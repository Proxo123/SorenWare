local Logger = {}
local settingsRef = nil

function Logger.init(s)
    settingsRef = s
end

function Logger.log(...)
    if settingsRef and settingsRef.Debug then
        print("[HypershotESP]", ...)
    end
end

function Logger.info(msg)
    print("[HypershotESP]", msg)
end

return Logger
