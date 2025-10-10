#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem Knife Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const KNFModels[][] =
{
	"models/v_knife.mdl",
	"models/incom/knife/v_knife_bayonet_lore.mdl",
	"models/incom/knife/v_knife_bufferfly_doppler.mdl",
	"models/incom/knife/v_knife_butterfly_lore.mdl",
	"models/incom/knife/v_knife_kerambit_gradient.mdl"
};

new const KNFMenuNames[][] =
{
    "Knife [DEFAULT]",
    "Knife Bayonet Lore",
    "Knife Butterfly Doppler",
    "Knife Butterfly Lore",
    "Knife Kerambit Gradient"
};

new KNF[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /knife","KnfMenu");
	register_event("CurWeapon", "CurentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof KNFModels; i++) 
	{
		precache_model(KNFModels[i]);
	}
}

public MenuKnf(id)
{
	new menu = menu_create("\y>>>>> \rKnife Menu \y<<<<<^n \dby >>\rTonitaga\d<<", "KnfCase")
	
	menu_additem(menu, "Knife \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wKnife \yBayonet Lore", "2", 0)
	menu_additem(menu, "\wKnife \yButterfly Doppler", "3", 0)
	menu_additem(menu, "\wKnife \yButterfly Lore", "4", 0)
	menu_additem(menu, "\wKnife \yKerambit Gradient", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public KnfCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}
	new nick[33]; get_user_name(id, nick, 32);
	KNF[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your Knife", nick, KNFMenuNames[item]);
	
	menu_destroy (menu);
	return 1;
}

public CurentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		set_pev(id, pev_viewmodel2, KNFModels[KNF[id]]);
	}
}

public KnfMenu(id)
{
	if(is_user_alive(id))
	{
		MenuKnf(id);
	}else{
		MenuKnf(id);
	}
}
