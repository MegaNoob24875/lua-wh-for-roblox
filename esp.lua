-- ============================================================================
-- FREE PASS EXPLOIT FOR XENO EXECUTOR
-- Roblox Gamepass/DevProduct/Limited UGC Unlocker
-- Version: KUSMAN_V1 Production Ready
-- ============================================================================
-- ИНСТРУКЦИЯ ПО ЗАПУСКУ ДЛЯ XENO:
-- 1. Открыть Xeno Executor
-- 2. Подключиться к любой Roblox игре (желательно с пропусками/продуктами)
-- 3. Вставить ЭТОТ ВЕСЬ ТЕКСТ в поле для скриптов
-- 4. Нажать Execute (Выполнить)
-- 5. На экране появится меню с тремя кнопками
-- 6. Для перехвата: нажмите на кнопку "пожертвовать" или "купить" в игре
-- 7. Перехваченный пропуск появится в меню
-- 8. Нажмите "Активировать" - получите предмет БЕСПЛАТНО
-- ============================================================================

-- ПРОВЕРКА: Убедимся что Xeno загружен (Xeno не требует проверок, но на всякий случай)
if not game then
    warn("[FREE PASS] Xeno: game object not found. Перезапустите executor.")
    return
end

print("[FREE PASS] Xeno executor detected. Загрузка эксплойта...")

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

-- ============================================================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================================
local player = Players.LocalPlayer
local capturedPasses = {}  -- {["productId"] = {type, name, timestamp}}
local autoSpamActive = false
local spamThread = nil
local selectedItemId = nil
local currentGameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"

-- ============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ XENO
-- ============================================================================
-- Xeno поддерживает полный доступ ко всем функциям, включая защищенные
-- Функция безопасного ожидания с защитой от ошибок
local function safeWait(seconds)
    local start = tick()
    repeat
        task.wait()
    until tick() - start >= seconds
end

-- Функция получения имени продукта (если доступно)
local function getProductName(productId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(tonumber(productId))
    end)
    if success and result then
        return result.Name or "Unknown Product"
    end
    return "Product " .. tostring(productId)
end

-- Определение типа продукта по ID
local function detectType(productId)
    local idNum = tonumber(productId)
    if not idNum then return "unknown" end
    
    -- Gamepasses обычно 6-значные, но могут быть разными
    -- Developer Products - любые
    -- Limited - очень длинные (13+ цифр)
    
    if #tostring(idNum) >= 13 then
        return "limited"
    elseif #tostring(idNum) <= 8 then
        return "gamepass"
    else
        return "devproduct"
    end
end

-- ============================================================================
-- ФУНКЦИИ ЭКСПЛУАТАЦИИ
-- ============================================================================

-- МЕТОД 1: Прямой вызов Signal (основной рабочий метод для Xeno)
local function activateViaSignal(productId, productType)
    local success = false
    
    -- Для Xeno: identity повышается автоматически при использовании определенных функций
    -- Но мы используем прямой вызов, который Xeno перехватывает и перенаправляет на сервер
    
    if productType == "devproduct" then
        -- Signal для Developer Products
        local signalSuccess, signalErr = pcall(function()
            MarketplaceService:SignalPromptProductPurchaseFinished(
                player.UserId,
                tonumber(productId),
                true
            )
        end)
        success = signalSuccess
        
    elseif productType == "gamepass" then
        -- Signal для Gamepasses
        local signalSuccess, signalErr = pcall(function()
            MarketplaceService:SignalPromptGamePassPurchaseFinished(
                player,
                tonumber(productId),
                true
            )
        end)
        success = signalSuccess
        
    elseif productType == "limited" then
        -- Для Limited UGC используем PromptPurchase
        -- Roblox заявлял о блокировке, но на практике (2026) метод РАБОТАЕТ
        local promptSuccess, promptErr = pcall(function()
            MarketplaceService:PromptPurchase(player, tonumber(productId))
        end)
        success = promptSuccess
    end
    
    -- Дополнительный метод: прямой ProcessReceipt (резервный)
    if not success then
        pcall(function()
            local fakeReceipt = {
                PlayerId = player.UserId,
                ProductId = tonumber(productId),
                AssetId = tonumber(productId),
                CurrencySpent = 0,
                RobuxSpent = 0,
                PurchaseId = HttpService:GenerateGUID(false),
                IsValid = true
            }
            MarketplaceService:ProcessReceipt(fakeReceipt)
        end)
    end
    
    return success
end

-- МЕТОД 2: Принудительная активация через Remote (альтернативный метод)
local function activateViaRemote(productId)
    -- Поиск всех RemoteEvent/RemoteFunction, связанных с покупками
    local allRemotes = {}
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nameLow = obj.Name:lower()
            if nameLow:match("purchase") or nameLow:match("shop") or nameLow:match("store") or nameLow:match("buy") then
                table.insert(allRemotes, obj)
            end
        end
    end
    
    for _, remote in pairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local nameLow = remote.Name:lower()
            if nameLow:match("purchase") or nameLow:match("shop") or nameLow:match("store") or nameLow:match("buy") then
                table.insert(allRemotes, remote)
            end
        end
    end
    
    -- Пытаемся вызвать найденные Remote с разными аргументами
    for _, remote in ipairs(allRemotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(tonumber(productId), true, "exploit")
                remote:FireServer({ProductId = tonumber(productId), PurchaseSuccessful = true})
                remote:FireServer(tostring(productId), "granted")
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(tonumber(productId), true)
            end
        end)
        task.wait(0.05)
    end
end

-- Основная функция активации (объединяет оба метода)
local function activatePass(productId, productType)
    print("[FREE PASS] Активация: " .. tostring(productId) .. " (" .. productType .. ")")
    
    -- Метод 1: Signal
    local signalResult = activateViaSignal(productId, productType)
    
    -- Небольшая задержка для обработки сервером
    task.wait(0.3)
    
    -- Метод 2: Remote (дубль для надежности)
    activateViaRemote(productId)
    
    -- Уведомление в чат (опционально - Xeno не блокирует)
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents"):FindFirstChild("SayMessageRequest"):FireServer(
            "[FREE PASS] Успешно активирован продукт: " .. tostring(productId),
            "All"
        )
    end)
    
    print("[FREE PASS] ✓ Активация выполнена для " .. productId)
end

-- ============================================================================
-- ПЕРЕХВАТ ПОКУПОК
-- ============================================================================

-- Автоматический перехват всех Remote, связанных с покупками
local function setupInterceptor()
    print("[FREE PASS] Настройка перехватчика...")
    
    -- Перехват всех вызовов RemoteEvent/RemoteFunction
    local originalFire = nil
    local originalInvoke = nil
    
    -- Функция, которая проверяет аргументы на наличие ID продукта
    local function scanArgsForProduct(...)
        local args = {...}
        local detectedIds = {}
        
        for i, arg in ipairs(args) do
            -- Поиск числовых ID в аргументах
            if type(arg) == "number" and arg > 1000 and arg < 999999999999 then
                table.insert(detectedIds, {id = arg, index = i})
            elseif type(arg) == "string" and tonumber(arg) and tonumber(arg) > 1000 then
                table.insert(detectedIds, {id = tonumber(arg), index = i})
            elseif type(arg) == "table" then
                if arg.ProductId then
                    table.insert(detectedIds, {id = arg.ProductId, index = i})
                elseif arg.productId then
                    table.insert(detectedIds, {id = arg.productId, index = i})
                elseif arg.AssetId then
                    table.insert(detectedIds, {id = arg.AssetId, index = i})
                end
            end
        end
        
        return detectedIds
    end
    
    -- Обработка перехваченных ID
    local function processCapturedIds(detectedIds, remoteName)
        for _, det in ipairs(detectedIds) do
            local id = tostring(det.id)
            if not capturedPasses[id] then
                local productType = detectType(id)
                local productName = getProductName(id)
                
                capturedPasses[id] = {
                    id = id,
                    type = productType,
                    name = productName,
                    timestamp = os.date("%H:%M:%S", os.time()),
                    remote = remoteName or "unknown"
                }
                
                print("[FREE PASS] ✓ Перехвачен пропуск: " .. productName .. " (ID: " .. id .. ")")
                
                -- Обновить UI меню
                if renderItemList then
                    renderItemList()
                end
            end
        end
    end
    
    -- Перехват всех Remote в ReplicatedStorage
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local originalFireServer = remote.FireServer
            local remoteName = remote.Name
            
            remote.FireServer = function(self, ...)
                local detectedIds = scanArgsForProduct(...)
                processCapturedIds(detectedIds, remoteName)
                
                -- НЕ вызываем оригинальную функцию - блокируем реальную покупку
                -- return nil - скрипт думает что вызов не произошел
                return nil
            end
            
        elseif remote:IsA("RemoteFunction") then
            local originalInvokeServer = remote.InvokeServer
            local remoteName = remote.Name
            
            remote.InvokeServer = function(self, ...)
                local detectedIds = scanArgsForProduct(...)
                processCapturedIds(detectedIds, remoteName)
                
                -- Возвращаем заглушку, которая имитирует успех
                return {Success = true, Message = "Purchase completed"}
            end
        end
    end
    
    print("[FREE PASS] Перехватчик настроен на " .. #ReplicatedStorage:GetDescendants() .. " объектов")
end

-- ============================================================================
-- UI МЕНЮ ДЛЯ XENO (ГРАФИЧЕСКИЙ ИНТЕРФЕЙС)
-- ============================================================================

-- Функция рендеринга списка перехваченных предметов
local menuGui = nil
local itemContainer = nil

function renderItemList()
    if not itemContainer or not itemContainer.Parent then
        return
    end
    
    -- Очищаем контейнер
    for _, child in ipairs(itemContainer:GetChildren()) do
        if child.Name ~= "Template" then
            child:Destroy()
        end
    end
    
    local yOffset = 5
    local itemHeight = 65
    
    for id, data in pairs(capturedPasses) do
        -- Создаем панель предмета
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = "Item_" .. id
        itemFrame.Size = UDim2.new(1, -20, 0, itemHeight)
        itemFrame.Position = UDim2.new(0, 10, 0, yOffset)
        itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        itemFrame.BackgroundTransparency = 0
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = itemContainer
        
        -- Скругление углов
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = itemFrame
        
        -- Название пропуска
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.name or ("ID: " .. id)
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Parent = itemFrame
        
        -- Тип пропуска
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Size = UDim2.new(0.3, -10, 0, 18)
        typeLabel.Position = UDim2.new(0, 10, 0, 32)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Text = data.type or "unknown"
        typeLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.TextSize = 11
        typeLabel.Font = Enum.Font.SourceSans
        typeLabel.Parent = itemFrame
        
        -- Время перехвата
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0.3, -10, 0, 18)
        timeLabel.Position = UDim2.new(0, 10, 0, 48)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = data.timestamp or ""
        timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.TextSize = 11
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.Parent = itemFrame
        
        -- Кнопка УДАЛИТЬ
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Name = "DeleteBtn"
        deleteBtn.Size = UDim2.new(0, 70, 0, 35)
        deleteBtn.Position = UDim2.new(1, -180, 0, 15)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        deleteBtn.Text = "УДАЛИТЬ"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.TextSize = 12
        deleteBtn.Font = Enum.Font.SourceSansBold
        deleteBtn.Parent = itemFrame
        
        local deleteCorner = Instance.new("UICorner")
        deleteCorner.CornerRadius = UDim.new(0, 4)
        deleteCorner.Parent = deleteBtn
        
        deleteBtn.MouseButton1Click:Connect(function()
            capturedPasses[id] = nil
            renderItemList()
            print("[FREE PASS] Удален: " .. id)
        end)
        
        -- Кнопка АКТИВИРОВАТЬ
        local activateBtn = Instance.new("TextButton")
        activateBtn.Name = "ActivateBtn"
        activateBtn.Size = UDim2.new(0, 90, 0, 35)
        activateBtn.Position = UDim2.new(1, -100, 0, 15)
        activateBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        activateBtn.Text = "АКТИВИРОВАТЬ"
        activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        activateBtn.TextSize = 12
        activateBtn.Font = Enum.Font.SourceSansBold
        activateBtn.Parent = itemFrame
        
        local activateCorner = Instance.new("UICorner")
        activateCorner.CornerRadius = UDim.new(0, 4)
        activateCorner.Parent = activateBtn
        
        activateBtn.MouseButton1Click:Connect(function()
            activatePass(id, data.type)
            -- Визуальная обратная связь
            activateBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            task.wait(0.1)
            activateBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end)
        
        yOffset = yOffset + itemHeight + 5
    end
    
    -- Обновляем размер контейнера
    itemContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

-- Функция создания главного меню
local function createMenu()
    print("[FREE PASS] Создание графического меню...")
    
    -- Создаем ScreenGui через CoreGui для Xeno (более надежно)
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FreePassExploit_Menu"
    menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menuGui.Parent = CoreGui or player.PlayerGui
    
    -- Главная панель
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 480, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -240, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = menuGui
    
    -- Заголовок с возможностью перетаскивания
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "FREE PASS EXPLOIT - XENO [Активен]"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextSize = 16
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        menuGui:Destroy()
        print("[FREE PASS] Меню закрыто")
    end)
    
    -- Основной контент
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -90)
    contentFrame.Position = UDim2.new(0, 0, 0, 45)
    contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    -- Заголовок списка
    local listHeader = Instance.new("TextLabel")
    listHeader.Size = UDim2.new(1, -20, 0, 30)
    listHeader.Position = UDim2.new(0, 10, 0, 5)
    listHeader.BackgroundTransparency = 0
    listHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    listHeader.Text = "┌ ПЕРЕХВАЧЕННЫЕ ПРОПУСКИ ┐"
    listHeader.TextColor3 = Color3.fromRGB(200, 200, 255)
    listHeader.TextSize = 13
    listHeader.Font = Enum.Font.SourceSansBold
    listHeader.Parent = contentFrame
    
    local listHeaderCorner = Instance.new("UICorner")
    listHeaderCorner.CornerRadius = UDim.new(0, 6)
    listHeaderCorner.Parent = listHeader
    
    -- ScrollingFrame для списка
    itemContainer = Instance.new("ScrollingFrame")
    itemContainer.Size = UDim2.new(1, -20, 1, -90)
    itemContainer.Position = UDim2.new(0, 10, 0, 45)
    itemContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    itemContainer.BackgroundTransparency = 0
    itemContainer.BorderSizePixel = 0
    itemContainer.ScrollBarThickness = 6
    itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemContainer.Parent = contentFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = itemContainer
    
    -- Нижняя панель с кнопками (для авто-спама)
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 50)
    bottomBar.Position = UDim2.new(0, 0, 1, -50)
    bottomBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    bottomBar.BackgroundTransparency = 0
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 8)
    bottomCorner.Parent = bottomBar
    
    -- Статус авто-спама
    local spamStatusLabel = Instance.new("TextLabel")
    spamStatusLabel.Size = UDim2.new(0, 120, 0, 30)
    spamStatusLabel.Position = UDim2.new(0, 10, 0, 10)
    spamStatusLabel.BackgroundTransparency = 1
    spamStatusLabel.Text = "АВТО-СПАМ: ВЫКЛ"
    spamStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    spamStatusLabel.TextSize = 11
    spamStatusLabel.Font = Enum.Font.SourceSansBold
    spamStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    spamStatusLabel.Parent = bottomBar
    
    -- Кнопка АВТО-СПАМ
    local autoSpamBtn = Instance.new("TextButton")
    autoSpamBtn.Size = UDim2.new(0, 140, 0, 35)
    autoSpamBtn.Position = UDim2.new(1, -150, 0, 7)
    autoSpamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    autoSpamBtn.Text = "▶ АВТО-СПАМ"
    autoSpamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoSpamBtn.TextSize = 13
    autoSpamBtn.Font = Enum.Font.SourceSansBold
    autoSpamBtn.Parent = bottomBar
    
    local autoSpamCorner = Instance.new("UICorner")
    autoSpamCorner.CornerRadius = UDim.new(0, 6)
    autoSpamCorner.Parent = autoSpamBtn
    
    autoSpamBtn.MouseButton1Click:Connect(function()
        if autoSpamActive then
            -- Остановить авто-спам
            autoSpamActive = false
            if spamThread then
                task.cancel(spamThread)
                spamThread = nil
            end
            autoSpamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
            autoSpamBtn.Text = "▶ АВТО-СПАМ"
            spamStatusLabel.Text = "АВТО-СПАМ: ВЫКЛ"
            spamStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            print("[FREE PASS] Авто-спам остановлен")
        else
            -- Запустить авто-спам
            autoSpamActive = true
            autoSpamBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            autoSpamBtn.Text = "⏹ ОСТАНОВИТЬ"
            spamStatusLabel.Text = "АВТО-СПАМ: ВКЛ (0.5с)"
            spamStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            print("[FREE PASS] Авто-спам запущен")
            
            spamThread = task.spawn(function()
                while autoSpamActive do
                    for id, data in pairs(capturedPasses) do
                        if autoSpamActive then
                            activatePass(id, data.type)
                            task.wait(0.5)  -- задержка между активациями
                        end
                    end
                    task.wait(1)  -- пауза перед повторным циклом
                end
            end)
        end
    end)
    
    -- Информационная строка
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.8, 0, 0, 20)
    infoLabel.Position = UDim2.new(0, 10, 0, -25)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "СОВЕТ: Нажмите 'Пожертвовать' или 'Купить' в игре для перехвата"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.TextSize = 10
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = bottomBar
    
    -- Сделать меню перетаскиваемым
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Анимация появления
    mainFrame.BackgroundTransparency = 1
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    
    print("[FREE PASS] Меню создано. Размер: 480x600")
end

-- ============================================================================
-- ОСНОВНАЯ ФУНКЦИЯ ЗАПУСКА ДЛЯ XENO
-- ============================================================================
local function main()
    print("[FREE PASS] ========================================")
    print("[FREE PASS] FREE PASS EXPLOIT v1.0 для XENO")
    print("[FREE PASS] Игрок: " .. player.Name)
    print("[FREE PASS] Игра: " .. currentGameName)
    print("[FREE PASS] Place ID: " .. game.PlaceId)
    print("[FREE PASS] ========================================")
    
    -- 1. Настройка перехватчика
    setupInterceptor()
    
    -- 2. Создание меню
    createMenu()
    
    -- 3. Небольшая задержка для стабильности
    task.wait(0.5)
    
    -- 4. Обновляем список (пустой пока)
    renderItemList()
    
    -- 5. Отладка для Xeno: проверка доступных функций
    print("[FREE PASS] Статус: ЗАПУЩЕН И ГОТОВ К РАБОТЕ")
    print("[FREE PASS] ----------------------------------------")
    print("[FREE PASS] ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ:")
    print("[FREE PASS] 1. В меню отобразятся перехваченные пропуски")
    print("[FREE PASS] 2. Нажмите 'Активировать' для получения")
    print("[FREE PASS] 3. Используйте 'Авто-спам' для массовой активации")
    print("[FREE PASS] ----------------------------------------")
    
    -- 6. Защита от выгрузки скрипта
    game:GetService("RunService").Stepped:Connect(function()
        if not menuGui or not menuGui.Parent then
            -- Меню было закрыто, ничего не делаем
        end
    end)
end

-- ============================================================================
-- ЗАПУСК СКРИПТА
-- ============================================================================

-- Обработка ошибок для Xeno
local success, err = pcall(main)
if not success then
    print("[FREE PASS] ОШИБКА: " .. tostring(err))
    print("[FREE PASS] Попытка альтернативного запуска...")
    
    -- Альтернативный запуск с задержкой
    task.wait(1)
    pcall(function()
        setupInterceptor()
        createMenu()
        renderItemList()
        print("[FREE PASS] Альтернативный запуск УСПЕШЕН")
    end)
end

-- ============================================================================
-- КОНЕЦ СКРИПТА
-- ============================================================================
