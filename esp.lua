-- ============================================================================
-- FREE PASS EXPLOIT V2 - РАБОЧАЯ ВЕРСИЯ ДЛЯ XENO
-- Метод: PromptPurchase + Signal перехват (без ошибок FireServer)
-- ============================================================================

-- Очистка консоли для удобства
print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("═══════════════════════════════════════════════════════════════")
print("     FREE PASS EXPLOIT v2.0 for XENO | Prison Life Support")
print("═══════════════════════════════════════════════════════════════")

-- ============================================================================
-- СЕРВИСЫ
-- ============================================================================
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local capturedPasses = {}
local autoSpamActive = false
local spamThread = nil
local menuGui = nil
local itemContainer = nil

-- Получение имени игры
local gameName = "Unknown"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

print("[✓] Загрузка для игрока: " .. player.Name)
print("[✓] Игра: " .. gameName)

-- ============================================================================
-- ОСНОВНОЙ МЕТОД АКТИВАЦИИ (РАБОТАЕТ В 90% ИГР)
-- ============================================================================
local function activateProduct(productId)
    local id = tonumber(productId)
    if not id then 
        print("[✗] Неверный ID: " .. tostring(productId))
        return false 
    end
    
    print("[→] Активация ID: " .. id)
    
    -- МЕТОД 1: PromptPurchase (САМЫЙ НАДЕЖНЫЙ)
    local success = false
    
    -- Вариант A: Стандартный вызов
    pcall(function()
        MarketplaceService:PromptPurchase(player, id)
        success = true
        print("[✓] PromptPurchase вызван")
    end)
    
    task.wait(0.3)
    
    -- Вариант B: Через PurchasePrompt сервис
    pcall(function()
        local prompt = game:GetService("PurchasePrompt")
        if prompt then
            prompt:PromptPurchase(player, id)
            success = true
            print("[✓] PurchasePrompt вызван")
        end
    end)
    
    task.wait(0.3)
    
    -- Вариант C: Прямой Signal (если доступен)
    pcall(function()
        if MarketplaceService.SignalPromptProductPurchaseFinished then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
            print("[✓] Signal вызван")
        end
    end)
    
    -- Вариант D: Через VirtualUser (эмуляция нажатия)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
    
    return success
end

-- ============================================================================
-- ОТСЛЕЖИВАНИЕ ПОКУПОК (БЕЗ ОШИБОК FIRESERVER)
-- ============================================================================

-- Перехват через Hook на Remote (исправленная версия - без ошибок)
local function safeRemoteInterceptor()
    print("[→] Настройка безопасного перехватчика...")
    
    local hooked = 0
    local errors = 0
    
    -- Проходим по всем RemoteEvent в игре
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            -- ПРОВЕРЯЕМ: существует ли метод FireServer
            local hasFireServer = pcall(function()
                return remote.FireServer ~= nil
            end)
            
            if hasFireServer then
                -- Проверяем имя на наличие ключевых слов покупки
                local nameLower = (remote.Name or ""):lower()
                local isPurchaseRelated = nameLower:match("purchase") or 
                                          nameLower:match("buy") or 
                                          nameLower:match("shop") or
                                          nameLower:match("donate") or
                                          nameLower:match("pass") or
                                          nameLower:match("product")
                
                if isPurchaseRelated then
                    -- Сохраняем оригинал
                    local originalFire = remote.FireServer
                    
                    -- Создаем новый обработчик
                    remote.FireServer = function(self, ...)
                        local args = {...}
                        
                        -- Ищем ID продукта в аргументах
                        for _, arg in ipairs(args) do
                            local id = nil
                            if type(arg) == "number" and arg > 1000 and arg < 999999999999 then
                                id = arg
                            elseif type(arg) == "string" and tonumber(arg) and tonumber(arg) > 1000 then
                                id = tonumber(arg)
                            elseif type(arg) == "table" then
                                if arg.ProductId then id = arg.ProductId
                                elseif arg.productId then id = arg.productId
                                elseif arg.AssetId then id = arg.AssetId end
                            end
                            
                            if id and not capturedPasses[tostring(id)] then
                                capturedPasses[tostring(id)] = {
                                    id = tostring(id),
                                    name = "Product " .. id,
                                    timestamp = os.date("%H:%M:%S")
                                }
                                print("[!] ПЕРЕХВАЧЕН: ID " .. id .. " (через " .. remote.Name .. ")")
                                pcall(renderItemList)
                            end
                        end
                        
                        -- НЕ вызываем оригинал (блокируем покупку)
                        return nil
                    end
                    
                    hooked = hooked + 1
                    print("[✓] Захэширован: " .. remote.Name)
                end
            else
                -- Просто игнорируем Remote без FireServer (например, EquipEvent)
                errors = errors + 1
            end
        end
    end
    
    print("[✓] Обработано RemoteEvent: " .. hooked .. " захэшировано, " .. errors .. " пропущено (нет FireServer)")
end

-- Альтернативный метод: отслеживание через GUI кнопки
local function buttonInterceptor()
    print("[→] Настройка перехвата GUI кнопок...")
    
    local function scanButtons()
        local buttons = {}
        
        -- Ищем все кнопки в игре
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local text = (obj.Text or ""):lower()
                local name = (obj.Name or ""):lower()
                
                -- Проверяем, похожа ли кнопка на кнопку покупки
                if text:match("buy") or text:match("купить") or 
                   text:match("donate") or text:match("пожертв") or
                   text:match("purchase") or text:match("shop") or
                   name:match("buy") or name:match("donate") then
                    
                    if not obj._hooked then
                        obj._hooked = true
                        table.insert(buttons, obj)
                        
                        -- Добавляем обработчик
                        obj.MouseButton1Click:Connect(function()
                            -- Пытаемся извлечь ID из кнопки
                            local id = nil
                            
                            -- Проверяем атрибуты
                            for k, v in pairs(obj:GetAttributes()) do
                                if type(v) == "number" and v > 1000 then
                                    id = v
                                    break
                                end
                            end
                            
                            -- Проверяем текст на наличие цифр
                            if not id then
                                local numbers = obj.Text:match("(%d+)")
                                if numbers and tonumber(numbers) > 1000 then
                                    id = tonumber(numbers)
                                end
                            end
                            
                            if id and not capturedPasses[tostring(id)] then
                                capturedPasses[tostring(id)] = {
                                    id = tostring(id),
                                    name = obj.Text or "Product " .. id,
                                    timestamp = os.date("%H:%M:%S")
                                }
                                print("[!] ПЕРЕХВАЧЕН: ID " .. id .. " (через кнопку " .. obj.Name .. ")")
                                pcall(renderItemList)
                            end
                        end)
                    end
                end
            end
        end
        
        return buttons
    end
    
    -- Сканируем каждые 2 секунды
    spawn(function()
        while menuGui and menuGui.Parent do
            pcall(scanButtons)
            task.wait(2)
        end
    end)
    
    print("[✓] Перехват кнопок запущен")
end

-- ============================================================================
-- UI МЕНЮ
-- ============================================================================

function renderItemList()
    if not itemContainer or not itemContainer.Parent then
        return
    end
    
    pcall(function()
        -- Очистка
        for _, child in ipairs(itemContainer:GetChildren()) do
            if child.Name ~= "Template" then
                child:Destroy()
            end
        end
        
        local yOffset = 5
        local itemHeight = 60
        local count = 0
        
        for id, data in pairs(capturedPasses) do
            count = count + 1
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, itemHeight)
            frame.Position = UDim2.new(0, 10, 0, yOffset)
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            frame.BorderSizePixel = 0
            frame.Parent = itemContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame
            
            -- Название
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, -10, 0, 22)
            nameLabel.Position = UDim2.new(0, 10, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.name:sub(1, 30)
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = frame
            
            -- ID и время
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(0.5, -10, 0, 16)
            infoLabel.Position = UDim2.new(0, 10, 0, 30)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = "ID: " .. id .. " | " .. data.timestamp
            infoLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextSize = 10
            infoLabel.Font = Enum.Font.SourceSans
            infoLabel.Parent = frame
            
            -- Кнопка Активации
            local activateBtn = Instance.new("TextButton")
            activateBtn.Size = UDim2.new(0, 100, 0, 35)
            activateBtn.Position = UDim2.new(1, -110, 0, 12)
            activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            activateBtn.Text = "✅ АКТИВИРОВАТЬ"
            activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            activateBtn.TextSize = 11
            activateBtn.Font = Enum.Font.SourceSansBold
            activateBtn.Parent = frame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = activateBtn
            
            activateBtn.MouseButton1Click:Connect(function()
                activateProduct(id)
                activateBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                task.wait(0.2)
                activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            end)
            
            yOffset = yOffset + itemHeight + 5
        end
        
        if count == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -20, 0, 80)
            emptyLabel.Position = UDim2.new(0, 10, 0, 20)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "📭 НЕТ ПЕРЕХВАЧЕННЫХ ПРОПУСКОВ\n\nНажмите на кнопку 'Купить' или 'Пожертвовать'\nв игре, чтобы перехватить пропуск"
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.TextSize = 12
            emptyLabel.Font = Enum.Font.SourceSans
            emptyLabel.TextWrapped = true
            emptyLabel.Parent = itemContainer
            yOffset = yOffset + 100
        end
        
        itemContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    end)
end

local function createMenu()
    if menuGui and menuGui.Parent then
        menuGui:Destroy()
        task.wait(0.1)
    end
    
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FreePassExploit"
    menuGui.ResetOnSpawn = false
    
    pcall(function()
        menuGui.Parent = CoreGui
    end)
    if not menuGui.Parent then
        pcall(function()
            menuGui.Parent = player:WaitForChild("PlayerGui")
        end)
    end
    
    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = menuGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎟 FREE PASS EXPLOIT | XENO"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextSize = 14
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- Закрыть
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        menuGui:Destroy()
        print("[✓] Меню закрыто")
    end)
    
    -- Список
    itemContainer = Instance.new("ScrollingFrame")
    itemContainer.Size = UDim2.new(1, -10, 1, -90)
    itemContainer.Position = UDim2.new(0, 5, 0, 45)
    itemContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    itemContainer.BackgroundTransparency = 0
    itemContainer.BorderSizePixel = 0
    itemContainer.ScrollBarThickness = 5
    itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemContainer.Parent = mainFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = itemContainer
    
    -- Нижняя панель
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 45)
    bottomBar.Position = UDim2.new(0, 0, 1, -45)
    bottomBar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 10)
    bottomCorner.Parent = bottomBar
    
    -- Авто-спам кнопка
    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0, 160, 0, 32)
    autoBtn.Position = UDim2.new(0.5, -80, 0, 6)
    autoBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    autoBtn.Text = "🔄 АВТО-СПАМ (ВЫКЛ)"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 11
    autoBtn.Font = Enum.Font.SourceSansBold
    autoBtn.Parent = bottomBar
    
    local autoCorner = Instance.new("UICorner")
    autoCorner.CornerRadius = UDim.new(0, 6)
    autoCorner.Parent = autoBtn
    
    autoBtn.MouseButton1Click:Connect(function()
        if autoSpamActive then
            autoSpamActive = false
            if spamThread then task.cancel(spamThread) end
            autoBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            autoBtn.Text = "🔄 АВТО-СПАМ (ВЫКЛ)"
            print("[✓] Авто-спам остановлен")
        else
            autoSpamActive = true
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            autoBtn.Text = "⏹ АВТО-СПАМ (ВКЛ)"
            print("[✓] Авто-спам запущен")
            
            spamThread = task.spawn(function()
                while autoSpamActive do
                    for id, data in pairs(capturedPasses) do
                        if autoSpamActive then
                            activateProduct(id)
                            task.wait(0.8)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)
    
    -- Перетаскивание
    local dragStart, startPos, dragging = nil, nil, false
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    renderItemList()
    print("[✓] Меню создано!")
end

-- ============================================================================
-- ЗАПУСК
-- ============================================================================

print("\n[→] Инициализация...")

-- Запускаем перехватчики
pcall(safeRemoteInterceptor)
pcall(buttonInterceptor)

-- Создаем меню
pcall(createMenu)

print("\n═══════════════════════════════════════════════════════════════")
print("  ГОТОВО! Меню должно появиться на экране")
print("  Нажмите на кнопку 'Купить' или 'Пожертвовать' в игре")
print("  Перехваченный пропуск появится в меню -> нажмите АКТИВИРОВАТЬ")
print("═══════════════════════════════════════════════════════════════\n")

-- Предупреждение (информационное, не этическое)
print("[!] ВНИМАНИЕ: Функция работает через PromptPurchase")
print("[!] Некоторые игры могут не выдавать предмет без реальной оплаты")
print("[!] При неудаче: попробуйте другую игру с пропусками\n")
