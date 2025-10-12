#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[]       = "Incomsystem M4A1 Menu";
new const VERSION[]      = "2.0";
new const AUTHOR[]       = "Tonitaga"
new const SKIN_COMMAND[] = "say /skins-m4a1";

new const Models_V[][] =
{
	"models/v_m4a1.mdl",
	"models/incom/m4a1/desolate_space/v_m4a1.mdl",
	"models/incom/m4a1/asiimov/v_m4a1.mdl",
	"models/incom/m4a1/chanticos_fire/v_m4a1.mdl",
	"models/incom/m4a1/dragon_king/v_m4a1.mdl",
	"models/incom/m4a1/golden_coil/v_m4a1.mdl",
	"models/incom/m4a1/hyper_beast/v_m4a1.mdl",
};

new const Models_P[][] =
{
	"models/p_m4a1.mdl",
	"models/incom/m4a1/desolate_space/p_m4a1.mdl",
	"models/incom/m4a1/asiimov/p_m4a1.mdl",
	"models/incom/m4a1/chanticos_fire/p_m4a1.mdl",
	"models/incom/m4a1/dragon_king/p_m4a1.mdl",
	"models/incom/m4a1/golden_coil/p_m4a1.mdl",
	"models/incom/m4a1/hyper_beast/p_m4a1.mdl",
};

new const ModelNames[][] =
{
    "M4A1 [DEFAULT]",
    "M4A1 Desolate Space",
	"M4A1 Asiimov",
	"M4A1 Chanticos Fire",
	"M4A1 Dragon King",
	"M4A1 Golden Coil",
	"M4A1 Hyper Beast",
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
	new menu = menu_create("\y>>>>> \rM4A1 skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "IncomCase")
	
	menu_additem(menu, "M4A1 \r[DEFAULT]^n",      "1", 0)
	menu_additem(menu, "\yM4A1 \wDesolate Space", "2", 0)
	menu_additem(menu, "\yM4A1 \wAsiimov",        "3", 0)
	menu_additem(menu, "\yM4A1 \wChanticos Fire", "4", 0)
	menu_additem(menu, "\yM4A1 \wDragon King",    "5", 0)
	menu_additem(menu, "\yM4A1 \wGolden Coil",    "6", 0)
	menu_additem(menu, "\yM4A1 \wHyper Beast",    "7", 0)

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
	if(get_user_weapon(id) == CSW_M4A1) 
	{
		set_pev(id, pev_viewmodel2,   Models_V[SkinStorage[id]]);
		set_pev(id, pev_weaponmodel2, Models_P[SkinStorage[id]]);
	}
}
