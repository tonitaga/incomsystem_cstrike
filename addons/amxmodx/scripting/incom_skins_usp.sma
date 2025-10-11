#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem USP Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const USPModels[][] =
{
	"models/v_usp.mdl",
    "models/incom/usp/v_usp_cyrex.mdl",
    "models/incom/usp/v_usp_kill_confirmed.mdl",
    "models/incom/usp/v_usp_neo_noir.mdl",
    "models/incom/usp/v_usp_hyper_beast_cs2.mdl"
};

new const USPModelNames[][] =
{
    "USP [DEFAULT]",
    "USP Cyrex",
    "USP Kill Confirmed",
    "USP Neo Noir",
    "USP Hyper Beast (CS2 Model)"
};

new USPsStorage[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /skins-usp","MenuUSP");
	register_event("CurWeapon", "ChangeCurrentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof USPModels; i++) 
	{
		precache_model(USPModels[i]);
	}
}

public MenuUSP(id)
{
	new menu = menu_create("\y>>>>> \rUSP skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "USPCase")
	
	menu_additem(menu, "USP \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wUSP \yCyrex", "2", 0)
	menu_additem(menu, "\wUSP \yKill Confirmed", "2", 0)
	menu_additem(menu, "\wUSP \yNeo Noir", "2", 0)
	menu_additem(menu, "\wUSP \yHyper Beast (CS2 Model)", "2", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public USPCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}

	new nick[33]; get_user_name(id, nick, 32);

	USPsStorage[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your USP", nick, USPModelNames[item]);
	
	menu_destroy(menu);
	return 1;
}

public ChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_USP) 
	{
		set_pev(id, pev_viewmodel2, USPModels[USPsStorage[id]]);
	}
}
