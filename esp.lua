-- BloxStrike: Упрощённая версия (работает на Solara/Xeno)
-- Нажми INSERT для меню, P для 3-го лица

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- ========== ПРОВЕРКА ЭКЗЕКУТОРА ==========
local isWeakExecutor = pcall(function() 
    return syn and true or false 
end) or false

print("[✓] Скрипт загружен, режим: " .. (isWeakExecutor and "Weak" or "Normal"))

-- ========== НАСТРОЙКИ ==========
local settings = {
    espEnabled = true,
    espColor = Color3.fromRGB(255, 0, 0),
    espAlwaysOnTop = true,
    bhopEnabled = true,
    thirdPersonEnabled = false
}

local activeHighlights = {}
local character = nil
local humanoid = nil

-- ========== ОБНОВЛЕНИЕ ПЕРСОНАЖА ==========
local function updateCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character and character:FindFirstChild("Humanoid")
    task.wait(0.5)
    if settings.thirdPersonEnabled then
        setThirdPerson(true)
    end
end)

-- ========== 3-Е ЛИЦО (УПРОЩЁННАЯ ВЕРСИЯ) ==========
local function setThirdPerson(enabled)
    settings.thirdPersonEnabled = enabled
    
    if enabled then
        -- Простой способ: просто меняем тип камеры
        Camera.CameraSubject = character
        Camera.CameraType = Enum.CameraType.Follow
        -- Увеличиваем расстояние
        Camera.FieldOfView = 70
        print("[✓] 3-е лицо включено")
    else
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = nil
        print("[✓] 1-е лицо включено")
    end
end

-- Бинд на P
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        setThirdPerson(not settings.thirdPersonEnabled)
    end
end)

-- ========== BUNNYHOP (УПРОЩЁННЫЙ) ==========
local spacePressed = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space and settings.bhopEnabled then
        spacePressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spacePressed = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not settings.bhopEnabled then return end
    
    updateCharacter()
    if not humanoid then return end
    
    -- Простая проверка: если зажат пробел и персонаж на земле
    if spacePressed then
        local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air or 
                          humanoid:GetState() == Enum.HumanoidStateType.Running or 
                          humanoid:GetState() == Enum.HumanoidStateType.Landed
        if isGrounded then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ========== ESP (БЕЗ OutlineThickness) ==========
local function updateESPForPlayer(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
    
    if not settings.espEnabled then return end
    if player == LocalPlayer then return end
    
    local char = player.Character
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Chams"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = settings.espColor
    highlight.DepthMode = settings.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Parent = char
    
    activeHighlights[player] = highlight
end

local function updateAllESP()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight.OutlineColor = settings.espColor
            highlight.DepthMode = settings.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not activeHighlights[player] and settings.espEnabled and player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end

-- ========== МЕНЮ ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_Menu"
screenGui.Parent = game:GetService("CoreGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 250, 0, 280)
menuFrame.Position = UDim2.new(0.5, -125, 0.5, -140)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BLOXSTRIKE MENU"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
content.Parent = menuFrame

local function createToggle(text, yPos, settingName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(55, 55, 70)
    btn.Text = text .. " : " .. (settings[settingName] and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = content
    
    btn.MouseButton1Click:Connect(function()
        settings[settingName] = not settings[settingName]
        btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(55, 55, 70)
        btn.Text = text .. " : " .. (settings[settingName] and "ON" or "OFF")
        
        if settingName == "espEnabled" or settingName == "espAlwaysOnTop" then
            updateAllESP()
        end
    end)
end

local function createColorPicker(yPos)
    local colors = {
        {Color3.fromRGB(255, 0, 0), "Красный"},
        {Color3.fromRGB(0, 255, 0), "Зелёный"},
        {Color3.fromRGB(0, 0, 255), "Синий"},
        {Color3.fromRGB(255, 255, 0), "Жёлтый"}
    }
    
    for i, colorData in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2, -5, 0, 30)
        btn.Position = UDim2.new(0.05 + (i-1) * 0.23, 0, 0, yPos)
        btn.BackgroundColor3 = colorData[1]
        btn.Text = colorData[2]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = content
        
        btn.MouseButton1Click:Connect(function()
            settings.espColor = colorData[1]
            updateAllESP()
        end)
    end
end

-- Сборка меню
local y = 10
createToggle("ESP (обводка)", y, "espEnabled")
y = y + 45
createToggle("Сквозь стены", y, "espAlwaysOnTop")
y = y + 45
createToggle("BunnyHop (авто-прыжок)", y, "bhopEnabled")
y = y + 45
createToggle("3-е лицо (P)", y, "thirdPersonEnabled")
y = y + 55
createColorPicker(y)

-- Подсказка
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 25)
hint.Position = UDim2.new(0, 10, 0, y + 45)
hint.BackgroundTransparency = 1
hint.Text = "Нажми P для 3-го лица"
hint.TextColor3 = Color3.fromRGB(150, 150, 170)
hint.TextSize = 11
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.Parent = content

-- ========== ИНИЦИАЛИЗАЦИЯ ==========
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuFrame.Visible = not menuFrame.Visible
    end
end)

updateCharacter()
updateAllESP()

print("✅ Загружено!")
print("📌 INSERT - меню")
print("🎮 P - 3-е лицо")
print("🦘 Зажми ПРОБЕЛ для BunnyHop")
