local State = {
    AutoGen = false,
    GenESP = false,
    KillerESP = false,
    SurvivorESP = false,
    RoundActive = false,
    Generators = {},
    LastCompleteTime = 0,
}

local Connections = {
    Round = {},
    Core = {},
}

function State.init(settings)
    State.AutoGen = settings.AutoGen
    State.GenESP = settings.GenESP
    State.KillerESP = settings.KillerESP
    State.SurvivorESP = settings.SurvivorESP == true
end

function State.disconnectRound()
    for _, conn in next, Connections.Round do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Connections.Round)
end

function State.disconnectCore()
    for _, conn in next, Connections.Core do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Connections.Core)
end

function State.addRoundConnection(conn)
    table.insert(Connections.Round, conn)
end

function State.addCoreConnection(conn)
    table.insert(Connections.Core, conn)
end

return State, Connections
