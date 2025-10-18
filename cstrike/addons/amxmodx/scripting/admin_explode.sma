#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <fun>

#define PLUGIN  "Admin Explode"
#define VERSION "1.1"
#define AUTHOR  "tuty & Tonitaga"

#define KEY_ENABLED    "admin_explode_enabled"
#define KEY_RADIUS     "admin_explode_radius"
#define KEY_DAMAGE     "admin_explode_damage"
#define KEY_FRAGS      "admin_explode_frags"
#define KEY_FRAG_MONEY "admin_explode_frag_money"

#define DEFAULT_ENABLED    "1"
#define DEFAULT_RADIUS     "350"
#define DEFAULT_DAMAGE     "50"
#define DEFAULT_FRAGS      "0"
#define DEFAULT_FRAG_MONEY "0"

new gMaxPlayers;
new gMessageDeathMsg;
new gCvarEnabled;
new gCvarRadius;
new gCvarDamage;
new gCvarFragBonus;
new gCvarMoneyBonus;
new gCylinderSprite;

new const gExplodeSound[] = "weapons/rocketfire1.wav";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event( "DeathMsg", "Hook_DeathMessage", "a" );
	
	gMaxPlayers = get_maxplayers();
	gMessageDeathMsg = get_user_msgid( "DeathMsg" );
}

public plugin_cfg()
{
	gCvarEnabled    = create_cvar(KEY_ENABLED, DEFAULT_ENABLED, _, "Статус плагина^n0 - Отключен^n1 - Включен", true, 0.0, true, 1.0);
	gCvarRadius     = create_cvar(KEY_RADIUS, DEFAULT_RADIUS, _, "Радиус взрыва", true, 0.0, true, 500.0);
	gCvarDamage     = create_cvar(KEY_DAMAGE, DEFAULT_DAMAGE, _, "Урон от взрыва взрыва", true, 0.0, true, 200.0);
	gCvarFragBonus  = create_cvar(KEY_FRAGS, DEFAULT_FRAGS, _, "Количество очков за фраг от ударной волны", true, 0.0, true, 5.0);
	gCvarMoneyBonus = create_cvar(KEY_FRAG_MONEY, DEFAULT_FRAG_MONEY, _, "Количество денег за фраг от ударной волны", true, 0.0, true, 300.0);

	AutoExecConfig(true, "admin_explode")
}

public plugin_precache()
{
	gCylinderSprite = precache_model( "sprites/shockwave.spr" );
	
	precache_sound( gExplodeSound );
}

public Hook_DeathMessage()
{
	if( get_pcvar_num( gCvarEnabled ) != 1 )
	{
		return PLUGIN_CONTINUE;
	}

	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );
	
	new szWeapon[ 30 ];
	read_data( 4, szWeapon, charsmax( szWeapon ) );
	
	if( iVictim == iKiller )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( equal( szWeapon, "world", 5 ) 
	|| equal( szWeapon, "worldspawn", 10 ) 
	|| equal( szWeapon, "trigger_hurt", 12 ) 
	|| equal( szWeapon, "door_rotating", 13 ) 
	|| equal( szWeapon, "door", 4 )
	|| equal( szWeapon, "rotating", 8 ) 
	|| equal( szWeapon, "env_explosion", 13 ) )
	{
		return PLUGIN_CONTINUE;
	}

	if( is_user_admin( iVictim ) )
	{
		new iOrigin[ 3 ];
		get_user_origin( iVictim, iOrigin );
		
		new iRadius = get_pcvar_num( gCvarRadius );
	
		Create_BeamCylinder( iOrigin, 120, gCylinderSprite, 0, 0, 6, 16, 0, random( 255 ), random( 255 ), random( 255 ), 255, 0 );
		Create_BeamCylinder( iOrigin, 320, gCylinderSprite, 0, 0, 6, 16, 0, random( 255 ), random( 255 ), random( 255 ), 255, 0 );
		Create_BeamCylinder( iOrigin, iRadius, gCylinderSprite, 0, 0, 6, 16, 0, random( 255 ), random( 255 ), random( 255 ), 255, 0 );
		
		Blast_ExplodeDamage( iVictim, get_pcvar_float( gCvarDamage ), float( iRadius ) );
		
		emit_sound( iVictim, CHAN_BODY, gExplodeSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}

	return PLUGIN_CONTINUE;
}

stock Blast_ExplodeDamage( entid, Float:damage, Float:range ) 
{
	new Float:flOrigin1[ 3 ];
	pev( entid, pev_origin, flOrigin1 );

	new Float:flDistance;
	new Float:flTmpDmg;
	new Float:flOrigin2[ 3 ];

	for( new i = 1; i <= gMaxPlayers; i++ ) 
	{
		if( is_user_alive( i ) && get_user_team( entid ) != get_user_team( i ) )
		{
			pev( i, pev_origin, flOrigin2 );
			flDistance = get_distance_f( flOrigin1, flOrigin2 );
			
			static const szWeaponName[] = "Admin Blast Explosion";
		
			if( flDistance <= range ) 
			{
				flTmpDmg = damage - ( damage / range ) * flDistance;
				fakedamage( i, szWeaponName, flTmpDmg, DMG_BLAST );
			
				message_begin( MSG_ALL, gMessageDeathMsg );
				write_byte( entid );
				write_byte( i );
				write_byte( 0 );
				write_string( szWeaponName );
				message_end();
			
				set_user_frags( entid, get_user_frags( entid ) + get_pcvar_num( gCvarFragBonus ) );
				cs_set_user_money( entid, cs_get_user_money( entid ) + get_pcvar_num( gCvarMoneyBonus ) );
			}
		}
	}
}

stock Create_BeamCylinder( origin[ 3 ], addrad, sprite, startfrate, framerate, life, width, amplitude, red, green, blue, brightness, speed )
{
	message_begin( MSG_PVS, SVC_TEMPENTITY, origin ); 
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + addrad );
	write_short( sprite );
	write_byte( startfrate );
	write_byte( framerate );
	write_byte(life );
	write_byte( width );
	write_byte( amplitude );
	write_byte( red );
	write_byte( green );
	write_byte( blue );
	write_byte( brightness );
	write_byte( speed );
	message_end();
}
