local Helpers = ...

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GenESP = {}

local DistConn = nil

local function hrpPos()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or nil
end

local function genPosition(generator)
    if generator:IsA("Model") then
        if generator.PrimaryPart then
            return generator.PrimaryPart.Position
        end
        local ok, pivot = pcall(function()
            return generator:GetPivot().Position
        end)
        if ok then return pivot end
    elseif generator:IsA("BasePart") then
        return generator.Position
    end
    return nil
end

function GenESP.addHighlight(generator, state, settings)
    local data = state.Generators[generator]
    if not data or data.highlight or data.complete then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "GenESP"
    highlight.Adornee = generator
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    highlight.FillColor = Helpers.getFillColor(settings)
    highlight.FillTransparency = settings.FillTransparency
    highlight.OutlineColor = Helpers.getOutlineColor(settings)
    highlight.OutlineTransparency = settings.OutlineTransparency
    highlight.Parent = generator
    data.highlight = highlight
    GenESP.applyDistanceToHighlight(generator, state, settings)
end

function GenESP.removeHighlight(generator, state)
    local data = state.Generators[generator]
    if not data or not data.highlight then return end
    data.highlight:Destroy()
    data.highlight = nil
end

function GenESP.applyDistanceToHighlight(generator, state, settings)
    local data = state.Generators[generator]
    if not data or not data.highlight then return end
    local maxD = settings.GenMaxDistance or 10000
    local pos = genPosition(generator)
    local hp = hrpPos()
    if not pos or not hp then
        data.highlight.Enabled = state.GenESP == true and not data.complete
        return
    end
    local dist = (hp - pos).Magnitude
    data.highlight.Enabled = state.GenESP == true and not data.complete and dist <= maxD
end

function GenESP.reconcileHighlights(state, settings)
    for gen, data in next, state.Generators do
        if not gen.Parent then
            -- skip orphaned
        elseif state.GenESP and not data.complete then
            if not data.highlight or not data.highlight.Parent then
                GenESP.addHighlight(gen, state, settings)
            else
                GenESP.applyDistanceToHighlight(gen, state, settings)
            end
        end
    end
end

function GenESP.refreshAll(state, settings)
    for gen, data in next, state.Generators do
        if data.highlight then
            data.highlight.FillColor = Helpers.getFillColor(settings)
            data.highlight.FillTransparency = settings.FillTransparency
            data.highlight.OutlineColor = Helpers.getOutlineColor(settings)
            data.highlight.OutlineTransparency = settings.OutlineTransparency
            GenESP.applyDistanceToHighlight(gen, state, settings)
        end
    end
end

function GenESP.startDistanceLoop(state, settings)
    if DistConn then return end
    DistConn = RunService.Heartbeat:Connect(function()
        if not state.GenESP then return end
        local hp = hrpPos()
        local maxD = settings.GenMaxDistance or 10000
        for gen, data in next, state.Generators do
            if data.highlight and data.highlight.Parent then
                local pos = genPosition(gen)
                if not hp or not pos then
                    data.highlight.Enabled = not data.complete
                else
                    local dist = (hp - pos).Magnitude
                    data.highlight.Enabled = not data.complete and dist <= maxD
                end
            end
        end
        GenESP.reconcileHighlights(state, settings)
    end)
    state.addCoreConnection(DistConn)
end

function GenESP.stopDistanceLoop()
    if DistConn then
        DistConn:Disconnect()
        DistConn = nil
    end
end

function GenESP.enable(state, settings)
    for gen, data in next, state.Generators do
        if not data.complete then GenESP.addHighlight(gen, state, settings) end
    end
    GenESP.startDistanceLoop(state, settings)
end

function GenESP.disable(state)
    GenESP.stopDistanceLoop()
    for gen in next, state.Generators do
        GenESP.removeHighlight(gen, state)
    end
end

function GenESP.cleanup(state)
    GenESP.stopDistanceLoop()
    pcall(function()
        local maps = workspace:FindFirstChild("MAPS")
        if maps then
            local gm = maps:FindFirstChild("GAME MAP")
            if gm then
                local gens = gm:FindFirstChild("Generators")
                if gens then
                    for _, gen in next, gens:GetChildren() do
                        for _, desc in next, gen:GetDescendants() do
                            if desc:IsA("Highlight") and desc.Name == "GenESP" then
                                desc:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end)
end

return GenESP
