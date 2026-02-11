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

-- Глобальные переменные для отслеживания состояний
QDKP2_ShipBattleCompleted = false
QDKP2_ValithriaHealed = false

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
    if not boss or type(boss) ~= 'string' then
        QDKP2_Debug(1, "Core", "Calling QDKP2_BossKilled with invalid boss: " .. tostring(boss))
        return
    end

    local award
    local DKPType = "DKP_" .. QDKP2_GetInstanceDifficulty()
    zone = zone or GetRealZoneText()
    local zoneEng = QDKP2zoneEnglish[zone] or zone
    zone = string.lower(zone)
    zoneEng = string.lower(zoneEng)

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

-- Обработчик событий
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_MONSTER_YELL" then
        local msg, sender = ...
        
        -- Бой на кораблях - ТОЛЬКО ТОЧНАЯ ФРАЗА
		if (msg == "Ну не говорите потом, что я не предупреждал. Вперед, братья и сестры!" and sender == "Мурадин Бронзобород") or
		   (msg == "Альянс повержен. Вперед, к Королю-личу!" and sender == "Верховный правитель Саурфанг") then
			QDKP2_ShipBattleCompleted = true
			QDKP2_Debug(2, "Core", "Бой на кораблях завершен! Вызываем награду.")
			QDKP2_BossKilled("Бой на Кораблях")
		end
        
        -- Валитрия Сноходица - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Я ИЗЛЕЧИЛАСЬ! Изера, даруй мне силу покончить с этими нечестивыми тварями." and 
           (sender == "Валитрия Сноходица" or sender == "Valithria Dreamwalker") then
            QDKP2_ValithriaHealed = true
            QDKP2_Debug(2, "Core", "Валитрия исцелена! Вызываем награду.")
            QDKP2_BossKilled("Валитрия Сноходица")
        end
        
        -- Чудовища Нордскола - ИВК - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Все чудовища повержены!" and 
           (sender == "Верховный лорд Тирион Фордринг" or sender == "Highlord Tirion Fordring") then
            QDKP2_Debug(2, "Core", "Чудовища повержены! Вызываем награду.")
            QDKP2_BossKilled("Чудовища Нордскола")
        end

        -- Чемпионы Фракций - ИВК - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Пустая и горькая победа. После сегодняшних потерь мы стали слабее как целое. Кто еще, кроме Короля-лича, выиграет от подобной глупости? Пали великие воины. И ради чего? Истинная опасность еще впереди – нас ждет битва с Королем-личом." and 
           (sender == "Верховный лорд Тирион Фордринг" or sender == "Highlord Tirion Fordring") then
            QDKP2_Debug(2, "Core", "Чемпионы повержены! Вызываем награду.")
            QDKP2_BossKilled("Чемпионы фракций")
        end
		
--        -- Валь'киры-близнецы - ИВК - ТОЛЬКО ТОЧНАЯ ФРАЗА
--        if msg == "Плеть не остановить..." and 
--           (sender == "Эйдис Погибель Тьмы" or sender == "Eydis Darkbane") then
--            QDKP2_Debug(2, "Core", "Валь'киры повержены! Вызываем награду.")
--            QDKP2_BossKilled("Валь'киры-близнецы")
--       end
--        -- Валь'киры-близнецы - ИВК - ТОЛЬКО ТОЧНАЯ ФРАЗА
--        if msg == "Король-лич понес тяжелую потерю! Вы проявили себя как бесстрашные герои Серебряного Авангарда! Мы вместе нанесем удар по Цитадели Ледяной Короны и разнесем в клочья остатки Плети! Нет такого испытания, которое мы бы не могли пройти сообща!" and 
--           (sender == "Верховный лорд Тирион Фордринг" or sender == "Highlord Tirion Fordring") then
--            QDKP2_Debug(2, "Core", "Валь'киры повержены! Вызываем награду.")
--            QDKP2_BossKilled("Валь'киры-близнецы")
--        end
		
        -- Железное Собрание - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Вы разгромили Железное Собрание и открыли Архив! Молодцы, ребятки!" and 
           (sender == "Бранн Бронзобород" or sender == "Brann Bronzebeard") then
            QDKP2_Debug(2, "Core", "Железное Собрание повержены! Вызываем награду.")
            QDKP2_BossKilled("Железное собрание")
        end
 
         -- Ходир - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Наконец-то я... свободен от его оков..." and 
           (sender == "Ходир" or sender == "Hodir") then
            QDKP2_Debug(2, "Core", "Ходир повержен! Вызываем награду.")
            QDKP2_BossKilled("Ходир")
        end

         -- Торим - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Придержите мечи! Я сдаюсь." and 
           (sender == "Торим" or sender == "Thorim") then
            QDKP2_Debug(2, "Core", "Торим повержен! Вызываем награду.")
            QDKP2_BossKilled("Торим")
        end

         -- Фрейя - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Он больше не властен надо мной. Мой взор снова ясен. Благодарю вас, герои." and 
           (sender == "Фрейя" or sender == "Freya") then
            QDKP2_Debug(2, "Core", "Фрейя повержена! Вызываем награду.")
            QDKP2_BossKilled("Фрейя")
        end
		
         -- Мимирон - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Очевидно, я совершил небольшую ошибку в расчетах. Пленный злодей затуманил мой разум и заставил меня отклониться от инструкций. Сейчас все системы в норме. Конец связи." and 
           (sender == "Мимирон" or sender == "Mimiron") then
            QDKP2_Debug(2, "Core", "Мимирон повержен! Вызываем награду.")
            QDKP2_BossKilled("Мимирон")
        end
		
         -- Алгалон - Ульдуар - ТОЛЬКО ТОЧНАЯ ФРАЗА
        if msg == "Я видел миры, охваченные пламенем Творцов. Их жители гибли, не успев издать ни звука. Я был свидетелем того, как галактики рождались и умирали в мгновение ока. И все время я оставался холодным... и безразличным. Я. Не чувствовал. Ничего. Триллионы загубленных судеб. Неужели все они были подобны вам? Неужели все они так же любили жизнь?" and 
           (sender == "Алгалон Наблюдатель" or sender == "Algalon the Observer") then
            QDKP2_Debug(2, "Core", "Алгалон повержена! Вызываем награду.")
            QDKP2_BossKilled("Алгалон Наблюдатель")
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
    -- Сохраняем текущее состояние авто-загрузки
    local wasUploading = QDKP2_SENDTRIG_RAIDAWARD
    
    -- Временно отключаем авто-загрузку для основного начисления
    QDKP2_SENDTRIG_RAIDAWARD = false
    
    -- Вызываем оригинальную функцию начисления за босса
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