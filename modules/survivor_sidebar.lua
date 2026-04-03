local Logger = ...

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local SurvivorSidebar = {}

local Gui = nil
local List = nil
local Conn = nil
local Rows = {}

local function getAliveFolder()
    local p = workspace:FindFirstChild("PLAYERS")
    return p and p:FindFirstChild("ALIVE")
end

local function ensureGui()
    if Gui then return end
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "GenHub_SurvivorRadar"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 50
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.Position = UDim2.new(0, 8, 0.2, 0)
    panel.Size = UDim2.new(0, 210, 0, 320)
    panel.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 200, 90)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = panel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(0, 255, 120)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "  SURVIVOR STATUS"
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "List"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0, 4, 0, 26)
    scroll.Size = UDim2.new(1, -8, 1, -30)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 4
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = scroll

    Gui = sg
    List = scroll
end

local function createRow(i)
    local f = Instance.new("Frame")
    f.Name = "Row" .. i
    f.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1, -6, 0, 42)
    f.LayoutOrder = i

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = f

    local nm = Instance.new("TextLabel")
    nm.Name = "NameLabel"
    nm.BackgroundTransparency = 1
    nm.Font = Enum.Font.Code
    nm.TextSize = 12
    nm.TextColor3 = Color3.fromRGB(220, 255, 220)
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    nm.Position = UDim2.new(0, 6, 0, 2)
    nm.Size = UDim2.new(1, -12, 0, 14)
    nm.Parent = f

    local hp = Instance.new("TextLabel")
    hp.Name = "HpText"
    hp.BackgroundTransparency = 1
    hp.Font = Enum.Font.Code
    hp.TextSize = 11
    hp.TextColor3 = Color3.fromRGB(160, 255, 160)
    hp.TextXAlignment = Enum.TextXAlignment.Left
    hp.Position = UDim2.new(0, 6, 0, 18)
    hp.Size = UDim2.new(1, -12, 0, 12)
    hp.Parent = f

    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    barBg.BorderSizePixel = 0
    barBg.Position = UDim2.new(0, 6, 1, -8)
    barBg.Size = UDim2.new(1, -12, 0, 5)
    barBg.Parent = f

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 2)
    bc.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
    barFill.BorderSizePixel = 0
    barFill.Size = UDim2.new(0.5, 0, 1, 0)
    barFill.Parent = barBg

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 2)
    fc.Parent = barFill

    f.Parent = List
    return {
        frame = f,
        nameLabel = nm,
        hpText = hp,
        barFill = barFill,
    }
end

local function getOrCreateRow(i)
    if Rows[i] then return Rows[i] end
    Rows[i] = createRow(i)
    return Rows[i]
end

local function hideExtra(from)
    for j = from, 48 do
        if Rows[j] and Rows[j].frame then
            Rows[j].frame.Visible = false
        end
    end
end

function SurvivorSidebar.init(state, settings)
    ensureGui()
    if Conn then return end
    Conn = RunService.Heartbeat:Connect(function()
        if not settings.SurvivorSidebar or not state.RoundActive then
            if Gui then Gui.Enabled = false end
            return
        end
        if Gui then Gui.Enabled = true end

        local folder = getAliveFolder()
        if not folder or not List then return end

        local idx = 0
        for _, m in folder:GetChildren() do
            if m:IsA("Model") then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    idx = idx + 1
                    local row = getOrCreateRow(idx)
                    row.frame.Visible = true
                    local disp = m.Name
                    local plr = Players:GetPlayerFromCharacter(m)
                    if plr then disp = plr.Name end
                    row.nameLabel.Text = disp
                    local pct = 1
                    if hum.MaxHealth > 0 then pct = hum.Health / hum.MaxHealth end
                    pct = math.clamp(pct, 0, 1)
                    row.hpText.Text = string.format("HP %.0f / %.0f", hum.Health, hum.MaxHealth)
                    row.barFill.Size = UDim2.new(pct, 0, 1, 0)
                    if pct > 0.55 then
                        row.barFill.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
                    elseif pct > 0.25 then
                        row.barFill.BackgroundColor3 = Color3.fromRGB(230, 200, 60)
                    else
                        row.barFill.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
                    end
                end
            end
        end
        hideExtra(idx + 1)
    end)
    state.addCoreConnection(Conn)
    Logger.log("Survivor sidebar init")
end

function SurvivorSidebar.destroy()
    if Conn then
        Conn:Disconnect()
        Conn = nil
    end
    Rows = {}
    if Gui then
        Gui:Destroy()
        Gui = nil
        List = nil
    end
end

return SurvivorSidebar
