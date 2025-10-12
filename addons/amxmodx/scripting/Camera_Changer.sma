#include <amxmodx>
#include <engine>

/*
*
*					[KrIvB@sS]
*
*					CrAzY
*
*					DEATHRUN
*
*					77.220.186.38:28404
*
*					Enjoy it! :)
*
*/

public plugin_init()
{
	register_plugin( "Camera Changer", "1.3", "Bl0ck" )
	
	register_cvar( "cam_change", "1" )
	register_cvar( "cam_connect", "0" )
	register_cvar( "cam_message", "1" )
	
	if( get_cvar_num( "cam_change" ) )
	{
		register_clcmd( "say /cam", "CamMenu" )
		register_clcmd( "say_team /cam", "CamMenu" )
		register_clcmd( "say /camera", "CamMenu" )
		register_clcmd( "say_team /camera", "CamMenu" )
	}
	
	register_dictionary( "cam_change.txt" )
	
	return
}

public plugin_precache()
	precache_model( "models/rpgrocket.mdl" )

public client_putinserver(id)
{
	switch ( get_cvar_num( "cam_connect" ) ) 
	{
		case 1:	set_view( id, 1 )
		case 2:	set_view( id, 3 )
		case 3:	set_view( id, 2 )
	}
	
	if ( get_cvar_num( "cam_message" ) ) 
	{
		set_task( 25.0, "CamMessage", id )
	}
	
	return
}

public CamMessage( id )
	client_print( id, print_chat, "[CAM] %L", id, "CAM_MESSAGE" )

public CamMenu( id ) 
{	
	new szText[ 555 char ]
	formatex( szText, charsmax( szText ), "\y%L", id, "CAM_MENU" )
	
	new menu = menu_create( szText, "cam_menu" )
	
	formatex( szText, charsmax( szText ), "%L", id, "CAM_3RD" )
	menu_additem( menu, szText, "1", 0 )
	
	formatex( szText, charsmax( szText ), "%L", id, "CAM_TOPDOWN" )
	menu_additem( menu, szText, "2", 0 )
	
	formatex( szText, charsmax( szText ), "%L", id, "CAM_UPLEFT" )
	menu_additem( menu, szText, "3", 0 )
	
	formatex( szText, charsmax( szText ), "%L", id, "CAM_1ST" )
	menu_additem( menu, szText, "4", 0 )
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL)
	menu_display( id, menu, 0 )
	
	return 1
}

public cam_menu( id, menu, item )
{
	if( item == MENU_EXIT )
	{
		menu_destroy( menu )
		return 1
	}
	
	new data[ 6 ], iName[ 64 ], access, callback
	menu_item_getinfo( menu, item, access, data, 5, iName, 63, callback )
	new key = str_to_num( data )
	
	switch ( key )
	{
		case 1:	set_view( id, 1 )
		case 2:	set_view( id, 3 )
		case 3:	set_view( id, 2 )
		case 4:	set_view( id, 0 )
	}
	
	menu_destroy( menu )
	return 1
}