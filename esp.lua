-- BloxStrike: ESP + BunnyHop + Anti-Aim + 3rd Person
-- Нажми INSERT для открытия меню
-- Нажми P для переключения вида от 1/3 лица

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- ========== НАСТРОЙКИ ==========
local settings = {
    -- ESP
    espEnabled = true,
    espColor = Color3.fromRGB(255, 0, 0),
    espAlwaysOnTop = true,
    
    -- BunnyHop
    bhopEnabled = true,
    bhopGroundCheck = true,
    
    -- Anti-Aim
    antiAimEnabled = true,
    antiAimType = "jitter", -- "jitter", "spin", "static"
    antiAimYaw = 180, -- дополнительное вращение
    
    -- 3rd Person
    thirdPersonEnabled = false,
    thirdPersonDistance = 8
}

local activeHighlights = {}
local antiAimAngle = 0
local lastTick = tick()

-- ========== 3-Е ЛИЦО ПО БИНДУ ==========
local function setThirdPerson(enabled)
    settings.thirdPersonEnabled = enabled
    if enabled then
        Camera.CameraType = Enum.CameraType.Scriptable
        -- Сохраняем текущую позицию камеры относительно персонажа
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local direction = (Camera.CFrame.Position - hrp.Position).unit
            local newPos = hrp.Position + direction * settings.thirdPersonDistance
            Camera.CFrame = CFrame.new(newPos, hrp.Position)
        end
    else
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- Обновление позиции камеры для 3 лица
local function updateThirdPerson()
    if not settings.thirdPersonEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Получаем направление камеры от мыши
    local mouseDirection = (Camera.CFrame.LookVector * Vector3.new(1, 0, 1)).unit
    if mouseDirection.Magnitude < 0.1 then
        mouseDirection = Vector3.new(1, 0, 0)
    end
    
    local cameraOffset = mouseDirection * settings.thirdPersonDistance
    local targetPos = hrp.Position + Vector3.new(0, 1.5, 0) + cameraOffset
    
    -- Плавное движение камеры
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(targetPos, hrp.Position + Vector3.new(0, 1.5, 0)), 0.3)
end

-- Бинд на P для переключения вида
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        setThirdPerson(not settings.thirdPersonEnabled)
        print("[✓] Вид от " .. (settings.thirdPersonEnabled and "3-го лица" or "1-го лица"))
    end
end)

-- ========== ANTI-AIM ==========
local function updateAntiAim()
    if not settings.antiAimEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Получаем текущее вращение
    local currentCFrame = hrp.CFrame
    local currentAngle = currentCFrame.Y
    
    if settings.antiAimType == "jitter" then
        -- Дёргающаяся голова (быстро меняется угол)
        antiAimAngle = (antiAimAngle + 45) % 360
        local newYaw = math.rad(antiAimAngle + settings.antiAimYaw)
        hrp.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, newYaw, 0)
        
    elseif settings.antiAimType == "spin" then
        -- Постоянное вращение
        antiAimAngle = (antiAimAngle + 15) % 360
        local newYaw = math.rad(antiAimAngle + settings.antiAimYaw)
        hrp.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, newYaw, 0)
        
    elseif settings.antiAimType == "static" then
        -- Фиксированный угол
        local newYaw = math.rad(settings.antiAimYaw)
        hrp.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, newYaw, 0)
    end
end

-- Запуск Anti-Aim в цикле (оптимизировано)
RunService.RenderStepped:Connect(function()
    if settings.antiAimEnabled and tick() - lastTick > 0.05 then
        lastTick = tick()
        updateAntiAim()
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
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Chams"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = settings.espColor
    highlight.DepthMode = settings.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
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

-- ========== BUNNYHOP ==========
local humanoid = nil
local character = nil

local function updateCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character and character:FindFirstChild("Humanoid")
end)

RunService.RenderStepped:Connect(function()
    if not settings.bhopEnabled then return end
    
    updateCharacter()
    if not humanoid then return end
    
    local isRunning = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or 
                      UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or
                      (UserInputService:IsKeyDown(Enum.KeyCode.W) and humanoid.MoveDirection.Magnitude > 0)
    
    if isRunning then
        if settings.bhopGroundCheck then
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

-- Обновление камеры для 3 лица
RunService.RenderStepped:Connect(function()
    if settings.thirdPersonEnabled then
        updateThirdPerson()
    end
end)

-- ========== МЕНЮ ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxStrike_Menu"
screenGui.Parent = game:GetService("CoreGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 320, 0, 500)
menuFrame.Position = UDim2.new(0.5, -160, 0.5, -250)
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
titleText.Text = "BLOXSTRIKE | ESP + BHOP + AA + 3P"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
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

-- Перетаскивание
local dragging = false
local dragStartPos, frameStartPos

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

-- Вспомогательные функции
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

local function createDropdown(text, options, yPos, settingName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local currentValue = settings[settingName]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    btn.Text = currentValue
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local expanded = false
    local dropdownFrame = nil
    
    btn.MouseButton1Click:Connect(function()
        if expanded then
            if dropdownFrame then dropdownFrame:Destroy() end
            expanded = false
            return
        end
        
        expanded = true
        dropdownFrame = Instance.new("Frame")
        dropdownFrame.Size = UDim2.new(1, 0, 0, #options * 30)
        dropdownFrame.Position = UDim2.new(0, 0, 0, 58)
        dropdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        dropdownFrame.BorderSizePixel = 0
        dropdownFrame.Parent = frame
        
        for i, option in ipairs(options) do
            local optionBtn = Instance.new("TextButton")
            optionBtn.Size = UDim2.new(1, 0, 0, 30)
            optionBtn.Position = UDim2.new(0, 0, 0, (i-1) * 30)
            optionBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
            optionBtn.Text = option
            optionBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            optionBtn.TextSize = 12
            optionBtn.Font = Enum.Font.Gotham
            optionBtn.BorderSizePixel = 0
            optionBtn.Parent = dropdownFrame
            
            optionBtn.MouseButton1Click:Connect(function()
                settings[settingName] = option
                btn.Text = option
                dropdownFrame:Destroy()
                expanded = false
            end)
        end
    end)
    
    -- Закрыть при клике вне
    local function closeDropdown()
        if dropdownFrame then
            dropdownFrame:Destroy()
            expanded = false
        end
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local btnAbsPos = btn.AbsolutePosition
            local btnSize = btn.AbsoluteSize
            
            if mousePos.X < btnAbsPos.X or mousePos.X > btnAbsPos.X + btnSize.X or
               mousePos.Y < btnAbsPos.Y or mousePos.Y > btnAbsPos.Y + btnSize.Y then
                closeDropdown()
            end
        end
    end)
end

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

-- СБОРКА МЕНЮ
local yOffset = 10

-- Секция: Anti-Aim
createSectionHeader("🎯 ANTI-AIM", yOffset)
yOffset = yOffset + 30
createToggle("Включить Anti-Aim", yOffset, "antiAimEnabled", false)
yOffset = yOffset + 50
createDropdown("Тип Anti-Aim", {"jitter", "spin", "static"}, yOffset, "antiAimType")

yOffset = yOffset + 80

-- Секция: BunnyHop
createSectionHeader("🦘 BUNNYHOP", yOffset)
yOffset = yOffset + 30
createToggle("Включить BunnyHop", yOffset, "bhopEnabled", false)
yOffset = yOffset + 50
createToggle("Проверка на земле", yOffset, "bhopGroundCheck", false)

yOffset = yOffset + 60

-- Секция: 3rd Person
createSectionHeader("📷 КАМЕРА", yOffset)
yOffset = yOffset + 30
local thirdPersonLabel = Instance.new("TextLabel")
thirdPersonLabel.Size = UDim2.new(1, -20, 0, 25)
thirdPersonLabel.Position = UDim2.new(0, 10, 0, yOffset)
thirdPersonLabel.BackgroundTransparency = 1
thirdPersonLabel.Text = "Нажми P для переключения вида"
thirdPersonLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
thirdPersonLabel.TextSize = 12
thirdPersonLabel.Font = Enum.Font.Gotham
thirdPersonLabel.TextXAlignment = Enum.TextXAlignment.Left
thirdPersonLabel.Parent = content

yOffset = yOffset + 40

-- Секция: ESP
createSectionHeader("👁️ ESP", yOffset)
yOffset = yOffset + 30
createToggle("Включить ESP", yOffset, "espEnabled", true)
yOffset = yOffset + 50
createToggle("Сквозь стены", yOffset, "espAlwaysOnTop", true)
yOffset = yOffset + 65
createColorPicker(yOffset)

-- ИНИЦИАЛИЗАЦИЯ
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

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
end)
updateCharacter()

print("✅ BloxStrike загружен! Нажми INSERT для меню, P для 3-го лица")
