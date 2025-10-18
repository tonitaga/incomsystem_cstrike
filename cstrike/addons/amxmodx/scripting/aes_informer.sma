/*
	Advanced Experience System
	by serfreeman1337		http://gf.hldm.org/
*/

/*
	HUD Informer
*/

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <csx>

#define CSSTATSX_SQL		

#include <aes_v>
#if defined CSSTATSX_SQL
	#include <csstatsx_sql>
#endif

#define PLUGIN "AES: Informer"
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
#endif

#define PLAYER_HUD_OFFSET	86444


/* - CVARS - */

enum _:cvars_num {
	CVAR_HUD_UPDATE,
	CVAR_HUD_INFO_DEFAULT,
	CVAR_HUD_INFO_TYPE,
	CVAR_HUD_INFO_COLOR,
	CVAR_HUD_INFO_POS,
	CVAR_HUD_INFO_TYPE_D,
	CVAR_HUD_INFO_COLOR_D,
	CVAR_HUD_INFO_POS_D,
	CVAR_TPL_MODE,
	CVAR_HUD_ANEW_TYPE,
	CVAR_HUD_ANEW_POS,
	CVAR_HUD_ANEW_COLOR,
	CVAR_CHAT_NEW_LEVEL
}

new cvar[cvars_num];

/* - CACHED VALUES - */

// кеш от души
new Float:hudUpdateInterval;
new bool:hudInfoOn, Float:hudInfoxPos,Float:hudInfoyPos,hudInfoColor[3],bool:hudInfoColorRandom;
new bool:hudDeadOn, Float:hudDeadxPos, Float:hudDeadyPos,hudDeadColor[3],bool:hudDeadColorRandom;
new bool:hudaNewOn, Float:hudaNewxPos,Float:hudaNewyPos,hudaNewColor[3];
new chatLvlUpStyle,bonusEnabledPointer,bool:isTplMode,aesMaxLevel,g_trackmode;
new playerLevel[MAX_PLAYERS + 1][AES_MAX_LEVEL_LENGTH],playerWatchLevel[MAX_PLAYERS + 1];

/* - SYNC HUD OBJ - */
new informerSyncObj,aNewSyncObj;

/* - FILE STORAGE - */

new Trie:g_DisabledInformer;

#if AMXX_VERSION_NUM < 183
new Array:g_ADisabledInformer;
#endif

#if defined CSSTATSX_SQL
new const g_skill_letters[][] = {
	"L-",
	"L",
	"L+",
	"M-",
	"M",
	"M+",
	"H-",
	"H",
	"H+",
	"P-",
	"P",
	"P+",
	"G"
}

new g_cvar_skill;
new Float:g_skill_opt[sizeof g_skill_letters];
#endif

enum _:tplInfo {
	INF_EXP,
	INF_LEVELEXP,
	INF_NEEDEXP,
	INF_LEVEL,
	INF_MAXLEVEL,
	INF_RANK,
	INF_NAME,
	INF_STEAMID,
	INF_BONUS,
	INF_TIME,
	INF_TOP,
	INF_MAXTOP,
	INF_TIMELEFT,
	INF_MAPNAME,
#if defined CSSTATSX_SQL
	INF_SKILL,
#endif

	INF_EXF,
	INF_LXF,
	INF_NXF
}

new const tplKeys[tplInfo][] = {
	"<exp>",
	"<levelexp>",
	"<needexp>",
	"<level>",
	"<maxlevel>",
	"<rank>",
	"<name>",
	"<steamid>",
	"<bonus>",
	"<time>",
	"<top>",
	"<maxtop>",
	"<timeleft>",
	"<mapname>",
#if defined CSSTATSX_SQL
	"<skill>",
#endif

	"<exf>",
	"<lxf>",
	"<nxf>"
}

enum _:tplVario {
	TPL_INF,
	TPL_INF_D,
	TPL_UP,
	TPL_UP_ALL
}

new tplBitSum[tplVario]

new const teamColor[] = {
	print_team_grey,
	print_team_red,
	print_team_blue
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	cvar[CVAR_TPL_MODE] = register_cvar("aes_informer_tpl","0");
	cvar[CVAR_HUD_UPDATE] = register_cvar("aes_hud_update","1.5");
	cvar[CVAR_HUD_INFO_DEFAULT] = register_cvar("aes_hud_info_default","1");
	cvar[CVAR_HUD_INFO_TYPE] = register_cvar("aes_hud_info_type","1");
	cvar[CVAR_HUD_INFO_COLOR] = register_cvar("aes_hud_info_color","100 100 100");
	cvar[CVAR_HUD_INFO_POS] = register_cvar("aes_hud_info_pos","0.01 0.13");
	cvar[CVAR_HUD_ANEW_TYPE] = register_cvar("aes_hud_anew_type","1");
	cvar[CVAR_HUD_ANEW_COLOR] = register_cvar("aes_hud_anew_color","100 100 100");
	cvar[CVAR_HUD_ANEW_POS] = register_cvar("aes_hud_anew_pos","-1.0 0.90");
	cvar[CVAR_CHAT_NEW_LEVEL] = register_cvar("aes_newlevel_chat","2");

	cvar[CVAR_HUD_INFO_TYPE_D] = register_cvar("aes_hud_info_default_d","1");
	cvar[CVAR_HUD_INFO_COLOR_D] = register_cvar("aes_hud_info_color_d","60 60 60");
	cvar[CVAR_HUD_INFO_POS_D] = register_cvar("aes_hud_info_pos_d","0.01 0.15");
	#if defined CSSTATSX_SQL
	g_cvar_skill = register_cvar("aes_statsx_skill","60.0 75.0 85.0 100.0 115.0 130.0 140.0 150.0 165.0 180.0 195.0 210.0");
	#endif

	register_clcmd("say /aenable","Informer_Switch",0,"- switch experience informer on/off");
}

public plugin_cfg()
{
	#if defined CSSTATSX_SQL
	new levelString[512], stPos, ePos, rawPoint[20], cnt;
	get_pcvar_string(g_cvar_skill, levelString, charsmax(levelString));

	// парсер значений для скилла
	do {
		ePos = strfind(levelString[stPos], " ");

		formatex(rawPoint, ePos, levelString[stPos]);
		g_skill_opt[cnt] = str_to_float(rawPoint);

		stPos += ePos + 1;

		cnt++;

		// narkoman wole suka
		if(cnt > charsmax(g_skill_letters))
			break;
	} while (ePos != -1)
	#endif
	bonusEnabledPointer = get_cvar_pointer("aes_bonus_enable");

	hudUpdateInterval = get_pcvar_float(cvar[CVAR_HUD_UPDATE]);
	hudInfoOn = get_pcvar_num(cvar[CVAR_HUD_INFO_DEFAULT]) > 0 ? true : false;
	hudDeadOn = get_pcvar_num(cvar[CVAR_HUD_INFO_TYPE_D]) > 0 ? true : false;
	hudaNewOn = get_pcvar_num(cvar[CVAR_HUD_ANEW_TYPE]) > 0 ? true : false;
	chatLvlUpStyle = get_pcvar_num(cvar[CVAR_CHAT_NEW_LEVEL]);
	isTplMode = get_pcvar_num(cvar[CVAR_TPL_MODE]) > 0 ? true : false;

	if(!bonusEnabledPointer)
		hudaNewOn = false;

	new temp[15],sColor[3][6];

	if(hudInfoOn){
		get_pcvar_string(cvar[CVAR_HUD_INFO_COLOR],temp,14);

		if(strcmp(temp,"random") != 0)
		{
			parse(temp,sColor[0],3,sColor[1],3,sColor[2],3);

			hudInfoColor[0] = str_to_num(sColor[0]);
			hudInfoColor[1] = str_to_num(sColor[1]);
			hudInfoColor[2] = str_to_num(sColor[2]);
		}
		else
			hudInfoColorRandom = true;

		get_pcvar_string(cvar[CVAR_HUD_INFO_POS],temp,14);
		parse(temp,sColor[0],5,sColor[1],5);

		hudInfoxPos = str_to_float(sColor[0]);
		hudInfoyPos = str_to_float(sColor[1]);

		informerSyncObj = CreateHudSyncObj();

		if(isTplMode){ // sum
			new tplString[256];
			formatex(tplString,charsmax(tplString),"%L",LANG_SERVER,"AES_HUD_TPL");

			for(new i ; i < tplInfo ; i++)
			{
				if(contain(tplString,tplKeys[i]) != -1)
					tplBitSum[TPL_INF] |= (1<<i);
			}
		}
	}

	if(hudDeadOn)
	{
		get_pcvar_string(cvar[CVAR_HUD_INFO_COLOR_D],temp,14);

		if(strcmp(temp,"random") != 0)
		{
			parse(temp,sColor[0],3,sColor[1],3,sColor[2],3);

			hudDeadColor[0] = str_to_num(sColor[0]);
			hudDeadColor[1] = str_to_num(sColor[1]);
			hudDeadColor[2] = str_to_num(sColor[2]);
		}
		else
			hudDeadColorRandom = true;

		get_pcvar_string(cvar[CVAR_HUD_INFO_POS_D],temp,14);
		parse(temp,sColor[0],5,sColor[1],5);

		hudDeadxPos = str_to_float(sColor[0]);
		hudDeadyPos = str_to_float(sColor[1]);

		if(!informerSyncObj)
			informerSyncObj = CreateHudSyncObj();

		if(isTplMode)
		{ // sum
			new tplString[256];
			formatex(tplString,charsmax(tplString),"%L",LANG_SERVER,"AES_HUD_TPL_D");

			for(new i ; i < tplInfo ; i++)
			{
				if(contain(tplString,tplKeys[i]) != -1)
					tplBitSum[TPL_INF_D] |= (1<<i);
			}
		}
	}

	if(isTplMode)
	{ // bit sum for chat notify messages
		switch(chatLvlUpStyle )
		{
			case 1:
			{
				new tplString[256];
				formatex(tplString,charsmax(tplString),"%L",LANG_SERVER,"AES_NEWLEVEL_TPL");

				for(new i ; i < tplInfo ; i++)
				{
					if(contain(tplString,tplKeys[i]) != -1)
						tplBitSum[TPL_UP] |= (1<<i);
				}

			}
			case 2:
			{
				new tplString[256];
				formatex(tplString,charsmax(tplString),"%L",LANG_SERVER,"AES_NEWLEVEL_TPL");

				for(new i ; i < tplInfo ; i++)
				{
					if(contain(tplString,tplKeys[i]) != -1)
						tplBitSum[TPL_UP] |= (1<<i);
				}

				formatex(tplString,charsmax(tplString),"%L",LANG_SERVER,"AES_NEWLEVEL_ALL_TPL");

				for(new i ; i < tplInfo ; i++)
				{
					if(contain(tplString,tplKeys[i]) != -1)
						tplBitSum[TPL_UP_ALL] |= (1<<i);
				}
			}
		}
	}

	if(hudaNewOn)
	{
		get_pcvar_string(cvar[CVAR_HUD_ANEW_COLOR],temp,14);
		parse(temp,sColor[0],3,sColor[1],3,sColor[2],3);

		hudaNewColor[0] = str_to_num(sColor[0]);
		hudaNewColor[1] = str_to_num(sColor[1]);
		hudaNewColor[2] = str_to_num(sColor[2]);

		get_pcvar_string(cvar[CVAR_HUD_ANEW_POS],temp,14);
		parse(temp,sColor[0],5,sColor[1],5);

		hudaNewxPos = str_to_float(sColor[0]);
		hudaNewyPos = str_to_float(sColor[1]);

		aNewSyncObj = CreateHudSyncObj();
	}

	aesMaxLevel = aes_get_max_level() - 1;

	g_trackmode = get_cvar_num("aes_track_mode");
	g_DisabledInformer = TrieCreate();

	#if AMXX_VERSION_NUM < 183
	g_ADisabledInformer = ArrayCreate(36);
	#endif

	new fPath[256],len;

	// TODO: directory autocreate
	len += get_datadir(fPath,charsmax(fPath));
	len += formatex(fPath[len],charsmax(fPath) - len,"/aes/informer.ini");

	new f = fopen(fPath,"r");

	if(f)
	{
		new buffer[512];

		while(!feof(f))
		{
			fgets(f,buffer,511);
			trim(buffer);

			if(!strlen(buffer) || buffer[0] == ';')
				continue;

			remove_quotes(buffer);

			TrieSetCell(g_DisabledInformer,buffer,true);

			#if AMXX_VERSION_NUM < 183
			ArrayPushString(g_ADisabledInformer,buffer);
			#endif
		}

		fclose(f);

	}
}

public plugin_end()
{
	new fPath[256],len;
	len += get_datadir(fPath,charsmax(fPath));
	len += formatex(fPath[len],charsmax(fPath) - len,"/aes/informer.ini");

	#if AMXX_VERSION_NUM < 183
	if(ArraySize(g_ADisabledInformer))
	{
		new f = fopen(fPath,"w+");

		fprintf(f,"; %s^n; by %s^n^n; Disable informer for SteamID^n",PLUGIN,AUTHOR);

		new trackId[36];

		for(new i ; i < ArraySize(g_ADisabledInformer) ; ++i)
		{
			ArrayGetString(g_ADisabledInformer,i,trackId,35);

			if(!TrieKeyExists(g_DisabledInformer,trackId))
				continue;

			fprintf(f,"^n^"%s^"",trackId);
		}

		fclose(f);
	}
	#else
	new Snapshot:trieIterator = TrieSnapshotCreate(g_DisabledInformer);

	if(TrieSnapshotLength(trieIterator))
	{
		new f = fopen(fPath,"w+");
		fprintf(f,"; %s^n; by %s^n^n; Disable informer for SteamID^n",PLUGIN,AUTHOR);

		new trackId[36];

		for(new i,trieSize = TrieSnapshotLength(trieIterator) ; i < trieSize ; i++)
		{
			TrieSnapshotGetKey(trieIterator,i,trackId,charsmax(trackId));
			fprintf(f,"^n^"%s^"",trackId);
		}

		fclose(f);
	}
	#endif

	else
	{
		if(file_exists(fPath))
			delete_file(fPath);
	}

	#if AMXX_VERSION_NUM >= 183
	TrieSnapshotDestroy(trieIterator);
	#endif
}

public Informer_Switch(id)
{
	if(!hudInfoOn && !hudDeadOn)
		return 0;

	new trackId[36];

	if(!get_player_trackid(id,trackId,charsmax(trackId)))
		return 0;

	if(!TrieKeyExists(g_DisabledInformer,trackId))
	{
		TrieSetCell(g_DisabledInformer,trackId,1);

		#if AMXX_VERSION_NUM < 183
		if(!CheckStringInArray(g_ADisabledInformer,trackId))
			ArrayPushArray(g_ADisabledInformer,trackId);
		#endif

		client_print_color(id,print_team_red,"%L %L",id,"AES_TAG",id,"AES_INFORMER_DISABLED");

		remove_task(PLAYER_HUD_OFFSET + id);
	}
	else
	{
		TrieDeleteKey(g_DisabledInformer,trackId);
		set_task(hudUpdateInterval,"Show_Hud_Informer",PLAYER_HUD_OFFSET + id,.flags="b");

		client_print_color(id,print_team_blue,"%L %L",id,"AES_TAG",id,"AES_INFORMER_ENABLED");
	}

	return 0;
}

#if AMXX_VERSION_NUM < 183
CheckStringInArray(Array:which,string[])
{
	new str[64];

	for(new i,arrSize = ArraySize(which) ; i < arrSize ; ++i)
	{
		ArrayGetString(which,i,str,charsmax(str));

		if(strcmp(string,str) == 0)
			return true;
	}

	return false;
}
#endif

public client_putinserver(id)
{
	if((hudInfoOn || hudaNewOn) && !is_user_bot(id))
	{
		new trackId[36];
		get_player_trackid(id,trackId,charsmax(trackId));

		if(!TrieKeyExists(g_DisabledInformer,trackId))
			set_task(hudUpdateInterval,"Show_Hud_Informer",PLAYER_HUD_OFFSET + id,.flags="b");
	}
}

public client_disconnected(id)
{
	if((hudInfoOn || hudaNewOn) &&!is_user_bot(id))
		remove_task(PLAYER_HUD_OFFSET + id);
}

public aes_player_levelup(id,newlevel,oldlevel)
{
	new levelName[AES_MAX_LEVEL_LENGTH];

	switch(chatLvlUpStyle)
	{
		case 1:
		{
			aes_get_level_name(newlevel,levelName,charsmax(levelName),id);

			if(!isTplMode)
				client_print_color(id,print_team_default,"%L %L",id,"AES_TAG",id,"AES_NEWLEVEL_ID",levelName);
			else
			{
				new msg[191],len;
				tplFormatNewLevel(id,msg,len,"AES_NEWLEVEL_TPL",id,TPL_UP);

				client_print_color(id,print_team_default,msg);
			}
		}
		case 2:
		{
			new pls[32],pnum,name[32];
			get_players(pls,pnum,"c");
			get_user_name(id,name,charsmax(name));

			new upTeam = get_user_team(id);

			if(!(0 <= upTeam < sizeof teamColor))
				upTeam = 0;

			for(new i,player; i < pnum ; ++i)
			{
				player = pls[i];

				aes_get_level_name(newlevel,levelName,charsmax(levelName),player);

				if(player != id)
				{
					if(!isTplMode)
						client_print_color(player,teamColor[upTeam],"%L %L",player,"AES_TAG",player,"AES_NEWLEVEL_ALL",name,levelName);
					else
					{
						new msg[191],len;
						tplFormatNewLevel(id,msg,len,"AES_NEWLEVEL_ALL_TPL",player,TPL_UP_ALL);

						client_print_color(player,teamColor[upTeam],msg);
					}
				}
				else
				{
					if(!isTplMode)
						client_print_color(id,teamColor[upTeam],"%L %L",id,"AES_TAG",id,"AES_NEWLEVEL_ID",levelName)
					else
					{
						new msg[191],len;
						tplFormatNewLevel(id,msg,len,"AES_NEWLEVEL_TPL",id,TPL_UP);

						client_print_color(id,teamColor[upTeam],msg);
					}
				}
			}
		}
		default: return;
	}
}

public tplFormatNewLevel(id,msg[],len,tplKey[],idLang,tplType)
{
	new Float:player_exp = aes_get_player_exp(id);
	new Float:player_reqexp = aes_get_player_reqexp(id);
	new player_level = aes_get_player_level(id);
	new player_bonus = aes_get_player_bonus(id);

	len = formatex(msg[len],190-len,"%L ",idLang,"AES_TAG");

	len += parse_informer_tpl(
		id,id,msg,len,190,tplKey,tplType,idLang,

		player_exp,
		player_level,
		player_reqexp,
		player_bonus
	);

	return len;
}

public Show_Hud_Informer(taskId)
{
	new id = taskId - PLAYER_HUD_OFFSET;
	new watchId = id;
	new isAlive = is_user_alive(id);
	new szTime[64]; get_time("%H:%M:%S", szTime, charsmax(szTime));

	if(informerSyncObj != 0)
		ClearSyncHud(id,informerSyncObj);

	if(!isAlive){
		watchId = get_entvar(id, var_iuser2);

		if(!watchId)
			return;
	}

	new hudMessage[256],len;

	new Float:player_exp = aes_get_player_exp(watchId);
	new Float:player_reqexp = aes_get_player_reqexp(watchId);
	new player_level = aes_get_player_level(watchId);
	new player_bonus = aes_get_player_bonus(watchId);


	new bool:status = true;

	if(player_exp == -1.0)
		status = false;

	if(hudInfoOn){
		ClearSyncHud(id,informerSyncObj);

		if(status)
		{
			if(!isTplMode)
			{
				if(playerWatchLevel[id] != player_level || !playerLevel[id][0])
				{
					aes_get_level_name(player_level,playerLevel[id],charsmax(playerLevel[]),id);
					playerWatchLevel[id] = player_level;
				}

				if(watchId != id)
				{
					new watchName[32];
					get_user_name(watchId,watchName,charsmax(watchName));

					len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L^n",id,"AES_INFORMER0",watchName);
				}

				len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L^n",id,"AES_INFORMER1",playerLevel[id]);

				if(player_reqexp != -1.0)
					len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L",id,"AES_INFORMER2",player_exp,player_reqexp);
				else
					len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L",id,"AES_PLAYER_XP_MAX");
			}
			else
			{
				if(isAlive)
				{
					len += parse_informer_tpl(
						id,watchId,
						hudMessage,len,charsmax(hudMessage),"AES_HUD_TPL",TPL_INF,id,

						player_exp,
						player_level,
						player_reqexp,
						player_bonus
					);
				}
				else if(!isAlive && hudDeadOn)
				{
					len += parse_informer_tpl(
						id,watchId,
						hudMessage,len,charsmax(hudMessage),"AES_HUD_TPL_D",TPL_INF_D,id,

						player_exp,
						player_level,
						player_reqexp,
						player_bonus
					);
				}
			}

		}
		else
			len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L",id,"AES_INFORMER_FAIL");

		if(isAlive)
		{
			if(hudInfoColorRandom)
			{
				hudInfoColor[0] = random(255);
				hudInfoColor[1] = random(255);
				hudInfoColor[2] = random(255);
			}

			set_hudmessage(hudInfoColor[0], hudInfoColor[1], hudInfoColor[2], hudInfoxPos , hudInfoyPos,.holdtime = hudUpdateInterval,.channel = 3);
		}
		else if(!isAlive && hudDeadOn)
		{
			if(hudDeadColorRandom)
			{
				hudDeadColor[0] = random(255);
				hudDeadColor[1] = random(255);
				hudDeadColor[2] = random(255);
			}

			set_hudmessage(hudDeadColor[0],hudDeadColor[1],hudDeadColor[2],hudDeadxPos,hudDeadyPos,0,.holdtime = hudUpdateInterval,.channel = 3);
		}

		replace_all(hudMessage,charsmax(hudMessage),"\n","^n");
		ShowSyncHudMsg(id,informerSyncObj,hudMessage);

		len = 0;
		hudMessage[0] = 0;
	}

	if(hudaNewOn && get_pcvar_num(bonusEnabledPointer) == 1 && player_bonus > 0 && watchId == id)
	{
		ClearSyncHud(id,aNewSyncObj);

		len += formatex(hudMessage[len],charsmax(hudMessage) - len,"%L",id,"AES_ANEW_HUD",player_bonus);
		replace_all(hudMessage,charsmax(hudMessage),"\n","^n");

		set_hudmessage(hudaNewColor[0],hudaNewColor[1],hudaNewColor[2],hudaNewxPos,hudaNewyPos,0,.holdtime = hudUpdateInterval);
		ShowSyncHudMsg(id,aNewSyncObj,hudMessage);
	}
}

public parse_informer_tpl(id,watchId,string[],len,maxLen,tplKey[],tplType,idLang,Float:player_exp,player_level,Float:player_reqexp,player_bonus)
{

	static tpl[256],tmp[AES_MAX_LEVEL_LENGTH],i;

	tpl[0] = 0;
	tmp[0] = 0;
	new top[8];
	new rank = get_user_stats_sql(watchId, top, top);
	new maxtop = get_statsnum_sql();
	new a = get_timeleft();

	formatex(tpl,charsmax(tpl),"%L",idLang,tplKey);

	player_exp = _:player_exp >= 0 ? player_exp + 0.005 : player_exp - 0.005;
	player_reqexp = _:player_reqexp >= 0 ? player_reqexp + 0.005 : player_reqexp - 0.005;

	for(i = 0; i < tplInfo ; i++)
	{
		if(tplBitSum[tplType] & (1 << i))
		{
			tmp[0] = 0;

			switch(i)
			{
				case INF_EXP: formatex(tmp,charsmax(tmp),"%.0f",player_exp);
				case INF_LEVELEXP:
				{
					if(player_reqexp >= 0)
						formatex(tmp,charsmax(tmp),"%.0f",player_reqexp);
					else
						formatex(tmp,charsmax(tmp),"MAX");
				}
				case INF_NEEDEXP:
				{
					if(player_reqexp >= 0)
						formatex(tmp,charsmax(tmp),"%.0f",player_reqexp - player_exp);
					else
						formatex(tmp,charsmax(tmp),"-");
				}
				case INF_LEVEL: formatex(tmp,charsmax(tmp),"%d",player_level + 1);
				case INF_MAXLEVEL: formatex(tmp,charsmax(tmp),"%d",aesMaxLevel);
				case INF_RANK:
				{
					if(playerWatchLevel[id] != player_level || !playerLevel[id][0])
					{
						aes_get_level_name(player_level,playerLevel[id],charsmax(playerLevel[]),idLang);
						playerWatchLevel[id] = player_level;
					}

					copy(tmp,charsmax(tmp),playerLevel[id]);
				}
				case INF_NAME: get_user_name(watchId,tmp,charsmax(tmp));
				case INF_TIME: get_time("%d.%m.%Y - %H:%M:%S",tmp, charsmax(tmp));
				case INF_STEAMID: get_user_authid(watchId,tmp,charsmax(tmp));
				case INF_BONUS: formatex(tmp,charsmax(tmp),"%d",player_bonus);
				case INF_TOP: formatex(tmp, charsmax(tmp),"%d",rank);
				case INF_MAXTOP: formatex(tmp, charsmax(tmp),"%d",maxtop);
				case INF_TIMELEFT: formatex(tmp, charsmax(tmp), "%d:%d", (a / 60), (a % 60));
				case INF_MAPNAME: get_mapname(tmp, charsmax(tmp));

#if defined CSSTATSX_SQL
				case INF_SKILL: statsx_get_user_skill_name(watchId, tmp, charsmax(tmp));
#endif
				case INF_EXF: formatex(tmp,charsmax(tmp),"%.2f",player_exp);
				case INF_LXF: formatex(tmp,charsmax(tmp),"%.2f",player_reqexp);
				case INF_NXF: formatex(tmp,charsmax(tmp),"%.2f",player_reqexp - player_exp);
			}

			if(tmp[0])
				replace(tpl,charsmax(tpl),tplKeys[i],tmp);
		}
	}

	len += formatex(string[len],maxLen-len,tpl);

	return len;
}

get_player_trackid(id,trackId[],trackLen)
{
	switch(g_trackmode)
	{
		case 0: get_user_name(id,trackId,trackLen);
		case 1:
		{
			get_user_authid(id,trackId,trackLen);

			if(!strcmp(trackId,"STEAM_ID_LAN") || !strcmp(trackId,"VALVE_ID_LAN") || !strcmp(trackId,"BOT")	|| !strcmp(trackId,"HLTV"))
				return 0;
		}
		case 2: get_user_ip(id,trackId,trackLen,1);
	}

	return 1;
}
#if defined CSSTATSX_SQL
statsx_get_user_skill_name(id, name[], len)
{
	new tmp[10],Float:skill;
	get_user_skill(id, skill);

	new skill_id = statsx_get_skill_id(skill);
	formatex(tmp,charsmax(tmp),"%s %.2f",g_skill_letters[skill_id], skill);
	copy(name, len, tmp);
}

statsx_get_skill_id(Float:skill)
{
	for(new i = 0; i < sizeof(g_skill_opt); i++)
	{
		if(skill < g_skill_opt[i])
			return i;
	}
	return charsmax(g_skill_opt);
}
#endif
