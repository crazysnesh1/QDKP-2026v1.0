--==============================================--
--======== QDKP V2 ФАЙЛ НАСТРОЕК ==========--
--==============================================--

------------------- НАГРАДЫ ЗА БОССОВ -------------------

------------------- ИНСТЫ -------------------

-- В этом блоке можно установить DKP по умолчанию для каждого рейдового инста(за одного босса)
-- Значения по умолчанию можно настроить для каждого уровня сложности (DKP_10N: 10 об, DKP_10H: 10 гер, DKP_25N: 25 об, DKP_25H: 25 гер)
-- Также можно настроить значения для определенного Босса отдельно
-- Названия боссов и инстов должны быть строго на АНГЛ. языке
-- Чтобы обнаружить убийство босса, у вас должен быть установлен один из аддонов(DBM или BigWigs)
-- Для начала установить значения по умолчанию для определенного инста, а уже после(если необходимо) для определенных боссов
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр
-- Ниже предоставлен пример того, как должно быть:

QDKP2_Instances = {
    { name = "Naxxramas", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 }, -- 1000 total for 10 normal, 2000 for 25 normal
    { name = "Ulduar", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 }, -- 1500 total for 10 normal, 3000 for 25 normal
    { name = "Trial of the Crusader", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 }, -- 1000 total for 25 heroic
    { name = "Icecrown Citadel", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 }, -- 1300 total for 25 normal, 2600 for 25 heroic
    { name = "Ruby Sanctum", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 } -- 400 total for 25 normal, 800 for 25 heroic
}

------------------- БОССЫ -------------------

-- Этот блок позволит установить значение DKP для каждого босса отдельно
-- Данные значения имеют приоритет выше, чем значения в "ИНСТЫ"
-- Если значение = nil, то награда будет установленна по умолчанию из блока "ИНСТЫ"
-- Вы можете добавить любое имя NPC на английском языке или на языке вашего клиента.
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр
-- Ниже предоставлен пример того, как должно быть:

QDKP2_Bosses = {
    -- Icecrown Citadel (ЦЛК) (25 гер = 2600 всего, 25 об = 1300 всего)
	{ name = "--Icecrown Citadel--", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },
    { name = "Lord Marrowgar", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Lady Deathwhisper", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
	{ name = "Icecrown Gunship Battle", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Deathbringer Saurfang", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Festergut", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Rotface", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Professor Putricide", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
	{ name = "Prince Valanar", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Blood-Queen Lana'thel", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Valithria Dreamwalker", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "Sindragosa", DKP_10N = 0, DKP_10H = 150, DKP_25N = 100, DKP_25H = 200 },
    { name = "The Lich King", DKP_10N = 0, DKP_10H = 300, DKP_25N = 200, DKP_25H = 400 },

    -- Ruby Sanctum (25 гер = 800 всего, 25 об = 400 всего) - Халион дает больше очков
	{ name = "----Ruby Sanctum----", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },	
    { name = "Halion", DKP_10N = nil, DKP_10H = nil, DKP_25N = 400, DKP_25H = 800 },
	
    -- Naxxramas (10 об = 1000 всего, 25 об = 2000 всего, 10 гер = 2000 всего, 25 гер = 4000 всего)
	{ name = "-----Naxxramas------", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },
    { name = "Anub'Rekhan", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Grand Widow Faerlina", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Maexxna", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Noth the Plaguebringer", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Heigan the Unclean", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Loatheb", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Instructor Razuvious", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Gothik the Harvester", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "The Four Horsemen", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Patchwerk", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Grobbulus", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Gluth", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Thaddius", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Sapphiron", DKP_10N = 65, DKP_10H = 130, DKP_25N = 130, DKP_25H = 260 },
    { name = "Kel'Thuzad", DKP_10N = 90, DKP_10H = 180, DKP_25N = 180, DKP_25H = 360 },
	
    -- Ulduar (10 об = 1500 всего, 25 об = 3000 всего)
	{ name = "-------Ulduar-------", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },
    { name = "Flame Leviathan", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Ignis the Furnace Master", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Razorscale", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "XT-002 Deconstructor", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "The Assembly of Iron", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Kologarn", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Auriaya", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Hodir", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Thorim", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Freya", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Mimiron", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "General Vezax", DKP_10N = 100, DKP_10H = 0, DKP_25N = 200, DKP_25H = 0 },
    { name = "Yogg-Saron", DKP_10N = 100, DKP_10H = 0, DKP_25N = 300, DKP_25H = 0 },
    { name = "Algalon the Observer", DKP_10N = 100, DKP_10H = 0, DKP_25N = 300, DKP_25H = 0 },

    -- Trial of the Crusader (ТОЛЬКО ГЕРОИЧЕСКИЙ РЕЖИМ) (25 гер = 1000 всего, 10 гер = 500 всего)
	{ name = "--------TotC--------", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },
    { name = "Northrend Beasts", DKP_10N = nil, DKP_10H = 100, DKP_25N = nil, DKP_25H = 200 },
    { name = "Lord Jaraxxus", DKP_10N = nil, DKP_10H = 100, DKP_25N = nil, DKP_25H = 200 },
    { name = "Faction Champions", DKP_10N = nil, DKP_10H = 100, DKP_25N = nil, DKP_25H = 200 },
    { name = "Eydis Darkbane", DKP_10N = nil, DKP_10H = 100, DKP_25N = nil, DKP_25H = 200 },
    { name = "Anub'arak", DKP_10N = nil, DKP_10H = 100, DKP_25N = nil, DKP_25H = 200 },
	
    -- Other Boss
	{ name = "-------Other--------", DKP_10N = 0, DKP_10H = 0, DKP_25N = 0, DKP_25H = 0 },
}

------------------- ЦЕНЫ НА ШМОТ -------------------

-- Если установлены фиксированные цены на добычу, тут можно установить определенные цены на (шмот, токены, оружия)
-- Необходимо заменить "0" на то количество DKP, которое хотите списать с игрока
-- Также можно установить значение в "%", которое будет взиматься с игрока (зависит от кол-ва DKP)

-- Naxxramas, Sartharion, Malygos, Archavon (10 men)
QDKP2_Prices_Nax10_Armor = 0   -- Armor pieces (not tier tokens)
QDKP2_Prices_Nax10_Tier = 0    -- T7 Tokens
QDKP2_Prices_Nax10_Weap = 0    -- Weapons

-- Naxxramas, Sartharion, Malygos, Archavon (25 men)
QDKP2_Prices_Nax25_Armor = 0
QDKP2_Prices_Nax25_Tier = 0   -- T7.5 Tokens
QDKP2_Prices_Nax25_Weap = 0

-- Ulduar, Emalon (10 men)
QDKP2_Prices_Uld10_Armor = 0
QDKP2_Prices_Uld10_Tier = 0  -- T8 tokens
QDKP2_Prices_Uld10_Weap = 0

-- Ulduar, Emalon (25 men)
QDKP2_Prices_Uld25_Armor = 0
QDKP2_Prices_Uld25_Tier = 0  -- T8.5 tokens
QDKP2_Prices_Uld25_Weap = 0

-- Coliseum NORMAL (10 men)
QDKP2_Prices_Col10_Armor = 0
QDKP2_Prices_Col10_Weap = 0

-- Coliseum NORMAL (25 men)
QDKP2_Prices_Col25_Armor = 0
QDKP2_Prices_Col25_Tier = 0  -- Trophy of the Crusade
QDKP2_Prices_Col25_Weap = 0

-- Coliseum HEROIC (10 men)
QDKP2_Prices_Col10H_Armor = 0
QDKP2_Prices_Col10H_Tier = 0  -- Trophy of the Crusade
QDKP2_Prices_Col10H_Weap = 0

-- Coliseum HEROIC (25 men)
QDKP2_Prices_Col25H_Armor = 0
QDKP2_Prices_Col25H_Tier = 0  -- T9.5+ tokens
QDKP2_Prices_Col25H_Weap = 0

-- Onyxia (10 men)
QDKP2_Prices_Ony10_Armor = 0
QDKP2_Prices_Ony10_Weap = 0

-- Onyxia (25 men)
QDKP2_Prices_Ony25_Armor = 0
QDKP2_Prices_Ony25_Weap = 0

-- Icecrown Citadel NORMAL (10 men)
QDKP2_Prices_IC10_Armor = 0
QDKP2_Prices_IC10_Weap = 0

-- Icecrown Citadel NORMAL (25 men)
QDKP2_Prices_IC25_Armor = 0
QDKP2_Prices_IC25_Tier = 0  --T10.5 tokens
QDKP2_Prices_IC25_Weap = 0

-- Icecrown Citadel HEROIC (10 men)
QDKP2_Prices_IC10H_Armor = 0
QDKP2_Prices_IC10H_Weap = 0

-- Icecrown Citadel HEROIC (25 men)
QDKP2_Prices_IC25H_Armor = 0
QDKP2_Prices_IC25H_Tier = 0  --T10.5+ tokens
QDKP2_Prices_IC25H_Weap = 0

-- Ruby Sanctum NORMAL (10 men)
QDKP2_Prices_RS10_Armor = 0
QDKP2_Prices_RS10_Weap = 0

-- Ruby Sanctum NORMAL (25 men)
QDKP2_Prices_RS25_Armor = 0
QDKP2_Prices_RS25_Weap = 0

-- Ruby Sanctum HEROIC (10 men)
QDKP2_Prices_RS10H_Armor = 0
QDKP2_Prices_RS10H_Weap = 0

-- Ruby Sanctum HEROIC (25 men)
QDKP2_Prices_RS25H_Armor = 0
QDKP2_Prices_RS25H_Weap = 0

-- Если значение = true , тогда QDKP будет открывать окно ставок каждый раз, когда кто то лутает (шмот, токены, оружия)
-- Если значение = false , окно будет открываться только если хотябы одна из категорий в блоке "ЦЕНЫ НА ШМОТ" не равна "0"
QDKP2_AlwaysOpenToolbox = false

-- В этом блоке можно указать конкретную цену на определенные предметы (шмот, токены, рецепты и т.д.)
-- Укажите значение DKP, которое хотите взымать с игрока
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр

QDKP2_ChargeLoots = {
    { item = "Uber Sword of Facerolling", DKP = 100 },
    { item = "Spam Cape", DKP = 25 },
}

------------------- ФИЛЬТР ПРЕДМЕТОВ -------------------
-- В этом блоке можно указать минимальное качество предметов, которые будут учитываться
-- 2 = зеленые; 3 = синие; 4 = фиолетовые; 5 = оранжевые

MIN_LOGGED_RAID_LOOT_QUALITY = 4    -- журнал рейда
MIN_LOGGED_LOOT_QUALITY = 4         -- журнал игрока
MIN_CHARGABLE_LOOT_QUALITY = 4      -- ответственный за добычу
MIN_CHARGABLE_CHAT_QUALITY = 4      -- рейд чат (предупреждения рейду)
MIN_LISTABLE_QUALITY = 4            -- блок истории
MIN_POPUP_TOOLBOX_Q = 4             -- всплывающее окно (ответственный за добычу)

------------------- ОТОБРАЖЕНИЕ В ЖУРНАЛЕ -------------------
-- Указать предметы, которые не вошли в фильтр "ФИЛЬТР ПРЕДМЕТОВ"
-- Значения меняют важность отображения
--    1 - просто зарегестрировать
--    2 - зарегестрировать и отправить сообщение в чат
--    3 - зарегестрировать и открыть окно предупреждения
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр

QDKP2_LogLoots = {
    { item = "Core Leather", level = 1 },
    { item = "Massive Mojo", level = 2 },
    { item = "Scale of Onyxia", level = 3 },
}

------------------- ЖУРНАЛ(ЧЕРНЫЙ СПИСОК) -------------------
QDKP2_LogBadges = false  -- если = true , регистрируются вся валюта (значки, эмблемы и т.д.)
QDKP2_LogShards = false  -- если = true , регистрировать все распыленные вещи (реагенты)

-- Укажите тут предметы, которые не хотите отображать в журнале
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр
QDKP2_NotLogLoots = {
--    "Эмблема льда",
--    "Эмблема Льда",	
--    "Эмблема триумфа",
--    "Эмблема Триумфа",
--    "Emblem of Triumph",
--    "Emblem of Frost",
}

------------------- СТАВКИ -------------------

-- тут можно настроить ключевые фразы, котороые QDKP будет улавливать
QDKP2_BidM_Keywords = {
    --{keywords="need,greed"},			  -- основные ключевые слова, которые будут использоваться без ставок
    { keywords = "$n,bid $n,need $n,os $n,$n os,$n ос,ос $n" }, -- $n = значение ставки DKP + какое либо слово
    --{keywords="half", value="$net/2"}, 		-- value используется для того, чтобы сказать QDKP какие операции после необходимо сделать с этим числом
    { keywords = "all,max,all in", value = "$net" }, -- просто дополнение к предыдущему ключевому слову
    { keywords = "min,minimum", value = "$minbid" }, -- ключевые слова поставят минимальную ставку, если такое значение установлено
}

QDKP2_BidM_GetFromWhisper = false            -- если = true , принимать ставки, отправленные шепотом
QDKP2_BidM_GetFromGroup = true               -- если = true , принимать ставки, отправленные в рейд/груп чат

QDKP2_BidM_AnnounceStart = true              -- если = true , объявить начало розыгрыша в рейд чат
QDKP2_BidM_AnnounceStartMinBidStep = true    -- если = true , объявить начало розыгрыша в рейд чат с указанием минимальной ставки и минимального шага
QDKP2_BidM_AnnounceWinner = true             -- если = true , объявить победителя в рейд чат
QDKP2_BidM_AnnounceCancel = true             -- если = true , объявить об отмене в рейд чат

QDKP2_BidM_CountStop = true                  -- если = true , запустить обратный отсчет при выборе победителя
QDKP2_BidM_CatchRoll = true                  -- если = true , запустить обратный отсчет при выборе победителя
QDKP2_BidM_CountAmount = 3                   -- длинна обратного отсчета(задержка между тиками 2 сек.)
QDKP2_BidM_AllowMultipleBid = true           -- если = true , игрок может ставить неограниченное количество ставок(если = false , то только одна на 1 предмет)
QDKP2_BidM_AllowLesserBid = false            -- если = false , игрок не сможет поставить меньше, чем его предыдущая ставка
QDKP2_BidM_HideWispBids = true               -- если = true , ставки отправленные шепотом не будут учитыватся
QDKP2_BidM_LogBids = true                    -- если = true , ставки регестрируются в журнале рейда
QDKP2_BidM_AckBids = false                   -- если = true , QDKP будет отправлять сообщение шепотом каждому игроку, какую ставку он сделал
QDKP2_BidM_AckRejBids = true                 -- если = true , отправлет сообщение в чат, что ставка отклоненна(если сделана шепотом, то отправляет в шепот и т.д.)
QDKP2_BidM_OverBid = false                   -- если = true , можно поставить ставку больше, чем у тебя имеется
QDKP2_BidM_DebugValues = true                -- если = true , отправит ПРЕДУПРЕЖДЕНИЕ в чат, что ставка не удалась, т.к. была неверно отправлена
QDKP2_BidM_CanOutGuild = true                -- если = false , игроки не состоящие в ГИ не смогут делать ставки, кидать /roll.(не будут учитываться в таблице)
QDKP2_BidM_RoundValue = true                 -- если = true , QDKP будет округлять значение до ближайшего целого числа
QDKP2_BidM_AutoRoll = false                  -- если = true , QDKP проверит, ставку и ее /roll. Если = false , QDKP отклонит ставку, попросив кинуть /roll.
QDKP2_BidM_ConfirmWin = true                 -- если = true , перед тем как отдать предмет, всплывет окно с уточнением
QDKP2_BidM_GiveItemToWinner = true           -- если = true , автоматически отдать предмет победителю, после уточнения отдачи в всплывающем окне

QDKP2_BidM_MinBid = 500                      -- минимальная ставка DKP
QDKP2_BidM_MaxBid = 1000000                  -- максимальная ставка DKP
QDKP2_BidM_MinStep = 500                     -- минимальный шаг DKP

QDKP2_BidM_BidStep1 = 10000                   -- после данного значения мин шаг будет равен QDKP2_BidM_Step1
QDKP2_BidM_Step1 = 1000                       -- минимальный шаг после достижения значения QDKP2_BidM_BidStep1
QDKP2_BidM_BidStep2 = 20000                  -- после данного значения мин шаг будет равен QDKP2_BidM_Step2
QDKP2_BidM_Step2 = 2000                      -- минимальный шаг после достижения значения QDKP2_BidM_BidStep2


-- Каналы чата, куда QDKP будет отправлять сообщения
-- Подтверждения или отклонения отправляются отправляются обратно в тот же чат, где они были получены
-- Названия каналов: "GUILD", "RAID", "PARTY", "GROUP", "RAID_WARNING", "OFFICER", "BATTLEGROUND", "SAY" , "YELL"
-- GROUP превращается в RAID, если вы в рейде. Если вы в группе то PARTY.
-- PS: названия канала писать ЗАГЛАВНЫМИ буквами
QDKP2_BidM_ChannelStart = "RAID_WARNING"
QDKP2_BidM_ChannelCanc = "GROUP"
QDKP2_BidM_ChannelWin = "RAID"
QDKP2_BidM_ChannelCount = "GROUP"
QDKP2_BidM_ChannelAck = "GROUP"
QDKP2_BidM_ChannelReject = "GROUP"

------------------------- РАЗНОЕ --------------------------

-- максимальное кол-во DKP, которое может иметь игрок
QDKP2_MAXIMUM_NET = 1000000

-- минимальное кол-во DKP, которое может иметь игрок
QDKP2_MINIMUM_NET = -10000

-- если = true , установить нулевую сумму, в качестве оплаты за предметы
QDKP2_CHARGEWITHZS = false

-- если = true , QDKP будет печатать имя каждого нового челена ГИ, когда его обнаружит
QDKP2_REPORT_NEW_GUILDMEMBER = false

-- отправить ПРЕДУПРЕЖДЕНИЕ, что игрок вступивший/покинувший рейд/группу не является челеном ГИ
QDKP2_ALERT_NOT_IN_GUILD = true

-- если = true , после убийства босса включить систему автоматического определения победителя
QDKP2_PROMPT_AWDS = false

-- если = false , автоматически определить разницу во времени между сервером и локальным сервером.
-- если = clock , установить серверное время
-- так же можно установить время вручную
-- если не желаете корректировать время то установить значение "0"
QDKP2_LOCALTIME_MANUALDELTA = 0

------------------------------- GUI -------------------------------------------------------
QDKP2_USE_CLASS_BASED_COLORS = false    -- если = true , установить цвет строки в таблице по цвету класса игрока
QDKP2_LOCALIZE_MESSAGES = true        -- если = false , будет локализироват только графический интерфейс, сообщения будут отправлятся на Англ. языке

------------------------------- LOG ----------------------------------------

QDKP2_LOG_MAXSIZE = 200        -- максимальное кол-во записей, сохраняемое в  журнале игрока, за сессию
QDKP2_LOG_RAIDMAXSIZE = 200    -- максимальное кол-во записей, сохраняемое в рейдовом журнале, за сессию
QDKP2_LOG_MAXSESSIONS = 100    -- максимальное кол-во сессий, сохраняемое в журнале

------------------------------ TIMER ------------------------------------------------------

-- время в минутах между тиками рейд таймера. Необходимо использовать число, кратное 6 (6,12,18,24 и т.д.)
-- после истечения времени игроки получат часы
-- пример( если = 30 то получат 0.5 часа, если 60 то 1 час и т.д.)
QDKP2_TIME_UNTIL_UPLOAD = 60

-- если = true , отправлять сообщение, когда игрок получает часы
QDKP_TIMER_SHOW_AWARDS = false

-- если = true , тики таймера регистрируются в журнале
QDKP_TIMER_RAIDLOG_TICK = false


----------------------------- FORMAT -------------------------------------------------------
-- Указать в какой заметке хранить данные DKP
-- ВАЖНО: Если хотите переместить данные из офицерской заметки в обычную, или наоборот то,
-- сначала нужно сделать резервную копию, закрыть WOW, поменять это значение, зайти в WOW,
-- восстановить резервную копию и сохранить изменения.
-- 1: Оффицерские заметки
-- 2: Обычные заметки
QDKP2_OfficerOrPublic = 1

-- если = 1 , то QDKP будет хранить заработанное DKP за все время
-- если = 2 , то QDKP будет хранить только то DKP, которое есть на текущий момент
QDKP2_TotalOrSpent = 1

-- если = true , сокращенные заметки
-- пример обычной заметки: Net:10 Tot:34 Hrs:25.2
-- пример сокращенной заметки: N:10 T:34 H:25.2
QDKP2_CompactNoteMode = true

-- если = false , отключает отображение кол-ва часов у игроков
QDKP2_StoreHours = true

QDKP2_NOTE_BREAK = " "  -- разделитель между значениями в заметке
QDKP2_NOTE_DASH = ":"   -- разделитель между названием и значением в заметке

-- если = true , считывать из офицерской заметки ники Альтов
QDKP2_AutoLinkAlts = true

-- если прошло менее "значение" часов, то отобразить время в формате ЧЧ:ММ:СС
QDKP2_DATE_TIME_TO_HOURS = 18

-- если прошло менее "значение" дней, то отобразить дату в формате 00 Day 00
QDKP2_DATE_TIME_TO_DAYS = 6

-- эти строки используются в объявление начала/конца отчета
QDKP2_Reports_Header = "Отчет журнала $NAME: ($TYPE)"  -- шапка отчета
QDKP2_Reports_Tail = "Конец отчета"                    -- подвал отчета

-- заголовок экспорта DKP в формате TXT или HTML
QDKP2_Export_TXT_Header = "QDKP2 - DKP Values of guild <$GUILDNAME> exported on $TIME"

--[[
NOTIFY
this is the template used by the notify function. You can change it as you wish,
including the following variables.
Available Variables:
$NAME: Name of the member
$GUILDNAME: Name of your guild
$RANK: Rank of the member
$CLASS: Class of the member
$NET: Net amount of DKP of the member
$TOTAL: Total amount of DKP of the member
$SPENT: Total amount of DKP spent by the member
$TIME: Total amount of raiding time of the member
$SESSGAINED: Amount of DKP gained by the member in the current session
$SESSSPENT: amount of DKP spent by the member in the current session
$SESSTIME: raiding time of the current session
$SESSNAME: Name of the current session
]]--

------------------------ БОТ -----------------------------
-- простой бот, запускаемый шепотом, используемый для предоставления информации другим игрокам по запросу

-- если = false , бот будет полностью отключен
QDKP2_ODS_ENABLE = true

-- если = true , вы будете видеть команды, отправляемые шепотом
QDKP2_OS_VIEWWHSP = true

-- если = false , игроки могут запрашивать только свои отчеты
QDKP2_IOD_REQALL = false

-- если = false , игроки вне гильдии не могу запрашивать данные
QDKP_OD_EXT = true

QDKP2_ROD = false  -- команда "?report или ?log получить отчет журнала
QDKP2_NOD = true  -- команда "?dkp" получить значения DKP
QDKP2_POD = false  -- команда "?price" получить цену на предмет
QDKP2_AOD = true  -- команда "?boss" получить бонусы за босса
QDKP2_COD = false  -- команда "?class" получить класс топ по DKP
QDKP2_KOD = false  -- команда "?rank" получить ранг топ по DKP

-- минимальная длинна ключевых слов для поиска Prices-on-Demand
QDKP2_POD_MINKEYWORD = 3

-- максимальное количество результатов, которые может отправить Prices-on-Demand
QDKP2_POD_MAXRESULTS = 8

-- минимальная длинна ключевых слов для поиска Awards-on-Demand
QDKP2_AOD_MINKEYWORD = 3

-- максимальное количество результатов, которые может отправить Awards-on-Demand
QDKP2_AOD_MAXRESULTS = 4

-- максимальная длинна списка лучших результатов
QDKP2_LOD_MAXLEN = 6


-------------------------------- АНОНСЫ ---------------------------------------------------
-- вы можете настроить QDKP, для объявления анонсов, розыгрышей и т.д. канал чата или шепот

-- каналы для объявления изменений: 'guild','raid','party','officer','say','yell','raid_warning','battleground'
QDKP2_AnnounceChannel = 'guild'

-- список событий, которые будут объявлены. Устрановите значение = true , чтобы включить объявление
QDKP2_AnnounceAwards = true      -- награды за рейд, бонус за убийство босса, награда IronMan
QDKP2_AnnounceIronman = false    -- включает событие начала и окончания награды ironman
QDKP2_AnnounceDKPChange = true   -- все награды и минуса DKP
QDKP2_AnnounceNegative = true    -- объявить если значение DKP стало отрицательным
QDKP2_AnnounceTimertick = true  -- сообщает о тиках таймера в рейд (спамит)


-- если = true , то сообщения будут отправлятся игрокам всякий раз, когда их DKP изменяется(спам)
QDKP2_AnnounceWhisper = false
QDKP2_AnnounceWhisperExternals = false

-- информирует игрока шепотом о том, что ему не удалось получить награду, и почему
QDKP2_AnnounceFailAw = false -- не удалось получить за начисления рейду
QDKP2_AnnounceFailHo = false -- не удалось получить за часовой бонус
QDKP2_AnnounceFailIM = false -- не удалось получить за Ironman бонус


---------------------- СИСТЕМА ОПРЕДЕЛЕНИЯ ПОБЕДИТЕЛЯ ------------------------------------------------
-- здесь вы можете редактировать слова, которые будут запускать систему определения победителя.
-- Если QDKP обнаружит в чате рейда сообщение от согильдейца, с числом и каким либо из этих слов, откроется
-- панель инструментов этого игрока, последний предмет в чате будет причиной платежа
-- МоЖнО нЕ сОблЮдАтЬ рЕгИсТр
QDKP2_WinTrigger = { "win", "wins", "won", "winner", "winning", "sold", "dkp", "points", "goes", "awards", "awarded" }


----------------------------- IRONMAN ------------------------------
-- это доп бонус рейдерам, которые находились на РТ с начала и до конца
-- им необходимо оставаться онайн в рейде все это время, чтобы получить бонус
QDKP2_IRONMAN_PER_REQ = 90

-- если = true , игрок должен быть в рейде, когда бонус запущен
QDKP2_IRONMAN_INWHENSTARTS = false

-- если = true , игрок должен быть в рейде, когда бонус завершен
QDKP2_IRONMAN_INWHENENDS = false


------------------------ ИСКЛЮЧЕНИЯ ------------------------

QDKP2_AWARD_OFFLINE_RAIDAWARD = false        -- если = true , игроки будут получать начисление рейду вне сети
QDKP2_AWARD_OFFLINE_TIMER = false            -- если = true , игроки будут получать начисление часового бонуса вне сети
QDKP2_AWARD_OFFLINE_ZEROSUM = false          -- если = true , игроки будут получать начисление нулевой суммы вне сети
QDKP2_AWARD_OFFLINE_IRONMAN = false          -- если = true , игроки будут получать начисление IronMan бонуса вне сети

QDKP2_AWARD_ZONE_RAIDAWARD = "100%"          -- "%" от начисления рейду, если игрок находится в другой зоне
QDKP2_AWARD_ZONE_TIMER = "100%"              -- "%" от начисления часового бонуса, если игрок находится в другой зоне
QDKP2_AWARD_ZONE_ZEROSUM = "100%"            -- "%" от начисления часового бонуса, если игрок находится в другой зоне
QDKP2_AWARD_ZONE_IRONMAN = "100%"            -- "%" от IronMan бонуса, если игрок находится в другой зоне

QDKP2_AWARD_RANK_RAIDAWARD = false
QDKP2_AWARD_RANK_TIMER = false
QDKP2_AWARD_RANK_ZEROSUM = false
QDKP2_AWARD_RANK_IRONMAN = false

QDKP2_AWARD_ALT_RAIDAWARD = true            -- если = true , альт персонажам начисляются награды рейду
QDKP2_AWARD_ALT_TIMER = true                -- если = true , альт персонажам начисляется часовой бонус
QDKP2_AWARD_ALT_ZEROSUM = true              -- если = true , альт персонажам начисляется нулевая сумма
QDKP2_AWARD_ALT_IRONMAN = true              -- если = true , альт персонажам начисляется IronMan бонус

QDKP2_AWARD_STANDBY_RAIDAWARD = "50%"      -- "%" от начисления рейду, если игрок на замене
QDKP2_AWARD_STANDBY_TIMER = "50%"          -- "%" от начисления часового бонуса, если игрок на замене
QDKP2_AWARD_STANDBY_ZEROSUM = "50%"        -- "%" от начисления часового бонуса, если игрок на замене
QDKP2_AWARD_STANDBY_IRONMAN = "50%"        -- "%" от IronMan бонуса, если игрок на замене

QDKP2_AWARD_EXTERNAL_RAIDAWARD = true        -- если = true , игрокам вне гильдии начисляются награды рейду
QDKP2_AWARD_EXTERNAL_TIMER = true            -- если = true , игрокам вне гильдии начисляется часовой бонус
QDKP2_AWARD_EXTERNAL_ZEROSUM = true          -- если = true , игрокам вне гильдии начисляется нулевая сумма
QDKP2_AWARD_EXTERNAL_IRONMAN = true          -- если = true , игрокам вне гильдии начисляется IronMan бонус

-- добавте сюда звания в гильдии, которые не могу получать DKP
-- пример: QDKP2_UNDKPABLE_RANK={"Initiate","Banished"}.
QDKP2_UNDKPABLE_RANK = {}

-- добавте сюда звания в гильдии, которые QDKP не учитывает
QDKP2_HIDE_RANK = {}

-- минимальный уровень, для отображения игрока в таблице QDKP
QDKP2_MINIMUM_LEVEL = 80

-- если = true , игрок может участвовать в розыгрыше, оплатив предмет методом нулевой суммы
QDKP_GIVEZSTOLOOTER = false


--------------------------- ЗАГРУЗКА ---------------------------------------------------------
-- события, которые автоматически вызовут загрузку данных

QDKP2_SENDTRIG_RAIDAWARD = true     -- если = true , загрузить после получения награды рейдом
QDKP2_SENDTRIG_TIMER_TICK = false   -- если = true , загрузить после тиков таймера
QDKP2_SENDTRIG_TIMER_AWARD = true   -- если = true , загрузить после получения часового бонуса
QDKP2_SENDTRIG_IRONMAN = true       -- если = true , загрузить после получения IronMan бонуса
QDKP2_SENDTRIG_CHARGE = true        -- если = true , загрузить после снятия DKP с игрока
QDKP2_SENDTRIG_MODIFY = true        -- если = true , загрузить после ручного редактирования DKP
QDKP2_SENDTRIG_ZS = true            -- если = true , загрузить после получения награды нулевой суммы

--------------------------- ПРЕДУПРЕЖДЕНИЯ --------------------------------------------------

-- если = true , предупредить когда данные игрока изменились и его текущее значение DKP стало отрицательным
QDKP2_CHANGE_NOTIFY_NEGATIVE = true

-- если = true , предупредить когда данные игрока изменились и эти изменения сделали его текущее значение DKP отрицательным
QDKP2_CHANGE_NOTIFY_WENT_NEGATIVE = true

--------------------------- ПРОВЕРКА СИСТЕМЫ  --------------------------------------------------
--!!!не трогайте настройки, если не понимаете, что делаете.!!!--

-- задержка перед закрытием запроса
QDKP2_CHECK_TIMEOUT = 20

-- во время запроса, каждую секунду выполнять запрос на загрузку данных гильдии
QDKP2_CHECK_RENEW = 3

-- после этого времени, запросить загрузку обновленных данных гильдии из КЭША
QDKP2_CHECK_REFRESH_DELAY = 8

-- по истечении этого времени обновляется ГИ КЭШ и офицерские заметки
QDKP2_CHECK_UPLOAD_DELAY = 2

-- сколько раз система должна прочитать заметки, если проверка не пройдена
QDKP2_CHECK_TRIES = 3

------------------------ DEFAULTS ---------------------
QDKP2_AutoBossEarn_Default = "on"      -- Авто начисление награды за боссов. Значения: "on" или "off"
QDKP2_DetectBid_Default = "off"         -- Авто определение победителя. Значения: "on" или "off"
QDKP2_UseFixedPrice_Default = "off"     -- Фиксированные цены. Значения: "on" или "off"
QDKP2GUI_Default_RaidBonus = 100        -- Стандартное значение награды рейду
QDKP2GUI_Default_TimerBonus = 50         -- Стандартное значение часового бонуса
QDKP2GUI_Default_IMBonus = 100            -- Стандартное значение IronMan бонуса
QDKP2GUI_Default_QuickMod = 100         -- Значение быстрого начисления DKP
QDKP2GUI_Default_QuickPerc1 = 10        -- Значение1 быстрого начисления DKP в %
QDKP2GUI_Default_QuickPerc2 = 15        -- Значение2 быстрого начисления DKP в %
QDKP2GUI_Default_ShowOutGuild = true

