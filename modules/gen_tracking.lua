local GenESP = ...

local GenTracking = {}

local function getPrompts(generator)
    local list = {}
    for _, desc in next, generator:GetDescendants() do
        if desc:IsA("ProximityPrompt") then
            table.insert(list, desc)
        end
    end
    return list
end

function GenTracking.track(generator, state, settings)
    if state.Generators[generator] then return end

    local data = {
        complete = false,
        highlight = nil,
        connections = {},
        promptHooks = {},
    }
    state.Generators[generator] = data

    local function checkAllComplete()
        local prompts = getPrompts(generator)
        if #prompts == 0 then
            return false
        end
        for _, prompt in next, prompts do
            if prompt.Parent and prompt.Enabled then
                return false
            end
        end
        return true
    end

    local function applyCompletionVisual()
        data.complete = checkAllComplete()
        if data.complete then
            if state.GenESP then GenESP.removeHighlight(generator, state) end
        else
            if state.GenESP then GenESP.addHighlight(generator, state, settings) end
        end
    end

    local function hookPrompt(prompt)
        if not prompt or not prompt.Parent then return end
        if data.promptHooks[prompt] then return end
        data.promptHooks[prompt] = true
        local conn = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
            applyCompletionVisual()
        end)
        table.insert(data.connections, conn)
        state.addRoundConnection(conn)
    end

    for _, p in next, getPrompts(generator) do
        hookPrompt(p)
    end

    local descConn = generator.DescendantAdded:Connect(function(desc)
        if desc:IsA("ProximityPrompt") then
            task.defer(function()
                hookPrompt(desc)
                applyCompletionVisual()
                GenESP.reconcileHighlights(state, settings)
            end)
        end
    end)
    table.insert(data.connections, descConn)
    state.addRoundConnection(descConn)

    data.complete = checkAllComplete()

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
        if data.promptHooks then
            table.clear(data.promptHooks)
        end
    end
    table.clear(state.Generators)
end

return GenTracking
