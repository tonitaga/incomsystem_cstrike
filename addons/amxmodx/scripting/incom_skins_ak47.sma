#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem AK47 Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const AKModels[][] =
{
	"models/v_ak47.mdl",
	"models/incom/ak47/v_ak47_wasteland_rebel.mdl",
	"models/incom/ak47/v_ak47_frontside_misty.mdl",
	"models/incom/ak47/v_ak47_furious_pouacock.mdl",
	"models/incom/ak47/v_ak47_vulkan.mdl"
};

new const AKMenuNames[][] =
{
    "Ak47 [DEFAULT]",
    "Ak47 Wasteland Rebel",
    "Ak47 Frontside misty",
    "Ak47 Furious Pouacock",
    "Ak47 Vulkan"
};

new AK[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /ak","AkMenu");
	register_event("CurWeapon", "CurentWeapon", "be", "1=1");
}

public plugin_precache() 
{ 
	for(new i; i < sizeof AKModels; i++) 
	{
		precache_model(AKModels[i]);
	}
}

public MenuAk(id)
{
	new menu = menu_create("\y>>>>> \rAK47 Menu \y<<<<<^n \dby >>\rTonitaga\d<<", "AkCase")
	
	menu_additem(menu, "Ak47 \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wAk47 \yWasteland Rebel", "2", 0)
	menu_additem(menu, "\wAk47 \yFrontside misty", "3", 0)
	menu_additem(menu, "\wAk47 \yFurious Pouacock", "4", 0)
	menu_additem(menu, "\wAk47 \yVulkan", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0 );
	
	return 1; 
}

public AkCase(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return 1;
	}
	new nick[33]; get_user_name(id, nick, 32);
	AK[id] = item;
	CC_SendMessage(id, "&x03%s &x01You Chouse &x04%s &x01as Your Ak47", nick, AKMenuNames[item]);
	
	menu_destroy (menu);
	return 1;
}

public CurentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_AK47) 
	{
		set_pev(id, pev_viewmodel2, AKModels[AK[id]]);
	}
}

public AkMenu(id)
{
	if(is_user_alive(id))
	{
		MenuAk(id);
	}else{
		MenuAk(id);
	}
}
