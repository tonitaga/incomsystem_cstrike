#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[]       = "Incomsystem Deagle Menu";
new const VERSION[]      = "2.0";
new const AUTHOR[]       = "Tonitaga"
new const SKIN_COMMAND[] = "say /skins-deagle";

new const Models_V[][] =
{
	"models/v_deagle.mdl",
	"models/incom/deagle/blaze/v_deagle.mdl",
	"models/incom/deagle/bloodsport/v_deagle.mdl"
};

new const Models_P[][] =
{
	"models/p_deagle.mdl",
	"models/incom/deagle/blaze/p_deagle.mdl",
	"models/incom/deagle/bloodsport/p_deagle.mdl"
};

new const ModelNames[][] =
{
    "Deagle [DEFAULT]",
	"Deagle Blaze",
	"Deagle Bloodsport",
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
	new menu = menu_create("\y>>>>> \rDeagle skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "IncomCase")
	
	menu_additem(menu, "Deagle \r[DEFAULT]^n",  "1", 0)
	menu_additem(menu, "\yDeagle \wBlaze",      "2", 0)
	menu_additem(menu, "\yDeagle \wBloodsport", "3", 0)

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
	if(get_user_weapon(id) == CSW_DEAGLE) 
	{
		set_pev(id, pev_viewmodel2,   Models_V[SkinStorage[id]]);
		set_pev(id, pev_weaponmodel2, Models_P[SkinStorage[id]]);
	}
}
