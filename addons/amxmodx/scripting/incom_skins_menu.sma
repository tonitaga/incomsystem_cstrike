#include <amxmodx>
#include <cstrike>

new const PLUGIN[]  = "Incomsystem Skins Menu";
new const VERSION[] = "1.0";
new const AUTHOR[]  = "Tonitaga";
new const SKIN_COMMAND[] = "say /skins-menu";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd(SKIN_COMMAND, "Menu")
}

public Menu(id)
{
	new menu = menu_create("\y>>>>> \rIncomsystem Skins Menu \y<<<<<", "menu_case")

	menu_additem(menu, "\yKnife \wMenu", "1", 0)
	menu_additem(menu, "\yAWP \wMenu", "2", 0) 
	menu_additem(menu, "\yAK47 \wMenu", "3", 0)
	menu_additem(menu, "\yM4A1 \wMenu", "4", 0)
	menu_additem(menu, "\yDeagle \wMenu", "5", 0)
	menu_additem(menu, "\yGlock \wMenu", "6", 0)
	menu_additem(menu, "\yUSP \wMenu", "7", 0)
	
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
	
	switch(key)
	{
		case 1: client_cmd(id,"say /skins-knife")
		case 2: client_cmd(id,"say /skins-awp")
		case 3: client_cmd(id,"say /skins-ak47")
		case 4: client_cmd(id,"say /skins-m4a1")
		case 5: client_cmd(id,"say /skins-deagle")
		case 6: client_cmd(id,"say /skins-glock")
		case 7: client_cmd(id,"say /skins-usp")
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}
