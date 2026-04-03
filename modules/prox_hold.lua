local Logger = ...

local RunService = game:GetService("RunService")

local ProxHold = {}

local Conn = nil

local function zeroPromptsUnder(inst)
    for _, d in inst:GetDescendants() do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                d.HoldDuration = 0
            end)
        end
    end
end

local function getGameMap()
    local maps = workspace:FindFirstChild("MAPS")
    return maps and maps:FindFirstChild("GAME MAP")
end

function ProxHold.start(state, settings)
    if Conn then return end
    Conn = RunService.Heartbeat:Connect(function()
        if not settings.InstantProximity or not state.RoundActive then return end
        local gm = getGameMap()
        if gm then
            pcall(function()
                zeroPromptsUnder(gm)
            end)
        end
    end)
    state.addCoreConnection(Conn)
    Logger.log("Instant proximity loop started")
end

function ProxHold.stop()
    if Conn then
        Conn:Disconnect()
        Conn = nil
    end
    Logger.log("Instant proximity loop stopped")
end

return ProxHold
