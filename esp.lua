-- BloxStrike: ESP + BunnyHop (авто-прыжок при беге)
-- Нажми INSERT для открытия меню

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ========== НАСТРОЙКИ ==========
local settings = {
    -- ESP настройки
    espEnabled = true,
    espColor = Color3.fromRGB(255, 0, 0),
    espAlwaysOnTop = true,
    
    -- BunnyHop настройки
    bhopEnabled = true,
    bhopGroundCheck = true
}

-- Хранилище обводок
local activeHighlights = {}

-- ========== ESP ФУНКЦИИ (исправлено) ==========
local function updateESPForPlayer(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
    
    if not settings.espEnabled then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Chams"
    highlight.FillTransparency = 1  -- только обводка, без заливки
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = settings.espColor
    highlight.DepthMode = settings.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    -- outlineThickness УДАЛЁН — его нет в Roblox
    highlight.Parent = character
    
    activeHighlights[player] = highlight
end

local function updateAllESP()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight.OutlineColor = settings.espColor
            highlight.DepthMode = settings.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
            activeHighlights[player] = nil
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not activeHighlights[player] and settings.espEnabled and player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end

-- ========== BUNNYHOP ФУНКЦИИ ==========
local humanoid = nil
local character = nil

local function updateCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
    end
end

-- Обновляем при смене персонажа
LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:FindFirstChild("Humanoid")
end)

-- Основной цикл BunnyHop
RunService.RenderStepped:Connect(function()
    if not settings.bhopEnabled then return end
    
    updateCharacter()
    if not humanoid then return end
    
    -- Проверка: зажат ли Shift (бег) или W
    local isRunning = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or 
                      UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or
                      (UserInputService:IsKeyDown(Enum.KeyCode.W) and humanoid.MoveDirection.Magnitude > 0)
    
    if isRunning then
        if settings.bhopGroundCheck then
            -- Проверка на земле
            local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air or 
                              humanoid:GetState() == Enum.HumanoidStateType.Running or 
                              humanoid:GetState() == Enum.HumanoidStateType.Landed
            
            if isGrounded then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        else
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ========== СОЗДАНИЕ МЕНЮ ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxStrike_Menu"
screenGui.Parent = game:GetService("CoreGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 280, 0, 350)
menuFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

-- Заголовок с возможностью перетаскивания
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BLOXSTRIKE | ESP + BUNNYHOP"
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

-- Перетаскивание окна
local dragging = false
local dragStartPos
local frameStartPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = input.Position
        frameStartPos = menuFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        menuFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
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

-- Функция создания переключателя
local function createToggle(text, yPos, settingName, isEspSetting)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
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
    btn.Size = UDim2.new(0, 60, 0, 28)
    btn.Position = UDim2.new(1, -70, 0.5, -14)
    btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
    btn.Text = settings[settingName] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        settings[settingName] = not settings[settingName]
        btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
        btn.Text = settings[settingName] and "ON" or "OFF"
        
        if isEspSetting then
            if settingName == "espEnabled" then
                updateAllESP()
            elseif settingName == "espAlwaysOnTop" then
                updateAllESP()
            end
        end
    end)
end

-- Функция выбора цвета
local function createColorPicker(yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 55)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = "Цвет обводки:"
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local colors = {
        {Color3.fromRGB(255, 0, 0), "🔴"},
        {Color3.fromRGB(0, 255, 0), "🟢"},
        {Color3.fromRGB(0, 0, 255), "🔵"},
        {Color3.fromRGB(255, 255, 0), "🟡"},
        {Color3.fromRGB(255, 0, 255), "🟣"}
    }
    
    for i, colorData in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 45, 0, 28)
        btn.Position = UDim2.new(0, (i-1) * 50 + 5, 0, 28)
        btn.BackgroundColor3 = colorData[1]
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = frame
        
        btn.MouseButton1Click:Connect(function()
            settings.espColor = colorData[1]
            updateAllESP()
        end)
    end
end

-- Сборка меню
local yOffset = 10

-- Секция: BunnyHop
createSectionHeader("🦘 BUNNYHOP (авто-прыжок)", yOffset)
yOffset = yOffset + 30
createToggle("Включить BunnyHop", yOffset, "bhopEnabled", false)
yOffset = yOffset + 50
createToggle("Проверка на земле", yOffset, "bhopGroundCheck", false)

yOffset = yOffset + 60

-- Секция: ESP
createSectionHeader("👁️ ESP НАСТРОЙКИ", yOffset)
yOffset = yOffset + 30
createToggle("Включить ESP", yOffset, "espEnabled", true)
yOffset = yOffset + 50
createToggle("Сквозь стены", yOffset, "espAlwaysOnTop", true)
yOffset = yOffset + 65
createColorPicker(yOffset)

-- ========== ИНИЦИАЛИЗАЦИЯ ESP ==========
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

-- Обновление персонажа для BunnyHop
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
end)
updateCharacter()

print("✅ BloxStrike ESP + BunnyHop загружен!")
print("📌 Нажми INSERT для открытия меню")
print("🦘 Зажми Shift + W и беги — персонаж будет автоматически прыгать!")
