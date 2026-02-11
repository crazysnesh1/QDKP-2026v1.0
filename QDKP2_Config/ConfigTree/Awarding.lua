local L=QDKP2_Config.Localize



----------------------Helper functions---------------------------

-- Award by boss

local function GetName(info)
	local i=tonumber(info[#info]) or tonumber(info[#info-1]) --so it can work both for the group and the input types
	local v=QDKP2_Config.Profile.Boss_Names[i]
	if v then return v.name or ''
	else return '!!VOID!!'
	end
end

local function SetName(info,value)
	local i=tonumber(info[#info-1])
	QDKP2_Config.Profile.Boss_Names[i].name=value
end

local function GetBossVoice(info)
	local i=info[#info-1]
	local field
	if string.find(info[#info],'10N') then field='DKP_10N'
	elseif string.find(info[#info],'10H') then field='DKP_10H'
	elseif string.find(info[#info],'25N') then field='DKP_25N'
	else field = 'DKP_25H'
	end
	local voice=QDKP2_Config.Profile.Boss_Names[tonumber(i)]
	return voice, field
end

local function SetCustom(info, value)
	local voice, field=GetBossVoice(info)
	voice[field]=tonumber(value)
end

local function GetCustom(info)
	local voice, field=GetBossVoice(info)
	local a=voice[field]
	if not a or a==0 then return ''
	else return tostring(a)
	end
end

local function SetSelect(info,value)
	if value==3 then SetCustom(info,"0")
	elseif value==1 then SetCustom(info, nil)
	else SetCustom(info,"1")
	end
end

local function GetSelect(info)
	local voice, field=GetBossVoice(info)
	local a=voice[field]
	if not a then return 1
	elseif a==0 then return 3
	else return 2
	end
end

local function IsDisabledCA(info)
	local a=GetCustom(info)
	if a=='' then return true; end
end

local function AddBoss(info)  
	table.insert(QDKP2_Config.Profile.Boss_Names,{name='NewEntry'})
	QDKP2_Config.AceConfigDialog:SelectGroup("QDKP_V2", Awarding,BA,ByName,tostring(#QDKP2_Config.Profile.Boss_Names))
end

local function RemoveBoss(info)
local i=info[#info-1]
	table.remove(QDKP2_Config.Profile.Boss_Names,i)
end


-- Award by instance

local function SetInstance(info,value)
	local size,i=string.match(info[#info],"Inst([%dHN]+)_(%d+)")
	local field='DKP_'..size
	local voice=QDKP2_Config.Profile.Boss_Instance[tonumber(i)]
	voice[field]=tonumber(value)
end

local function GetInstance(info)
	local size,i=string.match(info[#info],"Inst([%dHN]+)_(%d+)")
	local field='DKP_'..size
	local voice=QDKP2_Config.Profile.Boss_Instance[tonumber(i)]
	return tostring(voice[field] or 0)
end

local function GetInstName(info)
	local i=tonumber(string.match(info[#info],'(%d+)$'))
	local voice = QDKP2_Config.Profile.Boss_Instance[i]
	if not voice then return ''
	else return voice.name
	end
end

local function GetOrder(info)
	local i=tonumber(string.match(info[#info],'(%d+)$'))
	local o=tonumber(string.match(info[#info],'^(%d+)'))
	return i*10+o-1
end

local function GetAmountName(info)
	local t=(string.match(info[#info],'^%d([^_]+)'))
	if      t=='Inst10N' then return "10 Normal"
	elseif t=='Inst10H' then return "10 Heroic"
	elseif t=='Inst25N' then return "25 Normal" 
	elseif t=='Inst25H' then return "25 Heroic"
	end
end

local function GetHidden(info)
	if GetInstName(info)=='' then return true; end
end


-- Award exceptions

local function GetAwPerc(info)
	local var=QDKP2_Config:GetVar(info)
	if var==true then return 1
	elseif not var then return 0
	end
	var=string.gsub(var,'%%','')
	return tonumber(var)/100 or 0
end

local function SetAwPerc(info, value)
	if value==0 then value=false
	elseif value==1 then value=true
	else value=tostring(value*100)..'%' 
	end
	QDKP2_Config:SetVar(info,value)
end

local function GetColName(info)
	local n=info[#info]
	local sys=string.match(n,'AW_%a+_(%a+)')
	local v=GetAwPerc(info)
	local col
	if v==0 then col=QDKP2_Config.Colors.Disabled
	elseif v==1 then col=QDKP2_Config.Colors.Enabled
	else col=''
	end
	return col..L['AW_'..sys]
end



-------------------- TREES ----------------------------

--main

QDKP2_Config.Tree.args.Awarding={
	type = 'group',
	--childGroups = 'tab',
	order = 1,
	args={

		--Raid award (and boss)
		BA={
			type='group',
			--childGroups = 'select',
			args={
			
			--Award by Instance
				ByInstance={
					type='group',
					order=1,
					set=SetInstance,
					get=GetInstance,
					args={
					InstHelpText={
						type = 'description',
						name = "Set DKP awards for raid instances. Use 0 for no award.",
						--fontSize='medium',
						order=1,
						},
					Spacer1=QDKP2_Config:GetBreak(2),
					},
				},
				
				--Award by Name
				ByName={
					type='group',
					order=2,
					args={
						AddNewBoss={
							type='execute',
							func=AddBoss,
							order=1,
							name = "Add Custom Boss",
							desc = "Add a custom boss with specific DKP awards",
						},
					},
				},
			},
		},
		
		--Hourly bonus
		TIM={
			type='group',
			order=2,
			args={
				AW_TIM_Period={
					type='range',
					min=6,step=6,softMax=60,max=600,
					order=1,
					name = "Timer Period (minutes)",
					desc = "Time between hourly DKP awards"
				},
				AW_TIM_ShowAward={
					type='toggle',
					order=2,
					name = "Show Award Messages",
					desc = "Display messages when players receive hourly DKP"
				},
				AW_TIM_RaidLogTicks={
					type='toggle',
					order=3,
					name = "Log Timer Ticks",
					desc = "Record timer ticks in raid log"
				},
			},
		},
		
		--IronMan
		IM={
			type='group',
			order=3,
			args={
				AW_IM_PercReq={
					type='range',
					min=0,bigStep=5,max=100,
					order=1,
					name = "Attendance % Required",
					desc = "Minimum raid attendance percentage for IronMan bonus"
				},
				AW_IM_InWhenStarts={
					type='toggle',
					order=2,
					name = "Must Be Present at Start",
					desc = "Player must be in raid when IronMan starts"
				},
				AW_IM_InWhenEnds={
					type='toggle',
					order=3,
					name = "Must Be Present at End", 
					desc = "Player must be in raid when IronMan ends"
				},
			},
		},
		
		--ZeroSum
		ZS={
			type='group',
			order=4,
			args={
				AW_ZS_UseAsCharge={
					type='toggle',
					order=1,
					name = "Use ZeroSum as Default Charge",
					desc = "Use ZeroSum method for loot charges by default"
				},
				AW_ZS_GiveZS2Payer={
					type='toggle',
					order=2,
					name = "Give ZeroSum to Payer",
					desc = "Include the payer in ZeroSum distribution"
				},
			},
		},
	}
}



-- Award exceptions

local CtlHeader={
	type='header',
	order=100,
	name = "Award Exceptions",
}
local order={OfflineCtl=101,ZoneCtl=102,RankCtl=103,AltCtl=104,StandbyCtl=105,ExternalCtl=106}
local CtlSlider={
	type='range',
	min=0, step=0.01, bigStep=0.05, softMax=1, max=2.55,
	isPercent=true,
	name=GetColName,
	desc=function(info) local n=info[#info]; local sys=string.match(n,'AW_%a+_(%a+)'); return L['AW_'..sys..'_d']; end,
	order=function(info) local n=info[#info]; local sys=string.match(n,'AW_%a+_(%a+)'); return order[sys]; end,
	get=GetAwPerc,
	set=SetAwPerc,
}

for i,aw in pairs(QDKP2_Config.Tree.args.Awarding.args) do
	aw.args.AW_CtlHeader=CtlHeader
	for j,sys in pairs({"Offline","Zone","Rank","Alt","Standby","External"}) do
		local name="AW_"..i.."_"..sys.."Ctl"
		aw.args[name]=CtlSlider
	end
end
	
	

	
--Award by boss

local BossVoice={
	type = 'group',
	name = GetName,
	hidden = function(info) if GetName(info)=='!!VOID!!' then return true; end; end,
	order = function(info) return tonumber(info[#info]); end,
	args = {
		BossName={
			type='input',
			set=SetName,
			get=GetName,
			pattern='.+', --no null strings.
			name="Boss Name",
			desc="Name of the boss (case insensitive)",
			order=10,
		},
		AW_Boss_UseTarget={
			type='execute',
			name="Use Target",
			disabled=function(info) if not UnitName("target") then return true; end; end,
			func=function(info) SetName(info, UnitName("target")); end,
			order=12,
		},
		Break1=QDKP2_Config:GetBreak(15),
		
		-- 10 Player Normal
		Select10N={
			type = 'select',
			values ={"Default instance awards","Custom amounts","No awards"},
			name = "10 Player Normal",
			desc = "DKP award for 10 player normal mode",
			set=SetSelect,
			get=GetSelect,
			order=20,
		},
		CustomAmount10N={
			type = 'input',
			disabled=IsDisabledCA,
			name = "Custom DKP Amount",
			set=SetCustom,
			get=GetCustom,
			order=30,
			pattern = '^-?%d+$',
		},
		Break2=QDKP2_Config:GetBreak(35),
		
		-- 10 Player Heroic
		Select10H={
			type = 'select',
			values ={"Default instance awards","Custom amounts","No awards"},
			name = "10 Player Heroic", 
			desc = "DKP award for 10 player heroic mode",
			set=SetSelect,
			get=GetSelect,
			order=40,
		},
		CustomAmount10H={
			type = 'input',
			disabled=IsDisabledCA,
			name = "Custom DKP Amount",
			set=SetCustom,
			get=GetCustom,
			pattern = '^-?%d+$',
			order=50,
		},
		Break3=QDKP2_Config:GetBreak(55),
		
		-- 25 Player Normal
		Select25N={
			type = 'select',
			values ={"Default instance awards","Custom amounts","No awards"},
			name = "25 Player Normal",
			desc = "DKP award for 25 player normal mode",
			set=SetSelect,
			get=GetSelect,
			order=60,
		},
		CustomAmount25N={
			type = 'input',
			disabled=IsDisabledCA,
			name = "Custom DKP Amount",
			set=SetCustom,
			get=GetCustom,
			pattern = '^-?%d+$',
			order=70,
		},
		Break4=QDKP2_Config:GetBreak(75),
		
		-- 25 Player Heroic
		Select25H={
			type = 'select',
			values ={"Default instance awards","Custom amounts","No awards"},
			name = "25 Player Heroic",
			desc = "DKP award for 25 player heroic mode", 
			set=SetSelect,
			get=GetSelect,
			order=80,
		},
		CustomAmount25H={
			type = 'input',
			disabled=IsDisabledCA,
			name = "Custom DKP Amount",
			set=SetCustom,
			get=GetCustom,
			pattern = '^-?%d+$',
			order=90,
		},
		Break5=QDKP2_Config:GetBreak(95),
		
		RemoveBoss={
		  name="Remove Boss",
			type = 'execute',
			func=RemoveBoss,
			confirm=true,
			confirmText="Are you sure you want to remove this boss?",
			order=100,
		},
	},
}

for i=1,99 do --maximum of 99 boss names entries
	QDKP2_Config.Tree.args.Awarding.args.BA.args.ByName.args[tostring(i)]=BossVoice
end



--Award by instance

local InstName={
	type = 'description',
	fontSize  = 'medium',
	name = GetInstName,
	hidden = GetHidden,
	order = GetOrder,
}
local InstAmount={
	type = 'input',
	name = GetAmountName,
	width='half',
	pattern = '^-?%d+$',
	hidden = GetHidden,
	order=GetOrder,
}

for i=1,20 do --maximum of 20 instances entries
	local tab=QDKP2_Config.Tree.args.Awarding.args.BA.args.ByInstance.args
	tab["1InstName"..tostring(i)]=InstName
	tab["2Inst10N_"..tostring(i)]=InstAmount
	tab["3Inst10H_"..tostring(i)]=InstAmount
	tab["4Inst25N_"..tostring(i)]=InstAmount
	tab["5Inst25H_"..tostring(i)]=InstAmount
end