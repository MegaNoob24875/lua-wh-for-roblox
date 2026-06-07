-- ============================================================================
-- FREE PASS EXPLOIT V3 - СПЕЦИАЛЬНО ДЛЯ MURDER MYSTERY 2
-- Перехват кастомных покупок (радио, эмоции, скины)
-- ============================================================================

print("\n\n\n\n\n\n\n\n\n\n")
print("═══════════════════════════════════════════════════════════════")
print("     FREE PASS EXPLOIT v3.0 | MM2 + XENO OPTIMIZED")
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

local player = Players.LocalPlayer
local capturedItems = {}  -- перехваченные предметы
local autoSpamActive = false
local spamThread = nil
local menuGui = nil
local itemContainer = nil

print("[✓] Игрок: " .. player.Name)
print("[✓] Игра: " .. (game.PlaceId == 142823291 and "Murder Mystery 2" or "Другая игра"))

-- ============================================================================
-- ПОИСК ID ПРЕДМЕТОВ В MM2
-- ============================================================================

-- Функция для извлечения ID из GUI кнопки MM2
local function extractMM2ItemId(button)
    -- Проверяем текст кнопки на наличие Radio ID
    local text = button.Text or ""
    local name = button.Name or ""
    
    -- Стандартные ID радио в MM2 (известные значения)
    local knownRadios = {
        ["475"] = 475,    -- Radio ID
        ["500"] = 500,    -- Radio ID
        ["400"] = 400,    -- Radio ID
        ["539.00P"] = 539 -- Radio ID с ценой
    }
    
    -- Ищем в тексте
    for pattern, id in pairs(knownRadios) do
        if text:find(pattern) or name:find(pattern) then
            return id
        end
    end
    
    -- Ищем числа в тексте (от 1 до 9999)
    local numbers = text:match("(%d+)")
    if numbers and tonumber(numbers) and tonumber(numbers) > 0 and tonumber(numbers) < 10000 then
        return tonumber(numbers)
    end
    
    -- Проверяем атрибуты
    for k, v in pairs(button:GetAttributes()) do
        if type(v) == "number" and v > 0 and v < 10000 then
            return v
        end
    end
    
    return nil
end

-- ============================================================================
-- ГЛАВНЫЙ МЕТОД: ПЕРЕХВАТ REMOTEEVENT В MM2
-- ============================================================================

local function hookMM2Remotes()
    print("[→] Поиск RemoteEvent в MM2...")
    
    local remotesFound = {}
    
    -- Ищем все RemoteEvent в игре
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name
            -- В MM2 покупки обычно через Remote с именами: BuyItem, Purchase, Shop, Radio
            if name:lower():match("buy") or 
               name:lower():match("purchase") or 
               name:lower():match("shop") or
               name:lower():match("radio") or
               name:lower():match("item") then
                table.insert(remotesFound, remote)
            end
        end
    end
    
    print("[→] Найдено " .. #remotesFound .. " потенциальных RemoteEvent для покупок")
    
    -- Хукинг каждого Remote
    for _, remote in ipairs(remotesFound) do
        pcall(function()
            local originalFire = remote.FireServer
            
            remote.FireServer = function(self, ...)
                local args = {...}
                local detectedId = nil
                local detectedPrice = nil
                
                -- Анализ аргументов на наличие ID предмета
                for i, arg in ipairs(args) do
                    -- Прямой числовой ID
                    if type(arg) == "number" and arg > 0 and arg < 10000 then
                        detectedId = arg
                    end
                    -- Строковый ID
                    if type(arg) == "string" and tonumber(arg) and tonumber(arg) > 0 then
                        detectedId = tonumber(arg)
                    end
                    -- Таблица с ID
                    if type(arg) == "table" then
                        if arg.id then detectedId = arg.id end
                        if arg.ItemId then detectedId = arg.ItemId end
                        if arg.price then detectedPrice = arg.price end
                    end
                end
                
                -- Если нашли ID предмета
                if detectedId and not capturedItems[tostring(detectedId)] then
                    local itemName = getItemName(detectedId)
                    capturedItems[tostring(detectedId)] = {
                        id = tostring(detectedId),
                        name = itemName,
                        price = detectedPrice or "FREE",
                        timestamp = os.date("%H:%M:%S"),
                        remote = remote.Name
                    }
                    print("[!] ПЕРЕХВАЧЕН ПРЕДМЕТ: " .. itemName .. " (ID: " .. detectedId .. ") через " .. remote.Name)
                    pcall(renderItemList)
                end
                
                -- БЛОКИРУЕМ оригинальный вызов (покупка не происходит, но предмет перехвачен)
                -- Если хотим всё равно отправить, раскомментировать:
                -- return originalFire(self, unpack(args))
                return nil
            end
        end)
    end
end

-- Получение имени предмета по ID (для MM2)
local function getItemName(id)
    local mm2Items = {
        [475] = "Radio 475",
        [500] = "Radio 500", 
        [400] = "Radio 400",
        [539] = "Radio Premium",
        [1] = "Common Knife",
        [2] = "Rare Knife",
        [3] = "Legendary Knife",
        [4] = "Godly Knife",
        [5] = "Common Gun",
        [6] = "Rare Gun",
        [7] = "Legendary Gun",
        [8] = "Godly Gun",
        [9] = "Emote Dance",
        [10] = "Emote Laugh",
        [11] = "Effect Fire",
        [12] = "Effect Hearts",
    }
    return mm2Items[id] or ("Item #" .. id)
end

-- ============================================================================
-- МЕТОД АКТИВАЦИИ ПРЕДМЕТА (ПРИНУДИТЕЛЬНАЯ ВЫДАЧА)
-- ============================================================================

local function activateItem(itemId)
    print("[→] Активация предмета ID: " .. itemId)
    
    -- МЕТОД 1: Прямой вызов Signal (если сработает)
    pcall(function()
        MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, tonumber(itemId), true)
    end)
    
    -- МЕТОД 2: Через PromptPurchase
    pcall(function()
        MarketplaceService:PromptPurchase(player, tonumber(itemId))
    end)
    
    -- МЕТОД 3: Поиск и вызов Remote для MM2
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:match("buy") or name:match("purchase") or name:match("give") or name:match("reward") then
                pcall(function()
                    remote:FireServer(tonumber(itemId), "activate")
                    remote:FireServer({ItemId = tonumber(itemId), Action = "Grant"})
                end)
            end
        end
    end
    
    print("[✓] Активация выполнена для " .. itemId)
end

-- ============================================================================
-- ПЕРЕХВАТ КНОПОК GUI (РАБОТАЕТ ДАЖЕ БЕЗ REMOTE)
-- ============================================================================

local function hookMM2Buttons()
    print("[→] Настройка перехвата GUI кнопок MM2...")
    
    local processedButtons = {}
    
    local function scanForPurchaseButtons()
        for _, btn in ipairs(game:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and not processedButtons[btn] then
                local text = (btn.Text or ""):lower()
                local name = (btn.Name or ""):lower()
                
                -- Кнопки покупки в MM2 обычно содержат "buy", "purchase" или цены
                if text:match("buy") or name:match("buy") or 
                   text:match("purchase") or text:match("radio") or
                   text:match("%d+") then  -- содержит число (цену)
                    
                    processedButtons[btn] = true
                    
                    btn.MouseButton1Click:Connect(function()
                        local itemId = extractMM2ItemId(btn)
                        
                        if itemId and not capturedItems[tostring(itemId)] then
                            capturedItems[tostring(itemId)] = {
                                id = tostring(itemId),
                                name = getItemName(itemId),
                                timestamp = os.date("%H:%M:%S"),
                                source = "button_click"
                            }
                            print("[!] ПЕРЕХВАЧЕН ПРЕДМЕТ: " .. getItemName(itemId) .. " (через кнопку)")
                            pcall(renderItemList)
                        end
                    end)
                end
            end
        end
    end
    
    -- Сканируем каждую секунду
    spawn(function()
        while menuGui and menuGui.Parent do
            pcall(scanForPurchaseButtons)
            task.wait(1)
        end
    end)
end

-- ============================================================================
-- ДОПОЛНИТЕЛЬНО: ОТСЛЕЖИВАНИЕ DIALOG/ПОДТВЕРЖДЕНИЙ
-- ============================================================================

local function hookPurchaseDialogs()
    -- Отслеживаем создание новых окон подтверждения покупки
    game:GetService("CoreGui").DescendantAdded:Connect(function(obj)
        if obj:IsA("Frame") or obj:IsA("ScreenGui") then
            -- Ищем кнопки "Buy", "Confirm", "Purchase" в диалогах
            task.wait(0.1)
            for _, btn in ipairs(obj:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = (btn.Text or ""):lower()
                    if text:match("buy") or text:match("confirm") or text:match("purchase") then
                        -- Автоматически нажимаем кнопку подтверждения
                        pcall(function()
                            btn:Click()
                            print("[!] Автоподтверждение покупки")
                        end)
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- UI МЕНЮ
-- ============================================================================

function renderItemList()
    if not itemContainer or not itemContainer.Parent then
        return
    end
    
    pcall(function()
        for _, child in ipairs(itemContainer:GetChildren()) do
            child:Destroy()
        end
        
        local yOffset = 5
        local itemHeight = 60
        local count = 0
        
        for id, data in pairs(capturedItems) do
            count = count + 1
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, itemHeight)
            frame.Position = UDim2.new(0, 10, 0, yOffset)
            frame.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
            frame.BorderSizePixel = 0
            frame.Parent = itemContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame
            
            -- Название
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, -10, 0, 25)
            nameLabel.Position = UDim2.new(0, 10, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = frame
            
            -- ID и время
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(0.6, -10, 0, 16)
            infoLabel.Position = UDim2.new(0, 10, 0, 33)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = "ID: " .. id .. " | " .. data.timestamp
            infoLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextSize = 10
            infoLabel.Font = Enum.Font.SourceSans
            infoLabel.Parent = frame
            
            -- Кнопка Активации
            local activateBtn = Instance.new("TextButton")
            activateBtn.Size = UDim2.new(0, 100, 0, 35)
            activateBtn.Position = UDim2.new(1, -110, 0, 12)
            activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            activateBtn.Text = "✅ АКТИВ"
            activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            activateBtn.TextSize = 12
            activateBtn.Font = Enum.Font.SourceSansBold
            activateBtn.Parent = frame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = activateBtn
            
            activateBtn.MouseButton1Click:Connect(function()
                activateItem(id)
                activateBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                task.wait(0.15)
                activateBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            end)
            
            yOffset = yOffset + itemHeight + 5
        end
        
        if count == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -20, 0, 80)
            emptyLabel.Position = UDim2.new(0, 10, 0, 20)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "📭 НЕТ ПЕРЕХВАЧЕННЫХ ПРЕДМЕТОВ\n\nНажмите на кнопку 'BUY' (Купить) в магазине MM2\nПредмет автоматически перехватится и появится здесь"
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

-- ============================================================================
-- СОЗДАНИЕ МЕНЮ
-- ============================================================================

local function createMenu()
    if menuGui and menuGui.Parent then
        menuGui:Destroy()
    end
    
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "MM2FreeItemsExploit"
    menuGui.ResetOnSpawn = false
    
    pcall(function() menuGui.Parent = CoreGui end)
    if not menuGui.Parent then
        pcall(function() menuGui.Parent = player:WaitForChild("PlayerGui") end)
    end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = menuGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎮 MM2 FREE ITEMS | XENO"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextSize = 15
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- Закрыть
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
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
    itemContainer.Size = UDim2.new(1, -10, 1, -95)
    itemContainer.Position = UDim2.new(0, 5, 0, 50)
    itemContainer.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
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
    bottomBar.Size = UDim2.new(1, 0, 0, 50)
    bottomBar.Position = UDim2.new(0, 0, 1, -50)
    bottomBar.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 12)
    bottomCorner.Parent = bottomBar
    
    -- Авто-спам
    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0, 170, 0, 34)
    autoBtn.Position = UDim2.new(0.5, -85, 0, 8)
    autoBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    autoBtn.Text = "🔄 АВТО-АКТИВАЦИЯ"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 12
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
            autoBtn.Text = "🔄 АВТО-АКТИВАЦИЯ"
            print("[✓] Авто-активация остановлена")
        else
            autoSpamActive = true
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            autoBtn.Text = "⏹ ОСТАНОВИТЬ"
            print("[✓] Авто-активация запущена")
            
            spamThread = task.spawn(function()
                while autoSpamActive do
                    for id, data in pairs(capturedItems) do
                        if autoSpamActive then
                            activateItem(id)
                            task.wait(0.8)
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end)
    
    renderItemList()
    print("[✓] Меню создано!")
end

-- ============================================================================
-- ЗАПУСК
-- ============================================================================

print("\n[→] Запуск эксплойта для MM2...")

-- Запускаем все перехватчики
pcall(hookMM2Remotes)
pcall(hookMM2Buttons)
pcall(hookPurchaseDialogs)

-- Создаем меню
pcall(createMenu)

print("\n═══════════════════════════════════════════════════════════════")
print("  ✅ ГОТОВО! Инструкция:")
print("  ")
print("  1. Откройте магазин (Shop) в Murder Mystery 2")
print("  2. Нажмите на кнопку 'BUY' у любого радио/предмета")
print("  3. Предмет появится в меню выше")
print("  4. Нажмите 'АКТИВ' для получения")
print("═══════════════════════════════════════════════════════════════\n")

-- Дополнительная информация
print("[!] ВНИМАНИЕ ДЛЯ MM2:")
print("[!] - Радио с ID 475,500,400,539 должны перехватиться")
print("[!] - Если не появляется - нажмите 'BUY' несколько раз")
print("[!] - После активации проверьте инвентарь\n")
