#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

new const DEFAULT_ATTACKER_FLAGS[] = "";
new const DEFAULT_ATTACKER_COLOR[] = "0 100 200";
new const DEFAULT_ATTACKER_POSITION[] = "-1.0 0.55";
new const DEFAULT_SPECTATORS_FLAGS[] = "d";
new const DEFAULT_SPECTATORS_COLOR[] = "0 100 200";
new const DEFAULT_SPECTATORS_POSITION[] = "-1.0 0.55";

new damager_block_wall;
new damager_multi_hits_count;
new damager_attacker_flags;
new damager_attacker_color[3];
new Float:damager_attacker_position[2];
new damager_spectators_flags;
new damager_spectators_color[3];
new Float:damager_spectators_position[2];

new g_pCvarAttackerFlags;
new g_pCvarAttackerColor;
new g_pCvarAttackerPosition;
new g_pCvarSpectatorsFlags;
new g_pCvarSpectatorsColor;
new g_pCvarSpectatorsPosition;

new g_iTotalHits[MAX_PLAYERS + 1];
new Float:g_flTotalDamage[MAX_PLAYERS + 1];
new Float:g_flLastDamageTime[MAX_PLAYERS + 1];
new Float:g_vecLastEndPos[3];

new g_iHudSync_Damage;

public plugin_init()
{
	register_plugin("Simple Damager", "2.1.0", "fl0wer");

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "@CBasePlayer_TraceAttack_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", true);

	g_iHudSync_Damage = CreateHudSyncObj();
}

public plugin_cfg()
{
	bind_pcvar_num(create_cvar("damager_block_wall", "0", _, "Show damage through walls^n0 - disabled^n1 - enabled", true, 0.0, true, 1.0), damager_block_wall);
	bind_pcvar_num(create_cvar("damager_multi_hits", "1", _, "Show multi-hits counter if they more than one.^n0 - disabled^n1 - enabled", true, 0.0, true, 1.0), damager_multi_hits_count);

	g_pCvarAttackerFlags = create_cvar("damager_attacker_flags", DEFAULT_ATTACKER_FLAGS, _, "Attacker damager flags");
	UpdateFlagsVar(damager_attacker_flags, DEFAULT_ATTACKER_FLAGS);
	hook_cvar_change(g_pCvarAttackerFlags, "@HandleCvarChanged");

	g_pCvarAttackerColor = create_cvar("damager_attacker_color", DEFAULT_ATTACKER_COLOR, _, "Attacker damager colors");
	UpdateColorVar(damager_attacker_color, g_pCvarAttackerColor, DEFAULT_ATTACKER_COLOR);
	hook_cvar_change(g_pCvarAttackerColor, "@HandleCvarChanged");

	g_pCvarAttackerPosition = create_cvar("damager_attacker_position", DEFAULT_ATTACKER_POSITION, _, "Attacker damager position");
	UpdatePositionVar(damager_attacker_position, g_pCvarAttackerPosition, DEFAULT_ATTACKER_POSITION);
	hook_cvar_change(g_pCvarAttackerPosition, "@HandleCvarChanged");

	g_pCvarSpectatorsFlags = create_cvar("damager_spectators_flags", DEFAULT_SPECTATORS_FLAGS, _, "Spectators damager flags");
	UpdateFlagsVar(damager_spectators_flags, DEFAULT_SPECTATORS_FLAGS);
	hook_cvar_change(g_pCvarSpectatorsFlags, "@HandleCvarChanged");

	g_pCvarSpectatorsColor = create_cvar("damager_spectators_color", DEFAULT_SPECTATORS_COLOR, _, "Spectators damager colors");
	UpdateColorVar(damager_spectators_color, g_pCvarSpectatorsColor, DEFAULT_SPECTATORS_COLOR);
	hook_cvar_change(g_pCvarSpectatorsColor, "@HandleCvarChanged");

	g_pCvarSpectatorsPosition = create_cvar("damager_spectators_position", DEFAULT_SPECTATORS_POSITION, _, "Spectators damager position");
	UpdatePositionVar(damager_spectators_position, g_pCvarSpectatorsPosition, DEFAULT_SPECTATORS_POSITION);
	hook_cvar_change(g_pCvarSpectatorsPosition, "@HandleCvarChanged");

	AutoExecConfig(true, "simple_damager");
}

@CBasePlayer_TraceAttack_Post(id, attacker, Float:damage, Float:vecDir[3], trace, bitsDamageType)
{
	get_tr2(trace, TR_vecEndPos, g_vecLastEndPos);
}

@CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (id == attacker || !is_user_connected(attacker))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (damager_block_wall && !IsPlayerInView(attacker, id, bitsDamageType))
		return;

	new Float:time = get_gametime();
	new shotsFired;

	if (bitsDamageType & DMG_BULLET)
	{
		new activeItem = get_member(attacker, m_pActiveItem);

		if (!is_nullent(activeItem) && (get_member(activeItem, m_Weapon_iWeaponState) & (WPNSTATE_GLOCK18_BURST_MODE | WPNSTATE_FAMAS_BURST_MODE)))
		{
			switch (get_member(activeItem, m_iId))
			{
				case WEAPON_FAMAS: shotsFired = get_member(activeItem, m_Weapon_iFamasShotsFired);
				case WEAPON_GLOCK18: shotsFired = get_member(activeItem, m_Weapon_iGlock18ShotsFired);
			}
		}
	}

	if (!shotsFired && g_flLastDamageTime[attacker] != time)
	{
		g_iTotalHits[attacker] = 0;
		g_flTotalDamage[attacker] = 0.0;
	}

	g_iTotalHits[attacker]++;
	g_flTotalDamage[attacker] += damage;
	g_flLastDamageTime[attacker] = time;

	new intDamage = floatround(g_flTotalDamage[attacker], floatround_floor);

	if (intDamage < 1)
		return;

	new fmtDamage[32];

	if (damager_multi_hits_count && g_iTotalHits[attacker] > 1)
		formatex(fmtDamage, charsmax(fmtDamage), "%d (%d*)", intDamage, g_iTotalHits[attacker]);
	else
		formatex(fmtDamage, charsmax(fmtDamage), "%d", intDamage);

	if (!damager_attacker_flags || get_user_flags(attacker) & damager_attacker_flags)
	{
		new color[3];
		new Float:position[2];

		color = damager_attacker_color;
		position = damager_attacker_position;

		set_hudmessage(color[0], color[1], color[2], position[0], position[1], 2, 0.1, 1.5, 0.01, 0.01);
		ShowSyncHudMsg(attacker, g_iHudSync_Damage, fmtDamage);
	}

	ShowDamageToSpectators(attacker, fmtDamage);
}

ShowDamageToSpectators(attacker, damage[])
{
	#define GetObserverMode(%0)			get_entvar(%0, var_iuser1)

	new color[3];
	new Float:position[2];

	color = damager_spectators_color;
	position = damager_spectators_position;

	set_hudmessage(color[0], color[1], color[2], position[0], position[1], 2, 0.1, 1.5, 0.01, 0.01);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == attacker)
			continue;

		if (!is_user_connected(i))
			continue;

		if (damager_spectators_flags && !(get_user_flags(i) & damager_spectators_flags))
			continue;

		if (GetObserverMode(i) != OBS_IN_EYE)
			continue;

		if (get_member(i, m_hObserverTarget) != attacker)
			continue;

		ShowSyncHudMsg(i, g_iHudSync_Damage, damage);
	}
}

bool:IsPlayerInView(attacker, id, bitsDamageType)
{
	new Float:fraction;
	new Float:vecSrc[3];
	new Float:vecEnd[3];

	if (bitsDamageType & DMG_GRENADE)
		ExecuteHam(Ham_EyePosition, id, vecEnd);
	else
		vecEnd = g_vecLastEndPos;

	ExecuteHam(Ham_EyePosition, attacker, vecSrc);
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, attacker, 0);
	get_tr2(0, TR_flFraction, fraction);

	if (fraction == 1.0)
		return true;

	return false;
}

@HandleCvarChanged(pCvar, const oldValue[], const newValue[])
{
	if (pCvar == g_pCvarAttackerFlags)
	{
		UpdateFlagsVar(damager_attacker_flags, newValue);
	}
	else if (pCvar == g_pCvarAttackerColor)
	{
		UpdateColorVar(damager_attacker_color, pCvar, newValue, DEFAULT_ATTACKER_COLOR);
	}
	else if (pCvar == g_pCvarAttackerPosition)
	{
		UpdatePositionVar(damager_attacker_position, pCvar, newValue, DEFAULT_ATTACKER_POSITION);
	}
	else if (pCvar == g_pCvarSpectatorsFlags)
	{
		UpdateFlagsVar(damager_attacker_flags, newValue);
	}
	else if (pCvar == g_pCvarSpectatorsColor)
	{
		UpdateColorVar(damager_spectators_color, pCvar, newValue, DEFAULT_SPECTATORS_COLOR);
	}
	else if (pCvar == g_pCvarSpectatorsPosition)
	{
		UpdatePositionVar(damager_spectators_position, pCvar, newValue, DEFAULT_SPECTATORS_POSITION);
	}
}

UpdateFlagsVar(&valueVar, const newValue[])
{
	valueVar = read_flags(newValue);
}

UpdateColorVar(valueVar[3], pCvar, const newValue[], const defaultValue[] = "")
{
	new color[3][5];

	if (parse(newValue, color[0], charsmax(color[]), color[1], charsmax(color[]), color[2], charsmax(color[])) == sizeof(color))
	{
		for (new i = 0; i < sizeof(color); i++)
			valueVar[i] = clamp(str_to_num(color[i]), 0, 255);

		set_pcvar_string(pCvar, fmt("%d %d %d", valueVar[0], valueVar[1], valueVar[2]));
	}
	else
		set_pcvar_string(pCvar, defaultValue);
}

UpdatePositionVar(Float:valueVar[2], pCvar, const newValue[], const defaultValue[] = "")
{
	new position[2][6];

	if (parse(newValue, position[0], charsmax(position[]), position[1], charsmax(position[])) == sizeof(position))
	{
		new Float:temp;

		for (new i = 0; i < sizeof(position); i++)
		{
			temp = str_to_float(position[i]);

			valueVar[i] = temp < 0.0 ? -1.0 : floatclamp(temp, 0.0, 1.0);
		}

		set_pcvar_string(pCvar, fmt("%f %f", valueVar[0], valueVar[1]));
	}
	else
		set_pcvar_string(pCvar, defaultValue);
}
