-- ESP / Chams с меню (Insert для открытия/закрытия)
-- Работает через консоль (F9) или экзекутор

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Настройки по умолчанию
local settings = {
    enabled = true,
    color = Color3.fromRGB(255, 0, 0), -- красный
    thickness = 2,
    fillTransparency = 1, -- 1 = полностью прозрачный (только обводка)
    outlineTransparency = 0,
    alwaysOnTop = true
}

-- Создаём ScreenGui для меню
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_Menu"
screenGui.Parent = game:GetService("CoreGui")

-- Главное меню (Frame)
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MainMenu"
menuFrame.Size = UDim2.new(0, 300, 0, 400)
menuFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
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
titleText.Text = "ESP CHAMS MENU"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.Parent = titleBar

-- Закрыть кнопка (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
end)

-- Содержимое меню
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1
content.Parent = menuFrame

-- Функция создания переключателя (Toggle)
local function createToggle(name, description, yPos, settingKey)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = content
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    toggleLabel.TextSize = 14
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 25)
    toggleButton.Position = UDim2.new(1, -60, 0.5, -12.5)
    toggleButton.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(150, 60, 60)
    toggleButton.Text = settings[settingKey] and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 12
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    toggleButton.MouseButton1Click:Connect(function()
        settings[settingKey] = not settings[settingKey]
        toggleButton.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(150, 60, 60)
        toggleButton.Text = settings[settingKey] and "ON" or "OFF"
        updateAllESP()
    end)
    
    return toggleFrame
end

-- Функция создания слайдера
local function createSlider(name, minVal, maxVal, yPos, settingKey, formatFunc)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 60)
    sliderFrame.Position = UDim2.new(0, 10, 0, yPos)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = content
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, 0, 0, 20)
    sliderLabel.Position = UDim2.new(0, 0, 0, 5)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = name .. ": " .. (formatFunc and formatFunc(settings[settingKey]) or tostring(settings[settingKey]))
    sliderLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    sliderLabel.TextSize = 13
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 4)
    slider.Position = UDim2.new(0, 10, 0, 35)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.BorderSizePixel = 0
    slider.Parent = sliderFrame
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((settings[settingKey] - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = slider
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 15, 0, 15)
    sliderButton.Position = UDim2.new((settings[settingKey] - minVal) / (maxVal - minVal), -7.5, 0.5, -7.5)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderButton.BackgroundTransparency = 0.5
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = slider
    
    local dragging = false
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MousePosition then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderAbsPos = slider.AbsolutePosition.X
            local sliderWidth = slider.AbsoluteSize.X
            local percent = math.clamp((mousePos.X - sliderAbsPos) / sliderWidth, 0, 1)
            local value = minVal + percent * (maxVal - minVal)
            
            if settingKey == "thickness" then
                value = math.floor(value)
            end
            
            settings[settingKey] = value
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderButton.Position = UDim2.new(percent, -7.5, 0.5, -7.5)
            sliderLabel.Text = name .. ": " .. (formatFunc and formatFunc(value) or tostring(value))
            updateAllESP()
        end
    end)
    
    return sliderFrame
end

-- Функция выбора цвета
local function createColorPicker(yPos)
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -20, 0, 60)
    colorFrame.Position = UDim2.new(0, 10, 0, yPos)
    colorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    colorFrame.BorderSizePixel = 0
    colorFrame.Parent = content
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, 0, 0, 20)
    colorLabel.Position = UDim2.new(0, 0, 0, 5)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "Цвет обводки"
    colorLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    colorLabel.TextSize = 13
    colorLabel.Font = Enum.Font.Gotham
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorFrame
    
    local colors = {
        {Color3.fromRGB(255, 0, 0), "Красный"},
        {Color3.fromRGB(0, 255, 0), "Зелёный"},
        {Color3.fromRGB(0, 0, 255), "Синий"},
        {Color3.fromRGB(255, 255, 0), "Жёлтый"},
        {Color3.fromRGB(255, 0, 255), "Розовый"},
        {Color3.fromRGB(0, 255, 255), "Голубой"}
    }
    
    for i, colorData in ipairs(colors) do
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0, 40, 0, 30)
        colorBtn.Position = UDim2.new(0, (i-1) * 45 + 10, 0, 30)
        colorBtn.BackgroundColor3 = colorData[1]
        colorBtn.BackgroundTransparency = 0.2
        colorBtn.Text = ""
        colorBtn.BorderSizePixel = 0
        colorBtn.Parent = colorFrame
        
        colorBtn.MouseButton1Click:Connect(function()
            settings.color = colorData[1]
            updateAllESP()
        end)
    end
    
    return colorFrame
end

-- Обновление ESP для всех игроков
local activeHighlights = {}

local function updateESPForPlayer(player)
    -- Очищаем старые обводки
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
    
    if not settings.enabled then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = settings.fillTransparency
    highlight.OutlineTransparency = settings.outlineTransparency
    highlight.OutlineColor = settings.color
    highlight.DepthMode = settings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    
    activeHighlights[player] = highlight
end

local function updateAllESP()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight.OutlineColor = settings.color
            highlight.OutlineTransparency = settings.outlineTransparency
            highlight.DepthMode = settings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
            activeHighlights[player] = nil
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not activeHighlights[player] and settings.enabled then
            updateESPForPlayer(player)
        elseif activeHighlights[player] and not settings.enabled then
            activeHighlights[player]:Destroy()
            activeHighlights[player] = nil
        end
    end
end

-- Следим за появлением персонажей
local function onCharacterAdded(player, character)
    task.wait(0.1)
    if settings.enabled and player ~= LocalPlayer then
        updateESPForPlayer(player)
    end
end

-- Инициализация
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        updateESPForPlayer(player)
    end
    
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end

Players.PlayerAdded:Connect(function(player)
    updateESPForPlayer(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
end)

-- Создаём элементы меню
local yOffset = 10
createToggle("Включить ESP", "Показывать обводку игроков", yOffset, "enabled")
yOffset = yOffset + 50
createToggle("Сквозь стены", "Обводка через препятствия", yOffset, "alwaysOnTop")
yOffset = yOffset + 50
createSlider("Толщина обводки", 1, 5, yOffset, "thickness", function(v) return tostring(v) .. "px" end)
yOffset = yOffset + 70
createColorPicker(yOffset)
yOffset = yOffset + 70
createToggle("Только контур", "Убрать заливку (оставить обводку)", yOffset, "fillTransparency")
-- Это костыль для настройки, но мы уже используем fillTransparency

-- Открытие/закрытие по Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        menuFrame.Visible = not menuFrame.Visible
    end
end)

print("ESP с меню загружен! Нажми INSERT для открытия меню.")
