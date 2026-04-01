local Logger = {}

local settings = nil

function Logger.init(s)
    settings = s
end

function Logger.log(...)
    if settings and settings.Debug then
        print("[GenHub]", ...)
    end
end

return Logger
