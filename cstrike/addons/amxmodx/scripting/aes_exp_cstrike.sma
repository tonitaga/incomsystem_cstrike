/*
*	AES: CStrike Addon		     v. 0.5
*	by serfreeman1337	    http://1337.uz/
*/

#include <amxmodx>
#include <reapi>
#include <aes_v>

#define PLUGIN "AES: CStrike Addon"
#define VERSION "0.5.9 [REAPI]"
#define AUTHOR "serfreeman1337/sonyx"
#define LASTUPDATE "12, March (03), 2018"

#if AMXX_VERSION_NUM < 183
	#include <colorchat>

	#define print_team_default DontChange
	#define print_team_grey Grey
	#define print_team_red Red
	#define print_team_blue Blue

	#define MAX_NAME_LENGTH	32
	#define MAX_PLAYERS 32

	#define client_disconnected client_disconnect

	new MaxClients
#endif

/* - CVARS - */

enum _:cvars_num {
	CVAR_XP_KILL,
	CVAR_XP_HS,
	CVAR_XP_C4_PLANT,
	CVAR_XP_C4_EXPLODE,
	CVAR_XP_C4_DEFUSED,
	CVAR_XP_FFA,
	CVAR_XP_HOST_GOT,
	CVAR_XP_HOST_RESCUE,
	CVAR_XP_HOST_KILL,
	CVAR_XP_VIP_ESCAPED,
	CVAR_XP_VIP_KILLED,
	CVAR_XP_GOAL_MIN_PLAYERS,
	CVAR_XP_DEATH,
	CVAR_ANEW_FRAGS,
	CVAR_ANEW_HS,
	CVAR_ANEW_KNIFE,
	CVAR_ANEW_HE,
	CVAR_ANEW_REST,
	CVAR_LEVEL_BONUS,

	CVAR_RANK,
	CVAR_BONUS_ENABLE
}

new cvar[cvars_num]

/* - ADD BONUS - */

enum _:
{
	STREAK_KILLS,
	STREAK_HS,
	STREAK_KNIFE,
	STREAK_HE,

	STREAK_OPT
}

enum _:Arrays{
	Array:FRAG_ARRAY,
	Array:HS_ARRAY,
	Array:KNIFE_ARRAY,
	Array:HE_ARRAY
}

new Array: g_BonusCvars[Arrays];
new frArrSize,hsArrSize,kfArrSize,heArrSize;

new bool:is_by_stats;
new g_Planter;

new g_Players[MAX_PLAYERS + 1][STREAK_OPT];

native get_user_stats(index, stats[8], bodyhits[8]);
native get_user_stats2(index, stats[4]);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	cvar[CVAR_XP_KILL] = register_cvar("aes_xp_frag","1");
	cvar[CVAR_XP_HS] = register_cvar("aes_xp_hs","2");
	cvar[CVAR_XP_C4_PLANT] = register_cvar("aes_xp_c4_plant","1");
	cvar[CVAR_XP_C4_EXPLODE] = register_cvar("aes_xp_c4_explode","3");
	cvar[CVAR_XP_C4_DEFUSED] = register_cvar("aes_xp_c4_defused","4");
	cvar[CVAR_XP_HOST_GOT] = register_cvar("aes_xp_hostage_got","1");
	cvar[CVAR_XP_HOST_RESCUE] = register_cvar("aes_xp_hostage_rescue","1");
	cvar[CVAR_XP_HOST_KILL] = register_cvar("aes_xp_hostage_kill","0");
	cvar[CVAR_XP_VIP_ESCAPED] = register_cvar("aes_xp_vip_escaped","4");
	cvar[CVAR_XP_VIP_KILLED] = register_cvar("aes_xp_vip_killed","4");
	cvar[CVAR_XP_GOAL_MIN_PLAYERS] = register_cvar("aes_xp_goal_min_players","4");

	cvar[CVAR_XP_FFA] = register_cvar("aes_xp_ffa","0");

	cvar[CVAR_ANEW_FRAGS] = register_cvar("aes_anew_frags","10 1 20 2 30 3 40 5");
	cvar[CVAR_ANEW_HS] = register_cvar("aes_anew_hs","7 1 14 2 20 3 30 4");
	cvar[CVAR_ANEW_KNIFE] = register_cvar("aes_anew_knife","1 1 2 1 3 1 4 1");
	cvar[CVAR_ANEW_HE] = register_cvar("aes_anew_he","4 1 5 1 6 1 7 2");
	cvar[CVAR_ANEW_REST] = register_cvar("aes_anew_reset","1");

	cvar[CVAR_LEVEL_BONUS] = register_cvar("aes_bonus_levelup","3");
	cvar[CVAR_XP_DEATH] = register_cvar("aes_xp_death","0");

	#if AMXX_VERSION_NUM < 183
		MaxClients = get_maxplayers();
	#endif
}

public plugin_cfg()
{
	cvar[CVAR_RANK] = get_cvar_pointer("aes_track_mode");

	if((cvar[CVAR_RANK] = get_cvar_pointer("aes_track_mode")) == 0)
		set_fail_state("cvar ^"aes_track_mode^" not found");

	RegisterHookChain(RG_CGrenade_ExplodeBomb, "CGrenade_ExplodeBomb", true);
	RegisterHookChain(RG_PlantBomb, "PlantBomb", true);
	RegisterHookChain(RG_CGrenade_DefuseBombEnd, "CGrenade_DefuseBombEnd", true);
	RegisterHookChain(RG_CBasePlayer_AddAccount, "CBasePlayer_AddAccount", true);
	RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice", true);

	cvar[CVAR_BONUS_ENABLE] = get_cvar_pointer("aes_bonus_enable");

	if(!cvar[CVAR_BONUS_ENABLE])
		return;

	g_BonusCvars[FRAG_ARRAY] = ArrayCreate(2);
	g_BonusCvars[HS_ARRAY] = ArrayCreate(2);
	g_BonusCvars[KNIFE_ARRAY] = ArrayCreate(2);
	g_BonusCvars[HE_ARRAY] = ArrayCreate(2);

	new levelString[512];

	get_pcvar_string(cvar[CVAR_ANEW_FRAGS],levelString,charsmax(levelString));
	frArrSize = parse_aes_bonus_values(g_BonusCvars[FRAG_ARRAY],levelString);

	get_pcvar_string(cvar[CVAR_ANEW_HS],levelString,charsmax(levelString));
	hsArrSize = parse_aes_bonus_values(g_BonusCvars[HS_ARRAY],levelString);

	get_pcvar_string(cvar[CVAR_ANEW_KNIFE],levelString,charsmax(levelString));
	kfArrSize = parse_aes_bonus_values(g_BonusCvars[KNIFE_ARRAY],levelString);

	get_pcvar_string(cvar[CVAR_ANEW_HE],levelString,charsmax(levelString));
	heArrSize = parse_aes_bonus_values(g_BonusCvars[HE_ARRAY],levelString);

	if(get_pcvar_num(cvar[CVAR_RANK])== -1)
	{
		RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);
		is_by_stats = true;
	}
}


//
// Расчет опыта по статистике игрока из CSX
//
public CBasePlayer_Spawn(const id)
{
	if(!is_user_alive(id))
		return;

	new stats[8],bprelated[4],bh[8];

	get_user_stats(id,stats,bh);
	get_user_stats2(id,bprelated);

	new Float:exp = get_exp_for_stats(stats,bprelated);
	aes_set_player_exp(id,exp,true,true);
}


//
// native Float:aes_search_exp_in_stats(stats[8],stats2[4])
//
public plugin_natives()
{
	register_native("aes_get_exp_for_stats_f","_aes_get_exp_for_stats_f");
	register_native("aes_get_exp_for_stats","_aes_get_exp_for_stats");
}

public Float:_aes_get_exp_for_stats_f(plugin_id,params)
{
	/*if(!is_by_stats)
		return -1.0;*/

	if(params != 2)
	{
		log_error(AMX_ERR_NATIVE,"bad arguments num, expected 2, passed %d",params);
		return 0.0;
	}

	new stats[8],bprelated[4];
	get_array(1,stats,sizeof stats);
	get_array(2,bprelated,sizeof bprelated);

	return get_exp_for_stats(stats,bprelated);
}

public _aes_get_exp_for_stats(plugin_id,params)
{
	if(!is_by_stats)
		return -1;

	if(params != 2)
	{
		log_error(AMX_ERR_NATIVE,"bad arguments num, expected 2, passed %d",params);
		return 0;
	}

	new stats[8],bprelated[4];
	get_array(1,stats,sizeof stats);
	get_array(2,bprelated,sizeof bprelated);

	return floatround(get_exp_for_stats(stats,bprelated));
}

Float:get_exp_for_stats(stats[8],bprelated[4])
{
	stats[0] = stats[0] - stats[2];

	new Float:exp = (float(stats[0]) * get_pcvar_float(cvar[CVAR_XP_KILL])) + (float(stats[2]) * get_pcvar_float(cvar[CVAR_XP_HS]));
	exp += (float(bprelated[2]) * get_pcvar_float(cvar[CVAR_XP_C4_PLANT])) + (float(bprelated[3]) * get_pcvar_float(cvar[CVAR_XP_C4_EXPLODE]));
	exp += float(bprelated[1]) * get_pcvar_float(cvar[CVAR_XP_C4_DEFUSED]);

	return exp;
}

public client_disconnected(id)
	if(cvar[CVAR_BONUS_ENABLE])
		arrayset(g_Players[id],0,STREAK_OPT);

public CSGameRules_DeathNotice(const victim, const killer, pevInflictor)
{
	if(!(0 < killer <= MaxClients) || killer == victim || !is_user_connected(victim) || !is_user_connected(killer))
		return;

	if(!get_pcvar_num(cvar[CVAR_XP_FFA]) && (get_member(killer, m_iTeam) == get_member(victim, m_iTeam)))
		return;

	if(get_member(victim, m_bHeadshotKilled))
		aes_add_player_exp_f(killer,get_pcvar_float(cvar[CVAR_XP_HS]));
	else
		aes_add_player_exp_f(killer,get_pcvar_float(cvar[CVAR_XP_KILL]));

	aes_add_player_exp_f(victim,get_pcvar_float(cvar[CVAR_XP_DEATH]));

	// бонусы не включены или временно не работают
	if(!cvar[CVAR_BONUS_ENABLE] || !get_pcvar_num(cvar[CVAR_BONUS_ENABLE]))
		return;

	g_Players[killer][STREAK_KILLS]++;

	new bonusPoints = 0;

	bonusPoints += get_current_player_bonuses(killer,frArrSize,0,g_BonusCvars[FRAG_ARRAY]);

	if(get_member(victim, m_bHeadshotKilled))
	{
		g_Players[killer][STREAK_HS]++;
		bonusPoints += get_current_player_bonuses(killer,hsArrSize,1,g_BonusCvars[HS_ARRAY]);
	}
	if(killer == pevInflictor && WeaponIdType:get_member(get_member(killer, m_pActiveItem), m_iId) == WEAPON_KNIFE)
	{
		g_Players[killer][STREAK_KNIFE]++;
		bonusPoints += get_current_player_bonuses(killer,kfArrSize,2,g_BonusCvars[KNIFE_ARRAY]);
	}
	else if(FClassnameIs(pevInflictor, "grenade"))
	{
		g_Players[killer][STREAK_HE]++;
		bonusPoints += get_current_player_bonuses(killer,heArrSize,3,g_BonusCvars[HE_ARRAY]);
	}

	if(get_pcvar_num(cvar[CVAR_ANEW_REST]) == 1)
		arrayset(g_Players[victim],0,STREAK_OPT);

	if(bonusPoints)
	{
		client_print_color(killer,print_team_default,"%L %L",killer,"AES_TAG",killer,"AES_ANEW_GAIN",bonusPoints);
		aes_add_player_bonus_f(killer,bonusPoints);
	}
}


// бонусы при получении нового звания
public aes_player_levelup(id)
{
	if(!cvar[CVAR_BONUS_ENABLE] || !get_pcvar_float(cvar[CVAR_LEVEL_BONUS]))
		return;

	aes_add_player_bonus_f(id,get_pcvar_num(cvar[CVAR_LEVEL_BONUS]));
}

public CGrenade_ExplodeBomb(const this, tracehandle, const bitsDamageType)
{
	addExp(g_Planter,CVAR_XP_C4_EXPLODE);
}

public PlantBomb(id, Float:vecStart[3], Float:vecVelocity[3])
{
	g_Planter = id;
	addExp(id,CVAR_XP_C4_PLANT);
}

public CGrenade_DefuseBombEnd(const this, const id, bool:bDefused)
{
	if(bDefused)
		addExp(id,CVAR_XP_C4_DEFUSED);
}

public CBasePlayer_AddAccount(const id, amount, RewardType:type, bool:bTrackChange)
{
	switch(type)
	{
	  case RT_HOSTAGE_TOOK:addExp(id,CVAR_XP_HOST_GOT);
	  case RT_HOSTAGE_RESCUED:addExp(id,CVAR_XP_HOST_RESCUE);
	  case RT_HOSTAGE_KILLED:addExp(id,CVAR_XP_HOST_KILL);
	  case RT_VIP_KILLED:addExp(id,CVAR_XP_VIP_KILLED);
	  case RT_VIP_RESCUED_MYSELF:addExp(id,CVAR_XP_VIP_ESCAPED);
	}
}

// проверка на кол-во бонусных очков игрока
// cmpr - какой параметр проверяем
// Array:which - по какому массиву
public get_current_player_bonuses(id,size,cmpr,Array:which)
{
	new bonusPoints,rt[2],i;

	for(i = 0 ; i < size ; ++i)
	{
		ArrayGetArray(which,i,rt);

		if(g_Players[id][cmpr] == rt[0])
			bonusPoints += rt[1];
	}

	return bonusPoints;
}

// парсер значений бонусов в массив
public parse_aes_bonus_values(Array:which,levelString[])
{
	new stPos,ePos,rawPoint[20],rawVals[2],stState;

	// значение не задано
	if(!strlen(levelString))
		return 0;

	do {
		// ищем пробел
		ePos = strfind(levelString[stPos]," ");

		// узнаем значение с позиции stPos и длинной ePos
		formatex(rawPoint,ePos,levelString[stPos]);
		rawVals[stState] = str_to_num(rawPoint);

		stPos += ePos + 1;

		// указатель 2ой пары
		stState++;

		// два значения были найдены
		// записываем их в массив и сбрасываем указатель
		if(stState == 2)
		{
			ArrayPushArray(which,rawVals);
			stState = 0;
		}

	} while(ePos != -1)

	// возвращает кол-во 2ых пар
	return ArraySize(which);
}

addExp(id, rule)
{
	if(get_playersnum() >= get_pcvar_num(cvar[CVAR_XP_GOAL_MIN_PLAYERS]))
		aes_add_player_exp_f(id,get_pcvar_float(cvar[rule]));
}
