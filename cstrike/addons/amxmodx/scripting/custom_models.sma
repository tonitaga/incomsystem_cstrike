// *************************************************************************************//
// Плагин загружен с  www.neugomon.ru                                                   //
// Автор: Neygomon  [ https://neugomon.ru/members/1/ ]                                  //
// Официальная тема поддержки: https://neugomon.ru/threads/2038/                        //
// При копировании материала ссылка на сайт www.neugomon.ru ОБЯЗАТЕЛЬНА!                //
// *************************************************************************************//

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

enum _:MDL { ACCESS[32], MDL_T[64], MDL_CT[64] }	// ip, steam, flag, #, *. # - steam; * - всем 

#define MAX_MDL 64
new g_iBlockMdl[MAX_MDL];
new g_szModels[MAX_MDL][MDL];

new g_szPlayerModel[33][3][64];

public plugin_precache()
{
	new fp = fopen("addons/amxmodx/configs/custom_models.ini", "rt");
	if(!fp) set_fail_state("File addons/amxmodx/configs/custom_models.ini not found!");
	
	new buff[190], x;
	while(!feof(fp))
	{
		fgets(fp, buff, charsmax(buff)); trim(buff);
		if(!buff[0] || buff[0] == ';')
			continue;
		if(parse(buff, 
			g_szModels[x][ACCESS], charsmax(g_szModels[][ACCESS]), 
			g_szModels[x][MDL_T], charsmax(g_szModels[][MDL_T]), 
			g_szModels[x][MDL_CT], charsmax(g_szModels[][MDL_CT])) == 3
		) x++;
	}
	fclose(fp);
	if(!x) set_fail_state("File addons/amxmodx/configs/custom_models.ini incorrect!");

	for(new i, t, ct, str[64]; i < sizeof g_szModels; i++)
	{
		formatex(str, charsmax(str), "models/player/%s/%s.mdl", g_szModels[i][MDL_T], g_szModels[i][MDL_T]);
		t = file_exists(str);
		if(t) precache_model(str);
		
		formatex(str, charsmax(str), "models/player/%s/%s.mdl", g_szModels[i][MDL_CT], g_szModels[i][MDL_CT]);
		ct = file_exists(str);
		if(ct) precache_model(str);
		
		g_iBlockMdl[i] = (!t && !ct);
	}
}

public plugin_init()
{
	register_plugin("Custom Models", "1.3.2", "neugomon");
	
	RegisterHam(Ham_Spawn, "player", "fwd_HamSpawn_Post", true);
	register_forward(FM_SetClientKeyValue, "fwd_SetClientKeyValue_Pre", false);
}

public client_putinserver(id)
{
	new szIP[16]; 	 get_user_ip(id, szIP, charsmax(szIP), 1);
	new szAuthid[25];get_user_authid(id, szAuthid, charsmax(szAuthid));
	new flags = 	 get_user_flags(id);

	g_szPlayerModel[id][1][0] = EOS;
	g_szPlayerModel[id][2][0] = EOS;
	
	for(new i; i < sizeof g_szModels; i++)
	{
		if(g_iBlockMdl[i] == 1)
			continue;

		switch(g_szModels[i][ACCESS][0])
		{
			case '#':
			{
				if(is_user_steam(id))
				{
					CopyModel(id, i);
					break;
				}	
			}
			case '*':
			{
				CopyModel(id, i);
				break;
			}
			case 'S':
			{
				if(strcmp(g_szModels[i][ACCESS], szAuthid) == 0)
				{
					CopyModel(id, i);
					break;
				}
			}
			default:
			{
				if(isdigit(g_szModels[i][ACCESS][0]))
				{
					if(strcmp(g_szModels[i][ACCESS], szIP) == 0)
					{
						CopyModel(id, i);
						break;
					}
				}
				else if(flags & read_flags(g_szModels[i][ACCESS]))
				{
					CopyModel(id, i);
					break;
				}
			}
		}
	}
}

public fwd_HamSpawn_Post(id)
{
	if(!is_user_alive(id))
		return;
		
	switch(get_pdata_int(id, 114))
	{
		case 1: if(g_szPlayerModel[id][1][0]) fmSetModel(id, g_szPlayerModel[id][1]);
		case 2: if(g_szPlayerModel[id][2][0]) fmSetModel(id, g_szPlayerModel[id][2]);
	}
}

public fwd_SetClientKeyValue_Pre(id, const szInfobuffer[], const szKey[], const szValue[])
{	
	if(strcmp(szKey, "model") != 0)
		return FMRES_IGNORED;
	static iTeam; iTeam = get_pdata_int(id, 114);
	if(iTeam != 1 && iTeam != 2)
		return FMRES_IGNORED;
	if(g_szPlayerModel[id][iTeam][0] && strcmp(szValue, g_szPlayerModel[id][iTeam]) != 0)
	{
		fmSetModel(id, g_szPlayerModel[id][iTeam]);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;	
}

stock CopyModel(index, sId)
{
	copy(g_szPlayerModel[index][1], charsmax(g_szPlayerModel[][]), g_szModels[sId][MDL_T]);
	copy(g_szPlayerModel[index][2], charsmax(g_szPlayerModel[][]), g_szModels[sId][MDL_CT]);
}

stock fmSetModel(id, const model[])
	engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model);
	
bool:is_user_steam(id)
{
	static dp_pointer;
	if(!dp_pointer) dp_pointer = get_cvar_pointer("dp_r_id_provider");
	
	server_cmd("dp_clientinfo %d", id);
	server_exec();
	return (get_pcvar_num(dp_pointer) == 2) ? true : false;
}	