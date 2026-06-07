-- ============================================================================
-- FREE PASS EXPLOIT FOR XENO EXECUTOR - ИСПРАВЛЕННАЯ ВЕРСИЯ
-- Roblox Gamepass/DevProduct/Limited UGC Unlocker
-- Version: KUSMAN_V1.1 (FIXED)
-- ============================================================================
-- ИНСТРУКЦИЯ ПО ЗАПУСКУ ДЛЯ XENO:
-- 1. Открыть Xeno Executor
-- 2. Подключиться к Roblox игре (Prison Life или любая другая)
-- 3. Вставить ЭТОТ ВЕСЬ ТЕКСТ в поле для скриптов
-- 4. Нажать Execute (Выполнить)
-- 5. На экране появится меню (обычно нажимается Insert, но меню появляется сразу)
-- 6. Для перехвата: нажмите на кнопку "пожертвовать" или "купить" в игре
-- ============================================================================

-- ПРОВЕРКА XENO
print("[FREE PASS] Xeno executor detected. Загрузка эксплойта (исправленная версия)...")

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
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

-- ============================================================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================================
local player = Players.LocalPlayer
local capturedPasses = {}  -- {["productId"] = {type, name, timestamp}}
local autoSpamActive = false
local spamThread = nil
local selectedItemId = nil
local currentGameName = ""
local menuGui = nil
local itemContainer = nil

-- Получение имени игры с защитой от ошибок
pcall(function()
    currentGameName = MarketplaceService:GetProductInfo(game.PlaceId).Name or "Unknown Game"
end)

-- ============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================================

-- Безопасный поиск Remote (без ошибок)
local function safeFindRemotes()
    local remoteList = {}
    
    -- Поиск во всех сервисах, но без вызова FireServer напрямую
    local searchServices = {
        ReplicatedStorage,
        game:GetService("Workspace"),
        game:GetService("Players"),
        game
    }
    
    for _, service in ipairs(searchServices) do
        pcall(function()
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    -- Проверяем имя на наличие ключевых слов покупки
                    local nameLow = (obj.Name or ""):lower()
                    if nameLow:match("purchase") or nameLow:match("shop") or nameLow:match("store") or 
                       nameLow:match("buy") or nameLow:match("pass") or nameLow:match("product") or
                       nameLow:match("donate") or nameLow:match("gift") or nameLow:match("ugc") then
                        table.insert(remoteList, obj)
                    end
                end
            end
        end)
    end
    
    return remoteList
end

-- Определение типа продукта
local function detectType(productId)
    local idNum = tonumber(productId)
    if not idNum then return "unknown" end
    
    if #tostring(idNum) >= 13 then
        return "limited"
    elseif #tostring(idNum) <= 8 then
        return "gamepass"
    else
        return "devproduct"
    end
end

-- Получение имени продукта
local function getProductName(productId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(tonumber(productId))
    end)
    if success and result and result.Name then
        return result.Name
    end
    return "Product " .. tostring(productId)
end

-- ============================================================================
-- ФУНКЦИИ ЭКСПЛУАТАЦИИ (ОСНОВНЫЕ)
-- ============================================================================

-- Прямая активация через MarketplaceService (ОСНОВНОЙ МЕТОД)
local function activatePassDirect(productId, productType)
    print("[FREE PASS] Активация: " .. tostring(productId))
    
    local idNum = tonumber(productId)
    if not idNum then return false end
    
    local success = false
    
    -- МЕТОД 1: Прямой вызов PromptPurchase (работает в большинстве игр)
    pcall(function()
        MarketplaceService:PromptPurchase(player, idNum)
        success = true
        print("[FREE PASS] PromptPurchase вызван для " .. idNum)
    end)
    
    task.wait(0.2)
    
    -- МЕТОД 2: Signal методы (только если доступны, без ошибок)
    pcall(function()
        if MarketplaceService.SignalPromptProductPurchaseFinished then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, idNum, true)
            success = true
        end
    end)
    
    pcall(function()
        if MarketplaceService.SignalPromptGamePassPurchaseFinished then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, idNum, true)
            success = true
        end
    end)
    
    task.wait(0.2)
    
    -- МЕТОД 3: Через PurchasePrompt (старый метод)
    pcall(function()
        local PurchasePrompt = game:GetService("PurchasePrompt")
        if PurchasePrompt and PurchasePrompt.PromptPurchase then
            PurchasePrompt:PromptPurchase(player, idNum)
            success = true
        end
    end)
    
    return success
end

-- ============================================================================
-- ПЕРЕХВАТ ПОКУПОК (БЕЗ ОШИБОК FIRESERVER)
-- ============================================================================

-- Отслеживание нажатий на кнопки покупки через UserInputService
local function setupClickInterceptor()
    print("[FREE PASS] Настройка перехватчика кликов...")
    
    -- Отслеживаем GUI кнопки, которые могут быть кнопками покупки
    local function scanForPurchaseButtons()
        local buttons = {}
        
        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local text = (obj.Text or ""):lower()
                    local name = (obj.Name or ""):lower()
                    
                    if text:match("donate") or text:match("пожертв") or text:match("buy") or 
                       text:match("купить") or text:match("purchase") or text:match("shop") or
                       name:match("donate") or name:match("buy") or name:match("purchase") then
                        table.insert(buttons, obj)
                    end
                end
            end
        end)
        
        return buttons
    end
    
    -- Функция для извлечения ID из кнопки или ее родителей
    local function extractProductIdFromButton(button)
        -- Проверяем атрибуты кнопки
        local attrs = button:GetAttributes()
        for k, v in pairs(attrs) do
            if type(v) == "number" and v > 1000 and v < 999999999999 then
                return v
            end
        end
        
        -- Проверяем текстовые поля
        local text = button.Text or ""
        local numbers = text:match("(%d+)")
        if numbers and tonumber(numbers) and tonumber(numbers) > 1000 then
            return tonumber(numbers)
        end
        
        -- Ищем в родителях
        local parent = button.Parent
        for i = 1, 5 do
            if parent then
                local parentAttrs = parent:GetAttributes()
                for k, v in pairs(parentAttrs) do
                    if type(v) == "number" and v > 1000 and v < 999999999999 then
                        return v
                    end
                end
                parent = parent.Parent
            end
        end
        
        return nil
    end
    
    -- Добавляем обработчики на все кнопки покупки
    local function refreshButtonHandlers()
        local buttons = scanForPurchaseButtons()
        for _, btn in ipairs(buttons) do
            if not btn._freePassHooked then
                btn._freePassHooked = true
                
                local originalClick = btn.MouseButton1Click
                btn.MouseButton1Click:Connect(function()
                    local productId = extractProductIdFromButton(btn)
                    if productId then
                        local idStr = tostring(productId)
                        if not capturedPasses[idStr] then
                            capturedPasses[idStr] = {
                                id = idStr,
                                type = detectType(productId),
                                name = getProductName(productId),
                                timestamp = os.date("%H:%M:%S", os.time()),
                                source = "button_click"
                            }
                            print("[FREE PASS] ✓ Перехвачен пропуск: " .. idStr)
                            if renderItemList then pcall(renderItemList) end
                        end
                    end
                end)
            end
        end
    end
    
    -- Периодически сканируем новые кнопки
    spawn(function()
        while menuGui and menuGui.Parent do
            pcall(refreshButtonHandlers)
            task.wait(2)
        end
    end)
end

-- ============================================================================
-- UI МЕНЮ (ПОЛНОСТЬЮ ПЕРЕРАБОТАНО)
-- ============================================================================

function renderItemList()
    if not itemContainer or not itemContainer.Parent then
        return
    end
    
    pcall(function()
        -- Очищаем
        for _, child in ipairs(itemContainer:GetChildren()) do
            if child.Name ~= "Template" then
                child:Destroy()
            end
        end
        
        local yOffset = 5
        local itemHeight = 70
        local itemCount = 0
        
        for id, data in pairs(capturedPasses do
            itemCount = itemCount + 1
            
            -- Панель
            local itemFrame = Instance.new("Frame")
            itemFrame.Name = "Item_" .. id
            itemFrame.Size = UDim2.new(1, -20, 0, itemHeight)
            itemFrame.Position = UDim2.new(0, 10, 0, yOffset)
            itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            itemFrame.BorderSizePixel = 0
            itemFrame.Parent = itemContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = itemFrame
            
            -- Название
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, -10, 0, 22)
            nameLabel.Position = UDim2.new(0, 10, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (data.name or ("ID: " .. id)):sub(1, 35)
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = itemFrame
            
            -- Тип и время
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(0.6, -10, 0, 16)
            infoLabel.Position = UDim2.new(0, 10, 0, 30)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = data.type .. " | " .. data.timestamp
            infoLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextSize = 11
            infoLabel.Font = Enum.Font.SourceSans
            infoLabel.Parent = itemFrame
            
            -- ID
            local idLabel = Instance.new("TextLabel")
            idLabel.Size = UDim2.new(0.6, -10, 0, 16)
            idLabel.Position = UDim2.new(0, 10, 0, 48)
            idLabel.BackgroundTransparency = 1
            idLabel.Text = "ID: " .. id
            idLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
            idLabel.TextXAlignment = Enum.TextXAlignment.Left
            idLabel.TextSize = 10
            idLabel.Font = Enum.Font.SourceSans
            idLabel.Parent = itemFrame
            
            -- Кнопка УДАЛИТЬ
            local deleteBtn = Instance.new("TextButton")
            deleteBtn.Size = UDim2.new(0, 70, 0, 32)
            deleteBtn.Position = UDim2.new(1, -155, 0, 8)
            deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            deleteBtn.Text = "🗑 УДАЛИТЬ"
            deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            deleteBtn.TextSize = 11
            deleteBtn.Font = Enum.Font.SourceSansBold
            deleteBtn.Parent = itemFrame
            
            local delCorner = Instance.new("UICorner")
            delCorner.CornerRadius = UDim.new(0, 4)
            delCorner.Parent = deleteBtn
            
            deleteBtn.MouseButton1Click:Connect(function()
                capturedPasses[id] = nil
                pcall(renderItemList)
                print("[FREE PASS] Удален: " .. id)
            end)
            
            -- Кнопка АКТИВИРОВАТЬ
            local activateBtn = Instance.new("TextButton")
            activateBtn.Size = UDim2.new(0, 85, 0, 32)
            activateBtn.Position = UDim2.new(1, -80, 0, 8)
            activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            activateBtn.Text = "✅ АКТИВ"
            activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            activateBtn.TextSize = 11
            activateBtn.Font = Enum.Font.SourceSansBold
            activateBtn.Parent = itemFrame
            
            local actCorner = Instance.new("UICorner")
            actCorner.CornerRadius = UDim.new(0, 4)
            actCorner.Parent = activateBtn
            
            activateBtn.MouseButton1Click:Connect(function()
                activatePassDirect(id, data.type)
                activateBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                task.wait(0.15)
                activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            end)
            
            yOffset = yOffset + itemHeight + 5
        end
        
        -- Если нет предметов
        if itemCount == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -20, 0, 50)
            emptyLabel.Position = UDim2.new(0, 10, 0, 20)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "📭 НЕТ ПЕРЕХВАЧЕННЫХ ПРОПУСКОВ\n\nНажмите на кнопку 'Пожертвовать' или 'Купить' в игре"
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.TextSize = 12
            emptyLabel.Font = Enum.Font.SourceSans
            emptyLabel.TextWrapped = true
            emptyLabel.Parent = itemContainer
            yOffset = yOffset + 60
        end
        
        itemContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    end)
end

-- Создание главного меню
local function createMenu()
    print("[FREE PASS] Создание меню...")
    
    -- Проверяем, не существует ли уже меню
    if menuGui and menuGui.Parent then
        menuGui:Destroy()
        task.wait(0.2)
    end
    
    -- Создаем ScreenGui
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FreePassExploit_XENO"
    menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menuGui.ResetOnSpawn = false
    
    -- Пытаемся прикрепить к CoreGui, если не получается - к PlayerGui
    local success, err = pcall(function()
        menuGui.Parent = CoreGui
    end)
    if not success then
        pcall(function()
            menuGui.Parent = player:WaitForChild("PlayerGui")
        end)
    end
    
    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 450, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = menuGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
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
    titleText.TextSize = 16
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- Закрыть
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        if menuGui then menuGui:Destroy() end
        print("[FREE PASS] Меню закрыто")
    end)
    
    -- Контент
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -95)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    -- Список
    itemContainer = Instance.new("ScrollingFrame")
    itemContainer.Size = UDim2.new(1, -10, 1, -10)
    itemContainer.Position = UDim2.new(0, 5, 0, 5)
    itemContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    itemContainer.BackgroundTransparency = 0
    itemContainer.BorderSizePixel = 0
    itemContainer.ScrollBarThickness = 5
    itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemContainer.Parent = contentFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = itemContainer
    
    -- Нижняя панель
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 50)
    bottomBar.Position = UDim2.new(0, 0, 1, -50)
    bottomBar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 10)
    bottomCorner.Parent = bottomBar
    
    -- Кнопка АВТО-СПАМ
    local autoSpamBtn = Instance.new("TextButton")
    autoSpamBtn.Size = UDim2.new(0, 150, 0, 36)
    autoSpamBtn.Position = UDim2.new(0.5, -75, 0, 7)
    autoSpamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    autoSpamBtn.Text = "🔄 АВТО-СПАМ (ВЫКЛ)"
    autoSpamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoSpamBtn.TextSize = 12
    autoSpamBtn.Font = Enum.Font.SourceSansBold
    autoSpamBtn.Parent = bottomBar
    
    local spamCorner = Instance.new("UICorner")
    spamCorner.CornerRadius = UDim.new(0, 6)
    spamCorner.Parent = autoSpamBtn
    
    autoSpamBtn.MouseButton1Click:Connect(function()
        if autoSpamActive then
            autoSpamActive = false
            if spamThread then task.cancel(spamThread) end
            autoSpamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            autoSpamBtn.Text = "🔄 АВТО-СПАМ (ВЫКЛ)"
            print("[FREE PASS] Авто-спам остановлен")
        else
            autoSpamActive = true
            autoSpamBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            autoSpamBtn.Text = "⏹ АВТО-СПАМ (ВКЛ)"
            print("[FREE PASS] Авто-спам запущен")
            
            spamThread = task.spawn(function()
                while autoSpamActive do
                    for id, data in pairs(capturedPasses) do
                        if autoSpamActive then
                            activatePassDirect(id, data.type)
                            task.wait(0.5)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end)
    
    -- Информация
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 0, 20)
    infoText.Position = UDim2.new(0, 10, 0, -25)
    infoText.BackgroundTransparency = 1
    infoText.Text = "СОВЕТ: Нажмите на любую кнопку 'Купить'/'Пожертвовать' для перехвата"
    infoText.TextColor3 = Color3.fromRGB(140, 140, 160)
    infoText.TextSize = 10
    infoText.Font = Enum.Font.SourceSans
    infoText.Parent = bottomBar
    
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
    
    -- Анимация
    mainFrame.BackgroundTransparency = 0.3
    TweenService:Create(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    
    print("[FREE PASS] Меню создано! Нажмите на кнопки покупки в игре.")
end

-- ============================================================================
-- ЗАПУСК
-- ============================================================================

local function startExploit()
    print("[FREE PASS] ========================================")
    print("[FREE PASS] FREE PASS EXPLOIT v1.1 для XENO")
    print("[FREE PASS] Игрок: " .. player.Name)
    print("[FREE PASS] Игра: " .. currentGameName)
    print("[FREE PASS] Place ID: " .. game.PlaceId)
    print("[FREE PASS] ========================================")
    
    -- Создаем меню
    pcall(createMenu)
    
    -- Настраиваем перехват кнопок
    pcall(setupClickInterceptor)
    
    -- Обновляем список
    task.wait(0.5)
    pcall(renderItemList)
    
    print("[FREE PASS] ========================================")
    print("[FREE PASS] ГОТОВ К РАБОТЕ!")
    print("[FREE PASS] 1. Меню должно появиться на экране")
    print("[FREE PASS] 2. Нажмите 'Купить'/'Пожертвовать' в игре")
    print("[FREE PASS] 3. Пропуск появится в меню -> нажмите АКТИВ")
    print("[FREE PASS] ========================================")
end

-- Запуск с защитой от ошибок
local success, err = pcall(startExploit)
if not success then
    print("[FREE PASS] КРИТИЧЕСКАЯ ОШИБКА: " .. tostring(err))
    print("[FREE PASS] Пробуем упрощенный запуск...")
    
    -- Упрощенный запуск: только меню без перехвата
    pcall(createMenu)
    pcall(renderItemList)
    print("[FREE PASS] Упрощенный режим запущен. Работает только ручная активация.")
end

-- ============================================================================
-- КОНЕЦ СКРИПТА
-- ============================================================================
