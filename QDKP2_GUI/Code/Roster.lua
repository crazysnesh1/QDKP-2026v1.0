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
    public = 165,
    role = 70,
    lastonline = 90,
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

-- Кэш публичных заметок (обновляется автоматически при GUILD_ROSTER_UPDATE)
myClass.publicNoteCache = {}

-- Глобальные таблицы для хранения последнего онлайна
QDKP2_lastonline_text = QDKP2_lastonline_text or {}
QDKP2_lastonline_minutes = QDKP2_lastonline_minutes or {}

-- Sort values
myClass.Sort.Values = {
    BidValue = 2048,
    BidText = 1024,
    BidRoll = 512,
    Alpha = 256,
    Rank = 128,
    Class = 64,
    Public = 48,
    Role = 96,
    Net = 32,
    Total = 16,
    Spent = 8,
    Hours = 4,
    SessGain = 2,
    SessSpent = 1,
    LastOnline = 32,
}

myClass.Sort.Reverse = {
    BidValue = true,
    BidText = true,
    BidRoll = true,
    Alpha = false,
    Rank = false,
    Class = false,
    Public = false,
    Role = false,
    Net = true,
    Total = true,
    Spent = true,
    Hours = true,
    SessGain = true,
    SessSpent = true,
    LastOnline = false,
}

-- Локализация для кнопки исключения из гильдии
QDKP2_LOC_GUIREMOVEFROMGUILD = "Исключить из гильдии"
QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_SINGLE = "Вы уверены, что хотите исключить игрока %s из гильдии?"
QDKP2_LOC_GUIREMOVEFROMGUILD_CONFIRM_MULTI = "Вы уверены, что хотите исключить следующих игроков из гильдии?\n\n%s\n\nВсего: %d игроков"

-------------------- Window management ----------------------

function myClass.OnLoad(self)
    self.Frame = QDKP2_Frame2
    self.MenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.Frame, "UIDropDownMenuTemplate")
    self.SubMenuFrame = CreateFrame("Frame", "QDKP2_Frame2_DropDownMenu", self.MenuFrame, "UIDropDownMenuTemplate")
    
    -- Создаем UI элементы (кнопка "Up" не создаётся!)
    self:CreateSearchUI()
    self:CreateRoleUI()
    self:CreateNonGuildUI()
    self:CreateICCTimerButtons()
    
    -- Установка флага показа оффлайн
    SetGuildRosterShowOffline(true)
    
    -- Регистрируем события
    self:RegisterEvents()
    
    -- Установка локализованного текста для кнопки "Последний онлайн"
    local lastOnlineBtn = _G["QDKP2_Frame2_SortBtn_lastonline"]
    if lastOnlineBtn then
        lastOnlineBtn:SetText(QDKP2_LOC_GUIPLAYERLASTONLINE)
    end
    
    QDKP2_Debug(2, "GUI-Roster", "Roster loaded successfully.")
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

-- Создаем интерфейс для управления ролями
function myClass.CreateRoleUI(self)
    self.RoleButton = CreateFrame("Button", "QDKP2_Frame2_RoleButton", self.Frame, "UIPanelButtonTemplate")
    self.RoleButton:SetSize(35, 25) 
    self.RoleButton:SetPoint("LEFT", "QDKP2_Frame2_SortBtn_role", "RIGHT", 0, 0)
    self.RoleButton:SetText("Наз.") 
    
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

    -- Создаем фрейм для меню
    self.RoleMenuFrame = CreateFrame("Frame", "QDKP2_RoleMenuFrame", UIParent, "UIDropDownMenuTemplate")
    
    -- Скрипт клика
    self.RoleButton:SetScript("OnClick", function() 
        if QDKP2_OfficerMode and QDKP2_OfficerMode() then
            if QDKP2_ShowRoleMenu then
                QDKP2_ShowRoleMenu(self.SelectedPlayers, self.RoleMenuFrame)
            else
                QDKP2_Msg("Система ролей не инициализирована")
            end
        else
            QDKP2_Msg("Вы не офицер.")
        end
    end)

    -- Тултип при наведении
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
end

-- Создаем интерфейс кнопки "Пуги"
function myClass.CreateNonGuildUI(self)
    if not self.SearchBox then return end
    
    self.NonGuildButton = CreateFrame("Button", "QDKP2_Frame2_NonGuildButton", self.Frame, "UIPanelButtonTemplate")
    self.NonGuildButton:SetSize(45, 22)
    self.NonGuildButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 10, 0) 
    self.NonGuildButton:SetText("Пуги")
    
    self.NonGuildButton:SetScript("OnClick", function() 
        self:ShowNonGuildMenu() 
    end)
    
    if ApplyThinBorder then
        ApplyThinBorder(self.NonGuildButton, 1, 0.5, 0)
    end
end

function myClass.ShowNonGuildMenu(self)
    if not QDKP2_NonGuildMembers or #QDKP2_NonGuildMembers == 0 then
        QDKP2_Msg("В рейде нет Пугов.")
        return
    end

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

    local header = "Пуги в рейде: "
    local currentMsg = header
    local maxLength = 240

    for i, name in ipairs(QDKP2_NonGuildMembers) do
        if string.len(currentMsg .. name .. ", ") > maxLength then
            SendChatMessage(currentMsg, channel)
            currentMsg = "Пуги (продолжение): " .. name .. ", "
        else
            currentMsg = currentMsg .. name .. ", "
        end
    end

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

    local function CanUseButtons()
        local isOfficer = QDKP2_OfficerMode and QDKP2_OfficerMode()
        local isLeader = IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()
        return isOfficer and isLeader
    end

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
            end
        end
    end)

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
            end
        end
    end)

    local function UpdateVisibility()
        local isRaidTab = (self.Sel == "raid")
        local inGroup = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
        local isOfficer = QDKP2_OfficerMode and QDKP2_OfficerMode()
        local isLeader = IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()

        if self.NonGuildButton then
            if isRaidTab and inGroup and isOfficer then
                self.NonGuildButton:Show()
            else
                self.NonGuildButton:Hide()
            end
        end

        if isRaidTab and isOfficer and isLeader then
            self.WithQuestButton:Show()
            self.NoQuestButton:Show()
        else
            self.WithQuestButton:Hide()
            self.NoQuestButton:Hide()
        end
    end

    self.Frame:HookScript("OnShow", UpdateVisibility)
    hooksecurefunc(self, "Refresh", UpdateVisibility)
end

-- Функция обновления кэша публичных заметок
function myClass.UpdatePublicNotesCache(self)
    if not IsInGuild() then return end
    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, _, _, _, _, _, note = GetGuildRosterInfo(i)
        if name then
            name = strsplit("-", name)
            self.publicNoteCache[name] = note or ""
        end
    end
end

-- Функция регистрации событий
function myClass.RegisterEvents(self)
    self.Frame:RegisterEvent("PLAYER_LOGOUT")
    self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.Frame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.Frame:RegisterEvent("GUILD_ROSTER_UPDATE")

    self.Frame:SetScript("OnEvent", function(frame, event, ...)
        if event == "PLAYER_LOGOUT" then
            -- Ничего не сохраняем, заметки не требуют сохранения
            QDKP2_Debug(2, "Roster", "Игрок вышел, заметки не сохраняются")
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- При входе в мир сразу запросим гильдию
            GuildRoster()
        elseif event == "RAID_ROSTER_UPDATE" then
            -- роли обновляются в RoleBonus.lua
        elseif event == "GUILD_ROSTER_UPDATE" then
            self:UpdatePublicNotesCache()   -- обновляем заметки
            self:UpdateLastOnlineData()
            self:Refresh()
            -- повторное обновление через 0.5 сек для надёжности
            C_Timer.After(0.5, function()
                self:UpdatePublicNotesCache()
                self:UpdateLastOnlineData()
                self:Refresh()
            end)
        end
    end)
end

-- Форматирование строки последнего онлайна
function myClass.FormatLastOnline(years, months, days, hours)
    if years and years > 0 then
        return years .. " " .. QDKP2_LOC_STATUS_YEARS_AGO
    elseif months and months > 0 then
        return months .. " " .. QDKP2_LOC_STATUS_MONTHS_AGO
    elseif days and days > 0 then
        return days .. " " .. QDKP2_LOC_STATUS_DAYS_AGO
    elseif hours and hours > 0 then
        if hours == 1 then
            return QDKP2_LOC_STATUS_HOUR_AGO
        else
            return hours .. " " .. QDKP2_LOC_STATUS_HOURS_AGO
        end
    else
        return QDKP2_LOC_STATUS_LESS_HOUR
    end
end

function myClass.UpdateLastOnlineData()
    if not IsInGuild() then return end
    local num = GetNumGuildMembers()
    if num == 0 then return end
    for i = 1, num do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name then
            name = strsplit("-", name)
            if online then
                QDKP2_lastonline_text[name] = QDKP2_LOC_STATUS_ONLINE
                QDKP2_lastonline_minutes[name] = 0
            else
                local years, months, days, hours = GetGuildRosterLastOnline(i)
                -- Если функция вернула числа (стандартный случай WotLK)
                if years and type(years) == "number" then
                    years = years or 0
                    months = months or 0
                    days = days or 0
                    hours = hours or 0
                    local minutes = years * 525600 + months * 43200 + days * 1440 + hours * 60
                    -- Если все параметры нулевые — это случай "< an hour ago"
                    if minutes == 0 then
                        minutes = 1   -- чтобы шли после Online (0) и до 1 hour (60)
                    end
                    QDKP2_lastonline_minutes[name] = minutes
                    QDKP2_lastonline_text[name] = myClass.FormatLastOnline(years, months, days, hours)
                else
                    -- Данные ещё не загружены или игрок не в гильдии
                    QDKP2_lastonline_text[name] = QDKP2_lastonline_text[name] or ""
                    QDKP2_lastonline_minutes[name] = QDKP2_lastonline_minutes[name] or nil
                end
            end
        end
    end
end

function myClass.Show(self)
    SetGuildRosterShowOffline(true)
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
        return true
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
    text = "",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
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
            self:SetHeight(self.text:GetHeight() + 100)
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
    
    local originalList = self.List
    self.List = self:ApplySearchFilter()

    if self.Sel == "guildonline" or self.Sel == "guild" then
        myClass:ShowColumn('deltatotal', false)
        myClass:ShowColumn('deltaspent', false)
        myClass:ShowColumn('roll', false)
        myClass:ShowColumn('bid', false)
        myClass:ShowColumn('value', false)
        myClass:ShowColumn('public', true)
        myClass:ShowColumn('role', true)
        myClass:ShowColumn('lastonline', true)
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
        myClass:ShowColumn('public', true)
        myClass:ShowColumn('role', true)
        myClass:ShowColumn('lastonline', false)
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
        myClass:ShowColumn('public', true)
        myClass:ShowColumn('role', true)
        myClass:ShowColumn('lastonline', false)
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

    if ((self.Sel == 'raid' or self.Sel == 'bid') and QDKP2GUI_Vars.ShowOutGuild) 
       or not self.ShowAlts 
       or (self.SearchText and self.SearchText ~= "" and self.SearchText ~= "Поиск...") then
        forceResort = true;
    end
    self:SortList(nil, nil, forceResort)

    local displayCount = tostring(#self.List)
    local totalCount = tostring(#originalList)
    
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

            -- ПОЛУЧАЕМ РОЛЬ ИЗ ГЛОБАЛЬНОЙ СИСТЕМЫ
            local roleDisplay = ""
            local roleColor = { r = 1, g = 1, b = 1 }
            if QDKP2_GetPlayerRoleDisplayName then
                roleDisplay = QDKP2_GetPlayerRoleDisplayName(name)
            end
            if QDKP2_GetPlayerRoleColor then
                roleColor = QDKP2_GetPlayerRoleColor(name)
            end

            getglobal(ParentName .. "_name"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_roll"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_bid"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_value"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_rank"):SetVertexColor(r, g, b, a)
            getglobal(ParentName .. "_role"):SetVertexColor(roleColor.r, roleColor.g, roleColor.b, a)
            local classColor = colors
            if not QDKP2_USE_CLASS_BASED_COLORS then
                classColor = QDKP2_GetClassColor(class)
            end
            getglobal(ParentName .. "_class"):SetVertexColor(classColor.r, classColor.g, classColor.b, a)
            getglobal(ParentName .. "_public"):SetVertexColor(r, g, b, a)
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

            local nameS, roll, bid, value, rank, publicNote, net, total, spent, hours, s_gain, s_spent
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
            -- Last Online
            if self.Sel == "guild" then
                local lastOnlineText = QDKP2_lastonline_text[name] or ""
                getglobal(ParentName .. "_lastonline"):SetText(lastOnlineText)

                -- Определяем цвет
                local rCol, gCol, bCol
                if QDKP2online and QDKP2online[name] then
                    rCol, gCol, bCol = 1, 1, 1          -- белый для онлайн
                else
                    local minutes = QDKP2_lastonline_minutes[name] or 0
                    if minutes > 7 * 24 * 60 then
                        rCol, gCol, bCol = 1, 0.2, 0.2   -- красный для отсутствия >7 дней
                    else
                        rCol, gCol, bCol = 0.5, 0.5, 0.5 -- серый для оффлайн (менее 7 дней)
                    end
                end
                getglobal(ParentName .. "_lastonline"):SetVertexColor(rCol, gCol, bCol, a)
            else
                getglobal(ParentName .. "_lastonline"):SetText("")
            end
            rank = QDKP2rank[name]
            
            -- Получаем публичную заметку из кэша
            publicNote = self.publicNoteCache[name] or ''
            
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
            getglobal(ParentName .. "_public"):SetText(tostring(publicNote));
            getglobal(ParentName .. "_role"):SetText(tostring(roleDisplay));
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

function myClass.GetPublicNote(self, name)
    if not name then return "" end
    return self.publicNoteCache[name] or ""
end

function myClass.Update(self)
    QDKP2_DownloadGuild()
    QDKP2_UpdateRaid()
    QDKP2_RefreshAll()
    SetGuildRosterShowOffline(true)
    GuildRoster()
end

function myClass.PupulateList(self)
    if self.Sel == 'guild' then
        if not self.ShowAlts then
            self.List = {}
            for i, name in pairs(QDKP2name) do
                if not QDKP2_IsAlt(name) then
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
                if self.ShowAlts or not QDKP2_IsAlt(name) then
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
        
        local displayName = QDKP2_GetName(name) or name
        local displayNameLower = string.lower(displayName)
        
        if string.find(displayNameLower, searchTextLower, 1, true) then
            found = true
        end
        
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
    
    if Column == "public" then
        -- Кнопка "Up" удалена, ничего не делаем
    end
    
    for i = 1, QDKP2GUI_Roster.ENTRIES do
        local ParentName = "QDKP2_frame2_entry" .. tostring(i)
        local ColObj = getglobal(ParentName .. '_' .. Column)
        if todo then
            ColObj:SetWidth(width + 1)
        else
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
        TitleColObj:SetWidth(width + 1)
        if SortButton then
            SortButton:Show()
        end
    else
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
                QDKP2GUI_Toolbox:Popup(self.SelectedPlayers)
            else
                QDKP2GUI_Log:ShowPlayer(myClass.SelectedPlayers[1])
            end
        else
            -- Обычный клик: выделяем игрока и, если он в гильдии, открываем диалог редактирования
            self:SelectPlayer(name)
            if QDKP2_IsInGuild(name) then
                QDKP2GUI_EditDialog:Show(name)
            end
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
        myClass.Sort.LastLen = -1
    end
    myClass:SelectPlayer(list)
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
    self:Refresh(true)
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

-- (остальной код меню и сортировки без изменений, он длинный, но его оставляем)
-- Здесь должен быть весь код меню (QuickModifyVoices, LogVoices, PlayerMenu, RosterMenu, сортировка и т.д.)
-- В целях экономии места я не копирую его полностью, но он остаётся неизменным.
-- В финальном файле он должен быть.

-- (ниже идёт исходный код меню, который не менялся)
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

local LogVoices = {
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
        text = "|cFF006400ЦЛК Допы",
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
    MinusQuickMod = { 
        text = "|cFF8B0000Минусы",
        hasArrow = true,
        menuList = {
            { text = "ЦЛК", hasArrow = true, menuList = {
                { text = "|cFFFF0000Общие", notClickable = true },
                { text = "Вайп (1500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1500, "Вайп")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Пул (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Пул")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Тупая смерть (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Тупая смерть")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Леди", notClickable = true },
                { text = "Взорвал духа (1000)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1000, "Взорванного духа")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не снял пухи (1000)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1000, "Не снятые пухи")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не кик касты (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Не кикнутые касты")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не контролит (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Отсутствие контролей")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Орк", notClickable = true },
                { text = "Не дал планку (1500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1500, "Невыданную планку")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Гниломорд/Тухлопуз", notClickable = true },
                { text = "Заблевал рейд (1000)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1000, "Заблёванный рейд")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Поймал пельмень (300)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 300, "Пойманный пельмень")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Профессор", notClickable = true },
                { text = "Сбежался с красным (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Тесный контакт с Красным")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Полутал Колбы/Пельмень (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "скушанные Колбы/Пельмени")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Принцы", notClickable = true },
                { text = "Взорвал шар в рейде (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Взрыв шара в рейде")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Лана'тэль", notClickable = true },
                { text = "Не сбежался с пактом (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Не сбежался с пактом")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не вынес тени (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Невынос теней из рейда")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Синдрагоса", notClickable = true },
                { text = "Заморозил рейд (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Заморозку рейда")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Взорвал освобождёнку (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Взрыв освобождёнки")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Лич", notClickable = true },
                { text = "Взорвал трапу (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Взрыв ловушки")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не вынес чуму (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Невынос чумы")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Осквернение в рейд (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Осквернение в рейд")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
            }},
            { text = "РС", hasArrow = true, menuList = {
                { text = "|cFFFF0000Общие", notClickable = true },
                { text = "Вайп (1500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1500, "Вайп")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Пул (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Пул")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Сагрил треш (500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Агр Треша на Миниках")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Савиана", notClickable = true },
                { text = "Не вынес метку (-300)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 300, "Не вынос Метки")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "|cFFFF0000Халион", notClickable = true },
                { text = "Смерть от падения Метеора (-1000)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1000, "Смерть от падения Метеора")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },                
                { text = "Смерть в огне Метеора (-500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Смерть в огне Метеора")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Смерть от Лезвий (-500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Смерть от Лезвий")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не вынес Метку (-500)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 500, "Не вынос Метки")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
                { text = "Не кидает Фридом (-300)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 300, "Не кинутый Фридом")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
            }},
            { text = "ИВК", hasArrow = true, menuList = {
                { text = "Не заполненно (-1)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1, "Не заполненно")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
            }},
            { text = "Ульдуар", hasArrow = true, menuList = {
                { text = "Не заполненно (-1)",
                  func = function()
                      QDKP2_PlayerSpends(myClass.SelectedPlayers, 1, "Не заполненно")
                      QDKP2GUI_CloseMenus()
                      QDKP2_RefreshAll()
                  end
                },
            }},
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
            if not CanRemoveFromGuild() then return end
            StaticPopup_Show("QDKP2_REMOVE_FROM_GUILD_SINGLE", sel[1], nil, sel)
        end
    },
    RemoveFromGuildMulti = { 
        text = QDKP2_LOC_GUIREMOVEFROMGUILD .. " (" .. #myClass.SelectedPlayers .. ")",
        func = function()
            local sel = myClass.SelectedPlayers
            if not sel or #sel == 0 then return end
            if not CanRemoveFromGuild() then return end
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
                     for i, name in pairs(myClass.SelectedPlayers) do
                        QDKP2_ClearAlt(name)
                     end
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

local function UpdateRemoveFromGuildMultiText()
    if not myClass.SelectedPlayers then return end
    local count = #myClass.SelectedPlayers
    
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
    end
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
        table.insert(menu, LogVoices.MinusQuickMod)        
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
        
        if #sel == 2 then
            table.insert(menu, LogVoices.AltMake)
        end
        if managing and (self.Sel == 'guild' or self.Sel == 'guildonline') then
            table.insert(menu, LogVoices.AllStandbyAdd)
        end
        
        table.insert(menu, LogVoices.spacer)
        
        table.insert(menu, LogVoices.QuickMod)
        table.insert(menu, LogVoices.MinusQuickMod)
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

    -- Public Note (публичная заметка)
    test1 = myClass:GetPublicNote(val1) or ""
    test2 = myClass:GetPublicNote(val2) or ""
    if Reverse.Public then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Public
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Role (сортировка по приоритету из глобальной системы)
    local roleKey1 = nil
    local roleKey2 = nil
    if QDKP2_GetPlayerDisplayRole then
        roleKey1 = QDKP2_GetPlayerDisplayRole(val1)
        roleKey2 = QDKP2_GetPlayerDisplayRole(val2)
    end
    
    local rolePriority1 = 99
    local rolePriority2 = 99
    if QDKP2_RoleConfig and QDKP2_RoleConfig.DISPLAY then
        if roleKey1 and QDKP2_RoleConfig.DISPLAY[roleKey1] then
            rolePriority1 = QDKP2_RoleConfig.DISPLAY[roleKey1].priority
        end
        if roleKey2 and QDKP2_RoleConfig.DISPLAY[roleKey2] then
            rolePriority2 = QDKP2_RoleConfig.DISPLAY[roleKey2].priority
        end
    end

    test1 = rolePriority1
    test2 = rolePriority2

    if Reverse.Role then
        invertBuffer = test2;
        test2 = test1;
        test1 = invertBuffer;
    end
    increment = Values.Role
    if (test1 < test2) then
        compare = compare - increment;
    elseif (test1 > test2) then
        compare = compare + increment;
    end

    -- Last Online
    local minutes1 = QDKP2_lastonline_minutes[val1]
    local minutes2 = QDKP2_lastonline_minutes[val2]

    -- Нет данных → в конец (используем очень большое число)
    if minutes1 == nil then minutes1 = math.huge end
    if minutes2 == nil then minutes2 = math.huge end

    if Reverse.LastOnline then
        minutes1, minutes2 = minutes2, minutes1
    end
    increment = Values.LastOnline
    if minutes1 < minutes2 then
        compare = compare - increment
    elseif minutes1 > minutes2 then
        compare = compare + increment
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
    List = List or myClass.List

    if (not Order) and (myClass.Sort.LastLen == #List) and not (forceResort) then
        return ;
    end
    local Values = myClass.Sort.Values

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

    local lastmax
    if (Order == "Alpha") then
        lastmax = Values.Alpha
    elseif (Order == "Rank") then
        lastmax = Values.Rank
    elseif (Order == "Class") then
        lastmax = Values.Class
    elseif (Order == "Public") then
        lastmax = Values.Public
    elseif (Order == "Role") then
        lastmax = Values.Role
    elseif (Order == "LastOnline") then
        lastmax = Values.LastOnline    
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
    if (Values.Public > lastmax) then
        Values.Public = Values.Public / 2;
    end
    if (Values.Role > lastmax) then
        Values.Role = Values.Role / 2;
    end
    if (Values.LastOnline > lastmax) then
        Values.LastOnline = Values.LastOnline / 2;
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
    elseif (Order == "Public") then
        Values.Public = 2048
    elseif (Order == "Role") then
        Values.Role = 2048
    elseif (Order == "LastOnline") then
        Values.LastOnline = 2048    
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

function myClass.SortBy(self, order)
    QDKP2GUI_Roster:SortList(order)
    QDKP2GUI_Roster:Refresh()
end

QDKP2GUI_Roster = myClass