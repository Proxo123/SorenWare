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

local function fireCompletion(remote, payload)
    pcall(function()
        remote:FireServer(payload)
    end)
end

--- Games like Bite By Night use multiple puzzle stages per generator; one FireServer often only advances one stage.
local function runCompletionSequence(remote, screenGui, state, settings)
    local burstN = math.clamp(math.floor(settings.AutoGenBurstCount or 8), 1, 24)
    local delay = math.clamp(tonumber(settings.AutoGenBurstDelay) or 0.03, 0.01, 0.35)
    local fullPayload = { Wires = true, Switches = true, Lever = true }

    if settings.AutoGenWaveMode then
        --- One puzzle axis per fire, then a full pass (4 logical stages per round)
        local steps = {
            { Wires = true },
            { Switches = true },
            { Lever = true },
            fullPayload,
        }
        local rounds = math.clamp(math.ceil(burstN / 4), 1, 8)
        for _ = 1, rounds do
            if not state.AutoGen or not screenGui.Parent then break end
            for _, payload in ipairs(steps) do
                if not state.AutoGen or not screenGui.Parent then break end
                fireCompletion(remote, payload)
                task.wait(delay)
            end
        end
        return
    end

    --- Default: fast repeated full completions until count exhausted (typical multi-stage remote)
    for i = 1, burstN do
        if not state.AutoGen or not screenGui.Parent then break end
        fireCompletion(remote, fullPayload)
        if i < burstN then
            task.wait(delay)
        end
    end
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
    for _ = 1, 30 do
        remote = findEventRemote(screenGui)
        if remote then break end
        task.wait(0.03)
    end

    if not remote then return end

    runCompletionSequence(remote, screenGui, state, settings)
    state.LastCompleteTime = tick()
    Logger.log("Generator auto sequence finished (bursts / wave mode)")
end

function AutoGen.initWatcher(state, settings, playerGui)
    for _, child in next, playerGui:GetChildren() do
        if child:IsA("ScreenGui") and isGeneratorGui(child) then
            task.spawn(completeGui, child, state, settings)
        end
    end

    local conn = playerGui.ChildAdded:Connect(function(child)
        if not child:IsA("ScreenGui") then return end
        task.wait(0.15)
        if isGeneratorGui(child) then
            completeGui(child, state, settings)
        end
    end)
    state.addCoreConnection(conn)
end

return AutoGen
