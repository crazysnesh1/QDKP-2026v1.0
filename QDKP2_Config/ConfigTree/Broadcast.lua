
local L = QDKP2_Config.Localize

local function IfGM()
	if IsGuildLeader(UnitName("player")) then return true; end
end

local function IfNoGM()
	if not IfGM() then return true; end
end

local function GetRecipientList(info)	
  local v={z='Select the recipient'}
	for i=1,GetNumGuildMembers(true) do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile=GetGuildRosterInfo(i)
		if online then v[name]=name; end
	end
	return v
end

QDKP2_Config.Tree.args.Broadcast={
	type = 'group',
	name = L.BRC_Name,
	order=200,
	args ={
		BrcDesc1={
			type='description',
			name=QDKP2_Config.Colors.Emphasis..L.BrcDesc1,
			fontSize='medium',
			order=10,
		},
		BrcDesc2={
			type='description',
			order=20,
		},
		BRC_ActiveProf={
			type='description',
			fontSize='large',
			name=function()
				local str=string.format(L.BRC_ActiveProf, QDKP2_Config.DB:GetCurrentProfile())
				return QDKP2_Config.Colors.Emphasis..str
			end,
			order=30,
		},
		BRC_GuildProf={
			type='description',
			hidden=IfGM,
			fontSize='large',
			name=function()
				local str=string.format(L.BRC_GuildProf, QDKP2_Config.Profile.BCT_ProfileName or '')
				return QDKP2_Config.Colors.Emphasis..str 
			end,
			order=40,
		},
		BRC_SendGM={
			type='execute',
			func=function() QDKP2_Config:SendActiveProfile(QDKP2_Config:GetGM()); end,
			hidden=IfGM,
			order=50,
		},
		BRC_SendToAll={
			type='execute',
			func=function(info) QDKP2_Config:SendActiveProfile('GUILD'); end,
			hidden=IfNoGM,
			order=60,
		},
		BRC_SendToName={
			type='select',
			values=GetRecipientList,
			get=function() return 'z'; end,
			set=function(i,v) if v~='z' then QDKP2_Config:SendActiveProfile(v); end; end,
			disabled=function(info) return QDKP2_Config.Profile.BRC_AutoSendEn; end,
			hidden=IfNoGM,
			order=70,
		},
		Desc3=QDKP2_Config:GetBreak(80),

		BRC_AutoSendEn={
			type='toggle',
			hidden=IfNoGM,
			order=90,
		},
		BRC_AutoSendTime={
			type = 'range', min = 0.17, softMin=10, bigStep=10, softMax=180, max = 1440,
			disabled=function(info) if not QDKP2_Config.Profile.BRC_AutoSendEn then return true; end; end,
			hidden=IfNoGM,
			order=100,
		},
		BRC_OverrideBroadcast={
			type='toggle',
			hidden=IfGM,
			order = 110,
		},
		        -- Новые кнопки для отправки externals и alts
		SendExternals = {
			type = 'execute',
			name = L.BRC_SendExternals,
			desc = L.BRC_ToolExternals,
			func = function()
				if QDKP2_OfficerMode() then
					QDKP2_Config:SendExternals('GUILD')
				else
					QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
				end
			end,
			order = 120,
		},
		SendAlts = {
			type = 'execute',
			name = L.BRC_SendAlts, 
			desc = L.BRC_ToolAlts,
			func = function()
				if QDKP2_OfficerMode() then
					QDKP2_Config:SendAlts('GUILD')
				else
					QDKP2_Msg(QDKP2_LOC_NoRights, "ERROR")
				end
			end,
			order = 130,
		},
	},
}

