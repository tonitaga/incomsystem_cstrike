#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[]       = "Incomsystem Glock Menu";
new const VERSION[]      = "2.0";
new const AUTHOR[]       = "Tonitaga"
new const SKIN_COMMAND[] = "say /skins-glock";

new const Models_V[][] =
{
	"models/v_glock18.mdl",
	"models/incom/glock/fade/v_glock18.mdl",
	"models/incom/glock/cubes_world/v_glock18.mdl"
};

new const Models_P[][] =
{
	"models/p_glock18.mdl",
	"models/incom/glock/fade/p_glock18.mdl",
	"models/incom/glock/cubes_world/p_glock18.mdl"
};

new const ModelNames[][] =
{
    "Glock [DEFAULT]",
	"Glock Fade",
	"Glock Cubes World"
};

new SkinStorage[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd(SKIN_COMMAND,"IncomMenu");
	register_event("CurWeapon", "IncomChangeCurrentWeapon", "be", "1=1");
}

public plugin_precache() 
{
	for(new i; i < sizeof Models_V; i++) 
	{
		precache_model(Models_V[i]);
	}

	for(new i; i < sizeof Models_P; i++) 
	{
		precache_model(Models_P[i]);
	}
}

public IncomMenu(id)
{
	new menu = menu_create("\y>>>>> \rGlock skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "IncomCase")
	
	menu_additem(menu, "Glock \r[DEFAULT]^n",   "1", 0)
	menu_additem(menu, "\yGlock \wFade",        "2", 0)
	menu_additem(menu, "\yGlock \wCubes World", "3", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	
	return 1;
}

public IncomCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}

	new nick[33];
	get_user_name(id, nick, 32);

	SkinStorage[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s&x01", nick, ModelNames[item]);
	
	menu_destroy(menu);
	return 1;
}

public IncomChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_GLOCK18) 
	{
		set_pev(id, pev_viewmodel2,   Models_V[SkinStorage[id]]);
		set_pev(id, pev_weaponmodel2, Models_P[SkinStorage[id]]);
	}
}
