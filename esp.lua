-- ============================================================================
-- FREE PASS EXPLOIT V4 - С FIXED МЕНЮ (INSERT + ПЕРЕТАСКИВАНИЕ)
-- Для XENO | Murder Mystery 2 + любые другие игры
-- ============================================================================

print("\n\n\n\n\n\n\n\n\n\n")
print("═══════════════════════════════════════════════════════════════")
print("     FREE PASS EXPLOIT v4.0 | INSERT to toggle | Drag enabled")
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
local capturedItems = {}
local autoSpamActive = false
local spamThread = nil
local menuGui = nil
local itemContainer = nil
local menuVisible = true  -- меню видимо по умолчанию

print("[✓] Игрок: " .. player.Name)

-- ============================================================================
-- ФУНКЦИИ ПЕРЕТАСКИВАНИЯ (РАБОТАЮТ С ЛЮБОЙ КНОПКОЙ МЫШИ)
-- ============================================================================
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local handle = dragHandle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================================
-- ПОИСК ID ПРЕДМЕТОВ
-- ============================================================================
local function extractItemId(button)
    local text = button.Text or ""
    local name = button.Name or ""
    
    local knownIds = {
        ["475"] = 475, ["500"] = 500, ["400"] = 400, ["539"] = 539,
        ["radio"] = 475, ["Radio"] = 475
    }
    
    for pattern, id in pairs(knownIds) do
        if text:find(pattern) or name:find(pattern) then
            return id
        end
    end
    
    local numbers = text:match("(%d+)")
    if numbers and tonumber(numbers) and tonumber(numbers) > 0 and tonumber(numbers) < 10000 then
        return tonumber(numbers)
    end
    
    for k, v in pairs(button:GetAttributes()) do
        if type(v) == "number" and v > 0 and v < 10000 then
            return v
        end
    end
    
    return nil
end

local function getItemName(id)
    local items = {
        [475] = "📻 Radio 475", [500] = "📻 Radio 500", [400] = "📻 Radio 400",
        [539] = "📻 Radio Premium", [1] = "🔪 Common Knife", [2] = "🔪 Rare Knife",
        [3] = "🔪 Legendary Knife", [4] = "✨ Godly Knife", [5] = "🔫 Common Gun",
        [6] = "🔫 Rare Gun", [7] = "🔫 Legendary Gun", [8] = "✨ Godly Gun",
        [9] = "💃 Emote Dance", [10] = "😆 Emote Laugh",
    }
    return items[id] or ("📦 Item #" .. id)
end

-- ============================================================================
-- АКТИВАЦИЯ ПРЕДМЕТА
-- ============================================================================
local function activateItem(itemId)
    print("[→] Активация ID: " .. itemId)
    
    pcall(function()
        MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, tonumber(itemId), true)
    end)
    pcall(function()
        MarketplaceService:PromptPurchase(player, tonumber(itemId))
    end)
    
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:match("buy") or name:match("purchase") or name:match("give") then
                pcall(function() remote:FireServer(tonumber(itemId), "activate") end)
                pcall(function() remote:FireServer({ItemId = tonumber(itemId), Action = "Grant"}) end)
            end
        end
    end
    
    print("[✓] Активация выполнена")
end

-- ============================================================================
-- ПЕРЕХВАТЧИКИ
-- ============================================================================
local function hookRemotes()
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") and remote:IsA("RemoteEvent") then
            pcall(function()
                local original = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        local id = nil
                        if type(arg) == "number" and arg > 0 and arg < 10000 then id = arg
                        elseif type(arg) == "string" and tonumber(arg) then id = tonumber(arg)
                        elseif type(arg) == "table" then
                            if arg.id then id = arg.id
                            elseif arg.ItemId then id = arg.ItemId end
                        end
                        
                        if id and not capturedItems[tostring(id)] then
                            capturedItems[tostring(id)] = {
                                id = tostring(id), name = getItemName(id),
                                timestamp = os.date("%H:%M:%S")
                            }
                            print("[!] ПЕРЕХВАЧЕН: " .. getItemName(id))
                            pcall(renderItemList)
                        end
                    end
                    return nil
                end
            end)
        end
    end
end

local function hookButtons()
    spawn(function()
        while menuGui and menuGui.Parent do
            pcall(function()
                for _, btn in ipairs(game:GetDescendants()) do
                    if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and not btn._hooked then
                        local text = (btn.Text or ""):lower()
                        if text:match("buy") or text:match("purchase") or text:match("radio") or text:match("%d+") then
                            btn._hooked = true
                            btn.MouseButton1Click:Connect(function()
                                local id = extractItemId(btn)
                                if id and not capturedItems[tostring(id)] then
                                    capturedItems[tostring(id)] = {
                                        id = tostring(id), name = getItemName(id),
                                        timestamp = os.date("%H:%M:%S")
                                    }
                                    print("[!] ПЕРЕХВАЧЕН: " .. getItemName(id))
                                    pcall(renderItemList)
                                end
                            end)
                        end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- ============================================================================
-- UI МЕНЮ (С ПОДДЕРЖКОЙ INSERT И ПЕРЕТАСКИВАНИЕМ)
-- ============================================================================

function renderItemList()
    if not itemContainer or not itemContainer.Parent then return end
    
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
            
            local activateBtn = Instance.new("TextButton")
            activateBtn.Size = UDim2.new(0, 90, 0, 35)
            activateBtn.Position = UDim2.new(1, -100, 0, 12)
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
            emptyLabel.Text = "📭 НЕТ ПЕРЕХВАЧЕННЫХ ПРЕДМЕТОВ\n\nНажмите на кнопку 'BUY' в магазине\nПредмет автоматически перехватится"
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
    end
    
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FreePassExploit"
    menuGui.ResetOnSpawn = false
    
    pcall(function() menuGui.Parent = CoreGui end)
    if not menuGui.Parent then
        pcall(function() menuGui.Parent = player:WaitForChild("PlayerGui") end)
    end
    
    -- ГЛАВНОЕ ОКНО (можно перетаскивать за заголовок)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = menuVisible
    mainFrame.Parent = menuGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- ЗАГОЛОВОК (за него перетаскиваем)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- ПЕРЕТАСКИВАНИЕ - работает за заголовок
    makeDraggable(mainFrame, titleBar)
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎮 FREE PASS EXPLOIT | XENO"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextSize = 14
    titleText.Font = Enum.Font.SourceSansBold
    titleText.Parent = titleBar
    
    -- КНОПКА ЗАКРЫТИЯ (крестик)
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
    
    -- СПИСОК ПРЕДМЕТОВ
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
    
    -- НИЖНЯЯ ПАНЕЛЬ
    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 50)
    bottomBar.Position = UDim2.new(0, 0, 1, -50)
    bottomBar.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = mainFrame
    
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 12)
    bottomCorner.Parent = bottomBar
    
    -- КНОПКА АВТО-СПАМ
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
            print("[✓] Авто-спам остановлен")
        else
            autoSpamActive = true
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
            autoBtn.Text = "⏹ ОСТАНОВИТЬ"
            print("[✓] Авто-спам запущен")
            
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
    
    -- ИНФОСТРОКА
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 0, 18)
    infoLabel.Position = UDim2.new(0, 10, 0, -22)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "💡 INSERT = скрыть/показать | Перетащите за заголовок | Нажмите BUY для перехвата"
    infoLabel.TextColor3 = Color3.fromRGB(120, 130, 160)
    infoLabel.TextSize = 10
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Parent = bottomBar
    
    renderItemList()
    print("[✓] Меню создано! Нажмите INSERT для скрытия/показа")
    
    return mainFrame
end

-- ============================================================================
-- УПРАВЛЕНИЕ ПО КЛАВИШЕ INSERT
-- ============================================================================
local mainFrameReference = nil

local function setupInsertToggle()
    print("[→] Настройка клавиши INSERT для открытия/закрытия меню...")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Код 45 = Insert (на некоторых клавиатурах может быть 0x2D)
        if input.KeyCode == Enum.KeyCode.Insert then
            if menuGui and menuGui.Parent then
                -- Ищем главное окно внутри GUI
                for _, child in ipairs(menuGui:GetChildren()) do
                    if child:IsA("Frame") then
                        menuVisible = not menuVisible
                        child.Visible = menuVisible
                        print("[✓] Меню " .. (menuVisible and "показано" or "скрыто") .. " (INSERT)")
                        break
                    end
                end
            end
        end
    end)
    
    print("[✓] INSERT настроен")
end

-- ============================================================================
-- ЗАПУСК
-- ============================================================================

print("\n[→] Запуск эксплойта...")

pcall(hookRemotes)
pcall(hookButtons)
local mainFrame = pcall(createMenu) and mainFrame or nil
pcall(setupInsertToggle)

print("\n═══════════════════════════════════════════════════════════════")
print("  ✅ ГОТОВО! ФУНКЦИИ:")
print("  ")
print("  🖱 ПЕРЕТАСКИВАНИЕ: зажмите ЛКМ на заголовке и тяните")
print("  ⌨️ INSERT: скрыть/показать меню")
print("  🛒 Нажмите BUY в магазине -> предмет перехватится")
print("  ✅ Нажмите АКТИВ для получения")
print("═══════════════════════════════════════════════════════════════\n")
