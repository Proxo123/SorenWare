local Helpers = ...

local GenESP = {}

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
end

function GenESP.removeHighlight(generator, state)
    local data = state.Generators[generator]
    if not data or not data.highlight then return end
    data.highlight:Destroy()
    data.highlight = nil
end

function GenESP.refreshAll(state, settings)
    for _, data in next, state.Generators do
        if data.highlight then
            data.highlight.FillColor = Helpers.getFillColor(settings)
            data.highlight.FillTransparency = settings.FillTransparency
            data.highlight.OutlineColor = Helpers.getOutlineColor(settings)
            data.highlight.OutlineTransparency = settings.OutlineTransparency
        end
    end
end

function GenESP.enable(state, settings)
    for gen, data in next, state.Generators do
        if not data.complete then GenESP.addHighlight(gen, state, settings) end
    end
end

function GenESP.disable(state)
    for gen in next, state.Generators do
        GenESP.removeHighlight(gen, state)
    end
end

function GenESP.cleanup(state)
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
