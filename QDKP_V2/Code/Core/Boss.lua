-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## ОСНОВНЫЕ ФУНКЦИИ ##
--             Функции награждения за боссов
--
--      Функции для обнаружения, проверки и награждения за убийства боссов
--
-- Документация API:
-- QDKP2_BossKilled(boss): Вызывается когда босс убит. Защищена от повторных вызовов.
-- QDKP2_GetBossAward(boss,[zone]): возвращает награду за убийство <boss> в подземелье <zone>. <zone> устанавливается в GetRealZoneText() если не указан.
-- QDKP2_BossBonusSet(todo) -- Включает/выключает награду за боссов. todo может быть 'on', 'off' или 'toggle'
-- QDKP2_IsInBossTable(boss) -- возвращает true если босс есть в таблице наград за боссов

----------- Убийство босса ----------------------

local boss_translator = {}
boss_translator["Halion the Twilight Destroyer"] = "Halion"
boss_translator["Халион Сумеречный Разрушитель"] = "Halion"
boss_translator["Halion, the Twilight Destroyer"] = "Halion"
boss_translator["Халион, Сумеречный Разрушитель"] = "Halion"
boss_translator["Халион"] = "Halion"
boss_translator["Эйдис Погибель Тьмы"] = "Eydis Darkbane"
boss_translator["Эйдис, Погибель Тьмы"] = "Eydis Darkbane"
boss_translator["Огненный Левиафан"] = "Flame Leviathan"
boss_translator["Flame Leviathan"] = "Flame Leviathan"
boss_translator["Разрушитель XT-002"] = "XT-002 Deconstructor"
boss_translator["XT-002 Deconstructor"] = "XT-002 Deconstructor"
boss_translator["Железное Собрание"] = "The Assembly of Iron"
boss_translator["The Assembly of Iron"] = "The Assembly of Iron"
boss_translator["Ходир"] = "Hodir"
boss_translator["Hodir"] = "Hodir"
boss_translator["Торим"] = "Thorim"
boss_translator["Thorim"] = "Thorim"
boss_translator["Фрейя"] = "Freya"
boss_translator["Freya"] = "Freya"
boss_translator["Мимирон"] = "Mimiron"
boss_translator["Mimiron"] = "Mimiron"
boss_translator["Генерал Везакс"] = "General Vezax"
boss_translator["General Vezax"] = "General Vezax"
boss_translator["Йогг-Сарон"] = "Yogg-Saron"
boss_translator["Yogg-Saron"] = "Yogg-Saron"
--boss_translator["Боевой корабль"] = "Icecrown Gunship Battle"
--boss_translator["Бой на кораблях"] = "Icecrown Gunship Battle"
--boss_translator["Gunship Battle"] = "Icecrown Gunship Battle"
--boss_translator["The Skybreaker"] = "Icecrown Gunship Battle"
--boss_translator["Усмиритель небес"] = "Icecrown Gunship Battle"
--boss_translator["Orgrim's Hammer"] = "Icecrown Gunship Battle"
--boss_translator["Молот Оргрима"] = "Icecrown Gunship Battle"
--boss_translator["Валь'киры-близнецы"] = "Val'kyr Twins"
--boss_translator["Эйдис Погибель Тьмы"] = "Val'kyr Twins"
--boss_translator["Эйдис, Погибель Тьмы"] = "Val'kyr Twins"
--boss_translator["Чудовища Нордскола"] = "Northrend Beasts"
--boss_translator["Королева Лана'тель"] = "Blood-Queen Lana'thel"
--boss_translator["Кровавая королева Лана'тель"] = "Blood-Queen Lana'thel"
--boss_translator["Кровавый Совет"] = "Blood Prince Council"
--boss_translator["Совет Принцев Крови"] = "Blood Prince Council"


local specialBossHandlers = {
    -- ЦЛК
    ["Icecrown Gunship Battle"] = function()
        -- АДАПТИРУЙТЕ: Проверьте как определяется завершение на вашем сервере
        return not UnitExists("boss1") or QDKP2_ShipBattleCompleted
    end,
    ["Valithria Dreamwalker"] = function()
        -- АДАПТИРУЙТЕ: Проверьте механику исцеления
        return QDKP2_ValithriaHealed or not UnitExists("boss1")
    end
}

QDKP2_UlduarHM_Flags = {
    ["Flame Leviathan"] = false,
    ["XT-002 Deconstructor"] = false,
    ["The Assembly of Iron"] = false,
    ["Hodir"] = false,
    ["Thorim"] = false,
    ["Freya"] = false,
    ["Mimiron"] = false,
    ["General Vezax"] = false,
    ["Yogg-Saron"] = false,
}

AssemblyDeaths = { 
    ["Steelbreaker"] = false, 
    ["Runemaster Molgeim"] = false, 
    ["Stormcaller Brundir"] = false 
}

QDKP2_HodirStartTime = 0
QDKP2_ShipBattleCompleted = false
QDKP2_ValithriaHealed = false
QDKP2_FreyaHMTime = 0

-- Регистрация DBM для Халиона
local QDKP2_DBMHalionHookRegistered = false
local function QDKP2_DBMKillCallback(event, mod)
    if event ~= "DBM_Kill" or not mod then return end
    local modId = string.lower(tostring(mod.id or ""))
    local modName = string.lower(tostring(mod.localization and mod.localization.general and mod.localization.general.name or ""))

    if modId == "halion" or string.find(modName, "халион") or string.find(modName, "halion") then
        QDKP2_BossKilled("Halion")
    end
end

local function QDKP2_RegisterDBMHalionHook()
    if QDKP2_DBMHalionHookRegistered then return end
    if DBM and DBM.RegisterCallback then
        DBM:RegisterCallback("DBM_Kill", QDKP2_DBMKillCallback)
        QDKP2_DBMHalionHookRegistered = true
    end
end

if DBM then
    if DBM.RegisterOnLoadCallback then DBM:RegisterOnLoadCallback(QDKP2_RegisterDBMHalionHook)
    elseif DBM.RegisterCallback then QDKP2_RegisterDBMHalionHook() end
end

function QDKP2_CheckSpecialBoss(boss)
    if specialBossHandlers[boss] then
        local result = specialBossHandlers[boss]()
        QDKP2_Debug(2, "Core", "Проверка особого босса " .. boss .. ": " .. tostring(result))
        return result
    end
    return true -- обычные боссы всегда считаются убитыми
end

function QDKP2_BossKilled(boss)
    -- Добавьте проверку на особых боссов
    if specialBossHandlers[boss] then
        QDKP2_Debug(3, "Core", "Обнаружен особый босс: " .. boss)
        -- Для особых боссов используем специальную проверку
        if not QDKP2_CheckSpecialBoss(boss) then
            QDKP2_Debug(2, "Core", "Особый босс " .. boss .. " еще не побежден")
            return
        end
    end
    -- Вызывается в основном по событию, запускает награду за босса если <boss> есть в таблице QDKP2_Bosses.
    -- uses libBabble-Bosses for locales.
    QDKP2_Debug(3, "Core", boss .. " has died")
    if not QDKP2_ManagementMode() then
        QDKP2_Debug(3, "Core", "Quitting Boss award because you aren't in management mode")
        return
    end
    if not boss or type(boss) ~= 'string' then
        QDKP2_Debug(1, "Core", "Calling QDKP2_BossKilled with invalid boss: " .. tostring(boss))
        return
    end

    boss = boss_translator[boss] or boss

    if QDKP2_BossKilledTime and time() - QDKP2_BossKilledTime < 60 then
        -- устанавливает 1-минутное "время восстановления" между наградами за боссов чтобы избежать множественных наград
        --coming for various sources (DBM, BigWigs or simple slain detector)
        QDKP2_Debug(2, "Core", "Got " .. boss .. " kill trigger, but BossKill is in cooldown.")
        return
    else
        QDKP2_BossKilledTime = time()
    end

    local award = QDKP2_GetBossAward(boss)
	QDKP2_Debug(2, "Core", boss .. " award is "..tostring(award).." DKP")

    if award then
        QDKP2log_Entry("RAID", boss, QDKP2LOG_BOSS)
        if QDKP2_AutoBossEarn then
            --if the Boss Award is on
            local mess = string.gsub(QDKP2_LOC_BossKill, '$BOSS', boss)
            QDKP2_Msg(QDKP2_COLOR_BLUE .. mess)
            local reason = string.gsub(QDKP2_LOC_Kill, '$BOSS', boss)
            QDKP2_RaidAward(award, reason) --give DKP to the raid
        end
        if QDKP2_PROMPT_AWDS and not QDKP2_DetectBids then
            QDKP2_AskUser(QDKP2_LOC_WinDetect_Q, QDKP2_DetectBidSet, 'on')
        end
    end
    QDKP2_Events:Fire("DATA_UPDATED", "log")
end

function QDKP2_GetBossAward(boss, zone)
    if not boss or type(boss) ~= 'string' then return end

    local diff = QDKP2_GetInstanceDifficulty() 
    local DKPType = "DKP_" .. diff
    
    zone = zone or GetRealZoneText()
    local zoneEng = QDKP2zoneEnglish[zone] or zone
    zone = string.lower(zone)
    zoneEng = string.lower(zoneEng)

    if zone == "ульдуар" or zoneEng == "ulduar" then
        local isHardMode = false
        local checkBoss = boss_translator[boss] or boss -- используем внутреннее имя

        -- Проверка Ходира
        if (checkBoss == "Hodir") and QDKP2_HodirStartTime > 0 then
            if (GetTime() - QDKP2_HodirStartTime) <= 180 then
                isHardMode = true
            end
        end

        -- Безопасная проверка флагов по конкретному имени
        if QDKP2_UlduarHM_Flags[checkBoss] then
            isHardMode = true
        end

        if isHardMode then
            -- Переключаем типы: 1->3 (10H), 2->4 (25H) или по строкам N->H
            if DKPType == "DKP_1" then DKPType = "DKP_3"
            elseif DKPType == "DKP_2" then DKPType = "DKP_4"
            elseif string.match(DKPType, "10N") then DKPType = "DKP_10H"
            elseif string.match(DKPType, "25N") then DKPType = "DKP_25H"
            end
            QDKP2_Debug(2, "Core", "Ульдуар: Обнаружен ХАРДМОД для " .. boss)
        end
    end

    local award

    -- поиск конкретной награды за босса
    award = QDKP2_IsInBossTable(boss, DKPType)
    if award then
        QDKP2_Debug(2, "Core", "Specific DKP award for " .. boss .. "(" .. DKPType .. ") is " .. tostring(award))
        return award
    end

    -- поиск награды по умолчанию для подземелья
    for i, InstanceDKP in ipairs(QDKP2_Instances) do
        local DKPzone = string.lower(InstanceDKP.name or '-')
        if DKPzone == zone or DKPzone == zoneEng then
            award = InstanceDKP[DKPType]
            QDKP2_Debug(2, "Core", "Instance default DKP award for " .. boss .. "(" .. DKPType .. ") is " .. tostring(award))
            return award
        end
    end
end

function QDKP2_IsInBossTable(boss, DKPType)
    local DKPType = DKPType or "DKP_" .. QDKP2_GetInstanceDifficulty()
    boss = boss_translator[boss] or boss
    local bossEng = QDKP2bossEnglish[boss] or boss
    boss = string.lower(boss)
    bossEng = string.lower(boss_translator[bossEng] or bossEng)
    for i, BossDKP in ipairs(QDKP2_Bosses) do
        local DKPboss = string.lower(BossDKP.name or '-')
        if DKPboss == boss or DKPboss == bossEng then
            return BossDKP[DKPType]
        end
    end
	QDKP2_Debug(2, "Core", tostring(boss) .. " (" .. tostring(bossEng) .. ") not found in QDKP2_Bosses")
end

function QDKP2_BossBonusSet(todo)
    if todo == "toggle" then
        if QDKP2_AutoBossEarn then
            QDKP2_BossBonusSet("off")
        else
            QDKP2_BossBonusSet("on")
        end
    elseif todo == "on" then
        QDKP2_AutoBossEarn = true
        QDKP2_Events:Fire("BOSSBONUS_ON")
        QDKP2_Msg(QDKP2_COLOR_YELLOW .. QDKP2_LOC_GUIBOSSAWARDON)
    elseif todo == "off" then
        QDKP2_AutoBossEarn = false
        QDKP2_Events:Fire("BOSSBONUS_OFF")
        QDKP2_Msg(QDKP2_COLOR_YELLOW .. QDKP2_LOC_GUIBOSSAWARDOFF)
    end
end

function QDKP2_ForceBossKill(bossName)
    QDKP2_Debug(2, "Core", "Принудительный вызов награды для босса: " .. bossName)
    QDKP2_BossKilled(bossName)
end

-- 1. Таблица флагов и отладка
QDKP2_UlduarHM_Flags = QDKP2_UlduarHM_Flags or {}

local function UlduarDebug(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[QDKP2 Ulduar]:|r " .. msg)
end

-------------------------------------------------------
-- ГЛАВНЫЙ ОБРАБОТЧИК СОБЫТИЙ (Триггеры боссов)
-------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- 1. НАЧАЛО БОЯ
    if event == "PLAYER_REGEN_DISABLED" then
        -- Сброс флагов с защитой Мимирона и Фрейи
        for k in pairs(QDKP2_UlduarHM_Flags) do 
            if k == "Mimiron" and (GetTime() - (QDKP2_MimironButtonTime or 0)) < 180 then
                -- Флаг Мимирона не трогаем
            elseif k == "Freya" and (GetTime() - (QDKP2_FreyaHMTime or 0)) < 180 then
                -- Флаг Фрейи не трогаем
            else
                QDKP2_UlduarHM_Flags[k] = false 
            end
        end
        for k in pairs(AssemblyDeaths) do AssemblyDeaths[k] = false end
        QDKP2_HodirStartTime = GetTime()
        
        -- Проверка локации Йогг-Сарона
        local subzone = GetMinimapZoneText()
        if subzone == "Темница Йогг-Сарона" or subzone == "The Prison of Yogg-Saron" then
            -- Запускаем проверку через 3 секунды после начала боя, чтобы баффы успели прогрузиться
            C_Timer.After(3, function()
                local hasKeeper = false
                local keepers = {
                    [62671] = true, -- Скорость изобретения
                    [62702] = true, -- Гнев бури
                    [62670] = true, -- Устойчивость природы
                    [62650] = true  -- Стойкость льдов
                }

                for i = 1, 40 do
                    local name = UnitBuff("player", i)
                    if not name then break end
                    for id in pairs(keepers) do
                        if name == GetSpellInfo(id) then
                            hasKeeper = true
                            break
                        end
                    end
                    if hasKeeper then break end
                end
                
                if not hasKeeper then
                    QDKP2_UlduarHM_Flags["Yogg-Saron"] = true
                    UlduarDebug("Йогг-Сарон: ХМ (0 света) определен.")
                else
                    QDKP2_UlduarHM_Flags["Yogg-Saron"] = false
                    UlduarDebug("Йогг-Сарон: ОБЫЧКА (есть помощь хранителей).")
                end
            end)
        end
    end

-- 2. ЛОГ БОЯ
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, logType, _, _, _, _, destName, _, spellId = ...

        -- Левиафан (Твои ID: 65077, 65075, 65076, 64482)
        if spellId == 65077 or spellId == 65075 or spellId == 65076 or spellId == 64482 then
            if not QDKP2_UlduarHM_Flags["Flame Leviathan"] then
                QDKP2_UlduarHM_Flags["Flame Leviathan"] = true
                UlduarDebug("Огненный Левиафан: ХМ определен по ID " .. spellId)
            end
        end

        -- XT-002 (Твой ID: 64193 - бафф Heartbreak на боссе)
        if spellId == 64193 and (logType == "SPELL_AURA_APPLIED" or logType == "SPELL_CAST_SUCCESS") then
            if not QDKP2_UlduarHM_Flags["XT-002 Deconstructor"] then
                QDKP2_UlduarHM_Flags["XT-002 Deconstructor"] = true
                UlduarDebug("XT-002: ХМ определен (Сердце разбито)")
            end
        end

		-- Железное Собрание: Отслеживание смертей
        if logType == "UNIT_DIED" then
            if destName == "Сталелом" or destName == "Steelbreaker" then 
                AssemblyDeaths["Steelbreaker"] = true
            elseif destName == "Мастер рун Молгейм" or destName == "Runemaster Molgeim" then 
                AssemblyDeaths["Runemaster Molgeim"] = true
            elseif destName == "Буревестник Брундир" or destName == "Stormcaller Brundir" then 
                AssemblyDeaths["Stormcaller Brundir"] = true 
            end

            -- Проверяем, умерли ли все трое
            if AssemblyDeaths["Steelbreaker"] and AssemblyDeaths["Runemaster Molgeim"] and AssemblyDeaths["Stormcaller Brundir"] then
                -- Условие ХМ: Сталелом должен быть последним (текущим destName)
                if destName == "Сталелом" or destName == "Steelbreaker" then
                    QDKP2_UlduarHM_Flags["The Assembly of Iron"] = true
                    UlduarDebug("Железное Собрание: ХМ (Сталелом убит последним)")
                else
                    QDKP2_UlduarHM_Flags["The Assembly of Iron"] = false
                    UlduarDebug("Железное Собрание: ОБЫЧКА (последним убит " .. (destName or "неизвестно") .. ")")
                end
                
                QDKP2_BossKilled("The Assembly of Iron")
                -- Сброс, чтобы не сработало дважды за бой
                for k in pairs(AssemblyDeaths) do AssemblyDeaths[k] = false end
            end
        end
				
        -- Фрейя (Сущности)
        if spellId == 65761 or spellId == 65590 or spellId == 65586 then
            QDKP2_FreyaHMTime = GetTime() -- Засекаем время прока ХМ
            if not QDKP2_UlduarHM_Flags["Freya"] then
                QDKP2_UlduarHM_Flags["Freya"] = true
                UlduarDebug("Фрейя: ХМ определен.")
            end
        end

        -- Везакс (Саронитовый враг)
        if destName == "Саронитовый враг" or destName == "Saronite Animus" then
            if not QDKP2_UlduarHM_Flags["General Vezax"] then
                QDKP2_UlduarHM_Flags["General Vezax"] = true
                UlduarDebug("Везакс: Появился Саронитовый враг. ХМ активирован.")
            end
        end
    end

-- 3. КРИКИ МОНСТРОВ
    if event == "CHAT_MSG_MONSTER_YELL" then
        local msg, sender = ...
        if not msg then return end

		-- ТОРИМ (Крик Сиф)
        if string.find(msg, "Это невозможно! Торим, не сомневайся") or string.find(msg, "It is impossible") then
            QDKP2_UlduarHM_Flags["Thorim"] = true
            UlduarDebug("Торим: ХМ активирован (Сиф вступила в бой).")
        end
		
        -- Мимирон (Красная кнопка)
        if string.find(msg, "НЕ НАЖИМАЙТЕ ЭТУ КНОПКУ!") or string.find(msg, "DO NOT PUSH THIS BUTTON!") then
            QDKP2_UlduarHM_Flags["Mimiron"] = true
            UlduarDebug("Мимирон: ХМ активирован.")
        end

        -- Ходир (Таймер)
        if msg == "Вы будете наказаны за это вторжение!" or msg == "You will suffer for this trespass!" then
            QDKP2_HodirStartTime = GetTime()
        end

        -- Корабли
        if (msg == "Ну не говорите потом, что я не предупреждал. Вперед, братья и сестры!" and sender == "Мурадин Бронзобород") or
           (msg == "Альянс повержен. Вперед, к Королю-личу!" and sender == "Верховный правитель Саурфанг") then
            QDKP2_ShipBattleCompleted = true
            QDKP2_BossKilled("Icecrown Gunship Battle")
        end
        
		-- Валитрия
        if msg == "Я ИЗЛЕЧИЛАСЬ! Изера, даруй мне силу покончить с этими нечестивыми тварями." and 
           (sender == "Валитрия Сноходица" or sender == "Valithria Dreamwalker") then
            QDKP2_ValithriaHealed = true
            QDKP2_BossKilled("Valithria Dreamwalker")
        end
        
		-- Чудовища Нордскола
        if msg == "Все чудовища повержены!" and 
           (sender == "Верховный лорд Тирион Фордринг" or sender == "Highlord Tirion Fordring") then
            QDKP2_BossKilled("Northrend Beasts")
        end

		-- Чемпионы фракций
        if msg == "Пустая и горькая победа. После сегодняшних потерь мы стали слабее как целое. Кто еще, кроме Короля-лича, выиграет от подобной глупости? Пали великие воины. И ради чего? Истинная опасность еще впереди – нас ждет битва с Королем-личом." and 
           (sender == "Верховный лорд Тирион Фордринг" or sender == "Highlord Tirion Fordring") then
            QDKP2_BossKilled("Faction Champions")
        end
        
		-- Ходир
        if msg == "Наконец-то я... свободен от его оков..." and 
           (sender == "Ходир" or sender == "Hodir") then
            QDKP2_BossKilled("Hodir")
        end
		
		-- Торим
        if msg == "Придержите мечи! Я сдаюсь." and 
           (sender == "Торим" or sender == "Thorim") then
            QDKP2_BossKilled("Thorim")
        end

		-- Фрея
        if msg == "Он больше не властен надо мной. Мой взор снова ясен. Благодарю вас, герои." and 
           (sender == "Фрейя" or sender == "Freya") then
            QDKP2_BossKilled("Freya")
        end
        
		-- Мимирон
        if msg == "Очевидно, я совершил небольшую ошибку в расчетах. Пленный злодей затуманил мой разум и заставил меня отклониться от инструкций. Сейчас все системы в норме. Конец связи." and 
           (sender == "Мимирон" or sender == "Mimiron") then
            QDKP2_BossKilled("Mimiron")
        end
        
		-- Алгалон
        if msg == "Я видел миры, охваченные пламенем Творцов. Их жители гибли, не успев издать ни звука. Я был свидетелем того, как галактики рождались и умирали в мгновение ока. И все время я оставался холодным... и безразличным. Я. Не чувствовал. Ничего. Триллионы загубленных судеб. Неужели все они были подобны вам? Неужели все они так же любили жизнь?" and 
           (sender == "Алгалон Наблюдатель" or sender == "Algalon the Observer") then
            QDKP2_BossKilled("Algalon the Observer")
        end        
    end
end)

-- Функция сброса состояний
function QDKP2_ResetSpecialBosses()
    QDKP2_ShipBattleCompleted = false
    QDKP2_ValithriaHealed = false
    QDKP2_Debug(2, "Core", "Состояния особых боссов сброшены")
end

-- Интеграция с системой бонусов за роли
function QDKP2_GetFullBossAward(boss, difficulty)
    -- Возвращает полную награду за босса (базовая + бонусы за роли)
    local baseAward = QDKP2_GetBossAward(boss, difficulty)
    local roleBonuses = QDKP2_GetRoleBonusForBoss(boss, difficulty)
    
    return baseAward, roleBonuses
end

-- Переопределяем QDKP2_BossKilled для поддержки бонусов за роли
local original_BossKilled = QDKP2_BossKilled

function QDKP2_BossKilled(boss)
    -- Проверяем кулдаун прямо в обертке. Если с прошлого убийства прошло меньше 60 сек, 
    -- блокируем выполнение, чтобы не выдать двойные роли.
    if QDKP2_BossKilledTime and time() - QDKP2_BossKilledTime < 60 then
        QDKP2_Debug(2, "Core", "Повторный вызов убийства босса. Блокируем двойное начисление ролей.")
        return 
    end

    -- Сохраняем текущее состояние авто-загрузки
    local wasUploading = QDKP2_SENDTRIG_RAIDAWARD
    
    -- Временно отключаем авто-загрузку для основного начисления
    QDKP2_SENDTRIG_RAIDAWARD = false
    
    -- Вызываем оригинальную функцию начисления за босса.
    -- (Она отработает и сама обновит таймер QDKP2_BossKilledTime = time())
    original_BossKilled(boss)
    
    -- Добавляем бонусы за роли после основной награды
    if QDKP2_RoleBonus and QDKP2_RoleBonus.enabled and QDKP2_ManagementMode() then
        QDKP2_Debug(2, "Core", "Начисление бонусов за роли за босса: " .. boss)
        local difficulty = QDKP2_GetInstanceDifficulty()
        QDKP2_AwardRoleBonus(boss, difficulty)
    end
    
    -- Восстанавливаем состояние авто-загрузки и выполняем одну общую загрузку
    QDKP2_SENDTRIG_RAIDAWARD = wasUploading
    if wasUploading then
        QDKP2_UploadAll()
    end
    
    QDKP2_Debug(2, "Core", "Завершено комбинированное начисление за босса и роли")
end