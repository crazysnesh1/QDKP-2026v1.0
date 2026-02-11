-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## CORE FUNCTIONS ##
--              Session management
--
--      Functions that start, stop and modify locally created sessions.
--      Includes functions to check for management mode, and relative errors.
--
-- API Documentation:

function QDKP2_StartSession(SessionName)

    QDKP2_Debug(3, "Session", "Asked to start a new session: " .. tostring(SessionName))
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end

    if not QDKP2_IsRaidPresent() then
        QDKP2_Msg(QDKP2_LOC_NotIntoARaid, "ERROR")
        return
    end

    if not QDPK2_ReadGuildInfo then
        QDKP2_Msg("Still waiting to read guild data. Please retry in few seconds.", "ERROR")
        return
    end

    if QDKP2_IsManagingSession() then
        QDKP2_Msg("You are managing an open session. To start annother you first need to close this one.")
        return
    end

    local DefaultSessName = (GetRealZoneText() or UNKNOWN) .. ' (' .. QDKP2_GetInstanceDifficulty() .. ')'

    if SessionName == "" then
        QDKP2_OpenInputBox(QDKP2_LOC_NewSessionQ, QDKP2_StartSession)
        QDKP2_InputBox_SetDefault(DefaultSessName)
        return
    end

    SessionName = SessionName or QDKP2_LOC_NoSessName

    QDKP2_SID.INDEX = QDKP2_SID.INDEX + 1
    SID = tostring(QDKP2_SID.INDEX) .. '.' .. QDKP2_PLAYER_NAME_12
    QDKP2_SID.MANAGING = SID

    --Reset the Raid custom tables
    table.wipe(QDKP2standby)
    table.wipe(QDKP2raidRemoved)

    local msg = string.gsub(QDKP2_LOC_NewSession, "$SESSIONNAME", SessionName)
    QDKP2_Msg(msg)
    QDKP2log_StartSession(QDKP2_SID.MANAGING, SessionName, QDKP2_PLAYER_NAME_12, QDKP2_SID.INDEX)
    local List = QDKP2log_GetSession(SID)
    for i = 1, #QDKP2raid do
        --    local name = QDKP2_GetMain(QDKP2raid[i])
        local name = QDKP2raid[i]
        local online = QDKP2raidOffline[name]
        local name = QDKP2_GetMain(name)
        if not List[name] then
            if online == "online" then
                QDKP2log_Entry(name, QDKP2_LOC_IsInRaid, QDKP2LOG_JOINED)
            else
                QDKP2log_Entry(name, QDKP2_LOC_IsInRaidOffline, QDKP2LOG_LEFT)
            end
        end
    end

    QDKP2_Events:Fire("SESSION_START", SID)
    QDKP2_Events:Fire("DATA_UPDATED", "all")
end

function QDKP2_StopSession(sure)
    local SID = QDKP2_SID.MANAGING
    QDKP2_Debug(2, "Session", "Halting current session " .. tostring(SID))
    if not SID then
        QDKP2_Msg(QDKP2_LOC_GUINOONGOINGSESS)
        return
    end
    
    -- Сначала проверяем IronMan
    if QDKP2_IronManIsOn() and not sure then
        local msg = QDKP2_LOC_CloseIMSessWarn
        QDKP2_AskUser(msg, function() QDKP2_StopSession(true) end)
        return
    end

    -- Затем проверяем роли и показываем диалог
    local roleCount = 0
    if QDKP2GUI_Roster and QDKP2GUI_Roster.PlayerRoles then
        roleCount = QDKP2GUI_Roster:CountRoles()
    end
    
    if roleCount > 0 and not sure then
        local msg = string.format("Вы собираетесь закрыть сессию. Сбросить %d назначенных ролей?", roleCount)
        
        -- Создаем кастомный диалог с двумя кнопками
        StaticPopupDialogs["QDKP2_CLOSE_SESSION_CONFIRM"] = {
            text = msg,
            button1 = "Да, сбросить роли",
            button2 = "Нет, оставить роли", 
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                QDKP2_DoStopSession(true, true) -- закрыть и сбросить роли
            end,
            OnCancel = function()
                QDKP2_DoStopSession(true, false) -- закрыть без сброса ролей
            end
        }
        StaticPopup_Show("QDKP2_CLOSE_SESSION_CONFIRM")
        return
    end
    
    -- Если ролей нет или уже подтверждено, закрываем сессию
    QDKP2_DoStopSession(sure, sure) -- sure определяет сброс ролей
end

-- ОСНОВНАЯ ФУНКЦИЯ ЗАКРЫТИЯ СЕССИИ
function QDKP2_DoStopSession(sure, resetRoles)
    local SID = QDKP2_SID.MANAGING
    if not SID then return end
    
    QDKP2_Debug(2, "Session", "Closing session. Reset roles: " .. tostring(resetRoles))

    -- Выполняем стандартные операции закрытия
    if QDKP2_IronManIsOn() then
        QDKP2_IronManWipe();
    end
    if QDKP2_isTimerOn() then
        QDKP2_TimerOff();
    end
    if QDKP2_BidM_isBidding() then
        QDKP2_BidM_CancelBid();
    end
    QDKP2_BidM_CountdownCancel()

    -- Сбрасываем роли только если нужно
    if resetRoles and QDKP2GUI_Roster and QDKP2GUI_Roster.ResetRolesOnSessionClose then
        QDKP2GUI_Roster:ResetRolesOnSessionClose()
        QDKP2_Msg("Сессия закрыта. Роли сброшены.")
    else
        QDKP2_Msg("Сессия закрыта. Роли сохранены.")
    end

    -- Завершаем сессию
    local SID = QDKP2_OngoingSession()
    QDKP2log_StopSession(QDKP2_SID.MANAGING)

    QDKP2_SID.MANAGING = nil
    QDKP2libs.Timer:CancelTimer(QDKP2_CloseSessionTimer, true)

    -- Сбрасываем таблицы рейда
    table.wipe(QDKP2standby)
    table.wipe(QDKP2raidRemoved)

    QDKP2_Events:Fire("SESSION_END", SID)
    QDKP2_Events:Fire("DATA_UPDATED", "all")
end
-- Команды для закрытия сессии с разными опциями
SLASH_QDKP2_CLOSESESSION1 = "/dkpclose"
SLASH_QDKP2_CLOSESESSION2 = "/closesession"
SlashCmdList["QDKP2_CLOSESESSION"] = function(msg)
    QDKP2_StopSession()
end

SLASH_QDKP2_CLOSESESSION_RESET1 = "/dkpclosereset"
SlashCmdList["QDKP2_CLOSESESSION_RESET"] = function(msg)
    QDKP2_StopSessionWithReset()
end

SLASH_QDKP2_CLOSESESSION_NORESET1 = "/dkpclosenoreset"
SlashCmdList["QDKP2_CLOSESESSION_NORESET"] = function(msg)
    QDKP2_StopSessionWithoutReset()
end

--SID = QDKP2_OngoingSession()
--Returns the ongoing session. If no sessions are active, returns the general session.
function QDKP2_OngoingSession()
    return QDKP2_SID.MANAGING or "0"
end

function QDKP2_OngoingSessionDetails()
    --just an extension of QDKP2_OngoingSession
    --returns List,Name,Mantainer,Code,DateStart,DateStop,DateMod
    local List, Name, Mantainer, Code, DateStart, DateStop, DateMod = QDKP2_GetSessionInfo(QDKP2_OngoingSession())
    if not List then
        QDKP2_Debug(1, "Core", "Can't get data of the ongoing session. I'm closing it (if any)")
        QDKP2_StopSession(sure)
    end
    return List, Name, Mantainer, Code, DateStart, DateStop, DateMod
end

function QDKP2_IsSessionPresent()
    -- This function will return a list of open sessions where you are currently involved.
    -- ATM is same as managingsession as there is no sync.
    return { QDKP2_SID.MANAGING }
end

function QDKP2_IsManagingSession()
    return QDKP2_SID.MANAGING
end

function QDKP2_ManagementMode()
    if QDKP2_IsManagingSession() and QDKP2_OfficerMode() and QDKP2_IsRaidPresent() then
        return true;
    end
    return false
end

function QDKP2_OfficerMode()
    if (QDKP2_OfficerOrPublic == 2 and not CanEditPublicNote()) or
            (QDKP2_OfficerOrPublic ~= 2 and not CanEditOfficerNote()) then
        return
    end
    return true
end

function QDKP2_GetPermissions()
    --prints a list with the status of the rightsyou need to be a DKP officers.
    local CanEditNote, NoteName, CanEditGuildNotes, GotKey
    if QDKP2_OfficerOrPublic == 2 then
        CanEditNote = CanEditPublicNote()
        NoteName = QDKP2_LOC_OfficerEditPublic
    else
        CanEditNote = CanEditOfficerNote()
        NoteName = QDKP2_LOC_OfficerEditOfficer
    end
    if CanEditNote then
        CanEditNote = QDKP2_COLOR_GREEN .. QDKP2_LOC_OfficerEditYes .. QDKP2_COLOR_CLOSE
    else
        CanEditNote = QDKP2_COLOR_RED .. QDKP2_LOC_OfficerEditNo .. QDKP2_COLOR_CLOSE
    end
    local M1 = QDKP2_LOC_OfficerEdit1 .. CanEditNote .. QDKP2_LOC_OfficerEdit2 .. NoteName .. QDKP2_LOC_OfficerEdit3
    return M1
end

function QDKP2_NeedManagementMode()
    QDKP2_Msg(QDKP2_LOC_NeedManagementMode, "WARNING")
end

