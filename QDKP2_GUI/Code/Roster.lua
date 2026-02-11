-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--                   ## GUI ##
--                     Roster
--


------------ Class Initialization and defaults -------------

local myClass = {}

-- Функция для форматирования списка игроков для диалога
local function FormatPlayerList(players, maxDisplay)
    maxDisplay = maxDisplay or 10 -- максимальное количество отображаемых имен
    local displayPlayers = {}
    
    for i = 1, math.min(#players, maxDisplay) do
        table.insert(displayPlayers, "• " .. players[i])
    end
    
    local result = table.concat(displayPlayers, "\n")
    
    if #players > maxDisplay then
        result = result .. "\n\n... и еще " .. (#players - maxDisplay) .. " игроков"
    end
    
    return result
end

-- Initialize all tables FIRST
myClass.ColumnWidth = {
    deltatotal = 40,
    deltaspent = 40,
    hours = 45,
    roll = 40,
    bid = 55,
    value = 50,
    officer = 140,
    role = 120  -- НОВАЯ КОЛОНКА ДЛЯ РОЛЕЙ
}

myClass.Sort = {
    Order = "Alpha",
    LastLen = 0,
    Values = {},
    Reverse = {}
}

myClass.Offset = 0
myClass.Sel = "guild"
myClass.ENTRIES = 20
myClass.LINES_ON_SCROLL = 10
myClass.SelectedPlayers = {}
myClass.LastClickIndex = 1
myClass.EntryName = "QDKP2_frame2_entry"

myClass.PlayersColor = {
    Default = { r = 1, g = 1, b = 1 },
    Modified = { r = 0.27, g = 0.92, b = 1 },
    Standby = { r = 1, g = 0.7, b = 0 },
    Alt = { r = 1, g = 0.3, b = 1 },
    External = { r = 0.4, g = 1, b = 0.4 },
    NoClass = { r = 0.5, g = 0.5, b = 0.5 },
    NoGuild = { r = 0.5, g = 0.5, b = 0.5 }
}

myClass.ShowAlts = true
myClass.SearchText = ""
myClass.SearchByMain = false
myClass.SearchBox = nil

-- Настройки ролей
myClass.RoleBonusConfig = {
    BIS = { name = "БИС", color = { r = 1, g = 0.84, b = 0 } },
    TANK_HEAL = { name = "ТАНК/ХИЛ", color = { r = 0, g = 0.8, b = 1 } },
    BIS_TANK_HEAL = { name = "БИС ТАНК/ХИЛ", color = { r = 0, g = 1, b = 0 } }
}
myClass.RolePriority = {
    BIS_TANK_HEAL = 1, -- Самый высокий приоритет
    TANK_HEAL = 2,     -- Ниже чем БисТанкХил
    BIS = 3            -- Ниже всех
}

myClass.PlayerRoles = {} -- таблица для хранения ролей игроков
myClass.officerNoteCache = {} -- кеш для заметок игроков

-- Sort values
myClass.Sort.Values.BidValue = 2048
myClass.Sort.Values.BidText = 1024
myClass.Sort.Values.BidRoll = 512
myClass.Sort.Values.Alpha = 256
myClass.Sort.Values.Rank = 128
myClass.Sort.Values.Class = 64
myClass.Sort.Values.Officer = 48
myClass.Sort.Values.Net = 32
myClass.Sort.Values.Total = 16
myClass.Sort.Values.Spent = 8
myClass.Sort.Values.Hours = 4
myClass.Sort.Values.SessGain = 2
myClass.Sort.Values.SessSpent = 1
myClass.Sort.Values.Role = 96  -- НОВАЯ СОРТИРОВКА ПО РОЛЕЙ

myClass.Sort.Reverse.BidValue = true
myClass.Sort.Reverse.BidText = true
myClass.Sort.Reverse.BidRoll = true
myClass.Sort.Reverse.Alpha = false
myClass.Sort.Reverse.Rank = false
myClass.Sort.Reverse.Class = false
myClass.Sort.Reverse.Officer = false
myClass.Sort.Reverse.Net = true
myClass.Sort.Reverse.Total = true
myClass.Sort.Reverse.Spent = true
myClass.Sort.Reverse.Hours = true
myClass.Sort.Reverse.SessGain = true
myClass.Sort.Reverse.SessSpent = true
myClass.Sort.Reverse.Role = false  -- ДЛЯ РОЛЕЙ

-- Локализация для кнопки исключения из гильдии
QDKP2_LOC_GUIREMOVEFROMGUILD = "Исключить из гильдии"
QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_SINGLE = "Вы уверены, что хотите исключить игрока %s из гильдии?"
QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_MULTI = "Вы уверены, что хотите исключить следующих игроков из гильдии?\n\n%s\n\nВсего: %d игроков"

-------------------- Window management ----------------------

function myClass.OnLoad(self)
    self.Frame = QDKP2_Frame2
    self.MenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.Frame, "UIDropDownMenuTemplate")
    self.SubMenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.MenuFrame, "UIDropDownMenuTemplate")
    
    -- Загружаем сохраненные роли
    self:LoadRoles()
    
    -- Загружаем сохраненные заметки
    self:LoadNotesCache()
    
    -- Создаем UI элементы
    self:CreateSearchUI()
    self:CreateRoleUI()
    self:CreateNonGuildUI()
	self:CreateICCTimerButtons()
    self:CreateNotesButton() -- ПРОСТАЯ КНОПКА ДЛЯ ЗАМЕТОК
    
    -- Регистрируем события для сохранения
    self:RegisterEvents()
    
    QDKP2_Debug(2, "GUI-Roster", "Roster loaded successfully. Roles loaded: " .. tostring(self:CountRoles()))
end

function myClass.CreateSearchUI(self)
    -- Создаем поле поиска
    self.SearchBox = CreateFrame("EditBox", "QDKP2_Frame2_SearchBox", self.Frame, "InputBoxTemplate")
    self.SearchBox:SetSize(120, 20)
    self.SearchBox:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 13, -8)
    self.SearchBox:SetAutoFocus(false)
    self.SearchBox:SetScript("OnTextChanged", function(self)
        QDKP2GUI_Roster:OnSearchTextChanged()
    end)
    self.SearchBox:SetScript("OnEscapePressed", function(self)
        QDKP2GUI_Roster:ClearSearch()
        self:ClearFocus()
    end)
    self.SearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    -- Добавляем placeholder текст
    self.SearchBox:SetText("Поиск...")
    self.SearchBox:SetTextColor(0.5, 0.5, 0.5)
    self.SearchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Поиск..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end)
    self.SearchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Поиск...")
            self:SetTextColor(0.5, 0.5, 0.5)
        end
    end)
end

-- Создаем интерфейс для управления ролями (ЗЕЛЕНЫЙ)
function myClass.CreateRoleUI(self)
    self.RoleButton = CreateFrame("Button", "QDKP2_Frame2_RoleButton", self.Frame, "UIPanelButtonTemplate")
    self.RoleButton:SetSize(50, 25) 
    self.RoleButton:SetPoint("LEFT", "QDKP2_Frame2_SortBtn_role", "RIGHT", 0, 0)
    self.RoleButton:SetText("Назн.") 
    
    -- Функция для яркой покраски
    local function PaintGreen(btn)
        for _, tex in pairs({btn:GetRegions()}) do
            if tex:GetObjectType() == "Texture" then
                tex:SetVertexColor(0.3, 1, 0.3) 
            end
        end
    end

    PaintGreen(self.RoleButton)
    
    local sortBtnRole = _G["QDKP2_Frame2_SortBtn_role"]
    if sortBtnRole then PaintGreen(sortBtnRole) end

    -- ОБНОВЛЕННЫЙ СКРИПТ КЛИКА
    self.RoleButton:SetScript("OnClick", function() 
        if QDKP2_OfficerMode and QDKP2_OfficerMode() then
            self:ShowRoleMenu() 
        else
            -- Сообщение в чат, если не офицер
            QDKP2_Msg("Вы не офицер.")
        end
    end)

    -- ДОБАВЛЕНО: Тултип при наведении
    self.RoleButton:SetScript("OnEnter", function(btn)
        if not (QDKP2_OfficerMode and QDKP2_OfficerMode()) then
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cFFFF0000Вы не офицер|r")
            GameTooltip:AddLine("Доступ к назначению ролей ограничен.", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    
    self.RoleButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.RoleMenuFrame = CreateFrame("Frame", "QDKP2_RoleMenuFrame", UIParent, "UIDropDownMenuTemplate")
end

-- Создаем кнопку для обновления заметок (СИНИЙ)
function myClass.CreateNotesButton(self)
    self.NotesButton = CreateFrame("Button", "QDKP2_Frame2_NotesButton", self.Frame, "UIPanelButtonTemplate")
    self.NotesButton:SetSize(42, 25)
    self.NotesButton:SetPoint("LEFT", "QDKP2_Frame2_SortBtn_officer", "RIGHT", 0, 0)
    self.NotesButton:SetText("«Up»") 
    
	-- Функция для яркой покраски
    local function PaintBlue(btn)
        for _, tex in pairs({btn:GetRegions()}) do
            if tex:GetObjectType() == "Texture" then
                -- Увеличиваем интенсивность синего и добавляем немного белого для яркости
                tex:SetVertexColor(0.4, 0.7, 1) 
            end
        end
    end

    PaintBlue(self.NotesButton)

    local sortBtnNotes = _G["QDKP2_Frame2_SortBtn_officer"]
    if sortBtnNotes then PaintBlue(sortBtnNotes) end

    self.NotesButton:SetScript("OnClick", function() self:RefreshNotesCache() end)
end

-- Создаем интерфейс кнопки "Пуги"
function myClass.CreateNonGuildUI(self)
    if not self.SearchBox then return end
    
    self.NonGuildButton = CreateFrame("Button", "QDKP2_Frame2_NonGuildButton", self.Frame, "UIPanelButtonTemplate")
    self.NonGuildButton:SetSize(45, 22)
    self.NonGuildButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 10, 0) 
    self.NonGuildButton:SetText("Пуги")
    
    -- Теперь кнопка сразу вызывает анонс без открытия меню
    self.NonGuildButton:SetScript("OnClick", function() 
        self:ShowNonGuildMenu() 
    end)
    
    -- Применяем рамку (если функция ApplyThinBorder создана в коде выше)
    if ApplyThinBorder then
        ApplyThinBorder(self.NonGuildButton, 1, 0.5, 0)
    end
end

function myClass.ShowNonGuildMenu(self)
    -- Проверяем наличие пугов
    if not QDKP2_NonGuildMembers or #QDKP2_NonGuildMembers == 0 then
        QDKP2_Msg("В рейде нет Пугов.")
        return
    end

    -- 1. Определяем канал (RW или RAID)
    local channel = "RAID"
    if UnitInRaid("player") then
        if IsRaidLeader() or IsRaidOfficer() then
            channel = "RAID_WARNING"
        else
            channel = "RAID"
        end
    elseif UnitInParty("player") then
        channel = "PARTY"
    else
        QDKP2_Msg("Вы не в группе/рейде для анонса.")
        return
    end

    -- 2. Разбивка сообщения (лимит чата ~255 символов)
    local header = "Пуги в рейде: "
    local currentMsg = header
    local maxLength = 240 -- Оставляем запас под системные данные чата

    for i, name in ipairs(QDKP2_NonGuildMembers) do
        -- Если добавление имени превысит лимит, отправляем текущее и начинаем новое
        if string.len(currentMsg .. name .. ", ") > maxLength then
            SendChatMessage(currentMsg, channel)
            currentMsg = "Пуги (продолжение): " .. name .. ", "
        else
            currentMsg = currentMsg .. name .. ", "
        end
    end

    -- Убираем лишнюю запятую в конце и отправляем последний кусок
    currentMsg = currentMsg:gsub(", $", "")
    SendChatMessage(currentMsg, channel)
end

-- Вспомогательная функция для обработки строк макроса
local function RunAsMacro(text)
    if not text or text == "" then return end
    local chatFrame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
    local editBox = _G[chatFrame:GetName().."EditBox"]
    editBox:SetText(text)
    ChatEdit_SendText(editBox)
end

function myClass.CreateICCTimerButtons(self)
    if not self.NonGuildButton then return end

    -- Внутренняя функция для проверки прав
    local function CanUseButtons()
        local isOfficer = QDKP2_OfficerMode and QDKP2_OfficerMode()
        -- Проверка на лидера или ассистента рейда
        local isLeader = IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()
        return isOfficer and isLeader
    end

    -- Кнопка "С КВ"
    self.WithQuestButton = CreateFrame("Button", "QDKP2_Btn_WithQuest", self.Frame, "UIPanelButtonTemplate")
    self.WithQuestButton:SetSize(50, 22)
    self.WithQuestButton:SetPoint("LEFT", self.NonGuildButton, "RIGHT", 25, 0)
    self.WithQuestButton:SetText("|cFF00FF00С КВ|r")
    
    self.WithQuestButton:SetScript("OnClick", function()
        if CanUseButtons() then
            if QDKP2_ICCTimers and QDKP2_ICCTimers.WithQuest then
                for _, line in ipairs(QDKP2_ICCTimers.WithQuest) do
                    RunAsMacro(line)
                end
            else
                print("|cFFFF0000QDKP2 Error:|r ICCTimers.lua not found or empty!")
            end
        end
    end)

    -- Кнопка "Без КВ"
    self.NoQuestButton = CreateFrame("Button", "QDKP2_Btn_NoQuest", self.Frame, "UIPanelButtonTemplate")
    self.NoQuestButton:SetSize(50, 22)
    self.NoQuestButton:SetPoint("LEFT", self.WithQuestButton, "RIGHT", 1, 0)
    self.NoQuestButton:SetText("|cFF00FF00Без КВ|r")
    
    self.NoQuestButton:SetScript("OnClick", function()
        if CanUseButtons() then
            if QDKP2_ICCTimers and QDKP2_ICCTimers.NoQuest then
                for _, line in ipairs(QDKP2_ICCTimers.NoQuest) do
                    RunAsMacro(line)
                end
            else
                print("|cFFFF0000QDKP2 Error:|r ICCTimers.lua not found or empty!")
            end
        end
    end)

    -- Функция управления видимостью
    local function UpdateVisibility()
        -- 1. Мы на вкладке рейда?
        local isRaidTab = (self.Sel == "raid")
        
        -- 2. Мы вообще в группе или рейде?
        local inGroup = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
        
        -- 3. Проверка прав офицера гильдии (через встроенную функцию QDKP2)
        local isOfficer = QDKP2_OfficerMode and QDKP2_OfficerMode()
        
        -- 4. Есть ли права Лидера или Ассистента (для таймеров)
        local isLeader = IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()

        -- Логика для кнопки "Пуги"
        -- Показываем если: Вкладка Рейд И в группе И Офицер ГИ
        if self.NonGuildButton then
            if isRaidTab and inGroup and isOfficer then
                self.NonGuildButton:Show()
            else
                self.NonGuildButton:Hide()
            end
        end

        -- Логика для таймеров (С КВ / Без КВ)
        -- Показываем если: Вкладка Рейд И Офицер ГИ И есть права Лидера/Ассиста
        if isRaidTab and isOfficer and isLeader then
            self.WithQuestButton:Show()
            self.NoQuestButton:Show()
        else
            self.WithQuestButton:Hide()
            self.NoQuestButton:Hide()
        end
    end

    -- Привязываем проверку к событиям
    self.Frame:HookScript("OnShow", UpdateVisibility)
    hooksecurefunc(self, "Refresh", UpdateVisibility)
end

-- Функция регистрации событий
function myClass.RegisterEvents(self)
    -- Событие выхода из игры
    self.Frame:RegisterEvent("PLAYER_LOGOUT")
    
    -- Обработчик событий
    self.Frame:SetScript("OnEvent", function(frame, event, ...)
        if event == "PLAYER_LOGOUT" then
            self:SaveRoles()
            self:SaveNotesCache()
            QDKP2_Debug(2, "Roster", "Роли и заметки сохранены при выходе из игры")
        end
    end)
end

-- ФУНКЦИЯ ОБНОВЛЕНИЯ КЭША ЗАМЕТОК
function myClass.RefreshNotesCache(self)
    if not self.List or #self.List == 0 then
        QDKP2_Msg("Список игроков пуст")
        return
    end
    
    QDKP2_Msg("Обновляю заметки...")
    
    -- Обновляем данные гильдии
    QDKP2_DownloadGuild()
    
    local totalMembers = QDKP2_GetNumGuildMembers(true)
    local updatedCount = 0
    
    -- Создаем таблицу для быстрого поиска игроков из списка
    local listLookup = {}
    for _, name in ipairs(self.List) do
        listLookup[name] = true
    end
    
    -- Загружаем заметки только для игроков в текущем списке
    for i = 1, totalMembers do
        local name, _, _, _, _, _, note = QDKP2_GetGuildRosterInfo(i)
        if name and listLookup[name] then
            if note and note ~= "" then
                self.officerNoteCache[name] = note
                updatedCount = updatedCount + 1
            else
                -- Если заметка пустая, удаляем из кэша
                self.officerNoteCache[name] = nil
            end
        end
    end
    
    -- Сохраняем кэш
    self:SaveNotesCache()
    
    -- Обновляем отображение
    self:Refresh()
    
    QDKP2_Msg(string.format("Заметки обновлены: %d игроков", updatedCount))
end

-- ЗАГРУЗКА КЭША ЗАМЕТОК
function myClass.LoadNotesCache(self)
    -- Используем глобальную переменную, объявленную в TOC
    QDKP2_NotesCacheDB = QDKP2_NotesCacheDB or {}
    
    -- Загружаем заметки из сохраненной базы данных
    self.officerNoteCache = {}
    for playerName, note in pairs(QDKP2_NotesCacheDB) do
        self.officerNoteCache[playerName] = note
    end
    
    QDKP2_Debug(2, "Notes", "Кеш заметок загружен. Записей: " .. tostring(self:CountNotes()))
end

-- СОХРАНЕНИЕ КЭША ЗАМЕТОК
function myClass.SaveNotesCache(self)
    -- Сохраняем заметки в глобальную переменную
    QDKP2_NotesCacheDB = {}
    for playerName, note in pairs(self.officerNoteCache) do
        QDKP2_NotesCacheDB[playerName] = note
    end
    
    QDKP2_Debug(2, "Notes", "Кеш заметок сохранен. Записей: " .. tostring(self:CountNotes()))
end

-- ПОДСЧЕТ ЗАМЕТОК В КЭШЕ
function myClass.CountNotes(self)
    local count = 0
    if self.officerNoteCache then
        for _ in pairs(self.officerNoteCache) do
            count = count + 1
        end
    end
    return count
end

-- Функция для показа меню ролей
function myClass.ShowRoleMenu(self)
    local menu = {
        { text = "Назначение ролей", isTitle = true },
        { text = "БИС", 
          func = function() 
              self:AssignRoleToSelected("BIS") 
          end },
        { text = "ТАНК/ХИЛ", 
          func = function() 
              self:AssignRoleToSelected("TANK_HEAL") 
          end },
        { text = "БИС ТАНК/ХИЛ", 
          func = function() 
              self:AssignRoleToSelected("BIS_TANK_HEAL") 
          end },
        { text = "Сохранить роли", 
          func = function() 
              self:SaveRoles()
              QDKP2_Msg("Роли сохранены") 
          end },
        { text = "Сбросить роль", 
          func = function() 
              self:AssignRoleToSelected("NONE") 
          end },
        { text = "Сбросить все роли", 
          func = function() 
              self:ResetAllRoles() 
          end },
        { text = "" },
        { text = "Закрыть", 
          func = function() 
              CloseDropDownMenus() 
          end }
    }
    
    EasyMenu(menu, self.RoleMenuFrame, "cursor", 0, 0, "MENU")
end

-- Функция назначения роли выбранным игрокам (обновленная)
function myClass.AssignRoleToSelected(self, role)
    if not self.SelectedPlayers or #self.SelectedPlayers == 0 then
        QDKP2_Msg("Не выбраны игроки для назначения роли")
        return
    end
    
    for _, playerName in ipairs(self.SelectedPlayers) do
        if role == "NONE" then
            self.PlayerRoles[playerName] = nil
            QDKP2_Debug(2, "Roles", "Сброшена роль для: " .. playerName)
        else
            self.PlayerRoles[playerName] = role
            local roleName = self.RoleBonusConfig[role].name
            QDKP2_Debug(2, "Roles", "Назначена роль '" .. roleName .. "' для: " .. playerName)
        end
    end
    
    -- Автосохранение при изменении ролей
    self:SaveRoles()
    
    self:Refresh()
    QDKP2_Msg("Роли обновлены для выбранных игроков")
end

-- Функция сохранения ролей
function myClass.SaveRoles(self)
    -- Сохраняем роли в глобальную переменную для сохранения между сессиями
    QDKP2_RosterRolesDB = QDKP2_RosterRolesDB or {}
    
    -- Копируем текущие роли в базу данных
    for playerName, role in pairs(self.PlayerRoles) do
        QDKP2_RosterRolesDB[playerName] = role
    end
    
    -- Удаляем записи для игроков, у которых сброшены роли
    for playerName, _ in pairs(QDKP2_RosterRolesDB) do
        if not self.PlayerRoles[playerName] then
            QDKP2_RosterRolesDB[playerName] = nil
        end
    end
    
    QDKP2_Debug(2, "Roles", "Роли сохранены. Всего записей: " .. tostring(self:CountRoles()))
end

-- Функция загрузки ролей
function myClass.LoadRoles(self)
    if not QDKP2_RosterRolesDB then
        QDKP2_RosterRolesDB = {}
        QDKP2_Debug(2, "Roles", "База данных ролей инициализирована")
        return
    end
    
    -- Загружаем роли из сохраненной базы данных
    self.PlayerRoles = {}
    for playerName, role in pairs(QDKP2_RosterRolesDB) do
        self.PlayerRoles[playerName] = role
    end
    
    QDKP2_Debug(2, "Roles", "Роли загружены. Всего записей: " .. tostring(self:CountRoles()))
end

-- Функция сброса всех ролей при закрытии сессии
function myClass.ResetRolesOnSessionClose(self)
    if self.PlayerRoles then
        local roleCount = 0
        for _ in pairs(self.PlayerRoles) do
            roleCount = roleCount + 1
        end
        table.wipe(self.PlayerRoles)
        QDKP2_Debug(2, "Roles", "Роли сброшены при закрытии сессии. Сброшено: " .. roleCount .. " ролей")
        return true
    end
    return false
end

-- Функция подсчета ролей
function myClass.CountRoles(self)
    local count = 0
    if self.PlayerRoles then
        for _ in pairs(self.PlayerRoles) do
            count = count + 1
        end
    end
    return count
end

-- Функция сброса всех ролей (обновленная)
function myClass.ResetAllRoles(self)
    table.wipe(self.PlayerRoles)
    -- Также очищаем сохраненную базу
    if QDKP2_RosterRolesDB then
        table.wipe(QDKP2_RosterRolesDB)
    end
    self:Refresh()
    QDKP2_Msg("Все роли сброшены")
end

-- Функция получения названия роли игрока
function myClass.GetPlayerRole(self, playerName)
    return self.PlayerRoles[playerName]
end

-- Функция получения отображаемого названия роли
function myClass.GetPlayerRoleDisplay(self, playerName)
    local role = self.PlayerRoles[playerName]
    if role and self.RoleBonusConfig[role] then
        return self.RoleBonusConfig[role].name
    end
    return ""
end

-- Функция получения цвета роли
function myClass.GetPlayerRoleColor(self, playerName)
    local role = self.PlayerRoles[playerName]
    if role and self.RoleBonusConfig[role] then
        return self.RoleBonusConfig[role].color
    end
    return { r = 1, g = 1, b = 1 } -- белый по умолчанию
end

function myClass.Show(self)
    QDKP2_Toggle(2, true)
    QDKP2GUI_Roster:Refresh()
end

function myClass.Hide(self)
    QDKP2_Frame2:Hide()
    myClass.SelectNone()
end

function myClass.Toggle(self)
    if QDKP2_Frame2:IsVisible() then
        self.Hide()
    else
        self.Show()
    end
end

-- Функция проверки прав для исключения из гильдии
local function CanRemoveFromGuild()
    if not CanGuildRemove then
        QDKP2_Debug(2, "Roster", "Функция CanGuildRemove не найдена, проверка прав пропущена")
        return true -- Если функция не существует, предполагаем что права есть
    end
    
    if not CanGuildRemove() then
        QDKP2_Msg(QDKP2_COLOR_RED .. "У вас недостаточно прав для исключения из гильдии")
        return false
    end
    return true
end

-- Функция для исключения игроков из гильдии
local function RemoveFromGuild(players)
    if not players or #players == 0 then return end
    
    -- Проверяем права
    if not CanRemoveFromGuild() then return end
    
    local removedCount = 0
    local removedNames = {}
    
    for _, name in ipairs(players) do
        if QDKP2_IsInGuild(name) then
            if name == UnitName("player") then
                QDKP2_Msg(QDKP2_COLOR_RED .. "Нельзя исключить себя из гильдии!")
            else
                GuildUninvite(name)
                removedCount = removedCount + 1
                table.insert(removedNames, name)
                QDKP2_Debug(2, "Roster", "Исключен игрок: " .. name)
            end
        end
    end
    
    if removedCount > 0 then
        local message = string.format("Исключено игроков: %d\n%s", removedCount, FormatPlayerList(removedNames, 5))
        QDKP2_Msg(QDKP2_COLOR_GREEN .. message)
    end
end

-- Диалоги подтверждения исключения из гильдии
StaticPopupDialogs["QDKP2_REMOVE_FROM_GUILD_SINGLE"] = {
    text = QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_SINGLE,
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        RemoveFromGuild(data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["QDKP2_REMOVE_FROM_GUILD_MULTI"] = {
    text = "", -- будем устанавливать динамически
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        -- ИСПРАВЛЕНИЕ: передаем именно список игроков, который лежит в data.players
        if data and data.players then
            RemoveFromGuild(data.players)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        if data and data.players then
            local playerList = FormatPlayerList(data.players)
            self.text:SetText(string.format(QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_MULTI, playerList, #data.players))
            self:SetHeight(self.text:GetHeight() + 100) -- динамическая высота
        end
    end,
}

function myClass.Refresh(self, forceResort)
    if not QDKP2_Frame2:IsVisible() then
        return ;
    end
    QDKP2_Debug(3, "GUI-roster", "Refreshing")
    
    local Complete = QDKP2_OfficerMode()
    if Complete then
        QDKP2_frame2_showRaid:Hide()
        QDKP2frame2_selectList_Bid:Show()
    else
        QDKP2_frame2_showRaid:Show()
        QDKP2frame2_selectList_Bid:Hide()
    end
    QDKP2frame2_selectList_guild:SetChecked(false)
    QDKP2frame2_selectList_guildOnline:SetChecked(false)
    QDKP2frame2_selectList_Raid:SetChecked(false)
    QDKP2frame2_selectList_Bid:SetChecked(false)

    myClass:PupulateList()
    
    -- ПРИМЕНЯЕМ ФИЛЬТР ПОИСКА
    local originalList = self.List
    self.List = self:ApplySearchFilter()

    if self.Sel == "guildonline" or self.Sel == "guild" then
        myClass:ShowColumn('deltatotal', false)
        myClass:ShowColumn('deltaspent', false)
        myClass:ShowColumn('roll', false)
        myClass:ShowColumn('bid', false)
        myClass:ShowColumn('value', false)
        myClass:ShowColumn('officer', true)
        myClass:ShowColumn('role', true)  -- ПОКАЗЫВАЕМ КОЛОНКУ РОЛЕЙ
        QDKP2_Frame2_sesscount:Hide()
        QDKP2_Frame2_SessionZone:Hide()
        QDKP2_Frame2_bidcount:Hide()
        QDKP2_Frame2_BiddingZone:Hide()
        QDKP2_Frame2_Bid_Item:Hide()
        QDKP2_Frame2_Bid_Button:Hide()
        QDKP2_Frame2_Bid_ButtonWin:Hide()
        QDKP2_Frame2_NonGuildButton:Hide()
        if self.Sel == 'guild' then
            QDKP2frame2_selectList_guild:SetChecked(true)
        else
            QDKP2frame2_selectList_guildOnline:SetChecked(true)
        end
    elseif self.Sel == "raid" then
        myClass:ShowColumn('deltatotal', true)
        myClass:ShowColumn('deltaspent', true)
        myClass:ShowColumn('roll', false)
        myClass:ShowColumn('bid', false)
        myClass:ShowColumn('value', false)
        myClass:ShowColumn('officer', true)
        myClass:ShowColumn('role', true)  -- ПОКАЗЫВАЕМ КОЛОНКУ РОЛЕЙ
        QDKP2_Frame2_sesscount:Show()
        QDKP2_Frame2_SessionZone:Show()
        QDKP2_Frame2_bidcount:Hide()
        QDKP2_Frame2_BiddingZone:Hide()
        QDKP2_Frame2_Bid_Item:Hide()
        QDKP2_Frame2_Bid_Button:Hide()
        QDKP2_Frame2_Bid_ButtonWin:Hide()
        QDKP2_Frame2_NonGuildButton:Show()
        QDKP2frame2_selectList_Raid:SetChecked(true)
    elseif self.Sel == "bid" then
        myClass:ShowColumn('deltatotal', true)
        myClass:ShowColumn('deltaspent', true)
        myClass:ShowColumn('roll', true)
        myClass:ShowColumn('bid', true)
        myClass:ShowColumn('value', true)
        myClass:ShowColumn('officer', true)
        myClass:ShowColumn('role', true)  -- ПОКАЗЫВАЕМ КОЛОНКУ РОЛЕЙ
        QDKP2_Frame2_sesscount:Show()
        QDKP2_Frame2_SessionZone:Show()
        QDKP2_Frame2_bidcount:Show()
        QDKP2_Frame2_BiddingZone:Show()
        QDKP2_Frame2_Bid_Item:Show()
        QDKP2_Frame2_Bid_Button:Show()
        QDKP2_Frame2_Bid_ButtonWin:Show()
        QDKP2_Frame2_NonGuildButton:Hide()
        if QDKP2_BidM_isBidding() then
            QDKP2_Frame2_Bid_Button:SetText(QDKP2_LOC_GUICANCELBID)
        else
            QDKP2_Frame2_Bid_Button:SetText(QDKP2_LOC_GUISTARTBID)
        end
        if QDKP2_BidM_isBidding() and myClass.SelectedPlayers and #myClass.SelectedPlayers == 1 and QDKP2_BidM.LIST[myClass.SelectedPlayers[1]] then
            QDKP2_Frame2_Bid_ButtonWin:Enable()
        else
            QDKP2_Frame2_Bid_ButtonWin:Disable()
        end
        QDKP2frame2_selectList_Bid:SetChecked(true)
    end

    if QDKP2_StoreHours then
        myClass:ShowColumn('hours', true)
    else
        myClass:ShowColumn('hours', false)
    end

	-- Форсируем сортировку, если включены фильтры (чужаки, поиск или скрытие альтов)
	if ((self.Sel == 'raid' or self.Sel == 'bid') and QDKP2GUI_Vars.ShowOutGuild) 
	   or not self.ShowAlts 
	   or (self.SearchText and self.SearchText ~= "" and self.SearchText ~= "Поиск...") then
		forceResort = true;
	end
    self:SortList(nil, nil, forceResort)

    -- ДОБАВЛЯЕМ СЧЕТЧИК ИГРОКОВ В ЗАГОЛОВОК С УЧЕТОМ ПОИСКА
    local displayCount = tostring(#self.List)
    local totalCount = tostring(#originalList)
    
    -- Обновляем заголовок окна с информацией о поиске
    if self.SearchText and self.SearchText ~= "" and self.SearchText ~= "Поиск..." then
        if self.Sel == 'guild' then
            QDKP2_Frame2_Header:SetText("Гильдия - " .. displayCount .. "/" .. totalCount)
        elseif self.Sel == 'guildonline' then
            QDKP2_Frame2_Header:SetText("Онлайн - " .. displayCount .. "/" .. totalCount)
        elseif self.Sel == 'raid' then
            QDKP2_Frame2_Header:SetText("Рейд - " .. displayCount .. "/" .. totalCount)
        elseif self.Sel == 'bid' then
            QDKP2_Frame2_Header:SetText("Ставки - " .. displayCount .. "/" .. totalCount)
        end
    else
        -- оригинальный заголовок без информации о поиске
        if self.Sel == 'guild' then
            QDKP2_Frame2_Header:SetText("Гильдия - " .. displayCount)
        elseif self.Sel == 'guildonline' then
            QDKP2_Frame2_Header:SetText("Онлайн - " .. displayCount)
        elseif self.Sel == 'raid' then
            QDKP2_Frame2_Header:SetText("Рейд - " .. displayCount)
        elseif self.Sel == 'bid' then
            QDKP2_Frame2_Header:SetText("Ставки - " .. displayCount)
        end
    end

    if self.Offset > #self.List then
        self.Offset = #self.List - 1;
    end
    if self.Offset < 0 then
        self.Offset = 0;
    end

    for i = 1, QDKP2GUI_Roster.ENTRIES do
        --fills in the list data
        local indexAt = self.Offset + i
        local ParentName = "QDKP2_frame2_entry" .. tostring(i)
        if indexAt <= #self.List then
            local name = self.List[indexAt]
            local class = QDKP2class[name] or UnitClass(name)
            local isinguild = QDKP2_IsInGuild(name)
            local colors = myClass.PlayersColor.Default
            if not isinguild then
                colors = myClass.PlayersColor.NoGuild
            elseif QDKP2_USE_CLASS_BASED_COLORS then
                colors = QDKP2_GetClassColor(class)
            else
                if QDKP2_IsModified(name) then
                    colors = myClass.PlayersColor.Modified
                elseif QDKP2_IsStandby(name) then
                    colors = myClass.PlayersColor.Standby
                elseif QDKP2_IsAlt(name) then
                    colors = myClass.PlayersColor.Alt
                elseif QDKP2_IsExternal(name) then
                    colors = myClass.PlayersColor.External
                else
                end
            end
            local r, g, b, a = colors.r, colors.g, colors.b, 1
            local DKP_Ast = ""
            if QDKP2_USE_CLASS_BASED_COLORS and QDKP2_IsModified(name) then
                DKP_Ast = "*";
            end
            if self.Sel == 'raid' and QDKP2_IsRemoved(name) then
                a = 0.4;
            end

            -- ДОБАВЛЯЕМ ОТОБРАЖЕНИЕ РОЛИ
            local roleDisplay = self:GetPlayerRoleDisplay(name)
            local roleColor = self:GetPlayerRoleColor(name)

            --Setting fields color
            getglobal(ParentName .. "_name"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_roll"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_bid"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_value"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_rank"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_role"):SetVertexColor(roleColor.r, roleColor.g, roleColor.b, a)  -- ЦВЕТ ДЛЯ РОЛИ
            local classColor = colors
            if not QDKP2_USE_CLASS_BASED_COLORS then
                classColor = QDKP2_GetClassColor(class)
            end
            getglobal(ParentName .. "_class"):SetVertexColor(classColor.r, classColor.g, classColor.b, a)
            getglobal(ParentName .. "_officer"):SetVertexColor(r, g, b, a)
            if isinguild and QDKP2_GetNet(name) < 0 then
                getglobal(ParentName .. "_net"):SetVertexColor(1, 0.2, 0.2)
            else
                getglobal(ParentName .. "_net"):SetVertexColor(r, g, b, a)
            end
            getglobal(ParentName .. "_total"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_spent"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_hours"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_deltatotal"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_deltaspent"):SetVertexColor(r, g, b, a)

            --Setting content
            local nameS, roll, bid, value, rank, officerNote, net, total, spent, hours, s_gain, s_spent
            nameS = QDKP2_GetName(name) or 'Unknown'
            if self.Sel == 'bid' then
                local BidEntry = QDKP2_BidM_GetBidder(name) or {}
                roll = BidEntry.roll
                bid = BidEntry.txt
                value = BidEntry.value
            else
                roll = '';
                bid = '';
                value = ''
            end
            rank = QDKP2rank[name]
            
            -- ПОЛУЧАЕМ ГИЛЬДЕЙСКУЮ ЗАМЕТКУ ИЗ КЭША
            officerNote = self.officerNoteCache[name] or ''
            
            if class == "Death Knight" then
                class = "DK";
            end
            if isinguild then
                net = QDKP2_GetNet(name)
                total = QDKP2_GetTotal(name)
                spent = QDKP2_GetSpent(name)
                if QDKP2_StoreHours then
                    hours = tostring(QDKP2_GetHours(name)) .. DKP_Ast
                else
                    hours = ''
                end
                if self.Sel == "raid" or self.Sel == "bid" then
                    s_gain, s_spent = QDKP2_GetSessionAmounts(name)
                else
                    s_gain = '';
                    s_spent = ''
                end
            else
                net = '-';
                total = '-';
                spent = '-';
                hours = '';
                s_gain = '';
                s_spent = ''
            end
            getglobal(ParentName .. "_name"):SetText(tostring(nameS));
            getglobal(ParentName .. "_roll"):SetText(tostring(roll or '-'))
            getglobal(ParentName .. "_bid"):SetText(tostring(bid or '-'))
            getglobal(ParentName .. "_value"):SetText(tostring(value or '-'))
            getglobal(ParentName .. "_rank"):SetText(tostring(rank or '-'));
            getglobal(ParentName .. "_class"):SetText(tostring(class or '-'));
            getglobal(ParentName .. "_officer"):SetText(tostring(officerNote));
            getglobal(ParentName .. "_role"):SetText(tostring(roleDisplay));  -- ВЫВОДИМ РОЛЬ
            getglobal(ParentName .. "_net"):SetText(tostring(net or '-') .. DKP_Ast);
            getglobal(ParentName .. "_total"):SetText(tostring(total or '-') .. DKP_Ast);
            getglobal(ParentName .. "_spent"):SetText(tostring(spent or '-') .. DKP_Ast);
            getglobal(ParentName .. "_hours"):SetText(tostring(hours or '-'));
            getglobal(ParentName .. "_deltatotal"):SetText(tostring(s_gain or '-'));
            getglobal(ParentName .. "_deltaspent"):SetText(tostring(s_spent or '-'));

            if self:isSelectedPlayer(name) then
                getglobal(ParentName .. "_Highlight"):Show()
            else
                getglobal(ParentName .. "_Highlight"):Hide()
            end
            getglobal(ParentName):Show();
        else
            getglobal(ParentName):Hide();
        end
    end

    local numEntries = QDKP2GUI_Roster.ENTRIES
    if #self.List < numEntries then
        numEntries = #self.List;
    end
    FauxScrollFrame_Update(QDKP2_frame2_scrollbar, #self.List, numEntries, 16);
end

-- ОБНОВЛЕННАЯ ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ ГИЛЬДЕЙСКОЙ ЗАМЕТКИ
function myClass.GetOfficerNote(self, name)
    -- Возвращаем заметку только из кэша
    if not name then return "" end
    return self.officerNoteCache[name] or ""
end

function myClass.Update(self)
    QDKP2_DownloadGuild()
    QDKP2_UpdateRaid()
    QDKP2_RefreshAll()
    GuildRoster()
end

function myClass.PupulateList(self)
    if self.Sel == 'guild' then
        if not self.ShowAlts then
            self.List = {}
            for i, name in pairs(QDKP2name) do
                if not QDKP2_IsAlt(name) then  -- показываем только не-альтов
                    table.insert(self.List, name)
                end
            end
        else
            self.List = QDKP2name
        end
        QDKP2frame2_selectList_guild:SetChecked(true)
    elseif self.Sel == 'guildonline' then
        self.List = {}
        for i, name in pairs(QDKP2name) do
            if QDKP2online[name] and not QDKP2_IsExternal(name) then
                if self.ShowAlts or not QDKP2_IsAlt(name) then  -- фильтр для онлайн
                    table.insert(self.List, name)
                end
            end
        end
    elseif self.Sel == 'raid' then
        if QDKP2GUI_Vars.ShowOutGuild then
            local list = {}
            for i = 1, QDKP2_GetNumRaidMembers() do
                local name = QDKP2_GetRaidRosterInfo(i)
                table.insert(list, name)
            end
            self.List = list
        else
            self.List = QDKP2raid
        end
    elseif self.Sel == 'bid' then
        self.List = QDKP2_CopyTable(QDKP2_BidM_GetBidderList())
        if not QDKP2GUI_Vars.ShowOutGuild then
            for i, name in pairs(self.List) do
                if not QDKP2_IsInGuild(name) then
                    table.remove(self.List, i);
                end
            end
        end
    end
    QDKP2_Debug(2, "GUI-Roster", "List populated. Voices=" .. tostring(#self.List))
end

function myClass.ApplySearchFilter(self)
    if not self.SearchText or self.SearchText == "" or self.SearchText == "Поиск..." then
        return self.List
    end
    
    local filteredList = {}
    local searchTextLower = string.lower(self.SearchText)
    
    for i, name in pairs(self.List) do
        local found = false
        
        -- Проверяем текущее имя персонажа
        local displayName = QDKP2_GetName(name) or name
        local displayNameLower = string.lower(displayName)
        
        if string.find(displayNameLower, searchTextLower, 1, true) then
            found = true
        end
        
        -- Если включен поиск по мейну, проверяем основного персонажа
        if not found and self.SearchByMain then
            local mainName = QDKP2_GetMain(name)
            if mainName then
                local mainNameLower = string.lower(mainName)
                if string.find(mainNameLower, searchTextLower, 1, true) then
                    found = true
                end
            end
        end
        
        if found then
            table.insert(filteredList, name)
        end
    end
    
    return filteredList
end

function myClass.OnSearchTextChanged(self)
    if self.SearchBox then
        local text = self.SearchBox:GetText()
        if text == "Поиск..." then
            self.SearchText = ""
        else
            self.SearchText = text
        end
        self:Refresh(true)
    end
end

function myClass.ClearSearch(self)
    self.SearchText = ""
    if self.SearchBox then
        self.SearchBox:SetText("Поиск...")
        self.SearchBox:SetTextColor(0.5, 0.5, 0.5)
    end
    self.SearchByMain = false
    self:Refresh(true)
end

function myClass.ShowColumn(self, Column, todo)
    local width = myClass.ColumnWidth[Column]
    local expand, reduce
    
    -- ИСПРАВЛЕНИЕ: Правильно получаем объект кнопки сортировки
    local SortButton = getglobal("QDKP2_Frame2_SortBtn_" .. Column)
    if SortButton and SortButton:IsVisible() and not todo then
        QDKP2_Debug(3, "GUI-Roster", "Hiding column " .. tostring(Column))
        reduce = true
    elseif SortButton and not SortButton:IsVisible() and todo then
        QDKP2_Debug(3, "GUI-Roster", "showing column " .. tostring(Column))
        expand = true
    end

    if Column == "role" and self.RoleButton then
        if todo then
            self.RoleButton:Show()
        else
            self.RoleButton:Hide()
        end
    end
	
    if Column == "officer" and self.NotesButton then
        if todo then
            self.NotesButton:Show()
        else
            self.NotesButton:Hide()
        end
    end
    for i = 1, QDKP2GUI_Roster.ENTRIES do
        local ParentName = "QDKP2_frame2_entry" .. tostring(i)
        local ColObj = getglobal(ParentName .. '_' .. Column)
        if todo then
            --ColObj:Show()
            ColObj:SetWidth(width + 1)
        else
            --ColObj:Hide()
            ColObj:SetWidth(0)
        end
        local RowObj = getglobal(ParentName)
        if reduce then
            RowObj:SetWidth(RowObj:GetWidth() - (width))
        elseif expand then
            RowObj:SetWidth(RowObj:GetWidth() + (width))
        end
    end
    
    local TitleColObj = getglobal("QDKP2_frame2_title_" .. Column)
    if todo then
        --TitleColObj:Show()
        TitleColObj:SetWidth(width + 1)
        if SortButton then
            SortButton:Show()
        end
    else
        --TitleColObj:Hide()
        TitleColObj:SetWidth(0)
        if SortButton then
            SortButton:Hide()
        end
    end
    
    if reduce then
        QDKP2_Frame2:SetWidth(QDKP2_Frame2:GetWidth() - (width))
    elseif expand then
        QDKP2_Frame2:SetWidth(QDKP2_Frame2:GetWidth() + (width))
    end
end

---------------------- OnClick functions --------------------------


function myClass.LeftClickEntry(self)
    local name, btnIndex = QDKP2GUI_GetClickedEntry(myClass)
    if IsShiftKeyDown() then
        if not myClass.PreviousShiftSelSet then
            myClass.PreviousShiftSelSet = {}
            QDKP2_CopyTable(myClass.SelectedPlayers, myClass.PreviousShiftSelSet)
        else
            myClass.SelectedPlayers = {}
            QDKP2_CopyTable(myClass.PreviousShiftSelSet, myClass.SelectedPlayers)
        end
        local begin, stop
        local list = {}
        if btnIndex > myClass.LastClickIndex then
            begin = myClass.LastClickIndex + 1
            stop = btnIndex
        else
            begin = btnIndex
            stop = myClass.LastClickIndex - 1
        end
        for i = begin, stop do
            local name = myClass.List[i]
            if name then
                table.insert(list, name);
            end
        end
        local tempShiftSel = myClass.PreviousShiftSelSet
        self:SelectPlayer(list, true)
        myClass.PreviousShiftSelSet = tempShiftSel
    else
        if IsControlKeyDown() then
            self:SelectPlayer(name, true)
        elseif QDKP2GUI_IsDoubleClick(myClass) and QDKP2_IsInGuild(name) then
            if QDKP2_OfficerMode() then
                QDKP2GUI_Toolbox:Popup(self.SelectedPlayers) --double click
            else
                QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
            end
        else
            self:SelectPlayer(name)
        end
        myClass.LastClickIndex = btnIndex
    end
end

function myClass.RightClickEntry(self)
    local name = QDKP2GUI_GetClickedEntry(myClass)
    if not IsControlKeyDown() and not myClass:isSelectedPlayer(name) then
        self:SelectPlayer(name)
    elseif QDKP2GUI_IsDoubleClick(myClass) and QDKP2_IsInGuild(name) then
        QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
        QDKP2GUI_CloseMenus()
        return
    end
    self:PlayerMenu()
end

function myClass.ChangeList(self, Type)
    QDKP2_Debug(2, "GUI-Roster", "Changing view to " .. tostring(Type))
    self.Sel = Type
    myClass:PupulateList()
    local list = {}
    for i, v in pairs(self.List) do
        if myClass:isSelectedPlayer(v) then
            table.insert(list, v);
        end
    end
    self.SelectedPlayers = list
    if Type == 'bid' then
        myClass.Sort.Order = ''
        myClass.Sort.Reverse.BidValue = true
        myClass:SortList("BidValue")
    else
        myClass.Sort.LastLen = -1 --forces a resort
    end
    myClass:SelectPlayer(list) --this is to clean the selection if the previous selected players are no longer available.
end

function myClass.DragDropManager(self)
    local what, a1, a2 = GetCursorInfo()
    if what == 'item' then
        this:SetText(a2)
        ClearCursor()
    end
end

function myClass.PushedBidButton(self)
    if QDKP2_BidM_isBidding() then
        QDKP2_BidM_CancelBid()
        QDKP2_Frame2_Bid_Item:SetText("")
    else
        QDKP2_BidM_StartBid(QDKP2_Frame2_Bid_Item:GetText())
    end
    myClass:Refresh()
    QDKP2_Frame2_Bid_Item:ClearFocus()
end

function myClass.PushedBidWinButton(self)
    if QDKP2_BidM_isBidding() then
        if myClass.SelectedPlayers and #myClass.SelectedPlayers == 1 then
            QDKP2_BidM_Winner(myClass.SelectedPlayers[1])
        end
    end
end

---------- Entries Selection --------------------

function myClass.SelectPlayer(self, name, multiple)
    --Selects given player. if multiple is true, does a multiple selection (ctrl key), wich will toggle the
    --selected state of name.
    QDKP2_Debug(3, "GUI-Roster", "Selecting" .. tostring(name))
    myClass.PreviousShiftSelSet = nil
    if name == "RAID" then
        return ;
    end
    self.SelectedPlayers = self.SelectedPlayers or {}
    if type(name) == "string" then
        name = { name };
    end
    if multiple then
        for i1, v1 in pairs(name) do
            local found
            for i2, v2 in pairs(self.SelectedPlayers) do
                if v1 == v2 then
                    table.remove(self.SelectedPlayers, i2)
                    found = true
                    break
                end
            end
            if not found then
                table.insert(self.SelectedPlayers, 1, v1);
            end
        end
    else
        QDKP2GUI_Roster.SelectedPlayers = name
    end
    if #self.SelectedPlayers > 0 then
        if QDKP2_IsInGuild(self.SelectedPlayers[1]) then
            QDKP2GUI_Toolbox:SelectPlayer(self.SelectedPlayers)
            QDKP2GUI_Log:SelectPlayer(self.SelectedPlayers[1])
        elseif #self.SelectedPlayers > 1 then
            QDKP2GUI_Toolbox:SelectPlayer(self.SelectedPlayers)
        else
            QDKP2GUI_Toolbox:Hide()
            QDKP2GUI_Log:Hide()
        end
    else
        QDKP2GUI_Toolbox:Hide()
    end
    QDKP2GUI_CloseMenus()
    self:Refresh()
end

function myClass.isSelectedPlayer(self, name)
    self.SelectedPlayers = self.SelectedPlayers or {}
    for i, v in pairs(myClass.SelectedPlayers) do
        if v == name then
            return i;
        end
    end
end

function myClass.SelectAll()
    myClass:SelectPlayer(myClass.List)
end

function myClass.SelectNone()
    myClass:SelectPlayer({})
end

function myClass.SelectInvert()
    local out = {}
    for i1, v1 in pairs(myClass.List) do
        table.insert(out, v1)
        for i2, v2 in pairs(myClass.SelectedPlayers) do
            if v1 == v2 then
                table.remove(out)
                break
            end
        end
    end
    myClass:SelectPlayer(out)
end

function myClass.ToggleShowAlts(self)
    self.ShowAlts = not self.ShowAlts
    self:Refresh(true)  -- forceResort = true
end

function myClass.GetPlayerCounts(self)
    local totalMembers = #QDKP2name
    local mainMembers = 0
    local altMembers = 0
    
    for i, name in pairs(QDKP2name) do
        if QDKP2_IsAlt(name) then
            altMembers = altMembers + 1
        else
            mainMembers = mainMembers + 1
        end
    end
    
    return totalMembers, mainMembers, altMembers
end

-------------------- Scroll ------------------

function myClass.ScrollBarUpdate()
    myClass.Offset = FauxScrollFrame_GetOffset(QDKP2_frame2_scrollbar)
    myClass:Refresh()
end

--------------------- Menus --------------------------

local function NYIfunc()
    QDKP2_Msg("To be done")
end

local QuickModifyVoices = {
    { template = QDKP2_LOC_GUIADDDKPAMOUNT,
      func = function()
          QDKP2_PlayerGains(myClass.SelectedPlayers, QDKP2GUI_Vars.DKP_QuickModify)
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end },
    { template = QDKP2_LOC_GUISUBTRACTDKPAMOUNT,
      func = function()
          QDKP2_PlayerSpends(myClass.SelectedPlayers, QDKP2GUI_Vars.DKP_QuickModify)
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end },
    { text = string.gsub(QDKP2_LOC_GUISUBTRACTDKPAMOUNT, "$AMOUNT", tostring(QDKP2GUI_Default_QuickPerc1 .. "%%")),
      func = function()
          QDKP2_PlayerSpends(myClass.SelectedPlayers, QDKP2GUI_Default_QuickPerc1 .. "%")
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end
    },
    { text = string.gsub(QDKP2_LOC_GUISUBTRACTDKPAMOUNT, "$AMOUNT", tostring(QDKP2GUI_Default_QuickPerc2) .. "%%"),
      func = function()
          QDKP2_PlayerSpends(myClass.SelectedPlayers, QDKP2GUI_Default_QuickPerc2 .. "%%")
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end
    },
    { text = QDKP2_LOC_GUIADDONEHOUR,
      func = function()
          QDKP2_PlayerIncTime(myClass.SelectedPlayers, 1)
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end
    },
    { text = QDKP2_LOC_GUIRESETRAIDINGTIME,
      func = function()
          local Selection = myClass.SelectedPlayers
          if type(Selection) == "string" then
              Selection = { Selection };
          end
          local ts = QDKP2_Timestamp()
          for i, v in pairs(Selection) do
              local Hours = QDKP2_GetHours(v)
              if Hours and Hours > 0 then
                  QDKP2_AddTotals(v, nil, nil, -Hours, "raid timer reset (single)", true, ts)
              end
          end
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end
    },
    { text = QDKP2_LOC_GUIRESETDKP,
      func = function()
          local Selection = myClass.SelectedPlayers
          if type(Selection) == "string" then
              Selection = { Selection };
          end
          local ts = QDKP2_Timestamp()
          for i, v in pairs(Selection) do
              local Tot = QDKP2_GetTotal(v)
              local Spent = QDKP2_GetSpent(v)
              if Tot and Spent and (Tot ~= 0 or Spent ~= 0) then
                  QDKP2_AddTotals(v, -Tot, -Spent, nil, "DKP reset (single)", true, ts)
              end
          end
          QDKP2GUI_CloseMenus()
          QDKP2_RefreshAll()
      end
    },
    { text = QDKP2_LOC_GUISETQMODAMOUNT,
      func = function()
          QDKP2GUI_CloseMenus()
          QDKP2_OpenInputBox(QDKP2_LOC_GUISETQMODAMOUNTDESC,
                  function(amount)
                      amount = tonumber(amount)
                      if amount then
                          QDKP2GUI_Vars.DKP_QuickModify = amount;
                      end
                  end)
          QDKP2_InputBox_SetDefault(tostring(QDKP2GUI_Vars.DKP_QuickModify))
      end
    },
}

-- Добавляем опции ролей в меню
local RoleVoices = {
    BIS_Role = { 
        text = "Назначить БИС",
        func = function()
            myClass:AssignRoleToSelected("BIS")
        end
    },
    TankHeal_Role = { 
        text = "Назначить ТАНК/ХИЛ", 
        func = function()
            myClass:AssignRoleToSelected("TANK_HEAL")
        end
    },
    BisTankHeal_Role = { 
        text = "Назначить БИС ТАНК/ХИЛ",
        func = function()
            myClass:AssignRoleToSelected("BIS_TANK_HEAL")
        end
    },
    Clear_Role = { 
        text = "Сбросить роль",
        func = function()
            myClass:AssignRoleToSelected("NONE")
        end
    }
}

local LogVoices = {
    -- Dictionary with all the log voices.
    OpenLog = { text = QDKP2_LOC_GUISHOWLOG,
                func = function()
                    QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
                end,
    },
    OpenToolbox = { text = QDKP2_LOC_GUIOPENTOOLBOX,
                    func = function()
                        QDKP2GUI_Toolbox:Popup(myClass.SelectedPlayers)
                    end
    },
    OpenAmounts = { text = QDKP2_LOC_GUIEDITDKP,
                    func = function()
                        QDKP2GUI_SetAmounts:Popup(myClass.SelectedPlayers)
                    end
    },
    QuickMod = { text = QDKP2_LOC_GUIQUICKMOD,
                 hasArrow = true,
                 menuList = QuickModifyVoices,
    },
    BonusQuickMod = { 
        text = "|cFF7FFFD4ЦЛК Допы",
        hasArrow = true,
        menuList = {
            { text = "|cFF00FF00Контроль/Касты/Слизни (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за КОНТРОЛЬ/КАСТЫ/СЛИЗНИ")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFF00FF00Тотал Р1 (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за Тотал Р1")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFF00FF00Тотал Р2-5 (+100)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 100, "за Тотал Р2-5")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Орк 21+ (+400)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 400, "за Дпс Орк 21+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Орк 19+ (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за Дпс Орк 19+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Проф 17+ (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за ДПС Проф 17+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Проф 15+ (+100)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 100, "за ДПС Проф 15+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Лич 18+ (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за ДПС Лич 18+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFFCC00Дпс Лич 16+ (+100)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 100, "за ДПС Лич 16+")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
        }
    },
    MyQuickMod = { 
        text = "|cFF3366FFЦЛК Бис-Хил-Танк",
        hasArrow = true,
        menuList = {
            { text = "|cFF3366FFЦЛК ОБ", notClickable = true },
            { text = "Бис (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за БИС")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Хил/Танк (+400)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 400, "за ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Бис Хил/Танк (+600)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 600, "за БИС ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFF3366FFЦЛК ХМ", notClickable = true },
            { text = "Бис (+400)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 400, "за БИС")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Хил/Танк (+800)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 800, "за ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Бис Хил/Танк (+1200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 1200, "за БИС ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
        }
    },
    MyQuickModTwo = { 
        text = "|cFFFF0000РС Бис-Хил-Танк",
        hasArrow = true,
        menuList = {
            { text = "|cFFFF0000РС ОБ", notClickable = true },
            { text = "Бис (+100)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 100, "за БИС")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Хил/Танк (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Бис Хил/Танк (+300)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 300, "за БИС ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "|cFFFF0000РС ХМ", notClickable = true },
            { text = "Бис (+200)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 200, "за БИС")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Хил/Танк (+400)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 400, "за ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
            
            { text = "Бис Хил/Танк (+600)",
              func = function()
                  QDKP2_PlayerGains(myClass.SelectedPlayers, 600, "за БИС ХИЛ/ТАНК")
                  QDKP2GUI_CloseMenus()
                  QDKP2_RefreshAll()
              end
            },
        }
    },    
    RemoveFromGuildSingle = { 
        text = QDKP2_LOC_GUIREMOVEFROMGUILD,
        func = function()
            local sel = myClass.SelectedPlayers
            if not sel or #sel == 0 then return end
            
            -- Проверяем права
            if not CanRemoveFromGuild() then return end
            
            StaticPopup_Show("QDKP2_REMOVE_FROM_GUILD_SINGLE", sel[1], nil, sel)
        end
    },
    
    RemoveFromGuildMulti = { 
        text = QDKP2_LOC_GUIREMOVEFROMGUILD .. " (" .. #myClass.SelectedPlayers .. ")",
        func = function()
            local sel = myClass.SelectedPlayers
            if not sel or #sel == 0 then return end
            
            -- Проверяем права
            if not CanRemoveFromGuild() then return end
            
            -- Фильтруем только игроков в гильдии (кроме себя)
            local guildPlayers = {}
            for _, playerName in ipairs(sel) do
                if QDKP2_IsInGuild(playerName) and playerName ~= UnitName("player") then
                    table.insert(guildPlayers, playerName)
                end
            end
            
            if #guildPlayers == 0 then
                QDKP2_Msg(QDKP2_COLOR_RED .. "Нет игроков для исключения из гильдии")
                return
            end
            
            -- Показываем диалог со списком имен
            StaticPopup_Show("QDKP2_REMOVE_FROM_GUILD_MULTI", nil, nil, {players = guildPlayers})
        end
    },
    Notify = { text = QDKP2_LOC_GUINOTIFYDKP,
               func = function()
                   for i, name in pairs(myClass.SelectedPlayers) do
                       if QDKP2online[name] then
                           QDKP2_Notify(name);
                       end
                   end
               end
    },
    AltClear = { text = QDKP2_LOC_GUIUNLINKALT,
                 func = function()
                     -- ИСПРАВЛЕНИЕ: Разрешаем массовую отвязку альтов
                     for i, name in pairs(myClass.SelectedPlayers) do
                        QDKP2_ClearAlt(name)
                     end
                     -- Обновляем список после изменений
                     QDKP2_RefreshAll()
                 end
    },
    AltMake = { text = QDKP2_LOC_GUILINKALT, func = function()
        if #myClass.SelectedPlayers == 2 then
            local alt = myClass.SelectedPlayers[2]
            local main = myClass.SelectedPlayers[1]
            QDKP2_MakeAlt(alt, main)
        else
            QDKP2_NotifyUser(QDKP2_LOC_GUILINKALTDESC)
        end
    end
    },
    ExternalAdd = { text = QDKP2_LOC_GUIADDEXTERNAL,
                    func = function()
                        QDKP2_NewExternal()
                    end
    },
    ExternalRem = { text = QDKP2_LOC_GUIREMEXTERNAL,
                    func = function()
                        -- ИСПРАВЛЕНИЕ: Разрешаем массовое удаление External
                        local removed = false
                        for i, name in pairs(myClass.SelectedPlayers) do
                            if QDKP2_IsExternal(name) then
                                QDKP2_DelExternal(name)
                                removed = true
                            end
                        end
                        if removed then
                             myClass:Refresh()
                             QDKP2GUI_Log:Refresh()
                        end
                    end
    },
    AddAsExternal = { text = QDKP2_LOC_GUIADDEXTERNAL,
                      func = function()
                          QDKP2_NewExternal(myClass.SelectedPlayers[1])
                          myClass:Refresh()
                      end,
    },
    StandbyAdd = { text = QDKP2_LOC_GUIADDSTANDBY,
                   checked = function()
                       return QDKP2_IsStandby(myClass.SelectedPlayers[1]);
                   end,
                   func = function()
                       local name = myClass.SelectedPlayers[1]
                       if QDKP2_IsStandby(name) then
                           QDKP2_RemStandby(name)
                       else
                           QDKP2_AddStandby(name)
                       end
                       myClass:Refresh()
                       QDKP2GUI_Log:Refresh()
                   end
    },
    AllStandbyAdd = { text = QDKP2_LOC_GUIADDSTANDBYALL,
                      func = function()
                          for i, name in pairs(myClass.SelectedPlayers) do
                              if not QDKP2_IsInRaid(name) then
                                  QDKP2_AddStandby(name);
                              end
                          end
                      end,
    },
    ExcludeRaid = { text = QDKP2_LOC_GUIRAIDEXCLUDE,
                    checked = function()
                        return QDKP2_IsRemoved(myClass.SelectedPlayers[1]);
                    end,
                    func = function()
                        local name = myClass.SelectedPlayers[1]
                        if QDKP2_IsRemoved(name) then
                            QDKP2_RemoveFromRaid(name, true)
                        end
                    end,
    },
    ShowOutGuild = { text = QDKP2_LOC_GUISHOWPLAYERSNOTINGUILD,
                     checked = function()
                         return QDKP2GUI_Vars.ShowOutGuild;
                     end,
                     func = function()
                         if QDKP2GUI_Vars.ShowOutGuild then
                             QDKP2GUI_Vars.ShowOutGuild = false
                         else
                             QDKP2GUI_Vars.ShowOutGuild = true
                         end
                         myClass:ChangeList(myClass.Sel)
                     end,
    },
    SetWinner = { text = QDKP2_LOC_GUISETWINNER,
                  func = function()
                      QDKP2_BidM_Winner(myClass.SelectedPlayers[1])
                  end
    },
    CancelBid = { text = QDKP2_LOC_GUICANCELBET,
                  func = function()
                      for i, name in pairs(myClass.SelectedPlayers) do
                          QDKP2_BidM_CancelPlayer(name)
                      end
                  end
    },
    ClearBid = { text = QDKP2_LOC_GUICLEARBIDLIST,
                 func = function()
                     QDKP2_BidM_Reset()
                 end
    },
    CountDown = { text = QDKP2_LOC_GUITRIGGERCNT,
                  func = function()
                      QDKP2_BidM_Countdown()
                  end
    },
    AcceptBids = { text = QDKP2_LOC_GUIACCEPTBETS,
                   checked = function()
                       return QDKP2_BidM.ACCEPT_BID;
                   end,
                   func = function()
                       if not QDKP2_BidM.ACCEPT_BID then
                           QDKP2_BidM.ACCEPT_BID = true
                           QDKP2_Msg(QDKP2_LOC_GUIBETDETECTIONENABLED)
                       else
                           QDKP2_BidM.ACCEPT_BID = false
                           QDKP2_Msg(QDKP2_LOC_GUIBETDETECTIONDISABLED)
                       end
                   end
    },
    PubblishBids = { text = QDKP2_LOC_GUIPUBLISHBIDSTORAID,
                     func = function()
                         if not QDKP2_BidM.LIST then
                             return ;
                         end
                         local text
                         if QDKP2_BidM.ITEM and #QDKP2_BidM.ITEM > 0 then
                             text = "Current bidders for " .. tostring(QDKP2_BidM.ITEM) .. ":"
                         else
                             text = "Current bidders:"
                         end
                         ChatThrottleLib:SendChatMessage("NORMAL", "QDKP2", text, "RAID")
                         for player, bid in pairs(QDKP2_BidM.LIST) do
                             local text = player .. " - bid:" .. tostring(bid.value or '-') .. ", roll:" .. tostring(bid.roll or '-')
                             ChatThrottleLib:SendChatMessage("NORMAL", "QDKP2", text, "RAID")
                         end
                     end
    },
    Revert = { text = QDKP2_LOC_GUIREVERTCHANGES,
               func = function()
                   for i, name in pairs(myClass.SelectedPlayers) do
                       if QDKP2_IsInGuild(name) then
                           QDKP2_ReverPlayer(name);
                       end
                   end
                   QDKP2_RefreshAll()
               end,
    },
    SelectAll = { text = QDKP2_LOC_GUISELECTALL, func = myClass.SelectAll },
    SelectNone = { text = QDKP2_LOC_GUISELECTNONE, func = myClass.SelectNone },
    SelectInvert = { text = QDKP2_LOC_GUISELECTINVERT, func = myClass.SelectInvert },
    ExternalPost = { text = QDKP2_LOC_GUIPOSTEXTERNALAMOUNTS, func = function()
        QDKP2_PostExternals("GUILD");
    end },
    RosterUpdate = { text = QDKP2_LOC_GUIUPDATEROSTER, func = myClass.Update },
    MenuClose = { text = QDKP2_LOC_GUICLOSEMENU, func = QDKP2GUI_CloseMenus },
    spacer = { text = "", notClickable = true },
    ShowAlts = { 
        text = QDKP2_LOC_GUISHOWALTS or "Показывать альтов",
        checked = function()
            return myClass.ShowAlts
        end,
        func = function()
            myClass:ToggleShowAlts()
        end
    },
}
-- Функция для обновления текста групповой кнопки
local function UpdateRemoveFromGuildMultiText()
    if not myClass.SelectedPlayers then return end
    local count = #myClass.SelectedPlayers
    
    -- Подсчитываем только игроков в гильдии (кроме себя)
    local guildPlayersCount = 0
    for _, playerName in ipairs(myClass.SelectedPlayers) do
        if QDKP2_IsInGuild(playerName) and playerName ~= UnitName("player") then
            guildPlayersCount = guildPlayersCount + 1
        end
    end
    
    if LogVoices.RemoveFromGuildMulti then
        if guildPlayersCount == count then
            LogVoices.RemoveFromGuildMulti.text = QDKP2_LOC_GUIREMOVEFROMGUILD .. " (" .. count .. ")"
        else
            LogVoices.RemoveFromGuildMulti.text = QDKP2_LOC_GUIREMOVEFROMGUILD .. " (" .. guildPlayersCount .. "/" .. count .. ")"
        end
    end
end

function myClass.PlayerMenu(self, List)
    UpdateRemoveFromGuildMultiText()
    if not QDKP2_OfficerMode() then
        return ;
    end --view mode doesn't have a player menu.
    local managing = QDKP2_ManagementMode()
    local sel = List or self.SelectedPlayers
    local menu
    
    if #sel == 1 and not QDKP2_IsInGuild(sel[1]) then
        menu = {}
        table.insert(menu, { text = "|cFF00FF00" .. sel[1] .. "|r", isTitle = true })
		table.insert(menu, LogVoices.spacer)
        if self.Sel == "bid" then
            table.insert(menu, LogVoices.SetWinner)
            table.insert(menu, LogVoices.CancelBid)
        end
        table.insert(menu, LogVoices.AddAsExternal)
        
    elseif #sel == 1 then
        local name = self.SelectedPlayers[1]
        menu = {}
        table.insert(menu, { text = "|cFF00FF00" .. name .. "|r", isTitle = true })
		table.insert(menu, LogVoices.spacer)
        if self.Sel == "bid" then
            table.insert(menu, LogVoices.SetWinner)
            table.insert(menu, LogVoices.CancelBid)
            table.insert(menu, LogVoices.spacer)
        end
        table.insert(menu, LogVoices.OpenLog)
        table.insert(menu, LogVoices.OpenToolbox)
        table.insert(menu, LogVoices.OpenAmounts)
        table.insert(menu, LogVoices.Notify)
        table.insert(menu, LogVoices.spacer)
        
        -- КНОПКА ИСКЛЮЧЕНИЯ ИЗ ГИЛЬДИИ
        if QDKP2_IsInGuild(name) and name ~= UnitName("player") then
            table.insert(menu, LogVoices.RemoveFromGuildSingle)
        end
        
        if QDKP2_IsAlt(name) then
            table.insert(menu, LogVoices.AltClear)
        else
            table.insert(menu, LogVoices.AltMake)
        end
        
        if managing and (QDKP2_IsStandby(name) or not QDKP2_IsInRaid(name)) then
            table.insert(menu, LogVoices.StandbyAdd)
        end
        if QDKP2_IsExternal(name) then
            table.insert(menu, LogVoices.ExternalRem)
        end
        
        table.insert(menu, LogVoices.spacer)
        
        table.insert(menu, LogVoices.QuickMod)
        table.insert(menu, LogVoices.BonusQuickMod)
        table.insert(menu, LogVoices.MyQuickMod)
        table.insert(menu, LogVoices.MyQuickModTwo)
        table.insert(menu, LogVoices.Revert)
        QuickModifyVoices[1].text = string.gsub(QuickModifyVoices[1].template, "$AMOUNT", tostring(QDKP2GUI_Vars.DKP_QuickModify))
        QuickModifyVoices[2].text = string.gsub(QuickModifyVoices[2].template, "$AMOUNT", tostring(QDKP2GUI_Vars.DKP_QuickModify))
        
    elseif #sel > 1 then
        menu = {}
        table.insert(menu, { text = "|cFF00FF00GROUP's actions:|r", isTitle = true })
		table.insert(menu, LogVoices.spacer)
        if self.Sel == "bid" then
            table.insert(menu, LogVoices.CancelBid)
            table.insert(menu, LogVoices.spacer)
        end
        table.insert(menu, LogVoices.OpenToolbox)
        table.insert(menu, LogVoices.OpenAmounts)
        table.insert(menu, LogVoices.Notify)
        table.insert(menu, LogVoices.spacer)
        
        -- ИСКЛЮЧЕНИЕ ДЛЯ ГРУППЫ
        local guildPlayersCount = 0
        for _, playerName in ipairs(sel) do
            if QDKP2_IsInGuild(playerName) and playerName ~= UnitName("player") then
                guildPlayersCount = guildPlayersCount + 1
            end
        end
        
        if guildPlayersCount > 0 then
            table.insert(menu, LogVoices.RemoveFromGuildMulti)
        else
            table.insert(menu, { text = "|cFF808080Нет игроков для исключения|r", notClickable = true })
        end
        
        -- Управление альтами/стендбаем для группы
        if #sel == 2 then
            table.insert(menu, LogVoices.AltMake)
        end
        if managing and (self.Sel == 'guild' or self.Sel == 'guildonline') then
            table.insert(menu, LogVoices.AllStandbyAdd)
        end
        
        table.insert(menu, LogVoices.spacer)
        
        table.insert(menu, LogVoices.QuickMod)
        table.insert(menu, LogVoices.BonusQuickMod)
        table.insert(menu, LogVoices.MyQuickMod)
        table.insert(menu, LogVoices.MyQuickModTwo)
        table.insert(menu, LogVoices.Revert)
        QuickModifyVoices[1].text = string.gsub(QuickModifyVoices[1].template, "$AMOUNT", tostring(QDKP2GUI_Vars.DKP_QuickModify))
        QuickModifyVoices[2].text = string.gsub(QuickModifyVoices[2].template, "$AMOUNT", tostring(QDKP2GUI_Vars.DKP_QuickModify))
    end
    
    if not menu then
        return ;
    end
    table.insert(menu, LogVoices.spacer)
    table.insert(menu, LogVoices.MenuClose)
    EasyMenu(menu, self.MenuFrame, "cursor", 0, 0, "MENU")
end

function myClass.RosterMenu(self)
    menu = {}
    table.insert(menu, { text = "ROSTER MENU", isTitle = true })
    table.insert(menu, LogVoices.SelectAll)
    table.insert(menu, LogVoices.SelectNone)
    table.insert(menu, LogVoices.SelectInvert)
    table.insert(menu, 2, LogVoices.spacer)
    table.insert(menu, 2, LogVoices.ShowAlts)
    if self.Sel == "guild" or self.Sel == "guildonline" then
        menu[1].text = QDKP2_LOC_GUIGUILDROSTERMENU
        if QDKP2_OfficerMode() then
            table.insert(menu, 2, LogVoices.spacer)
            table.insert(menu, 2, LogVoices.ExternalAdd)
            table.insert(menu, 2, LogVoices.ExternalPost)
        end
    elseif self.Sel == "raid" then
        menu[1].text = QDKP2_LOC_GUIRAIDROSTERMENU
        table.insert(menu, 2, LogVoices.spacer)
        table.insert(menu, 2, LogVoices.ShowOutGuild)
    elseif self.Sel == "bid" then
        menu[1].text = QDKP2_LOC_GUIBIDMANAGERMENU
        table.insert(menu, 2, LogVoices.spacer)
        table.insert(menu, 2, LogVoices.PubblishBids)
        table.insert(menu, 2, LogVoices.ClearBid)
        if QDKP2_BidM_isBidding() then
            table.insert(menu, 2, LogVoices.CountDown)
            table.insert(menu, 2, LogVoices.AcceptBids)
        end
        table.insert(menu, 3, LogVoices.ShowOutGuild)
    end

    table.insert(menu, LogVoices.spacer)
    table.insert(menu, LogVoices.RosterUpdate)
    table.insert(menu, LogVoices.MenuClose)
    EasyMenu(menu, self.MenuFrame, "cursor", 0, 0, "MENU")
end


--------------------- SORTING ALGORYTHMS -------------------

-- Perform all sorting at once. Values the sorting by category- highest power of 2 is most important.
-- When a new sorting category is used (say, rank), it will be incresed to max (8) and the others will be
-- adjusted downwards accordingly

-- Incoming val1, val2 are names.
local function SortComparitor(val1, val2)
    local compare = 0;
    local test1, test2, increment, invertBuffer
    local Values = myClass.Sort.Values
    local Reverse = myClass.Sort.Reverse

    -- Alpha
    test1 = val1
    test2 = val2
    if Reverse.Alpha then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Alpha
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    if not QDKP2_IsInGuild(val1) then
        if QDKP2_IsInGuild(val2) then
            return false
        else
            return compare < 0
        end
    elseif not QDKP2_IsInGuild(val2) then
        return true
    end

    -- Rank
    test1 = QDKP2rankIndex[val1] or 255
    test2 = QDKP2rankIndex[val2] or 255
    if Reverse.Rank then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Rank
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Class
    test1 = QDKP2class[val1] or ""
    test2 = QDKP2class[val2] or ""
    if Reverse.Class then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Class
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Officer Note
    test1 = myClass:GetOfficerNote(val1) or ""
    test2 = myClass:GetOfficerNote(val2) or ""
    if Reverse.Officer then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Officer
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

	-- Role (СОРТИРОВКА ПО ПРИОРИТЕТУ)
    -- Получаем ключи ролей (например "BIS_TANK_HEAL"), а не их названия
    local roleKey1 = myClass:GetPlayerRole(val1)
    local roleKey2 = myClass:GetPlayerRole(val2)
    
    -- Превращаем ключи в числа приоритета (если роли нет, приоритет 99 - в самом низу)
    test1 = myClass.RolePriority[roleKey1] or 99
    test2 = myClass.RolePriority[roleKey2] or 99

    if Reverse.Role then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Role
    -- Сравниваем числа: чем меньше число, тем выше игрок
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Net
    test1 = QDKP2_GetNet(val1) or QDKP2_MINIMUM_NET
    test2 = QDKP2_GetNet(val2) or QDKP2_MINIMUM_NET
    if Reverse.Net then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Net
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Total
    test1 = QDKP2_GetTotal(val1) or QDKP2_MINIMUM_NET
    test2 = QDKP2_GetTotal(val2) or QDKP2_MINIMUM_NET
    if Reverse.Total then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Total
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Spent
    test1 = QDKP2_GetSpent(val1) or QDKP2_MINIMUM_NET
    test2 = QDKP2_GetSpent(val2) or QDKP2_MINIMUM_NET
    if Reverse.Spent then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Spent
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    --Hours
    test1 = QDKP2_GetHours(val1) or 0
    test2 = QDKP2_GetHours(val2) or 0
    if Reverse.Hours then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Hours
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    if myClass.Sel == 'raid' or myClass.Sel == 'bid' then
        local s_gain1, s_spent1 = QDKP2_GetSessionAmounts(val1)
        local s_gain2, s_spent2 = QDKP2_GetSessionAmounts(val2)
        s_gain1 = s_gain1 or QDKP2_MINIMUM_NET
        s_spent1 = s_spent1 or QDKP2_MINIMUM_NET
        s_gain2 = s_gain2 or QDKP2_MINIMUM_NET
        s_spent2 = s_spent2 or QDKP2_MINIMUM_NET

        --Session Gain
        if Reverse.SessGain then
            invertBuffer = s_gain2;
            s_gain2 = s_gain1;
            s_gain1 = invertBuffer;
        end
        increment = Values.SessGain
        if (s_gain1 < s_gain2) then
            compare = compare - increment;
        elseif (s_gain1 > s_gain2) then
            compare = compare + increment;
        end

        --Session spent
        if Reverse.SessSpent then
            invertBuffer = s_spent2;
            s_spent2 = s_spent1;
            s_spent1 = invertBuffer;
        end
        increment = Values.SessSpent
        if (s_spent1 < s_spent2) then
            compare = compare - increment;
        elseif (s_spent1 > s_spent2) then
            compare = compare + increment;
        end

        if myClass.Sel == 'bid' then

            local bid1 = QDKP2_BidM_GetBidder(val1) or {}
            local bid2 = QDKP2_BidM_GetBidder(val2) or {}

            --Bid Value
            test1 = bid1.value or -100000
            test2 = bid2.value or -100000
            if Reverse.BidValue then
                invertBuffer = test2;
                test2 = test1;
                test1 = invertBuffer;
            end
            increment = Values.BidValue
            if (test1 < test2) then
                compare = compare - increment;
            elseif (test1 > test2) then
                compare = compare + increment;
            end

            --Bid text
            test1 = bid1.txt or ' '
            test2 = bid2.txt or ' '
            if Reverse.BidText then
                invertBuffer = test2;
                test2 = test1;
                test1 = invertBuffer;
            end
            increment = Values.BidText
            if (test1 < test2) then
                compare = compare - increment;
            elseif (test1 > test2) then
                compare = compare + increment;
            end

            --Bid Roll
            test1 = bid1.roll or 0
            test2 = bid2.roll or 0
            if Reverse.BidRoll then
                invertBuffer = test2;
                test2 = test1;
                test1 = invertBuffer;
            end
            increment = Values.BidRoll
            if (test1 < test2) then
                compare = compare - increment;
            elseif (test1 > test2) then
                compare = compare + increment;
            end
        end
    end
    return compare < 0
end

function myClass.SortList(self, Order, List, forceResort)
    -- Sorts the list of guild members given by <List> by <OrderToGive>. if Order is nil, will use
    -- the default in QDKP2_Order, and in that case it won't sort if the order hasn't changed.

    List = List or myClass.List

    if (not Order) and (myClass.Sort.LastLen == #List) and not (forceResort) then
        return ;
    end --no need to resort if the sorting or the entriesh haven't changed.
    local Values = myClass.Sort.Values

    --this manages the inversion when you click 2 times the same sorting button
    if Order and Order == myClass.Sort.Order then
        local InvFlag = QDKP2GUI_Roster.Sort.Reverse[Order]
        if InvFlag then
            InvFlag = false
        else
            InvFlag = true
        end
        QDKP2GUI_Roster.Sort.Reverse[Order] = InvFlag
    end

    Order = Order or myClass.Sort.Order
    QDKP2_Debug(2, "GUI-Roster", "Sorting by " .. Order)

    -- Fixup valuation of ordering. (which is most important?)
    local lastmax
    if (Order == "Alpha") then
        lastmax = Values.Alpha
    elseif (Order == "Rank") then
        lastmax = Values.Rank
    elseif (Order == "Class") then
        lastmax = Values.Class
    elseif (Order == "Officer") then
        lastmax = Values.Officer
    elseif (Order == "Role") then
        lastmax = Values.Role
    elseif (Order == "Net") then
        lastmax = Values.Net
    elseif (Order == "Total") then
        lastmax = Values.Total
    elseif (Order == "Spent") then
        lastmax = Values.Spent
    elseif (Order == "Hours") then
        lastmax = Values.Hours
    elseif (Order == "SessGain") then
        lastmax = Values.SessGain
    elseif (Order == "SessSpent") then
        lastmax = Values.SessSpent
    elseif (Order == "BidRoll") then
        lastmax = Values.BidRoll
    elseif (Order == "BidText") then
        lastmax = Values.BidText
    elseif (Order == "BidValue") then
        lastmax = Values.BidValue
    else
        QDKP2_Debug(1, "GUI-Roster", "Unknown sorting method: " .. Order)
        return
    end
    if (Values.Alpha > lastmax) then
        Values.Alpha = Values.Alpha / 2;
    end
    if (Values.Rank > lastmax) then
        Values.Rank = Values.Rank / 2;
    end
    if (Values.Class > lastmax) then
        Values.Class = Values.Class / 2;
    end
    if (Values.Officer > lastmax) then
        Values.Officer = Values.Officer / 2;
    end
    if (Values.Role > lastmax) then
        Values.Role = Values.Role / 2;
    end
    if (Values.Net > lastmax) then
        Values.Net = Values.Net / 2;
    end
    if (Values.Total > lastmax) then
        Values.Total = Values.Total / 2;
    end
    if (Values.Spent > lastmax) then
        Values.Spent = Values.Spent / 2;
    end
    if (Values.Hours > lastmax) then
        Values.Hours = Values.Hours / 2;
    end
    if (Values.SessGain > lastmax) then
        Values.SessGain = Values.SessGain / 2;
    end
    if (Values.SessSpent > lastmax) then
        Values.SessSpent = Values.SessSpent / 2;
    end
    if (Values.BidRoll > lastmax) then
        Values.BidRoll = Values.BidRoll / 2;
    end
    if (Values.BidText > lastmax) then
        Values.BidText = Values.BidText / 2;
    end
    if (Values.BidValue > lastmax) then
        Values.BidValue = Values.BidValue / 2;
    end
    if (Order == "Alpha") then
        Values.Alpha = 2048
    elseif (Order == "Rank") then
        Values.Rank = 2048
    elseif (Order == "Class") then
        Values.Class = 2048
    elseif (Order == "Officer") then
        Values.Officer = 2048
    elseif (Order == "Role") then
        Values.Role = 2048
    elseif (Order == "Net") then
        Values.Net = 2048
    elseif (Order == "Total") then
        Values.Total = 2048
    elseif (Order == "Spent") then
        Values.Spent = 2048
    elseif (Order == "Hours") then
        Values.Hours = 2048
    elseif (Order == "SessGain") then
        Values.SessGain = 2048
    elseif (Order == "SessSpent") then
        Values.SessSpent = 2048
    elseif (Order == "BidRoll") then
        Values.BidRoll = 2048
    elseif (Order == "BidText") then
        Values.BidText = 2048
    elseif (Order == "BidValue") then
        Values.BidValue = 2048
    end
    table.sort(List, SortComparitor)
    myClass.Sort.LastLen = #List
    myClass.Sort.Order = Order
    return List
end

--Changes sort method.
function myClass.SortBy(self, order)
    QDKP2GUI_Roster:SortList(order)
    QDKP2GUI_Roster:Refresh()
end

QDKP2GUI_Roster = myClass