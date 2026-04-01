--[[
    SorenUI — Custom Glassmorphism UI Library
    Built for SorenWare / Velocity executor
    Style: Frosted glass panels, purple accent, smooth animations
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════

local Theme = {
    Background      = Color3.fromRGB(16, 14, 22),
    Panel           = Color3.fromRGB(28, 24, 40),
    PanelLighter    = Color3.fromRGB(36, 31, 52),
    Sidebar         = Color3.fromRGB(22, 19, 32),
    Element         = Color3.fromRGB(34, 30, 48),
    ElementHover    = Color3.fromRGB(44, 39, 62),
    Accent          = Color3.fromRGB(139, 92, 246),
    AccentHover     = Color3.fromRGB(160, 120, 255),
    AccentDark      = Color3.fromRGB(100, 60, 200),
    Text            = Color3.fromRGB(235, 235, 240),
    TextSec         = Color3.fromRGB(150, 148, 165),
    TextDark        = Color3.fromRGB(95, 93, 110),
    ToggleOff       = Color3.fromRGB(55, 50, 72),
    SliderBg        = Color3.fromRGB(42, 38, 58),
    Border          = Color3.fromRGB(255, 255, 255),
    BorderTrans     = 0.88,
    NotifInfo       = Color3.fromRGB(59, 130, 246),
    NotifSuccess    = Color3.fromRGB(34, 197, 94),
    NotifWarn       = Color3.fromRGB(245, 158, 11),
    NotifError      = Color3.fromRGB(239, 68, 68),
    Corner          = UDim.new(0, 8),
    CornerLg        = UDim.new(0, 12),
    CornerSm        = UDim.new(0, 6),
    CornerPill       = UDim.new(0, 999),
    SidebarW        = 155,
    TitleH          = 38,
    SearchH         = 30,
    ElemH           = 34,
    ElemPad         = 4,
    Anim            = 0.22,
    AnimFast        = 0.14,
    AnimSlow        = 0.32,
}

-- ═══════════════════════════════════════════════════════════
-- ANIMATION
-- ═══════════════════════════════════════════════════════════

local Anim = {}

function Anim.tween(inst, props, dur, style, dir)
    local tw = TweenService:Create(inst,
        TweenInfo.new(dur or Theme.Anim, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.InOut),
        props)
    tw:Play()
    return tw
end

function Anim.smooth(inst, props, dur)
    return Anim.tween(inst, props, dur or Theme.Anim)
end

function Anim.snap(inst, props, dur)
    return Anim.tween(inst, props, dur or Theme.AnimFast, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

function Anim.linear(inst, props, dur)
    return Anim.tween(inst, props, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
end

-- ═══════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════

local U = {}

function U.new(cls, props)
    local inst = Instance.new(cls)
    for k, v in next, props do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

function U.corner(f, r) return U.new("UICorner", { CornerRadius = r or Theme.Corner, Parent = f }) end
function U.stroke(f, c, t, th) return U.new("UIStroke", { Color = c or Theme.Border, Transparency = t or Theme.BorderTrans, Thickness = th or 1, Parent = f }) end
function U.padding(f, t, r, b, l)
    return U.new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or r or t or 0),
        Parent = f,
    })
end
function U.list(f, pad, dir, hAlign, sort)
    return U.new("UIListLayout", {
        Padding = UDim.new(0, pad or Theme.ElemPad),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        SortOrder = sort or Enum.SortOrder.LayoutOrder,
        Parent = f,
    })
end

function U.glass(f, trans)
    f.BackgroundTransparency = trans or 0.08
    U.corner(f)
    U.stroke(f)
    U.new("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 210, 220)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.96),
            NumberSequenceKeypoint.new(1, 0.99),
        }),
        Rotation = 145,
        Parent = f,
    })
end

function U.guiParent()
    local ok, r = pcall(function() if gethui then return gethui() end end)
    if ok and r then return r end
    ok, r = pcall(function() return game:GetService("CoreGui") end)
    if ok and r then return r end
    return LocalPlayer:WaitForChild("PlayerGui")
end

function U.protect(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
end

function U.rgbToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local h, s, v = 0, 0, mx
    local d = mx - mn
    s = mx == 0 and 0 or d / mx
    if mx ~= mn then
        if mx == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, v
end

function U.hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r, g, b)
end

function U.colorToHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

function U.autoCanvas(scroll, layout, extra)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 10))
    end)
end

function U.hover(frame, onColor, offColor)
    frame.MouseEnter:Connect(function()
        Anim.snap(frame, { BackgroundColor3 = onColor or Theme.ElementHover })
    end)
    frame.MouseLeave:Connect(function()
        Anim.snap(frame, { BackgroundColor3 = offColor or Theme.Element })
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SORENUI LIBRARY
-- ═══════════════════════════════════════════════════════════

local SorenUI = {}
SorenUI._windows = {}

function SorenUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "SorenUI"
    local size = config.Size or UDim2.fromOffset(560, 420)
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightControl

    local win = {}
    win._tabs = {}
    win._activeTab = nil
    win._connections = {}
    win._minimized = false
    win._visible = true
    win._elements = {}

    local function conn(c) table.insert(win._connections, c) return c end

    -- ScreenGui
    local screenGui = U.new("ScreenGui", {
        Name = "SorenUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = U.guiParent(),
    })
    U.protect(screenGui)
    win._gui = screenGui

    -- Notification container (separate from main window)
    local notifHolder = U.new("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 280, 1, -32),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    win._notifHolder = notifHolder
    win._activeNotifs = {}

    -- ─── MAIN FRAME ───
    local main = U.new("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    U.glass(main, 0.04)
    U.corner(main, Theme.CornerLg)
    win._main = main

    -- open animation
    main.BackgroundTransparency = 1
    main.Size = UDim2.new(size.X.Scale, size.X.Offset - 20, size.Y.Scale, size.Y.Offset - 20)
    task.defer(function()
        Anim.smooth(main, { BackgroundTransparency = 0.04, Size = size }, Theme.AnimSlow)
    end)

    -- ─── TITLE BAR ───
    local titleBar = U.new("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, Theme.TitleH),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.3,
        Parent = main,
    })
    U.new("UICorner", { CornerRadius = Theme.CornerLg, Parent = titleBar })

    local titleLabel = U.new("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    -- accent dot next to title
    U.new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, 6, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Accent,
        Parent = titleBar,
    })
    titleLabel.Position = UDim2.new(0, 18, 0, 0)

    -- minimize button
    local minimizeBtn = U.new("TextButton", {
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.TextSec,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(Theme.TitleH, Theme.TitleH),
        Position = UDim2.new(1, -Theme.TitleH * 2, 0, 0),
        Parent = titleBar,
    })

    -- close button
    local closeBtn = U.new("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Theme.TextSec,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(Theme.TitleH, Theme.TitleH),
        Position = UDim2.new(1, -Theme.TitleH, 0, 0),
        Parent = titleBar,
    })

    -- button hover effects
    conn(minimizeBtn.MouseEnter:Connect(function() Anim.snap(minimizeBtn, { TextColor3 = Theme.Text }) end))
    conn(minimizeBtn.MouseLeave:Connect(function() Anim.snap(minimizeBtn, { TextColor3 = Theme.TextSec }) end))
    conn(closeBtn.MouseEnter:Connect(function() Anim.snap(closeBtn, { TextColor3 = Theme.NotifError }) end))
    conn(closeBtn.MouseLeave:Connect(function() Anim.snap(closeBtn, { TextColor3 = Theme.TextSec }) end))

    -- ─── DRAG ───
    local dragging, dragStart, startPos = false, nil, nil
    conn(titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end))
    conn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    -- ─── BODY (sidebar + content) ───
    local body = U.new("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, Theme.TitleH),
        Size = UDim2.new(1, 0, 1, -Theme.TitleH),
        BackgroundTransparency = 1,
        Parent = main,
    })

    -- sidebar
    local sidebar = U.new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, Theme.SidebarW, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = body,
    })
    U.new("UICorner", { CornerRadius = UDim.new(0, 0), Parent = sidebar })

    -- divider line between sidebar and content
    U.new("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = Theme.BorderTrans,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    -- ─── SEARCH BAR ───
    local searchContainer = U.new("Frame", {
        Size = UDim2.new(1, -12, 0, Theme.SearchH),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = Theme.Element,
        Parent = sidebar,
    })
    U.corner(searchContainer, Theme.CornerSm)

    local searchIcon = U.new("TextLabel", {
        Text = "🔍",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.TextDark,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(24, Theme.SearchH),
        Position = UDim2.new(0, 4, 0, 0),
        Parent = searchContainer,
    })

    local searchBox = U.new("TextBox", {
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.TextDark,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -52, 1, 0),
        Position = UDim2.new(0, 28, 0, 0),
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchContainer,
    })

    local searchClear = U.new("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.TextDark,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(20, Theme.SearchH),
        Position = UDim2.new(1, -22, 0, 0),
        Visible = false,
        Parent = searchContainer,
    })

    local function applySearch(query)
        query = query:lower()
        searchClear.Visible = query ~= ""
        local tab = win._activeTab
        if not tab then return end
        for _, elem in next, tab._elements do
            if query == "" then
                elem.frame.Visible = true
            else
                elem.frame.Visible = elem.name:lower():find(query, 1, true) ~= nil
            end
        end
    end

    conn(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applySearch(searchBox.Text)
    end))
    conn(searchClear.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        applySearch("")
    end))

    -- ─── TAB BUTTONS AREA ───
    local tabScroll = U.new("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, Theme.SearchH + 16),
        Size = UDim2.new(1, 0, 1, -(Theme.SearchH + 16)),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    local tabListLayout = U.list(tabScroll, 2, nil, Enum.HorizontalAlignment.Center)
    U.padding(tabScroll, 4, 6, 4, 6)
    U.autoCanvas(tabScroll, tabListLayout, 8)

    -- active tab indicator (purple bar)
    local tabIndicator = U.new("Frame", {
        Size = UDim2.new(0, 3, 0, 24),
        Position = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 5,
        Parent = tabScroll,
    })
    U.corner(tabIndicator, Theme.CornerPill)
    tabIndicator.Visible = false

    -- ─── CONTENT AREA ───
    local contentArea = U.new("Frame", {
        Name = "Content",
        Position = UDim2.new(0, Theme.SidebarW, 0, 0),
        Size = UDim2.new(1, -Theme.SidebarW, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = body,
    })

    -- ─── MINIMIZED PILL ───
    local pill = U.new("TextButton", {
        Name = "MinPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 12),
        Size = UDim2.fromOffset(160, 30),
        BackgroundColor3 = Theme.Panel,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Parent = screenGui,
    })
    U.glass(pill, 0.1)
    U.corner(pill, Theme.CornerPill)

    U.new("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Accent,
        Parent = pill,
    })
    U.new("UICorner", { CornerRadius = Theme.CornerPill, Parent = pill:FindFirstChild("Frame") })

    U.new("TextLabel", {
        Text = title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = pill,
    })

    -- ─── WINDOW METHODS ───

    function win:Minimize()
        win._minimized = true
        Anim.smooth(main, { Size = UDim2.fromOffset(size.X.Offset - 20, size.Y.Offset - 20), BackgroundTransparency = 1 }, Theme.Anim)
        task.delay(Theme.Anim, function() main.Visible = false end)
        pill.Visible = true
        pill.Position = UDim2.new(0.5, 0, 0, -40)
        Anim.smooth(pill, { Position = UDim2.new(0.5, 0, 0, 12) })
    end

    function win:Restore()
        win._minimized = false
        pill.Visible = false
        main.Visible = true
        main.BackgroundTransparency = 1
        main.Size = UDim2.fromOffset(size.X.Offset - 20, size.Y.Offset - 20)
        Anim.smooth(main, { Size = size, BackgroundTransparency = 0.04 }, Theme.AnimSlow)
    end

    function win:Toggle()
        if win._minimized then
            win:Restore()
        else
            win:Minimize()
        end
    end

    conn(minimizeBtn.MouseButton1Click:Connect(function() win:Minimize() end))
    conn(closeBtn.MouseButton1Click:Connect(function()
        if config.CloseCallback then config.CloseCallback() end
        win:Destroy()
    end))
    conn(pill.MouseButton1Click:Connect(function() win:Restore() end))

    -- toggle key
    conn(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            if main.Visible then win:Minimize() else win:Restore() end
        end
    end))

    -- ─── TAB SWITCHING ───
    local function switchTab(tab)
        if win._activeTab == tab then return end

        searchBox.Text = ""
        applySearch("")

        if win._activeTab then
            local old = win._activeTab
            Anim.snap(old._btn, { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1 })
            Anim.snap(old._btnLabel, { TextColor3 = Theme.TextSec })
            old._scroll.Visible = false
        end

        win._activeTab = tab
        Anim.snap(tab._btn, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85 })
        Anim.snap(tab._btnLabel, { TextColor3 = Theme.Text })
        tab._scroll.Visible = true

        -- animate indicator
        tabIndicator.Visible = true
        local btnPos = tab._btn.AbsolutePosition
        local scrollPos = tabScroll.AbsolutePosition
        local yOff = btnPos.Y - scrollPos.Y + (tab._btn.AbsoluteSize.Y / 2) - 12
        Anim.smooth(tabIndicator, { Position = UDim2.new(0, 0, 0, yOff) })
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB CREATION
    -- ═══════════════════════════════════════════════════════

    function win:CreateTab(cfg)
        cfg = cfg or {}
        local tabName = cfg.Name or "Tab"
        local icon = cfg.Icon

        local tab = {}
        tab._elements = {}
        tab._order = 0

        -- tab button
        local btn = U.new("TextButton", {
            Name = tabName,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = #win._tabs,
            Parent = tabScroll,
        })
        U.corner(btn, Theme.CornerSm)
        tab._btn = btn

        local btnLayout = U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = btn,
        })
        U.padding(btn, 0, 8, 0, 10)

        if icon then
            U.new("ImageLabel", {
                Image = icon,
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.TextSec,
                LayoutOrder = 0,
                Parent = btn,
            })
        end

        local btnLabel = U.new("TextLabel", {
            Text = tabName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = Theme.TextSec,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, icon and -22 or 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = btn,
        })
        tab._btnLabel = btnLabel

        -- hover
        conn(btn.MouseEnter:Connect(function()
            if win._activeTab ~= tab then
                Anim.snap(btn, { BackgroundTransparency = 0.9, BackgroundColor3 = Theme.ElementHover })
            end
        end))
        conn(btn.MouseLeave:Connect(function()
            if win._activeTab ~= tab then
                Anim.snap(btn, { BackgroundTransparency = 1 })
            end
        end))

        -- content scroll frame
        local scroll = U.new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            Visible = false,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Parent = contentArea,
        })
        local scrollLayout = U.list(scroll, Theme.ElemPad)
        U.padding(scroll, 8, 10, 12, 10)
        U.autoCanvas(scroll, scrollLayout, 20)
        tab._scroll = scroll

        conn(btn.MouseButton1Click:Connect(function() switchTab(tab) end))

        table.insert(win._tabs, tab)

        if #win._tabs == 1 then
            task.defer(function() switchTab(tab) end)
        end

        -- ═══════════════════════════════════════════════
        -- COMPONENT HELPERS
        -- ═══════════════════════════════════════════════

        local function nextOrder()
            tab._order = tab._order + 1
            return tab._order
        end

        local function registerElement(name, frame)
            table.insert(tab._elements, { name = name, frame = frame })
        end

        -- ─── SECTION ───
        function tab:CreateSection(name)
            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })

            U.new("TextLabel", {
                Text = name:upper(),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = Theme.TextDark,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 2, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            U.new("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                Parent = f,
            })

            return f
        end

        -- ─── TOGGLE ───
        function tab:CreateToggle(cfg)
            cfg = cfg or {}
            local toggled = cfg.Default or false
            local callback = cfg.Callback or function() end
            local toggleObj = {}

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, Theme.ElemH),
                BackgroundColor3 = Theme.Element,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            U.hover(f)
            registerElement(cfg.Name or "Toggle", f)

            U.new("TextLabel", {
                Text = cfg.Name or "Toggle",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            local switchBg = U.new("Frame", {
                Size = UDim2.fromOffset(38, 20),
                Position = UDim2.new(1, -48, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff,
                Parent = f,
            })
            U.corner(switchBg, Theme.CornerPill)

            local knob = U.new("Frame", {
                Size = UDim2.fromOffset(16, 16),
                Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Text,
                Parent = switchBg,
            })
            U.corner(knob, Theme.CornerPill)

            local function updateVisual()
                Anim.smooth(switchBg, { BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff }, Theme.AnimFast)
                Anim.smooth(knob, { Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, Theme.AnimFast)
            end

            conn(f.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggled = not toggled
                    updateVisual()
                    pcall(callback, toggled)
                end
            end))

            function toggleObj:Set(val)
                if toggled == val then return end
                toggled = val
                updateVisual()
            end

            function toggleObj:Get() return toggled end

            return toggleObj
        end

        -- ─── SLIDER ───
        function tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local default = cfg.Default or min
            local increment = cfg.Increment or 1
            local suffix = cfg.Suffix or ""
            local callback = cfg.Callback or function() end
            local value = default
            local sliderObj = {}

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, Theme.ElemH + 16),
                BackgroundColor3 = Theme.Element,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            registerElement(cfg.Name or "Slider", f)

            U.new("TextLabel", {
                Text = cfg.Name or "Slider",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.new(0, 10, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            local valLabel = U.new("TextLabel", {
                Text = tostring(value) .. suffix,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.TextSec,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -56, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = f,
            })

            local barBg = U.new("Frame", {
                Size = UDim2.new(1, -20, 0, 8),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundColor3 = Theme.SliderBg,
                Parent = f,
            })
            U.corner(barBg, Theme.CornerPill)

            local barFill = U.new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = barBg,
            })
            U.corner(barFill, Theme.CornerPill)

            local barKnob = U.new("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.Text,
                ZIndex = 2,
                Parent = barBg,
            })
            U.corner(barKnob, Theme.CornerPill)

            local function update(val, fireCallback)
                val = math.clamp(val, min, max)
                val = math.floor(val / increment + 0.5) * increment
                val = math.clamp(val, min, max)
                if increment >= 1 then val = math.floor(val) end
                value = val
                local pct = (value - min) / (max - min)
                barFill.Size = UDim2.new(pct, 0, 1, 0)
                barKnob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLabel.Text = tostring(value) .. suffix
                if fireCallback ~= false then pcall(callback, value) end
            end

            local sliding = false
            local function beginSlide(input)
                sliding = true
                local barAbs = barBg.AbsolutePosition
                local barSize = barBg.AbsoluteSize
                local rel = math.clamp((input.Position.X - barAbs.X) / barSize.X, 0, 1)
                update(min + rel * (max - min))

                local moveConn, upConn
                moveConn = UserInputService.InputChanged:Connect(function(mv)
                    if mv.UserInputType == Enum.UserInputType.MouseMovement or mv.UserInputType == Enum.UserInputType.Touch then
                        rel = math.clamp((mv.Position.X - barAbs.X) / barSize.X, 0, 1)
                        update(min + rel * (max - min))
                    end
                end)
                upConn = UserInputService.InputEnded:Connect(function(up)
                    if up.UserInputType == Enum.UserInputType.MouseButton1 or up.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                        if moveConn then moveConn:Disconnect() end
                        if upConn then upConn:Disconnect() end
                    end
                end)
            end

            conn(barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    beginSlide(input)
                end
            end))

            function sliderObj:Set(val)
                update(val, false)
            end

            function sliderObj:Get() return value end

            return sliderObj
        end

        -- ─── DROPDOWN ───
        function tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local selected = cfg.Default or (options[1] or "")
            local callback = cfg.Callback or function() end
            local expanded = false
            local dropObj = {}
            local optionBtns = {}

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, Theme.ElemH),
                BackgroundColor3 = Theme.Element,
                ClipsDescendants = true,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            registerElement(cfg.Name or "Dropdown", f)

            U.new("TextLabel", {
                Text = cfg.Name or "Dropdown",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -10, 0, Theme.ElemH),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            local selBtn = U.new("TextButton", {
                Text = selected .. "  ▾",
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.TextSec,
                BackgroundColor3 = Theme.PanelLighter,
                Size = UDim2.new(0.5, -14, 0, 24),
                Position = UDim2.new(0.5, 4, 0, 5),
                AutoButtonColor = false,
                Parent = f,
            })
            U.corner(selBtn, Theme.CornerSm)

            local optContainer = U.new("Frame", {
                Position = UDim2.new(0, 6, 0, Theme.ElemH + 2),
                Size = UDim2.new(1, -12, 0, 0),
                BackgroundColor3 = Theme.PanelLighter,
                ClipsDescendants = true,
                Parent = f,
            })
            U.corner(optContainer, Theme.CornerSm)
            local optLayout = U.list(optContainer, 1)
            U.padding(optContainer, 2, 2, 2, 2)

            local function collapse()
                expanded = false
                Anim.smooth(f, { Size = UDim2.new(1, 0, 0, Theme.ElemH) }, Theme.AnimFast)
                Anim.smooth(optContainer, { Size = UDim2.new(1, -12, 0, 0) }, Theme.AnimFast)
                selBtn.Text = selected .. "  ▾"
            end

            local function expand()
                expanded = true
                local listH = #options * 26 + 6
                Anim.smooth(f, { Size = UDim2.new(1, 0, 0, Theme.ElemH + listH + 6) }, Theme.AnimFast)
                Anim.smooth(optContainer, { Size = UDim2.new(1, -12, 0, listH) }, Theme.AnimFast)
                selBtn.Text = selected .. "  ▴"
            end

            local function buildOptions()
                for _, btn in next, optionBtns do btn:Destroy() end
                table.clear(optionBtns)
                for i, opt in ipairs(options) do
                    local ob = U.new("TextButton", {
                        Text = opt,
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = opt == selected and Theme.Accent or Theme.Text,
                        BackgroundColor3 = Theme.Element,
                        BackgroundTransparency = 0.5,
                        Size = UDim2.new(1, 0, 0, 24),
                        AutoButtonColor = false,
                        LayoutOrder = i,
                        Parent = optContainer,
                    })
                    U.corner(ob, Theme.CornerSm)
                    conn(ob.MouseEnter:Connect(function() Anim.snap(ob, { BackgroundTransparency = 0 }) end))
                    conn(ob.MouseLeave:Connect(function() Anim.snap(ob, { BackgroundTransparency = 0.5 }) end))
                    conn(ob.MouseButton1Click:Connect(function()
                        selected = opt
                        for _, b in next, optionBtns do
                            b.TextColor3 = b.Text == selected and Theme.Accent or Theme.Text
                        end
                        collapse()
                        pcall(callback, selected)
                    end))
                    table.insert(optionBtns, ob)
                end
            end
            buildOptions()

            conn(selBtn.MouseButton1Click:Connect(function()
                if expanded then collapse() else expand() end
            end))

            function dropObj:Set(val)
                selected = val
                collapse()
            end

            function dropObj:SetOptions(opts)
                options = opts
                buildOptions()
                collapse()
            end

            function dropObj:Get() return selected end

            return dropObj
        end

        -- ─── COLORPICKER ───
        function tab:CreateColorpicker(cfg)
            cfg = cfg or {}
            local currentColor = cfg.Default or Color3.fromRGB(255, 0, 0)
            local callback = cfg.Callback or function() end
            local expanded = false
            local pickerObj = {}
            local h, s, v = U.rgbToHsv(currentColor)

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, Theme.ElemH),
                BackgroundColor3 = Theme.Element,
                ClipsDescendants = true,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            registerElement(cfg.Name or "Color", f)

            U.new("TextLabel", {
                Text = cfg.Name or "Color",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 0, Theme.ElemH),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            local swatch = U.new("TextButton", {
                Size = UDim2.fromOffset(28, 20),
                Position = UDim2.new(1, -38, 0, 7),
                BackgroundColor3 = currentColor,
                Text = "",
                AutoButtonColor = false,
                Parent = f,
            })
            U.corner(swatch, Theme.CornerSm)
            U.stroke(swatch, Theme.Border, 0.7)

            -- expanded picker area
            local pickerH = 140
            local hueBarH = 14
            local hexRowH = 28
            local expandedH = Theme.ElemH + pickerH + hueBarH + hexRowH + 24

            -- SV area
            local svFrame = U.new("Frame", {
                Position = UDim2.new(0, 8, 0, Theme.ElemH + 4),
                Size = UDim2.new(1, -16, 0, pickerH),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                ClipsDescendants = true,
                Parent = f,
            })
            U.corner(svFrame, Theme.CornerSm)

            -- white-to-transparent gradient (saturation)
            U.new("UIGradient", {
                Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                Transparency = NumberSequence.new(0, 1),
                Parent = svFrame,
            })

            -- black overlay (value)
            local blackOverlay = U.new("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                Parent = svFrame,
            })
            U.new("UIGradient", {
                Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                Transparency = NumberSequence.new(1, 0),
                Rotation = 90,
                Parent = blackOverlay,
            })
            U.corner(blackOverlay, Theme.CornerSm)

            -- SV cursor
            local svCursor = U.new("Frame", {
                Size = UDim2.fromOffset(12, 12),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(s, 0, 1 - v, 0),
                BackgroundTransparency = 1,
                ZIndex = 3,
                Parent = svFrame,
            })
            U.stroke(svCursor, Theme.Text, 0, 2)
            U.corner(svCursor, Theme.CornerPill)

            -- Hue bar
            local hueBar = U.new("Frame", {
                Position = UDim2.new(0, 8, 0, Theme.ElemH + pickerH + 8),
                Size = UDim2.new(1, -16, 0, hueBarH),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = f,
            })
            U.corner(hueBar, Theme.CornerPill)
            U.new("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
                Parent = hueBar,
            })

            local hueCursor = U.new("Frame", {
                Size = UDim2.new(0, 4, 1, 4),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(h, 0, 0.5, 0),
                BackgroundColor3 = Theme.Text,
                ZIndex = 3,
                Parent = hueBar,
            })
            U.corner(hueCursor, Theme.CornerPill)

            -- Hex row
            local hexRow = U.new("Frame", {
                Position = UDim2.new(0, 8, 0, Theme.ElemH + pickerH + hueBarH + 12),
                Size = UDim2.new(1, -16, 0, hexRowH),
                BackgroundTransparency = 1,
                Parent = f,
            })

            U.new("TextLabel", {
                Text = "HEX",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = Theme.TextDark,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 30, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = hexRow,
            })

            local hexBox = U.new("TextBox", {
                Text = U.colorToHex(currentColor),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.PanelLighter,
                Size = UDim2.new(0, 80, 1, -4),
                Position = UDim2.new(0, 34, 0, 2),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = hexRow,
            })
            U.corner(hexBox, Theme.CornerSm)

            local previewSwatch = U.new("Frame", {
                Size = UDim2.new(0, 28, 1, -4),
                Position = UDim2.new(0, 120, 0, 2),
                BackgroundColor3 = currentColor,
                Parent = hexRow,
            })
            U.corner(previewSwatch, Theme.CornerSm)
            U.stroke(previewSwatch, Theme.Border, 0.7)

            local function applyColor()
                currentColor = Color3.fromHSV(h, s, v)
                swatch.BackgroundColor3 = currentColor
                previewSwatch.BackgroundColor3 = currentColor
                svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                hexBox.Text = U.colorToHex(currentColor)
                pcall(callback, currentColor)
            end

            -- SV drag
            local function svInput(input)
                local abs = svFrame.AbsolutePosition
                local sz = svFrame.AbsoluteSize
                s = math.clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                v = 1 - math.clamp((input.Position.Y - abs.Y) / sz.Y, 0, 1)
                applyColor()
            end

            conn(svFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    svInput(input)
                    local mc, uc
                    mc = UserInputService.InputChanged:Connect(function(mv)
                        if mv.UserInputType == Enum.UserInputType.MouseMovement then svInput(mv) end
                    end)
                    uc = UserInputService.InputEnded:Connect(function(up)
                        if up.UserInputType == Enum.UserInputType.MouseButton1 then
                            if mc then mc:Disconnect() end
                            if uc then uc:Disconnect() end
                        end
                    end)
                end
            end))

            -- Hue drag
            local function hueInput(input)
                local abs = hueBar.AbsolutePosition
                local sz = hueBar.AbsoluteSize
                h = math.clamp((input.Position.X - abs.X) / sz.X, 0, 0.999)
                applyColor()
            end

            conn(hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueInput(input)
                    local mc, uc
                    mc = UserInputService.InputChanged:Connect(function(mv)
                        if mv.UserInputType == Enum.UserInputType.MouseMovement then hueInput(mv) end
                    end)
                    uc = UserInputService.InputEnded:Connect(function(up)
                        if up.UserInputType == Enum.UserInputType.MouseButton1 then
                            if mc then mc:Disconnect() end
                            if uc then uc:Disconnect() end
                        end
                    end)
                end
            end))

            -- Hex input
            conn(hexBox.FocusLost:Connect(function()
                local parsed = U.hexToColor(hexBox.Text)
                if parsed then
                    h, s, v = U.rgbToHsv(parsed)
                    applyColor()
                else
                    hexBox.Text = U.colorToHex(currentColor)
                end
            end))

            -- Expand/collapse
            conn(swatch.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Anim.smooth(f, { Size = UDim2.new(1, 0, 0, expandedH) }, Theme.AnimFast)
                else
                    Anim.smooth(f, { Size = UDim2.new(1, 0, 0, Theme.ElemH) }, Theme.AnimFast)
                end
            end))

            function pickerObj:Set(color)
                h, s, v = U.rgbToHsv(color)
                applyColor()
            end

            function pickerObj:Get() return currentColor end

            return pickerObj
        end

        -- ─── BUTTON ───
        function tab:CreateButton(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end

            local f = U.new("TextButton", {
                Text = cfg.Name or "Button",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.15,
                Size = UDim2.new(1, 0, 0, Theme.ElemH),
                AutoButtonColor = false,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            registerElement(cfg.Name or "Button", f)

            conn(f.MouseEnter:Connect(function()
                Anim.snap(f, { BackgroundColor3 = Theme.AccentHover, BackgroundTransparency = 0.05 })
            end))
            conn(f.MouseLeave:Connect(function()
                Anim.snap(f, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.15 })
            end))
            conn(f.MouseButton1Click:Connect(function()
                Anim.snap(f, { BackgroundTransparency = 0.3 }, 0.06)
                task.delay(0.06, function()
                    Anim.snap(f, { BackgroundTransparency = 0.15 })
                end)
                pcall(callback)
            end))

            return f
        end

        -- ─── PARAGRAPH ───
        function tab:CreateParagraph(cfg)
            cfg = cfg or {}

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Element,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            U.padding(f, 8, 10, 8, 10)
            U.list(f, 2)
            registerElement(cfg.Title or "Info", f)

            if cfg.Title then
                U.new("TextLabel", {
                    Text = cfg.Title,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    LayoutOrder = 0,
                    Parent = f,
                })
            end

            local contentLabel = U.new("TextLabel", {
                Text = cfg.Content or "",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Theme.TextSec,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                LayoutOrder = 1,
                Parent = f,
            })

            return { Frame = f, ContentLabel = contentLabel }
        end

        -- ─── TEXTBOX ───
        function tab:CreateTextbox(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end
            local tbObj = {}

            local f = U.new("Frame", {
                Size = UDim2.new(1, 0, 0, Theme.ElemH),
                BackgroundColor3 = Theme.Element,
                LayoutOrder = nextOrder(),
                Parent = scroll,
            })
            U.corner(f, Theme.CornerSm)
            registerElement(cfg.Name or "Textbox", f)

            U.new("TextLabel", {
                Text = cfg.Name or "Input",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.45, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })

            local inputBox = U.new("TextBox", {
                Text = cfg.Default or "",
                PlaceholderText = cfg.Placeholder or "...",
                PlaceholderColor3 = Theme.TextDark,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.PanelLighter,
                Size = UDim2.new(0.55, -14, 0, 24),
                Position = UDim2.new(0.45, 4, 0, 5),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })
            U.corner(inputBox, Theme.CornerSm)
            U.padding(inputBox, 0, 6, 0, 6)

            local stroke = U.stroke(inputBox, Theme.Accent, 1, 1)
            conn(inputBox.Focused:Connect(function()
                Anim.smooth(stroke, { Transparency = 0.3 }, Theme.AnimFast)
            end))
            conn(inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                if not inputBox:IsFocused() then return end
            end))
            conn(inputBox.FocusLost:Connect(function(enterPressed)
                Anim.smooth(stroke, { Transparency = 1 }, Theme.AnimFast)
                pcall(callback, inputBox.Text, enterPressed)
            end))

            function tbObj:Set(text) inputBox.Text = text end
            function tbObj:Get() return inputBox.Text end

            return tbObj
        end

        return tab
    end

    -- ═══════════════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ═══════════════════════════════════════════════════════

    function win:CreateNotification(cfg)
        cfg = cfg or {}
        local nTitle = cfg.Title or "Notification"
        local nContent = cfg.Content or ""
        local duration = cfg.Duration or 3
        local nType = cfg.Type or "info"

        local accentColor = Theme.NotifInfo
        if nType == "success" then accentColor = Theme.NotifSuccess
        elseif nType == "warning" then accentColor = Theme.NotifWarn
        elseif nType == "error" then accentColor = Theme.NotifError end

        -- calculate Y offset from existing notifications
        local yOffset = 0
        for _, n in next, win._activeNotifs do
            if n.frame and n.frame.Parent then
                yOffset = yOffset + n.height + 8
            end
        end

        local nf = U.new("Frame", {
            Size = UDim2.new(1, 0, 0, 66),
            Position = UDim2.new(1, 300, 0, yOffset),
            BackgroundColor3 = Theme.Panel,
            Parent = notifHolder,
        })
        U.glass(nf, 0.08)

        -- accent stripe on left
        local stripe = U.new("Frame", {
            Size = UDim2.new(0, 3, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundColor3 = accentColor,
            Parent = nf,
        })
        U.corner(stripe, Theme.CornerPill)

        U.new("TextLabel", {
            Text = nTitle,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 14, 0, 8),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = nf,
        })

        U.new("TextLabel", {
            Text = nContent,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Theme.TextSec,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 14, 0, 26),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = nf,
        })

        -- progress bar
        local progBar = U.new("Frame", {
            Size = UDim2.new(1, -8, 0, 2),
            Position = UDim2.new(0, 4, 1, -5),
            BackgroundColor3 = accentColor,
            Parent = nf,
        })
        U.corner(progBar, Theme.CornerPill)

        local entry = { frame = nf, height = 66 }
        table.insert(win._activeNotifs, entry)

        -- animate in
        Anim.smooth(nf, { Position = UDim2.new(0, 0, 0, yOffset) })

        -- progress drain
        Anim.linear(progBar, { Size = UDim2.new(0, 0, 0, 2) }, duration)

        -- dismiss after duration
        task.delay(duration, function()
            Anim.smooth(nf, { Position = UDim2.new(1, 300, 0, yOffset) })
            task.wait(Theme.Anim + 0.05)
            nf:Destroy()

            for i, n in next, win._activeNotifs do
                if n == entry then
                    table.remove(win._activeNotifs, i)
                    break
                end
            end

            -- reposition remaining
            local newY = 0
            for _, n in next, win._activeNotifs do
                if n.frame and n.frame.Parent then
                    Anim.smooth(n.frame, { Position = UDim2.new(0, 0, 0, newY) })
                    newY = newY + n.height + 8
                end
            end
        end)
    end

    -- ═══════════════════════════════════════════════════════
    -- DESTROY
    -- ═══════════════════════════════════════════════════════

    function win:Destroy()
        for _, c in next, win._connections do
            if typeof(c) == "RBXScriptConnection" and c.Connected then
                c:Disconnect()
            end
        end
        table.clear(win._connections)
        pcall(function() screenGui:Destroy() end)
    end

    table.insert(SorenUI._windows, win)
    return win
end

function SorenUI:Destroy()
    for _, w in next, self._windows do
        pcall(function() w:Destroy() end)
    end
    table.clear(self._windows)
end

return SorenUI
