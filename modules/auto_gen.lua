local Logger = ...

local AutoGen = {}

local function isGeneratorGui(screenGui)
    local ok, result = pcall(function()
        local mf = screenGui:FindFirstChild("MainFrame")
        if not mf then return false end
        local gen = mf:FindFirstChild("Generator")
        if not gen then return false end
        return gen:FindFirstChild("Lever") and gen:FindFirstChild("Switch") and gen:FindFirstChild("Wires")
    end)
    return ok and result
end

local function findEventRemote(screenGui)
    for _, desc in next, screenGui:GetDescendants() do
        if desc:IsA("RemoteEvent") and desc.Name == "Event" then
            return desc
        end
    end
    return nil
end

local function completeGui(screenGui, state, settings)
    if not state.AutoGen then return end

    local now = tick()
    local elapsed = now - state.LastCompleteTime
    if elapsed < settings.AutoGenCooldown then
        task.wait(settings.AutoGenCooldown - elapsed)
    end

    Logger.log("Generator UI detected:", screenGui.Name)

    local remote = nil
    for i = 1, 20 do
        remote = findEventRemote(screenGui)
        if remote then break end
        task.wait(0.1)
    end

    if not remote then return end

    pcall(function()
        remote:FireServer({ Wires = true, Switches = true, Lever = true })
    end)
    state.LastCompleteTime = tick()
    Logger.log("Generator completed!")
end

function AutoGen.initWatcher(state, settings, playerGui)
    for _, child in next, playerGui:GetChildren() do
        if child:IsA("ScreenGui") and isGeneratorGui(child) then
            task.spawn(completeGui, child, state, settings)
        end
    end

    local conn = playerGui.ChildAdded:Connect(function(child)
        if not child:IsA("ScreenGui") then return end
        task.wait(0.3)
        if isGeneratorGui(child) then
            completeGui(child, state, settings)
        end
    end)
    state.addCoreConnection(conn)
end

return AutoGen
