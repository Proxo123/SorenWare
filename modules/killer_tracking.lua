local KillerESP, Logger = ...

local KillerTracking = {}

function KillerTracking.track(state, settings)
    local ok, killerFolder = pcall(function()
        return workspace:WaitForChild("PLAYERS", 5) and workspace.PLAYERS:FindFirstChild("KILLER")
    end)
    if not ok or not killerFolder then return end

    for _, child in next, killerFolder:GetChildren() do
        if child:IsA("Model") then
            KillerESP.createDrawings(child, settings)
        end
    end

    local addConn = killerFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.wait(0.3)
            KillerESP.createDrawings(child, settings)
        end
    end)
    state.addRoundConnection(addConn)

    local removeConn = killerFolder.ChildRemoved:Connect(function(child)
        KillerESP.destroyDrawings(child)
    end)
    state.addRoundConnection(removeConn)

    Logger.log("Killer tracking active")
end

return KillerTracking
