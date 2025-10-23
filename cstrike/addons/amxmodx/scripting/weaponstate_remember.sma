// Copyright © 2016 Vaqtincha

//============================ CONFIG START ===========================//
// #define ONLY_GIVEN
// #define NOTIFICATION 		// glock & famas
//============================= CONFIG END ============================//

#define VERSION "0.0.4"

// offsets
const m_iId = 43
const m_pPlayer = 41
const m_fWeaponState = 74
// linux extraoffset
const XO_WEAPON = 4

const PDATA_SAFE = 2


#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define MAX_PLAYERS			32

#define IsOnGround(%1) 				(pev(pev(%1, pev_owner), pev_flags) & FL_ONGROUND)
#define IsPlayer(%1)				(1 <= (%1) <= g_iMaxPlayers)
#define get_weapon_owner(%1)		get_pdata_cbase(%1, m_pPlayer, XO_WEAPON)
#define get_weapon_state(%1)		any:get_pdata_int(%1, m_fWeaponState, XO_WEAPON)
#define set_weapon_state(%1,%2)		set_pdata_int(%1, m_fWeaponState, any:%2, XO_WEAPON)

// #define get_weapon_id(%1)			get_pdata_int(%1, m_iId, XO_WEAPON)
stock get_weapon_id(pWeapon) { 													// safe
	new iId = get_pdata_int(pWeapon, m_iId, XO_WEAPON)
	return (CSW_P228 <= iId <= CSW_P90) ? iId : 0
}

enum WeaponState
{
	WPNSTATE_NULL = 			0,
	WPNSTATE_USP_SILENCED		= (1<<0),
	WPNSTATE_GLOCK18_BURST_MODE	= (1<<1),
	WPNSTATE_M4A1_SILENCED		= (1<<2),
	// WPNSTATE_ELITE_LEFT			= (1<<3),
	WPNSTATE_FAMAS_BURST_MODE	= (1<<4),
	// WPNSTATE_SHIELD_DRAWN		= (1<<5)
}

new g_iMaxPlayers
new WeaponState:g_bWeaponState[MAX_PLAYERS +1][CSW_P90 + 1]


public plugin_init()
{
	register_plugin("WeaponState Remember", VERSION, "Vaqtincha")

	static const szWeaponList[][] = {
		"weapon_m4a1", "weapon_usp",
		"weapon_famas", "weapon_glock18"
	}

	for(new i = 0; i < sizeof(szWeaponList); ++i)
	{
		RegisterHam(Ham_Item_AddToPlayer, szWeaponList[i], "Item_AddToPlayer_Post", .Post = true)
		RegisterHam(Ham_Weapon_SecondaryAttack, szWeaponList[i], "Weapon_SecondaryAttack_Post", .Post = true)
	}

	g_iMaxPlayers = get_maxplayers()
}

public client_putinserver(id)
{
	g_bWeaponState[id][CSW_M4A1]
		= g_bWeaponState[id][CSW_USP]
		= g_bWeaponState[id][CSW_FAMAS] 
		= g_bWeaponState[id][CSW_GLOCK18] 
		= WPNSTATE_NULL;
}

public Weapon_SecondaryAttack_Post(pWeapon)
{
	if(pWeapon <= 0)
		return HAM_IGNORED

	new id = get_weapon_owner(pWeapon)
	if(IsPlayer(id))
	{
		// client_print(id, print_center, "current %i my %i", get_weapon_state(pWeapon), g_bWeaponState[id][get_weapon_id(wEnt)])
		g_bWeaponState[id][get_weapon_id(pWeapon)] = get_weapon_state(pWeapon)
	}

	return HAM_IGNORED
}

public Item_AddToPlayer_Post(pWeapon, id)
{
	if(pWeapon <= 0 || pev_valid(pWeapon) != PDATA_SAFE /* || !is_user_alive(id) */)
		return HAM_IGNORED

#if defined ONLY_GIVEN
	if(IsOnGround(pWeapon))
		return HAM_IGNORED
#endif

	new iId = get_weapon_id(pWeapon)
	set_weapon_state(pWeapon, g_bWeaponState[id][iId])

#if defined NOTIFICATION
	if((g_bWeaponState[id][iId] & WPNSTATE_FAMAS_BURST_MODE) || (g_bWeaponState[id][iId] & WPNSTATE_GLOCK18_BURST_MODE))
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Switch_To_BurstFire")
	}
#endif
	return HAM_IGNORED
}


