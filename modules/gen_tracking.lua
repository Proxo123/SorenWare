local GenESP = ...

local GenTracking = {}

function GenTracking.track(generator, state, settings)
    if state.Generators[generator] then return end

    local data = { complete = false, highlight = nil, connections = {}, prompts = {} }
    state.Generators[generator] = data

    for _, desc in next, generator:GetDescendants() do
        if desc:IsA("ProximityPrompt") then
            table.insert(data.prompts, desc)
        end
    end

    if #data.prompts == 0 then return end

    local function checkAllComplete()
        for _, prompt in next, data.prompts do
            if prompt.Enabled then return false end
        end
        return true
    end

    data.complete = checkAllComplete()

    for _, prompt in next, data.prompts do
        local conn = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
            local was = data.complete
            data.complete = checkAllComplete()
            if data.complete and not was then
                if state.GenESP then GenESP.removeHighlight(generator, state) end
            elseif not data.complete and was then
                if state.GenESP then GenESP.addHighlight(generator, state, settings) end
            end
        end)
        table.insert(data.connections, conn)
        state.addRoundConnection(conn)
    end

    if state.GenESP and not data.complete then
        GenESP.addHighlight(generator, state, settings)
    end
end

function GenTracking.untrackAll(state)
    for _, data in next, state.Generators do
        if data.highlight then data.highlight:Destroy() end
        for _, conn in next, data.connections do
            if conn.Connected then conn:Disconnect() end
        end
    end
    table.clear(state.Generators)
end

return GenTracking
