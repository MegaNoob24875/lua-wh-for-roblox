-- Подключаем библиотеку Rayfield для красивого меню
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Создаем окно
local Window = Rayfield:CreateWindow({
    Name = "Glow ESP | Anti-Cheat Test",
    LoadingTitle = "Загрузка Advanced ESP...",
    LoadingSubtitle = "by Hyper",
    ConfigurationSaving = {
        Enabled = true,
        FileName = "Hyper_ESP_Config"
    },
    KeySystem = false, -- Ключ не нужен
    ToggleUIKeybind = "K", -- Кнопка показа/скрытия меню
})

-- Вкладка ESP
local MainTab = Window:CreateTab("Настройки ESP", nil)

-- --- Настройки по умолчанию ---
local Settings = {
    Enabled = true,      -- Включен ли ESP
    Color = Color3.fromRGB(255, 0, 0), -- Цвет по умолчанию (Красный)
    Transparency = 0.5,  -- Прозрачность заливки (0 - сочная, 1 - невидимо)
    Outline = true       -- Обводка вкл/выкл
}

-- --- Функция создания свечения (Glow/Chams) ---
-- Эта функция создает эффект Highlight, который виден сквозь стены
local function applyHighlightToPlayer(player)
    -- Не применяем эффект к самому себе, чтобы не мешать обзору
    if player == game.Players.LocalPlayer then return end
    
    -- Ждем, пока у игрока появится персонаж
    local character = player.Character
    if not character then
        player.CharacterAppearanceLoaded:Wait()
        character = player.Character
    end

    -- Создаем объект Highlight (встроенный инструмент Roblox)
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = Settings.Color        -- Цвет заливки
    highlight.FillTransparency = Settings.Transparency -- Прозрачность
    highlight.OutlineTransparency = 0.5         -- Прозрачность контура
    
    -- Режим AlwaysOnTop = видно через стены (как Wallhack) [citation:8]
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Прячем контур, если игрок выключил настройку
    if not Settings.Outline then
        highlight.OutlineTransparency = 1
    end
    
    -- Сохраняем хайлайт в таблицу, чтобы потом удалить или изменить
    _G.Highlights[player] = highlight
end

-- Функция для удаления свечения
local function removeHighlight(player)
    if _G.Highlights[player] then
        _G.Highlights[player]:Destroy()
        _G.Highlights[player] = nil
    end
end

-- --- Обработка подключения новых игроков ---
_G.Highlights = {}

-- Применяем ESP ко всем кто уже в игре
for _, player in pairs(game.Players:GetPlayers()) do
    task.spawn(function() applyHighlightToPlayer(player) end)
end

-- Следим за новыми игроками
game.Players.PlayerAdded:Connect(function(player)
    task.spawn(function() applyHighlightToPlayer(player) end)
end)

-- Следим за выходом игроков (чистим память)
game.Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

-- --- ПОЛНОСТЬЮ НАСТРАИВАЕМЫЙ GUI (Rayfield) ---

-- Переключатель Вкл/Выкл (Master Switch)
MainTab:CreateToggle({
    Name = "Включить ESP (Glow через стены)",
    CurrentValue = true,
    Flag = "ESPToggle",
    Callback = function(Value)
        Settings.Enabled = Value
        -- Проходим по всем хайлайтам и включаем/выключаем видимость
        for player, highlight in pairs(_G.Highlights) do
            if highlight then
                highlight.Enabled = Value
            end
        end
    end
})

-- Выбор цвета (Color Picker)
MainTab:CreateColorPicker({
    Name = "Цвет свечения",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ColorPick",
    Callback = function(Color)
        Settings.Color = Color
        -- Меняем цвет у всех активных хайлайтов в реальном времени
        for player, highlight in pairs(_G.Highlights) do
            if highlight then
                highlight.FillColor = Color
            end
        end
    end
})

-- Ползунок прозрачности
MainTab:CreateSlider({
    Name = "Прозрачность заливки",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "%",
    CurrentValue = 0.5,
    Flag = "TransSlider",
    Callback = function(Value)
        Settings.Transparency = Value
        for player, highlight in pairs(_G.Highlights) do
            if highlight then
                highlight.FillTransparency = Value
            end
        end
    end
})

-- Переключатель обводки (контура)
MainTab:CreateToggle({
    Name = "Показать обводку (Outline)",
    CurrentValue = true,
    Flag = "OutlineToggle",
    Callback = function(Value)
        Settings.Outline = Value
        for player, highlight in pairs(_G.Highlights) do
            if highlight then
                highlight.OutlineTransparency = Value and 0.5 or 1
            end
        end
    end
})

-- Уведомление о запуске
Rayfield:Notify({
    Title = "ESP Активен",
    Content = "Настройки применены. Читы разрешены? Докажи!",
    Duration = 5,
})
