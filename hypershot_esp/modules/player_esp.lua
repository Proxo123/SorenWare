local Helpers, Logger = ...

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local V2New = Helpers.V2New
local V3New = Helpers.V3New
local mathFloor = Helpers.mathFloor

local PlayerESP = {}
local Drawings = {}
local RenderConn = nil

function PlayerESP.createDrawings(character, settings, player)
    if not character or not player or Drawings[character] then return end
    if player == LocalPlayer and not settings.ShowSelf then return end

    local color = Helpers.getEnemyColor(settings)

    local boxOutline, boxLines = {}, {}
    for i = 1, 4 do
        local outline = Drawing.new("Line")
        outline.Visible = false
        outline.Color = Color3.new(0, 0, 0)
        outline.Thickness = settings.BoxThickness + 2
        outline.Transparency = 1
        boxOutline[i] = outline

        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = color
        line.Thickness = settings.BoxThickness
        line.Transparency = 1
        boxLines[i] = line
    end

    local tracerOutline = Drawing.new("Line")
    tracerOutline.Visible = false
    tracerOutline.Color = Color3.new(0, 0, 0)
    tracerOutline.Thickness = settings.TracerThickness + 2
    tracerOutline.Transparency = 1

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = color
    tracer.Thickness = settings.TracerThickness
    tracer.Transparency = 1

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = color
    nameText.Size = settings.TextSize
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Font = 2
    nameText.Text = player.DisplayName

    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = color
    healthText.Size = settings.TextSize - 2
    healthText.Center = true
    healthText.Outline = true
    healthText.OutlineColor = Color3.new(0, 0, 0)
    healthText.Font = 2
    healthText.Text = ""

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = color
    distText.Size = settings.TextSize - 2
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Font = 2
    distText.Text = ""

    Drawings[character] = {
        boxLines = boxLines,
        boxOutline = boxOutline,
        tracer = tracer,
        tracerOutline = tracerOutline,
        nameText = nameText,
        healthText = healthText,
        distText = distText,
        player = player,
    }

    Logger.log("ESP drawings for", player.Name)
end

local function hideDrawings(data)
    for _, line in next, data.boxLines do line.Visible = false end
    for _, line in next, data.boxOutline do line.Visible = false end
    data.tracer.Visible = false
    data.tracerOutline.Visible = false
    data.nameText.Visible = false
    data.healthText.Visible = false
    data.distText.Visible = false
end

function PlayerESP.destroyDrawings(character)
    local data = Drawings[character]
    if not data then return end
    for _, line in next, data.boxLines do line:Remove() end
    for _, line in next, data.boxOutline do line:Remove() end
    data.tracer:Remove()
    data.tracerOutline:Remove()
    data.nameText:Remove()
    data.healthText:Remove()
    data.distText:Remove()
    Drawings[character] = nil
end

function PlayerESP.destroyAll()
    for char in next, Drawings do
        PlayerESP.destroyDrawings(char)
    end
end

local function getHumanoid(model)
    return model:FindFirstChildWhichIsA("Humanoid")
end

local function updateRender(state, settings)
    local Camera = workspace.CurrentCamera
    if not Camera then return end
    local WTVP = Camera.WorldToViewportPoint
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local viewportSize = Camera.ViewportSize

    for model, data in next, Drawings do
        local plr = data.player
        local shouldDraw = false
        local dist, rootPos, rootOnScreen, topScreen, bottomScreen

        if state.PlayerESP and model.Parent and plr and plr.Parent then
            if settings.TeamCheck and Helpers.sameTeam(LocalPlayer, plr) then
                shouldDraw = false
            else
                local hum = getHumanoid(model)
                if settings.HideDead and hum and hum.Health <= 0 then
                    shouldDraw = false
                else
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root then
                        dist = localRoot and (localRoot.Position - root.Position).Magnitude or 0
                        if dist <= settings.MaxDistance then
                            rootPos, rootOnScreen = WTVP(Camera, root.Position)
                            if rootOnScreen and rootPos.Z > 0 then
                                local ok, cf, size = pcall(model.GetBoundingBox, model)
                                if ok and cf then
                                    local halfY = size.Y / 2
                                    topScreen = WTVP(Camera, cf.Position + V3New(0, halfY, 0))
                                    bottomScreen = WTVP(Camera, cf.Position - V3New(0, halfY, 0))
                                    shouldDraw = true
                                end
                            end
                        end
                    end
                end
            end
        end

        if not shouldDraw then
            hideDrawings(data)
        else
            local isEnemy = not Helpers.sameTeam(LocalPlayer, plr)
            local color = isEnemy and Helpers.getEnemyColor(settings) or Helpers.getTeammateColor(settings)

            local boxHeight = math.abs(topScreen.Y - bottomScreen.Y)
            if boxHeight < 10 then boxHeight = 10 end
            local boxWidth = boxHeight * 0.6
            local boxTop = math.min(topScreen.Y, bottomScreen.Y)
            local boxBottom = math.max(topScreen.Y, bottomScreen.Y)
            local boxLeft = rootPos.X - boxWidth / 2
            local boxRight = rootPos.X + boxWidth / 2

            local topLeft = V2New(boxLeft, boxTop)
            local topRight = V2New(boxRight, boxTop)
            local bottomLeft = V2New(boxLeft, boxBottom)
            local bottomRight = V2New(boxRight, boxBottom)

            local ts = settings.TextSize

            if settings.Box then
                data.boxOutline[1].From = topLeft
                data.boxOutline[1].To = topRight
                data.boxLines[1].From = topLeft
                data.boxLines[1].To = topRight
                data.boxOutline[2].From = topRight
                data.boxOutline[2].To = bottomRight
                data.boxLines[2].From = topRight
                data.boxLines[2].To = bottomRight
                data.boxOutline[3].From = bottomRight
                data.boxOutline[3].To = bottomLeft
                data.boxLines[3].From = bottomRight
                data.boxLines[3].To = bottomLeft
                data.boxOutline[4].From = bottomLeft
                data.boxOutline[4].To = topLeft
                data.boxLines[4].From = bottomLeft
                data.boxLines[4].To = topLeft
                for i = 1, 4 do
                    data.boxOutline[i].Visible = true
                    data.boxOutline[i].Thickness = settings.BoxThickness + 2
                    data.boxLines[i].Visible = true
                    data.boxLines[i].Color = color
                    data.boxLines[i].Thickness = settings.BoxThickness
                end
            else
                for i = 1, 4 do
                    data.boxOutline[i].Visible = false
                    data.boxLines[i].Visible = false
                end
            end

            if settings.Tracer then
                local tracerFrom = V2New(viewportSize.X / 2, viewportSize.Y)
                local tracerTo = V2New(rootPos.X, boxBottom)
                data.tracerOutline.From = tracerFrom
                data.tracerOutline.To = tracerTo
                data.tracerOutline.Visible = true
                data.tracerOutline.Thickness = settings.TracerThickness + 2
                data.tracer.From = tracerFrom
                data.tracer.To = tracerTo
                data.tracer.Visible = true
                data.tracer.Color = color
                data.tracer.Thickness = settings.TracerThickness
            else
                data.tracer.Visible = false
                data.tracerOutline.Visible = false
            end

            if settings.Name then
                data.nameText.Position = V2New(rootPos.X, boxTop - ts * 2 - 6)
                data.nameText.Text = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
                data.nameText.Color = color
                data.nameText.Size = ts
                data.nameText.Visible = true
            else
                data.nameText.Visible = false
            end

            local hum = getHumanoid(model)
            local hpStr = ""
            if hum and settings.HealthText then
                hpStr = mathFloor(hum.Health) .. " / " .. mathFloor(hum.MaxHealth)
            end
            if settings.HealthText and hpStr ~= "" and settings.Name then
                data.healthText.Position = V2New(rootPos.X, boxTop - ts - 2)
                data.healthText.Text = hpStr
                data.healthText.Color = color
                data.healthText.Size = ts - 2
                data.healthText.Visible = true
            elseif settings.HealthText and hpStr ~= "" then
                data.healthText.Position = V2New(rootPos.X, boxTop - ts - 4)
                data.healthText.Text = hpStr
                data.healthText.Color = color
                data.healthText.Size = ts - 2
                data.healthText.Visible = true
            else
                data.healthText.Visible = false
            end

            if settings.Distance then
                data.distText.Position = V2New(rootPos.X, boxBottom + 2)
                data.distText.Text = mathFloor(dist) .. " studs"
                data.distText.Color = color
                data.distText.Size = ts - 2
                data.distText.Visible = true
            else
                data.distText.Visible = false
            end
        end
    end
end

function PlayerESP.startRender(state, settings)
    if RenderConn then return end
    RenderConn = RunService.RenderStepped:Connect(function()
        updateRender(state, settings)
    end)
    state.addCoreConnection(RenderConn)
    Logger.log("Render started")
end

function PlayerESP.stopRender()
    if RenderConn then
        RenderConn:Disconnect()
        RenderConn = nil
    end
    for _, data in next, Drawings do
        hideDrawings(data)
    end
end

return PlayerESP
