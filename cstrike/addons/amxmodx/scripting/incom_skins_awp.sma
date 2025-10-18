#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[]       = "Incomsystem AWP Menu";
new const VERSION[]      = "2.0";
new const AUTHOR[]       = "Tonitaga"
new const SKIN_COMMAND[] = "say /skins-awp";

new const Models_V[][] =
{
	"models/v_awp.mdl",
	"models/incom/awp/dragon_lore/v_awp.mdl",
	"models/incom/awp/fever_dream/v_awp.mdl",
	"models/incom/awp/hyper_beast/v_awp.mdl",
	"models/incom/awp/lightning_strike/v_awp.mdl",
	"models/incom/awp/oni_taiji/v_awp.mdl",
};

new const Models_P[][] =
{
	"models/p_awp.mdl",
	"models/incom/awp/dragon_lore/p_awp.mdl",
	"models/incom/awp/fever_dream/p_awp.mdl",
	"models/incom/awp/hyper_beast/p_awp.mdl",
	"models/incom/awp/lightning_strike/p_awp.mdl",
	"models/incom/awp/oni_taiji/p_awp.mdl",
};

new const ModelNames[][] =
{
    "AWP [DEFAULT]",
	"AWP Dragon	Lore",
	"AWP Fever Dream",
	"AWP Hyper Beast",
	"AWP Lightning Strike",
	"AWP Oni Taiji",
};

new SkinStorage[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd(SKIN_COMMAND,"IncomMenu");
	register_event("CurWeapon", "IncomChangeCurrentWeapon", "be", "1=1");
}

public client_putinserver(id)
{
	SkinStorage[id] = 1; // "AWP Dragon	Lore"
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
	new menu = menu_create("\y>>>>> \rAWP skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "IncomCase")
	
	menu_additem(menu, "AWP \r[DEFAULT]^n",        "1", 0)
	menu_additem(menu, "\yAWP \wDragon Lore",     "2", 0)
	menu_additem(menu, "\yAWP \wFever Dream",      "3", 0)
	menu_additem(menu, "\yAWP \wHyper Beast",      "4", 0)
	menu_additem(menu, "\yAWP \wLightning Strike", "5", 0)
	menu_additem(menu, "\yAWP \wOni Taiji",        "6", 0)

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
	if(get_user_weapon(id) == CSW_AWP) 
	{
		set_pev(id, pev_viewmodel2,   Models_V[SkinStorage[id]]);
		set_pev(id, pev_weaponmodel2, Models_P[SkinStorage[id]]);
	}
}
