#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[]       = "Incomsystem Knife Menu";
new const VERSION[]      = "2.0";
new const AUTHOR[]       = "Tonitaga"
new const SKIN_COMMAND[] = "say /skins-knife";

new const Models_V[][] =
{
	"models/v_knife.mdl",

	// Ножи Karambit
	"models/incom/knife/karambit/lore/v_knife.mdl",
	"models/incom/knife/karambit/doppler_emerald/v_knife.mdl",
	"models/incom/knife/karambit/ultraviolet/v_knife.mdl",
	"models/incom/knife/karambit/gradient/v_knife.mdl",

	// Ножи Butterfly
	"models/incom/knife/butterfly/fade/v_knife.mdl",
	"models/incom/knife/butterfly/crimson_web/v_knife.mdl",

	// Ножи Bayonet
	"models/incom/knife/bayonet/lore/v_knife.mdl",
	"models/incom/knife/bayonet/chang_specialist/v_knife.mdl",

	// Ножи Flip
	"models/incom/knife/flip/ultraviolet/v_knife.mdl",

	// Ножи Skeleton
	"models/incom/knife/skeleton/fade/v_knife.mdl",
	"models/incom/knife/skeleton/crimson_web/v_knife.mdl",
	"models/incom/knife/skeleton/case_hardened/v_knife.mdl",
}

new const ModelNames[][] =
{
    "Knife [DEFAULT]",

	// Ножи Karambit
	"Knife Karambit Lore",
	"Knife Karambit Doppler Emerald",
	"Knife Karambit Ultraviolet",
	"Knife Karambit Gradient",

	// Ножи Butterfly
	"Knife Butterfly Fade",
	"Knife Butterfly Crimson Web",

	// Ножи Bayonet
	"Knife Bayonet Lore",
	"Knife Bayonet Chang Specialist",

	// Ножи Flip
	"Knife Flip Ultraviolet",

	// Ножи Skeleton
	"Knife Skeleton Fade",
	"Knife Skeleton Crimson Web",
	"Knife Skeleton Case Hardened"
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
}

public IncomMenu(id)
{
	new menu = menu_create("\y>>>>> \rKnife skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "IncomCase")
	
	menu_additem(menu, "Knife \r[DEFAULT]^n",                "1", 0)

	// Ножи Karambit
	menu_additem(menu, "\yKnife \wKarambit Lore",            "2", 0)
	menu_additem(menu, "\yKnife \wKarambit Doppler Emerald", "3", 0)
	menu_additem(menu, "\yKnife \wKarambit Ultraviolet",     "4", 0)
	menu_additem(menu, "\yKnife \wKarambit Gradient",        "5", 0)

	// Ножи Butterfly
	menu_additem(menu, "\yKnife \wButterfly Fade",        "100", 0)
	menu_additem(menu, "\yKnife \wButterfly Crimson Web", "101", 0)

	// Ножи Bayonet
	menu_additem(menu, "\yKnife \wBayonet Lore",             "200", 0)
	menu_additem(menu, "\yKnife \wBayonet Chang Specialist", "201", 0)

	// Ножи Flip
	menu_additem(menu, "\yKnife \wFlip Ultraviolet", "300", 0)

	// Ножи Skeleton
	menu_additem(menu, "\yKnife \wSkeleton Fade",          "400", 0)
	menu_additem(menu, "\yKnife \wSkeleton Crimson Web",   "401", 0)
	menu_additem(menu, "\yKnife \wSkeleton Case Hardened", "402", 0)

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
	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		set_pev(id, pev_viewmodel2, Models_V[SkinStorage[id]]);
	}
}
