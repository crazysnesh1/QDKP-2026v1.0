-- QDKP2_Config_Sync.lua
-- Функции для объединённой синхронизации списков внешних игроков и альтов

local MAX_DISPLAY_NAMES = 5

-- Вспомогательная функция для форматирования списка имён
local function GetItemizedList(names, prefix)
    if #names == 0 then return "" end
    local list = ""
    for i = 1, #names do
        if i > 1 then list = list .. "\n" end
        list = list .. prefix .. names[i]
    end
    return list
end

-- Кастомное окно с прокруткой для больших логов синхронизации
local function ShowScrollableConfirm(message, onAccept, onCancel)
    -- Создаем фрейм только один раз
    if not QDKP2_SyncConfirmFrame then
        local f = CreateFrame("Frame", "QDKP2_SyncConfirmFrame", UIParent)
        f:SetSize(450, 400) -- Размер окна
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        
        -- Стандартный фон диалоговых окон WoW
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        -- Заголовок
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -18)
        title:SetText("Подтверждение синхронизации")

        -- Скролл-фрейм
        local scrollFrame = CreateFrame("ScrollFrame", "QDKP2_SyncScrollFrame", f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 20, -45)
        scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)

        -- Контейнер внутри скролл-фрейма
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(370, 10) 
        scrollFrame:SetScrollChild(scrollChild)

        -- Текст сообщения
        local textFs = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        textFs:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -5)
        textFs:SetWidth(370) -- Ограничиваем ширину для переноса строк
        textFs:SetJustifyH("LEFT")
        textFs:SetJustifyV("TOP")
        
        f.textFs = textFs
        f.scrollChild = scrollChild

        -- Кнопка "Принять"
        local btnAccept = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btnAccept:SetSize(120, 22)
        btnAccept:SetPoint("BOTTOMLEFT", 60, 20)
        btnAccept:SetText("Принять")
        btnAccept:SetScript("OnClick", function()
            f:Hide()
            if f.onAccept then f.onAccept() end
        end)

        -- Кнопка "Отмена"
        local btnCancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btnCancel:SetSize(120, 22)
        btnCancel:SetPoint("BOTTOMRIGHT", -60, 20)
        btnCancel:SetText("Отмена")
        btnCancel:SetScript("OnClick", function()
            f:Hide()
            if f.onCancel then f.onCancel() end
        end)
    end

    local f = QDKP2_SyncConfirmFrame
    f.textFs:SetText(message)
    
    -- Динамически подгоняем высоту контента для правильной работы ползунка
    f.scrollChild:SetHeight(f.textFs:GetStringHeight() + 20)
    
    f.onAccept = onAccept
    f.onCancel = onCancel
    f:Show()
end

-- Отправка объединённых данных (экстерналы + альты)
function QDKP2_Config:SendSyncData(target)
    if not target then return end
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end

    local data = {
        type = QDKP2_Config.CommTypes.SYNC,
        data = {
            externals = QDKP2externals,  -- текущий список внешних
            alts = QDKP2alts,            -- текущий список альтов
            altsRestore = QDKP2altsRestore
        },
        version = QDKP2_Config.CommVersion
    }
    local text = self:Serialize(data)
    local distribution = (target == 'GUILD') and 'GUILD' or 'WHISPER'
    
    self:SendCommMessage("QDKP2ConfPro", text, distribution, target, "BULK")
    QDKP2_Msg("Синхронизация (внешние + альты) отправлена игроку " .. target)
end

-- Обработка полученного пакета синхронизации
function QDKP2_Config:HandleSyncData(data, distribution, sender)
    QDKP2_Debug(1, "Config", "HandleSyncData from " .. sender)
    
    local externals = data.externals
    local alts = data.alts
    local altsRestore = data.altsRestore or {}
    
    -- Проверяем права: импорт разрешён только офицерам
    if not QDKP2_OfficerMode() then
        QDKP2_Msg("У вас нет прав на импорт списков", "ERROR")
        return
    end
    
    -- Анализируем изменения
    local oldExternals = {}
    for k,v in pairs(QDKP2externals) do oldExternals[k] = v end
    local newExternals = externals or {}
    
    local oldAlts = {}
    for k,v in pairs(QDKP2alts) do oldAlts[k] = v end
    local newAlts = alts or {}
    
    -- Списки добавлений и удалений
    local addedExternals = {}
    for name in pairs(newExternals) do
        if not oldExternals[name] then
            table.insert(addedExternals, name)
        end
    end
    local removedExternals = {}
    for name in pairs(oldExternals) do
        if not newExternals[name] then
            table.insert(removedExternals, name)
        end
    end
    
    local addedAlts = {}
    for alt, main in pairs(newAlts) do
        if not oldAlts[alt] then
            table.insert(addedAlts, alt .. " -> " .. main)
        end
    end
    local removedAlts = {}
    for alt in pairs(oldAlts) do
        if not newAlts[alt] then
            table.insert(removedAlts, alt)
        end
    end
    
    -- Формируем сообщение с изменениями
    local message = "Получены данные синхронизации от " .. sender .. "\n\n"
    local hasChanges = false
    
    if #addedExternals > 0 then
        hasChanges = true
        message = message .. "Будет ДОБАВЛЕНО внешних: " .. #addedExternals .. "\n"
        message = message .. GetItemizedList(addedExternals, "  ") .. "\n\n"
    end
    if #removedExternals > 0 then
        hasChanges = true
        message = message .. "Будет УДАЛЕНО внешних: " .. #removedExternals .. "\n"
        message = message .. GetItemizedList(removedExternals, "  ") .. "\n\n"
    end
    if #addedAlts > 0 then
        hasChanges = true
        message = message .. "Будет ДОБАВЛЕНО связей альт-мейн: " .. #addedAlts .. "\n"
        message = message .. GetItemizedList(addedAlts, "  ") .. "\n\n"
    end
    if #removedAlts > 0 then
        hasChanges = true
        message = message .. "Будет УДАЛЕНО связей альт-мейн: " .. #removedAlts .. "\n"
        message = message .. GetItemizedList(removedAlts, "  ") .. "\n\n"
    end
    
    if not hasChanges then
        QDKP2_Msg("Нет изменений в полученных списках", "INFO")
        return
    end
    
    -- Запрос подтверждения
    ShowScrollableConfirm(message,
        function()
            -- Применяем изменения
            -- Внешние
            for name in pairs(oldExternals) do
                if not newExternals[name] then
                    QDKP2_DelExternal(name, true)
                end
            end
            for name, data in pairs(newExternals) do
                if not oldExternals[name] then
                    QDKP2_NewExternal(name, data.datafield or "")
                end
            end
            -- Альты
            for alt in pairs(oldAlts) do
                if not newAlts[alt] then
                    QDKP2_ClearAlt(alt)
                end
            end
            for alt, main in pairs(newAlts) do
                if not oldAlts[alt] then
                    QDKP2_MakeAlt(alt, main, true)  -- true = без подтверждения
                end
            end
            
            -- Обновляем GUI
            QDKP2_DownloadGuild()
            QDKP2_RefreshAll()
            
            -- Сохраняем данные
            if QDKP2_UpdateDatabase then QDKP2_UpdateDatabase() end
            if QDKP2_SaveData then QDKP2_SaveData() end
            
            QDKP2_Msg("Синхронизация завершена: списки внешних и альтов обновлены", "SUCCESS")
        end,
        function()
            QDKP2_Msg("Импорт синхронизации отменён")
        end
    )
end