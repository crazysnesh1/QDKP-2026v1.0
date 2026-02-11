-- ==========================================================
-- СИСТЕМА БОНУСОВ (ИСКЛЮЧЕНИЕ ИГРОКОВ + ВЫБОР СЕГМЕНТА)
-- ==========================================================

local LBB = LibStub("LibBabble-Boss-3.0"):GetLookupTable()

local DPS_Rewards = {
    ["Lord Marrowgar"] = { pts1 = 10, dps1 = 19000, pts2 = 5, dps2 = 15000 },
    ["Deathbringer Saurfang"] = { pts1 = 400, dps1 = 21000, pts2 = 200, dps2 = 19000 },
    ["Professor Putricide"] = { pts1 = 200, dps1 = 17000, pts2 = 100, dps2 = 15000 },
    ["The Lich King"] = { pts1 = 200, dps1 = 18000, pts2 = 100, dps2 = 16000 },
}

local Pending_Awards = {}
local Current_Segment_Index = 1
local Current_Config = nil

-- [ЦВЕТА КЛАССОВ]
local function GetClassColor(name)
    local _, class = UnitClass(name)
    if not class then return "ffffff" end
    local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
    return string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)
end

-- [ИНТЕРФЕЙС]
local frame = CreateFrame("Frame", "QDKP2_DpsBonusMainFrame", UIParent)
frame:SetSize(420, 440); frame:SetPoint("CENTER")
frame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 }})
frame:Hide(); frame:SetMovable(true); frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)

local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helpText:SetPoint("BOTTOM", 0, 55); helpText:SetText("|cffaaaaaa(ПКМ по игроку, чтобы исключить его из списка)|r")

-- КНОПКИ ПЕРЕКЛЮЧЕНИЯ
local prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
prevBtn:SetSize(30, 22); prevBtn:SetPoint("TOPLEFT", 15, -12); prevBtn:SetText("<")
prevBtn:SetScript("OnClick", function() QDKP2_DpsBonus_ChangeSegment(1) end)

local nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
nextBtn:SetSize(30, 22); nextBtn:SetPoint("TOPRIGHT", -15, -12); nextBtn:SetText(">")
nextBtn:SetScript("OnClick", function() QDKP2_DpsBonus_ChangeSegment(-1) end)

-- СКРОЛЛ И ТЕКСТ
local scrollFrame = CreateFrame("ScrollFrame", "QDKP2_DpsScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -45); scrollFrame:SetPoint("BOTTOMRIGHT", -35, 75)
local content = CreateFrame("Frame", nil, scrollFrame); content:SetSize(340, 1); scrollFrame:SetScrollChild(content)

-- Создаем контейнер для строк, чтобы на них можно было нажимать
local playerRows = {}
for i=1, 40 do
    local row = CreateFrame("Button", nil, content)
    row:SetSize(320, 14); row:SetPoint("TOPLEFT", 0, -(i-1)*14)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetAllPoints(); row.text:SetJustifyH("LEFT")
    row:Hide()
    playerRows[i] = row
end

-- [ОБНОВЛЕНИЕ ИНТЕРФЕЙСА]
local function RefreshUI()
    -- Сортировка
    table.sort(Pending_Awards, function(a, b) return a.dps > b.dps end)
    
    for _, row in ipairs(playerRows) do row:Hide() end
    
    local logY = 0
    local hasShownSeparator = false
    local rowIndex = 1

    if Current_Config and #Pending_Awards > 0 then
        for i, e in ipairs(Pending_Awards) do
            if rowIndex > 40 then break end
            local row = playerRows[rowIndex]
            
            -- Логика разделителя (просто текст в строке)
            if e.pts <= Current_Config.pts2 and not hasShownSeparator and Current_Config.pts1 ~= Current_Config.pts2 then
                row.text:SetText("\n|cffFFD100[Мин. бонус: +" .. Current_Config.pts2 .. " DKP]|r")
                row:SetID(0); row:Show(); rowIndex = rowIndex + 1
                row = playerRows[rowIndex]
                hasShownSeparator = true
            elseif i == 1 then
                row.text:SetText("|cffFFD100[Макс. бонус: +" .. Current_Config.pts1 .. " DKP]|r")
                row:SetID(0); row:Show(); rowIndex = rowIndex + 1
                row = playerRows[rowIndex]
            end

            local c = GetClassColor(e.name)
            row.text:SetText(string.format("|cff%s%s|r: |cff00ff00+%d|r |cff00ffff(%d dps)|r", c, e.name, e.pts, e.dps))
            row:SetID(i) -- Запоминаем индекс игрока в таблице Pending_Awards
            row:RegisterForClicks("RightButtonUp")
            row:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    table.remove(Pending_Awards, self:GetID())
                    RefreshUI()
                end
            end)
            row:Show()
            rowIndex = rowIndex + 1
        end
    else
        playerRows[1].text:SetText("|cffaaaaaaСписок пуст или бой не в списке.|r")
        playerRows[1]:Show()
    end
    content:SetHeight(rowIndex * 14 + 20)
end

-- [АНАЛИЗ СЕГМЕНТА]
function QDKP2_DpsBonus_Calculate(index, manual)
    Current_Segment_Index = index
    local set = Skada.sets and Skada.sets[index]
    if not set then return end

    local segName = set.mobname or set.name or "Unknown"
    title:SetText(segName)
    
    Current_Config = nil
    for key, cfg in pairs(DPS_Rewards) do
        if segName == key or segName == LBB[key] then Current_Config = cfg; break end
    end

    wipe(Pending_Awards)
    if Current_Config and set.actors then
        local combatTime = set.time or 1
        for name, p in pairs(set.actors) do
            if not p.enemy then
                local dps = math.floor(((p.damage or 0) / (p.time or combatTime)) + 0.5)
                local award = (dps >= Current_Config.dps1) and Current_Config.pts1 or (dps >= Current_Config.dps2 and Current_Config.pts2 or 0)
                if award > 0 then
                    table.insert(Pending_Awards, { boss = segName, name = name, pts = award, dps = dps })
                end
            end
        end
    end

    RefreshUI()
    if manual or #Pending_Awards > 0 then frame:Show() end
end

function QDKP2_DpsBonus_ChangeSegment(delta)
    local newIndex = Current_Segment_Index + delta
    if newIndex < 1 then newIndex = 1 end
    if Skada.sets and newIndex > #Skada.sets then newIndex = #Skada.sets end
    QDKP2_DpsBonus_Calculate(newIndex, true)
end

-- КНОПКИ ДЕЙСТВИЙ
local btnClose = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnClose:SetSize(100, 30); btnClose:SetPoint("BOTTOMRIGHT", -20, 20); btnClose:SetText("Закрыть")
btnClose:SetScript("OnClick", function() frame:Hide() end)

local btnAward = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnAward:SetSize(120, 30); btnAward:SetPoint("BOTTOMLEFT", 20, 20); btnAward:SetText("|cff00ff00Начислить|r")
btnAward:SetScript("OnClick", function()
    if #Pending_Awards == 0 then return end
    if not QDKP2_ManagementMode() then print("|cffff0000[DpsBonus] Ошибка: Включите Management Mode!|r") return end
    for _, data in ipairs(Pending_Awards) do
        QDKP2_PlayerGains(data.name, data.pts, "Бонус ДПС: " .. data.boss)
    end
    print("|cff00ff00[DpsBonus]|r Бонусы начислены.")
    frame:Hide()
end)

-- [ЛОАДЕР]
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        SLASH_QDKPDPS1 = "/qdkpdps"
        SlashCmdList["QDKPDPS"] = function() QDKP2_DpsBonus_Calculate(1, true) end
        print("|cff00ff00[DpsBonus]|r Загружен.")
    end
end)