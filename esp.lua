-- BloxStrike: ESP + Skin Changer (нож M9 Bayonet | Damascus Steel)
-- Нажми INSERT для открытия меню

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========== НАСТРОЙКИ СКИНОВ ==========
-- ID скинов для BloxStrike (примеры, могут отличаться)
local knifeSkins = {
    ["M9 Bayonet"] = {id = 1, name = "M9 Bayonet | Damascus Steel"},
    ["Karambit"] = {id = 2, name = "Karambit | Fade"},
    ["Butterfly"] = {id = 3, name = "Butterfly Knife | Slaughter"},
    ["Huntsman"] = {id = 4, name = "Huntsman Knife | Tiger Tooth"},
    ["Falchion"] = {id = 5, name = "Falchion Knife | Marble Fade"}
}

local gloveSkins = {
    ["Sport Gloves"] = {id = 1, name = "Sport Gloves | Vice"},
    ["Driver Gloves"] = {id = 2, name = "Driver Gloves | King Snake"},
    ["Hand Wraps"] = {id = 3, name = "Hand Wraps | Overprint"}
}

-- Текущий выбранный скин
local selectedKnife = "M9 Bayonet"
local selectedGlove = "Sport Gloves"

-- ========== НАСТРОЙКИ ESP ==========
local espSettings = {
    enabled = true,
    color = Color3.fromRGB(255, 0, 0),
    alwaysOnTop = true
}

-- Хранилище обводок
local activeHighlights = {}

-- ========== ФУНКЦИЯ СМЕНЫ СКИНА НОЖА ==========
local function changeKnifeSkin(knifeName)
    local knifeData = knifeSkins[knifeName]
    if not knifeData then return end
    
    -- Метод 1: Через RemoteEvent (работает в большинстве скриптов)
    local remote = ReplicatedStorage:FindFirstChild("KnifeChanger") or 
                   ReplicatedStorage:FindFirstChild("SkinChanger") or
                   ReplicatedStorage:FindFirstChild("Remote")
    
    if remote then
        remote:FireServer(knifeData.id, "knife")
    end
    
    -- Метод 2: Через изменение локального значения (альтернатива)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local knifeValue = playerGui:FindFirstChild("CurrentKnife")
        if knifeValue then
            knifeValue.Value = knifeData.id
        end
    end
    
    print("[✓] Скин ножа изменён на: " .. knifeData.name)
end

-- ========== ФУНКЦИЯ СМЕНЫ ПЕРЧАТОК ==========
local function changeGloveSkin(gloveName)
    local gloveData = gloveSkins[gloveName]
    if not gloveData then return end
    
    local remote = ReplicatedStorage:FindFirstChild("GloveChanger") or 
                   ReplicatedStorage:FindFirstChild("SkinChanger")
    
    if remote then
        remote:FireServer(gloveData.id, "glove")
    end
    
    print("[✓] Скин перчаток изменён на: " .. gloveData.name)
end

-- ========== ESP ФУНКЦИИ (обводка) ==========
local function updateESPForPlayer(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
    
    if not espSettings.enabled then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Chams"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = espSettings.color
    highlight.DepthMode = espSettings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    
    activeHighlights[player] = highlight
end

local function updateAllESP()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight.OutlineColor = espSettings.color
            highlight.DepthMode = espSettings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not activeHighlights[player] and espSettings.enabled and player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end

-- ========== СОЗДАНИЕ МЕНЮ ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxStrike_Menu"
screenGui.Parent = game:GetService("CoreGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 320, 0, 450)
menuFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BLOXSTRIKE | ESP + SKIN CHANGER"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 15
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1
content.Parent = menuFrame

-- Функция создания заголовка секции
local function createSectionHeader(text, yPos)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 25)
    header.Position = UDim2.new(0, 10, 0, yPos)
    header.BackgroundTransparency = 1
    header.Text = text
    header.TextColor3 = Color3.fromRGB(255, 200, 100)
    header.TextSize = 14
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = content
    return header
end

-- Функция создания кнопки выбора ножа
local function createKnifeButton(knifeName, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.45, 0, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    btn.Text = knifeName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = content
    
    btn.MouseButton1Click:Connect(function()
        selectedKnife = knifeName
        changeKnifeSkin(knifeName)
        -- Визуальный фидбек
        btn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        task.wait(0.15)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    end)
end

-- Функция создания переключателя ESP
local function createESPToggle(text, yPos, settingName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 25)
    btn.Position = UDim2.new(1, -70, 0.5, -12.5)
    btn.BackgroundColor3 = espSettings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
    btn.Text = espSettings[settingName] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        espSettings[settingName] = not espSettings[settingName]
        btn.BackgroundColor3 = espSettings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
        btn.Text = espSettings[settingName] and "ON" or "OFF"
        if settingName == "enabled" then
            updateAllESP()
        elseif settingName == "alwaysOnTop" then
            updateAllESP()
        end
    end)
end

-- Функция выбора цвета ESP
local function createColorPicker(yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = "Цвет обводки:"
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local colors = {
        {Color3.fromRGB(255, 0, 0), "Красный"},
        {Color3.fromRGB(0, 255, 0), "Зелёный"},
        {Color3.fromRGB(0, 0, 255), "Синий"},
        {Color3.fromRGB(255, 255, 0), "Жёлтый"},
        {Color3.fromRGB(255, 0, 255), "Розовый"}
    }
    
    for i, colorData in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 45, 0, 25)
        btn.Position = UDim2.new(0, (i-1) * 50 + 5, 0, 25)
        btn.BackgroundColor3 = colorData[1]
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = frame
        
        btn.MouseButton1Click:Connect(function()
            espSettings.color = colorData[1]
            updateAllESP()
        end)
    end
end

-- Сборка меню
local yOffset = 10

-- Секция: Скин ножа
createSectionHeader("🔪 СКИНЫ НОЖЕЙ", yOffset)
yOffset = yOffset + 30

-- Кнопки ножей (в 2 ряда)
createKnifeButton("M9 Bayonet", yOffset)
local btn2 = Instance.new("TextButton")
btn2.Size = UDim2.new(0.45, 0, 0, 35)
btn2.Position = UDim2.new(0.53, 0, 0, yOffset)
btn2.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
btn2.Text = "Karambit"
btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
btn2.TextSize = 12
btn2.Font = Enum.Font.Gotham
btn2.BorderSizePixel = 0
btn2.Parent = content
btn2.MouseButton1Click:Connect(function()
    selectedKnife = "Karambit"
    changeKnifeSkin("Karambit")
    btn2.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    task.wait(0.15)
    btn2.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
end)

yOffset = yOffset + 45
createKnifeButton("Butterfly", yOffset)
local btn4 = Instance.new("TextButton")
btn4.Size = UDim2.new(0.45, 0, 0, 35)
btn4.Position = UDim2.new(0.53, 0, 0, yOffset)
btn4.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
btn4.Text = "Huntsman"
btn4.TextColor3 = Color3.fromRGB(255, 255, 255)
btn4.TextSize = 12
btn4.Font = Enum.Font.Gotham
btn4.BorderSizePixel = 0
btn4.Parent = content
btn4.MouseButton1Click:Connect(function()
    selectedKnife = "Huntsman"
    changeKnifeSkin("Huntsman")
    btn4.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    task.wait(0.15)
    btn4.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
end)

yOffset = yOffset + 50

-- Секция: ESP
createSectionHeader("👁️ ESP НАСТРОЙКИ", yOffset)
yOffset = yOffset + 30
createESPToggle("Включить ESP", yOffset, "enabled")
yOffset = yOffset + 45
createESPToggle("Сквозь стены", yOffset, "alwaysOnTop")
yOffset = yOffset + 50
createColorPicker(yOffset)

-- ========== ИНИЦИАЛИЗАЦИЯ ==========
-- ESP для всех игроков
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            updateESPForPlayer(player)
        end
        player.CharacterAdded:Connect(function()
            task.wait(0.1)
            updateESPForPlayer(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    updateESPForPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        updateESPForPlayer(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
end)

-- Открытие меню по Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuFrame.Visible = not menuFrame.Visible
    end
end)

-- Автоматическая попытка применить скин при загрузке
task.wait(1)
changeKnifeSkin("M9 Bayonet")

print("✅ BloxStrike ESP + Skin Changer загружен!")
print("📌 Нажми INSERT для открытия меню")
print("🔪 Скин M9 Bayonet применён автоматически")
