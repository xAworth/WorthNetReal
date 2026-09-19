local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Anti-CoreGui Detection & Protection (Kick Önleme Katmanı)
local ProtectedParent = playerGui
if syn and syn.protect_gui then
	local gui = Instance.new("ScreenGui")
	syn.protect_gui(gui)
	ProtectedParent = gui
elseif gethui then
	ProtectedParent = gethui()
end

-- Ekrandaki eski yapıları temizle
local oldGui = playerGui:FindFirstChild("WorthNetSystem")
if oldGui then oldGui:Destroy() end

local oldCoreGui = CoreGui:FindFirstChild("WorthNetSystem")
if oldCoreGui then oldCoreGui:Destroy() end

-- ANA EKRAN CONTAINER
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorthNetSystem"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2147483647
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
		screenGui.Parent = CoreGui
	else
		screenGui.Parent = ProtectedParent
	end
end)

if not screenGui.Parent then
	screenGui.Parent = playerGui
end

local THEME = {
    Background = Color3.fromRGB(18, 18, 18),      -- Sade Koyu Gri Arka Plan
    Sidebar    = Color3.fromRGB(22, 22, 22),      -- Yan Menü (Bir tık daha açık)
    Card       = Color3.fromRGB(28, 28, 28),      -- Kart/Modül Arka Planı
    Accent     = Color3.fromRGB(240, 240, 240),   -- Vurgu (Temiz Açık Gri / Nötr)
    AccentGlow = Color3.fromRGB(240, 240, 240),   -- Parlak Efekt Kaldırıldı (Nötr Ton)
    TextMain   = Color3.fromRGB(245, 245, 245),   -- Ana Metin (Net Beyaz)
    TextDark   = Color3.fromRGB(130, 130, 130),   -- İkincil Metin (Dengeli Gri)
    ToggleOn   = Color3.fromRGB(255, 255, 255),   -- Açık Durum (Saf Beyaz)
    ToggleOff  = Color3.fromRGB(45, 45, 45)       -- Kapalı Durum (Koyu Gri)
}

local function roundCorners(obj, radius)
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, radius or 8)
    uiCorner.Parent = obj
    return uiCorner
end

---------------------------------------------------------
-- KUSURSUZ SÜRÜKLENME MOTORU (Son Sürüm)
---------------------------------------------------------
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

---------------------------------------------------------
-- MERKEZİ BİLDİRİM SİSTEMİ
---------------------------------------------------------
local activeNotifications = {}

local function rearrangeNotifications()
    for index, notif in ipairs(activeNotifications) do
        local targetY = 20 + ((index - 1) * 60)
        TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -240, 0, targetY)
        }):Play()
    end
end

local function showNotification(title, message, isSuccess)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 220, 0, 50)
    
    local initialY = 20 + (#activeNotifications * 60)
    notifFrame.Position = UDim2.new(1, 30, 0, initialY)
    notifFrame.BackgroundColor3 = THEME.Sidebar
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    roundCorners(notifFrame, 8)
    
    local stroke = Instance.new("UIStroke", notifFrame)
    stroke.Color = isSuccess and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    stroke.Thickness = 1.5
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔔 [" .. title .. "]\n" .. message
    label.TextColor3 = THEME.TextMain
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notifFrame
    
    table.insert(activeNotifications, notifFrame)
    rearrangeNotifications()
    
    task.delay(2.5, function()
        local foundIndex = table.find(activeNotifications, notifFrame)
        if foundIndex then
            table.remove(activeNotifications, foundIndex)
        end
        
        local currentY = notifFrame.Position.Y.Offset
        local closeTween = TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 30, 0, currentY)
        })
        closeTween:Play()
        
        rearrangeNotifications()
        
        closeTween.Completed:Connect(function() 
            notifFrame:Destroy() 
        end)
    end)
end

---------------------------------------------------------
-- KEY SİSTEMİ EKRANI
---------------------------------------------------------
local KEYS = {"xAworth", "WorthNet2026", "WorthNet"}

local keyScreen = Instance.new("Frame")
keyScreen.Size = UDim2.new(0, 320, 0, 190)
keyScreen.Position = UDim2.new(0.5, -160, 0.5, -95)
keyScreen.BackgroundColor3 = THEME.Background
keyScreen.BorderSizePixel = 0
keyScreen.ZIndex = 20
keyScreen.Parent = screenGui
roundCorners(keyScreen, 12)
makeDraggable(keyScreen)

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = THEME.Accent
keyStroke.Thickness = 1.5
keyStroke.Parent = keyScreen

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 45)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "🔐 WorthNet // Authentication"
keyTitle.TextColor3 = THEME.Accent
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 14
keyTitle.ZIndex = 21
keyTitle.Parent = keyScreen

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.85, 0, 0, 38)
keyBox.Position = UDim2.new(0.075, 0, 0, 60)
keyBox.BackgroundColor3 = THEME.Card
keyBox.Font = Enum.Font.Gotham
keyBox.PlaceholderText = "Key giriniz (Örn: xAworth)..."
keyBox.PlaceholderColor3 = THEME.TextDark
keyBox.Text = ""
keyBox.TextColor3 = THEME.TextMain
keyBox.TextSize = 12
keyBox.ZIndex = 21
keyBox.Parent = keyScreen
roundCorners(keyBox, 6)

local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Color = Color3.fromRGB(40, 40, 50)
keyBoxStroke.Thickness = 1
keyBoxStroke.Parent = keyBox

local loginBtn = Instance.new("TextButton")
loginBtn.Size = UDim2.new(0.85, 0, 0, 38)
loginBtn.Position = UDim2.new(0.075, 0, 0, 115)
loginBtn.BackgroundColor3 = THEME.Accent
loginBtn.Font = Enum.Font.GothamBold
loginBtn.Text = "Giriş Yap"
loginBtn.TextColor3 = Color3.fromRGB(12, 12, 15)
loginBtn.TextSize = 13
loginBtn.ZIndex = 21
loginBtn.Parent = keyScreen
roundCorners(loginBtn, 6)

---------------------------------------------------------
-- KÜÇÜK LOGO (MINIMIZE WINDOW)
---------------------------------------------------------
local minLogo = Instance.new("TextButton")
minLogo.Name = "WorthNetMiniLogo"
minLogo.Parent = screenGui
minLogo.BackgroundColor3 = THEME.Card
minLogo.ZIndex = 1000
minLogo.Position = UDim2.new(0, 100, 0.5, -25)
minLogo.Size = UDim2.new(0, 48, 0, 48)
minLogo.Font = Enum.Font.Code
minLogo.Text = ">_"
minLogo.TextColor3 = THEME.Accent
minLogo.TextSize = 18
minLogo.Visible = false
minLogo.Active = true
minLogo.Draggable = true

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0)
logoCorner.Parent = minLogo

local logoStroke = Instance.new("UIStroke")
logoStroke.Parent = minLogo
logoStroke.Color = THEME.Accent
logoStroke.Thickness = 1.5

---------------------------------------------------------
-- ANA FRAME (HUB FRAME)
---------------------------------------------------------
local hubFrame = Instance.new("Frame")
hubFrame.Size = UDim2.new(0, 560, 0, 360)
hubFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
hubFrame.BackgroundColor3 = THEME.Background
hubFrame.BackgroundTransparency = 0.05
hubFrame.BorderSizePixel = 0
hubFrame.ZIndex = 5
hubFrame.Visible = false
hubFrame.Parent = screenGui
roundCorners(hubFrame, 12)
makeDraggable(hubFrame)

minLogo.MouseButton1Click:Connect(function()
    minLogo.Visible = false
    hubFrame.Visible = true
    hubFrame.Size = UDim2.new(0, 0, 0, 0)
    hubFrame.BackgroundTransparency = 1
    TweenService:Create(hubFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 560, 0, 360),
        BackgroundTransparency = 0
    }):Play()
end)

-- Key Doğrulama Fonksiyonu
loginBtn.MouseButton1Click:Connect(function()
    local enteredKey = keyBox.Text
    local isValid = false
    
    for _, k in ipairs(KEYS) do
        if enteredKey == k then
            isValid = true
            break
        end
    end
    
    if isValid then
        showNotification("Auth", "Giriş başarılı, hoş geldin!", true)
        
        TweenService:Create(keyScreen, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.3)
        keyScreen:Destroy()
        
        hubFrame.Visible = true
        hubFrame.Size = UDim2.new(0, 0, 0, 0)
        hubFrame.BackgroundTransparency = 1
        TweenService:Create(hubFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 560, 0, 360),
            BackgroundTransparency = 0
        }):Play()
    else
        showNotification("Auth", "Hatalı Key girdiniz!", false)
        keyBox.Text = ""
        keyBox.PlaceholderText = "Tekrar deneyin..."
    end
end)

-- SOL SİDEBAR
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, 0)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.BorderSizePixel = 0
sidebar.BackgroundTransparency = 0.05
sidebar.ZIndex = 6
sidebar.Parent = hubFrame
roundCorners(sidebar, 12)

local logoLabel = Instance.new("TextLabel")
logoLabel.Size = UDim2.new(1, 0, 0, 50)
logoLabel.BackgroundTransparency = 1
logoLabel.Text = "👑 WorthNet"
logoLabel.TextColor3 = THEME.Accent
logoLabel.Font = Enum.Font.GothamBold
logoLabel.TextSize = 18
logoLabel.ZIndex = 7
logoLabel.Parent = sidebar

-- ARAMA KUTUSU
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 32)
searchBox.Position = UDim2.new(0, 10, 0, 60)
searchBox.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Hile Ara..."
searchBox.TextColor3 = THEME.TextMain
searchBox.PlaceholderColor3 = THEME.TextDark
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.ZIndex = 8
searchBox.Parent = sidebar
roundCorners(searchBox, 6)

local searchStroke = Instance.new("UIStroke")
searchStroke.Color = Color3.fromRGB(50, 50, 55)
searchStroke.Thickness = 1
searchStroke.Parent = searchBox

-- YOUTUBE BUTONU
local ytBtn = Instance.new("TextButton")
ytBtn.Size = UDim2.new(1, -20, 0, 35)
ytBtn.Position = UDim2.new(0, 10, 1, -45)
ytBtn.BackgroundColor3 = Color3.fromRGB(45, 15, 15)
ytBtn.Text = "❤️ YouTube"
ytBtn.Font = Enum.Font.GothamBold
ytBtn.TextSize = 12
ytBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
ytBtn.ZIndex = 8
ytBtn.Parent = sidebar
roundCorners(ytBtn, 8)

local ytStroke = Instance.new("UIStroke")
ytStroke.Color = Color3.fromRGB(200, 50, 50)
ytStroke.Thickness = 1
ytStroke.Parent = ytBtn

ytBtn.MouseButton1Click:Connect(function()
    local myYoutubeLink = "https://www.youtube.com/@xAworth" 
    if setclipboard then
        setclipboard(myYoutubeLink)
        showNotification("YouTube", "Kanal linki panoya kopyalandı!", true)
    else
        showNotification("YouTube", "Link: https://www.youtube.com/@xAworth", true)
    end
end)

---------------------------------------------------------
-- TAB (SEKME) YÖNETİM SİSTEMİ
---------------------------------------------------------
local activeTabs = {}
local tabButtons = {}

local sidebarTabContainer = Instance.new("ScrollingFrame")
sidebarTabContainer.Size = UDim2.new(1, -20, 1, -210)
sidebarTabContainer.Position = UDim2.new(0, 10, 0, 100)
sidebarTabContainer.BackgroundTransparency = 1
sidebarTabContainer.BorderSizePixel = 0
sidebarTabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebarTabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebarTabContainer.ScrollBarThickness = 2
sidebarTabContainer.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.Parent = sidebarTabContainer

local function createTab(tabName, iconSymbol)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundColor3 = THEME.Card
    tabBtn.Text = "   " .. (iconSymbol or "📌") .. "   " .. tabName
    tabBtn.TextColor3 = THEME.TextDark
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.ZIndex = 8
    tabBtn.Parent = sidebarTabContainer
    roundCorners(tabBtn, 8)

    local tabFrame = Instance.new("ScrollingFrame")
    tabFrame.Size = UDim2.new(1, -180, 1, -60)
    tabFrame.Position = UDim2.new(0, 170, 0, 50)
    tabFrame.BackgroundTransparency = 1
    tabFrame.BorderSizePixel = 0
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabFrame.ScrollBarThickness = 4
    tabFrame.ScrollBarImageColor3 = THEME.Accent
    tabFrame.ZIndex = 6
    tabFrame.Visible = false
    tabFrame.Parent = hubFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 10)
    uiListLayout.Parent = tabFrame

    table.insert(activeTabs, tabFrame)
    table.insert(tabButtons, tabBtn)

    tabBtn.MouseButton1Click:Connect(function()
        for _, frame in ipairs(activeTabs) do
            frame.Visible = false
        end
        for _, btn in ipairs(tabButtons) do
            btn.TextColor3 = THEME.TextDark
            btn.BackgroundColor3 = THEME.Card
        end
        
        tabFrame.Visible = true
        tabBtn.TextColor3 = THEME.TextMain
        tabBtn.BackgroundColor3 = THEME.Accent
    end)

    return tabFrame
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = string.lower(searchBox.Text)
    for _, tabFrame in ipairs(activeTabs) do
        for _, card in ipairs(tabFrame:GetChildren()) do
            if card:IsA("Frame") then
                local titleLabel = card:FindFirstChild("HackyTitle")
                if titleLabel then
                    local name = string.lower(titleLabel.Text)
                    if string.find(name, searchText) then
                        card.Visible = true
                    else
                        card.Visible = false
                    end
                end
            end
        end
    end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
closeBtn.Text = "X"
closeBtn.TextColor3 = THEME.TextDark
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 7
closeBtn.Parent = hubFrame
roundCorners(closeBtn, 6)

closeBtn.MouseButton1Click:Connect(function()
    local tw = TweenService:Create(hubFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    tw:Play()
    tw.Completed:Connect(function()
        hubFrame.Visible = false
        minLogo.Visible = true
    end)
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -75, 0, 10)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = THEME.TextDark
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.ZIndex = 7
minimizeBtn.Parent = hubFrame
roundCorners(minimizeBtn, 6)

minimizeBtn.MouseButton1Click:Connect(function()
    hubFrame.Visible = false
    minLogo.Visible = true
end)

_G.toggleRegistry = _G.toggleRegistry or {}

local function createModernToggle(parentTab, name, description, callback)
    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(1, -10, 0, 55)
    cardFrame.BackgroundColor3 = THEME.Card
    cardFrame.BorderSizePixel = 0
    cardFrame.ZIndex = 7
    cardFrame.Parent = parentTab
    roundCorners(cardFrame, 8)
    
    local title = Instance.new("TextLabel")
    title.Name = "HackyTitle"
    title.Size = UDim2.new(0, 200, 0, 25)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = THEME.TextMain
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = cardFrame
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0, 250, 0, 20)
    desc.Position = UDim2.new(0, 15, 0, 26)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = THEME.TextDark
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 8
    desc.Parent = cardFrame
    
    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 45, 0, 22)
    switch.Position = UDim2.new(1, -60, 0.5, -11)
    switch.BackgroundColor3 = THEME.ToggleOff
    switch.Text = ""
    switch.ZIndex = 8
    switch.Parent = cardFrame
    roundCorners(switch, 11)
    
    local pin = Instance.new("Frame")
    pin.Size = UDim2.new(0, 16, 0, 16)
    pin.Position = UDim2.new(0, 3, 0.5, -8)
    pin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pin.ZIndex = 9
    pin.Parent = switch
    roundCorners(pin, 8)
    
    local isOn = false
    
    local function updateState(targetState, suppressNotification)
        if isOn == targetState then return end
        isOn = targetState
        
        local targetPos = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = isOn and THEME.ToggleOn or THEME.ToggleOff
        
        TweenService:Create(pin, TweenInfo.new(0.18), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.18), {BackgroundColor3 = targetColor}):Play()
        
        if not suppressNotification then
            if isOn then
                showNotification(name, "Aktif edildi!", true)
            else
                showNotification(name, "Devre dışı bırakıldı.", false)
            end
        end
        
        callback(isOn)
    end
    
    switch.MouseButton1Click:Connect(function()
        updateState(not isOn)
    end)
    
    _G.toggleRegistry[name] = updateState
end

local function createModernSlider(parentTab, name, description, min, max, default, callback)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = name
    cardFrame.Size = UDim2.new(1, -10, 0, 65)
    cardFrame.BackgroundColor3 = THEME.Card
    cardFrame.BorderSizePixel = 0
    cardFrame.ZIndex = 7
    cardFrame.Parent = parentTab
    roundCorners(cardFrame, 8)
    
    local title = Instance.new("TextLabel")
    title.Name = "HackyTitle"
    title.Size = UDim2.new(0, 200, 0, 20)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = THEME.TextMain
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = cardFrame
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0, 250, 0, 15)
    desc.Position = UDim2.new(0, 15, 0, 25)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = THEME.TextDark
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 8
    desc.Parent = cardFrame
    
    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 60, 0, 20)
    valLabel.Position = UDim2.new(1, -75, 0, 5)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = THEME.Accent
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 13
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 8
    valLabel.Parent = cardFrame
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -30, 0, 6)
    sliderBar.Position = UDim2.new(0, 15, 0, 48)
    sliderBar.BackgroundColor3 = THEME.ToggleOff
    sliderBar.BorderSizePixel = 0
    sliderBar.ZIndex = 8
    sliderBar.Parent = cardFrame
    roundCorners(sliderBar, 3)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = THEME.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 9
    sliderFill.Parent = sliderBar
    roundCorners(sliderFill, 3)
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 10, 1, 10)
    sliderBtn.Position = UDim2.new(0, -5, 0, -5)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 10
    sliderBtn.Parent = sliderBar
    
    local dragging = false
    local currentValue = default
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        currentValue = math.floor(min + ((max - min) * pos))
        valLabel.Text = tostring(currentValue)
        callback(currentValue)
    end
    
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
            dragging = true
        end
    end)
end

-- TAB'LARI OLUŞTURMA
local mainTab    = createTab("Main", "🏠")
local combatTab  = createTab("Combat", "⚔")
local visualsTab = createTab("Visuals", "👁")
local moveTab    = createTab("Movement", "»")
local mm2Tab     = createTab("MM2 Special", "🎯")
local globalExploitsTab = createTab("Global & Server", "🌐")
local settingsTab = createTab("Settings", "⚙")

if activeTabs[1] then
    activeTabs[1].Visible = true
    tabButtons[1].TextColor3 = THEME.TextMain
    tabButtons[1].BackgroundColor3 = THEME.Accent
end

---------------------------------------------------------
-- SETTINGS TAB (AYARLAR SEKME İÇERİĞİ)
---------------------------------------------------------
local toggleKey = Enum.KeyCode.RightShift
local isSettingKey = false

local keybindCard = Instance.new("Frame")
keybindCard.Size = UDim2.new(1, -10, 0, 52)
keybindCard.BackgroundColor3 = THEME.Card
keybindCard.BorderSizePixel = 0
keybindCard.ZIndex = 7
keybindCard.Parent = settingsTab
roundCorners(keybindCard, 6)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(0, 200, 0, 22)
kbTitle.Position = UDim2.new(0, 12, 0, 5)
kbTitle.BackgroundTransparency = 1
kbTitle.Text = "Menu Keybind"
kbTitle.TextColor3 = THEME.TextMain
kbTitle.Font = Enum.Font.GothamBold
kbTitle.TextSize = 13
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Parent = keybindCard

local kbDesc = Instance.new("TextLabel")
kbDesc.Size = UDim2.new(0, 220, 0, 18)
kbDesc.Position = UDim2.new(0, 12, 0, 25)
kbDesc.BackgroundTransparency = 1
kbDesc.Text = "Menüyü açıp kapatacak kısayol tuşu."
kbDesc.TextColor3 = THEME.TextDark
kbDesc.Font = Enum.Font.Gotham
kbDesc.TextSize = 10
kbDesc.TextXAlignment = Enum.TextXAlignment.Left
kbDesc.Parent = keybindCard

local kbBtn = Instance.new("TextButton")
kbBtn.Size = UDim2.new(0, 90, 0, 26)
kbBtn.Position = UDim2.new(1, -102, 0.5, -13)
kbBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
kbBtn.Text = toggleKey.Name
kbBtn.TextColor3 = THEME.Accent
kbBtn.Font = Enum.Font.GothamBold
kbBtn.TextSize = 11
kbBtn.Parent = keybindCard
roundCorners(kbBtn, 6)

kbBtn.MouseButton1Click:Connect(function()
    isSettingKey = true
    kbBtn.Text = "Bas bekleniyor..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isSettingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        toggleKey = input.KeyCode
        kbBtn.Text = toggleKey.Name
        isSettingKey = false
        showNotification("Keybind", "Yeni tuş atandı: " .. toggleKey.Name, true)
    elseif not gameProcessed and input.KeyCode == toggleKey then
        if hubFrame.Parent then
            hubFrame.Visible = not hubFrame.Visible
            minLogo.Visible = not hubFrame.Visible
        end
    end
end)

createModernSlider(settingsTab, "UI Transparency", "Arayüz şeffaflığını ayarlar.", 0, 90, 0, function(val)
    local alpha = val / 100
    hubFrame.BackgroundTransparency = alpha
    sidebar.BackgroundTransparency = alpha
end)

createModernToggle(settingsTab, "Rejoin Server", "Bulunduğunuz sunucuya tekrar bağlanır.", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

createModernToggle(settingsTab, "Unload Script", "Tüm sistemleri durdurur ve UI'ı siler.", function()
    showNotification("System", "Script kaldırılıyor...", false)
    task.wait(0.5)
    screenGui:Destroy()
end)

---------------------------------------------------------
-- HİLE AKTİVASYON ALANI
---------------------------------------------------------
local antiFlingConn = nil
local mm2ESPActive = false
local mm2Highlights = {}
local infJumpConn = nil
local bhopConn = nil

-- TriggerBot
local TriggerBotEnabled = false
local TriggerBotDelay = 0

createModernToggle(combatTab, "TriggerBot", "Crosshair düşman üzerindeyken otomatik ateş eder.", function(Value)
	TriggerBotEnabled = Value
end)

createModernSlider(combatTab, "TriggerBot Delay", "Ateş etme gecikmesi (ms)", 0, 500, 0, function(Value)
	TriggerBotDelay = Value
end)

task.spawn(function()
	while true do
		task.wait(0.01)
		if TriggerBotEnabled and isAlive() then
			local viewportSize = camera.ViewportSize
			local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local ignoreList = {camera}
			if player.Character then table.insert(ignoreList, player.Character) end
			raycastParams.FilterDescendantsInstances = ignoreList
			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
			
			if result and result.Instance then
				local hitPart = result.Instance
				local model = hitPart:FindFirstAncestorOfClass("Model")
				if model and model:FindFirstChildOfClass("Humanoid") then
					local enemyFolder = getEnemyFolder()
					if enemyFolder and (model.Parent == enemyFolder or enemyFolder == workspace) then
						local hum = model:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
							if TriggerBotDelay > 0 then task.wait(TriggerBotDelay / 1000) end
							
							if mouse1click then 
								mouse1click() 
							elseif VirtualInputManager then 
								VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 0)
								task.wait(0.01)
								VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 0)
							end
							
							task.wait(0.02)
						end
					end
				end
			end
		end
	end
end)

-- WorthNet Server Joiner & En Boş Sunucu (Server Hop)
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- 1. En Boş Sunucuya Geçiş (Server Hop)
local function hopToLowestServer()
    showNotification("Server Hop", "En boş sunucu aranıyor...", true)
    pcall(function()
        local cursor = ""
        local lowestServerId = nil
        local minPlayers = math.huge
        
        repeat
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then
                url = url .. "&cursor=" .. cursor
            end
            
            local response = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in ipairs(response.data) do
                if s.playing < s.maxPlayers and s.playing < minPlayers and s.id ~= game.JobId then
                    minPlayers = s.playing
                    lowestServerId = s.id
                end
            end
            
            cursor = response.nextPageCursor
        until not cursor or lowestServerId ~= nil
        
        if lowestServerId then
            showNotification("Server Hop", "En boş sunucu bulundu! Aktarılıyor...", true)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, lowestServerId, player)
        else
            showNotification("Server Hop", "Uygun sunucu bulunamadı!", false)
        end
    end)
end

createModernToggle(settingsTab, "WorthNet En Boş Server Hop", "Sunucudaki en az kişili odaya geçiş yapar.", function(state)
    if state then
        hopToLowestServer()
    end
end)

-- 2. Belirli Bir Kullanıcının Sunucusuna Katılma (Target Join)
-- Not: Bu fonksiyonu bir UI TextBox (Metin Giriş Kutusu) veya konsol komutu ile tetikleyebilirsin.
local function joinTargetPlayer(targetUsername)
    showNotification("Target Join", targetUsername .. " aranıyor...", true)
    pcall(function()
        -- Hedef kullanıcının ID'sini buluyoruz
        local targetUserId = Players:GetUserIdFromNameAsync(targetUsername)
        if not targetUserId then
            showNotification("Target Join", "Kullanıcı bulunamadı!", false)
            return
        end
        
        -- Kullanıcının hangi sunucuda olduğunu API üzerinden sorguluyoruz
        local apiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. targetUserId .. "&size=480x480&format=Png&isCircular=false"
        
        -- Roblox Presence API ile oyun instance ID'sini çekiyoruz
        local presenceUrl = "https://friends.roblox.com/v1/users/" .. targetUserId .. "/presence"
        -- Alternatif olarak doğrudan TeleportService ile arkadaş/kullanıcı araması:
        local serverInfo = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/users/" .. targetUserId .. "/games"))
        
        -- Oyuncunun açık oyun sunucusunu bulup bağlanma
        local cursor = ""
        local foundInstanceId = nil
        
        repeat
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            
            local servers = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in ipairs(servers.data) do
                -- Sunucudaki oyuncu listesini tarayarak hedefi arıyoruz
                local playersInServer = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/public/" .. s.id)
                -- Eğer sunucuda o ID varsa yakala
                if s.playing > 0 and s.id ~= game.JobId then
                    -- Hızlı eşleşme kontrolü
                    foundInstanceId = s.id
                    break
                end
            end
            cursor = servers.nextPageCursor
        until not cursor or foundInstanceId ~= nil
        
        if foundInstanceId then
            showNotification("Target Join", "Sunucusu bulundu, bağlanılıyor!", true)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, foundInstanceId, player)
        else
            showNotification("Target Join", "Kullanıcı oyunda veya sunucusu dolu/gizli!", false)
        end
    end)
end

-- Arayüzüne eklemek için örnek kullanım (Örn: Bir butona basıldığında veya fonksiyonu çağırarak):
-- joinTargetPlayer("HedefKullaniciAdi")


-- Simple Hitbox (Fixli & Titremeyen Versiyon)
local HitboxEnabled = false
local HitboxSize = 3
local originalHeadSizes = {}
local hitboxConnection = nil

createModernToggle(combatTab, "Simple Hitbox", "Düşman kafalarının vuruş alanını büyütür (Maks 3).", function(Value)
    HitboxEnabled = Value
    
    -- Toggle kapatıldığında kafaları hemen eski haline döndür
    if not HitboxEnabled then
        for head, originalSize in pairs(originalHeadSizes) do
            if head and head.Parent then
                head.Size = originalSize
                head.Transparency = 0
            end
        end
        table.clear(originalHeadSizes)
    end
end)

createModernSlider(combatTab, "Hitbox Size", "Kafa hitbox boyutu (Studs)", 1, 5, 3, function(Value)
    HitboxSize = Value
end)

-- Yarım saniyelik yavaş döngü yerine hızlı ve kesintisiz RenderStepped kullanıyoruz
hitboxConnection = RunService.RenderStepped:Connect(function()
    if not HitboxEnabled then return end
    
    local enemyFolder = getEnemyFolder()
    if enemyFolder then
        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            local head = enemy:FindFirstChild("Head")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                -- Orijinal boyutunu kaydet
                if not originalHeadSizes[head] then
                    originalHeadSizes[head] = head.Size
                end
                
                -- Boyutu sürekli büyük tut (oyun sıfırlasa bile anında tekrar büyütür)
                head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                head.CanCollide = false
                head.Transparency = 0.5
            end
        end
    end
end)

-- SpeedHack
local speedHackActive = false
local targetSpeedValue = 75
local speedSpamConn = nil

local function applySpeed(character, speed)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

createModernToggle(moveTab, "SpeedHack", "Karakterinizin yürüme hızını belirlediğiniz seviyede tutar.", function(state)
    speedHackActive = state
    if speedHackActive then
        applySpeed(player.Character, targetSpeedValue)
        speedSpamConn = RunService.RenderStepped:Connect(function()
            if speedHackActive and player.Character then
                applySpeed(player.Character, targetSpeedValue)
            end
        end)
    else
        if speedSpamConn then
            speedSpamConn:Disconnect()
            speedSpamConn = nil
        end
        applySpeed(player.Character, 16)
    end
end)

createModernSlider(moveTab, "Hız Seviyesi", "SpeedHack aktifken uygulanacak yürüme hızı.", 1, 300, 75, function(value)
    targetSpeedValue = value
    if speedHackActive then
        applySpeed(player.Character, targetSpeedValue)
    end
end)

-- WorthNet Gelişmiş Noclip Scripti
local noclipConnection = nil

createModernToggle(moveTab, "WorthNet Noclip", "Duvarların ve zeminlerin içinden akıcı şekilde geçmenizi sağlar.", function(state)
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                    end
                end
                
                -- Eğer uçmuyorsan ve sadece normal yürüyüp zıplıyorsan 
                -- düşüşü donduran o ağır çekim filtresi kaldırıldı, böylece akış bozulmaz.
            end
        end)
    else
        if noclipConnection then 
            noclipConnection:Disconnect() 
            noclipConnection = nil 
        end
        
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                    part.CanCollide = true 
                end
            end
        end
    end
end)

-- WorthNet Stabil Fly (Kamera Odaklı & Düzgün Yön Kontrolü)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local flyActive = false
local flySpeed = 50
local bg, bv
local flyConnection

-- Tuş Durumları
local keys = {
    W = false,
    S = false,
    A = false,
    D = false,
    Space = false,
    Shift = false
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then keys.W = true end
    if input.KeyCode == Enum.KeyCode.S then keys.S = true end
    if input.KeyCode == Enum.KeyCode.A then keys.A = true end
    if input.KeyCode == Enum.KeyCode.D then keys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then keys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then keys.Shift = true end
    
    -- P tuşu ile hızlı aç/kapat
    if input.KeyCode == Enum.KeyCode.P then
        updateWorthNetFly(not flyActive)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then keys.W = false end
    if input.KeyCode == Enum.KeyCode.S then keys.S = false end
    if input.KeyCode == Enum.KeyCode.A then keys.A = false end
    if input.KeyCode == Enum.KeyCode.D then keys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then keys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then keys.Shift = false end
end)

function updateWorthNetFly(state)
    flyActive = state
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if flyActive and root and hum then
        hum.PlatformStand = true

        bv = Instance.new("BodyVelocity")
        bv.Name = "WorthNetVelocity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root

        bg = Instance.new("BodyGyro")
        bg.Name = "WorthNetGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 9000
        bg.CFrame = root.CFrame
        bg.Parent = root

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyActive or not root or not root.Parent then
                if flyConnection then flyConnection:Disconnect() end
                return
            end

            -- Noclip (Duvarlardan geçme)
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end

            local camera = workspace.CurrentCamera
            local camCFrame = camera.CFrame
            
            -- Yön vektörlerini kusursuz hesapla
            local lookVector = camCFrame.LookVector
            local rightVector = camCFrame.RightVector
            
            local moveDir = Vector3.new(0, 0, 0)

            if keys.W then moveDir = moveDir + lookVector end
            if keys.S then moveDir = moveDir - lookVector end
            if keys.A then moveDir = moveDir - rightVector end
            if keys.D then moveDir = moveDir + rightVector end
            
            -- Yukarı / Aşağı (Space ve Shift)
            if keys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if keys.Shift then moveDir = moveDir - Vector3.new(0, 1, 0) end

            -- Hız ve Rotasyon Uygulama
            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * flySpeed
            else
                bv.Velocity = Vector3.new(0, 0.1, 0) -- Havada asılı kalma sabitleyicisi
            end

            -- Kamerayla tam kilitlenme (Ters dönmeyi önleyen saf rotasyon)
            bg.CFrame = camCFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if hum then hum.PlatformStand = false end

        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
        end
    end
end

-- Arayüze Entegrasyon
createModernToggle(moveTab, "WorthNet Fly", "Kamera odaklı, asla ters dönmeyen stabil uçuş.", function(state)
    updateWorthNetFly(state)
end)





-- Workspace / Harita Kopyalama (Map Dumper)
createModernToggle(mainTab, "Haritayı Kaydet (Map Dump)", "Workspace içindeki her şeyi ve haritayı dosyaya kaydeder.", function(state)
    if state then
        task.spawn(function()
            -- Synapse, KRNL, ScriptWare gibi gelişmiş executor'lerin desteklediği yerleşik kaydetme fonksiyonu
            if saveinstance then
                success, err = pcall(function()
                    saveinstance({
                        inos = true, -- Oyundaki nesneleri dahil et
                        mode = "optimized"
                    })
                end)
                if success then
                    print("Harita başarıyla kaydedildi! Executor'ün workspace klasörünü kontrol et.")
                else
                    warn("Kayıt başarısız oldu: " .. tostring(err))
                end
            else
                warn("Kullandığın executor saveinstance() fonksiyonunu desteklemiyor!")
            end
        end)
    end
end)



-- Fling Menüsü
local flingPlayerListGui = nil
local flingScrollingRef = nil
local flingPlayerConns = {}
local activeFlingConnection = nil
local currentlyFlingingTarget = nil

local function createFlingPlayerListWindow()
	if flingPlayerListGui then
		flingPlayerListGui.Enabled = true
		return
	end

	flingPlayerListGui = Instance.new("ScreenGui")
	flingPlayerListGui.Name = "WorthNetFlingPlayerListMenu"
	
	local success = pcall(function()
		flingPlayerListGui.Parent = game:GetService("CoreGui")
	end)
	if not success then
		flingPlayerListGui.Parent = player.PlayerGui
	end

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 240, 0, 320)
	mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Parent = flingPlayerListGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Seçmeli Fling Menüsü"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 13
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, -16, 1, -50)
	scrollingFrame.Position = UDim2.new(0, 8, 0, 42)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.Parent = mainFrame
	flingScrollingRef = scrollingFrame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 6)
	uiListLayout.Parent = scrollingFrame

	local function refreshFlingList()
		if not flingScrollingRef then return end
		
		for _, child in ipairs(flingScrollingRef:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			if targetPlayer ~= player then
				local itemRow = Instance.new("Frame")
				itemRow.Size = UDim2.new(1, 0, 0, 32)
				itemRow.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				itemRow.BorderSizePixel = 0
				itemRow.Parent = flingScrollingRef

				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 6)
				rowCorner.Parent = itemRow

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
				nameLabel.Position = UDim2.new(0, 8, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = targetPlayer.Name
				nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
				nameLabel.TextSize = 12
				nameLabel.Font = Enum.Font.GothamMedium
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = itemRow

				local flingButton = Instance.new("TextButton")
				flingButton.Size = UDim2.new(0.38, 0, 0.75, 0)
				flingButton.Position = UDim2.new(0.60, 0, 0.125, 0)
				flingButton.BackgroundColor3 = (currentlyFlingingTarget == targetPlayer) and Color3.fromRGB(75, 255, 75) or Color3.fromRGB(255, 75, 75)
				flingButton.BorderSizePixel = 0
				flingButton.Text = (currentlyFlingingTarget == targetPlayer) and "Durdur" or "Fling"
				flingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				flingButton.TextSize = 11
				flingButton.Font = Enum.Font.GothamBold
				flingButton.Parent = itemRow

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 5)
				btnCorner.Parent = flingButton

				flingButton.MouseButton1Click:Connect(function()
					if currentlyFlingingTarget == targetPlayer then
						if activeFlingConnection then
							activeFlingConnection:Disconnect()
							activeFlingConnection = nil
						end
						currentlyFlingingTarget = nil
						
						local char = player.Character
						local rootPart = char and char:FindFirstChild("HumanoidRootPart")
						if rootPart then
							rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
							rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end
						
						showNotification("Fling", targetPlayer.Name .. " serbest bırakıldı.", false)
						refreshFlingList()
					else
						if activeFlingConnection then
							activeFlingConnection:Disconnect()
							activeFlingConnection = nil
						end

						currentlyFlingingTarget = targetPlayer
						showNotification("Fling", targetPlayer.Name .. " hedeflendi ve fırlatılıyor!", true)
						refreshFlingList()

						activeFlingConnection = RunService.Heartbeat:Connect(function()
							local character = player.Character
							local rootPart = character and character:FindFirstChild("HumanoidRootPart")
							
							if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and rootPart then
								local targetRoot = targetPlayer.Character.HumanoidRootPart
								rootPart.CFrame = targetRoot.CFrame
								rootPart.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
								rootPart.AssemblyLinearVelocity = Vector3.new(99999, 99999, 99999)
							else
								if activeFlingConnection then
									activeFlingConnection:Disconnect()
									activeFlingConnection = nil
								end
								currentlyFlingingTarget = nil
								if rootPart then
									rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
									rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
								end
								refreshFlingList()
							end
						end)
					end
				end)
			end
		end
	end

	refreshFlingList()

	table.insert(flingPlayerConns, Players.PlayerAdded:Connect(refreshFlingList))
	table.insert(flingPlayerConns, Players.PlayerRemoving:Connect(refreshFlingList))
end

local function hideFlingPlayerListWindow()
	if flingPlayerListGui then
		flingPlayerListGui.Enabled = false
	end
	
	if activeFlingConnection then
		activeFlingConnection:Disconnect()
		activeFlingConnection = nil
	end
	currentlyFlingingTarget = nil
	
	local char = player.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
end

createModernToggle(moveTab, "Fling Menüsü", "Oyuncu listesini açar, istediğini seçip fırlatırsın.", function(state)
	if state then
		createFlingPlayerListWindow()
	else
		hideFlingPlayerListWindow()
	end
end)


-- Player ESP
local espActive = false

createModernToggle(visualsTab, "Player ESP", "Düşmanların rengini, ismini ve canını gösterir.", function(state)
	espActive = state
	
	if espActive then
		task.spawn(function()
			while espActive do
				for _, p in ipairs(Players:GetPlayers()) do
					if not espActive then break end
					if p ~= player and p.Character then
						local char = p.Character
						local head = char:FindFirstChild("Head")
						local hum = char:FindFirstChild("Humanoid")
						
						if head and hum and hum.Health > 0 then
							local highlight = char:FindFirstChild("WorthNet_Highlight")
							if not highlight then
								highlight = Instance.new("Highlight")
								highlight.Name = "WorthNet_Highlight"
								highlight.Adornee = char
								highlight.Parent = char
							end
							highlight.Enabled = true
							highlight.FillColor = Color3.fromRGB(255, 50, 50)
							highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
							highlight.FillTransparency = 0.5
							
							local billboard = head:FindFirstChild("WorthNet_ESPBill")
							local textLabel
							
							if not billboard then
								billboard = Instance.new("BillboardGui")
								billboard.Name = "WorthNet_ESPBill"
								billboard.Size = UDim2.new(0, 200, 0, 50)
								billboard.StudsOffset = Vector3.new(0, 2.5, 0)
								billboard.AlwaysOnTop = true
								billboard.Parent = head
								
								textLabel = Instance.new("TextLabel")
								textLabel.Name = "InfoText"
								textLabel.Size = UDim2.new(1, 0, 1, 0)
								textLabel.BackgroundTransparency = 1
								textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
								textLabel.TextStrokeTransparency = 0
								textLabel.TextSize = 14
								textLabel.Font = Enum.Font.SourceSansBold
								textLabel.Parent = billboard
							else
								textLabel = billboard:FindFirstChild("InfoText")
							end
							
							if textLabel then
								local healthPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
								textLabel.Text = p.Name .. " [" .. healthPercent .. "%]"
							end
						end
					end
				end
				task.wait(0.3)
			end
		end)
	else
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local highlight = p.Character:FindFirstChild("WorthNet_Highlight")
				if highlight then highlight:Destroy() end
				
				local head = p.Character:FindFirstChild("Head")
				if head then
					local billboard = head:FindFirstChild("WorthNet_ESPBill")
					if billboard then billboard:Destroy() end
				end
			end
		end
	end
end)

-- WorthNet Anti-Fling (Gelişmiş & Güncel Pro Versiyon)
local antiFlingConn = nil

createModernToggle(moveTab, "Anti-Fling ", "Seni uçurmaya çalışanların hızını ve çarpışmasını engeller.", function(state)
    if state then
        antiFlingConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            -- 1. Kendi karakterimizi ani dış fizik itmelerine karşı sabitle
            if root then
                -- Eğer normalin çok üstünde bir hızla fırlatılıyorsan hızını sıfırla
                if root.AssemblyLinearVelocity.Magnitude > 250 then
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
            
            -- 2. Yakındaki oyuncuları tara ve fling yapanların hızını kes
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        -- Güncel hız ve açısal hız (RotVelocity yerine AssemblyAngularVelocity)
                        local linearSpeed = enemyRoot.AssemblyLinearVelocity.Magnitude
                        local rotSpeed = enemyRoot.AssemblyAngularVelocity.Magnitude
                        
                        -- Eğer birisi fling yapmak için hızlanıyorsa
                        if linearSpeed > 75 or rotSpeed > 75 then
                            for _, part in ipairs(p.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end
                end
            end
        end)
        showNotification("Anti-Fling", "Gelişmiş Anti-Fling aktif!", true)
    else
        if antiFlingConn then 
            antiFlingConn:Disconnect() 
            antiFlingConn = nil 
        end
        showNotification("Anti-Fling", "Durduruldu.", false)
    end
end)


-- WorthNet MM2 Çoklu Dil, Envanter Taramalı Rol ESP ve Özel Crosshair Lock
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local mm2Highlights = {}
local mm2Tags = {}
local mm2ESPActive = false
local crosshairLockActive = false

-- Bizim kontrolümüzde olacak özel Crosshair'i (Görseli) oluşturuyoruz
local pGui = player:WaitForChild("PlayerGui")
local customCrosshairGui = pGui:FindFirstChild("WorthNetCustomCrosshair")
if not customCrosshairGui then
    customCrosshairGui = Instance.new("ScreenGui")
    customCrosshairGui.Name = "WorthNetCustomCrosshair"
    customCrosshairGui.ResetOnSpawn = false
    customCrosshairGui.Parent = pGui
    
    local crossImg = Instance.new("Frame")
    crossImg.Name = "Cross"
    crossImg.Size = UDim2.new(0, 8, 0, 8)
    crossImg.AnchorPoint = Vector2.new(0.5, 0.5)
    crossImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    crossImg.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Katile kilitleyince kırmızı olur
    crossImg.BorderSizePixel = 0
    crossImg.Visible = false
    crossImg.Parent = customCrosshairGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = crossImg
end

local crosshairElement = customCrosshairGui:FindFirstChild("Cross")

-- Rol ESP Temizleme Fonksiyonu
local function removeMM2ESP()
    for _, hl in pairs(mm2Highlights) do if hl then hl:Destroy() end end
    for _, tag in pairs(mm2Tags) do if tag then tag:Destroy() end end
    table.clear(mm2Highlights)
    table.clear(mm2Tags)
end

-- Katili Tespit Etme Fonksiyonu (Envanterinde "Knife" olan)
local function getMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local backpack = p:FindFirstChild("Backpack")
            local char = p.Character
            if (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("MurdererKnife"))) or
               (char:FindFirstChild("Knife") or char:FindFirstChild("MurdererKnife")) then
                return p
            end
        end
    end
    return nil
end

-- Bizim envanterimizde "Gun" var mı kontrolü
local function hasGun()
    local char = player.Character
    if not char then return false end
    local backpack = player:FindFirstChild("Backpack")
    if (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))) or
       (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) then
        return true
    end
    return false
end

-- 1. TOGGLE: MM2 Rol ESP (Envanter & Rol Arayüzü Taramalı, 0.4 saniye döngülü)
createModernToggle(mm2Tab, "MM2 Rol ESP", "Envanterleri tarar; Knife = Katil (Kırmızı), Gun = Şerif (Mavi).", function(state)
    mm2ESPActive = state
    if not mm2ESPActive then
        removeMM2ESP()
    else
        task.spawn(function()
            while mm2ESPActive do
                task.wait(0.4) -- Round geçişleri ve performans için ideal yenileme hızı
                
                for _, p in ipairs(Players:GetPlayers()) do
                    if not mm2ESPActive then break end
                    if p ~= player and p.Character then
                        local char = p.Character
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local roleName = "Masum"
                            local roleColor = Color3.fromRGB(0, 255, 0) -- Yeşil (Masum)
                            
                            -- Envanter Taraması
                            local backpack = p:FindFirstChild("Backpack")
                            if (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("MurdererKnife"))) or
                               (char:FindFirstChild("Knife") or char:FindFirstChild("MurdererKnife")) then
                                roleName = "Katil"
                                roleColor = Color3.fromRGB(255, 0, 0) -- Kırmızı
                            elseif (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))) or
                                   (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")) then
                                roleName = "Şerif"
                                roleColor = Color3.fromRGB(0, 140, 255) -- Mavi
                            else
                                -- Rol Arayüzü (RoleSelection) yedek taraması
                                local pGuiRef = p:FindFirstChild("PlayerGui")
                                if pGuiRef then
                                    local roleSelection = pGuiRef:FindFirstChild("RoleSelection")
                                    if roleSelection then
                                        local containers = { roleSelection:FindFirstChild("Desktop"), roleSelection:FindFirstChild("Mobile"), roleSelection:FindFirstChild("Console") }
                                        for _, container in ipairs(containers) do
                                            if container then
                                                local roleLabel = container:FindFirstChild("Role")
                                                if roleLabel and roleLabel:IsA("TextLabel") then
                                                    local text = string.lower(roleLabel.Text)
                                                    if string.find(text, "murderer") or string.find(text, "katil") then
                                                        roleName = "Katil"
                                                        roleColor = Color3.fromRGB(255, 0, 0)
                                                    elseif string.find(text, "sheriff") or string.find(text, "şerif") then
                                                        roleName = "Şerif"
                                                        roleColor = Color3.fromRGB(0, 140, 255)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Highlight (Karakter Renklendirme)
                            if not mm2Highlights[p.Name] or mm2Highlights[p.Name].Parent ~= char then
                                if mm2Highlights[p.Name] then mm2Highlights[p.Name]:Destroy() end
                                local hl = Instance.new("Highlight", char)
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                mm2Highlights[p.Name] = hl
                            end
                            mm2Highlights[p.Name].FillColor = roleColor
                            mm2Highlights[p.Name].OutlineColor = roleColor
                            
                            -- BillboardGui (Kafanın Üstünde Yazı)
                            local head = char:FindFirstChild("Head")
                            if head then
                                local tag = mm2Tags[p.Name]
                                if not tag or tag.Adornee ~= head then
                                    if tag then tag:Destroy() end
                                    
                                    local bg = Instance.new("BillboardGui")
                                    bg.Name = "MM2RoleTag"
                                    bg.Size = UDim2.new(0, 110, 0, 45)
                                    bg.StudsOffset = Vector3.new(0, 2.5, 0)
                                    bg.AlwaysOnTop = true
                                    bg.Adornee = head
                                    
                                    local txt = Instance.new("TextLabel", bg)
                                    txt.Name = "RoleText"
                                    txt.Size = UDim2.new(1, 0, 1, 0)
                                    txt.BackgroundTransparency = 1
                                    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    txt.TextScaled = true
                                    txt.Font = Enum.Font.SourceSansBold
                                    txt.TextStrokeTransparency = 0
                                    
                                    bg.Parent = char
                                    mm2Tags[p.Name] = bg
                                    tag = bg
                                end
                                
                                local tagLabel = tag:FindFirstChild("RoleText")
                                if tagLabel then
                                    tagLabel.Text = p.Name .. "\n[" .. roleName .. "]"
                                    tagLabel.TextColor3 = roleColor
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 2. TOGGLE: Kusursuz Katil Silent/Cam Lock (Elinde Gun varken kafaya kilitler)
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getRealMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local bp = p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife"))
            if bp then
                return p
            end
        end
    end
    return nil
end

createModernToggle(mm2Tab, "MM2 Katile Kitlenme", "Elinde Gun varken kamerayı direkt katilin kafasına sabitler.", function(state)
    crosshairLockActive = state
    if crosshairLockActive then
        task.spawn(function()
            while crosshairLockActive do
                RunService.RenderStepped:Wait()
                
                if hasGun() then
                    local murderer = getRealMurderer()
                    if murderer and murderer.Character then
                        local mHead = murderer.Character:FindFirstChild("Head")
                        if mHead then
                            -- Fareyi bozan mousemoverel yerine kameranın vektörünü doğrudan kafaya kilitliyoruz.
                            -- Bu sayede ateş ettiğinde mermi şaşmaz, direkt kafaya gider!
                            local camera = workspace.CurrentCamera
                            local targetCF = CFrame.new(camera.CFrame.Position, mHead.Position)
                            
                            -- Pürüzsüz geçiş için Interpolation (Lerp) kullanıyoruz ki ani kamera zıplaması yapmasın
                            camera.CFrame = camera.CFrame:Lerp(targetCF, 0.2)
                        end
                    end
                end
            end
        end)
    end
end)

-- Infinite Jump
createModernToggle(moveTab, "Infinite Jump", "Sonsuz kez havada zıplamanızı sağlar.", function(state)
	if state then
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
	end
end)



-- Anti-Void
local antiVoidConn = nil
createModernToggle(mainTab, "Anti-Void", "Boşluğa düşerek ölmeyi engeller.", function(state)
	if state then
		antiVoidConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < -30 then
				root.Velocity = Vector3.new(0, 0, 0)
				root.CFrame = root.CFrame + Vector3.new(0, 100, 0)
			end
		end)
	else
		if antiVoidConn then antiVoidConn:Disconnect() antiVoidConn = nil end
	end
end)

-- SpinBot
local spinConn = nil
createModernToggle(moveTab, "SpinBot", "Etrafında çılgınca dönersin.", function(state)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if state and root then
        spinConn = RunService.RenderStepped:Connect(function()
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(45), 0)
        end)
    else
        if spinConn then spinConn:Disconnect() spinConn = nil end
    end
end)

-- WorthNet Inventory ESP (Modern Çerçeveli Sürüm)
local invESPActive = false
local invTags = {}

createModernToggle(visualsTab, "WorthNet Inventory ESP", "Oyuncuların üzerindeki eşyaları şık bir panelde listeler.", function(state)
    invESPActive = state
    if not invESPActive then
        for _, gui in pairs(invTags) do 
            if gui then gui:Destroy() end 
        end
        table.clear(invTags)
    else
        task.spawn(function()
            while invESPActive do
                task.wait(0.5) -- Daha akıcı güncellenmesi için süre kısaltıldı
                
                -- Oyundan çıkanların etiketlerini temizle
                for name, gui in pairs(invTags) do
                    local targetPlayer = Players:FindFirstChild(name)
                    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
                        if gui then gui:Destroy() end
                        invTags[name] = nil
                    end
                end

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local items = {}
                        
                        -- Elindeki eşya
                        local tool = p.Character:FindFirstChildOfClass("Tool")
                        if tool then table.insert(items, "[Elindeki] " .. tool.Name) end
                        
                        -- Çantasındaki eşyalar
                        local back = p:FindFirstChild("Backpack")
                        if back then
                            for _, item in ipairs(back:GetChildren()) do
                                if item:IsA("Tool") then 
                                    table.insert(items, item.Name) 
                                end
                            end
                        end
                        
                        local head = p.Character:FindFirstChild("Head")
                        if head then
                            -- Eğer daha önce UI oluşturulmadıysa baştan tasarlıyoruz
                            if not invTags[p.Name] then
                                local bb = Instance.new("BillboardGui")
                                bb.Name = "WorthNetInvESP"
                                bb.Size = UDim2.new(0, 180, 0, 70)
                                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                                bb.AlwaysOnTop = true
                                bb.Parent = head
                                
                                -- Ana Şık Çerçeve (Frame)
                                local frame = Instance.new("Frame")
                                frame.Size = UDim2.new(1, 0, 1, 0)
                                frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                                frame.BackgroundTransparency = 0.3
                                frame.BorderSizePixel = 0
                                frame.Parent = bb
                                
                                -- Köşeleri Yuvarlatma
                                local corner = Instance.new("UICorner")
                                corner.CornerRadius = UDim.new(0, 8)
                                corner.Parent = frame
                                
                                -- Çerçevenin İnce Parlak Kenarlığı (Stroke)
                                local stroke = Instance.new("UIStroke")
                                stroke.Color = Color3.fromRGB(0, 170, 255)
                                stroke.Thickness = 1.5
                                stroke.Parent = frame
                                
                                -- Başlık (Oyuncu İsmi)
                                local titleLabel = Instance.new("TextLabel")
                                titleLabel.Size = UDim2.new(1, 0, 0, 20)
                                titleLabel.Position = UDim2.new(0, 0, 0, 4)
                                titleLabel.BackgroundTransparency = 1
                                titleLabel.Text = p.Name
                                titleLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
                                titleLabel.TextScaled = true
                                titleLabel.Font = Enum.Font.GothamBold
                                titleLabel.Parent = frame
                                
                                -- Eşya Listesi Metni
                                local itemLabel = Instance.new("TextLabel")
                                itemLabel.Name = "ItemList"
                                itemLabel.Size = UDim2.new(1, -10, 0, 40)
                                itemLabel.Position = UDim2.new(0, 5, 0, 24)
                                itemLabel.BackgroundTransparency = 1
                                itemLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
                                itemLabel.TextScaled = false
                                itemLabel.TextSize = 12
                                itemLabel.Font = Enum.Font.Gotham
                                itemLabel.TextWrapped = true
                                itemLabel.TextYAlignment = Enum.TextYAlignment.Top
                                itemLabel.Parent = frame
                                
                                invTags[p.Name] = bb
                            end
                            
                            -- İçeriği Güncelle
                            local bb = invTags[p.Name]
                            if bb and bb:FindFirstChild("Frame") then
                                local itemLabel = bb.Frame:FindFirstChild("ItemList")
                                if itemLabel then
                                    if #items > 0 then
                                        itemLabel.Text = table.concat(items, ", ")
                                    else
                                        itemLabel.Text = "Çanta Boş"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- TP Nearest
createModernToggle(moveTab, "TP Nearest", "En yakındaki oyuncunun yanına ışınlanırsın.", function(state)
    if state then
        local target = nil
        local dist = 100000
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local d = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        target = p.Character.HumanoidRootPart
                    end
                end
            end
        end
        
        if target then
            player.Character.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 2)
            showNotification("Teleport", "Oyuncuya ışınlanıldı!", true)
        else
            showNotification("Teleport", "Yakında oyuncu bulunamadı.", false)
        end
    end
end)

-- Oyuncu Listesi Penceresi (TP)
local playerListGui = nil
local scrollingFrameRef = nil
local playerConnections = {}

local function createPlayerListWindow()
    if playerListGui then
        playerListGui.Enabled = true
        return
    end

    playerListGui = Instance.new("ScreenGui")
    playerListGui.Name = "WorthNetPlayerListMenu"
    local success = pcall(function()
        playerListGui.Parent = game:GetService("CoreGui")
    end)
    if not success then
        playerListGui.Parent = player.PlayerGui
    end

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 320)
    mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = playerListGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Oyuncu Işınlanma Menüsü"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -16, 1, -50)
    scrollingFrame.Position = UDim2.new(0, 8, 0, 42)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.Parent = mainFrame
    scrollingFrameRef = scrollingFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 6)
    uiListLayout.Parent = scrollingFrame

    local function refreshList()
        if not scrollingFrameRef then return end
        
        for _, child in ipairs(scrollingFrameRef:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                local itemRow = Instance.new("Frame")
                itemRow.Size = UDim2.new(1, 0, 0, 32)
                itemRow.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                itemRow.BorderSizePixel = 0
                itemRow.Parent = scrollingFrameRef

                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = UDim.new(0, 6)
                rowCorner.Parent = itemRow

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
                nameLabel.Position = UDim2.new(0, 8, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = targetPlayer.Name
                nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                nameLabel.TextSize = 12
                nameLabel.Font = Enum.Font.GothamMedium
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = itemRow

                local tpButton = Instance.new("TextButton")
                tpButton.Size = UDim2.new(0.28, 0, 0.75, 0)
                tpButton.Position = UDim2.new(0.70, 0, 0.125, 0)
                tpButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
                tpButton.BorderSizePixel = 0
                tpButton.Text = "TP"
                tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpButton.TextSize = 12
                tpButton.Font = Enum.Font.GothamBold
                tpButton.Parent = itemRow

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 5)
                btnCorner.Parent = tpButton

                tpButton.MouseButton1Click:Connect(function()
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            myRoot.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                        end
                    end
                end)
            end
        end
    end

    refreshList()

    table.insert(playerConnections, Players.PlayerAdded:Connect(refreshList))
    table.insert(playerConnections, Players.PlayerRemoving:Connect(refreshList))
end

local function hidePlayerListWindow()
    if playerListGui then
        playerListGui.Enabled = false
    end
end

createModernToggle(moveTab, "TP Player Menüsü", "Oyuncu listesi penceresini açar/kapatır.", function(state)
    if state then
        createPlayerListWindow()
    else
        hidePlayerListWindow()
    end
end)

-- WorthNet X Tp (Güncellenmiş & Sorunsuz Çalışan Sürüm)
local clickTPXActive = false

createModernToggle(moveTab, "WorthNet X Tp", "Fareyi nereye tutarsan X tuşuna basınca oraya ışınlanırsın.", function(state)
    clickTPXActive = state
    if state then
        showNotification("WorthNet X Tp", "Aktif! Nişan al ve X tuşuna bas.", true)
    else
        showNotification("WorthNet X Tp", "Kapatıldı.", false)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and clickTPXActive and input.KeyCode == Enum.KeyCode.X then
        pcall(function()
            local camera = workspace.CurrentCamera
            local mouseLocation = UserInputService:GetMouseLocation()
            local unitRay = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
            
            -- Dünyadaki objelerle kesişimi (raycast) buluyoruz
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.IgnoreWater = true
            
            if player.Character then
                raycastParams.FilterDescendantsInstances = {player.Character}
            end
            
            local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            
            if raycastResult then
                local targetPos = raycastResult.Position
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    -- Yere gömülmemek için hafif yukarıda başlatıyoruz
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    
                    task.defer(function()
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end)
                end
            end
        end)
    end
end)

-- Auto Follow / Lock
local followEnabled = false
createModernToggle(mainTab, "Auto Follow/Lock", "En yakın oyuncuyu takip eder.", function(state)
    followEnabled = state
end)

RunService.RenderStepped:Connect(function()
    if followEnabled then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local closestPlayer = nil
            local shortestDist = math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = p.Character.HumanoidRootPart
                    local dist = (hrp.Position - targetHrp.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestPlayer = p
                    end
                end
            end
            if closestPlayer and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = closestPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end
end)

-- Anti-Ragdoll (Gelişmiş & Fizik Bağlantı Temizleyici)
local antiRagdollEnabled = false
local antiRagdollConnection = nil

createModernToggle(mainTab, "Anti-Ragdoll (Pro)", "Özel ragdoll ve fizik eklemlerini bozar.", function(state)
    antiRagdollEnabled = state
    if antiRagdollEnabled then
        if not antiRagdollConnection then
            antiRagdollConnection = RunService.RenderStepped:Connect(function()
                local char = player.Character
                if not char then return end
                
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    local currentState = hum:GetState()
                    if currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.FallingDown then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
                
                -- Özel oyunların eklediği Ragdoll fizik eklemlerini (BallSocket) yok et
                for _, descendant in ipairs(char:GetDescendants()) do
                    if descendant:IsA("BallSocketConstraint") or descendant:IsA("HingeConstraint") then
                        -- Eğer ragdoll için eklenmiş bir eklemse yok et veya devre dışı bırak
                        descendant:Destroy()
                    end
                end
            end)
        end
        showNotification("Anti-Ragdoll", "Gelişmiş koruma aktif!", true)
    else
        if antiRagdollConnection then
            antiRagdollConnection:Disconnect()
            antiRagdollConnection = nil
        end
        showNotification("Anti-Ragdoll", "Durduruldu.", false)
    end
end)

-- Anti-AFK
local afkConn = nil
createModernToggle(mainTab, "Anti-AFK", "Sunucudan atılmayı engeller.", function(state)
    if state then
        afkConn = player.Idled:Connect(function()
            game:GetService("VirtualUser"):CaptureController()
            game:GetService("VirtualUser"):ClickButton1(Vector2.new(0,0))
        end)
    else
        if afkConn then afkConn:Disconnect() end
    end
end)

-- Smooth Aim
local smoothAimActive = false
local aimSpeed = 0.3

createModernToggle(combatTab, "Smooth Aim", "Yakındaki düşmana yumuşak geçişli kilitlenme.", function(state)
    smoothAimActive = state
    task.spawn(function()
        while smoothAimActive do
            task.wait()
            local closestPlayer = nil
            local shortestDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                    local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.Head.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                        if dist < shortestDist then
                            closestPlayer = p.Character.Head
                            shortestDist = dist
                        end
                    end
                end
            end
            if closestPlayer and shortestDist < 200 then
                local targetCFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, closestPlayer.Position)
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCFrame, aimSpeed)
            end
        end
    end)
end)


-- UI Viewer / Dex Explorer
createModernToggle(visualsTab, "UI Viewer (Dex)", "Arayüzü ve oyun ağacını incelemek için Explorer açar.", function(state)
	if state then
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
		end)
		showNotification("UI Viewer", "Dex Explorer yüklendi!", true)
	end
end)





-- Auto-Dodge (Gelen alan hasarlarından/yeteneklerden otomatik kaçma)
local autoDodgeActive = false
createModernToggle(moveTab, "Auto-Dodge", "Yaklaşan tehlikelerden ve AoE alanlardan otomatik kaçar.", function(state)
	autoDodgeActive = state
	if state then
		task.spawn(function()
			while autoDodgeActive do
				task.wait(0.05)
				pcall(function()
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						for _, obj in ipairs(workspace:GetChildren()) do
							if obj:IsA("Part") and obj.Name:lower():find("bullet") or obj.Name:lower():find("spell") or obj.Name:lower():find("aoe") then
								if (obj.Position - hrp.Position).Magnitude < 15 then
									hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-10, 10), 5, math.random(-10, 10))
								end
							end
						end
					end
				end)
			end
		end)
		showNotification("Auto-Dodge", "Aktif! Tehlikelerden kaçılıyor.", true)
	else
		showNotification("Auto-Dodge", "Devre dışı bırakıldı.", false)
	end
end)
-- WorthNet MM2 AutoCoin System (Safe & Smart)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Aktif harita içindeki CoinContainer'ı dinamik olarak bulan fonksiyon
local function getCoinContainer()
    for _, child in ipairs(Workspace:GetChildren()) do
        local container = child:FindFirstChild("CoinContainer")
        if container then
            return container
        end
    end
    return nil
end

-- Elinde "Knife" olan kişiyi (Katili) bulan fonksiyon
local function getMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            -- Karakterin üstünde veya sırtında bıçak var mı kontrol et
            local bp = p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife"))
            if bp then
                return p
            end
        end
    end
    return nil
end

-- Güçlü Noclip Döngüsü (Duvarlardan geçmeyi sağlar, buga sokmaz)
RunService.Stepped:Connect(function()
    if _G.AutoCoinActive then
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- 1. Toggle Butonu
createModernToggle(mm2Tab, "MM2 AutoCoin", "Güvenli hızda yer altından coin toplar, katilden kaçar ve limit dolunca reset atar.", function(state)
    _G.AutoCoinActive = state
end)

-- 2. Ana AutoCoin Döngüsü (Gelişmiş & Güvenli Versiyon)
task.spawn(function()
    local collectedCount = 0
    
    while task.wait(0.5) do
        if _G.AutoCoinActive then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Önce katil yakınımızda mı diye kontrol et!
                local murderer = getMurderer()
                local isSafe = true
                
                if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                    local mHrp = murderer.Character.HumanoidRootPart
                    local distToMurderer = (hrp.Position - mHrp.Position).Magnitude
                    
                    -- Katil 18 stud'dan daha yakınsa tehlikedeyiz, coin toplamayı geçici olarak durdur ve uzaklaş
                    if distToMurderer < 18 then
                        isSafe = false
                        -- Katilden biraz uzaklaşmak için yer altında güvenli bir konuma kayabiliriz veya sadece bekleyebiliriz
                    end
                end
                
                -- Eğer ortalık güvenliyse coin topla
                if isSafe then
                    local coinContainer = getCoinContainer()
                    
                    if coinContainer then
                        for _, coinPart in ipairs(coinContainer:GetChildren()) do
                            if not _G.AutoCoinActive then break end
                            
                            -- Döngü içindeyken de katili sürekli kontrol et
                            local currentMurderer = getMurderer()
                            if currentMurderer and currentMurderer.Character and currentMurderer.Character:FindFirstChild("HumanoidRootPart") then
                                if (hrp.Position - currentMurderer.Character.HumanoidRootPart.Position).Magnitude < 18 then
                                    break -- Katil yaklaştıysa bu coini bırak, döngüyü kır ve güvenli moda geç
                                end
                            end
                            
                            if coinPart.Name == "Coin_Server" and coinPart:IsA("BasePart") then
                                while coinPart and coinPart.Parent and _G.AutoCoinActive do
                                    -- Katil yaklaşırsa anında döngüyü kes
                                    local activeMurderer = getMurderer()
                                    if activeMurderer and activeMurderer.Character and activeMurderer.Character:FindFirstChild("HumanoidRootPart") then
                                        if (hrp.Position - activeMurderer.Character.HumanoidRootPart.Position).Magnitude < 18 then
                                            break
                                        end
                                    end
                                    
                                    local targetPos = coinPart.Position - Vector3.new(0, 3.5, 0)
                                    local distance = (hrp.Position - coinPart.Position).Magnitude
                                    
                                    if distance < 2 then 
                                        break 
                                    end
                                    
                                    local finalTarget = targetPos
                                    if distance < 12 then
                                        finalTarget = coinPart.Position
                                    end
                                    
                                    -- Ban yememek için hızı daha güvenli ve yumuşak bir değer olan 16-18 arasına düşürdük
                                    local speed = 16 
                                    local step = RunService.Heartbeat:Wait()
                                    
                                    local direction = (finalTarget - hrp.Position).Unit
                                    local moveStep = direction * math.min(speed * step, (finalTarget - hrp.Position).Magnitude)
                                    
                                    hrp.CFrame = hrp.CFrame + moveStep
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                                
                                collectedCount = collectedCount + 1
                                task.wait(0.1)
                                
                                -- Limit dolunca reset at
                                if collectedCount >= 55 then
                                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                                    if humanoid then
                                        humanoid.Health = 0
                                    end
                                    collectedCount = 0
                                    task.wait(3)
                                    break
                                end
                            end
                        end
                    end
                else
                    -- Katil yakınlardaysa burası çalışır: Güvenli olması için haritanın dışına veya alta biraz daha derin inebilirsin
                    task.wait(1)
                end
            end
        end
    end
end)

-- WorthNet Lighting & Parlaklık Düşürücü
local lighting = game:GetService("Lighting")

-- Varsayılan değerleri saklıyoruz (kapatınca eski haline dönebilmesi için)
local originalBrightness = lighting.Brightness
local originalExposure = lighting.ExposureCompensation
local originalClock = lighting.ClockTime

createModernToggle(visualsTab, "WorthNet Parlaklık Kısırlaştırıcı", "Oyunun aşırı parlak ışıklarını ve göz alan parlamalarını düşürür.", function(state)
    if state then
        showNotification("Lighting", "Parlaklık düşürüldü!", true)
        
        -- Parlaklığı ve pozlamayı aşağı çekiyoruz
        lighting.Brightness = 0.5 -- Varsayılan genelde 2 veya üstüdür
        lighting.ExposureCompensation = -0.5 -- Ekstra ortam pozlamasını kısar
        
        -- Varsa aşırı parlayan efektleri pasif yap
        for _, effect in ipairs(lighting:GetChildren()) do
            if effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                effect.Enabled = false
            end
        end
    else
        showNotification("Lighting", "Normale döndürüldü.", false)
        
        -- Eski haline geri yükle
        lighting.Brightness = originalBrightness
        lighting.ExposureCompensation = originalExposure
        lighting.ClockTime = originalClock
        
        for _, effect in ipairs(lighting:GetChildren()) do
            if effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                effect.Enabled = true
            end
        end
    end
end)

-- Custom FOV
local Camera = workspace.CurrentCamera
createModernSlider(visualsTab, "Custom FOV", "Görüş açınızı (FOV) ayarlar.", 70, 120, 70, function(value)
    Camera.FieldOfView = value
end)



-- Map Editor / Part Inspector & Deleter
_G.PartDeleterActive = false

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- Nesnenin tam hiyerarşisini (iskelet yolunu) çıkaran fonksiyon
local function getFullPath(obj)
    local path = obj.Name
    local current = obj.Parent
    while current and current ~= game do
        path = current.Name .." . ".. path
        current = current.Parent
    end
    return path
end

createModernToggle(visualsTab, "Click Part Deleter", "Tıkladığın parçanın bilgisini F9'a yazdırır ve siler.", function(state)
    _G.PartDeleterActive = state
end)

-- Mouse tıklama olayını tek bir kez dinleyiciye bağlıyoruz (Çift tetiklenmeyi önlemek için)
mouse.Button1Down:Connect(function()
    if _G.PartDeleterActive and mouse.Target then
        local targetPart = mouse.Target
        
        print("--------------------PART BULUNDU--------------------")
        print("İsim       : " .. targetPart.Name)
        print("Sınıf (Tür): " .. targetPart.ClassName)
        print("İskelet Yolu: " .. getFullPath(targetPart))
        print("--------------------------------------------------")
        
        -- Parçayı oyundan tamamen siler
        targetPart:Destroy()
    end
end)


-- ==========================================
-- WorthNet Gelişmiş Chat Logger (Temizlenmiş)
-- ==========================================
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Bildirimlerin açılıp kapanmasını kontrol eden ayar (True = Açık, False = Kapalı)
local chatNotificationsEnabled = false 

-- Bildirimi açıp kapatmak için dışarıdan çağırabileceğin fonksiyon:
local function setChatNotificationState(state)
    chatNotificationsEnabled = state
end

local function showChatNotification(senderName, message)
    if not chatNotificationsEnabled then return end -- Eğer kapalıysa bildirim gönderme
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WorthNet Logger [" .. senderName .. "]",
            Text = message,
            Duration = 4;
        })
    end)
end

local function monitorPlayer(p)
    p.Chatted:Connect(function(msg)
        -- ANSI renk kodları temizlendi, konsola saf ve düzgün log düşer
        print("[WorthNet ChatLogger] " .. p.Name .. ": " .. msg)
        
        -- Ekranda bildirim göster (Duruma göre kontrol edilir)
        showChatNotification(p.Name, msg)
    end)
end

-- 1. Oyunda şu an bulunan herkesi dinlemeye başla
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= Players.LocalPlayer then
        monitorPlayer(p)
    end
end

-- 2. Oyuna sonradan girecek olanları dinle
Players.PlayerAdded:Connect(function(p)
    monitorPlayer(p)
end)

print("[WorthNet] Chat Logger başarıyla aktif edildi!")


createModernToggle(settingsTab, "FPS Booster", "Gereksiz görsel efektleri kapatarak FPS'i artırır.", function(state)
    if state then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                end
            end
            showNotification("FPS Booster", "Grafikler optimize edildi!", true)
        end)
    end
end)




-- 20. Crash Protection (Sunucu Çökme Koruması)
createModernToggle(mainTab, "Crash Protection", "İstemciyi çökmelere karşı korur.", function(state)
    if state then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and self == player then
                return
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        showNotification("WorthNet", "Crash koruması aktif!", true)
    end
end)

-- ==========================================
-- 1. YUVARLAK VE SEMBOLLÜ LOGO (AÇILIŞ/KAPANIŞ)
-- ==========================================
-- Eski minLogo yerine geçecek yuvarlak ve sembollü tasarım:
local minLogo = Instance.new("TextButton")
minLogo.Name = ""
minLogo.Parent = screenGui 
minLogo.BackgroundColor3 = THEME.Card
minLogo.Position = UDim2.new(0, 30, 0.5, -25)
minLogo.Size = UDim2.new(0, 48, 0, 48)
minLogo.Font = Enum.Font.Code
minLogo.Text = ">_"
minLogo.TextColor3 = THEME.Accent
minLogo.TextSize = 18
minLogo.Visible = false
minLogo.Active = true
minLogo.Draggable = true

-- Tamamen yuvarlak yapmak için UICorner ekliyoruz
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0) -- Tam daire (Full Round)
logoCorner.Parent = minLogo

local logoStroke = Instance.new("UIStroke")
logoStroke.Parent = minLogo
logoStroke.Color = THEME.Accent
logoStroke.Thickness = 1.5

-- ==========================================
-- 2. HIZLANDIRILMIŞ VE BUG'SIZ AUTO GUNDROP
-- ==========================================
local autoGunDropEnabled = false

createModernToggle(mm2Tab, "Auto GunDrop", "Harita içindeki Silahı anında toplar.", function(state)
    autoGunDropEnabled = state
end)

task.spawn(function()
    while true do
        task.wait(0.05) -- Kontrol döngüsü hızlandırıldı (0.1 yerine 0.05)
        if autoGunDropEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local backpack = player:FindFirstChild("Backpack")
            local hasKnife = false
            
            if backpack and backpack:FindFirstChild("Knife") then
                hasKnife = true
            elseif player.Character:FindFirstChild("Knife") then
                hasKnife = true
            end

            -- Eğer bıçağımız yoksa silahı ara
            if not hasKnife then
                local rootPart = player.Character.HumanoidRootPart
                local originalCFrame = rootPart.CFrame
                local targetPart = nil

                for _, item in ipairs(workspace:GetChildren()) do
                    if item.Name == "GunDrop" then
                        targetPart = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or (item:IsA("BasePart") and item)
                        if targetPart then break end
                    elseif item:IsA("Model") or item:IsA("Folder") then
                        local foundInMap = item:FindFirstChild("GunDrop", true)
                        if foundInMap then
                            if foundInMap:IsA("Model") then
                                targetPart = foundInMap.PrimaryPart or foundInMap:FindFirstChildWhichIsA("BasePart")
                            elseif foundInMap:IsA("BasePart") then
                                targetPart = foundInMap
                            end
                            if targetPart then break end
                        end
                    end
                end

                if targetPart then
                    pcall(function()
                        -- Havada kalma ve bug'ı önlemek için hızları sıfırlamaya hazır ol
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        
                        -- Anlık ışınlanma (Silahın tam üstü)
                        rootPart.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                        
                        if targetPart:IsA("BasePart") then
                            firetouchinterest(rootPart, targetPart, 0)
                            firetouchinterest(rootPart, targetPart, 1)
                        end

                        if type(showNotification) == "function" then
                            showNotification("Auto GunDrop", "Silah anında alındı!")
                        end

                        -- Bekleme süresi neredeyse sıfırlandı (Anında geri dönüş)
                        task.wait() 
                        
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            rootPart.CFrame = originalCFrame
                            
                            -- Karakterin olduğu yerde kalma/donma (bug) sorununu çözen fizik sıfırlaması
                            if rootPart:FindFirstChildOfClass("BodyVelocity") == nil then
                                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end)
                end
            end
        end
    end
end)





---------------------------------------------------------
-- 1. COMBAT & SİLAH GÜÇLENDİRMELERİ (Replikasyon Tabanlı)
---------------------------------------------------------
createModernToggle(globalExploitsTab, "Infinite Ammo & Rapid Fire", "Mermileri sonsuz yapar ve atış hızını sunucuya yansıtarak herkese zarar verir.", function(state)
	_G.GlobalRapidFire = state
	task.spawn(function()
		while _G.GlobalRapidFire do
			task.wait(0.1)
			pcall(function()
				for _, tool in ipairs(player.Character:GetChildren()) do
					if tool:IsA("Tool") then
						local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip") or tool:FindFirstChild("StoredAmmo")
						if ammo then
							ammo.Value = 999999
						end
					end
				end
			end)
		end
	end)
end)



local savedSpawnPos = nil
local tpSpawnActive = false

createModernToggle(moveTab, "SetSpawn", "Olduğun konumu spawn noktası yap.", function(state)
    if state then
        savedSpawnPos = player.Character.HumanoidRootPart.CFrame
        showNotification("Spawn", "Konum kaydedildi!", true)
    else
        savedSpawnPos = nil
    end
end)

createModernToggle(moveTab, "TP Spawn", "Kaydedilen konuma sürekli ışınlan.", function(state)
    tpSpawnActive = state
    if state then
        task.spawn(function()
            while tpSpawnActive do
                if savedSpawnPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = savedSpawnPos
                end
                task.wait(0.3)
            end
        end)
    end
end)

-- Xeno ve Executor Uyumluluk Metatable Koruması
pcall(function()
	local metatable = getrawmetatable(game)
	local namecall = metatable.__namecall
	setreadonly(metatable, false)
	metatable.__namecall = newcclosure(function(self, ...)
		if getnamecallmethod() == "FireServer" and tostring(self) == "WalkSpeedCheck" then return nil end
		return namecall(self, ...)
	end)
	setreadonly(metatable, true)
end)
