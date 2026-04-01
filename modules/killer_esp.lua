local Helpers, Logger = ...

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local V2New = Helpers.V2New
local V3New = Helpers.V3New
local mathFloor = Helpers.mathFloor

local KillerESP = {}

local Drawings = {}
local RenderConn = nil

function KillerESP.createDrawings(killerModel, settings)
    if Drawings[killerModel] then return end

    local color = Helpers.getKillerColor(settings)

    local boxOutline = {}
    local boxLines = {}
    for i = 1, 4 do
        local outline = Drawing.new("Line")
        outline.Visible = false
        outline.Color = Color3.new(0, 0, 0)
        outline.Thickness = settings.KillerBoxThickness + 2
        outline.Transparency = 1
        boxOutline[i] = outline

        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = color
        line.Thickness = settings.KillerBoxThickness
        line.Transparency = 1
        boxLines[i] = line
    end

    local tracerOutline = Drawing.new("Line")
    tracerOutline.Visible = false
    tracerOutline.Color = Color3.new(0, 0, 0)
    tracerOutline.Thickness = settings.KillerTracerThickness + 2
    tracerOutline.Transparency = 1

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = color
    tracer.Thickness = settings.KillerTracerThickness
    tracer.Transparency = 1

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = color
    nameText.Size = settings.KillerTextSize
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Font = 2
    nameText.Text = killerModel.Name

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = color
    distText.Size = settings.KillerTextSize - 2
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Font = 2
    distText.Text = ""

    Drawings[killerModel] = {
        boxLines = boxLines,
        boxOutline = boxOutline,
        tracer = tracer,
        tracerOutline = tracerOutline,
        nameText = nameText,
        distText = distText,
    }

    Logger.log("Killer drawings created for", killerModel.Name)
end

local function hideDrawings(data)
    for _, line in next, data.boxLines do line.Visible = false end
    for _, line in next, data.boxOutline do line.Visible = false end
    data.tracer.Visible = false
    data.tracerOutline.Visible = false
    data.nameText.Visible = false
    data.distText.Visible = false
end

function KillerESP.destroyDrawings(killerModel)
    local data = Drawings[killerModel]
    if not data then return end

    for _, line in next, data.boxLines do line:Remove() end
    for _, line in next, data.boxOutline do line:Remove() end
    data.tracer:Remove()
    data.tracerOutline:Remove()
    data.nameText:Remove()
    data.distText:Remove()

    Drawings[killerModel] = nil
    Logger.log("Killer drawings destroyed for", killerModel.Name)
end

function KillerESP.destroyAll()
    for model in next, Drawings do
        KillerESP.destroyDrawings(model)
    end
end

local function updateRender(state, settings)
    local Camera = workspace.CurrentCamera
    local WTVP = Camera.WorldToViewportPoint
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local viewportSize = Camera.ViewportSize

    for model, data in next, Drawings do
        local shouldDraw = false
        local dist, rootPos, rootOnScreen, topScreen, bottomScreen

        if state.KillerESP then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                dist = localRoot and (localRoot.Position - root.Position).Magnitude or 0
                if dist <= settings.KillerMaxDistance then
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

        if not shouldDraw then
            hideDrawings(data)
        else
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

            local color = Helpers.getKillerColor(settings)

            local showBox = settings.KillerBox
            data.boxOutline[1].From = topLeft;  data.boxOutline[1].To = topRight
            data.boxLines[1].From = topLeft;    data.boxLines[1].To = topRight
            data.boxOutline[2].From = topRight; data.boxOutline[2].To = bottomRight
            data.boxLines[2].From = topRight;   data.boxLines[2].To = bottomRight
            data.boxOutline[3].From = bottomRight; data.boxOutline[3].To = bottomLeft
            data.boxLines[3].From = bottomRight;    data.boxLines[3].To = bottomLeft
            data.boxOutline[4].From = bottomLeft;   data.boxOutline[4].To = topLeft
            data.boxLines[4].From = bottomLeft;     data.boxLines[4].To = topLeft

            for i = 1, 4 do
                data.boxOutline[i].Visible = showBox
                data.boxOutline[i].Thickness = settings.KillerBoxThickness + 2
                data.boxLines[i].Visible = showBox
                data.boxLines[i].Color = color
                data.boxLines[i].Thickness = settings.KillerBoxThickness
            end

            local showTracer = settings.KillerTracer
            local tracerFrom = V2New(viewportSize.X / 2, viewportSize.Y)
            local tracerTo = V2New(rootPos.X, boxBottom)

            data.tracerOutline.From = tracerFrom
            data.tracerOutline.To = tracerTo
            data.tracerOutline.Visible = showTracer
            data.tracerOutline.Thickness = settings.KillerTracerThickness + 2

            data.tracer.From = tracerFrom
            data.tracer.To = tracerTo
            data.tracer.Visible = showTracer
            data.tracer.Color = color
            data.tracer.Thickness = settings.KillerTracerThickness

            local showName = settings.KillerName
            data.nameText.Position = V2New(rootPos.X, boxTop - settings.KillerTextSize - 4)
            data.nameText.Text = model.Name
            data.nameText.Color = color
            data.nameText.Size = settings.KillerTextSize
            data.nameText.Visible = showName

            local showDist = settings.KillerDistance
            data.distText.Position = V2New(rootPos.X, boxBottom + 2)
            data.distText.Text = mathFloor(dist) .. " studs"
            data.distText.Color = color
            data.distText.Size = settings.KillerTextSize - 2
            data.distText.Visible = showDist
        end
    end
end

function KillerESP.startRender(state, settings)
    if RenderConn then return end
    RenderConn = RunService.RenderStepped:Connect(function()
        updateRender(state, settings)
    end)
    state.addCoreConnection(RenderConn)
    Logger.log("Killer render loop started")
end

function KillerESP.stopRender()
    if RenderConn then
        RenderConn:Disconnect()
        RenderConn = nil
    end
    for _, data in next, Drawings do
        hideDrawings(data)
    end
    Logger.log("Killer render loop stopped")
end

function KillerESP.getDrawings()
    return Drawings
end

return KillerESP
