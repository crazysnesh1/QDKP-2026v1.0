--QDKP2_Config
--Manages the configuration of Quick DKP V2

--Addon definition
QDKP2_Config = LibStub("AceAddon-3.0"):NewAddon("QDKP2_Config", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")
QDKP2_Config_DB={}

--Constants
QDKP2_Config.CommVersion='900'
QDKP2_Config.Localize = LibStub("AceLocale-3.0"):GetLocale("QDKP2_Config", true)
QDKP2_Config.Colors={
Enabled="|cff77ff77",
Disabled="|cffff7788",
Emphasis="|cffffc500",
}
QDKP2_Config.CommTypes = {
    PROFILE = "Profile",
    EXTERNALS = "Externals", 
    ALTS = "Alts"
}


------------------------------------------------------------- Main addon methods ----------------------------------------------------------------

function QDKP2_Config:OnEnable()
--Called by AceAddon when everything is up and running: Addon, UI, savedvars, environment, API etc.

	self:ApplyNameDesc()

	self.Defaults=QDKP2_Config:ReadGlobalOptions()		--this line can be removed when	QDKP will use the profile-based configure system 
	--self.Defaults=QDKP2_DefaultOptions --this is the line to use when QDKP will use the profile-based configure system. 
	
	--default settings for QDKP2_Config only
	self.Defaults.BRC_OverrideBroadcast=false
	self.Defaults.BRC_AutoSendTime=120
	self.Defaults.BRC_AutoSendEn=false	
	QDKP2_Config.CharDefaults={ActiveProfiles={},}

	--Loading libraries
	self.DB = LibStub("AceDB-3.0"):New(QDKP2_Config_DB, {profile = QDKP2_Config.Defaults, char = QDKP2_Config.CharDefaults},true)
	self.AceConfig=LibStub("AceConfig-3.0")
	self.AceConfigDialog=LibStub("AceConfigDialog-3.0")

	--Registering the configuration tables
	self.Tree.args["Profile"]=LibStub("AceDBOptions-3.0"):GetOptionsTable(QDKP2_Config.DB,true)		
	self.AceConfig:RegisterOptionsTable("QDKP_V2", QDKP2_Config.Tree,{})
	self.AceConfig:RegisterOptionsTable("QDKP_V2_Bliz", QDKP2_Config.BlizTree,{})
	self.AceConfigDialog:AddToBlizOptions("QDKP_V2_Bliz","Quick DKP V2")
	
	--Registering for Click event on QDKP minimap button (if exists) to open the configuration frame
	if QDKP2GUI_MiniBtn then 
		QDKP2GUI_MiniBtn:SetScript("OnMouseDown", function (self, button, down)
			if button=="RightButton" then
				QDKP2_Config:OpenDialog()
			end
		end)
	end

	--registering for events
	self:RegisterComm("QDKP2ConfPro")	
	self.DB.RegisterCallback(self,"OnProfileChanged", "ApplyProfile")
	self.DB.RegisterCallback(self,"OnProfileCopied", "ApplyProfile")
	self.DB.RegisterCallback(self,"OnProfileReset", "ApplyProfile")
	self.DB.RegisterCallback(self,"OnProfileShutdown","FreezeSubtables")
	self.DB.RegisterCallback(self,"OnDatabaseShutdown","FreezeSubtables")
	
	--hook to detect when QDKP_V2 reads database. I use this to detect guild changes. 
	local OrigReadDatabase=QDKP2_ReadDatabase
	function QDKP2_ReadDatabase(...)
		OrigReadDatabase(...)
		self:UpdateGuildProfile()
	end
	
	--Apply the profile given the current guild.
	self:UpdateGuildProfile()
	QDKP2_Config:ApplyProfile()
	
	--Launch autobroadcast.
	self:AutoBroadcast(true)
end


function QDKP2_Config:ApplyProfile()
--Called on profile change.

	QDKP2_Debug(1,"Config","Profile changed to "..self.DB:GetCurrentProfile()..". Applying settings.")
	self.DB.char.ActiveProfiles[QDKP2_Config:GetDefaultProfileName()]=self.DB:GetCurrentProfile()
	self.Profile=self.DB.profile

	--the following is used to clean old Boss_Instance voices when the addon mantainer updates the table
	for i,v in pairs(self.Profile.Boss_Instance) do if not v.name then self.Profile.Boss_Instance[i]=nil; end; end
	
	self.Profile.Boss_Names=self:DefrostSubtable(self.Profile.Boss_Names)
	self.Profile.BM_Keywords=self:DefrostSubtable(self.Profile.BM_Keywords)
	self.Profile.LOOT_Items=self:DefrostSubtable(self.Profile.LOOT_Items)
	
	self:UpdateItemTables()
	self:ApplyProfileToGlobal()	--this line can be removed when	QDKP will use the profile-based configure system 
	self:RefreshGUI()
end

function QDKP2_Config:UpdateGuildProfile()
	--called when QDKP indicates you have changed guild
	
	QDKP2_Debug(1,"Config","Detected guild change, updating active profile")
	local Profile=self:GetDefaultProfileName()
	local lastProfile=self.DB.char.ActiveProfiles[Profile]
	if lastProfile and Profile~="Default"	then Profile=lastProfile; end
	self.DB:SetProfile(Profile)
end

function QDKP2_Config:OpenDialog()
	self.AceConfigDialog:SetDefaultSize("QDKP_V2", 700, 600)
	self.AceConfigDialog:Open("QDKP_V2")
end

----------------------------------------------- Configuration syncronization functions -------------------------------------------

function QDKP2_Config:SendActiveProfile(name)
    if not name then return; end
    local distribution='WHISPER'
    local data = {
        type = QDKP2_Config.CommTypes.PROFILE,
        data = {self.DB:GetCurrentProfile(), self.Profile},
        version = QDKP2_Config.CommVersion
    }
    local text = self:Serialize(data)
    if name=='GUILD' then    
        distribution='GUILD'
        if not IsGuildLeader(UnitName("player")) then
            QDKP2_Msg("Only Guild Master can broadcast to guild", "ERROR")
            return
        end
    end
    self:SendCommMessage("QDKP2ConfPro", text, distribution, name, "BULK")
end

function QDKP2_Config:SendExternals(name)
    if not name then return; end
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end
    
    local distribution = 'WHISPER'
    local data = {
        type = QDKP2_Config.CommTypes.EXTERNALS,
        data = QDKP2externals,
        version = QDKP2_Config.CommVersion
    }
    local text = self:Serialize(data)
    
    if name == 'GUILD' then 
        distribution = 'GUILD'
        -- Проверяем права офицера вместо прав ГМа
        if not QDKP2_OfficerMode() then
            QDKP2_Msg("You don't have officer rights to broadcast to guild", "ERROR")
            return
        end
    end
    
    self:SendCommMessage("QDKP2ConfPro", text, distribution, name, "BULK")
    QDKP2_Msg("Externals list sent to "..name)
end

function QDKP2_Config:SendAlts(name)
    if not name then return; end
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end
    
    local distribution = 'WHISPER'
    local data = {
        type = QDKP2_Config.CommTypes.ALTS,
        data = {
            alts = QDKP2alts,
            altsRestore = QDKP2altsRestore
        },
        version = QDKP2_Config.CommVersion
    }
    local text = self:Serialize(data)
    
    if name == 'GUILD' then 
        distribution = 'GUILD'
        -- Проверяем права офицера вместо прав ГМа
        if not QDKP2_OfficerMode() then
            QDKP2_Msg("You don't have officer rights to broadcast to guild", "ERROR")
            return
        end
    end
    
    self:SendCommMessage("QDKP2ConfPro", text, distribution, name, "BULK")
    QDKP2_Msg("Alts list sent to "..name)
end

function QDKP2_Config:OnCommReceived(prefix, message, distribution, sender)
    if prefix=='QDKP2ConfPro' then
        if sender==UnitName("player") then return; end --do not want stuff from self.
        
        -- Пытаемся десериализовать данные
        local success, data = self:Deserialize(message)
        if not success then
            QDKP2_Debug(1,"Config","Received corrupted data from "..sender..". Error="..data)
            return
        end
        
        -- Проверяем формат данных (старый vs новый)
        if type(data) == 'table' and data.type and data.version then
            -- Новый формат с типами
            if data.version ~= QDKP2_Config.CommVersion then
                QDKP2_Debug(2,"Config","Version mismatch from "..sender..". Expected "..QDKP2_Config.CommVersion..", got "..data.version)
                return
            end
            
            if data.type == QDKP2_Config.CommTypes.PROFILE then
                self:HandleProfileData(data.data, distribution, sender)
            elseif data.type == QDKP2_Config.CommTypes.EXTERNALS then
                self:HandleExternalsData(data.data, distribution, sender)
            elseif data.type == QDKP2_Config.CommTypes.ALTS then
                self:HandleAltsData(data.data, distribution, sender)
            else
                QDKP2_Debug(2,"Config","Unknown data type from "..sender..": "..tostring(data.type))
            end
        else
            -- Старый формат (для обратной совместимости)
            local ProfileName, Profile, Version = data, message, distribution
            if not ProfileName or type(ProfileName)~='string' or
                 not Profile or type(Profile)~='table'    or
                 not Version or Version~=QDKP2_Config.CommVersion then
                QDKP2_Debug(2,"Config","Received old format data from "..sender.." that didn't pass compliance check.")
                return
            end
            if distribution=='GUILD' then
                if IsGuildLeader(sender) then self:ImportProfile(ProfileName,Profile)
                else
                    QDKP2_Debug(1,"Config",sender.." is broadcasting a configuration profile on the guild channel but he's not the GM.")
                end
            elseif distribution=='WHISPER' then
                QDKP2_AskUser(string.format(QDKP2_Config.Localize.MESS_AllowImport,sender,ProfileName),QDKP2_Config.ImportProfile,self,ProfileName,Profile)
            end
        end
    end
end

function QDKP2_Config:ImportProfile(BCT_ProfileName,BCT_Profile)
--import a received profile
	local oldProfile=self.DB:GetCurrentProfile()
	self.DB:SetProfile(BCT_ProfileName)
	for i,v in pairs(BCT_Profile) do self.Profile[i]=v; end --import keys from received profile
	for i,v in pairs(self.Profile) do 
		if not BCT_Profile[i] then self.Profile[i]=nil; end --delete every key that does not exist on received profile
	end
	if self.Profile.BCT_OverrideBroadcast then self.DB:SetProfile(oldProfile); end
	self.Profile.BCT_ProfileName = BCT_ProfileName	
end

function QDKP2_Config:AutoBroadcast(first)
	local sec=math.ceil((self.Profile.BRC_AutoSendTime or 120)*60)
	if first then sec=30; end
	self:ScheduleTimer('AutoBroadcast', sec)
	if self.Profile.BRC_AutoSendEn and IsGuildLeader(UnitName("player")) and not first then
		self:SendActiveProfile('GUILD')
	end
end



-------------------------------------- Database helper function ----------------------------------------------------
--AceDB has an odd behaviour with tables: it does not overwrite defaults if the value is nil. Let's say you have a default
--table with {"a","b","c", "d"}. Now we delete the item 2. What you have now is {"a","c","d"}. Now, we reload the UI.
--You now expect the table to be the same, but you get{"a","c","d","d"}. The first three values are just fines (the ones 
--before reload that was in the already in the table), but the 4th item that whould be nil is still there.
--To overcome this problem without touching Quick DKP code I "freeze" subtables right before the profile is closed by
--serialize them and storing the string representation. When the profile is loaded, if those are string i defrost (deserialize)
--them.

local function FreezeSubtable(subtable)
	if not QDKP2_Config.Profile then return; end
	if QDKP2_Config:Serialize(QDKP2_Config.Profile[subtable])~=QDKP2_Config:Serialize(QDKP2_Config.Defaults[subtable]) then
		QDKP2_Config.Profile[subtable]=QDKP2_Config:Serialize(QDKP2_Config.Profile[subtable])
	end
end

function QDKP2_Config:FreezeSubtables()
	FreezeSubtable('Boss_Names')
	FreezeSubtable('BM_Keywords')
	FreezeSubtable('LOOT_Items')
end

function QDKP2_Config:DefrostSubtable(subtable)
	if type(subtable)~='string' then return subtable; end
	local ok,t=self:Deserialize(subtable)
	if ok then return t
	else return {}
	end
end

-------------------------------------- Helpers for functions in the config tree ---------------------------------- 

function QDKP2_Config:GetVar(info,...)
--standard getter for config voices. Idexes the actual profile with the voice name.
	local varname = info[#info] 
	local v=self.Profile[varname]
	if info.option.pattern and info.option.pattern== '^-?%d+$' then v=tostring(v); end --convert from number if is a number entry
	return v
end

function QDKP2_Config:SetVar(info,value,...)
--standard setter for config voices.
	local varname = info[#info]
	if info.option.pattern and info.option.pattern== '^-?%d+$' then value=tonumber(value); end --convert to number if is a number entry
	self.Profile[varname]=value
	self:ApplyVarToGlobal(varname) --this line can be removed when QDKP will be modified to use a profile-based setting system
end

function QDKP2_Config:GetGM()
--returns the name of the guild master
	for i=1,GetNumGuildMembers(true) do
		if IsGuildLeader(GetGuildRosterInfo(i)) then return GetGuildRosterInfo(i); end
	end
end

function QDKP2_Config:GetDefaultProfileName()
--returns a standard name for the profile in the form "Server-GuildName"
	local GuildName=GetGuildInfo("player")
	if GuildName then
		return string.format("%s-%s",GetRealmName(),GuildName)
	else
		return "Default"
	end
end

function QDKP2_Config:RefreshGUI()
	if QDKP2_RefreshAll then QDKP2_RefreshAll(); end
end

function QDKP2_Config:GetBreak(order)
	local v={
		type = 'description',
		name = ' ',
		fontSize = 'medium',
		order = order,
	}
	return v
end



--The following functions are used to get a table of default settings from the DefaultOptions.lua and the Options.ini file in the QDKP_V2 addon.
--This is to make QDKP2_Config flawlessy compatible with QDKP2 as it is now.
--It would be wiser to change QDKP_V2 and QDKP2_GUI global-based configuration to a modern system based on Profiles. The process will be 
--really invasive though, as the options are quite much and are spreaded all over the addons file.	


function QDKP2_Config:UpdateItemTables()
--Used to extract the tables used in the options.ini file from the LOOT_Items I use in the config addon.
--On Quick DKP upgrade to setting profile, the aforementioned tables should be unified in the LOOT_Items table in this way:
--[[
QDKP2_ChargeLoots[i].item => profile.LOOT_Items.name[i].name
QDKP2_ChargeLoots[i].DKP => profile.LOOT_Items[i].price
QDKP2_LogLoots[i].level => profile.LOOT_Items[i].level-2 (level-2 will be any value between -1 and 3: -1 and 0 must be skipped.
QDKP2_NotLogLoots[i] => profile.LOOT_Items[i].level==1 (the first returns a string, the seconds returns true if the item at index i must not be logged)
--]]

	local Item={}
	local Log={}
	local NoLog={}
	
	for i,v in pairs(QDKP2_Config.Profile.LOOT_Items) do
		local name=v.name
		if v.price then table.insert(Item, {item=name, DKP=v.price}); end
		if v.log and v.log>=3 then table.insert(Log, {item=name, level=v.log-2})
		elseif v.log==1 then table.insert(NoLog, name)
		end
	end
	
	QDKP2_Config.Profile.LOOT_ItemPrices=Item
	QDKP2_Config.Profile.LOOT_LootsLog=Log
	QDKP2_Config.Profile.LOOT_LootsNoLog=NoLog
	QDKP2_Config:ApplyVarToGlobal('LOOT_ItemPrices')
	QDKP2_Config:ApplyVarToGlobal('LOOT_LootsLog')
	QDKP2_Config:ApplyVarToGlobal('LOOT_LootsNoLog')
	QDKP2_Config.Profile.LOOT_ItemPrices=nil
	QDKP2_Config.Profile.LOOT_LootsLog=nil
	QDKP2_Config.Profile.LOOT_LootsNoLog=nil
end
	

function QDKP2_Config:ReadGlobalOptions()
	QDKP2_Config_Temp={}
	for i,v in pairs(self.TransTable) do
		RunScript("QDKP2_Config_Temp."..i.."="..v)
	end
	
	local items={}
	for i,v in pairs(QDKP2_ChargeLoots) do
		table.insert(items,{name=v.item,price=v.DKP})
	end
	for i,v in pairs(QDKP2_LogLoots) do
		table.insert(items,{name=v.item,level=v.level+2})
	end
	for i,v in pairs(QDKP2_NotLogLoots) do
		table.insert(items, {name=v, level=1})
	end
	QDKP2_Config_Temp.LOOT_Items=items
	
	return QDKP2_Config_Temp
end

function QDKP2_Config:ApplyVarToGlobal(varname)
	assert(self.TransTable[varname],varname.." is not present in TransTable")
	RunScript(self.TransTable[varname].."=QDKP2_Config.Profile."..varname)
end

function QDKP2_Config:ApplyProfileToGlobal()
	for i,v in pairs(self.TransTable) do
		RunScript(v.."=QDKP2_Config.Profile."..i)
	end
end

function QDKP2_Config:HandleProfileData(Data, distribution, sender)
    local ProfileName, Profile = Data[1], Data[2]
    if distribution=='GUILD' then
        if IsGuildLeader(sender) then 
            self:ImportProfile(ProfileName,Profile)
        else
            QDKP2_Debug(1,"Config",sender.." broadcasted profile but is not GM.")
        end
    elseif distribution=='WHISPER' then
        QDKP2_AskUser(string.format(QDKP2_Config.Localize.MESS_AllowImport,sender,ProfileName),
                     QDKP2_Config.ImportProfile, self, ProfileName, Profile)
    end
end

local MAX_DISPLAY_NAMES = 5 -- Максимальное количество отображаемых имен

local function GetExternalsListMessage(ExternalsData, sender)
    -- ExternalsData - это таблица (словарь), где ключами являются имена.
    local names = {}
    for name in pairs(ExternalsData) do
        table.insert(names, name)
    end

    table.sort(names) -- Сортируем для последовательного отображения
    
    local total_count = #names
    local message_template = QDKP2_Config.Localize.MESS_AllowImportExternals or "Do you want to import externals list from %s?"
    local more_text = QDKP2_Config.Localize.MESS_AndMore or " and %d more..."

    local full_message = string.format(message_template, sender)
    
    if total_count > 0 then
        -- Отображаем первые MAX_DISPLAY_NAMES имен
        local display_list = {}
        for i = 1, math.min(total_count, MAX_DISPLAY_NAMES) do
            table.insert(display_list, names[i])
        end
        
        -- Добавляем имена в отдельной строке
        local list_message = "\n\n" .. table.concat(display_list, ", ")
        
        if total_count > MAX_DISPLAY_NAMES then
            local remaining = total_count - MAX_DISPLAY_NAMES
            list_message = list_message .. string.format(more_text, remaining)
        end
        
        full_message = full_message .. list_message
    end
    
    return full_message
end

function QDKP2_Config:HandleExternalsData(ExternalsData, distribution, sender)
    QDKP2_Debug(1, "Config", "HandleExternalsData from " .. sender)
    if distribution=='GUILD' then
        -- Разрешаем принимать от любого офицера
        if QDKP2_IsInGuild(sender) then
            self:ImportExternals(ExternalsData)
        else
            QDKP2_Debug(1,"Config",sender.." broadcasted externals but is not in guild.")
        end
    elseif distribution=='WHISPER' then
        -- Генерация сообщения с ограниченным списком
        local confirmation_message = GetExternalsListMessage(ExternalsData, sender)
        
        -- Используем сгенерированное сообщение для вызова QDKP2_AskUser
        QDKP2_AskUser(confirmation_message, function() self:ImportExternals(ExternalsData) end)
    end
end

function QDKP2_Config:HandleAltsData(AltsData, distribution, sender)
    QDKP2_Debug(1, "Config", "HandleAltsData from " .. sender)
    
    if distribution=='GUILD' then
        if QDKP2_IsInGuild(sender) then 
            self:ImportAlts(AltsData)
        else
            QDKP2_Debug(1,"Config",sender.." broadcasted alts but is not in guild.")
        end
    elseif distribution=='WHISPER' then
        QDKP2_AskUser(string.format(QDKP2_Config.Localize.MESS_AllowImportAlts, sender),
                     function() 
                         QDKP2_Debug(1, "Config", "User accepted alts import from whisper")
                         self:ImportAlts(AltsData) 
                     end)
    end
end

function QDKP2_Config:ImportExternals(ExternalsData)
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end
    
    -- Сохраняем текущие данные для сравнения
    local oldExternals = {}
    for k,v in pairs(QDKP2externals) do oldExternals[k] = v end
    
    -- Находим новых externals
    local addedExternals = {}
    for name, data in pairs(ExternalsData) do
        if not oldExternals[name] then
            table.insert(addedExternals, name)
        end
    end
    
    -- Находим удаленных externals  
    local removedExternals = {}
    for name, data in pairs(oldExternals) do
        if not ExternalsData[name] then
            table.insert(removedExternals, name)
        end
    end
    
    -- Формируем информационное сообщение
    local message = "Import externals list?\n\n"
    
    if #addedExternals > 0 then
        local maxShow = 8
        local addedList = table.concat(addedExternals, ", ", 1, math.min(maxShow, #addedExternals))
        if #addedExternals > maxShow then
            addedList = addedList .. ", ... and " .. (#addedExternals - maxShow) .. " more"
        end
        message = message .. "Will ADD " .. #addedExternals .. " externals:\n" .. addedList .. "\n\n"
    end
    
    if #removedExternals > 0 then
        local maxShow = 8
        local removedList = table.concat(removedExternals, ", ", 1, math.min(maxShow, #removedExternals))
        if #removedExternals > maxShow then
            removedList = removedList .. ", ... and " .. (#removedExternals - maxShow) .. " more"
        end
        message = message .. "Will REMOVE " .. #removedExternals .. " externals:\n" .. removedList .. "\n\n"
    end
    
    if #addedExternals == 0 and #removedExternals == 0 then
        message = message .. "No changes detected."
    end
    
    -- Запрашиваем подтверждение
    QDKP2_AskUser(message, 
        function()
            -- Удаляем старые externals которых нет в новых данных
            for name, data in pairs(oldExternals) do
                if not ExternalsData[name] then
                    QDKP2_DelExternal(name, true)
                end
            end
            
            -- Добавляем новых externals используя API QDKP2
            for name, data in pairs(ExternalsData) do
                if not oldExternals[name] then
                    QDKP2_NewExternal(name, data.datafield or "")
                end
            end
            
            -- Обновляем GUI
            QDKP2_DownloadGuild()
            QDKP2_RefreshAll()
            
            -- Выводим в чат список добавленных
            if #addedExternals > 0 then
                QDKP2_Msg("Added " .. #addedExternals .. " externals: " .. table.concat(addedExternals, ", "))
            end
            if #removedExternals > 0 then
                QDKP2_Msg("Removed " .. #removedExternals .. " externals: " .. table.concat(removedExternals, ", "))
            end
            
            QDKP2_Msg("Externals list imported successfully")
            
            -- Принудительно сохраняем данные
            self:ForceSaveData()
        end,
        function()
            QDKP2_Msg("Externals import cancelled")
        end
    )
end

function QDKP2_Config:ImportAlts(AltsData)
    QDKP2_Debug(1, "Config", "ImportAlts started")
    
    if not QDKP2_OfficerMode() then
        QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
        return
    end

    -- Извлекаем данные
    local newAlts = AltsData.alts or AltsData
    local newAltsRestore = AltsData.altsRestore or {}

    -- Сохраняем текущие данные для сравнения
    local oldAlts = {}
    local oldAltsRestore = {}
    for k,v in pairs(QDKP2alts) do oldAlts[k] = v end
    for k,v in pairs(QDKP2altsRestore) do oldAltsRestore[k] = v end

    -- Находим новые отношения alt-main
    local addedAlts = {}
    for alt, main in pairs(newAlts) do
        if not oldAlts[alt] then
            table.insert(addedAlts, alt .. " -> " .. main)
        end
    end

    -- Находим удаленные отношения
    local removedAlts = {}
    for alt, main in pairs(oldAlts) do
        if not newAlts[alt] then
            table.insert(removedAlts, alt)
        end
    end

    -- Формируем информационное сообщение
    local message = "Import alts list?\n\n"
    
    if #addedAlts > 0 then
        local maxShow = 6
        local addedList = ""
        for i = 1, math.min(maxShow, #addedAlts) do
            if i > 1 then
                addedList = addedList .. "\n"
            end
            addedList = addedList .. addedAlts[i]
        end
        if #addedAlts > maxShow then
            addedList = addedList .. "\n... and " .. (#addedAlts - maxShow) .. " more"
        end
        message = message .. "Will ADD " .. #addedAlts .. " alt relations:\n" .. addedList .. "\n\n"
    end
    
    if #removedAlts > 0 then
        local maxShow = 8
        local removedList = table.concat(removedAlts, ", ", 1, math.min(maxShow, #removedAlts))
        if #removedAlts > maxShow then
            removedList = removedList .. ", ... and " .. (#removedAlts - maxShow) .. " more"
        end
        message = message .. "Will REMOVE " .. #removedAlts .. " alt relations:\n" .. removedList .. "\n\n"
    end
    
    if #addedAlts == 0 and #removedAlts == 0 then
        message = message .. "No changes detected."
    end
    
    -- Запрашиваем подтверждение
    QDKP2_AskUser(message, 
        function()
            QDKP2_Debug(1, "Config", "User accepted alts import")
            
            -- Удаляем старые alts которых нет в новых данных
            for alt, main in pairs(oldAlts) do
                if not newAlts[alt] then
                    QDKP2_ClearAlt(alt)
                end
            end
            
            -- Добавляем новых alts используя API QDKP2
            for alt, main in pairs(newAlts) do
                if not oldAlts[alt] then
                    QDKP2_MakeAlt(alt, main, true)  -- true = без подтверждения
                end
            end
            
            QDKP2_Debug(1, "Config", "API calls completed, updating GUI")
            
            -- Обновляем GUI
            QDKP2_DownloadGuild()
            QDKP2_RefreshAll()
            
            -- Выводим в чат список изменений
            if #addedAlts > 0 then
                QDKP2_Msg("Added " .. #addedAlts .. " alt relations:")
                for _, relation in ipairs(addedAlts) do
                    QDKP2_Msg("  " .. relation)
                end
            end
            if #removedAlts > 0 then
                QDKP2_Msg("Removed " .. #removedAlts .. " alt relations: " .. table.concat(removedAlts, ", "))
            end
            
            QDKP2_Msg("Alts list imported successfully")
            
            -- Принудительно сохраняем данные
            self:ForceSaveData()
        end,
        function()
            QDKP2_Debug(1, "Config", "User cancelled alts import")
            QDKP2_Msg("Alts import cancelled")
        end
    )
end

function QDKP2_Config:ForceSaveData()
    -- Пробуем разные методы сохранения
    if QDKP2_UpdateDatabase then
        QDKP2_UpdateDatabase()
        QDKP2_Debug(1, "Config", "Called QDKP2_UpdateDatabase")
    end
    
    if QDKP2_SaveData then
        QDKP2_SaveData()
        QDKP2_Debug(1, "Config", "Called QDKP2_SaveData")
    end
    
    -- Сохраняем переменные WoW
--    SaveVariables()
--    QDKP2_Debug(1, "Config", "Called SaveVariables")
    
    QDKP2_Msg("Data saved successfully")
end

function QDKP2_Config:CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end