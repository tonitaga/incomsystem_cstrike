#include < amxmodx >
#include < fakemeta >
#include < hamsandwich > 

#define PLUGIN "[ESF] Show Damage"
#define VERSION "1.1"
#define AUTHOR "alan_el_more"

#define esf_get_advancedmelee(%1) get_pdata_int(%1, 298)

new CvarEnable, gMsgHud

public plugin_init( ) 
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	
	RegisterHam( Ham_TakeDamage, "player", "FwTakeDamage", 1 )
	
	register_cvar( "showdmg_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY )
	CvarEnable = register_cvar( "esf_showdmg", "1" )
		
	gMsgHud = get_user_msgid( "MeleeTxtHud" )
}

public FwTakeDamage( victim, inflictor, attacker, Float:damage, damage_type )
{
	if( get_pcvar_num( CvarEnable ) && !esf_get_advancedmelee( attacker ) )
	{
		new Damage
		Damage = pev( victim, pev_dmg_take )
		
		if( Damage > 0 )
			ShowDmg( attacker, Damage )
	}
}

ShowDmg( id, Dmg )
{
	message_begin( MSG_ONE_UNRELIABLE, gMsgHud, _, id )
	write_byte( 3 ) // HUD Damage
	write_byte( Dmg )
	message_end( )
}
