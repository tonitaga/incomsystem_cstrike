#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem AWP Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const AWPModels[][] =
{
	"models/v_awp.mdl",
	"models/incom/awp/v_awp_fever_dream.mdl",
	"models/incom/awp/v_awp_d_cyan.mdl",
	"models/incom/awp/v_awp_tiger.mdl",
	"models/incom/awp/v_awp_dragon_lore.mdl"
};

new const AWPMenuNames[][] =
{
    "Awp [DEFAULT]",
    "Awp Fever Dream",
    "Awp D'Cyan",
    "Awp Tiger",
    "Awp Dragon Lore"
};

new AWP[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /skins-awp","AwpMenu");
	register_event("CurWeapon", "ChangeCurrentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof AWPModels; i++) 
	{
		precache_model(AWPModels[i]);
	}
}

public MenuAwp(id)
{
	new menu = menu_create("\y>>>>> \rAWP skin selection menu \y<<<<<^n \dby >>\Tonitaga\d<<", "AwpCase")
	
	menu_additem(menu, "Awp \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wAwp \yFever Dream", "2", 0)
	menu_additem(menu, "\wAwp \yD'Cyan", "3", 0)
	menu_additem(menu, "\wAwp \yTiger", "4", 0)
	menu_additem(menu, "\wAwp \yDragon Lore", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public AwpCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}
	new nick[33]; get_user_name(id, nick, 32);
	
	AWP[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your Awp", nick, AWPMenuNames[item]);
	
	menu_destroy (menu);
	return 1;
}

public ChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_AWP) 
	{
		set_pev(id, pev_viewmodel2, AWPModels[AWP[id]]);
	}
}

public AwpMenu(id)
{
	MenuAwp(id);
}
