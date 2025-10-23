#include <amxmodx>
#include <engine>
#include <fakemeta>

#if AMXX_VERSION_NUM < 183
	#include <dhudmessage>
	#include <colorchat>
#else
	#define DontChange print_team_default
#endif

#pragma ctrlchar			'\'
#pragma semicolon			1

/***** SETTING DEFINE START *****/

#define ALLOW_MODE			// Разрешить использовать команду "/mode"
#define ALLOW_CHANGE			// Разрешить использовать команду "/change"

#define CHECK_FORCE_ONLINE		// Заставлять проверять онлайн даже при /change, если нет действующих админов в игре, кроме админов в спектаторе, при ADMIN_ONE_ONLY, проверяет только одного активного админа.
#define STATE_USE			// Использовать динамические статы
//#define ADD_MORE_CHECK		// Дополнительные проверки (имхо лишние)
//#define ADMIN_ONE_ONLY		// Запрещает второму админу использовать команду "/change", если первый админ его уже использовал для открытия карты и если админ который активировал "/change" - активный и находится в команде. (Не проверено)
#define MODE_DESCRIPTON			// Отображать при режиме 2x2 в GameDescripton, что включен режим "Mode:карта_2x2"
#define MOVE_COORD_DUST2		// Сместить координаты спавнов T на карте de_dust2, которые находятся за аркой.
#define WEAPONBOX_PUSH			// Толкать weaponbox (оружия, C4) от стенки
#define GAME_COMMENCING			// Никогда не ставить стенки при "GameCommencing" или "Restart"
#define MODE_TOUCHMESSAGE		// Сообщать игроку при касании стены о том, что проход закрыт.

#if defined MODE_TOUCHMESSAGE
	#define MESSAGE_TIMEWAIT	5.5	// Задержка для повторного сообщения при касании стенки игроком.
#endif

					//x	//y
#define MESSAGE_MAP_STATUS		-1.0,	0.8				// Позиция сообщении о Закрытии/Открытии карты.


					//r	//green		//blue
#define COLOR_MAP_CLOSE			255,	0,		0		// Цвет сообщения, когда низкий онлайн и карта закрывается. Тип цвета RGB, http://www.colorschemer.com/online.html
#define COLOR_MAP_OPEN			0,	255,		0		// Цвет сообщения, когда онлайн выше требуемого и карта открывается. Тип цвета RGB, http://www.colorschemer.com/online.html

#if defined ALLOW_MODE

#define MODE_TIME_START			10.0	// Через сколько начать голосование, после нужного количества голосов.
#define MODE_COUNT_START		5	// Отчет до начала голосования
#define VOTE_TIMEWAIT			3	// Через сколько минут после голосования /mode, будет снова доступно.
#define VOTE_RATIO			0.5	// Погрешность для количество голосов, Пример: (Ratio: 0.5, требуется 0.5 * 32 = 16 голосов из 32 игроков)

#endif
#define STRONG_PUSH			15.0	// Сила толчка weaponbox (оружия, C4) от стенки

#if defined ALLOW_CHANGE
#define ALLOW_ALL
#else
#if defined ALLOW_MODE
#define ALLOW_ALL
#else
#if defined GAME_COMMENCING
#endif
#endif
#endif

/***** SETTING DEFINE END *****/

#define MAX_PLAYERS			32
#define PREFIX				"\1[\4Mode\1]"
#define CLASSNAME_WALL			"info_mode"
#define SPRITE_WALL			"sprites/mode/wall.spr"

#if defined ALLOW_MODE
#define IsRatio				(floatround(VOTE_RATIO * checkNumPlayers()))
#endif

#define IsUserTeam(%0)			(1 <= get_pdata_int(%0,114) <= 2)
#define IsUserFlags(%0,%1)		(get_user_flags(%0) & %1)
#define IsUserAValid(%0)		(1 <= %0 <= g_pServerVar[m_iMaxpl] && is_user_alive(%0))

#define CheckPlayers			(g_pServerVar[m_iOnline] > checkNumPlayers())

#define Vector(%0,%1,%2)		(Float:{%0,%1,%2})
#define VectorEqual(%0,%1)		(%0[x] == %1[x] && %0[y] == %1[y] && %0[z] == %1[z])
#define VectorDT(%0,%1,%2,%3)		(!(%0[x] > %3[x] || %1[x] < %2[x]) && !(%0[y] > %3[y] || %1[y] < %2[y]) && !(%0[z] > %3[z] || %1[z] < %2[z]))

#if defined STATE_USE
#define STATEMENT_FALLBACK(%0,%1,%2)	public %0()<>{return %1;} public %0()<%2>{return %1;}
#endif

#if defined ALLOW_MODE
enum (+= 256222)
{
	TASK_MODE_VOTE = 256222,
	TASK_MODE_START
};
#endif

enum _:coord_s
{
	Float:x,
	Float:y,
	Float:z
};

enum _:status_s
{
	box_open = 0,
	box_close,
};

#if defined ALLOW_ALL
enum _:blocked_s
{
	block_none = 0,
	block_vote,
	block_start_vote,
	block_success_vote,
	block_roundnew,
	block_commencing,
	block_admin_change,
	block_permament
}
#else
#if defined GAME_COMMENCING
enum _:blocked_s
{
	block_none = 0,
	block_commencing = 5
}
#endif
#endif

#if defined ALLOW_MODE
enum _:vote_s
{
	vote_no,
	vote_yes
};
#endif

enum server_box_s
{
	m_fOrigin,
	m_fAngles,
	m_fMins,
	m_fMaxs
};

enum _:server_info_s
{
	m_iNone,
#if defined ALLOW_MODE
	m_iAll,
#endif
	m_iBox,
	m_iCopy,
	m_iType,
	m_iEntid,
	m_iSetting,
	m_iSolid,
	m_iMaxpl,
#if defined ALLOW_ALL
	blocked_s:m_iBlocked,
#else
	#if defined GAME_COMMENCING
	blocked_s:m_iBlocked,
	#endif
#endif
	m_szFile[64],
#if defined ALLOW_MODE
	m_iCount,
#endif
	m_iThink,
	bool:m_bAdvanced,
#if defined ADMIN_ONE_ONLY
	m_iClose,
#endif
#if defined MODE_DESCRIPTON
	m_szDescr[64],
#endif
	m_iOnline,
	m_iSprite,
	status_s:m_iStatus,
	m_szMap[32],
#if defined ALLOW_MODE
	m_iVoting[vote_s],
	m_iVote[MAX_PLAYERS + 1],
	Float:m_fNext,
#endif
	Float:m_fWait[MAX_PLAYERS + 1],
	Float:m_fScale
};

new g_pServerVar[server_info_s];
new Float:g_pServerBox[server_box_s][coord_s];

public plugin_precache()
{
	get_mapname(g_pServerVar[m_szMap],31);

#if defined STATE_USE
	#if defined MOVE_COORD_DUST2
	if(equal(g_pServerVar[m_szMap],"de_dust2"))
	{
		state stpfnSpawn:Enabled;
	}
	#endif
#endif
	precache_model(SPRITE_WALL);
}
public plugin_init()
{
	register_plugin("Mode 2x2","1.9","s1lent");

	#if defined ALLOW_MODE
	register_clcmd("say /mode","cmdMode");
	#endif
	register_clcmd("say /box","cmdMenuBox",ADMIN_RCON,"<Управление объектами, Создание/Изменение/Удаление>");

	#if defined ALLOW_CHANGE
	register_clcmd("say /change","cmdModeChange",ADMIN_VOTE,"<Смена режима Mode 2x2, Открыть/Закрыть карту>");
	#endif

	register_menucmd(register_menuid("Main Edit Menu"),0x3FF,"mainEditHandler");
	register_menucmd(register_menuid("Setting Menu"),0x3FF,"settingHandler");
	register_menucmd(register_menuid("Properties Menu"),0x3FF,"propertiesHandler");

	register_dictionary("mode.txt");

	g_pServerVar[m_iMaxpl] = get_maxplayers();
	#if defined ALLOW_MODE
	g_pServerVar[m_fNext] = _:(get_gametime() + (VOTE_TIMEWAIT * 60.0));

	#endif
	loadConfig();
}
loadConfig()
{
#if defined STATE_USE
	#if defined MOVE_COORD_DUST2
	state stpfnSpawn:Disabled;
	#endif
#endif
	get_localinfo("amxx_configsdir",g_pServerVar[m_szFile],63);

	add(g_pServerVar[m_szFile],63,"/mode/");

	if(!dir_exists(g_pServerVar[m_szFile]))
	{
		mkdir(g_pServerVar[m_szFile]);
	}
	formatex(g_pServerVar[m_szFile],63,"%s%s.ini",g_pServerVar[m_szFile],g_pServerVar[m_szMap]);
	if(file_exists(g_pServerVar[m_szFile]))
	{
		g_pServerVar[m_iNone] = boxLoad();
		showBox(g_pServerVar[m_iStatus] = box_open,.bShow = false);

		#if defined MODE_DESCRIPTON
			formatex(g_pServerVar[m_szDescr],63,"Mode: %s_2x2",g_pServerVar[m_szMap]);
			register_forward(FM_GetGameDescription,"pfnGetGameDescription");
		#endif
		#if defined MODE_TOUCHMESSAGE
			register_touch(CLASSNAME_WALL,"player","pfnTouch");
		#endif
		#if defined WEAPONBOX_PUSH
			register_touch("weaponbox",CLASSNAME_WALL,"pfnTouchWeaponBox");
		#endif

		#if defined ALLOW_MODE
		register_menucmd(register_menuid("Mode Menu"),0x03,"modemenu");
		#endif

		register_event("HLTV","RoundNew","a","1=0","2=0");
		#if defined GAME_COMMENCING
		register_event("TextMsg","GameCommencing","a","2=#Game_Commencing","2=#Game_will_restart_in");
		#endif
	}
}
public plugin_end()
{
#if defined ALLOW_MODE
	if(task_exists(TASK_MODE_VOTE))
	{
		remove_task(TASK_MODE_VOTE);
	}
	if(task_exists(TASK_MODE_START))
	{
		remove_task(TASK_MODE_START);
	}
#endif
	if(g_pServerVar[m_iThink] && !g_pServerVar[m_iNone])
	{
		boxSave(0); // Force save box
	}
}
public client_disconnect(id)
{
	if(!g_pServerVar[m_iNone])
	{
		return;
	}
#if defined ADMIN_ONE_ONLY
	if(g_pServerVar[m_iClose] == id)
	{
		g_pServerVar[m_iClose] = 0;
	}
#endif
#if defined ALLOW_MODE
	if(g_pServerVar[m_iVote][id])
	{
		g_pServerVar[m_iAll]--;
		g_pServerVar[m_iVote][id] = 0;
	}
#endif
}
#if defined GAME_COMMENCING
public GameCommencing()
{
	g_pServerVar[m_iBlocked] = blocked_s:block_commencing;
	showBox((g_pServerVar[m_iStatus] = status_s:box_open),.bShow = false);
}
#endif
public RoundNew()
{
#if defined ALLOW_CHANGE
#if defined CHECK_FORCE_ONLINE
	if(g_pServerVar[m_iBlocked] > blocked_s:block_admin_change)
	{
		new iNum;
		for(new a = 1; a <= g_pServerVar[m_iMaxpl]; a++)
		{
			if(!is_user_connected(a) || !IsUserFlags(a,ADMIN_VOTE) || !IsUserTeam(a))
			{
				continue;
			}
#if defined ADMIN_ONE_ONLY
			if(g_pServerVar[m_iClose] != a)
			{
				continue;
			}
#endif
			iNum++;
		}
		if(!iNum)
		{
			if(CheckPlayers)
			{
				g_pServerVar[m_iBlocked] = blocked_s:block_none;
				showBox((g_pServerVar[m_iStatus] = status_s:box_close),true);
			}
		}
	}
	else
#endif
#endif

#if !defined ALLOW_ALL
#if defined GAME_COMMENCING
	if(g_pServerVar[m_iBlocked] == blocked_s:block_commencing)
		g_pServerVar[m_iBlocked] = blocked_s:block_none;
#endif
#endif
#if defined ALLOW_ALL
	if(g_pServerVar[m_iBlocked])
	{
		switch(g_pServerVar[m_iBlocked])
		{
			case block_success_vote:
			{
				showBox(g_pServerVar[m_iStatus],true);
				g_pServerVar[m_iBlocked] = blocked_s:block_roundnew;
			}
			#if defined GAME_COMMENCING
			case block_commencing:
			{
				g_pServerVar[m_iBlocked] = blocked_s:block_none;
			}
			#endif
			case block_admin_change:
			{
				showBox(g_pServerVar[m_iStatus],true);
				g_pServerVar[m_iBlocked] = blocked_s:block_permament;
			}
		}
	}
	else
#endif
	if(CheckPlayers)
	{
		if(g_pServerVar[m_iStatus] == status_s:box_open)
		{
			showBox((g_pServerVar[m_iStatus] = status_s:box_close),true);
		}
	}
	else
	{
		if(g_pServerVar[m_iStatus] == status_s:box_close)
		{
			showBox((g_pServerVar[m_iStatus] = status_s:box_open),true);
		}
	}
}

#if defined MOVE_COORD_DUST2
public pfn_spawn(ent)
#if defined STATE_USE
	<stpfnSpawn:Enabled>
#endif
{
	#if !defined STATE_USE
	if(!equal(g_pServerVar[m_szMap],"de_dust2"))
	{
		return 0;
	}
	#endif
	static classname[32];
	entity_get_string(ent,EV_SZ_classname,classname,31);
	if(equali(classname,"info_player_deathmatch"))
	{
		static Float:vec[coord_s];
		entity_get_vector(ent,EV_VEC_origin,vec);

		static Float:looking[][coord_s] =
		{
			{-1024.0, -800.0, 176.0},
			{-1024.0, -704.0, 176.0},
			{-1024.0, -896.0, 192.0},

			{-826.0, -970.0, 200.0},
			{-726.0, -970.0, 200.0},
			{-626.0, -970.0, 200.0}
		};
		for(new b = 0; b < sizeof(looking) / 2; b++)
		{
			if(VectorEqual(vec,looking[b]))
			{
				entity_set_vector(ent,EV_VEC_origin,looking[b + 3]);
				break;
			}
		}
	}
	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfn_spawn,0,stpfnSpawn:Disabled)
#endif
#endif

public pfnThink(ent)
#if defined STATE_USE
	<stpfnThink:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(g_pServerVar[m_iEntid]) || !is_valid_ent(ent) || g_pServerVar[m_iEntid] != ent)
	{
		return 0;
	}
	#else
	if(g_pServerVar[m_iEntid] != ent)
	{
		return 0;
	}
	#endif
	static Float:b_mins[coord_s],Float:b_maxs[coord_s],Float:b_origin[coord_s];
	entity_get_vector(ent,EV_VEC_origin,b_origin);
	entity_get_vector(ent,EV_VEC_mins,b_mins);
	entity_get_vector(ent,EV_VEC_maxs,b_maxs);

	engfunc(EngFunc_MessageBegin,MSG_BROADCAST,SVC_TEMPENTITY,b_origin);
	write_byte(TE_BOX);
	engfunc(EngFunc_WriteCoord,(b_mins[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_mins[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_mins[z] += b_origin[z]));
	engfunc(EngFunc_WriteCoord,(b_maxs[x] += b_origin[x]));
	engfunc(EngFunc_WriteCoord,(b_maxs[y] += b_origin[y]));
	engfunc(EngFunc_WriteCoord,(b_maxs[z] += b_origin[z]));
	write_short(2);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	message_end();

	return entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnThink,0,stpfnThink:Disabled)
#endif

#if defined WEAPONBOX_PUSH
public pfnTouchWeaponBox(ent,id)
#if defined STATE_USE
	<stMode:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !is_valid_ent(id)) // why do it?!
	{
		return 0;
	}
	#endif
	new Float:velocity[3];
	get_global_vector(GL_v_forward,velocity);

	velocity[x] = -velocity[x] * STRONG_PUSH;
	velocity[y] = -velocity[y] * STRONG_PUSH;
	velocity[z] = -velocity[z] * STRONG_PUSH;

	entity_set_vector(ent,EV_VEC_velocity,velocity);

	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnTouchWeaponBox,0,stMode:Disabled)
#endif
#endif

#if defined MODE_DESCRIPTON
public pfnGetGameDescription()
#if defined STATE_USE
	<stMode:Enabled>
#endif
{
	#if !defined STATE_USE
	if(g_pServerVar[m_iStatus] != status_s:box_close)
	{
		return FMRES_IGNORED;
	}
	#endif

	forward_return(FMV_STRING,g_pServerVar[m_szDescr]);
	return FMRES_SUPERCEDE;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnGetGameDescription,0,stMode:Disabled)
#endif
#endif

#if defined MODE_TOUCHMESSAGE
public pfnTouch(ent,id)
#if defined STATE_USE
	<stMode:Enabled>
#endif
{
	#if defined ADD_MORE_CHECK
	if(!is_valid_ent(ent) || !IsUserAValid(id)) // why do it?!
	{
		return 0;
	}
	#else
	if(!is_user_alive(id))
	{
		return 0;
	}
	#endif

	static Float:currentTime;
	currentTime = get_gametime();
	if(currentTime > g_pServerVar[m_fWait][id])
	{
		g_pServerVar[m_fWait][id] = _:(currentTime + MESSAGE_TIMEWAIT);
		return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_MESSAGE_TOUCH");
	}
	return 0;
}
#if defined STATE_USE
STATEMENT_FALLBACK(pfnTouch,0,stMode:Disabled)
#endif
#endif

#if defined ALLOW_CHANGE
public cmdModeChange(id,level,cid)
{
	if(!IsUserFlags(id,level))
	{
		return 0;
	}
	if(!g_pServerVar[m_iNone])
	{
		return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_NOT_USED");
	}

#if defined ADMIN_ONE_ONLY
	if(g_pServerVar[m_iClose] != id)
	{
		if(is_user_connected(g_pServerVar[m_iClose]))
		{
			new name[32];
			get_user_name(id,name,31);
			return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_ADMIN_BUSY_CHANGE",name);
		}
	}
#endif
	switch(g_pServerVar[m_iBlocked])
	{
		case block_vote: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_VOTE");
		case block_start_vote: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_START_VOTE");
		case block_success_vote: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_WAIT_NEW_ROUND");
		case block_admin_change: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_ADMIN_CHANGED",id,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_ADMIN_CLOSED" : "MODE_ADMIN_OPENED");
	}
	g_pServerVar[m_iBlocked] = blocked_s:block_admin_change;
	#if defined ALLOW_MODE
	g_pServerVar[m_fNext] = _:(get_gametime() + (VOTE_TIMEWAIT * 60.0));
	#endif
	g_pServerVar[m_iStatus] ^= status_s:box_close;
#if defined ADMIN_ONE_ONLY
	g_pServerVar[m_iClose] = (g_pServerVar[m_iStatus] == status_s:box_open) ? id : 0;
#endif
	new name[32];
	get_user_name(id,name,31);
	for(new a = 1; a <= g_pServerVar[m_iMaxpl]; a++)
	{
		if(!is_user_connected(a) || !IsUserFlags(a,ADMIN_VOTE))
		{
			continue;
		}
		client_print_color(a,DontChange + id,"%L %L",a,"MODE_PREFIX",a,"MODE_ADMIN_CHANGED_ADMINS",name,a,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_ADMIN_CLOSED" : "MODE_ADMIN_OPENED");
	}
	return 1;
}
#endif

#if defined ALLOW_MODE
public cmdMode(id)
{
	if(!g_pServerVar[m_iNone])
	{
		return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_NOT_USED");
	}
	switch(g_pServerVar[m_iBlocked])
	{
		case block_vote: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_VOTE");
		case block_start_vote: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_START_VOTE");
		case block_admin_change: return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_ADMIN_CHANGED",id,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_ADMIN_CLOSED" : "MODE_ADMIN_OPENED");
	}
	new Float:flCurrent = get_gametime();
	if(g_pServerVar[m_fNext] > flCurrent)
	{
		new ibuf[64];
		getChangeleft(id,floatround(g_pServerVar[m_fNext] - flCurrent),ibuf,63);
		return client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_VOTE_LEFT",ibuf);
	}
	else
	{
		new num = IsRatio;

		if(g_pServerVar[m_iVote][id])
		{
			client_print_color(id,DontChange,"%L %L",id,"MODE_PREFIX",id,"MODE_VOTE_ALREADY",g_pServerVar[m_iAll],num);
		}
		else
		{
			g_pServerVar[m_iAll]++;
			g_pServerVar[m_iVote][id] = 1;

			new name[32];
			get_user_name(id,name,31);
			for(new a = 1; a <= g_pServerVar[m_iMaxpl]; a++)
			{
				if(!is_user_connected(a))
				{
					continue;
				}
				client_print_color(a,DontChange + id,"%L %L",id,"MODE_PREFIX",id,"MODE_VOTED",name,id,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_VOTE_OPENED" : "MODE_VOTE_CLOSED",g_pServerVar[m_iAll],num);
			}
			if(num <= g_pServerVar[m_iAll])
			{
				g_pServerVar[m_iCount] = MODE_COUNT_START;
				g_pServerVar[m_iBlocked] = blocked_s:block_vote;

				set_task(MODE_TIME_START,"taskidMenu",TASK_MODE_START);
				client_print_color(0,DontChange,"%L %L",LANG_PLAYER,"MODE_PREFIX",LANG_PLAYER,"MODE_MESSAGE_VOTE_START",10);
			}
		}
	}
	return 1;
}
public taskidMenu()
{
	if(0 < g_pServerVar[m_iCount]--)
	{
		new menu[128],speak[24];

		num_to_word(g_pServerVar[m_iCount] + 1,speak,23);
		client_cmd(0,"spk \"fvox/%s\"",speak);

		formatex(menu,127,"%L",LANG_PLAYER,"MODE_VOTE_PRESTART_MENU",LANG_PLAYER,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_TITLE_OPENED" : "MODE_TITLE_CLOSED",g_pServerVar[m_iCount] + 1);
		show_menu(0,0x3FF,menu,2,"Mode Menu");
		set_task(1.0,"taskidMenu",TASK_MODE_START);
	}
	else
	{
		new menu[128];
		g_pServerVar[m_iBlocked] = 2;
		formatex(menu,127,"%L",LANG_PLAYER,"MODE_VOTE_POSTSTART_MENU",LANG_PLAYER,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_TITLE_OPENED" : "MODE_TITLE_CLOSED");
		set_task(20.0,"taskidResult",TASK_MODE_VOTE);
		show_menu(0,0x3,menu,18,"Mode Menu");
	}
}
public modemenu(id,key)
{
	if(g_pServerVar[m_iBlocked] == blocked_s:block_vote)
	{
		return client_cmd(id,"slot%d",key + 1);
	}
	new name[32];
	get_user_name(id,name,31);
	client_print_color(0,DontChange + id,"%L",id,"MODE_VOTE_FORMAT",name,id,key ? "MODE_VOTE_NO" : "MODE_VOTE_YES");
	g_pServerVar[m_iVoting][key]++;
	return 0;
}
public taskidResult()
{
	g_pServerVar[m_iAll] = 0;
	g_pServerVar[m_fNext] = _:(get_gametime() + (VOTE_TIMEWAIT * 60.0));
	for(new id = 1; id <= g_pServerVar[m_iMaxpl]; id++)
	{
		g_pServerVar[m_iVote][id] = 0;
	}
	if(g_pServerVar[m_iVoting][vote_no] > g_pServerVar[m_iVoting][vote_yes])
	{
		g_pServerVar[m_iBlocked] = blocked_s:block_success_vote;
		g_pServerVar[m_iStatus] ^= status_s:box_close;

		client_print_color(0,DontChange,"%L %L",LANG_PLAYER,"MODE_PREFIX",LANG_PLAYER,"MODE_VOTE_RESULT",
			g_pServerVar[m_iVoting][vote_no],
			g_pServerVar[m_iVoting][vote_yes],
			g_pServerVar[m_iVoting][vote_no] + g_pServerVar[m_iVoting][vote_yes]);

		client_print_color(0,DontChange,"%L %L",
			LANG_PLAYER,"MODE_PREFIX",
			LANG_PLAYER,"MODE_VOTE_SUCCESS",
			LANG_PLAYER,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_RESULT_CLOSED" : "MODE_RESULT_OPENED");
	}
	else if(g_pServerVar[m_iVoting][vote_no] < g_pServerVar[m_iVoting][vote_yes])
	{
		g_pServerVar[m_iBlocked] = blocked_s:block_none;

		client_print_color(0,DontChange,"%L %L",LANG_PLAYER,"MODE_PREFIX",LANG_PLAYER,"MODE_VOTE_RESULT",
			g_pServerVar[m_iVoting][vote_no],
			g_pServerVar[m_iVoting][vote_yes],
			g_pServerVar[m_iVoting][vote_no] + g_pServerVar[m_iVoting][vote_yes]);

		client_print_color(0,DontChange,"%L %L",LANG_PLAYER,"MODE_PREFIX",LANG_PLAYER,"MODE_VOTE_FAILED");
	}
	else
	{
		g_pServerVar[m_iBlocked] = blocked_s:block_none;
		client_print_color(0,DontChange,"%L %L",LANG_PLAYER,"MODE_PREFIX",LANG_PLAYER,"MODE_VOTE_FAILED");
	}
}
#endif
public cmdMenuBox(id,level,cid)
{
	if(!IsUserFlags(id,level))
	{
		return 0;
	}
	if(!g_pServerVar[m_iThink])
	{
		g_pServerVar[m_iThink] = register_think(CLASSNAME_WALL,"pfnThink");
	}
	return showMainEditMenu(id);
}
showMainEditMenu(id)
{
	new menu[512];
	formatex(menu,511,
		"%L",id,"MODE_DEV_MENU_MAIN",
		g_pServerVar[m_iBox],
		g_pServerVar[m_iEntid] > 0 ? "\\d" : "\\w",
		g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
		g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
		id,g_pServerVar[m_iEntid] == 0 ? "MODE_DEV_CHANGE" : "MODE_DEV_SAVE",
		g_pServerVar[m_iEntid] == 0 ? "\\d" : "\\w",
		(g_pServerVar[m_iBox] == 0 || g_pServerVar[m_iEntid] > 0) ? "\\d" : "\\w",
		g_pServerVar[m_iCopy] == 0 ? "\\d" : "\\w",
		(g_pServerVar[m_iBox] == 0 || g_pServerVar[m_iEntid] > 0) ? "\\d" : "\\w"
	);
	return show_menu(id,0x3FF,menu,-1,"Main Edit Menu");
}
public mainEditHandler(id,key)
{
	switch(key)
	{
		case 0:
		{
			if(g_pServerVar[m_iEntid] > 0)
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_5");
				goto ret0;
			}
			new Float:p_origin[coord_s],ent = createWall(.bParse = false);
			entity_get_vector(id,EV_VEC_origin,p_origin);

			g_pServerVar[m_iBox]++;
			g_pServerVar[m_iEntid] = ent;
			p_origin[z] += 32.0;

			#if defined STATE_USE
				state stpfnThink:Enabled;
			#endif

			entity_set_vector(ent,EV_VEC_origin,p_origin);
			entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));
		}
		case 1:
		{
			new ent,dummy;
			get_user_aiming(id,ent,dummy);
			if(is_valid_ent(ent))
			{
				new classname[32];
				entity_get_string(ent,EV_SZ_classname,classname,31);
				if(equali(classname,CLASSNAME_WALL))
				{
					if(--g_pServerVar[m_iBox] < 0)
					{
						g_pServerVar[m_iBox] = 0;
					}
					if(g_pServerVar[m_iEntid] == ent)
					{
						g_pServerVar[m_iEntid] = 0;
					}
					remove_entity(ent);
					client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_1","SOLID_BBOX");
				}
				else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");
			}
			else if(is_valid_ent(g_pServerVar[m_iEntid]))
			{
				new ent = g_pServerVar[m_iEntid];
				new Float:v_absmins[coord_s],Float:v_absmaxs[coord_s],Float:e_absmin[coord_s],Float:e_absmax[coord_s];

				entity_get_vector(id,EV_VEC_absmin,v_absmins);
				entity_get_vector(id,EV_VEC_absmax,v_absmaxs);

				v_absmins[x] += 1.0;
				v_absmins[y] += 1.0;
				v_absmins[z] += 3.0;

				v_absmaxs[x] -= 1.0;
				v_absmaxs[y] -= 1.0;
				v_absmaxs[z] -= 17.0;

				entity_get_vector(ent,EV_VEC_absmin,e_absmin);
				entity_get_vector(ent,EV_VEC_absmax,e_absmax);

				if(VectorDT(e_absmin,e_absmax,v_absmins,v_absmaxs))
				{
					g_pServerVar[m_iBox]--;
					g_pServerVar[m_iEntid] = 0;
					client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_1",(entity_get_int(ent,EV_INT_solid) == SOLID_NOT) ? "SOLID_NOT" : "SOLID_BBOX");
					remove_entity(ent);
				}
			}
			else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");

			#if defined STATE_USE
			if(g_pServerVar[m_iEntid] == 0)
			{
				state stpfnThink:Disabled;
			}
			#endif
		}
		case 2:
		{
			if(is_valid_ent(g_pServerVar[m_iEntid]))
			{
				#if defined STATE_USE
					state stpfnThink:Disabled;
				#endif
				entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,SOLID_BBOX);
				entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_rendercolor,Vector(0.0,0.0,0.0));
				entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

				g_pServerVar[m_iEntid] = 0;
				g_pServerVar[m_fScale] = _:0.250;

				g_pServerBox[m_fMaxs][x] = 32.0;
				g_pServerBox[m_fMaxs][y] = 32.0;
				g_pServerBox[m_fMaxs][z] = 32.0;

				g_pServerBox[m_fMins][x] = -32.0;
				g_pServerBox[m_fMins][y] = -32.0;
				g_pServerBox[m_fMins][z] = -32.0;

				g_pServerBox[m_fOrigin][x] = 0.0;
				g_pServerBox[m_fOrigin][y] = 0.0;
				g_pServerBox[m_fOrigin][z] = 0.0;

				g_pServerBox[m_fAngles][x] = 0.0;
				g_pServerBox[m_fAngles][y] = 0.0;
				g_pServerBox[m_fAngles][z] = 0.0;

				client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_4");
			}
			else
			{
				new ent,body;
				get_user_aiming(id,ent,body);
				if(is_valid_ent(ent))
				{
					new classname[32];
					entity_get_string(ent,EV_SZ_classname,classname,31);
					if(equali(classname,CLASSNAME_WALL))
					{
						#if defined STATE_USE
							state stpfnThink:Enabled;
						#endif
						g_pServerVar[m_iEntid] = ent;

						entity_get_vector(ent,EV_VEC_mins,g_pServerBox[m_fMins]);
						entity_get_vector(ent,EV_VEC_maxs,g_pServerBox[m_fMaxs]);

						entity_get_vector(ent,EV_VEC_origin,g_pServerBox[m_fOrigin]);
						entity_get_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);

						g_pServerVar[m_fScale] = _:(entity_get_float(ent,EV_FL_scale));

						entity_set_int(ent,EV_INT_solid,SOLID_NOT);
						entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);
						entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));
						entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);
						client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_5");
					}
					else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");
				}
				else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");
			}
		}
		case 3:
		{
			if(!g_pServerVar[m_iEntid])
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_4");
				goto ret0;
			}
			return showPropertiesMenu(id);
		}
		case 4:
		{
			return showSettingsMenu(id);
		}
		case 5:
		{
			if(g_pServerVar[m_iEntid] > 0)
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_5");
				goto ret0;
			}
			new ent,dummy;
			get_user_aiming(id,ent,dummy);
			if(is_valid_ent(ent))
			{
				new classname[32];
				entity_get_string(ent,EV_SZ_classname,classname,31);
				if(equali(classname,CLASSNAME_WALL))
				{
					if(g_pServerVar[m_iCopy] == ent)
					{
						client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_2");
						goto ret0;
					}
					g_pServerVar[m_iCopy] = ent;
					client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_2");
				}
				else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");
			}
			else client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_1");
		}
		case 6:
		{
			if(g_pServerVar[m_iEntid] > 0)
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_5");
				goto ret0;
			}
			if(!is_valid_ent(g_pServerVar[m_iCopy]))
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_3");
				goto ret0;
			}

			new Float:p_origin[coord_s],ent = createWall(.bParse = false);
			entity_get_vector(id,EV_VEC_origin,p_origin);

			g_pServerVar[m_iBox]++;
			g_pServerVar[m_iEntid] = ent;
			p_origin[z] += 32.0;

			#if defined STATE_USE
				state stpfnThink:Enabled;
			#endif

			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_mins,g_pServerBox[m_fMins]);
			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_maxs,g_pServerBox[m_fMaxs]);

			entity_get_vector(g_pServerVar[m_iCopy],EV_VEC_angles,g_pServerBox[m_fAngles]);

			g_pServerVar[m_fScale] = _:(entity_get_float(g_pServerVar[m_iCopy],EV_FL_scale));
			g_pServerVar[m_iSprite] = floatround(entity_get_float(g_pServerVar[m_iCopy],EV_FL_frame));

			entity_set_vector(ent,EV_VEC_origin,p_origin);
			entity_set_vector(ent,EV_VEC_rendercolor,Vector(255.0,100.0,100.0));

			entity_set_vector(ent,EV_VEC_mins,g_pServerBox[m_fMins]);
			entity_set_vector(ent,EV_VEC_maxs,g_pServerBox[m_fMaxs]);
			entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);

			new iFlags = entity_get_int(g_pServerVar[m_iCopy],EV_INT_effects);

			entity_set_int(ent,EV_INT_effects,iFlags);
			entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
			entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));
		}
		case 8:
		{
			if(!g_pServerVar[m_iBox])
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_4");
			}
			else if(g_pServerVar[m_iEntid])
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_5");
			}
			else boxSave(id);
		}
		case 9:
		{
			return 0;
		}
	}
	ret0:
	return showMainEditMenu(id);
}
showPropertiesMenu(id)
{
	new menu[512],len;
	len = formatex(menu,511,"%L",id,"MODE_DEV_MENU_TITLE");
	switch(g_pServerVar[m_iSetting])
	{
		case 0:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.1;
			len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_COORD",
			g_pServerBox[m_fOrigin][x],
			g_pServerBox[m_fOrigin][y],
			g_pServerBox[m_fOrigin][z],iSize);
		}
		case 1:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 45.0 : (g_pServerVar[m_iType] == 1) ? 15.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_ANGLES",
			g_pServerBox[m_fAngles][x],
			g_pServerBox[m_fAngles][y],
			g_pServerBox[m_fAngles][z],iSize);
		}
		case 2,3:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_SIZE",
			g_pServerBox[m_fMins][x],
			g_pServerBox[m_fMins][y],
			g_pServerBox[m_fMins][z],
			g_pServerBox[m_fMaxs][x],
			g_pServerBox[m_fMaxs][y],
			g_pServerBox[m_fMaxs][z],iSize);
		}
		case 4:
		{
			new Float:iSize = ((g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051);
			switch(g_pServerVar[m_iType])
			{
				case 0,1:
					len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_SCALE_1",
					g_pServerVar[m_fScale],iSize,iSize,iSize);
				case 2:
					len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_SCALE_2",
					g_pServerVar[m_fScale],iSize,iSize,iSize);

				case 3:
					len += formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_SCALE_3",
					g_pServerVar[m_fScale],iSize,iSize,iSize);
			}
		}
	}
	formatex(menu[len],511 - len,"%L",id,"MODE_DEV_MENU_ADDON",id,
	(g_pServerVar[m_iSetting] == 0) ?
		"MODE_DEV_COORD"
			:
		(g_pServerVar[m_iSetting] == 1) ?
			"MODE_DEV_ANGLES"
				:
			(g_pServerVar[m_iSetting] == 2 && g_pServerVar[m_bAdvanced]) ?
				"MODE_DEV_MINS"
					:
				(g_pServerVar[m_iSetting] == 3 && g_pServerVar[m_bAdvanced]) ?
					"MODE_DEV_MAXS"
						:
					(g_pServerVar[m_iSetting] == 3) ?
						"MODE_DEV_SIZE"
							:
						"MODE_DEV_SPRITE",
	id,(g_pServerVar[m_iSprite] == 0) ?
		"MODE_DEV_TITLE"
			:
		(g_pServerVar[m_iSprite] == 1) ?
			"MODE_DEV_WALL"
				:
			"MODE_DEV_NULL"
	);
	return show_menu(id,(g_pServerVar[m_iSetting] < 4) ? 0x3FF : 0x3C3,menu,-1,"Properties Menu");
}
public propertiesHandler(id,key)
{
	if(key == 9)
	{
		return showMainEditMenu(id);
	}
	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_origin,g_pServerBox[m_fOrigin]);
	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_angles,g_pServerBox[m_fAngles]);
	entity_get_vector(g_pServerVar[m_iEntid],EV_VEC_maxs,g_pServerBox[m_fMaxs]);
	g_pServerVar[m_fScale] = _:(entity_get_float(g_pServerVar[m_iEntid],EV_FL_scale));

	switch(g_pServerVar[m_iSetting])
	{
		case 0:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.1;
			switch(key)
			{
				case 0:	g_pServerBox[m_fOrigin][x] += iSize;
				case 1:	g_pServerBox[m_fOrigin][y] += iSize;
				case 2:	g_pServerBox[m_fOrigin][z] += iSize;
				case 3:	g_pServerBox[m_fOrigin][x] -= iSize;
				case 4:	g_pServerBox[m_fOrigin][y] -= iSize;
				case 5:	g_pServerBox[m_fOrigin][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSprite] > 1 && g_pServerVar[m_iSetting] == 1) ? 2 + ((g_pServerVar[m_bAdvanced] == false) ? 1 : 0) : g_pServerVar[m_iSetting];
				}
			}
		}
		case 1:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 45.0 : (g_pServerVar[m_iType] == 1) ? 15.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			switch(key)
			{
				case 0: g_pServerBox[m_fAngles][x] += iSize;
				case 1: g_pServerBox[m_fAngles][y] += iSize;
				case 2: g_pServerBox[m_fAngles][z] += iSize;
				case 3: g_pServerBox[m_fAngles][x] -= iSize;
				case 4: g_pServerBox[m_fAngles][y] -= iSize;
				case 5: g_pServerBox[m_fAngles][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSetting] == 2 && g_pServerVar[m_bAdvanced] == false) ? 3 : g_pServerVar[m_iSetting];
				}
			}
		}
		case 2:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			switch(key)
			{
				case 0: g_pServerBox[m_fMins][x] -= iSize;
				case 1: g_pServerBox[m_fMins][y] -= iSize;
				case 2: g_pServerBox[m_fMins][z] -= iSize;
				case 3: g_pServerBox[m_fMins][x] += iSize;
				case 4: g_pServerBox[m_fMins][y] += iSize;
				case 5: g_pServerBox[m_fMins][z] += iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;
				}
			}
		}
		case 3:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 10.0 : (g_pServerVar[m_iType] == 1) ? 5.0 : (g_pServerVar[m_iType] == 2) ? 1.0 : 0.5;
			switch(key)
			{
				case 0: g_pServerBox[m_fMaxs][x] += iSize;
				case 1: g_pServerBox[m_fMaxs][y] += iSize;
				case 2: g_pServerBox[m_fMaxs][z] += iSize;
				case 3: g_pServerBox[m_fMaxs][x] -= iSize;
				case 4: g_pServerBox[m_fMaxs][y] -= iSize;
				case 5: g_pServerBox[m_fMaxs][z] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;

					g_pServerVar[m_iSetting] = (g_pServerVar[m_iSprite] > 1 && g_pServerVar[m_iSetting] == 4) ? 0 : g_pServerVar[m_iSetting];
				}
			}
		}
		case 4:
		{
			new Float:iSize = (g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051;
			if(iSize > g_pServerVar[m_fScale])
			{
				if(++g_pServerVar[m_iType] > 3)
					g_pServerVar[m_iType] = 0;

				iSize = (g_pServerVar[m_iType] == 0) ? 0.5 : (g_pServerVar[m_iType] == 1) ? 0.1 : (g_pServerVar[m_iType] == 2) ? 0.0101 : 0.0051;
			}
			switch(key)
			{
				case 0:	g_pServerVar[m_fScale] += iSize;
				case 1: g_pServerVar[m_fScale] -= iSize;
				case 6:
				{
					if(++g_pServerVar[m_iType] > 3)
						g_pServerVar[m_iType] = 0;
				}
				case 7:
				{
					if(++g_pServerVar[m_iSetting] > 4)
						g_pServerVar[m_iSetting] = 0;
				}
			}

		}
	}
	switch(key)
	{
		case 8:
		{
			if(is_valid_ent(g_pServerVar[m_iEntid]))
			{
				if(++g_pServerVar[m_iSprite] > 2)
				{
					g_pServerVar[m_iSprite] = 0;
				}
				new iFlags = entity_get_int(g_pServerVar[m_iEntid],EV_INT_effects);
				if(g_pServerVar[m_iSprite] > 1)
				{
					entity_set_int(g_pServerVar[m_iEntid],EV_INT_effects,iFlags|EF_NODRAW);
				}
				else
				{
					if(iFlags & EF_NODRAW)
					{
						entity_set_int(g_pServerVar[m_iEntid],EV_INT_effects,iFlags&~EF_NODRAW);
					}
				}
				entity_set_float(g_pServerVar[m_iEntid],EV_FL_frame,float(g_pServerVar[m_iSprite]));
			}
		}
	}
	if(g_pServerVar[m_fScale] < 0.0051)
	{
		g_pServerVar[m_fScale] = _:0.0051;
	}
	if(g_pServerVar[m_bAdvanced])
	{
		if(g_pServerBox[m_fMins][x] > 0.0)
		{
			g_pServerBox[m_fMins][x] = 0.0;
		}
		else if(g_pServerBox[m_fMins][y] > 0.0)
		{
			g_pServerBox[m_fMins][y] = 0.0;
		}
		else if(g_pServerBox[m_fMins][z] > 0.0)
		{
			g_pServerBox[m_fMins][z] = 0.0;
		}
		if(g_pServerBox[m_fMaxs][x] < 0.0)
		{
			g_pServerBox[m_fMaxs][x] = 0.0;
		}
		else if(g_pServerBox[m_fMaxs][y] < 0.0)
		{
			g_pServerBox[m_fMaxs][y] = 0.0;
		}
		else if(g_pServerBox[m_fMaxs][z] < 0.0)
		{
			g_pServerBox[m_fMaxs][z] = 0.0;
		}
	}
	else
	{
		if(g_pServerBox[m_fMaxs][x] < 1.0)
		{
			g_pServerBox[m_fMaxs][x] = 1.0;
		}
		else if(g_pServerBox[m_fMaxs][y] < 1.0)
		{
			g_pServerBox[m_fMaxs][y] = 1.0;
		}
		else if(g_pServerBox[m_fMaxs][z] < 1.0)
		{
			g_pServerBox[m_fMaxs][z] = 1.0;
		}
	}
	if(g_pServerBox[m_fAngles][x] >= 360.0 || g_pServerBox[m_fAngles][x] <= -360.0)
	{
		g_pServerBox[m_fAngles][x] = 0.0;
	}
	if(g_pServerBox[m_fAngles][y] >= 360.0 || g_pServerBox[m_fAngles][y] <= -360.0)
	{
		g_pServerBox[m_fAngles][y] = 0.0;
	}
	if(g_pServerBox[m_fAngles][z] >= 360.0 || g_pServerBox[m_fAngles][z] <= -360.0)
	{
		g_pServerBox[m_fAngles][z] = 0.0;
	}
	if(!g_pServerVar[m_bAdvanced])
	{
		g_pServerBox[m_fMins][x] = -g_pServerBox[m_fMaxs][x];
		g_pServerBox[m_fMins][y] = -g_pServerBox[m_fMaxs][y];
		g_pServerBox[m_fMins][z] = -g_pServerBox[m_fMaxs][z];
	}
	entity_set_float(g_pServerVar[m_iEntid],EV_FL_scale,g_pServerVar[m_fScale]);
	entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_angles,g_pServerBox[m_fAngles]);
	entity_set_float(g_pServerVar[m_iEntid],EV_FL_nextthink,get_gametime() + 0.1);
	entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,g_pServerVar[m_iSolid] ? SOLID_BBOX : SOLID_NOT);

	entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);
	entity_set_vector(g_pServerVar[m_iEntid],EV_VEC_origin,g_pServerBox[m_fOrigin]);

	return showPropertiesMenu(id);
}
showSettingsMenu(id)
{
	new menu[512];
	formatex(menu,511,"%L",id,"MODE_DEV_MENU_CONFIG",
	id,g_pServerVar[m_iEntid] == 0 ? "MODE_DEV_SOLID" : "MODE_DEV_SOLID_D",
	g_pServerVar[m_iSolid] ? "SOLID_BBOX" : "SOLID_NOT",
	g_pServerVar[m_iBox] == 0 ? "\\d" : "\\w",
	id,(g_pServerVar[m_iStatus] == status_s:box_close) ? "MODE_DEV_HIDE" : "MODE_DEV_SHOW",
	g_pServerVar[m_iOnline],
	id,entity_get_int(id,EV_INT_movetype) == MOVETYPE_NOCLIP ? "MODE_DEV_YES" : "MODE_DEV_NO",
	id,g_pServerVar[m_bAdvanced] ? "MODE_DEV_YES" : "MODE_DEV_NO"
	);

	return show_menu(id,MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_0,menu,-1,"Setting Menu");
}
public settingHandler(id,key)
{
	switch(key)
	{
		case 0:
		{
			if(!g_pServerVar[m_iEntid])
			{
				client_print(id,print_center,"%L",id,"MODE_DEV_FAILED_4");
				goto ret0;
			}
			entity_set_float(g_pServerVar[m_iEntid],EV_FL_nextthink,get_gametime() + 0.1);
			entity_set_int(g_pServerVar[m_iEntid],EV_INT_solid,(g_pServerVar[m_iSolid] ^= 1) ? SOLID_BBOX : SOLID_NOT);
			entity_set_size(g_pServerVar[m_iEntid],g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

			client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_6",g_pServerVar[m_iSolid] ? "SOLID_BBOX" : "SOLID_NOT");
		}
		case 1:
		{
			if(g_pServerVar[m_iBox])
			{
				showBoxDeveloper((g_pServerVar[m_iStatus] ^= status_s:box_close));
			}
		}
		case 2:
		{
			if(++g_pServerVar[m_iOnline] > g_pServerVar[m_iMaxpl])
			{
				g_pServerVar[m_iOnline] = 0;
			}
		}
		case 3:
		{
			if(is_user_alive(id))
			{
				entity_set_int(id,EV_INT_movetype,(entity_get_int(id,EV_INT_movetype) == MOVETYPE_NOCLIP) ? MOVETYPE_WALK : MOVETYPE_NOCLIP);
			}
		}
 		case 4: g_pServerVar[m_bAdvanced] ^= true;
		case 9:	return showMainEditMenu(id);
	}
	ret0:
	return showSettingsMenu(id);
}
#if defined ALLOW_MODE
getChangeleft(id,time,output[],len)
{
	if(time > 0)
	{
		new minute = 0,second = 0;

		second = time;

		minute = second / 60;
		second -= (minute * 60);

		new ibuf[2][33],ending[22],num = -1;

		if(minute > 0)
		{
			getEnding(minute,"MODE_MINUT","MODE_MINUTE","MODE_MINUTES",21,ending);
			formatex(ibuf[++num],32,"%i %L",minute,id,ending);
		}
		if(second > 0)
		{
			getEnding(second,"MODE_SECOND","MODE_SECUNDE","MODE_SECONDS",21,ending);
			formatex(ibuf[++num],32,"%i %L",second,id,ending);
		}
		switch(num)
		{
			case 0: formatex(output,len,"%s",ibuf[0]);
			case 1: formatex(output,len,"%L",id,"MODE_AND",ibuf[0],ibuf[1]);
		}
	}
	else formatex(output,len,"0 %L",id,"MODE_SECOND");
}
getEnding(num,const a[],const b[],const c[],lenght,output[])
{
	new num100 = num % 100,num10 = num % 10,ibuf[22];
	if(num100 >= 5 && num100 <= 20 || num10 == 0 || num10 >= 5 && num10 <= 9)
	{
		copy(ibuf,21,a);
	}
	else if(num10 == 1)
	{
		copy(ibuf,21,b);
	}
	else if(num10 >= 2 && num10 <= 4)
	{
		copy(ibuf,21,c);
	}
	return formatex(output,lenght,"%s",ibuf);
}
#endif
boxSave(id)
{
	if(file_exists(g_pServerVar[m_szFile]))
	{
		delete_file(g_pServerVar[m_szFile]);
	}
	new ibuf[1024],Float:frame,Float:p_origin[coord_s],Float:p_angles[coord_s],Float:p_mins[coord_s],Float:p_maxs[coord_s],Float:p_scale,p_sprite,count,ent = -1;
	formatex(ibuf,1023,"ONLINE=%d",g_pServerVar[m_iOnline]);		
	write_file(g_pServerVar[m_szFile],ibuf,0);
	while((ent = find_ent_by_class(ent,CLASSNAME_WALL)))
	{
		if(g_pServerVar[m_iEntid] == ent)
		{
			continue;
		}
		entity_get_vector(ent,EV_VEC_origin,p_origin);
		entity_get_vector(ent,EV_VEC_angles,p_angles);
		entity_get_vector(ent,EV_VEC_mins,p_mins);
		entity_get_vector(ent,EV_VEC_maxs,p_maxs);

		p_scale = entity_get_float(ent,EV_FL_scale);
		frame = entity_get_float(ent,EV_FL_frame);

		p_sprite = floatround(frame);

		formatex(ibuf,1023,"\"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%f\" \"%d\"",p_origin[x],p_origin[y],p_origin[z],p_angles[x],p_angles[y],p_angles[z],p_mins[x],p_mins[y],p_mins[z],p_maxs[x],p_maxs[y],p_maxs[z],p_scale,p_sprite);
		write_file(g_pServerVar[m_szFile],ibuf,-1);
		count++;
	}
	if(id && count > 0)
	{
		client_print(id,print_center,"%L",id,"MODE_DEV_SUCCESS_3");
	}
}
boxLoad()
{
	new ibuf[2048],key[32],value[32],p_origin[coord_s][6],p_angles[coord_s][6],p_mins[coord_s][6],p_maxs[coord_s][6],p_scale[6],p_sprite[6];
	new file = fopen(g_pServerVar[m_szFile],"r");
	while(!feof(file))
	{
		fgets(file,ibuf,2047);
		if(!ibuf[0] || ibuf[0] == ';')
		{
			continue;
		}
		trim(ibuf);
		strtok(ibuf,key,31,value,31,'=');

		if(equal(key,"ONLINE"))
		{
			g_pServerVar[m_iOnline] = str_to_num(value);
			continue;
		}

		parse(ibuf,
		p_origin[x],5,
		p_origin[y],5,
		p_origin[z],5,
		p_angles[x],5,
		p_angles[y],5,
		p_angles[z],5,
		p_mins[x],5,
		p_mins[y],5,
		p_mins[z],5,
		p_maxs[x],5,
		p_maxs[y],5,
		p_maxs[z],5,
		p_scale,5,
		p_sprite,5);

		g_pServerBox[m_fOrigin][x] = str_to_float(p_origin[x]);
		g_pServerBox[m_fOrigin][y] = str_to_float(p_origin[y]);
		g_pServerBox[m_fOrigin][z] = str_to_float(p_origin[z]);

		g_pServerBox[m_fAngles][x] = str_to_float(p_angles[x]);
		g_pServerBox[m_fAngles][y] = str_to_float(p_angles[y]);
		g_pServerBox[m_fAngles][z] = str_to_float(p_angles[z]);

		g_pServerBox[m_fMins][x] = str_to_float(p_mins[x]);
		g_pServerBox[m_fMins][y] = str_to_float(p_mins[y]);
		g_pServerBox[m_fMins][z] = str_to_float(p_mins[z]);

		g_pServerBox[m_fMaxs][x] = str_to_float(p_maxs[x]);
		g_pServerBox[m_fMaxs][y] = str_to_float(p_maxs[y]);
		g_pServerBox[m_fMaxs][z] = str_to_float(p_maxs[z]);

		g_pServerVar[m_fScale] = _:(str_to_float(p_scale));
		g_pServerVar[m_iSprite] = str_to_num(p_sprite);

		createWall(.bParse = true);
		g_pServerVar[m_iBox]++;
	}
	return fclose(file);
}
checkNumPlayers()
{
	static iNum;
	iNum = 0;

	for(new index = 1; index <= g_pServerVar[m_iMaxpl]; index++)
	{
		if(!is_user_connected(index) || !IsUserTeam(index))
		{
			continue;
		}
		iNum++;
	}
	return iNum;
}
showBoxDeveloper(status_s:st)
{
	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt,CLASSNAME_WALL)))
	{
		entity_set_int(iEnt,EV_INT_solid,st == status_s:box_close ? SOLID_BBOX : SOLID_NOT);

		if(g_pServerVar[m_iEntid] == iEnt || entity_get_float(iEnt,EV_FL_frame) > 1.0)
		{
			continue;
		}
		static iFlags;
		iFlags = entity_get_int(iEnt,EV_INT_effects);
		entity_set_int(iEnt,EV_INT_effects,st == status_s:box_close ? iFlags &~ EF_NODRAW : iFlags|EF_NODRAW);
	}
}
showBox(status_s:st,bool:bShow)
{
	new iEnt = -1;
	while((iEnt = find_ent_by_class(iEnt,CLASSNAME_WALL)))
	{
		entity_set_int(iEnt,EV_INT_solid,st == status_s:box_close ? SOLID_BBOX : SOLID_NOT);

		if(entity_get_float(iEnt,EV_FL_frame) > 1)
		{
			continue;
		}
		static iFlags;
		iFlags = entity_get_int(iEnt,EV_INT_effects);
		entity_set_int(iEnt,EV_INT_effects,st == status_s:box_close ? iFlags &~ EF_NODRAW : iFlags|EF_NODRAW);
	}
	switch(st)
	{
		case box_open:
		{
			#if defined STATE_USE
			state stMode:Disabled;
			#endif
			if(bShow)
			{
				set_dhudmessage(COLOR_MAP_OPEN,MESSAGE_MAP_STATUS,2,0.1,2.0,0.05,0.2);
				show_dhudmessage(0,"%L",LANG_PLAYER,"MODE_MESSAGE_MAP_OPENED");
			}
		}
		case box_close:
		{
			#if defined STATE_USE
			state stMode:Enabled;
			#endif
			if(bShow)
			{
				set_dhudmessage(COLOR_MAP_CLOSE,MESSAGE_MAP_STATUS,2,0.1,2.0,0.05,0.2);
				show_dhudmessage(0,"%L",LANG_PLAYER,"MODE_MESSAGE_MAP_CLOSED");
			}
		}
	}
}
createWall(bool:bParse)
{
	new ent = create_entity("func_wall");

	if(!is_valid_ent(ent))
	{
		return 0;
	}
	entity_set_string(ent,EV_SZ_classname,CLASSNAME_WALL);
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_FLY);

	if(bParse)
	{
		entity_set_model(ent,SPRITE_WALL);
		entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

		entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
		entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);
		entity_set_int(ent,EV_INT_solid,SOLID_BBOX);

		if(g_pServerVar[m_iSprite] > 1)
		{
			entity_set_int(ent,EV_INT_effects,entity_get_int(ent,EV_INT_effects)|EF_NODRAW);
		}
		entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));
		entity_set_int(ent,EV_INT_rendermode,kRenderTransAdd);
		entity_set_float(ent,EV_FL_renderamt,175.0);
		entity_set_vector(ent,EV_VEC_origin,g_pServerBox[m_fOrigin]);
	}
	else
	{
		g_pServerBox[m_fAngles][x] = 0.0;
		g_pServerBox[m_fAngles][y] = 0.0;
		g_pServerBox[m_fAngles][z] = 0.0;

		g_pServerBox[m_fMaxs][x] = 32.0;
		g_pServerBox[m_fMaxs][y] = 32.0;
		g_pServerBox[m_fMaxs][z] = 32.0;

		g_pServerBox[m_fMins][x] = -32.0;
		g_pServerBox[m_fMins][y] = -32.0;
		g_pServerBox[m_fMins][z] = -32.0;

		g_pServerVar[m_fScale] = _:0.250;

		entity_set_model(ent,SPRITE_WALL);
		entity_set_size(ent,g_pServerBox[m_fMins],g_pServerBox[m_fMaxs]);

		entity_set_float(ent,EV_FL_scale,g_pServerVar[m_fScale]);
		entity_set_vector(ent,EV_VEC_angles,g_pServerBox[m_fAngles]);
		entity_set_int(ent,EV_INT_solid,SOLID_NOT);

		entity_set_float(ent,EV_FL_frame,float(g_pServerVar[m_iSprite]));

		entity_set_int(ent,EV_INT_rendermode,kRenderTransAdd);
		entity_set_float(ent,EV_FL_renderamt,175.0);

		entity_set_float(ent,EV_FL_nextthink,get_gametime() + 0.1);

		return ent;
	}
	return 0;
}