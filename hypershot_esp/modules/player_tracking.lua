local PlayerESP, Logger = ...

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerTracking = {}
local Conns = {}

function PlayerTracking.stop()
    for _, c in next, Conns do
        if c.Connected then c:Disconnect() end
    end
    table.clear(Conns)
end

function PlayerTracking.start(state, settings)
    PlayerTracking.stop()

    local function hookCharacter(plr, char)
        if plr == LocalPlayer and not settings.ShowSelf then return end
        PlayerESP.createDrawings(char, settings, plr)
    end

    local function attach(plr)
        local c1 = plr.CharacterAdded:Connect(function(char)
            task.defer(function()
                task.wait(0.15)
                hookCharacter(plr, char)
            end)
        end)
        local c2 = plr.CharacterRemoving:Connect(function(char)
            PlayerESP.destroyDrawings(char)
        end)
        table.insert(Conns, c1)
        table.insert(Conns, c2)
        state.addCoreConnection(c1)
        state.addCoreConnection(c2)
        if plr.Character then
            task.defer(function()
                task.wait(0.1)
                hookCharacter(plr, plr.Character)
            end)
        end
    end

    for _, p in Players:GetPlayers() do
        attach(p)
    end

    local cAdd = Players.PlayerAdded:Connect(attach)
    local cRem = Players.PlayerRemoving:Connect(function(plr)
        if plr.Character then
            PlayerESP.destroyDrawings(plr.Character)
        end
    end)
    table.insert(Conns, cAdd)
    table.insert(Conns, cRem)
    state.addCoreConnection(cAdd)
    state.addCoreConnection(cRem)

    Logger.log("Tracking all players (Hypershot / standard characters)")
end

return PlayerTracking
