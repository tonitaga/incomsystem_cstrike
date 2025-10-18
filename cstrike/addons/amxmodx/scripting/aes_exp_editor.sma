/*
*	AES: Admin Tools		     v. 0.5
*	by serfreeman1337	    http://1337.uz/
*/

/*
	TODO:
		Поддержка show_activity
*/

#include <amxmodx>
#include <amxmisc>

#include <aes_v>

#define PLUGIN "AES: Admin Tools"
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

enum _:cvars {
	CVAR_EXP_MENU
}

new cvar[cvars];

new Array:g_ExpsVals;

enum _:menuStatus {
	MENU_EDITID,
	MENU_SETMODE,
	MENU_CURRENT
}

enum _:menuCurrent {
	MID_LIST,
	MID_ACT,
	MID_ADD_EXP,
	MID_SET_LEVEL,
	MID_SET_BONUSES
}

enum _:menuSetMode {
	M_ADD_EXP = 1,
	M_SUB_EXP,
	M_SET_EXP,
	M_SET_LEVEL,
	M_SET_BONUSES
}

new g_MenuStatus[33][menuStatus];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("aes_exp_menu","C_Show_Exp_Menu",ADMIN_CVAR,"- open AES experience menu");
	register_concmd("aes_exp_menu_set","C_Set_Exp",ADMIN_CVAR,"<name or #userid> <experience>");
	register_concmd("aes_exp_menu_level","C_Set_Level",ADMIN_CVAR,"<name or #userid> <level>");
	
	cvar[CVAR_EXP_MENU] = register_cvar("aes_exp_menu_value","1 5 10 15 20 50 100");
	
	register_clcmd("caes_exp_menu_set","C_Exp_Set");
	
	register_dictionary("aes_expeditor.txt");
	
}

public C_Show_Exp_Menu(id,level,cid)
{
	if(!cmd_access(id,level,cid,0))
		return PLUGIN_HANDLED;
	
	E_Build_Players_Menu(id);
		
	return PLUGIN_HANDLED;
}

public C_Set_Exp(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;

	new args[128];
	read_args(args,127);
	
	trim(args);
	remove_quotes(args);
	
	new usrId[32],sExpVal[32],Float:expVal;
	strtok(args,usrId,31,sExpVal,31,' ',1);
	
	new player = cmd_target(id,usrId,CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF);
	
	if(!player)
		return PLUGIN_HANDLED;
		
	expVal = floatmax(0.0,floatstr(sExpVal));
		
	if(aes_set_player_exp(player,expVal,.force = true))
	{
		new vicName[32];
		get_user_name(player,vicName,31);
		
		client_print(id,print_console,"%L %L",
			id,"AES_TAG_CON",
			id,"ACT_CON_EXP",
			vicName,Get_ValuevStr(expVal));
			
		A_Chat_Msg(id,player,M_SET_EXP,expVal);
	}
	else
	{
		client_print(id,print_console,"%L %L",
			id,"AE_TAG_CON",
			id,"ACT_WRONG");
	}
		
	return PLUGIN_HANDLED;
}

public C_Set_Level(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;
		
	new args[128];
	read_args(args,127);
	
	trim(args);
	remove_quotes(args);
	
	new usrId[32],expVal,sExpVal[32];
	strtok(args,usrId,31,sExpVal,31,' ',1);
	
	new player = cmd_target(id,usrId,CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF);
	
	if(!player)
		return PLUGIN_HANDLED;
		
	expVal = max(0,str_to_num(sExpVal));
	
	if(aes_set_player_level(player,expVal,.force = true))
	{
		new vicName[32],vicLevel[32];
		get_user_name(player,vicName,31);
		aes_get_level_name(expVal,vicLevel,charsmax(vicLevel),id);
		
		client_print(id,print_console,"%L %L",
			id,"AES_TAG_CON",
			id,"ACT_CON_LEVEL",
			vicName,vicLevel);
			
		A_Chat_Msg(id,player,M_SET_LEVEL,expVal);
	}
	else
	{
		client_print(id,print_console,"%L %L",
			id,"AE_TAG_CON",
			id,"ACT_WRONG");
	}
	
	return PLUGIN_HANDLED;
}

// обработка своего значения опыта или бонусов
public C_Exp_Set(id,level,cid)
{
	// проверяем достууп
	if(!cmd_access(id,level,cid,0) || !g_MenuStatus[id][MENU_SETMODE] || !is_user_connected(g_MenuStatus[id][MENU_EDITID]))
		return PLUGIN_HANDLED;
		
	new sExpVal[20],Float:expVal;
	
	read_args(sExpVal,19);
	trim(sExpVal);
	remove_quotes(sExpVal);
	
	// админ не ввел значение Ничего не делаем.
	if(!strlen(sExpVal))
		return PLUGIN_HANDLED;
	
	expVal = floatstr(sExpVal);
	
	switch(g_MenuStatus[id][MENU_SETMODE])
	{
		case M_ADD_EXP,M_SUB_EXP,M_SET_EXP:
		{
			if(g_MenuStatus[id][MENU_SETMODE] != M_SET_EXP)
			{
				aes_set_player_exp(g_MenuStatus[id][MENU_EDITID],
					g_MenuStatus[id][MENU_SETMODE] == M_ADD_EXP ? 
						floatadd(
							aes_get_player_exp(g_MenuStatus[id][MENU_EDITID]),
							expVal) :
						floatsub(
							aes_get_player_exp(g_MenuStatus[id][MENU_EDITID]),
							expVal),
					.force = true
				);
					
				
				A_Chat_Msg(id,g_MenuStatus[id][MENU_EDITID],g_MenuStatus[id][MENU_SETMODE] == M_SUB_EXP ? M_SUB_EXP : M_ADD_EXP,
					g_MenuStatus[id][MENU_SETMODE] == M_SUB_EXP ? -expVal : expVal);
			}
			else
			{
				aes_set_player_exp(g_MenuStatus[id][MENU_EDITID],expVal,.force = true);
			}
		}
		case M_SET_BONUSES:
		{
			A_Chat_Msg(id,g_MenuStatus[id][MENU_EDITID],M_SET_BONUSES,expVal);
			aes_set_player_bonus(g_MenuStatus[id][MENU_EDITID],floatround(expVal),.force = true);
		}
	}
	
	// показываем меню действий над игроком
	E_Build_Action_Menu(id,g_MenuStatus[id][MENU_EDITID]);
	
	return PLUGIN_HANDLED;
}


public A_Chat_Msg(id,editId,actId,any:valuev)
{
	new admName[32],admAuth[36],editName[32],editAuth[36];
	
	get_user_name(id,admName,31);
	get_user_name(editId,editName,31);

	get_user_authid(id,admAuth,35);
	get_user_authid(editId,editAuth,35);
	
	new const LangAct[][] = {
		"",
		"ACT_ADD_EXP",
		"ACT_SUB_EXP",
		"ACT_ADD_EXP",
		"ACT_SET_LEVEL",
		"ACT_SET_BONUS"
	}
	
	new const LogAct[][] = {
		"",
		"add <s> exp",
		"sub <s> exp",
		"set <s> exp",
		"set level <s> for",
		"set <s> bonuses"
	}
	
	//имена переменных оставлены в знак уважения перед автором)

	new nikolay[32];
		
	if(actId == M_SET_LEVEL)
		aes_get_level_name(valuev,nikolay,charsmax(nikolay),editId);
	else
		formatex(nikolay,charsmax(nikolay),"%s",actId != M_SUB_EXP ? Get_ValuevStr(valuev) : Get_ValuevStr(floatabs(valuev)));
	
	new logMsg[46];

	formatex(logMsg,charsmax(logMsg),"%s",LogAct[actId]);
	replace_all(logMsg,charsmax(logMsg),"<s>",nikolay);
	
	log_amx("^"%s<%d><%s><>^" %s ^"%s<%d><%s><>^"",
		admName,
		get_user_userid(id),
		admAuth,
		logMsg,
		editName,
		get_user_userid(editId),
		editAuth);
	
	client_print_color(editId,print_team_default,"%L %L",
		editId,"AES_TAG",
		editId,LangAct[actId],
		admName,
		nikolay);
	
	/*
	if(id != editId)
	{
		client_print_color(id,print_team_default,"%L %L",
			editId,"AES_TAG",
			id,LangAct[actId],
			nikolay,
			editName)
	}
	*/
}

// список игроков
public E_Build_Players_Menu(id)
{
	arrayset(g_MenuStatus[id],0,menuStatus);
	
	new langStr[96];

	formatex(langStr,charsmax(langStr),"%L %L",id,"AES_TAG_MENU",id,"TITLE");
	
	new m = menu_create(langStr,"E_Menu_Handler");
	
	g_MenuStatus[id][MENU_CURRENT] = MID_LIST;
	
	new players[MAX_PLAYERS],pCount;
	new name[MAX_NAME_LENGTH],lKey[10];
	
	get_players(players,pCount);
	
	for(new i ; i < pCount ; ++i)
	{
		get_user_name(players[i],name,charsmax(name));
		
		formatex(langStr,charsmax(langStr),"%s \y(%s/%s)",
			name,
			Get_ValuevStr(
				aes_get_player_exp(players[i])
			),
			Get_ValuevStr(
				aes_get_level_reqexp(
					aes_get_player_level(players[i])
				)
			)
		);
		
		formatex(lKey,charsmax(lKey),"l%d",players[i]);
		menu_additem(m,langStr,lKey);
	}
	
	F_Format_NavButtons(id,m);
	menu_display(id,m);
}

// меню действий
public E_Build_Action_Menu(id,editId)
{
	if(!is_user_connected(editId))
	{
		E_Build_Players_Menu(id);
				
		return PLUGIN_CONTINUE;
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_ACT;
	
	new langStr[96],actName[32],lKey[10];
	get_user_name(editId,actName,31);
	
	formatex(langStr,charsmax(langStr),"%L %L %s",id,"AES_TAG_MENU",id,"TITLE_ACT",actName);
	
	new m = menu_create(langStr,"E_Menu_Handler");
	
	formatex(langStr,charsmax(langStr),"%L",id,"ADD_EXP");
	formatex(lKey,charsmax(lKey),"e1#%d",editId);
	menu_additem(m,langStr,lKey);
	
	formatex(langStr,charsmax(langStr),"%L",id,"SUB_EXP");
	formatex(lKey,charsmax(lKey),"e2#%d",editId);
	menu_additem(m,langStr,lKey);
	
	formatex(langStr,charsmax(langStr),"%L",id,"SET_EXP");
	formatex(lKey,charsmax(lKey),"e3#%d",editId);
	menu_additem(m,langStr,lKey);
	
	formatex(langStr,charsmax(langStr),"%L",id,"SET_LEVEL");
	formatex(lKey,charsmax(lKey),"e4#%d",editId);
	menu_additem(m,langStr,lKey);
	
	formatex(langStr,charsmax(langStr),"%L",id,"SET_BONUSES");
	formatex(lKey,charsmax(lKey),"e5#%d",editId);
	menu_additem(m,langStr,lKey);
	
	E_Menu_Add_Player_Info(id,editId,m);
	F_Format_NavButtons(id,m);
	
	menu_display(id,m);
	
	return PLUGIN_CONTINUE;
}


// информация о текущем игроке в меню
public E_Menu_Add_Player_Info(id,editId,m)
{
	new langStr[128],actName[MAX_NAME_LENGTH];
	get_user_name(editId,actName,charsmax(actName));
	
	new aLevel[AES_MAX_LEVEL_LENGTH];
	new Float:player_exp = aes_get_player_exp(editId);
	new player_level = aes_get_player_level(editId);
	new player_bonus = aes_get_player_bonus(editId);
	
	aes_get_level_name(player_level,aLevel,charsmax(aLevel),id);
	
	formatex(langStr,charsmax(langStr),"%L",id,"EXP_TEXT",
		actName,
		Get_ValuevStr(player_exp),
		Get_ValuevStr(aes_get_level_reqexp(player_level)),
		player_level + 1,aLevel,
		player_bonus
	);
	
	menu_addtext(m,langStr);
}

// меню добавления или вычитания опыта
public E_Build_Exp_Menu(id,editId,bool:isSub)
{
	// отображаем список игроков, если выбранный игрок отключился
	if(!is_user_connected(editId))
	{
		E_Build_Players_Menu(id);
				
		return PLUGIN_CONTINUE;
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_ADD_EXP;
	g_MenuStatus[id][MENU_EDITID] = editId;
	
	// загружаем массив со значением опыта
	if(g_ExpsVals == Invalid_Array)
		V_Load_Exp_Vals();
		
	new langStr[96],Float:cell,lKey[10];
	
	formatex(langStr,charsmax(langStr),"%L %L",id,"AES_TAG_MENU",id,!isSub ? "ADD_EXP" : "SUB_EXP");
	
	new m = menu_create(langStr,"E_Menu_Handler");
	
	for(new i,length = ArraySize(g_ExpsVals) ; i < length ; ++i)
	{
		cell = ArrayGetCell(g_ExpsVals,i);
		
		formatex(langStr,charsmax(langStr),"%L",id,!isSub ? "ADD_EXP_ITEM" : "SUB_EXP_ITEM",Get_ValuevStr(cell));
		formatex(lKey,charsmax(lKey),"d%d#%s%s",editId,!isSub ? "" : "-" , Get_ValuevStr(cell));
		
		menu_additem(m,langStr,lKey);
	}
	
	formatex(langStr,charsmax(langStr),"%L",id,"EXP_SELF");
	formatex(lKey,charsmax(lKey),"d%d#%sself",editId, !isSub ? "" : "-");
	
	menu_additem(m,langStr,lKey);
	
	// E_Menu_Add_Player_Info(id,editId,m)
	
	F_Format_NavButtons(id,m);
	menu_display(id,m);
		
	return PLUGIN_CONTINUE;
}

public F_Format_NavButtons(id,menu)
{
	new tmpLang[20];
	
	formatex(tmpLang,charsmax(tmpLang),"%L",id,"BACK");
	menu_setprop(menu,MPROP_BACKNAME,tmpLang);
	
	formatex(tmpLang,charsmax(tmpLang),"%L",id,"EXIT");
	menu_setprop(menu,MPROP_EXITNAME,tmpLang);
	
	formatex(tmpLang,charsmax(tmpLang),"%L",id,"MORE");
	menu_setprop(menu,MPROP_NEXTNAME,tmpLang);
}

// меню для задания уровня игроку
public E_Build_Level_Menu(id,editId)
{
	// отображаем список игроков, если выбранный игрок отключился
	if(!is_user_connected(editId))
	{
		E_Build_Players_Menu(id);
				
		return PLUGIN_CONTINUE;
	}
	
	g_MenuStatus[id][MENU_CURRENT] = MID_SET_LEVEL;
	g_MenuStatus[id][MENU_EDITID] = editId;
	
	new langStr[96],lKey[10];
	
	formatex(langStr,charsmax(langStr),"%L %L",id,"AES_TAG_MENU",id,"SET_LEVEL");
	
	new m = menu_create(langStr,"E_Menu_Handler");
	
	new pageCnt = -1,pageLevel;
	new player_level = aes_get_player_level(editId);
	
	for(new i,max_level = aes_get_max_level() ; i < max_level ; ++i)
	{
		// считаем общее кол-во страниц
		if(!(i % 7))
			pageCnt++;
		
		langStr[0] = 0;
		aes_get_level_name(i,langStr,charsmax(langStr),id);
		
		new lvl = i - 1;
		
		if(player_level != i)
			formatex(langStr,charsmax(langStr),"%s \r[\y%s\r]",langStr,Get_ValuevStr(aes_get_level_reqexp(lvl)));
		else
		{
			// запоминаем страницу уровня игрока
			
			pageLevel = pageCnt;
			formatex(langStr,charsmax(langStr),"%s \r[\y%s\r] %L",
				langStr,Get_ValuevStr(aes_get_level_reqexp(lvl)),
				id,"CUR_LEVEL");
		}
		
		formatex(lKey,charsmax(lKey),"s%d#%d",editId,i);
		menu_additem(m,langStr,lKey);
	}
	
	F_Format_NavButtons(id,m);
	menu_display(id,m,pageLevel);
	
	return PLUGIN_CONTINUE;
}

public V_Load_Exp_Vals()
{
	new expString[512],stPos,ePos,rawPoint[20];
	get_pcvar_string(cvar[CVAR_EXP_MENU],expString,511);
	
	g_ExpsVals = ArrayCreate(1);
	
	if(strlen(expString))
	{
		do {
			ePos = strfind(expString[stPos]," ");
			
			formatex(rawPoint,ePos,expString[stPos]);
			ArrayPushCell(g_ExpsVals,floatstr(rawPoint));
			
			stPos += ePos + 1;
		} while (ePos != -1)
	}
}

public E_Menu_Handler(id,m,item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(m);
		
		// открываем последнее меню
		switch(g_MenuStatus[id][MENU_CURRENT])
		{
			case MID_ACT: E_Build_Players_Menu(id);
			case MID_ADD_EXP,MID_SET_LEVEL,MID_SET_BONUSES: E_Build_Action_Menu(id,g_MenuStatus[id][MENU_EDITID]);
		}
		
		return PLUGIN_HANDLED;
	}
	
	new itemData[20];
	new a,n[2];
	
	menu_item_getinfo(m,item,a,itemData,19,n,1,a);
	
	switch(itemData[0])
	{
		case 'l':
		{ // отображаем меню действий над выбраным игроком
			E_Build_Action_Menu(id,str_to_num(itemData[1]));
		}
		case 'e':
		{ // выполняем выбраное действие
			new SeKey[2],SeEditId[3];
			
			// разбераем информацию пункта меню
			strtok(itemData[1],SeKey,1,SeEditId,2,'#');
			
			new eKey = str_to_num(SeKey); // узнаем ID действия
			new editId = str_to_num(SeEditId); // узнаем ID игрока
			
			switch(eKey)
			{
				// меню добавить/отнять опыт
				case 1,2: E_Build_Exp_Menu(id,editId,eKey == 1 ? false : true);
				case 3:
				{ // указываем опыт вручную
					g_MenuStatus[id][MENU_SETMODE] = M_SET_EXP;
					g_MenuStatus[id][MENU_EDITID] = editId;
					
					client_cmd(id,"messagemode caes_exp_menu_set");
				}
				// задаем уровень игроку
				case 4: E_Build_Level_Menu(id,editId);
				// задаем бонусы игроку
				case 5:
				{
					g_MenuStatus[id][MENU_SETMODE] = M_SET_BONUSES;
					g_MenuStatus[id][MENU_EDITID] = editId;
					
					client_cmd(id,"messagemode caes_exp_menu_set");
				}
			}
			
		}
		case 'd':
		{ // добавляем или отнимаем опыт
			new SeEditId[3],SeVal[20];
			
			strtok(itemData[1],SeEditId,2,SeVal,19,'#');
			
			new editId = str_to_num(SeEditId);
			
			// задаем опыт вручную
			if(contain(SeVal,"self") != -1)
			{
				g_MenuStatus[id][MENU_SETMODE] = (SeVal[0] != '-') ? M_ADD_EXP : M_SUB_EXP;
				g_MenuStatus[id][MENU_EDITID] = editId;
				
				client_cmd(id,"messagemode caes_exp_menu_set");
				
				return PLUGIN_HANDLED;
			}
			
			new Float:val = floatstr(SeVal);
			
			aes_set_player_exp(editId,
				floatadd(
					aes_get_player_exp(editId),
					val
				) 
				,.force = true
			);
			
			// показываем меню действий снова
			E_Build_Action_Menu(id,editId);
			A_Chat_Msg(id,editId,SeVal[0] != '-' ? M_ADD_EXP : M_SUB_EXP,val);
		}
		case 's':
		{ // установка уровня
			new SeEditId[3],SeVal[20];
			
			strtok(itemData[1],SeEditId,2,SeVal,19,'#');
			
			new editId = str_to_num(SeEditId);
			aes_set_player_level(editId,str_to_num(SeVal),.force =  true);
			
			E_Build_Level_Menu(id,editId);
			A_Chat_Msg(id,editId,M_SET_LEVEL,aes_get_player_level(editId));
		}
	}
	
	return PLUGIN_HANDLED;
}

Get_ValuevStr(Float:val)
{
	new str[10];
	
	if(floatfract(val))
		formatex(str,charsmax(str),"%.2f",_:val >= 0 ? val + 0.005 : val - 0.005);
	else
		formatex(str,charsmax(str),"%.0f",val);
	
	return str;
}