local Logger = ...

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local ObjectiveESP = {}

local Highlights = {}
local FuseKeys = {}
local BatteryKeys = {}
local UpdateConn = nil
local DescConn = nil

local function inLivingCharacter(inst)
    local hum = inst:FindFirstAncestorWhichIsA("Humanoid")
    return hum ~= nil
end

local function nameFuseCandidate(name)
    local n = name:lower()
    if n:find("fusebox", 1, true) then return true end
    if n:find("fuse", 1, true) and n:find("box", 1, true) then return true end
    return false
end

local function nameBatteryCandidate(name)
    local n = name:lower()
    if not n:find("battery", 1, true) then return false end
    if n:find("hud", 1, true) or n:find("gui", 1, true) then return false end
    return true
end

local function batteryAdornee(inst)
    if inst:IsA("Model") then return inst end
    if inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle")
        if h and h:IsA("BasePart") then return h end
    end
    return nil
end

function ObjectiveESP.playerHasBatteryEquipped()
    local ch = LocalPlayer.Character
    if not ch then return false end
    for _, t in ch:GetChildren() do
        if t:IsA("Tool") then
            if nameBatteryCandidate(t.Name) then return true end
        end
    end
    return false
end

local function destroyHighlight(h)
    if h and h.Parent then h:Destroy() end
end

local function addHighlightKey(adornee, key, kind, parent)
    if Highlights[key] then return end
    local h = Instance.new("Highlight")
    h.Name = "ObjectiveESP_" .. kind
    h.Adornee = adornee
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = 0.65
    h.OutlineTransparency = 0.2
    h.Parent = parent or workspace
    Highlights[key] = h
    if kind == "fuse" then
        FuseKeys[key] = true
    else
        BatteryKeys[key] = true
    end
end

local function tryRegister(inst)
    if inLivingCharacter(inst) then return end
    if inst:IsA("Model") and nameFuseCandidate(inst.Name) then
        addHighlightKey(inst, inst:GetFullName(), "fuse", inst)
        return
    end
    if inst:IsA("Model") and nameBatteryCandidate(inst.Name) then
        addHighlightKey(inst, inst:GetFullName(), "battery", inst)
        return
    end
    if inst:IsA("Tool") and nameBatteryCandidate(inst.Name) then
        local ad = batteryAdornee(inst)
        if ad then
            addHighlightKey(ad, inst:GetFullName(), "battery", inst)
        end
    end
end

local function scanMap(root)
    for _, d in root:GetDescendants() do
        tryRegister(d)
    end
end

local function applyVisibility(settings)
    local maxD = settings.ObjectiveMaxDistance or settings.GenMaxDistance or 8000
    local hp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hpPos = hp and hp.Position

    local fuseOn = settings.FuseboxESP == true
    local batOn = settings.BatteryESP == true
    local needBat = settings.FuseboxOnlyWithBattery ~= false
    local hasBat = ObjectiveESP.playerHasBatteryEquipped()

    for key, hl in next, Highlights do
        if not hl.Parent then
            Highlights[key] = nil
            FuseKeys[key] = nil
            BatteryKeys[key] = nil
        else
            local ad = hl.Adornee
            if not ad or not ad.Parent then
                pcall(function() hl:Destroy() end)
                Highlights[key] = nil
                FuseKeys[key] = nil
                BatteryKeys[key] = nil
            else
            local pos = nil
            if ad and ad:IsA("Model") then
                if ad.PrimaryPart then
                    pos = ad.PrimaryPart.Position
                else
                    local ok, p = pcall(function()
                        return ad:GetPivot().Position
                    end)
                    if ok then pos = p end
                end
            elseif ad and ad:IsA("BasePart") then
                pos = ad.Position
            end
            local distOk = true
            if hpPos and pos then
                distOk = (hpPos - pos).Magnitude <= maxD
            end

            if FuseKeys[key] then
                local allow = fuseOn and distOk and (not needBat or hasBat)
                hl.Enabled = allow
                hl.FillColor = Color3.fromRGB(255, 200, 80)
                hl.OutlineColor = Color3.fromRGB(255, 240, 200)
            elseif BatteryKeys[key] then
                hl.Enabled = batOn and distOk
                hl.FillColor = Color3.fromRGB(80, 180, 255)
                hl.OutlineColor = Color3.fromRGB(200, 230, 255)
            end
            end
        end
    end
end

function ObjectiveESP.start(gameMap, state, settings)
    ObjectiveESP.stop()
    scanMap(gameMap)

    DescConn = gameMap.DescendantAdded:Connect(function(d)
        task.defer(function()
            tryRegister(d)
        end)
    end)
    state.addRoundConnection(DescConn)

    UpdateConn = RunService.Heartbeat:Connect(function()
        if not state.RoundActive then return end
        applyVisibility(settings)
    end)
    state.addRoundConnection(UpdateConn)

    applyVisibility(settings)
    Logger.log("Objective ESP scan started")
end

function ObjectiveESP.stop()
    if UpdateConn then
        UpdateConn:Disconnect()
        UpdateConn = nil
    end
    if DescConn then
        DescConn:Disconnect()
        DescConn = nil
    end
    for _, h in next, Highlights do
        destroyHighlight(h)
    end
    table.clear(Highlights)
    table.clear(FuseKeys)
    table.clear(BatteryKeys)
end

return ObjectiveESP
