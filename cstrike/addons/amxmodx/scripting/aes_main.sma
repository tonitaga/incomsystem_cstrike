/*
*	Advanced Experience System	     v. 0.5
*	by serfreeman1337	    http://1337.uz/
*/

#include <amxmodx>
#include <aes_v>
#include <sqlx>

#define PLUGIN "Advanced Experience System"
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

 #pragma dynamic 32768

// -- КОНСТАНТЫ -- //

enum _:sql_que_type	// тип sql запроса
{
	SQL_DUMMY,
	SQL_IMPORT,	// импорт в БД из файла stats.ini
	SQL_IMPORTFINISH,
	SQL_LOAD,	// загрузка статистики
	SQL_UPDATE,	// обновление
	SQL_INSERT,	// внесение новой записи
	SQL_UPDATERANK,	// получение ранков игроков,
	SQL_GETSTATS	// потоквый запрос на get_stats
}

enum _:load_state_type	// состояние получение статистики
{
	LOAD_NO,	// данных нет
	LOAD_WAIT,	// ожидание данных
	LOAD_NEW,	// новая запись
	LOAD_NEWWAIT,	// новая запись, ждем ответа
	LOAD_UPDATE,	// перезагрузить после обновления
	LOAD_OK		// есть данные
}

enum _:cvars
{
	CVAR_SQL_TYPE,
	CVAR_SQL_HOST,
	CVAR_SQL_USER,
	CVAR_SQL_PASS,
	CVAR_SQL_DB,
	CVAR_SQL_TABLE,
	CVAR_SQL_CREATE_DB,
	CVAR_SQL_MAXFAIL,

	CVAR_RANK,
	CVAR_RANKBOTS,
	CVAR_PAUSE,

	CVAR_LEVELS
}

enum _:player_data_struct
{
	PLAYER_ID,				// id игрока БД
	PLAYER_LOADSTATE,			// состояние загрузки статистики игрока

	Float:PLAYER_EXP,			// тек. опыт игрока
	Float:PLAYER_EXPLAST,			// последний опыт игрока
	PLAYER_BONUS,				// бонусы игрока
	PLAYER_BONUSLAST,			// последнее кол-во бонусов

	PLAYER_NAME[MAX_NAME_LENGTH * 3],	// ник игрока
	PLAYER_STEAMID[30],			// steamid игрока
	PLAYER_IP[16],				// ip игрока

	PLAYER_LEVEL,				// уровень игрока
	Float:PLAYER_LEVELEXP,			// опыт для уровня
	Float:PLAYER_EXP_TO_NEXT		// требуемое кол-во опыта для сл. уровня игроку
}

enum _:row_ids		// столбцы таблицы
{
	ROW_ID,
	ROW_NAME,
	ROW_STEAMID,
	ROW_IP,
	ROW_EXP,
	ROW_BONUS,
	ROW_LASTUPDATE
}

enum (+=1) {
	NONE = 0,
	MYSQL,
	SQLITE,
	AMX,
	FB
}

new const row_names[row_ids][] = // имена столбцов
{
	"id",
	"name",
	"steamid",
	"ip",
	"exp",
	"bonus_count",
	"last_update"
}

const QUERY_LENGTH =	1472		// мой ммр, когда я катаю пати

// -- ПЕРЕМЕННЫЕ --
new player_data[MAX_PLAYERS + 1][player_data_struct];
new cvar[cvars];

new tbl_name[32];
new Handle:sql;
new cnt_sqlfail,bool:gg_sql;
new g_System = NONE;

new Array:levels_list;
new levels_count;
new Float:max_exp;

new FW_LevelUp, FW_LevelDown, FW_PlConnect;
new dummy;

new flush_que[QUERY_LENGTH * 3],flush_que_len;
new const task_flush		=	11337;
new bool:is_by_stats		=	false;

// -- ПОДКЛЮЧЕНИЕ ЧЕРЕЗ БАН-СИСТЕМУ --
forward amxbans_sql_initialized(Handle:sqlTuple, const dbPrefix[]);
forward fbans_sql_connected(Handle:sqlTuple);

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR);

	server_print("");
	server_print("   %s Copyright (c) 2016 %s",PLUGIN,AUTHOR);
	server_print("   Version %s build on %s", VERSION, LASTUPDATE);
	server_print("");

	//
	// Квары настройки подключения
	//
	cvar[CVAR_SQL_TYPE] = register_cvar("aes_sql_driver","sqlite");
	cvar[CVAR_SQL_HOST] = register_cvar("aes_sql_host","",FCVAR_UNLOGGED|FCVAR_PROTECTED);
	cvar[CVAR_SQL_USER] = register_cvar("aes_sql_user","",FCVAR_UNLOGGED|FCVAR_PROTECTED);
	cvar[CVAR_SQL_PASS] = register_cvar("aes_sql_pass","",FCVAR_UNLOGGED|FCVAR_PROTECTED);
	cvar[CVAR_SQL_DB] = register_cvar("aes_sql_name","amxx",FCVAR_UNLOGGED|FCVAR_PROTECTED);
	cvar[CVAR_SQL_TABLE] = register_cvar("aes_sql_table","aes_stats",FCVAR_UNLOGGED|FCVAR_PROTECTED);
	cvar[CVAR_SQL_MAXFAIL] = register_cvar("aes_sql_maxfail","10");

	cvar[CVAR_SQL_CREATE_DB] = register_cvar("aes_sql_create_db","1");

	cvar[CVAR_RANK] = register_cvar("aes_track_mode","1");
	cvar[CVAR_RANKBOTS] = register_cvar("aes_track_bots","1");
	cvar[CVAR_PAUSE] = register_cvar("aes_track_pause","0",FCVAR_SERVER);

	cvar[CVAR_LEVELS] = register_cvar("aes_level","0 20 40 60 100 150 200 300 400 600 1000 1500 2100 2700 3400 4200 5100 5900 7000 10000");

	FW_LevelUp = CreateMultiForward("aes_player_levelup",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	FW_LevelDown = CreateMultiForward("aes_player_leveldown",ET_IGNORE,FP_CELL,FP_CELL,FP_CELL);
	FW_PlConnect = CreateMultiForward("aes_player_connect",ET_IGNORE,FP_CELL);

	register_srvcmd("aes_import","ImportFromFile");

	register_dictionary("aes.txt");

	#if AMXX_VERSION_NUM < 183
		MaxClients = get_maxplayers();
	#endif

	register_cvar("aes", VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED);
}

#pragma unused max_exp

//
// загрузка конфигурации
//
public plugin_cfg()
{
	new cfg_path[256];
	get_localinfo("amxx_configsdir", cfg_path, charsmax(cfg_path));

	server_cmd("exec %s/aes/aes.cfg",cfg_path);
	server_exec();

	// парсим уровни
	new levels_string[512],level_str[10];
	get_pcvar_string(cvar[CVAR_LEVELS],levels_string,charsmax(levels_string));
	levels_list = ArrayCreate(1);

	#if AMXX_VERSION_NUM < 183
	if(levels_string[0])
	{
		new e_pos,s_pos;

		do {
			e_pos = strfind(levels_string[s_pos]," ");

			formatex(level_str,e_pos,levels_string[s_pos]);

			if(!levels_list)
				levels_list = ArrayCreate(1);

			ArrayPushCell(levels_list,floatstr(level_str));
			max_exp = floatstr(level_str);

			s_pos += e_pos + 1;
		} while (e_pos != -1)
	}
	#else
	while((argbreak(levels_string,level_str,charsmax(level_str),levels_string,charsmax(levels_string))) != -1)
	{
		if(!levels_list)
			levels_list = ArrayCreate(1);

		ArrayPushCell(levels_list,floatstr(level_str));
		max_exp = floatstr(level_str);
	}
	#endif

	if(levels_list)
		levels_count = ArraySize(levels_list);

	// AES работает в режиме статистики по csx
	// выключаем работу с БД
	if(get_pcvar_num(cvar[CVAR_RANK]) == -1)
	{
		is_by_stats = true;
		return PLUGIN_CONTINUE;
	}

	new type[12];
	get_pcvar_string(cvar[CVAR_SQL_TYPE],type,charsmax(type));


	if(strcmp(type,"mysql") == 0)
		g_System = MYSQL;
	else if(strcmp(type,"sqlite") == 0)
		g_System = SQLITE;
	else if(strcmp(type,"bans") == 0){}
	else
		set_fail_state("invalid ^"aes_sql_driver^" cvar value");


	if (g_System == MYSQL || g_System == SQLITE)
	{
		new host[128],user[64],pass[64],db[64];
		get_pcvar_string(cvar[CVAR_SQL_HOST],host,charsmax(host));
		get_pcvar_string(cvar[CVAR_SQL_USER],user,charsmax(user));
		get_pcvar_string(cvar[CVAR_SQL_PASS],pass,charsmax(pass));
		get_pcvar_string(cvar[CVAR_SQL_DB],db,charsmax(db));
		get_pcvar_string(cvar[CVAR_SQL_TABLE],tbl_name,charsmax(tbl_name));

		SQL_SetAffinity(type);
		sql = SQL_MakeDbTuple(host,user,pass,db,3);

		if(get_pcvar_num(cvar[CVAR_SQL_CREATE_DB]))
			CreateTable();
	}

	return PLUGIN_CONTINUE;
}

public CreateTable()
{
	new sql_data[1], query[QUERY_LENGTH];

	switch (g_System)
	{
		case AMX,FB,MYSQL :
		{
			formatex(query,charsmax(query),"\
				CREATE TABLE IF NOT EXISTS `%s` (\
					`%s` int(11) NOT NULL AUTO_INCREMENT,\
					`%s` varchar(32) NOT NULL,\
					`%s` varchar(30) NOT NULL,\
					`%s` varchar(16) NOT NULL,\
					`%s` float NOT NULL DEFAULT '0.0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,\
					PRIMARY KEY (%s),\
					INDEX (`%s`)\
				);",

				tbl_name,
				row_names[ROW_ID],
				row_names[ROW_NAME],
				row_names[ROW_STEAMID],
				row_names[ROW_IP],
				row_names[ROW_EXP],
				row_names[ROW_BONUS],
				row_names[ROW_LASTUPDATE],
				row_names[ROW_ID],
				row_names[get_pcvar_num(cvar[CVAR_RANK]) + 1]
			);
		}
		case SQLITE :
		{
			formatex(query,charsmax(query),"\
				CREATE TABLE IF NOT EXISTS `%s` (\
					`%s`	INTEGER PRIMARY KEY AUTOINCREMENT,\
					`%s`	TEXT,\
					`%s`	TEXT,\
					`%s`	TEXT,\
					`%s`	REAL NOT NULL DEFAULT 0.0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP\
				);",

				tbl_name,
				row_names[ROW_ID],
				row_names[ROW_NAME],
				row_names[ROW_STEAMID],
				row_names[ROW_IP],
				row_names[ROW_EXP],
				row_names[ROW_BONUS],
				row_names[ROW_LASTUPDATE]
			);
		}
	}

	sql_data[0] = SQL_DUMMY;

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data);
}

public amxbans_sql_initialized(Handle:sqlTuple, const dbPrefix[])
{
	if (g_System != NONE || is_by_stats)
		return PLUGIN_CONTINUE;

	sql = sqlTuple;
	g_System = AMX;

	get_pcvar_string(cvar[CVAR_SQL_TABLE],tbl_name,charsmax(tbl_name));

	if(get_pcvar_num(cvar[CVAR_SQL_CREATE_DB]))
			CreateTable();

	return PLUGIN_CONTINUE;
}

public fbans_sql_connected(Handle:sqlTuple)
{
	if (g_System != NONE || is_by_stats)
		return PLUGIN_CONTINUE;

	sql = sqlTuple;
	g_System = FB;

	get_pcvar_string(cvar[CVAR_SQL_TABLE],tbl_name,charsmax(tbl_name));

	if(get_pcvar_num(cvar[CVAR_SQL_CREATE_DB]))
			CreateTable();

	return PLUGIN_CONTINUE;
}

public plugin_end()
	DB_FlushQuery();

//
// Функция импорта в БД из файла stats.ini
//
public ImportFromFile()
{
	if(sql == Empty_Handle)
	{
		log_amx("DB is disabled");
		return false;
	}

	new fPath[256],len;
	len = get_localinfo("amxx_datadir", fPath, charsmax(fPath));

	len += formatex(fPath[len],charsmax(fPath) - len,"/aes/stats.ini");

	new f = fopen(fPath,"r");

	if(!f)
	{
		log_amx("^"%s^" doesn't exists",fPath);
		return false;
	}

	new query[QUERY_LENGTH],sql_data[2] = SQL_DUMMY;


	log_amx("import started");
	log_amx("clearing ^"%s^" table",tbl_name);

	// очищаем таблицу перед началом импорта
	formatex(query,charsmax(query),"TRUNCATE TABLE `%s`",tbl_name);

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data);

	new track_field;

	// сверяем track_id
	switch(get_pcvar_num(cvar[CVAR_RANK]))
	{
		case 0: track_field = ROW_NAME;
		case 1: track_field = ROW_STEAMID;
		case 2: track_field = ROW_IP;
		default: return false;
	}

	while(!feof(f))
	{
		new buffer[512];
		fgets(f,buffer,charsmax(buffer));
		trim(buffer);

		if(!buffer[0] || buffer[0] == ';')
			continue;

		new trackId[MAX_NAME_LENGTH * 3],userName[MAX_NAME_LENGTH * 3],sStats[4][12],import_data[31];
		import_data[0] = SQL_IMPORT;

		parse(buffer,trackId,charsmax(trackId),
			userName,charsmax(userName),
			sStats[0],charsmax(sStats[]),
			sStats[3],charsmax(sStats[]),
			sStats[1],charsmax(sStats[]),
			sStats[2],charsmax(sStats[])
		);

		copy(import_data[1],charsmax(import_data) - 1,trackId);

		mysql_escape_string(trackId,charsmax(trackId));
		mysql_escape_string(userName,charsmax(userName));

		new lastdate[40];
		format_time(lastdate,charsmax(lastdate),"%Y-%m-%d %H:%M:%S",str_to_num(sStats[2]));

		// строим запрос на импорит
		if(track_field != ROW_NAME)
		{
			len = formatex(query,charsmax(query),"INSERT INTO `%s` (`%s`,`%s`,`%s`,`%s`,`%s`)\
				VALUES('%s','%s','%.2f','%d','%s');",

				tbl_name,

				row_names[track_field],
				row_names[ROW_NAME],
				row_names[ROW_EXP],
				row_names[ROW_BONUS],
				row_names[ROW_LASTUPDATE],

				trackId,
				userName,
				str_to_float(sStats[0]),
				str_to_num(sStats[1]),
				lastdate
			);
		}
		else
		{
			len = formatex(query,charsmax(query),"INSERT INTO `%s` (`%s`,`%s`,`%s`,`%s`)\
				VALUES('%s','%.2f','%d','%s');",

				tbl_name,

				row_names[track_field],
				row_names[ROW_EXP],
				row_names[ROW_BONUS],
				row_names[ROW_LASTUPDATE],

				trackId,
				str_to_float(sStats[0]),
				str_to_num(sStats[1]),
				lastdate
			);
		}

		SQL_ThreadQuery(sql,"SQL_Handler",query,import_data,sizeof import_data);
	}

	sql_data[0] = SQL_IMPORTFINISH;

	// запрос при окончании импорта
	formatex(query,charsmax(query),"SELECT COUNT(*) FROM `%s`",tbl_name);
	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data);

	fclose(f);

	return true;
}

//
// Загружаем статистику из БД при подключении игрока
//
public client_putinserver(id)
	DB_LoadPlayerData(id);

//
// Сохраняем данные на дисконнекте
//
public client_disconnected(id)
	DB_SavePlayerData(id);

//
// Смена ника игрока
//
public client_infochanged(id)
{
	new cur_name[MAX_NAME_LENGTH],new_name[MAX_NAME_LENGTH];
	get_user_name(id,cur_name,charsmax(cur_name));
	get_user_info(id,"name",new_name,charsmax(new_name));

	if(strcmp(cur_name,new_name) != 0)
	{
		copy(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]),new_name);
		mysql_escape_string(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]));

		if(get_pcvar_num(cvar[CVAR_RANK]) == 0)
			DB_SavePlayerData(id,true);
	}
}

//
// Задаем опыт игроку
//
Player_SetExp(id,Float:new_exp,bool:no_forward = false,bool:force = false)
{
	// статистика на паузе
	if(get_pcvar_num(cvar[CVAR_PAUSE]) && !force)
		return AES_RT_NO;

	// опыт не может быть отрицательным
	if(new_exp < 0.0)
		new_exp = 0.0;

	new rt = AES_RT_YES;
	player_data[id][PLAYER_EXP] = _:new_exp;

	if(new_exp < player_data[id][PLAYER_EXP_TO_NEXT])
		rt = AES_RT_LEVEL_DOWN;
	else if(new_exp >= player_data[id][PLAYER_EXP_TO_NEXT])
		rt = AES_RT_LEVEL_UP;

	// расчитываем новый уровень
	if(rt != AES_RT_YES)
	{
		new old_level = player_data[id][PLAYER_LEVEL];
		new level = player_data[id][PLAYER_LEVEL] = Level_GetByExp(new_exp);
		player_data[id][PLAYER_LEVELEXP] = _:Level_GetExp(player_data[id][PLAYER_LEVEL]);
		player_data[id][PLAYER_EXP_TO_NEXT] = _:Level_GetExpToNext(player_data[id][PLAYER_LEVEL]);

		if(!no_forward)
		{
			new fw;

			if(level > old_level)
				fw = FW_LevelUp;
			else if(level < old_level)
				fw = FW_LevelDown;

			if(fw)
				ExecuteForward(fw,dummy,id,level,old_level);
		}
	}

	return rt;
}

//
// Задаем бонусы игрока
//
Player_SetBonus(id,bonus,bool:force = false)
{
	// статистика на паузе
	if(get_pcvar_num(cvar[CVAR_PAUSE]) && !force)
		return false;

	player_data[id][PLAYER_BONUS] = bonus;

	return true;
}

//
// Задаем уровень игроку
//
Player_SetLevel(id,level,bool:force = false)
{
	// статистика на паузе
	if(get_pcvar_num(cvar[CVAR_PAUSE]) && !force)
		return false;

	new Float:exp = Level_GetExp(level);

	if(exp == -1.0)
		return false;

	player_data[id][PLAYER_EXP] = _:exp;
	player_data[id][PLAYER_LEVEL] = level;
	player_data[id][PLAYER_LEVELEXP] = _:Level_GetExp(player_data[id][PLAYER_LEVEL]);
	player_data[id][PLAYER_EXP_TO_NEXT] = _:Level_GetExpToNext(player_data[id][PLAYER_LEVEL]);

	return true;
}

//
// Функция возвращается текущий уровень по значению опыта
//
Level_GetByExp(Float:exp)
{
	for(new i ; i < levels_count ; i++)
	{
		// ищем уровень по опыту
		if(exp < ArrayGetCell(levels_list,i))
			return clamp(i  - 1,0,levels_count - 1);
	}

	// возвращаем максимальный уровень
	return levels_count - 1;
}

//
// Функция возвращает необходимый опыт до сл. уровня
//
Float:Level_GetExpToNext(level)
{
	level++;

	// достигнут максимальный уровень
	if(level >= levels_count)
		return -1.0;

	// TODO: проверки
	level = clamp(level,0,levels_count - 1);

	return ArrayGetCell(levels_list,level);
}

//
// Функция возвращает опыт для указанного уровня
//
Float:Level_GetExp(level)
{
	if(!(0 <= level < levels_count))
		return -1.0;

	return ArrayGetCell(levels_list,level);
}

//
// Загрузка статистики игрока из базы данных
//
DB_LoadPlayerData(id)
{
	if(sql == Empty_Handle || gg_sql)
		return false;

	if((!get_pcvar_num(cvar[CVAR_RANKBOTS]) && is_user_bot(id)) || is_user_hltv(id))
		return false;

	arrayset(player_data[id],0,player_data_struct);

	get_user_name(id,player_data[id][PLAYER_NAME],MAX_NAME_LENGTH - 1);
	mysql_escape_string(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]));

	get_user_authid(id,player_data[id][PLAYER_STEAMID],charsmax(player_data[][PLAYER_STEAMID]));
	get_user_ip(id,player_data[id][PLAYER_IP],charsmax(player_data[][PLAYER_IP]),true);

	// формируем SQL запрос
	new query[QUERY_LENGTH],len,sql_data[2];

	sql_data[0] = SQL_LOAD;
	sql_data[1] = id;
	player_data[id][PLAYER_LOADSTATE] = LOAD_WAIT;

	len += formatex(query[len],charsmax(query)-len,"SELECT * FROM `%s` WHERE ",tbl_name);

	switch(get_pcvar_num(cvar[CVAR_RANK]))
	{
		// статистика по нику
		case 0: len += formatex(query[len],charsmax(query)-len,"`name` = '%s'",player_data[id][PLAYER_NAME]);
		// статистика по steamid
		case 1: len += formatex(query[len],charsmax(query)-len,"`steamid` = '%s'",player_data[id][PLAYER_STEAMID]);
		// статистика по ip
		case 2: len += formatex(query[len],charsmax(query)-len,"`ip` = '%s'",player_data[id][PLAYER_IP]);
		default: return false;
	}

	// отправка потокового запроса
	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data);

	return true;
}

//
// Сохранение статистики игрока
//
DB_SavePlayerData(id,bool:reload = false)
{
	if(sql == Empty_Handle || gg_sql)
		return false;

	if(player_data[id][PLAYER_LOADSTATE] < LOAD_OK && player_data[id][PLAYER_LOADSTATE] != LOAD_NEW) // игрок не загрузился
		return false;

	new query[QUERY_LENGTH],len;

	new sql_data[2];
	sql_data[1] = id;

	switch(player_data[id][PLAYER_LOADSTATE])
	{
		case LOAD_OK: // обновление данных
		{
			if(reload)
				player_data[id][PLAYER_LOADSTATE] = LOAD_UPDATE;

			sql_data[0] = SQL_UPDATE;

			new to_save;

			len += formatex(query[len],charsmax(query) - len,"UPDATE `%s` SET",tbl_name);

			new Float:diffexp = player_data[id][PLAYER_EXP] - player_data[id][PLAYER_EXPLAST];
			new diffbonus = player_data[id][PLAYER_BONUS] - player_data[id][PLAYER_BONUSLAST];

			if(diffexp != 0.0)
			{
				len += formatex(query[len],charsmax(query) - len,"`%s` = `%s` + '%.2f'",
					row_names[ROW_EXP],
					row_names[ROW_EXP],
					_:diffexp >= 0 ? diffexp + 0.005 : diffexp - 0.005
				);

				player_data[id][PLAYER_EXPLAST] = _:player_data[id][PLAYER_EXP];

				to_save++;
			}

			if(diffbonus != 0)
			{
				len += formatex(query[len],charsmax(query) - len,"%s`%s` = `%s` + '%d'",
					to_save ? "," : "",
					row_names[ROW_BONUS],
					row_names[ROW_BONUS],
					diffbonus
				);

				player_data[id][PLAYER_BONUSLAST] = player_data[id][PLAYER_BONUS];

				to_save++;
			}

			// обновляем время последнего подключения, ник, ип и steamid
			len += formatex(query[len],charsmax(query) - len,",\
				`%s` = CURRENT_TIMESTAMP,\
				`%s` = '%s',\
				`%s` = '%s'",

				row_names[ROW_LASTUPDATE],
				row_names[ROW_STEAMID],player_data[id][PLAYER_STEAMID],
				row_names[ROW_IP],player_data[id][PLAYER_IP]
			);

			if(!reload) // не обновляем ник при его смене
				len += formatex(query[len],charsmax(query) - len,",`%s` = '%s'",row_names[ROW_NAME],player_data[id][PLAYER_NAME]);

			len += formatex(query[len],charsmax(query) - len,"WHERE `%s` = '%d'",row_names[ROW_ID],player_data[id][PLAYER_ID]);

			if(!to_save) // нечего сохранять
			{
				// я обманул. азазаза
				if(player_data[id][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[id][PLAYER_LOADSTATE] = LOAD_NO;
					DB_LoadPlayerData(id);
				}

				return false;
			}
		}
		case LOAD_NEW: // запрос на добавление новой записи
		{
			sql_data[0] = SQL_INSERT;

			formatex(query,charsmax(query),"INSERT INTO `%s` \
							(`%s`,`%s`,`%s`,`%s`,`%s`)\
							VALUES('%s','%s','%s','%.2f','%d')\
							",tbl_name,

					row_names[ROW_NAME],
					row_names[ROW_STEAMID],
					row_names[ROW_IP],
					row_names[ROW_EXP],
					row_names[ROW_BONUS],

					player_data[id][PLAYER_NAME],
					player_data[id][PLAYER_STEAMID],
					player_data[id][PLAYER_IP],

					player_data[id][PLAYER_EXP],
					player_data[id][PLAYER_BONUS]
			);

			player_data[id][PLAYER_LOADSTATE] = (reload) ? LOAD_UPDATE : LOAD_NEWWAIT;
		}
	}

	if(query[0])
	{
		switch(sql_data[0])
		{
			// накапливаем запросы
			case SQL_UPDATE:
			{
				// запросов достаточно, сбрасываем их
				DB_AddQuery(query,len);
				return true;
			}
		}

		SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data);
	}

	return true;
}

DB_AddQuery(query[],len)
{
	if((flush_que_len + len + 1) > charsmax(flush_que))
		DB_FlushQuery();

	flush_que_len += formatex(
		flush_que[flush_que_len],
		charsmax(flush_que) - flush_que_len,
		"%s%s",flush_que_len ? ";" : "",
		query
	);

	// задание на сброс накопленных запросов
	remove_task(task_flush);
	set_task(0.1,"DB_FlushQuery",task_flush);
}

//
// Сброс накопленных запросов
//
public DB_FlushQuery()
{
	if(sql == Empty_Handle || gg_sql)
		return false;

	if(flush_que_len)
	{
		new sql_data[1] = SQL_UPDATE;
		SQL_ThreadQuery(sql,"SQL_Handler",flush_que,sql_data,sizeof sql_data);

		flush_que_len = 0;
	}

	return true;
}

//
// Хандлер SQL ответа
//
public SQL_Handler(failstate,Handle:sqlQue,err[],errNum,data[],dataSize)
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("SQL connection failed");
			log_amx("[ %d ] %s",errNum,err);

			cnt_sqlfail++;

			if(cnt_sqlfail >= get_pcvar_num(cvar[CVAR_SQL_MAXFAIL]) && !gg_sql)
			{
				log_amx("db query is disabled for this map");
				gg_sql = true;
			}

			return PLUGIN_HANDLED;
		}
		case TQUERY_QUERY_FAILED:
		{
			new lastQue[QUERY_LENGTH];
			SQL_GetQueryString(sqlQue,lastQue,charsmax(lastQue)); // узнаем запрос

			log_amx("SQL query failed");
			log_amx("[ %d ] %s",errNum,err);
			log_amx("[ SQL ] [%s]",lastQue);

			cnt_sqlfail++;

			if(cnt_sqlfail >= get_pcvar_num(cvar[CVAR_SQL_MAXFAIL]) && !gg_sql)
			{
				log_amx("db query is disabled for this map");
				gg_sql = true;
			}

			return PLUGIN_HANDLED;
		}
	}

	switch(data[0])
	{
		case SQL_LOAD: // загрзука статистики игрока
		{
			new id = data[1];

			if(!is_user_connected(id))
				return PLUGIN_HANDLED;

			if(SQL_NumResults(sqlQue)) // считываем статистику
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_OK;
				player_data[id][PLAYER_ID] = SQL_ReadResult(sqlQue,ROW_ID);

				new Float:exp;

				SQL_ReadResult(sqlQue,ROW_EXP,exp);
				Player_SetExp(id,exp,true,true);

				player_data[id][PLAYER_EXPLAST] = _:player_data[id][PLAYER_EXP];
				player_data[id][PLAYER_BONUS] = player_data[id][PLAYER_BONUSLAST] = SQL_ReadResult(sqlQue,ROW_BONUS);

				ExecuteForward(FW_PlConnect,dummy,id);
			}
			else // помечаем как нового игрока
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_NEW;

				DB_SavePlayerData(id); // добавляем запись в базу данных
			}
		}
		case SQL_INSERT:	// запись новых данных
		{
			new id = data[1];

			if(is_user_connected(id))
			{
				if(player_data[id][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[id][PLAYER_LOADSTATE] = LOAD_NO;
					DB_LoadPlayerData(id);

					return PLUGIN_HANDLED;
				}

				player_data[id][PLAYER_ID] = SQL_GetInsertId(sqlQue);	// первичный ключ
				player_data[id][PLAYER_LOADSTATE] = LOAD_OK;	// данные загружены

				Player_SetExp(id,player_data[id][PLAYER_EXP],true,true);

				player_data[id][PLAYER_EXPLAST] = _:player_data[id][PLAYER_EXP];
				player_data[id][PLAYER_BONUS] = player_data[id][PLAYER_BONUSLAST] = 0;

				ExecuteForward(FW_PlConnect,dummy,id);

				// я упрлся 0)0)0
			}
		}
		case SQL_UPDATE: // обновление данных
		{
			new players[MAX_PLAYERS],pnum;
			get_players(players,pnum);

			for(new i,player ; i < pnum ; i++)
			{
				player = players[i];

				if(player_data[player][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[player][PLAYER_LOADSTATE] = LOAD_NO;
					DB_LoadPlayerData(player);
				}
			}
		}
		case SQL_IMPORT:
		{
			log_amx("imported ^"%s^" with new id ^"%d^"",data[1],SQL_GetInsertId(sqlQue));
		}
		case SQL_IMPORTFINISH:
		{
			log_amx("import finished. %d entries imported.",SQL_ReadResult(sqlQue,0));

			new players[MAX_PLAYERS],pnum;
			get_players(players,pnum);

			for(new i ; i < pnum ; i++)
			{
				DB_LoadPlayerData(players[i]);
			}
		}
		case SQL_GETSTATS: // aes_find_stats
		{
			new id = data[1];
			new Array:aes_stats_array = ArrayCreate(aes_stats_struct);
			new aes_stats[aes_stats_struct];

			while(SQL_MoreResults(sqlQue))
			{
				SQL_ReadResult(sqlQue,ROW_NAME,aes_stats[AES_S_NAME],charsmax(aes_stats[AES_S_NAME]));
				SQL_ReadResult(sqlQue,ROW_STEAMID,aes_stats[AES_S_STEAMID],charsmax(aes_stats[AES_S_STEAMID]));
				SQL_ReadResult(sqlQue,ROW_IP,aes_stats[AES_S_IP],charsmax(aes_stats[AES_S_IP]));

				SQL_ReadResult(sqlQue,ROW_EXP,aes_stats[AES_S_EXP]);
				aes_stats[AES_S_LEVEL] = Level_GetByExp(aes_stats[AES_S_EXP]);
				aes_stats[AES_S_ID] = SQL_ReadResult(sqlQue,ROW_ID);

				ArrayPushArray(aes_stats_array,aes_stats);

				SQL_NextRow(sqlQue);
			}


			// передаваемые данные
			new stats_size = dataSize - 4; // почему 4? потому что не 3
			new stats_data[32];

			for(new i ; i < stats_size ; i++)
			{
				stats_data[i] = data[4 + i];
			}

			// callback
			if(callfunc_begin_i(data[3],data[2]))
			{
				callfunc_push_int(id);
				callfunc_push_int(_:aes_stats_array);
				callfunc_push_array(stats_data,stats_size);

				callfunc_end();
			}
		}
	}

	return PLUGIN_HANDLED;
}

//
// API
//

#define CHECK_PLAYER(%1) \
if (!(0 < %1 <= MaxClients)) \
{ \
	log_error(AMX_ERR_NATIVE, "player out of range (%d)", %1); \
	return 0; \
}

public plugin_natives()
{
	register_library("aes");

	register_native("aes_set_player_exp","_aes_set_player_exp",true);
	register_native("aes_get_player_exp","_aes_get_player_exp",true);
	register_native("aes_get_player_reqexp","_aes_get_player_reqexp",true);
	register_native("aes_set_player_bonus","_aes_set_player_bonus",true);
	register_native("aes_get_player_bonus","_aes_get_player_bonus",true);
	register_native("aes_set_player_level","_aes_set_player_level",true);
	register_native("aes_get_player_level","_aes_get_player_level",true);
	register_native("aes_get_max_level","_aes_get_max_level",true);
	register_native("aes_get_level_name","_aes_get_level_name");
	register_native("aes_get_exp_level","_aes_get_exp_level",true);
	register_native("aes_get_level_reqexp","_aes_get_level_reqexp",true);
	register_native("aes_find_stats_thread","_aes_find_stats_thread");

	// 0.4 DEPRECATED
	register_library("aes_main");
	register_native("aes_add_player_exp","_aes_add_player_exp",true);
	register_native("aes_add_player_bonus","_aes_add_player_bonus",true);
	register_native("aes_get_stats","_aes_get_stats");
	register_native("aes_get_player_stats","_aes_get_player_stats");
	register_native("aes_set_player_stats","_aes_set_player_stats");
	register_native("aes_set_level_exp","_aes_set_level_exp");
	register_native("aes_get_level_name","_aes_get_level_name");
	register_native("aes_get_level_for_exp","_aes_get_level_for_exp",true);
	register_native("aes_get_exp_to_next_level","_aes_get_exp_to_next_level",true);
}

public _aes_find_stats_thread(plugin_id,params)
{
	if(sql == Empty_Handle || gg_sql)
		return false;

	new callback_func[32],func_id;
	new id = get_param(1);
	new Array:track_ids = Array:get_param(2);
	get_string(3,callback_func,charsmax(callback_func));
	func_id = get_func_id(callback_func,plugin_id);

	// неверно указана функция на callback
	if(func_id == INVALID_PLUGIN_ID)
	{
		log_error(AMX_ERR_NATIVE,"invalid callback function ^"%s^"",callback_func);
		return false;
	}

	new stats_data[32],stats_size;

	// передаваемые данные
	if(params == 5)
	{
		stats_size = get_param(5);

		// лул
		if(stats_size > sizeof stats_data)
		{
			log_error(AMX_ERR_NATIVE,"maximum data size is %d",sizeof stats_data);
			return false;
		}

		get_array(4,stats_data,stats_size);
	}



	new length = ArraySize(track_ids);

	// не обрабатываем пустой массив
	if(!length)
	{
		log_error(AMX_ERR_NATIVE,"passed empty track_ids array");
		return false;
	}

	// строим запрос
	new query[QUERY_LENGTH],len;

	len += formatex(query,charsmax(query) - len,"SELECT * FROM `%s` WHERE ",
		tbl_name
	);

	switch(get_pcvar_num(cvar[CVAR_RANK]))
	{
		case 0: len += formatex(query[len],charsmax(query)-len,"`%s` IN(",row_names[ROW_NAME]); // статистика по нику
		case 1: len += formatex(query[len],charsmax(query)-len,"`%s` IN(",row_names[ROW_STEAMID]); // статистика по steamid
		case 2: len += formatex(query[len],charsmax(query)-len,"`%s` IN(",row_names[ROW_IP]); // статистика по ip
		default:
		{
			log_error(AMX_ERR_NATIVE,"lol retard admin");
			return false;
		}
	}

	for(new i,id_str[MAX_NAME_LENGTH * 3] ; i < length ; i++)
	{
		ArrayGetString(track_ids,i,id_str,charsmax(id_str));
		mysql_escape_string(id_str,charsmax(id_str));
		len += formatex(query[len],charsmax(query)-len,"%s'%s'",i == 0 ? "" : ",",id_str);
	}

	len += formatex(query[len],charsmax(query)-len,")");


	new sql_data[4 + sizeof stats_data];

	sql_data[0] = SQL_GETSTATS;
	sql_data[1] = id;
	sql_data[2] = plugin_id;
	sql_data[3] = func_id;

	// добавляем передаваемые данные
	if(stats_size)
	{
		for(new i ; i < stats_size ; i++)
		{
			sql_data[4 + i] = stats_data[i];
		}
	}

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,4 + stats_size);

	return true;
}

public _aes_set_player_exp(id,Float:exp,bool:no_forward,bool:force)
{
	CHECK_PLAYER(id)

	if(is_by_stats)
	{
		player_data[id][PLAYER_LOADSTATE] = LOAD_OK;
	}

	return Player_SetExp(id,exp,no_forward,force);
}

public _aes_get_player_exp(id)
{
	CHECK_PLAYER(id)

	if(player_data[id][PLAYER_LOADSTATE] != LOAD_OK)
	{
		return _:-1.0;
	}

	return _:player_data[id][PLAYER_EXP];
}

public _aes_get_player_reqexp(id)
{
	CHECK_PLAYER(id)
	return _:player_data[id][PLAYER_EXP_TO_NEXT];
}

public _aes_set_player_bonus(id,bonus,bool:force)
{
	CHECK_PLAYER(id)
	return Player_SetBonus(id,bonus,force);
}

public _aes_get_player_bonus(id)
{
	CHECK_PLAYER(id)
	return player_data[id][PLAYER_BONUS];
}

public _aes_set_player_level(id,level,bool:force)
{
	CHECK_PLAYER(id)
	return Player_SetLevel(id,level,force);
}

public _aes_get_player_level(id)
{
	CHECK_PLAYER(id)
	return player_data[id][PLAYER_LEVEL];
}

public _aes_get_max_level()
	return levels_count;

public _aes_get_level_name(plugin,params)
{
	new level = get_param(1);
	new len = get_param(3);
	new idLang = get_param(4);

	if(level > levels_count)
		level = levels_count - 1;

	new LangKey[10],levelName[AES_MAX_LEVEL_LENGTH];

	formatex(LangKey,charsmax(LangKey),"LVL_%d",level + 1);
	len = formatex(levelName,len,"%L",idLang,LangKey);

	set_string(2,levelName,len);

	return len;
}

public _aes_get_exp_level(Float:exp)
	return Level_GetByExp(exp);

public Float:_aes_get_level_reqexp(level)
	return Level_GetExpToNext(level);

//
// ОБРАТНАЯ СОВМЕСТИМОСТЬ С 0.4
//
public _aes_get_stats()
	return false;

public _aes_add_player_exp(id,exp)
{
	CHECK_PLAYER(id)

	if(!exp)
		return 0;

	return Player_SetExp(id,player_data[id][PLAYER_EXP] + float(exp));
}

public _aes_add_player_bonus(id,bonus)
{
	CHECK_PLAYER(id)

	if(!bonus)
		return 0;

	return Player_SetBonus(id,player_data[id][PLAYER_BONUS] +bonus);
}

public _aes_get_player_stats(plugin,params)
{
	new id = get_param(1);

	CHECK_PLAYER(id)

	if(player_data[id][PLAYER_LOADSTATE] == LOAD_NO)
		return 0;

	new ret[4];

	ret[0] = floatround(player_data[id][PLAYER_EXP]);
	ret[1] = player_data[id][PLAYER_LEVEL];
	ret[2] = player_data[id][PLAYER_BONUS];
	ret[3] = floatround(player_data[id][PLAYER_EXP_TO_NEXT]);

	set_array(2,ret,sizeof ret);

	return 1;
}

public _aes_set_player_stats(plugin,params)
{
	if(params < 2)
	{
		log_error(AMX_ERR_NATIVE,"bad arguments num, expected 2, passed %d", params);
		return 0;
	}

	new id = get_param(1);

	CHECK_PLAYER(id)

	new st[3];
	get_array(2,st,3);

	if(st[0] > -1)
		Player_SetExp(id,float(st[0]),true,true);

	if(st[1] > -1)
		Player_SetLevel(id,st[1]);

	if(st[2] > -1)
		Player_SetBonus(id,st[2]);

	return 1;
}

// что это за херня D:
public _aes_set_level_exp()
	return false;

public _aes_get_level_for_exp(exp)
	return Level_GetByExp(float(exp));

public _aes_get_exp_to_next_level(lvl)
	return floatround(Level_GetExpToNext(lvl));

/*********    mysql escape functions     ************/
mysql_escape_string(dest[],len)
{
	//copy(dest, len, source);
	replace_all(dest,len,"\\","\\\\");
	replace_all(dest,len,"\0","\\0");
	replace_all(dest,len,"\n","\\n");
	replace_all(dest,len,"\r","\\r");
	replace_all(dest,len,"\x1a","\Z");
	replace_all(dest,len,"'","''");
	replace_all(dest,len,"^"","^"^"");
}
