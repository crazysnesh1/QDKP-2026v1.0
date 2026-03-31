-- Диалог редактирования игрока
QDKP2GUI_EditDialog = {}

-- Инициализация: при закрытии ростера закрываем диалог
local function InitEditDialog()
    if not QDKP2_Frame2 then return end
    local originalOnHide = QDKP2_Frame2:GetScript("OnHide")
    QDKP2_Frame2:SetScript("OnHide", function(self, ...)
        if originalOnHide then
            originalOnHide(self, ...)
        end
        QDKP2GUI_EditDialog:Hide()
    end)
end

-- Ждём загрузки аддона, чтобы QDKP2_Frame2 существовал
local waitFrame = CreateFrame("Frame")
waitFrame:RegisterEvent("ADDON_LOADED")
waitFrame:SetScript("OnEvent", function(self, event, addon)
    if addon == "QDKP2_GUI" then
        InitEditDialog()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

function QDKP2GUI_EditDialog:Show(playerName)
    if not playerName or not IsInGuild() then
        QDKP2_Msg("Невозможно открыть окно: игрок не в гильдии или вы не в гильдии.")
        return
    end

    if not QDKP2_OfficerMode() then
        QDKP2_Msg("У вас нет прав для редактирования гильдейских данных.")
        return
    end

    local frame = QDKP2_EditDialogFrame
    if not frame then
        QDKP2_Msg("Ошибка: не найден фрейм диалога.")
        return
    end

    self.currentPlayer = playerName

    -- Получаем элементы по глобальным именам
    local nameValue = _G["QDKP2_EditDialogFrameNameValue"]
    local rankValue = _G["QDKP2_EditDialogFrameRankValue"]
    local publicEdit = _G["QDKP2_EditDialogFramePublicNoteEdit"]
    local officerEdit = _G["QDKP2_EditDialogFrameOfficerNoteEdit"]

    if not nameValue or not rankValue or not publicEdit or not officerEdit then
        QDKP2_Msg("Ошибка: не найдены элементы диалога.")
        return
    end

    nameValue:SetText(playerName)
    rankValue:SetText(QDKP2rank[playerName] or "Неизвестно")

    local publicNote = QDKP2GUI_Roster.publicNoteCache[playerName] or ""
    local officerNote = self:GetOfficerNote(playerName)

    publicEdit:SetText(publicNote)
    officerEdit:SetText(officerNote)

    self:UpdateButtons()

    frame:Show()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", QDKP2_Frame2, "TOPRIGHT", 0, 0)
    frame:SetUserPlaced(false)
end

-- Обновить состояние кнопок
function QDKP2GUI_EditDialog:UpdateButtons()
    local frame = QDKP2_EditDialogFrame
    if not frame or not self.currentPlayer then return end

    local promoteBtn = _G["QDKP2_EditDialogFramePromoteButton"]
    local demoteBtn = _G["QDKP2_EditDialogFrameDemoteButton"]
    local removeBtn = _G["QDKP2_EditDialogFrameRemoveButton"]
    local inviteBtn = _G["QDKP2_EditDialogFrameInviteButton"]

    if not promoteBtn or not demoteBtn or not removeBtn or not inviteBtn then
        return
    end

    local playerRankIndex = QDKP2rankIndex[self.currentPlayer]
    local myRankIndex = self:GetMyRankIndex()
    local maxRankIndex = 0
    for name, idx in pairs(QDKP2rankIndex) do
        if idx > maxRankIndex then maxRankIndex = idx end
    end

    if playerRankIndex and myRankIndex and playerRankIndex > 0 and myRankIndex < playerRankIndex then
        promoteBtn:Enable()
    else
        promoteBtn:Disable()
    end

    if playerRankIndex and maxRankIndex and playerRankIndex < maxRankIndex then
        demoteBtn:Enable()
    else
        demoteBtn:Disable()
    end

    if self.currentPlayer ~= UnitName("player") and (myRankIndex == 0 or self:CanRemoveFromGuild()) then
        removeBtn:Enable()
    else
        removeBtn:Disable()
    end

    if QDKP2online[self.currentPlayer] and self.currentPlayer ~= UnitName("player") then
        inviteBtn:Enable()
    else
        inviteBtn:Disable()
    end
end

-- Сохранить заметки
function QDKP2GUI_EditDialog:Save()
    if not self.currentPlayer then return end

    local publicEdit = _G["QDKP2_EditDialogFramePublicNoteEdit"]
    local officerEdit = _G["QDKP2_EditDialogFrameOfficerNoteEdit"]

    if not publicEdit or not officerEdit then
        QDKP2_Msg("Ошибка: не найдены поля ввода заметок.")
        return
    end

    local publicNote = publicEdit:GetText()
    local officerNote = officerEdit:GetText()

    local memberIndex = self:GetMemberIndex(self.currentPlayer)
    if not memberIndex then
        QDKP2_Msg("Не удалось найти игрока в гильдии.")
        return
    end

    GuildRosterSetPublicNote(memberIndex, publicNote)
    GuildRosterSetOfficerNote(memberIndex, officerNote)

    QDKP2GUI_Roster.publicNoteCache[self.currentPlayer] = publicNote
    if QDKP2_officerNoteCache then
        QDKP2_officerNoteCache[self.currentPlayer] = officerNote
    end

    QDKP2_Msg("Заметки для " .. self.currentPlayer .. " сохранены.")
    self:Hide()
end

-- Повысить игрока
function QDKP2GUI_EditDialog:Promote()
    if not self.currentPlayer then return end
    if not IsInGuild() then return end
    GuildPromote(self.currentPlayer)
    self:RequestRosterUpdate()
    -- Обновить отображение ранга и кнопок через задержку
    C_Timer.After(0.5, function()
        self:RefreshDisplay()
    end)
end

-- Понизить игрока
function QDKP2GUI_EditDialog:Demote()
    if not self.currentPlayer then return end
    if not IsInGuild() then return end
    GuildDemote(self.currentPlayer)
    self:RequestRosterUpdate()
    C_Timer.After(0.5, function()
        self:RefreshDisplay()
    end)
end

-- Исключить из гильдии
function QDKP2GUI_EditDialog:Remove()
    if not self.currentPlayer then return end
    if not IsInGuild() then return end
    if self.currentPlayer == UnitName("player") then
        QDKP2_Msg("Нельзя исключить себя.")
        return
    end

    StaticPopupDialogs["QDKP2_EDIT_REMOVE_CONFIRM"] = {
        text = "Вы уверены, что хотите исключить " .. self.currentPlayer .. " из гильдии?",
        button1 = "Да",
        button2 = "Нет",
        OnAccept = function()
            GuildUninvite(self.currentPlayer)
            self:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("QDKP2_EDIT_REMOVE_CONFIRM")
end

-- Пригласить в группу
function QDKP2GUI_EditDialog:Invite()
    if not self.currentPlayer then return end
    InviteUnit(self.currentPlayer)
    QDKP2_Msg("Приглашение отправлено " .. self.currentPlayer)
end

-- Скрыть окно
function QDKP2GUI_EditDialog:Hide()
    if QDKP2_EditDialogFrame then
        QDKP2_EditDialogFrame:Hide()
    end
    self.currentPlayer = nil
end

-- Получить индекс игрока в гильдии
function QDKP2GUI_EditDialog:GetMemberIndex(name)
    if not IsInGuild() then return nil end
    local total = GetNumGuildMembers()
    for i = 1, total do
        local memberName, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
        if memberName then
            memberName = strsplit("-", memberName)
            if memberName == name then
                return i
            end
        end
    end
    return nil
end

-- Обновить данные гильдии
function QDKP2GUI_EditDialog:RequestRosterUpdate()
    GuildRoster()
    C_Timer.After(0.5, function()
        if QDKP2GUI_Roster.UpdatePublicNotesCache then
            QDKP2GUI_Roster:UpdatePublicNotesCache()
        end
        if QDKP2GUI_Roster.UpdateLastOnlineData then
            QDKP2GUI_Roster:UpdateLastOnlineData()
        end
        if QDKP2GUI_Roster.Refresh then
            QDKP2GUI_Roster:Refresh()
        end
    end)
end

-- Получить мой ранг
function QDKP2GUI_EditDialog:GetMyRankIndex()
    local myName = UnitName("player")
    return QDKP2rankIndex[myName] or 255
end

-- Проверить права на исключение
function QDKP2GUI_EditDialog:CanRemoveFromGuild()
    return self:GetMyRankIndex() == 0
end

-- Получить офицерскую заметку
function QDKP2GUI_EditDialog:GetOfficerNote(name)
    if IsInGuild() then
        local total = GetNumGuildMembers()
        for i = 1, total do
            local memberName, _, _, _, _, _, _, officernote = GetGuildRosterInfo(i)
            if memberName then
                memberName = strsplit("-", memberName)
                if memberName == name then
                    return officernote or ""
                end
            end
        end
    end
    return ""
end

-- Обновить отображение ранга и кнопок в открытом диалоге
function QDKP2GUI_EditDialog:RefreshDisplay()
    if not self.currentPlayer then return end
    local rankValue = _G["QDKP2_EditDialogFrameRankValue"]
    if rankValue then
        rankValue:SetText(QDKP2rank[self.currentPlayer] or "Неизвестно")
    end
    self:UpdateButtons()
end