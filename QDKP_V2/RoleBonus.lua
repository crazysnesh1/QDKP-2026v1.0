-- Copyright 2010 Riccardo Belloli (belloli@email.it)
-- This file is a part of QDKP_V2 (see about.txt in the Addon's root folder)

--             ## СИСТЕМА БОНУСОВ ЗА РОЛИ ##
--             Бонусные награды за БИС/ТАНК/ХИЛ роли
--

-- Таблица перевода имен боссов для системы бонусов за роли
local role_boss_translator = {
    -- Icecrown Citadel (ЦЛК)
--    ["Лорд Ребрад"] = "Lord Marrowgar",
--    ["Леди Смертный Шепот"] = "Lady Deathwhisper",
--    ["Бой на кораблях"] = "Icecrown Gunship Battle",
--    ["Завоеватель Дракономор"] = "Icecrown Gunship Battle", -- альтернативный перевод
--    ["Саурфанг Смертоносный"] = "Deathbringer Saurfang",
--    ["Трухлявый"] = "Festergut",
--    ["Гниломорд"] = "Rotface",
--    ["Профессор Мерзоцид"] = "Professor Putricide",
--    ["Принц Валанар"] = "Prince Valanar",
--    ["Кровавая королева Лана'тель"] = "Blood-Queen Lana'thel",
--    ["Валитрия Сноходица"] = "Valithria Dreamwalker",
--    ["Синдрагоса"] = "Sindragosa",
--   ["Король-лич"] = "The Lich King",
    
    -- Ruby Sanctum (РС)
    ["Халион"] = "Halion",
    ["Халион Сумеречный Разрушитель"] = "Halion",
    
    -- Trial of the Crusader (Испытание крестоносца)
    ["Чудовища Нордскола"] = "Northrend Beasts",
    ["Лорд Джараксус"] = "Lord Jaraxxus",
    ["Чемпионы фракций"] = "Faction Champions",
    ["Валь'киры-близнецы"] = "The Twin Val'kyr",
    ["Эйдис Погибель Тьмы"] = "The Twin Val'kyr", -- одна из близнецов
    ["Фьола Погибель Света"] = "The Twin Val'kyr", -- вторая из близнецов
	["Эйдис Погибель Тьмы"] = "Eydis Darkbane",
	["Эйдис, Погибель Тьмы"] = "Eydis Darkbane",
    ["Ануб'арак"] = "Anub'arak"
}

-- Функция для нормализации имени босса с использованием перевода
local function NormalizeBossName(bossName)
    if not bossName or type(bossName) ~= 'string' then
        return bossName
    end
    
    -- Сначала проверяем локальную таблицу переводов
    local normalized = role_boss_translator[bossName] or bossName
    
    -- Затем используем библиотеку LibBabble если доступна
    if QDKP2bossEnglish then
        normalized = QDKP2bossEnglish[normalized] or normalized
    end
    
    QDKP2_Debug(3, "RoleBonus", "Нормализация имени босса: '" .. bossName .. "' -> '" .. normalized .. "'")
    return normalized
end

QDKP2_RoleBonus = {
    enabled = true,
    config = {
        BIS = {
            name = "БИС",
            color = { r = 1, g = 0.84, b = 0 },
            DKP_10N = 0,
            DKP_10H = 0,
            DKP_25N = 0,
            DKP_25H = 0
        },
        TANK_HEAL = {
            name = "ТАНК/ХИЛ", 
            color = { r = 0, g = 0.8, b = 1 },
            DKP_10N = 0,
            DKP_10H = 0,
            DKP_25N = 0,
            DKP_25H = 0
        },
        BIS_TANK_HEAL = {
            name = "БИС ТАНК/ХИЛ",
            color = { r = 0, g = 1, b = 0 },
            DKP_10N = 0,
            DKP_10H = 0,
            DKP_25N = 0,
            DKP_25H = 0
        }
    }
}

-- Таблица бонусов за роли по боссам с разделением сложностей
QDKP2_RoleBonusBosses = {
    -- Icecrown Citadel (ЦЛК)
    { name = "--Icecrown Citadel--" },
    
    { name = "Lord Marrowgar", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Lady Deathwhisper", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Icecrown Gunship Battle", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Deathbringer Saurfang", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Festergut", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Rotface", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Professor Putricide", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Prince Valanar", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Blood-Queen Lana'thel", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Valithria Dreamwalker", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "Sindragosa", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 10, BIS_25H = 25,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 25, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 40, BIS_TANK_HEAL_25H = 90 },
    
    { name = "The Lich King", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 90, BIS_25H = 125,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 125, TANK_HEAL_25H = 140, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 160, BIS_TANK_HEAL_25H = 210 },
		
	-- Ruby Sanctum (РС)
    { name = "----Ruby Sanctum----" },
    
    { name = "Halion", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 100, BIS_25H = 200,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 200, TANK_HEAL_25H = 400, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 300, BIS_TANK_HEAL_25H = 600 },

	-- Trial of the Crusader (РС)
    { name = "--------TotC--------" },
    
    { name = "Northrend Beasts", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 0, BIS_25H = 20,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 0, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 0, BIS_TANK_HEAL_25H = 80 },
		
	{ name = "Lord Jaraxxus", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 0, BIS_25H = 20,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 0, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 0, BIS_TANK_HEAL_25H = 80 },

    { name = "Faction Champions", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 0, BIS_25H = 20,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 0, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 0, BIS_TANK_HEAL_25H = 80 },

    { name = "Eydis Darkbane", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 0, BIS_25H = 20,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 0, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 0, BIS_TANK_HEAL_25H = 80 },

    { name = "Anub'arak", 
        BIS_10N = 0, BIS_10H = 0,
        BIS_25N = 0, BIS_25H = 20,
        TANK_HEAL_10N = 0, TANK_HEAL_10H = 0, 
        TANK_HEAL_25N = 0, TANK_HEAL_25H = 60, 
        BIS_TANK_HEAL_10N = 0, BIS_TANK_HEAL_10H = 0, 
        BIS_TANK_HEAL_25N = 0, BIS_TANK_HEAL_25H = 80 },	
}

-- Глобальные функции для работы с ролями (интеграция с Roster.lua)
function QDKP2_GetRoleBonusForBoss(boss, difficulty)
    -- Возвращает бонусы за роли для конкретного босса и сложности
    if not QDKP2_RoleBonus.enabled then return {} end
    
    difficulty = difficulty or "25N" -- по умолчанию 25 обычный
    
    -- Нормализуем имя босса перед поиском
    local normalizedBoss = NormalizeBossName(boss)
    
    local bonuses = {}
    local bossFound = false
    
    -- Поиск босса в таблице
    for _, bossData in ipairs(QDKP2_RoleBonusBosses) do
        if bossData.name == normalizedBoss then
            bossFound = true
            for roleKey, roleConfig in pairs(QDKP2_RoleBonus.config) do
                local bonusField = roleKey .. "_" .. difficulty
                local bonusAmount = bossData[bonusField]
                if bonusAmount and bonusAmount > 0 then
                    bonuses[roleKey] = {
                        amount = bonusAmount,
                        name = roleConfig.name,
                        color = roleConfig.color
                    }
                end
            end
            break
        end
    end
    
    if not bossFound then
        QDKP2_Debug(2, "RoleBonus", "Босс " .. normalizedBoss .. " (оригинал: " .. boss .. ") не найден в таблице бонусов за роли")
    end
    
    return bonuses
end

function QDKP2_AwardRoleBonus(boss, difficulty)
    print("QDKP2: AwardRoleBonus вызвана для " .. boss .. ", сложность: " .. tostring(difficulty))
    -- Начисляет бонусы за роли за убийство босса
    if not QDKP2_RoleBonus.enabled then
        QDKP2_Debug(2, "RoleBonus", "Бонусы за роли отключены")
        return
    end
    
    if not QDKP2_ManagementMode() then
        QDKP2_Debug(2, "RoleBonus", "Не в режиме управления")
        return
    end
    
    local bonuses = QDKP2_GetRoleBonusForBoss(boss, difficulty)
    if not bonuses or not next(bonuses) then
        QDKP2_Debug(2, "RoleBonus", "Нет бонусов за роли для " .. boss)
        return
    end
    
    local awardedPlayers = {}
    local totalAwarded = 0
    
    -- Получаем список игроков в рейде
    for i = 1, QDKP2_GetNumRaidMembers() do
        local name = QDKP2_GetRaidRosterInfo(i)
        if name and QDKP2_IsInGuild(name) then
            -- Используем существующую систему ролей из Roster.lua
            local role = (QDKP2GUI_Roster and QDKP2GUI_Roster.PlayerRoles and QDKP2GUI_Roster.PlayerRoles[name]) or 
             (QDKP2_RosterRolesDB and QDKP2_RosterRolesDB[name])
            if role and bonuses[role] then
                local bonusInfo = bonuses[role]
                local reason = string.format("Бонус %s за %s", bonusInfo.name, boss)
                
                QDKP2_AddTotals(name, bonusInfo.amount, 0, 0, reason)
                table.insert(awardedPlayers, {
                    name = name,
                    role = bonusInfo.name,
                    amount = bonusInfo.amount
                })
                totalAwarded = totalAwarded + bonusInfo.amount
                
                QDKP2_Debug(2, "RoleBonus", string.format("Начислен бонус %s DKP игроку %s за роль %s", 
                    bonusInfo.amount, name, bonusInfo.name))
            end
        end
    end
    
    -- Логируем общее начисление
    if #awardedPlayers > 0 then
        local roleText = ""
        for _, player in ipairs(awardedPlayers) do
            roleText = roleText .. string.format("%s (%s: +%s) ", player.name, player.role, player.amount)
        end
        
        QDKP2log_Entry("RAID", string.format("Бонусы за роли за %s: %s", boss, roleText), QDKP2LOG_BOSS)
        QDKP2_Msg(QDKP2_COLOR_GREEN .. string.format("Начислены бонусы за роли за %s: %d игроков (+%d DKP)", 
            boss, #awardedPlayers, totalAwarded))
    else
        QDKP2_Debug(2, "RoleBonus", "Нет игроков с назначенными ролями для бонусов")
    end
    
    QDKP2_Events:Fire("DATA_UPDATED", "roster")
end

function QDKP2_RoleBonusSet(todo)
    -- Включает/выключает систему бонусов за роли
    if todo == "toggle" then
        if QDKP2_RoleBonus.enabled then
            QDKP2_RoleBonusSet("off")
        else
            QDKP2_RoleBonusSet("on")
        end
    elseif todo == "on" then
        QDKP2_RoleBonus.enabled = true
        QDKP2_Events:Fire("ROLEBONUS_ON")
        QDKP2_Msg(QDKP2_COLOR_GREEN .. "Бонусы за роли включены")
    elseif todo == "off" then
        QDKP2_RoleBonus.enabled = false
        QDKP2_Events:Fire("ROLEBONUS_OFF")
        QDKP2_Msg(QDKP2_COLOR_YELLOW .. "Бонусы за роли выключены")
    end
end

function QDKP2_IsRoleBonusEnabled()
    return QDKP2_RoleBonus.enabled
end

-- Функции для GUI настроек
function QDKP2_GetRoleBonusConfig()
    return QDKP2_RoleBonus.config
end

function QDKP2_GetRoleBonusBosses()
    return QDKP2_RoleBonusBosses
end

function QDKP2_SetRoleBonusBosses(newBosses)
    if type(newBosses) == "table" then
        QDKP2_RoleBonusBosses = newBosses
        QDKP2_Msg("Таблица бонусов за роли обновлена")
        QDKP2_Events:Fire("ROLEBONUS_CONFIG_UPDATED")
    end
end

-- Утилиты для работы с ролями
function QDKP2_GetPlayerRoleBonus(playerName, boss, difficulty)
    -- Возвращает бонус игрока за роль для конкретного босса
    if not QDKP2_RoleBonus.enabled then return 0 end
    
    local role = QDKP2GUI_Roster and QDKP2GUI_Roster.PlayerRoles and QDKP2GUI_Roster.PlayerRoles[playerName]
    if not role then return 0 end
    
    local bonuses = QDKP2_GetRoleBonusForBoss(boss, difficulty)
    return bonuses[role] and bonuses[role].amount or 0
end

-- Инициализация
local function InitializeRoleBonus()
    QDKP2_Debug(1, "RoleBonus", "Система бонусов за роли инициализирована")
    
    -- Проверяем интеграцию с Roster
    if not QDKP2GUI_Roster then
        QDKP2_Debug(1, "RoleBonus", "Внимание: Roster не найден, бонусы за роли могут не работать")
    end
end

