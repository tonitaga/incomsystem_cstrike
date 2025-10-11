#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem Glock18 Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const GlockModels[][] =
{
	"models/v_glock18.mdl",
	"models/incom/glock/v_glock18_fade.mdl",
	"models/incom/glock/v_glock18_water_elemental.mdl"
};

new const GlockModelNames[][] =
{
    "Glock18 [DEFAULT]",
	"Glock18 Fade",
	"Glock18 Water Elemental"
};

new GlocksStorage[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /skins-glock","MenuGloak");
	register_event("CurWeapon", "ChangeCurrentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof GlockModels; i++) 
	{
		precache_model(GlockModels[i]);
	}
}

public MenuGloak(id)
{
	new menu = menu_create("\y>>>>> \rGlock18 skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "GlockCase")
	
	menu_additem(menu, "Glock \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wGlock \yFade", "2", 0)
	menu_additem(menu, "\wGlock \yWater Elemental", "3", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public GlockCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}

	new nick[33]; get_user_name(id, nick, 32);

	GlocksStorage[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your Glock18", nick, GlockModelNames[item]);
	
	menu_destroy(menu);
	return 1;
}

public ChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_GLOCK18) 
	{
		set_pev(id, pev_viewmodel2, GlockModels[GlocksStorage[id]]);
	}
}