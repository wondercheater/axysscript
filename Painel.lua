-- ============================================================================
--  AXYS SCRIPT v4.0
--  Layout: sidebar + duas colunas (opcoes | settings) | accent roxo | vidro
--  Client-side only. Nenhum remote, nenhuma escrita no servidor.
-- ============================================================================

--// SERVICOS
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    Lighting = game:GetService("Lighting"),
    Teleport = game:GetService("TeleportService"),
}

local LP = Services.Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local UIS = Services.UIS
local RunService = Services.RunService
local TweenS = Services.TweenService
local Lighting = Services.Lighting

--// TEMA
local Theme = {
    Window = Color3.fromRGB(14,14,18),
    Sidebar = Color3.fromRGB(18,18,22),
    Card = Color3.fromRGB(24,24,30),
    CardHover = Color3.fromRGB(32,32,40),
    Line = Color3.fromRGB(40,40,50),
    Accent = Color3.fromRGB(168,85,247),
    AccentDim = Color3.fromRGB(70,40,100),
    Text = Color3.fromRGB(240,240,248),
    Dim = Color3.fromRGB(135,135,150),
    Track = Color3.fromRGB(44,44,54),
    AWin = 0.04,
    ASide = 0.06,
    ACard = 0.10,
}

-- transparencia ajustavel (0 = opaco, 1 = vidro total)
local Alpha = { Win = 0.04, Side = 0.06, Card = 0.10, Row = 0.30 }

--// CONFIG
local Config = {
    Aimbot = {
        Enabled = false, Part = "Head", Smoothness = 0.25,
        FOV_Enabled = true, FOV_Radius = 140, FOV_Filled = false,
        FOV_Color = Theme.Accent, FOVColorPreset = "Purple",
        TeamCheck = true, WallCheck = true, HoldKey = "MouseButton2",
    },
    Triggerbot = { Enabled = false, Delay = 0.12, DamageOnly = false },
    ESP = {
        Enabled = false, Box = true, Name = true, HealthBar = true,
        Distance = true, Tracers = true, TracerOrigin = "Bottom",
        TeamCheck = false, UseTeamColor = false, ColorPreset = "Purple",
        MaxDistance = 2500, BoxThickness = 1.5, NameSize = 12, DistanceSize = 11,
    },
    Fly = { Enabled = false, Speed = 60, SmoothAccel = false, KeepUponDeath = false },
    Speed = { Enabled = false, Value = 60 },
    Spin = { Enabled = false, Speed = 12 },
    BunnyHop = { Enabled = false },
    ClickTP = { Enabled = false, Distance = 1000, HoldKey = "LeftControl" },
    Ghost = { Enabled = false, Transparency = 1 },
    Noclip = false,
    InfJump = false,
    FOV = 70,
    Gravity = 196.2,
    Fullbright = false,
    NoFog = false,
    UIAlpha = 4,
    AntiAFK = true,
    VCBypass = false,
    VCBypassAggressive = false,
    ChatBypass = false,
    AnimTrack = nil,
}

--// ESTADO
local State = {
    FlyVel = nil, FlyGyro = nil,
    GhostStored = {}, ParticleCache = {},
    TPHeld = false,
    OpenPopup = nil,
    Minimized = false,
    VCC = nil,
    LastTrigger = 0,
    ESP = {},
}

--// UTILIDADES
local function Safe(fn)
    local ok, err = pcall(fn)
    if not ok then warn("[AXYS] " .. tostring(err)) end
end

local function GetConfig(path)
    local node = Config
    for part in path:gmatch("[^.]+") do node = node[part] end
    return node
end

local function SetConfig(path, value)
    local node = Config
    local parts = {}
    for part in path:gmatch("[^.]+") do table.insert(parts, part) end
    for i = 1, #parts - 1 do node = node[parts[i]] end
    node[parts[#parts]] = value
end

local ColorPresets = {
    Purple = Color3.fromRGB(168,85,247),
    Green = Color3.fromRGB(80,240,130),
    Red = Color3.fromRGB(255,70,70),
    Blue = Color3.fromRGB(80,150,255),
    Yellow = Color3.fromRGB(255,220,90),
    White = Color3.fromRGB(255,255,255),
    Orange = Color3.fromRGB(255,150,60),
    Cyan = Color3.fromRGB(90,230,240),
    Pink = Color3.fromRGB(255,110,190),
    Gray = Color3.fromRGB(140,140,150),
}
local PresetNames = {}
for k in pairs(ColorPresets) do table.insert(PresetNames, k) end
table.sort(PresetNames)
local function GetColor(p) return ColorPresets[p] or ColorPresets.Purple end

local function IsKeyDownName(name)
    if name == "MouseButton2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if name == "MouseButton1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    local ok, code = pcall(function() return Enum.KeyCode[name] end)
    if ok and code then return UIS:IsKeyDown(code) end
    return false
end

local function IsKeyDownInput(input, name)
    if name == "MouseButton2" then return input.UserInputType == Enum.UserInputType.MouseButton2 end
    if name == "MouseButton1" then return input.UserInputType == Enum.UserInputType.MouseButton1 end
    return input.KeyCode and input.KeyCode.Name == name
end

--// DECLARACOES ANTECIPADAS
local startFly, stopFly, ghostApply, ghostRestore, startAntiAFK

-- ============================================================================
--  GUI
-- ============================================================================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "AXYS"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local espLayer = Instance.new("Frame", gui)
espLayer.Size = UDim2.fromScale(1,1)
espLayer.BackgroundTransparency = 1
espLayer.BorderSizePixel = 0
espLayer.Visible = false

local fovCircle = Instance.new("Frame", gui)
fovCircle.Name = "FovCircle"
fovCircle.AnchorPoint = Vector2.new(0.5,0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.ZIndex = 0
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1,0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.35

local Window = Instance.new("Frame", gui)
Window.AnchorPoint = Vector2.new(0.5,0.5)
Window.Position = UDim2.fromScale(0.5,0.5)
Window.Size = UDim2.fromOffset(0,0)
Window.BackgroundColor3 = Theme.Window
Window.BackgroundTransparency = Alpha.Win
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.ZIndex = 1
Instance.new("UICorner", Window).CornerRadius = UDim.new(0,14)
local winStroke = Instance.new("UIStroke", Window)
winStroke.Color = Color3.fromRGB(60,60,75)
winStroke.Thickness = 1
winStroke.Transparency = 0.45
TweenS:Create(Window, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    {Size = UDim2.fromOffset(760,480)}):Play()

--// TOP BAR
local TopBar = Instance.new("Frame", Window)
TopBar.Size = UDim2.new(1,0,0,48)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BackgroundTransparency = Alpha.Side
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,14)
local topCover = Instance.new("Frame", TopBar)
topCover.Size = UDim2.new(1,0,0,14)
topCover.Position = UDim2.new(0,0,1,-14)
topCover.BackgroundColor3 = Theme.Sidebar
topCover.BackgroundTransparency = Alpha.Side
topCover.BorderSizePixel = 0
topCover.ZIndex = 3
local topLine = Instance.new("Frame", TopBar)
topLine.Size = UDim2.new(1,0,0,1)
topLine.Position = UDim2.new(0,0,0,47)
topLine.BackgroundColor3 = Theme.Accent
topLine.BackgroundTransparency = 0.65
topLine.BorderSizePixel = 0
topLine.ZIndex = 3

local Logo = Instance.new("Frame", TopBar)
Logo.Size = UDim2.fromOffset(22,22)
Logo.Position = UDim2.new(0,16,0,13)
Logo.BackgroundColor3 = Theme.Accent
Logo.BorderSizePixel = 0
Logo.Rotation = 45
Logo.ZIndex = 4
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0,6)

local LogoA = Instance.new("TextLabel", TopBar)
LogoA.Size = UDim2.fromOffset(22,22)
LogoA.Position = UDim2.new(0,16,0,13)
LogoA.BackgroundTransparency = 1
LogoA.Text = "A"
LogoA.Font = Enum.Font.GothamBlack
LogoA.TextSize = 14
LogoA.TextColor3 = Theme.Window
LogoA.TextTransparency = 0.1
LogoA.Rotation = -45
LogoA.ZIndex = 5

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0,50,1,0)
Title.Position = UDim2.new(0,48,0,0)
Title.BackgroundTransparency = 1
Title.Text = "AXYS"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4

local Subtitle = Instance.new("TextLabel", TopBar)
Subtitle.Size = UDim2.new(0,40,1,0)
Subtitle.Position = UDim2.new(0,100,0,0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "v4.0"
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 11
Subtitle.TextColor3 = Theme.Dim
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 4

local Search = Instance.new("TextBox", TopBar)
Search.Size = UDim2.new(0,210,0,30)
Search.Position = UDim2.new(1,-262,0,9)
Search.BackgroundColor3 = Theme.Card
Search.BackgroundTransparency = Theme.ACard
Search.BorderSizePixel = 0
Search.PlaceholderText = "Buscar opcao..."
Search.PlaceholderColor3 = Theme.Dim
Search.Text = ""
Search.ClearTextOnFocus = false
Search.Font = Enum.Font.GothamMedium
Search.TextSize = 12
Search.TextColor3 = Theme.Text
Search.ZIndex = 4
Instance.new("UICorner", Search).CornerRadius = UDim.new(0,8)
local sp = Instance.new("UIPadding", Search)
sp.PaddingLeft = UDim.new(0,10)

local function WinBtn(txt, xoff)
    local b = Instance.new("TextButton", TopBar)
    b.Size = UDim2.fromOffset(28,28)
    b.Position = UDim2.new(1, xoff, 0, 10)
    b.BackgroundColor3 = Theme.Card
    b.BackgroundTransparency = Theme.ACard
    b.BorderSizePixel = 0
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Theme.Text
    b.AutoButtonColor = false
    b.ZIndex = 4
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.CardHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Card end)
    return b
end

local CloseBtn = WinBtn("X", -38)
CloseBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)
local MinBtn = WinBtn("-", -72)
MinBtn.MouseButton1Click:Connect(function()
    State.Minimized = not State.Minimized
    TweenS:Create(Window, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = State.Minimized and UDim2.fromOffset(760,48) or UDim2.fromOffset(760,480)
    }):Play()
end)

do
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = Window.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

--// SIDEBAR
local Sidebar = Instance.new("Frame", Window)
Sidebar.Position = UDim2.new(0,0,0,48)
Sidebar.Size = UDim2.new(0,190,1,-48)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BackgroundTransparency = Alpha.Side
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
local sideSep = Instance.new("Frame", Sidebar)
sideSep.Size = UDim2.new(0,1,1,0)
sideSep.Position = UDim2.new(1,-1,0,0)
sideSep.BackgroundColor3 = Theme.Line
sideSep.BackgroundTransparency = 0.4
sideSep.BorderSizePixel = 0

local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0,4)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
local sidePad = Instance.new("UIPadding", Sidebar)
sidePad.PaddingTop = UDim.new(0,12)
sidePad.PaddingLeft = UDim.new(0,10)
sidePad.PaddingRight = UDim.new(0,10)

local OptLabel = Instance.new("TextLabel", Sidebar)
OptLabel.Size = UDim2.new(1,-8,0,20)
OptLabel.BackgroundTransparency = 1
OptLabel.Text = "OPTIONS"
OptLabel.Font = Enum.Font.GothamBold
OptLabel.TextSize = 10
OptLabel.TextColor3 = Theme.Dim
OptLabel.TextTransparency = 0.4
OptLabel.TextXAlignment = Enum.TextXAlignment.Left
OptLabel.LayoutOrder = -1
OptLabel.ZIndex = 4
local olp = Instance.new("UIPadding", OptLabel)
olp.PaddingLeft = UDim.new(0,8)

local Footer = Instance.new("TextLabel", Sidebar)
Footer.Size = UDim2.new(1,-8,0,36)
Footer.Position = UDim2.new(0,10,1,-46)
Footer.BackgroundTransparency = 1
Footer.Text = "AXYS v4.0  |  client-side"
Footer.Font = Enum.Font.GothamMedium
Footer.TextSize = 10
Footer.TextColor3 = Theme.Dim
Footer.TextTransparency = 0.45
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 4

--// TABS
local Tabs, TabButtons = {}, {}
local ActiveTab = nil

local function SwitchTab(name)
    for n, t in pairs(Tabs) do t.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        local on = (n == name)
        b.BackgroundColor3 = on and Theme.AccentDim or Theme.Card
        b.BackgroundTransparency = on and 0.25 or Alpha.Row
        b.TextColor3 = on and Theme.Text or Theme.Dim
        local d = b:FindFirstChild("Dot")
        if d then d.Visible = on end
    end
    ActiveTab = name
end

local function CreateTab(name)
    local scroll = Instance.new("ScrollingFrame", Window)
    scroll.Position = UDim2.new(0,190,0,48)
    scroll.Size = UDim2.new(1,-190,1,-48)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Theme.Accent
    scroll.ScrollBarImageTransparency = 0.35
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.ZIndex = 3
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0,16)
    pad.PaddingBottom = UDim.new(0,20)
    pad.PaddingLeft = UDim.new(0,16)
    pad.PaddingRight = UDim.new(0,16)

    local columns = Instance.new("Frame", scroll)
    columns.Size = UDim2.new(1,0,0,0)
    columns.AutomaticSize = Enum.AutomaticSize.Y
    columns.BackgroundTransparency = 1
    columns.BorderSizePixel = 0
    local cl = Instance.new("UIListLayout", columns)
    cl.FillDirection = Enum.FillDirection.Horizontal
    cl.Padding = UDim.new(0,12)
    cl.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function NewCol()
        local col = Instance.new("Frame", columns)
        col.Size = UDim2.new(0.5,-6,0,0)
        col.AutomaticSize = Enum.AutomaticSize.Y
        col.BackgroundTransparency = 1
        col.BorderSizePixel = 0
        local l = Instance.new("UIListLayout", col)
        l.Padding = UDim.new(0,12)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        return col
    end

    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = Theme.Card
    btn.BackgroundTransparency = Alpha.Row
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Theme.Dim
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local bp = Instance.new("UIPadding", btn)
    bp.PaddingLeft = UDim.new(0,28)
    local dot = Instance.new("Frame", btn)
    dot.Name = "Dot"
    dot.Size = UDim2.fromOffset(4,16)
    dot.Position = UDim2.new(0,14,0.5,-8)
    dot.BackgroundColor3 = Theme.Accent
    dot.BorderSizePixel = 0
    dot.Visible = false
    dot.ZIndex = 5
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    btn.MouseEnter:Connect(function()
        if ActiveTab ~= name then btn.BackgroundTransparency = 0.15 end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= name then btn.BackgroundTransparency = Alpha.Row end
    end)

    Tabs[name] = scroll
    TabButtons[name] = btn
    return NewCol(), NewCol()
end

-- ============================================================================
--  COMPONENTES
-- ============================================================================
local Order = {}
local function NextOrder(p)
    Order[p] = (Order[p] or 0) + 1
    return Order[p]
end

local SearchIndex = {}
local function RegisterSearch(sec, title, label)
    table.insert(SearchIndex, {sec = sec, title = title:lower(), label = label:lower()})
end

local function ApplySearch(q)
    q = q:lower():gsub("%s+", "")
    for _, e in ipairs(SearchIndex) do
        local show = true
        if q ~= "" then
            show = (e.title:find(q, 1, true) ~= nil) or (e.label:find(q, 1, true) ~= nil)
        end
        e.sec.Visible = show
    end
end

local function Section(parent, title)
    local sec = Instance.new("Frame", parent)
    sec.Name = title
    sec.Size = UDim2.new(1,0,0,0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundColor3 = Theme.Card
    sec.BackgroundTransparency = Alpha.Card
    sec.BorderSizePixel = 0
    sec.LayoutOrder = NextOrder(parent)
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0,12)

    local head = Instance.new("TextLabel", sec)
    head.Size = UDim2.new(1,-24,0,26)
    head.Position = UDim2.new(0,14,0,6)
    head.BackgroundTransparency = 1
    head.Text = title
    head.Font = Enum.Font.GothamBold
    head.TextSize = 12
    head.TextColor3 = Theme.Text
    head.TextTransparency = 0.08
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.ZIndex = 5

    local line = Instance.new("Frame", sec)
    line.Size = UDim2.new(1,-28,0,1)
    line.Position = UDim2.new(0,14,0,30)
    line.BackgroundColor3 = Theme.Line
    line.BackgroundTransparency = 0.35
    line.BorderSizePixel = 0
    line.ZIndex = 5

    local body = Instance.new("Frame", sec)
    body.Name = "Body"
    body.Size = UDim2.new(1,-24,0,0)
    body.Position = UDim2.new(0,12,0,38)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    local l = Instance.new("UIListLayout", body)
    l.Padding = UDim.new(0,8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local p = Instance.new("UIPadding", body)
    p.PaddingBottom = UDim.new(0,10)

    RegisterSearch(sec, title, title)
    return body, sec
end

local function Toggle(parent, text, key, callback)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 5

    local cb = Instance.new("Frame", row)
    cb.Size = UDim2.fromOffset(15,15)
    cb.Position = UDim2.new(0,2,0.5,-7.5)
    cb.BackgroundColor3 = Theme.Track
    cb.BackgroundTransparency = 0.2
    cb.BorderSizePixel = 0
    cb.ZIndex = 6
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0,4)

    local fill = Instance.new("TextLabel", cb)
    fill.Size = UDim2.fromScale(1,1)
    fill.BackgroundTransparency = 1
    fill.Text = "✓"
    fill.Font = Enum.Font.GothamBold
    fill.TextSize = 10
    fill.TextColor3 = Theme.Window
    fill.TextTransparency = 1
    fill.ZIndex = 7

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-24,1,0)
    lbl.Position = UDim2.new(0,24,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTransparency = 0.1
    lbl.ZIndex = 6

    local function paint(v)
        TweenS:Create(cb, TweenInfo.new(0.15), {BackgroundColor3 = v and Theme.Accent or Theme.Track}):Play()
        TweenS:Create(fill, TweenInfo.new(0.15), {TextTransparency = v and 0 or 1}):Play()
        TweenS:Create(lbl, TweenInfo.new(0.15), {TextTransparency = v and 0.05 or 0.3}):Play()
    end
    paint(GetConfig(key))

    row.MouseEnter:Connect(function() row.BackgroundTransparency = 0.94 end)
    row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
    row.MouseButton1Click:Connect(function()
        SetConfig(key, not GetConfig(key))
        paint(GetConfig(key))
        Safe(function() if callback then callback(GetConfig(key)) end end)
    end)
    return row
end

local function Slider(parent, text, key, min, max, decimals, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,42)
    row.BackgroundTransparency = 1
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-70,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Text
    lbl.TextTransparency = 0.2
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5

    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(0,70,0,18)
    val.Position = UDim2.new(1,-70,0,0)
    val.BackgroundTransparency = 1
    val.Text = ""
    val.Font = Enum.Font.GothamBold
    val.TextSize = 11
    val.TextColor3 = Theme.Accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 5

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,0,0,6)
    track.Position = UDim2.new(0,0,0,24)
    track.BackgroundColor3 = Theme.Track
    track.BackgroundTransparency = 0.25
    track.BorderSizePixel = 0
    track.ZIndex = 5
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fillf = Instance.new("Frame", track)
    fillf.Size = UDim2.new(0,0,1,0)
    fillf.BackgroundColor3 = Theme.Accent
    fillf.BorderSizePixel = 0
    fillf.ZIndex = 6
    Instance.new("UICorner", fillf).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.fromOffset(12,12)
    knob.BackgroundColor3 = Theme.Text
    knob.BackgroundTransparency = 0.05
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0,0,0.5,0)
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    local function apply(rel)
        rel = math.clamp(rel, 0, 1)
        local v = min + (max - min) * rel
        if decimals == 0 then v = math.floor(v + 0.5)
        else v = math.floor(v * 10^decimals + 0.5) / 10^decimals end
        SetConfig(key, v)
        fillf.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        val.Text = tostring(v)
        if callback then Safe(function() callback(v) end) end
    end

    local base = GetConfig(key) or min
    local rel0 = math.clamp((base - min) / (max - min), 0, 1)
    fillf.Size = UDim2.new(rel0, 0, 1, 0)
    knob.Position = UDim2.new(rel0, 0, 0.5, 0)
    val.Text = tostring(base)

    local function fromX(x)
        return (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; apply(fromX(i.Position.X))
        end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            apply(fromX(i.Position.X))
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return row
end

local function Dropdown(parent, text, key, options, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-120,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Text
    lbl.TextTransparency = 0.2
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,110,0,24)
    btn.Position = UDim2.new(1,-110,0,1)
    btn.BackgroundColor3 = Theme.Track
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = tostring(GetConfig(key))
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextColor3 = Theme.Text
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local bp2 = Instance.new("UIPadding", btn)
    bp2.PaddingLeft = UDim.new(0,8)

    local popup = Instance.new("Frame", gui)
    popup.Size = UDim2.fromOffset(130, math.min(#options*24 + 8, 170))
    popup.BackgroundColor3 = Theme.Card
    popup.BackgroundTransparency = 0.05
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 60
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,8)
    local pst = Instance.new("UIStroke", popup)
    pst.Color = Theme.Accent; pst.Thickness = 1; pst.Transparency = 0.55

    local ps = Instance.new("ScrollingFrame", popup)
    ps.Size = UDim2.fromScale(1,1)
    ps.BackgroundTransparency = 1
    ps.BorderSizePixel = 0
    ps.ScrollBarThickness = 3
    ps.ZIndex = 61
    ps.CanvasSize = UDim2.new(0,0,0,#options*24)
    Instance.new("UIListLayout", ps)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton", ps)
        ob.Size = UDim2.new(1,-4,0,24)
        ob.BackgroundTransparency = 1
        ob.Text = opt
        ob.Font = Enum.Font.GothamMedium
        ob.TextSize = 11
        ob.TextColor3 = Theme.Text
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.AutoButtonColor = false
        ob.ZIndex = 62
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0,5)
        local op = Instance.new("UIPadding", ob)
        op.PaddingLeft = UDim.new(0,8)
        ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Theme.AccentDim; ob.BackgroundTransparency = 0.3 end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
        ob.MouseButton1Click:Connect(function()
            SetConfig(key, opt)
            btn.Text = opt
            popup.Visible = false
            State.OpenPopup = nil
            if callback then Safe(function() callback(opt) end) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if popup.Visible then
            popup.Visible = false; State.OpenPopup = nil
        else
            if State.OpenPopup then State.OpenPopup.Visible = false end
            popup.Visible = true
            State.OpenPopup = popup
            popup.Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4)
        end
    end)
    return row
end

local function ColorRow(parent, text, key, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-46,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Text
    lbl.TextTransparency = 0.2
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5

    local sw = Instance.new("TextButton", row)
    sw.Size = UDim2.fromOffset(40,16)
    sw.Position = UDim2.new(1,-40,0,5)
    sw.BackgroundColor3 = GetConfig(key)
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.ZIndex = 6
    Instance.new("UICorner", sw).CornerRadius = UDim.new(0,4)
    local sws = Instance.new("UIStroke", sw)
    sws.Color = Color3.new(0,0,0); sws.Transparency = 0.5; sws.Thickness = 1

    local popup = Instance.new("Frame", gui)
    local cols, rows = 5, math.ceil(#PresetNames / 5)
    popup.Size = UDim2.fromOffset(cols*28 + 16, rows*28 + 12)
    popup.BackgroundColor3 = Theme.Card
    popup.BackgroundTransparency = 0.05
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 60
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0,8)
    local pst = Instance.new("UIStroke", popup)
    pst.Color = Theme.Accent; pst.Thickness = 1; pst.Transparency = 0.55
    local grid = Instance.new("Frame", popup)
    grid.Size = UDim2.new(1,-12,1,-8)
    grid.Position = UDim2.new(0,6,0,4)
    grid.BackgroundTransparency = 1
    local gl = Instance.new("UIGridLayout", grid)
    gl.CellSize = UDim2.fromOffset(24,24)
    gl.CellPadding = UDim2.fromOffset(4,4)

    for _, name in ipairs(PresetNames) do
        local c = Instance.new("TextButton", grid)
        c.Size = UDim2.fromOffset(24,24)
        c.BackgroundColor3 = ColorPresets[name]
        c.BorderSizePixel = 0
        c.Text = ""
        c.AutoButtonColor = false
        c.ZIndex = 61
        Instance.new("UICorner", c).CornerRadius = UDim.new(0,5)
        c.MouseButton1Click:Connect(function()
            SetConfig(key, name)
            sw.BackgroundColor3 = ColorPresets[name]
            popup.Visible = false
            State.OpenPopup = nil
            if callback then Safe(function() callback(ColorPresets[name], name) end) end
        end)
    end

    sw.MouseButton1Click:Connect(function()
        if popup.Visible then
            popup.Visible = false; State.OpenPopup = nil
        else
            if State.OpenPopup then State.OpenPopup.Visible = false end
            popup.Visible = true
            State.OpenPopup = popup
            popup.Position = UDim2.fromOffset(sw.AbsolutePosition.X - 110, sw.AbsolutePosition.Y + sw.AbsoluteSize.Y + 4)
        end
    end)
    return row
end

local function Keybind(parent, text, key, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 4

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-110,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Text
    lbl.TextTransparency = 0.2
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.fromOffset(100,24)
    btn.Position = UDim2.new(1,-100,0,1)
    btn.BackgroundColor3 = Theme.Track
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = tostring(GetConfig(key))
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextColor3 = Theme.Accent
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "..."
        local conn
        conn = UIS.InputBegan:Connect(function(i, gpe)
            if not listening or gpe then return end
            listening = false
            conn:Disconnect()
            if i.UserInputType == Enum.UserInputType.Keyboard then
                SetConfig(key, i.KeyCode.Name)
            elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
                SetConfig(key, "MouseButton1")
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
                SetConfig(key, "MouseButton2")
            end
            btn.Text = tostring(GetConfig(key))
            if callback then Safe(callback) end
        end)
    end)
    return row
end

local function Button(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = Theme.Track
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextColor3 = Theme.Text
    btn.TextTransparency = 0.1
    btn.AutoButtonColor = false
    btn.LayoutOrder = NextOrder(parent)
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.AccentDim; btn.BackgroundTransparency = 0.2 end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Track; btn.BackgroundTransparency = 0.3 end)
    btn.MouseButton1Click:Connect(function() Safe(callback) end)
    return btn
end

local function InfoLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1,0,0,14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = Theme.Dim
    lbl.TextTransparency = 0.45
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = NextOrder(parent)
    lbl.ZIndex = 5
    return lbl
end

local function TextInput(parent, text, placeholder, onSubmit)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = NextOrder(parent)
    row.ZIndex = 4
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.fromScale(1,1)
    box.BackgroundColor3 = Theme.Track
    box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Theme.Dim
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 11
    box.TextColor3 = Theme.Text
    box.ZIndex = 5
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)
    local bp = Instance.new("UIPadding", box)
    bp.PaddingLeft = UDim.new(0,10)
    if onSubmit then
        box.FocusLost:Connect(function(enter) if enter then onSubmit(box.Text) end end)
    end
    return row, box
end

-- ============================================================================
--  ABAS
-- ============================================================================
local CombatL, CombatR = CreateTab("Combat")
local VisualL, VisualR = CreateTab("Visuals")
local MoveL, MoveR = CreateTab("Movement")
local PlayerL, PlayerR = CreateTab("Player")
local AnimsL, AnimsR = CreateTab("Animations")
local SetL, SetR = CreateTab("Settings")

--// COMBAT
local C1 = Section(CombatL, "Aimbot Options")
Toggle(C1, "Enable Aimbot", "Aimbot.Enabled")
Toggle(C1, "Team Check", "Aimbot.TeamCheck")
Toggle(C1, "Wall Check", "Aimbot.WallCheck")
Toggle(C1, "Show FOV Circle", "Aimbot.FOV_Enabled")
Toggle(C1, "FOV Filled", "Aimbot.FOV_Filled")

local C2 = Section(CombatR, "Aimbot Settings")
Dropdown(C2, "Aim Part", "Aimbot.Part", {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"})
Slider(C2, "Smoothness", "Aimbot.Smoothness", 0.05, 1, 2)
Slider(C2, "FOV Size", "Aimbot.FOV_Radius", 40, 400, 0)
Keybind(C2, "Hold Key", "Aimbot.HoldKey")

local C3 = Section(CombatL, "Triggerbot Options")
Toggle(C3, "Enable Triggerbot", "Triggerbot.Enabled")
Toggle(C3, "Damage Only", "Triggerbot.DamageOnly")

local C4 = Section(CombatR, "Triggerbot Settings")
Slider(C4, "Fire Delay (s)", "Triggerbot.Delay", 0.05, 1, 2)
InfoLabel(C4, "Atira no inimigo alinhado com a mira.")

--// VISUALS
local V1 = Section(VisualL, "ESP Options")
Toggle(V1, "Enable ESP", "ESP.Enabled")
Toggle(V1, "Box", "ESP.Box")
Toggle(V1, "Name", "ESP.Name")
Toggle(V1, "Health Bar", "ESP.HealthBar")
Toggle(V1, "Distance", "ESP.Distance")
Toggle(V1, "Tracers", "ESP.Tracers")
Toggle(V1, "Team Check", "ESP.TeamCheck")
Toggle(V1, "Use Team Color", "ESP.UseTeamColor")

local V2 = Section(VisualR, "ESP Settings")
Dropdown(V2, "Tracer Origin", "ESP.TracerOrigin", {"Bottom","Center","Mouse"})
Slider(V2, "Max Distance", "ESP.MaxDistance", 100, 5000, 0)
Slider(V2, "Box Thickness", "ESP.BoxThickness", 0.5, 4, 1)
Slider(V2, "Name Size", "ESP.NameSize", 10, 24, 0)
Slider(V2, "Distance Size", "ESP.DistanceSize", 8, 20, 0)

local V3 = Section(VisualR, "Miscellaneous")
ColorRow(V3, "FOV Colour", "Aimbot.FOVColorPreset", function(c) Config.Aimbot.FOV_Color = c end)
ColorRow(V3, "Tracer Colour", "ESP.ColorPreset")

--// MOVEMENT
local M1 = Section(MoveL, "Fly Options")
Toggle(M1, "Enable Fly", "Fly.Enabled", function(v) if v then startFly() else stopFly() end end)
Toggle(M1, "Smooth Acceleration", "Fly.SmoothAccel")
Toggle(M1, "Keep Upon Death", "Fly.KeepUponDeath")

local M2 = Section(MoveR, "Fly Settings")
Slider(M2, "Fly Speed", "Fly.Speed", 10, 300, 0)
InfoLabel(M2, "W/S avanca, A/D lateral, Space sobe, Shift desce.")

local M3 = Section(MoveL, "Movement Options")
Toggle(M3, "Infinite Jump", "InfJump")
Toggle(M3, "Spin", "Spin.Enabled")
Toggle(M3, "Bunny Hop", "BunnyHop.Enabled")
Toggle(M3, "Noclip", "Noclip")
Toggle(M3, "Speed Hack", "Speed.Enabled")
Toggle(M3, "Invisible (Ghost)", "Ghost.Enabled", function(v) if v then ghostApply() else ghostRestore() end end)

local M4 = Section(MoveR, "Movement Settings")
Slider(M4, "Spin Speed", "Spin.Speed", 1, 30, 1)
Slider(M4, "WalkSpeed", "Speed.Value", 16, 500, 0)
Slider(M4, "Jump Power", "JumpPower", 50, 500, 0)

local M5 = Section(MoveL, "Teleport Options")
Toggle(M5, "Click TP", "ClickTP.Enabled")

local M6 = Section(MoveR, "Teleport Settings")
Keybind(M6, "Hold Key", "ClickTP.HoldKey")
Slider(M6, "TP Distance", "ClickTP.Distance", 100, 2000, 0)
Slider(M6, "Ghost Transparency", "Ghost.Transparency", 0, 1, 2)

--// PLAYER
local P1 = Section(PlayerL, "Player Options")
Button(P1, "Reset Character", function() local c = LP.Character; if c then c:BreakJoints() end end)
Button(P1, "Respawn", function() LP:LoadCharacter() end)

local P2 = Section(PlayerR, "Camera Settings")
Slider(P2, "FOV", "FOV", 40, 120, 0)
Slider(P2, "Gravity", "Gravity", 0, 500, 0)

--// ANIMATIONS
local AnimsPresets = {
    ["Idle"] = "507766388", ["Walk"] = "507777826", ["Run"] = "507767714",
    ["Jump"] = "507765000", ["Fall"] = "507767968", ["Climb"] = "507765644",
    ["Sit"] = "507768133", ["Wave"] = "507770239", ["Point"] = "507770453",
    ["Dance 1"] = "507771019", ["Dance 2"] = "507776043", ["Dance 3"] = "507777268",
    ["Laugh"] = "507770818", ["Cheer"] = "507770677", ["Swim"] = "507784897",
    ["ToolSlash"] = "522635514", ["ToolLunge"] = "522638767",
}
local PresetList = {}
for k in pairs(AnimsPresets) do table.insert(PresetList, k) end
table.sort(PresetList)

local function PlayAnim(id)
    Safe(function()
        if State.AnimTrack then State.AnimTrack:Stop() State.AnimTrack:Destroy() State.AnimTrack = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then animator = Instance.new("Animator", hum) end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. tostring(id)
        local track = animator:LoadAnimation(anim)
        track.Looped = true
        track.Priority = Enum.AnimationPriority.Action4
        track:Play()
        State.AnimTrack = track
    end)
end

local A1 = Section(AnimsL, "Custom Animation")
local _, idBox = TextInput(A1, "ID", "Animation ID (apenas numeros)", nil)
Button(A1, "Play Custom ID", function() PlayAnim(idBox.Text) end)
Button(A1, "Stop", function()
    Safe(function()
        if State.AnimTrack then
            State.AnimTrack:Stop(); State.AnimTrack:Destroy(); State.AnimTrack = nil
        end
    end)
end)
InfoLabel(A1, "Funciona com IDs pagos e raros sem possessao.")

local A2 = Section(AnimsR, "Presets")
local grid = Instance.new("ScrollingFrame", A2)
grid.Size = UDim2.new(1,0,0,230)
grid.CanvasSize = UDim2.new(0,0,0,math.ceil(#PresetList/2)*34)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 3
grid.ScrollBarImageColor3 = Theme.Accent
grid.ZIndex = 5
local gL = Instance.new("UIGridLayout", grid)
gL.CellSize = UDim2.new(0.5,-4,0,30)
gL.CellPadding = UDim2.new(0,6,0,4)
gL.SortOrder = Enum.SortOrder.LayoutOrder
for i, name in ipairs(PresetList) do
    local b = Instance.new("TextButton", grid)
    b.LayoutOrder = i
    b.BackgroundColor3 = Theme.Track
    b.BackgroundTransparency = 0.3
    b.BorderSizePixel = 0
    b.Text = name
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.TextColor3 = Theme.Text
    b.TextTransparency = 0.1
    b.AutoButtonColor = false
    b.ZIndex = 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.AccentDim; b.BackgroundTransparency = 0.2 end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Track; b.BackgroundTransparency = 0.3 end)
    b.MouseButton1Click:Connect(function() PlayAnim(AnimsPresets[name]) end)
end

--// SETTINGS
local S1 = Section(SetL, "World Visuals")
Toggle(S1, "Fullbright", "Fullbright", function(v)
    if v then
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)
Toggle(S1, "No Fog", "NoFog", function(v) Lighting.FogEnd = v and 100000 or 1000 end)
Slider(S1, "Clock Time", "ClockTime", 0, 24, 1, function(v) Lighting.ClockTime = v end)

local S2 = Section(SetR, "Utility")
Toggle(S2, "Anti-AFK", "AntiAFK", function(v) if v then startAntiAFK() end end)
Toggle(S2, "Chat Bypass", "ChatBypass", function(v)
    Safe(function()
        local ts = game:GetService("TextChatService")
        if ts and ts.ChatInputBarConfiguration then ts.ChatInputBarConfiguration.Enabled = true end
    end)
end)
Button(S2, "Rejoin Server", function() Services.Teleport:Teleport(game.PlaceId, LP) end)
Button(S2, "Copy Job ID", function() pcall(function() setclipboard(game.JobId) end) end)
Button(S2, "Copy Place ID", function() pcall(function() setclipboard(tostring(game.PlaceId)) end) end)
Button(S2, "Destroy GUI", function() gui:Destroy() end)

local S3 = Section(SetL, "Voice")
Button(S3, "VC Bypass", function()
    Config.VCBypass = not Config.VCBypass
    if Config.VCBypass then
        Safe(function()
            local ref = cloneref or function(x) return x end
            State.VCC = ref(game:GetService("VoiceChatService"))
            State.VCC:joinVoice()
        end)
    end
end)
Button(S3, "VC Bypass (aggressive)", function()
    Config.VCBypassAggressive = not Config.VCBypassAggressive
    if Config.VCBypassAggressive then
        task.spawn(function()
            local ref = cloneref or function(x) return x end
            while Config.VCBypassAggressive do
                Safe(function()
                    local v = ref(game:GetService("VoiceChatService"))
                    v.EnableDefaultVoice = true
                    v:joinVoice()
                    task.wait(2)
                    v:leaveVoice()
                    task.wait(0.5)
                    v:joinVoice()
                end)
                task.wait(0.5)
            end
        end)
    end
end)

local S4 = Section(SetR, "Steal Clothes")
local _, nameBox = TextInput(S4, "Player", "Nome do player alvo", nil)
Button(S4, "Steal Clothes", function()
    Safe(function()
        local q = nameBox.Text
        if q == "" then return end
        local target
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr.Name:lower():find(q:lower(), 1, true)
            or plr.DisplayName:lower():find(q:lower(), 1, true) then
                target = plr
                break
            end
        end
        if not target then warn("[AXYS] player nao encontrado") return end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local ok, desc = pcall(function()
            return Services.Players:GetHumanoidDescriptionFromUserId(target.UserId)
        end)
        if ok and desc then
            hum:ApplyDescription(desc, Enum.AssetTypeVerification.ClientOnly)
        else
            warn("[AXYS] falha ao obter descricao")
        end
    end)
end)
InfoLabel(S4, "Aplica a descricao do alvo no seu rig, client-side.")

local S5 = Section(SetL, "VIP")
Button(S5, "Infinite WalkSpeed", function()
    Config.Speed.Enabled = true
    Config.Speed.Value = 1000
end)
Button(S5, "Infinite Jump Power", function() Config.JumpPower = 1000 end)
Button(S5, "Gravity 0", function() Config.Gravity = 0 end)

local S6 = Section(SetR, "Appearance")
Slider(S6, "Window Transparency", "UIAlpha", 0, 60, 0, function(v)
    Alpha.Win = v/100
    Window.BackgroundTransparency = Alpha.Win
    TopBar.BackgroundTransparency = Alpha.Win
    topCover.BackgroundTransparency = Alpha.Win
    Sidebar.BackgroundTransparency = Alpha.Win
end)
Button(S6, "Reset Search", function() Search.Text = ""; ApplySearch("") end)
InfoLabel(S6, "Use a busca acima para filtrar os cartoes.")

SwitchTab("Combat")

--// busca
Search:GetPropertyChangedSignal("Text"):Connect(function() ApplySearch(Search.Text) end)

-- fecha popup ao clicar fora
UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 and State.OpenPopup then
        local mp = UIS:GetMouseLocation()
        local p = State.OpenPopup
        if mp.X < p.AbsolutePosition.X or mp.X > p.AbsolutePosition.X + p.AbsoluteSize.X
        or mp.Y < p.AbsolutePosition.Y or mp.Y > p.AbsolutePosition.Y + p.AbsoluteSize.Y then
            p.Visible = false
            State.OpenPopup = nil
        end
    end
end)

-- ============================================================================
--  AIMBOT
-- ============================================================================
local function IsEnemy(p)
    if p == LP then return false end
    if Config.Aimbot.TeamCheck and LP.Team and p.Team == LP.Team then return false end
    return true
end

local function GetClosest()
    local closest, best = nil, math.huge
    local m = UIS:GetMouseLocation()
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if IsEnemy(p) and p.Character then
            local part = p.Character:FindFirstChild(Config.Aimbot.Part)
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - m).Magnitude
                    if d < best then best = d; closest = p end
                end
            end
        end
    end
    if Config.Aimbot.FOV_Enabled and closest then
        local part = closest.Character and closest.Character:FindFirstChild(Config.Aimbot.Part)
        if part then
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if on and (Vector2.new(sp.X, sp.Y) - m).Magnitude > Config.Aimbot.FOV_Radius then
                closest = nil
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    -- FOV
    Safe(function()
        local show = Config.Aimbot.FOV_Enabled and Config.Aimbot.Enabled
        fovCircle.Visible = show
        if show then
            fovCircle.Position = UDim2.fromOffset(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Size = UDim2.fromOffset(Config.Aimbot.FOV_Radius*2, Config.Aimbot.FOV_Radius*2)
            fovCircle.BackgroundColor3 = Config.Aimbot.FOV_Color
            fovCircle.BackgroundTransparency = Config.Aimbot.FOV_Filled and 0.75 or 1
            fovStroke.Color = Config.Aimbot.FOV_Color
        end
    end)

    -- AIMBOT
    Safe(function()
        if Config.Aimbot.Enabled and IsKeyDownName(Config.Aimbot.HoldKey) then
            local target = GetClosest()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Config.Aimbot.Part)
                if part then
                    if Config.Aimbot.WallCheck then
                        local origin = Camera.CFrame.Position
                        local dir = part.Position - origin
                        local rp = RaycastParams.new()
                        rp.FilterDescendantsInstances = {LP.Character}
                        rp.FilterType = Enum.RaycastFilterType.Exclude
                        local hit = workspace:Raycast(origin, dir.Unit * dir.Magnitude, rp)
                        if hit and not hit.Instance:IsDescendantOf(target.Character) then return end
                    end
                    local cam = Camera.CFrame
                    Camera.CFrame = cam:Lerp(CFrame.lookAt(cam.Position, part.Position), Config.Aimbot.Smoothness)
                end
            end
        end
    end)

    -- TRIGGERBOT
    Safe(function()
        if Config.Triggerbot.Enabled and os.clock() - State.LastTrigger >= Config.Triggerbot.Delay then
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {LP.Character}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, rp)
            if hit and hit.Instance then
                local model = hit.Instance:FindFirstAncestorOfClass("Model")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                local plr = model and Services.Players:GetPlayerFromCharacter(model)
                local valid = hum and hum.Health > 0 and plr and IsEnemy(plr)
                if Config.Triggerbot.DamageOnly and valid then
                    valid = hum.Health < hum.MaxHealth
                end
                if valid then
                    State.LastTrigger = os.clock()
                    if mouse1click then Safe(mouse1click)
                    elseif mouse1press and mouse1release then
                        Safe(function() mouse1press() mouse1release() end)
                    end
                end
            end
        end
    end)
end)

--// CLICK TP
UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if IsKeyDownInput(i, Config.ClickTP.HoldKey) then State.TPHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    if IsKeyDownInput(i, Config.ClickTP.HoldKey) then State.TPHeld = false end
end)

LP:GetMouse().Button1Down:Connect(function()
    Safe(function()
        if not (Config.ClickTP.Enabled and State.TPHeld) then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local ray = Camera:ViewportPointToRay(LP:GetMouse().X, LP:GetMouse().Y)
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {LP.Character}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(ray.Origin, ray.Direction * Config.ClickTP.Distance, rp)
        if hit then hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0,3,0)) end
    end)
end)

-- ============================================================================
--  ESP
-- ============================================================================
local function ESPColor(p)
    if Config.ESP.UseTeamColor and p.Team then return p.Team.TeamColor.Color end
    return GetColor(Config.ESP.ColorPreset)
end

local function MakeESP(p)
    if State.ESP[p] or p == LP then return end
    local e = {}
    local box = Instance.new("Frame", espLayer)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.ZIndex = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,3)
    local bs = Instance.new("UIStroke", box)
    bs.Name = "Stroke"
    bs.Thickness = Config.ESP.BoxThickness
    e.box = box

    local function MkText()
        local t = Instance.new("TextLabel", espLayer)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold
        t.TextStrokeTransparency = 0.45
        t.TextStrokeColor3 = Color3.new(0,0,0)
        t.AnchorPoint = Vector2.new(0.5, 0)
        t.Size = UDim2.fromOffset(240,16)
        t.ZIndex = 0
        return t
    end
    e.name = MkText()
    e.dist = MkText()
    e.dist.Font = Enum.Font.GothamMedium
    e.dist.Size = UDim2.fromOffset(240,14)

    local hpBg = Instance.new("Frame", espLayer)
    hpBg.BackgroundColor3 = Color3.new(0,0,0)
    hpBg.BackgroundTransparency = 0.45
    hpBg.BorderSizePixel = 0
    hpBg.ZIndex = 0
    e.hpBg = hpBg
    local hpFill = Instance.new("Frame", hpBg)
    hpFill.BackgroundColor3 = Color3.fromRGB(80,240,130)
    hpFill.BorderSizePixel = 0
    hpFill.ZIndex = 0
    e.hpFill = hpFill

    local tracer = Instance.new("Frame", espLayer)
    tracer.BackgroundTransparency = 0.55
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5,0.5)
    tracer.Visible = false
    tracer.ZIndex = 0
    e.tracer = tracer

    State.ESP[p] = e
end

local function DropESP(p)
    local e = State.ESP[p]
    if not e then return end
    for _, v in pairs(e) do if v and v.Destroy then v:Destroy() end end
    State.ESP[p] = nil
end

Services.Players.PlayerAdded:Connect(MakeESP)
Services.Players.PlayerRemoving:Connect(DropESP)
for _, p in ipairs(Services.Players:GetPlayers()) do MakeESP(p) end

local function HideESP(e)
    for _, v in pairs(e) do if v then v.Visible = false end end
end

RunService.RenderStepped:Connect(function()
    espLayer.Visible = Config.ESP.Enabled
    if not Config.ESP.Enabled then return end
    local vp = Camera.ViewportSize
    for p, e in pairs(State.ESP) do
        if not p.Parent or p == LP then DropESP(p); continue end
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not root or hum.Health <= 0 then HideESP(e); continue end
        if Config.ESP.TeamCheck and LP.Team and p.Team == LP.Team then HideESP(e); continue end
        local dWorld = (Camera.CFrame.Position - root.Position).Magnitude
        if dWorld > Config.ESP.MaxDistance then HideESP(e); continue end
        local head = char:FindFirstChild("Head")
        local top, on = Camera:WorldToViewportPoint(head and head.Position or root.Position + Vector3.new(0,3,0))
        if not on or top.Z < 0 then HideESP(e); continue end
        local botV = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
        local h = math.abs(top.Y - botV.Y)
        local w = h * 0.55
        local boxX = top.X - w/2
        local col = ESPColor(p)

        if Config.ESP.Box then
            e.box.Visible = true
            e.box.Position = UDim2.fromOffset(boxX, top.Y)
            e.box.Size = UDim2.fromOffset(w, h)
            e.box:FindFirstChild("Stroke").Color = col
            e.box:FindFirstChild("Stroke").Thickness = Config.ESP.BoxThickness
        else e.box.Visible = false end

        if Config.ESP.Name then
            e.name.Visible = true
            e.name.Position = UDim2.fromOffset(top.X, top.Y - 15)
            e.name.Text = p.Name
            e.name.TextColor3 = col
            e.name.TextSize = Config.ESP.NameSize
        else e.name.Visible = false end

        if Config.ESP.HealthBar then
            e.hpBg.Visible = true
            e.hpBg.Position = UDim2.fromOffset(boxX - 6, top.Y)
            e.hpBg.Size = UDim2.fromOffset(4, h)
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            e.hpFill.Position = UDim2.fromScale(0, 1 - pct)
            e.hpFill.Size = UDim2.fromScale(1, pct)
            e.hpFill.BackgroundColor3 = Color3.fromRGB(255*(1-pct), 255*pct, 0)
        else e.hpBg.Visible = false end

        if Config.ESP.Distance then
            e.dist.Visible = true
            e.dist.Position = UDim2.fromOffset(top.X, botV.Y + 2)
            e.dist.Text = math.floor(dWorld) .. "m"
            e.dist.TextColor3 = Theme.Text
            e.dist.TextSize = Config.ESP.DistanceSize
        else e.dist.Visible = false end

        if Config.ESP.Tracers then
            e.tracer.Visible = true
            local sx, sy = vp.X/2, vp.Y
            if Config.ESP.TracerOrigin == "Center" then sx, sy = vp.X/2, vp.Y/2 end
            if Config.ESP.TracerOrigin == "Mouse" then local m = UIS:GetMouseLocation(); sx, sy = m.X, m.Y end
            local ex, ey = top.X, top.Y + h
            e.tracer.Position = UDim2.fromOffset((sx+ex)/2, (sy+ey)/2)
            e.tracer.Size = UDim2.fromOffset(math.sqrt((ex-sx)^2 + (ey-sy)^2), 1.5)
            e.tracer.Rotation = math.deg(math.atan2(ey - sy, ex - sx))
            e.tracer.BackgroundColor3 = col
        else e.tracer.Visible = false end
    end
end)

-- ============================================================================
--  FLY
-- ============================================================================
startFly = function()
    Safe(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if State.FlyVel then State.FlyVel:Destroy() end
        if State.FlyGyro then State.FlyGyro:Destroy() end
        State.FlyVel = Instance.new("BodyVelocity", hrp)
        State.FlyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
        State.FlyVel.Velocity = Vector3.zero
        State.FlyGyro = Instance.new("BodyGyro", hrp)
        State.FlyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
        State.FlyGyro.P = 100000
        State.FlyGyro.CFrame = hrp.CFrame
        hum.PlatformStand = true
    end)
end

stopFly = function()
    Safe(function()
        if State.FlyVel then State.FlyVel:Destroy(); State.FlyVel = nil end
        if State.FlyGyro then State.FlyGyro:Destroy(); State.FlyGyro = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
end

RunService.RenderStepped:Connect(function()
    if not Config.Fly.Enabled then return end
    if not State.FlyVel or not State.FlyVel.Parent or not State.FlyGyro then
        if LP.Character then startFly() end
        return
    end
    Safe(function()
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit end
        local target = move * Config.Fly.Speed
        if Config.Fly.SmoothAccel then
            State.FlyVel.Velocity = State.FlyVel.Velocity:Lerp(target, 0.15)
        else
            State.FlyVel.Velocity = target
        end
        State.FlyGyro.CFrame = Camera.CFrame
    end)
end)

-- ============================================================================
--  NOCLIP / GHOST / SPIN / BUNNYHOP / SPEED
-- ============================================================================
RunService.Stepped:Connect(function()
    if Config.Noclip then
        Safe(function()
            local char = LP.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    if Config.Ghost.Enabled then
        Safe(function()
            local char = LP.Character
            if not char then return end
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    if State.GhostStored[d] == nil then
                        State.GhostStored[d] = {T = d.Transparency, C = d.CanCollide}
                    end
                    d.Transparency = Config.Ghost.Transparency
                    d.LocalTransparencyModifier = 1
                    d.CanCollide = false
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    if State.GhostStored[d] == nil then State.GhostStored[d] = {T = d.Transparency} end
                    d.Transparency = 1
                elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Fire")
                    or d:IsA("Smoke") or d:IsA("Sparkles") then
                    if State.ParticleCache[d] == nil then State.ParticleCache[d] = d.Enabled end
                    d.Enabled = false
                end
            end
        end)
    end
end)

ghostApply = function()
    State.GhostStored = {}
    State.ParticleCache = {}
end

ghostRestore = function()
    Safe(function()
        for inst, data in pairs(State.GhostStored) do
            if inst and inst.Parent then
                if data.T ~= nil then inst.Transparency = data.T end
                if data.C ~= nil then inst.CanCollide = data.C end
                inst.LocalTransparencyModifier = 0
            end
        end
        for e, v in pairs(State.ParticleCache) do
            if e and e.Parent then e.Enabled = v end
        end
        State.GhostStored = {}
        State.ParticleCache = {}
    end)
end

local lastHop = 0
RunService.RenderStepped:Connect(function()
    Safe(function()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if Config.Speed.Enabled then hum.WalkSpeed = Config.Speed.Value end
        hum.JumpPower = Config.JumpPower
        if Camera.FieldOfView ~= Config.FOV then Camera.FieldOfView = Config.FOV end
        if Config.Spin.Enabled and hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.Spin.Speed), 0)
        end
        if Config.BunnyHop.Enabled and hum:GetState() == Enum.HumanoidStateType.Landed then
            if os.clock() - lastHop > 0.1 then
                lastHop = os.clock()
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end)

workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
    if workspace.Gravity ~= Config.Gravity then workspace.Gravity = Config.Gravity end
end)

UIS.JumpRequest:Connect(function()
    if Config.InfJump then
        Safe(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

-- ============================================================================
--  UTILIDADES
-- ============================================================================
startAntiAFK = function()
    Safe(function()
        local vu = game:GetService("VirtualUser")
        LP.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
end
if Config.AntiAFK then startAntiAFK() end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    Safe(function()
        if Config.Fly.Enabled then startFly() end
        if Config.Ghost.Enabled then ghostApply() end
        workspace.Gravity = Config.Gravity
    end)
end)

-- VC loop
task.spawn(function()
    while true do
        task.wait(1.5)
        Safe(function()
            if Config.VCBypass then
                local ref = cloneref or function(x) return x end
                local v = State.VCC or ref(game:GetService("VoiceChatService"))
                State.VCC = v
                if not v.EnableDefaultVoice then v.EnableDefaultVoice = true end
                v:joinVoice()
            end
        end)
    end
end)

-- gravidade inicial
workspace.Gravity = Config.Gravity
Lighting.ClockTime = Config.ClockTime
