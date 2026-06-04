-- ESP / Chams с РАБОЧИМ меню (Insert)
-- Исправлено: ползунок, тогглы, сохранение настроек

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Настройки по умолчанию
local settings = {
    enabled = true,
    color = Color3.fromRGB(255, 0, 0),
    thickness = 2,
    alwaysOnTop = true
}

-- Хранилище обводок
local activeHighlights = {}

-- Функция обновления обводки у одного игрока
local function updateHighlightForPlayer(player)
    -- Удаляем старую
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
    
    if not settings.enabled then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Chams"
    highlight.FillTransparency = 1  -- только обводка
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = settings.color
    highlight.DepthMode = settings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    
    activeHighlights[player] = highlight
end

-- Обновить всех
local function updateAllESP()
    for player, highlight in pairs(activeHighlights) do
        if highlight and highlight.Parent then
            -- Обновляем параметры существующих
            highlight.OutlineColor = settings.color
            highlight.DepthMode = settings.alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        else
            activeHighlights[player] = nil
        end
    end
    
    -- Добавляем новых игроков или обновляем отсутствующих
    for _, player in ipairs(Players:GetPlayers()) do
        if not activeHighlights[player] and settings.enabled and player ~= LocalPlayer then
            updateHighlightForPlayer(player)
        end
    end
end

-- Создаём GUI меню
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPMenu"
screenGui.Parent = game:GetService("CoreGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 260, 0, 320)
menuFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
menuFrame.BackgroundTransparency = 0.15
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

-- Заголовок с возможностью перетаскивания
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
titleBar.BorderSizePixel = 0
titleBar.Parent = menuFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -35, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ ESP CHAMS"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 16
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
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
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
content.Parent = menuFrame

-- Функция создания переключателя (рабочий)
local function createToggle(text, yPos, settingName)
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
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 28)
    btn.Position = UDim2.new(1, -70, 0.5, -14)
    btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
    btn.Text = settings[settingName] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        settings[settingName] = not settings[settingName]
        btn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 70, 70)
        btn.Text = settings[settingName] and "ON" or "OFF"
        if settingName == "enabled" then
            updateAllESP()
        elseif settingName == "alwaysOnTop" then
            updateAllESP()
        end
    end)
end

-- Функция создания ползунка (ИСПРАВЛЕНА)
local function createSlider(text, minVal, maxVal, yPos, settingName, formatFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 65)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. (formatFunc and formatFunc(settings[settingName]) or tostring(settings[settingName]))
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 4)
    sliderBg.Position = UDim2.new(0, 10, 0, 45)
    sliderBg.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((settings[settingName] - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.Position = UDim2.new((settings[settingName] - minVal) / (maxVal - minVal), -8, 0.5, -8)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg
    
    local sliding = false
    
    local function updateSlider(inputPos)
        local sliderAbsPos = sliderBg.AbsolutePosition.X
        local sliderWidth = sliderBg.AbsoluteSize.X
        local percent = math.clamp((inputPos.X - sliderAbsPos) / sliderWidth, 0, 1)
        local value = minVal + percent * (maxVal - minVal)
        
        if settingName == "thickness" then
            value = math.floor(value)
        end
        
        settings[settingName] = value
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -8, 0.5, -8)
        label.Text = text .. ": " .. (formatFunc and formatFunc(value) or tostring(value))
        
        -- Применяем изменение толщины (для Highlight это OutlineThickness)
        for _, highlight in pairs(activeHighlights) do
            if highlight then
                highlight.OutlineThickness = settings.thickness
            end
        end
    end
    
    sliderBtn.MouseButton1Down:Connect(function()
        sliding = true
        updateSlider(UserInputService:GetMouseLocation())
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
    
    -- Инициализация толщины
    for _, highlight in pairs(activeHighlights) do
        if highlight then
            highlight.OutlineThickness = settings.thickness
        end
    end
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
    label.Text = "Цвет обводки"
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local colors = {
        {Color3.fromRGB(255, 0, 0), "🔴"},
        {Color3.fromRGB(0, 255, 0), "🟢"},
        {Color3.fromRGB(0, 0, 255), "🔵"},
        {Color3.fromRGB(255, 255, 0), "🟡"},
        {Color3.fromRGB(255, 0, 255), "🟣"},
        {Color3.fromRGB(0, 255, 255), "🔷"}
    }
    
    for i, colorData in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 35, 0, 30)
        btn.Position = UDim2.new(0, (i-1) * 40 + 5, 0, 30)
        btn.BackgroundColor3 = colorData[1]
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = frame
        
        btn.MouseButton1Click:Connect(function()
            settings.color = colorData[1]
            for _, highlight in pairs(activeHighlights) do
                if highlight then
                    highlight.OutlineColor = settings.color
                end
            end
        end)
    end
end

-- Создаём элементы меню
createToggle("Включить ESP", 10, "enabled")
createToggle("Сквозь стены", 60, "alwaysOnTop")
createSlider("Толщина", 1, 5, 110, "thickness", function(v) return tostring(v) .. "px" end)
createColorPicker(185)

-- Открытие/закрытие по Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuFrame.Visible = not menuFrame.Visible
    end
end)

-- Обработка появления новых игроков и персонажей
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        updateHighlightForPlayer(player)
    end)
    if player.Character then
        task.wait(0.1)
        updateHighlightForPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeHighlights[player] then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = nil
    end
end)

-- Инициализация всех игроков
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then
            updateHighlightForPlayer(player)
        end
        player.CharacterAdded:Connect(function()
            task.wait(0.1)
            updateHighlightForPlayer(player)
        end)
    end
end

-- Запускаем обновление
updateAllESP()

print("✅ ESP с меню загружен! Нажми INSERT")
