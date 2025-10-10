#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem M4A1 Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const M4Models[][] =
{
	"models/v_m4a1.mdl",
	"models/incom/m4a1/v_m4a1_d_cyan.mdl",
	"models/incom/m4a1/v_m4a1_golden_r.mdl",
	"models/incom/m4a1/v_m4a1_hyper_beast.mdl",
	"models/incom/m4a1/v_m4a1_howl.mdl"
};

new const M4MenuNames[][] =
{
    "M4a1 [DEFAULT]",
    "M4a1 D'Cyan",
    "M4a1 Golden'R",
    "M4a1 Hyper Beast",
    "M4a1 Howl"
};

new M4[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /m4","M4Menu");
	register_event("CurWeapon", "CurentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof M4Models; i++) 
	{
		precache_model(M4Models[i]);
	}
}

public MenuM4(id)
{
	new menu = menu_create("\y>>>>> \rM4a1 Menu \y<<<<<^n \dby >>\rTonitaga\d<<", "M4Case")
	
	menu_additem(menu, "M4a1 \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wM4a1 \yD'Cyan", "2", 0)
	menu_additem(menu, "\wM4a1 \yGolden'R", "3", 0)
	menu_additem(menu, "\wM4a1 \yHyper Beast", "4", 0)
	menu_additem(menu, "\wM4a1 \yHowl", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public M4Case(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}
	new nick[33]; get_user_name(id, nick, 32);
	M4[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your M4a1", nick, M4MenuNames[item]);
	
	menu_destroy (menu);
	return 1;
}

public CurentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_M4A1) 
	{
		set_pev(id, pev_viewmodel2, M4Models[M4[id]]);
	}
}

public M4Menu(id)
{
	if(is_user_alive(id))
	{
		MenuM4(id);
	}else{
		MenuM4(id);
	}
}
