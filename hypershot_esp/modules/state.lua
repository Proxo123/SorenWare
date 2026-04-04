local State = {
    PlayerESP = false,
}

local Connections = {}

function State.init(settings)
    State.PlayerESP = settings.PlayerESP == true
end

function State.disconnectCore()
    for _, conn in next, Connections do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(Connections)
end

function State.addCoreConnection(conn)
    table.insert(Connections, conn)
end

return State
