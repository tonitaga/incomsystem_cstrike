/**
 *
 * Team Grenade Trail
 *  by Numb
 *
 *
 * Description
 *  This plugin adds a trail after the grenade. Each type of grenade has an unique
 *  color what can be changed by cvar. Unlike other grenade trail plugins, this one
 *  has two major differences. First is that trails are actually made out of arrows
 *  what show direction in what grenade is moving (so now if you came out of corner
 *  and see a trail - you can instantly tell where to expect grenade to be). Second
 *  and most important one is that by default only team mates can see trails of your
 *  thrown grenades (this gives you and your team mates advantage from misunderstandings
 *  - no more guessing did any of those 10 noobs behind you thrown flashes or what;
 *  but when it comes to enemy grenades - you still must spot the model of the grenade
 *  to see and identify grenade type).
 *
 *
 * Requires:
 *  CStrike
 *  CSX
 *
 *
 * Cvars:
 *
 *  + "amx_grentrail_status" - who can see the trail.
 *  - "3" - everyone.
 *  - "2" - team and everyone who's dead.
 *  - "1" - only team. [default]
 *  - "0" - plugin disabled.
 *
 *  + "amx_grentrail_color_fb" - flashbang trail color [rrrgggbbb].
 *  - "000255255" - red 0; 255 green; 255 blue [default].
 *
 *  + "amx_grentrail_color_he" - explosive trail color [rrrgggbbb].
 *  - "255063000" - red 255; 63 green; 0 blue [default].
 *
 *  + "amx_grentrail_color_sg" - smokegren trail color [rrrgggbbb].
 *  - "031255127" - red 31; 255 green; 127 blue [default].
 *
 *  + "amx_grentrail_team_color" - extra trail line with owners team color.
 *  - "1" - enabled.
 *  - "0" - disabled. [default]
 *
 *
 * Additional info:
 *  Tested in Counter-Strike 1.6 with amxmodx 1.8.2 (dev build hg21).
 *
 *
 * Credits:
 *  Original idea came from AssKicR's ( http://forums.alliedmods.net/member.php?u=261 )
 *  plugin ( http://forums.alliedmods.net/showthread.php?p=19096 ) what was published in
 *  2004/May/05. Method of showing trails taken from jim_yang's
 *  ( http://forums.alliedmods.net/member.php?u=19661 ) plugin
 *  ( http://forums.alliedmods.net/showthread.php?t=50171 ) what was published in 2007/Jan/21.
 *
 *
 * Change-Log:
 *
 *  + 1.2
 *  - Added: Support for team color trail (this is another smaller trail what has no effect on the main one).
 *  - Changed: Improved plugin performance.
 *  - Changed: Renamed "amx_grentrail_team" cvar to "amx_grentrail_status".
 *  - Changed: Renamed "amx_grentrail_color_sm" cvar to "amx_grentrail_color_sg".
 *
 *  + 1.1
 *  - Fixed: An issue with team detection once player team was changed by some custom plugin.
 *
 *  + 1.0
 *  - First release.
 *
 *
 * Downloads:
 *  Amx Mod X forums: http://forums.alliedmods.net/showthread.php?p=1443603#post1443603
 *
**/

// ----------------------------------------- CONFIG START -----------------------------------------

// If you are having problems, that not everyone who should see the trail is seeing them, that can
// be due to message type and ping. Using "MSG_ONE_UNRELIABLE" and "MSG_BROADCAST" is better for server
// stability, however using "MSG_ONE" and "MSG_ALL" garanties that client will recieve the update.
#define MSG_TYPE_ALONE MSG_ONE // default: (uncommented)
//#define MSG_TYPE_ALONE MSG_ONE_UNRELIABLE // default: (commented)
#define MSG_TYPE_ALL MSG_ALL // default: (uncommented)
//#define MSG_TYPE_ALL MSG_BROADCAST // default: (commented)

// ------------------------------------------ CONFIG END ------------------------------------------


#include <amxmodx>
#include <cstrike>
#include <csx>

#define PLUGIN_NAME	"Team Grenade Trail"
#define PLUGIN_VERSION	"1.2"
#define PLUGIN_AUTHOR	"Numb"

#define SetPlayerBit(%1,%2)    ( %1 |=  ( 1 << ( %2 & 31 ) ) )
#define ClearPlayerBit(%1,%2)  ( %1 &= ~( 1 << ( %2 & 31 ) ) )
#define CheckPlayerBit(%1,%2)  ( %1 &   ( 1 << ( %2 & 31 ) ) )

new g_iCvar_ColorFlash;
new g_iCvar_ColorHe;
new g_iCvar_ColorSmoke;
new g_iCvar_TrailStatus;
new g_iCvar_TeamColor;

new g_iSpriteLine;
new g_iSpriteArrow;

new g_iConnectedUsers;
new g_iDeadUsers;
new g_iMaxPlayers;

public plugin_precache()
{
	g_iSpriteArrow = precache_model("sprites/arrow1.spr");
	g_iSpriteLine  = precache_model("sprites/smoke.spr");
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	g_iCvar_TrailStatus = register_cvar("amx_grentrail_status", "1");
	
	g_iCvar_ColorFlash  = register_cvar("amx_grentrail_color_fb", "000255255");
	g_iCvar_ColorHe     = register_cvar("amx_grentrail_color_he", "255063000");
	g_iCvar_ColorSmoke  = register_cvar("amx_grentrail_color_sg", "031255127");
	
	g_iCvar_TeamColor   = register_cvar("amx_grentrail_team_color", "0");
	
	register_event("ResetHUD", "Event_ResetHUD", "be");
	register_event("Health",   "Event_Health",   "bd");
	
	g_iMaxPlayers = clamp(get_maxplayers(), 1, 32);
}

public client_connect(iPlrId)
{
	ClearPlayerBit(g_iConnectedUsers, iPlrId);
	ClearPlayerBit(g_iDeadUsers, iPlrId);
}

public client_putinserver(iPlrId)
{
	if( !is_user_bot(iPlrId) )
	{
		SetPlayerBit(g_iConnectedUsers, iPlrId);
		if( is_user_alive(iPlrId) )
			ClearPlayerBit(g_iDeadUsers, iPlrId);
		else
			SetPlayerBit(g_iDeadUsers, iPlrId);
	}
}

public client_disconnect(iPlrId)
{
	ClearPlayerBit(g_iConnectedUsers, iPlrId);
	ClearPlayerBit(g_iDeadUsers, iPlrId);
}

public Event_ResetHUD(iPlrId)
{
	if( CheckPlayerBit(g_iConnectedUsers, iPlrId) )
	{
		if( is_user_alive(iPlrId) )
			ClearPlayerBit(g_iDeadUsers, iPlrId);
		else
			SetPlayerBit(g_iDeadUsers, iPlrId);
	}
}

public Event_Health(iPlrId)
{
	if( CheckPlayerBit(g_iConnectedUsers, iPlrId) )
	{
		if( is_user_alive(iPlrId) )
			ClearPlayerBit(g_iDeadUsers, iPlrId);
		else
			SetPlayerBit(g_iDeadUsers, iPlrId);
	}
}

public plugin_unpause()
{
	g_iConnectedUsers = 0;
	g_iDeadUsers = 0;
	
	for( new iPlrId=1; iPlrId<=g_iMaxPlayers; iPlrId++ )
	{
		if( is_user_connected(iPlrId) )
		{
			if( !is_user_bot(iPlrId) )
			{
				SetPlayerBit(g_iConnectedUsers, iPlrId);
				if( !is_user_alive(iPlrId) )
					SetPlayerBit(g_iDeadUsers, iPlrId);
			}
		}
	}
}

public grenade_throw(iPlrId, iGrenId, iWeaponType)
{
	new iTemp;
	switch( iWeaponType )
	{
		case CSW_FLASHBANG:    iTemp = get_pcvar_num(g_iCvar_ColorFlash);
		case CSW_HEGRENADE:    iTemp = get_pcvar_num(g_iCvar_ColorHe);
		case CSW_SMOKEGRENADE: iTemp = get_pcvar_num(g_iCvar_ColorSmoke);
		default: return;
	}
	
	new iRed = iTemp/1000000;
	iTemp %= 1000000;
	new iGreen = iTemp/1000;
	new iBlue = iTemp%1000;
	
	iTemp = clamp(get_pcvar_num(g_iCvar_TeamColor), 0, 1);
	
	switch( clamp(get_pcvar_num(g_iCvar_TrailStatus), 0, 3) )
	{
		case 1:
		{
			new CsTeams:iOwnerTeam = cs_get_user_team(iPlrId);
			
			for( new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++ )
			{
				if( CheckPlayerBit(g_iConnectedUsers, iPlayer) )
				{
					if( cs_get_user_team(iPlayer)==iOwnerTeam )
					{
						message_begin(MSG_TYPE_ALONE, SVC_TEMPENTITY, _, iPlayer);
						write_byte(TE_BEAMFOLLOW);
						write_short(iGrenId);
						write_short(g_iSpriteArrow);
						write_byte(15);
						write_byte(7);
						write_byte(iRed);
						write_byte(iGreen);
						write_byte(iBlue);
						write_byte(191);
						message_end();
						
						if( iTemp )
						{
							message_begin(MSG_TYPE_ALONE, SVC_TEMPENTITY, _, iPlayer);
							write_byte(TE_BEAMFOLLOW);
							write_short(iGrenId);
							write_short(g_iSpriteLine);
							write_byte(15);
							write_byte(1);
							switch( iOwnerTeam )
							{
								case CS_TEAM_T:
								{
									write_byte(255);
									write_byte(0);
									write_byte(0);
								}
								case CS_TEAM_CT:
								{
									write_byte(0);
									write_byte(0);
									write_byte(255);
								}
								default:
								{
									write_byte(127);
									write_byte(127);
									write_byte(127);
								}
							}
							write_byte(191);
							message_end();
						}
					}
				}
			}
		}
		case 2:
		{
			new CsTeams:iOwnerTeam = cs_get_user_team(iPlrId);
			
			for( new iPlayer=1; iPlayer<=g_iMaxPlayers; iPlayer++ )
			{
				if( CheckPlayerBit(g_iConnectedUsers, iPlayer) )
				{
					if( CheckPlayerBit(g_iDeadUsers, iPlayer) || cs_get_user_team(iPlayer)==iOwnerTeam )
					{
						message_begin(MSG_TYPE_ALONE, SVC_TEMPENTITY, _, iPlayer);
						write_byte(TE_BEAMFOLLOW);
						write_short(iGrenId);
						write_short(g_iSpriteArrow);
						write_byte(15);
						write_byte(7);
						write_byte(iRed);
						write_byte(iGreen);
						write_byte(iBlue);
						write_byte(191);
						message_end();
						
						if( iTemp )
						{
							message_begin(MSG_TYPE_ALONE, SVC_TEMPENTITY, _, iPlayer);
							write_byte(TE_BEAMFOLLOW);
							write_short(iGrenId);
							write_short(g_iSpriteLine);
							write_byte(15);
							write_byte(1);
							switch( iOwnerTeam )
							{
								case CS_TEAM_T:
								{
									write_byte(255);
									write_byte(0);
									write_byte(0);
								}
								case CS_TEAM_CT:
								{
									write_byte(0);
									write_byte(0);
									write_byte(255);
								}
								default:
								{
									write_byte(127);
									write_byte(127);
									write_byte(127);
								}
							}
							write_byte(191);
							message_end();
						}
					}
				}
			}
		}
		case 3:
		{
			message_begin(MSG_TYPE_ALL, SVC_TEMPENTITY);
			write_byte(TE_BEAMFOLLOW);
			write_short(iGrenId);
			write_short(g_iSpriteArrow);
			write_byte(15);
			write_byte(7);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(191);
			message_end();
			
			if( iTemp )
			{
				message_begin(MSG_TYPE_ALL, SVC_TEMPENTITY);
				write_byte(TE_BEAMFOLLOW);
				write_short(iGrenId);
				write_short(g_iSpriteLine);
				write_byte(15);
				write_byte(1);
				switch( cs_get_user_team(iPlrId) )
				{
					case CS_TEAM_T:
					{
						write_byte(255);
						write_byte(0);
						write_byte(0);
					}
					case CS_TEAM_CT:
					{
						write_byte(0);
						write_byte(0);
						write_byte(255);
					}
					default:
					{
						write_byte(127);
						write_byte(127);
						write_byte(127);
					}
				}
				write_byte(191);
				message_end();
			}
		}
	}
}

