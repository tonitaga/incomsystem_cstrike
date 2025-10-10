#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem Deagle Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const DGLModels[][] =
{
	"models/v_deagle.mdl",
	"models/incom/deagle/v_deagle_red.mdl",
	"models/incom/deagle/v_deagle_emperor_dragon.mdl",
	"models/incom/deagle/v_deagle_hypnotic.mdl",
	"models/incom/deagle/v_deagle_blaze.mdl"
};

new const DGLMenuNames[][] =
{
    "Deagle [DEFAULT]",
    "Deagle Red",
    "Deagle Emperor Dragon",
    "Deagle Hypnotic",
    "Deagle Blaze"
};

new DGL[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /dgl","DglMenu");
	register_event("CurWeapon", "CurentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof DGLModels; i++) 
	{
		precache_model(DGLModels[i]);
	}
}

public MenuDgl(id)
{
	new menu = menu_create("\y>>>>> \rDeagle Menu \y<<<<<^n \dby >>\rTonitaga\d<<", "DglCase")
	
	menu_additem(menu, "Deagle \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wDeagle \yRed", "2", 0)
	menu_additem(menu, "\wDeagle \yEmperor Dragon", "3", 0)
	menu_additem(menu, "\wDeagle \yHypnotic", "4", 0)
	menu_additem(menu, "\wDeagle \yBlaze", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public DglCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}
	new nick[33]; get_user_name(id, nick, 32);
	DGL[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your Deagle", nick, DGLMenuNames[item]);
	
	menu_destroy (menu);
	return 1;
}

public CurentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_DEAGLE) 
	{
		set_pev(id, pev_viewmodel2, DGLModels[DGL[id]]);
	}
}

public DglMenu(id)
{
	if(is_user_alive(id))
	{
		MenuDgl(id);
	}else{
		MenuDgl(id);
	}
}
