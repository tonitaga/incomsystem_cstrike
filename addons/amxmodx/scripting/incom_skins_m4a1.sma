#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem M4A1 Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const M4Models[][] =
{
	"models/v_m4a1.mdl",
	"models/incom/m4a1/v_m4a1_asiimov.mdl",
	"models/incom/m4a1/v_m4a1_desolate_space.mdl",
	"models/incom/m4a1/v_m4a1_golden_r.mdl",
	"models/incom/m4a1/v_m4a1_howl.mdl",
	"models/incom/m4a1/v_m4a1_hyper_beast.mdl",
	"models/incom/m4a1/v_m4a1_master_piece.mdl"
};

new const M4MenuNames[][] =
{
    "M4a1 [DEFAULT]",
    "M4a1 Asiimov",
    "M4a1 Desolate Space",
	"M4a1 Golden'R",
	"M4a1 Howl",
	"M4a1 Hyper Beast",
	"M4a1 Master Piece"
};

new M4[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /skins-m4a1","M4Menu");
	register_event("CurWeapon", "ChangeCurrentWeapon", "be", "1=1");
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
	new menu = menu_create("\y>>>>> \rM4a1 skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "M4Case")
	
	menu_additem(menu, "M4a1 \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wM4a1 \yAsiimov'R", "2", 0)
	menu_additem(menu, "\wM4a1 \yDesolate Space", "3", 0)
	menu_additem(menu, "\wM4a1 \yGolden'R", "4", 0)
	menu_additem(menu, "\wM4a1 \yHowlHowld", "5", 0)
	menu_additem(menu, "\wM4a1 \yHyper Beast", "6", 0)
	menu_additem(menu, "\wM4a1 \yMaster Piece", "7", 0)

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

public ChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_M4A1) 
	{
		set_pev(id, pev_viewmodel2, M4Models[M4[id]]);
	}
}

public M4Menu(id)
{
	MenuM4(id);
}
