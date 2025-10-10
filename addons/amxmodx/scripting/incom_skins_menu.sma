#include <amxmodx>
#include <cstrike>

#pragma tabsize 0

new nightvisionOverrideActive[33];

public plugin_init()
{
	register_plugin("Incomsystem Skins Menu", "1.0", "Tonitaga")
	register_clcmd("say /menu", "GameMenu")
	register_clcmd("nightvision", "nightvision")
}
public nightvision(id)
{
	if (nightvisionOverrideActive[id])
	{
		GameMenu(id)
		return PLUGIN_HANDLED;
	}
	nightvisionOverrideActive[id] = true
	return PLUGIN_CONTINUE;
}
public client_putinserver(id)
{
	nightvisionOverrideActive[id] = true
}

public GameMenu(id)
{
	new menu = menu_create("\y>>>>> \rServer Menu \y<<<<<", "menu_case")

	menu_additem(menu, "\yKnife \wMenu", "1", 0)
	menu_additem(menu, "\yAwp \wMenu", "2", 0) 
	menu_additem(menu, "\yAk47 \wMenu", "3", 0)
	menu_additem(menu, "\yM4a1 \wMenu", "4", 0)
	menu_additem(menu, "\yDeagle \wMenu", "5", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public menu_case(id, menu, item) 
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(menu, item, acces, data,5, iName, 63, callback)
	new key = str_to_num(data)
	
	switch(key){
	
	case 1: client_cmd(id,"say /knife")
	case 2: client_cmd(id,"say /awp")
	case 3: client_cmd(id,"say /ak")
	case 4: client_cmd(id,"say /m4")
	case 5: client_cmd(id,"say /dgl")
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
