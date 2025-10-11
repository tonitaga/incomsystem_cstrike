#include <amxmodx>
#include <cstrike>
#include <cromchat>

new const PLUGIN[] = "Incomsystem AK47 Menu";
new const VERSION[] = "1.0";
new const AUTHOR[] = "Tonitaga";

new const AKModels[][] =
{
	"models/v_ak47.mdl",
	"models/incom/ak47/v_ak47_vulkan.mdl",
	"models/incom/ak47/v_ak47_aquamarine_revenge.mdl",
	"models/incom/ak47/v_ak47_bloodsport.mdl",
	"models/incom/ak47/v_ak47_case_hardened.mdl",
	"models/incom/ak47/v_ak47_fire_serpent.mdl",
	"models/incom/ak47/v_ak47_gold.mdl",
	"models/incom/ak47/v_ak47_the_empress.mdl"
};

new const AKMenuNames[][] =
{
    "Ak47 [DEFAULT]",
    "Ak47 Vulkan",
	"Ak47 Aquamarine Revenge",
	"Ak47 Bloodsport",
	"Ak47 Case Hardened",
	"Ak47 Fire Serpent",
	"Ak47 Gold",
	"Ak47 The Empress"
};

new AK[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /skins-ak47","MenuAk");
	register_event("CurWeapon", "ChangeCurrentWeapon", "be", "1=1");
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
	new menu = menu_create("\y>>>>> \rAK47 skin selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "AkCase")
	
	menu_additem(menu, "Ak47 \r[DEFAULT]^n", "1", 0)
	menu_additem(menu, "\wAk47 \yVulkan", "2", 0)
	menu_additem(menu, "\wAk47 \yAquamarine Revenge", "3", 0)
	menu_additem(menu, "\wAk47 \yBloodsport", "4", 0)
	menu_additem(menu, "\wAk47 \yCase Hardened", "5", 0)
	menu_additem(menu, "\wAk47 \yFire Serpent", "6", 0)
	menu_additem(menu, "\wAk47 \yGold", "7", 0)
	menu_additem(menu, "\wAk47 \yThe Empress", "8", 0)
	
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

public ChangeCurrentWeapon(id) 
{
	if(get_user_weapon(id) == CSW_AK47) 
	{
		set_pev(id, pev_viewmodel2, AKModels[AK[id]]);
	}
}
