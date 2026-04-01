local GenTracking, KillerTracking, KillerESP, Logger = ...

local RoundManager = {}

local function onRoundStart(gameMap, state, settings)
    Logger.log("Round started")
    state.RoundActive = true

    local generators = gameMap:WaitForChild("Generators", 10)
    if generators then
        for _, gen in next, generators:GetChildren() do
            GenTracking.track(gen, state, settings)
        end
        local conn = generators.ChildAdded:Connect(function(gen)
            task.wait(0.5)
            GenTracking.track(gen, state, settings)
        end)
        state.addRoundConnection(conn)
    end

    KillerTracking.track(state, settings)
end

local function onRoundEnd(state)
    Logger.log("Round ended")
    state.RoundActive = false
    state.disconnectRound()
    GenTracking.untrackAll(state)
    KillerESP.destroyAll()
end

function RoundManager.init(state, settings)
    local maps = workspace:WaitForChild("MAPS", 30)
    if not maps then return end

    local existing = maps:FindFirstChild("GAME MAP")
    if existing then task.spawn(onRoundStart, existing, state, settings) end

    local a = maps.ChildAdded:Connect(function(child)
        if child.Name == "GAME MAP" then
            task.wait(0.5)
            onRoundStart(child, state, settings)
        end
    end)
    state.addCoreConnection(a)

    local r = maps.ChildRemoved:Connect(function(child)
        if child.Name == "GAME MAP" then onRoundEnd(state) end
    end)
    state.addCoreConnection(r)
end

return RoundManager
