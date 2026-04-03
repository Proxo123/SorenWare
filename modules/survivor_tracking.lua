local SurvivorESP, Logger = ...

local SurvivorTracking = {}

function SurvivorTracking.track(state, settings)
    local ok, aliveFolder = pcall(function()
        return workspace:WaitForChild("PLAYERS", 5) and workspace.PLAYERS:FindFirstChild("ALIVE")
    end)
    if not ok or not aliveFolder then return end

    local function tryTrack(m)
        if m:IsA("Model") and m:FindFirstChild("Humanoid") then
            SurvivorESP.createDrawings(m, settings)
        end
    end

    for _, child in next, aliveFolder:GetChildren() do
        tryTrack(child)
    end

    local addConn = aliveFolder.ChildAdded:Connect(function(child)
        task.wait(0.3)
        tryTrack(child)
    end)
    state.addRoundConnection(addConn)

    local removeConn = aliveFolder.ChildRemoved:Connect(function(child)
        SurvivorESP.destroyDrawings(child)
    end)
    state.addRoundConnection(removeConn)

    Logger.log("Survivor tracking active")
end

return SurvivorTracking
