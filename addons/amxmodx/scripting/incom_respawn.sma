#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <fun>

#define PLUGIN  "Incomsystem Respawn"
#define VERSION "1.0"
#define AUTHOR  "Tonitaga"

#define WEAPONS_COMMAND "say /weapons"

#define KEY_ENABLED      "amx_incom_respawn_enable"
#define KEY_GODMODE_TIME "amx_incom_respawn_godmode"
#define KEY_RESPAWN_TIME "amx_incom_respawn_time"
#define KEY_GLOW_COLOR   "amx_incom_respawn_glow_color"
#define KEY_HUD_COLOR    "amx_incom_respawn_hud_color"
#define KEY_ENABLE_HUD   "amx_incom_respawn_enable_hud"

#define DEFAULT_ENABLED      "0"
#define DEFAULT_GODMODE_TIME "3.0"
#define DEFAULT_RESPAWN_TIME "1.5"
#define DEFAULT_GLOW_COLOR   "255215000"
#define DEFAULT_HUD_COLOR    "110030175"
#define DEFAULT_ENABLE_HUD   "1"

new g_RespawnEnabled;
new g_GodmodeTime;
new g_RespawnTime;
new g_GlowColor;
new g_HUDColor;
new g_HUDEnabled;

// Базовый оффсет для задач неуязвимости
new g_GodmodeTaskOffset = 1000;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("DeathMsg", "OnPlayerDeath", "a");
	register_event("ShowMenu", "OnTeamSelection", "b", "4&Team_Select");
	register_event("VGUIMenu", "OnTeamSelection", "b", "1=2");
	register_clcmd(WEAPONS_COMMAND, "ShowWeaponsMenu");

	CreateConvVars()

	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage");
}

static CreateConvVars()
{
	g_RespawnEnabled = register_cvar(KEY_ENABLED, DEFAULT_ENABLED);
	g_GodmodeTime    = register_cvar(KEY_GODMODE_TIME, DEFAULT_GODMODE_TIME);
	g_RespawnTime    = register_cvar(KEY_RESPAWN_TIME, DEFAULT_RESPAWN_TIME);
	g_GlowColor      = register_cvar(KEY_GLOW_COLOR, DEFAULT_GLOW_COLOR);
	g_HUDColor       = register_cvar(KEY_HUD_COLOR, DEFAULT_HUD_COLOR);
	g_HUDEnabled     = register_cvar(KEY_ENABLE_HUD, DEFAULT_ENABLE_HUD);
}

public OnTeamSelection(playerId)
{
	if (get_pcvar_num(g_RespawnEnabled))
	{
		new playerData[1];
		playerData[0] = playerId;

		new Float:respawnAfter = get_pcvar_float(g_RespawnTime);
		set_task(respawnAfter, "RespawnPlayerTask", 0, playerData, sizeof(playerData));
	}
}

public OnPlayerDeath()
{
	if (get_pcvar_num(g_RespawnEnabled))
	{
		new deadPlayerId = read_data(2);

		new playerData[1];
		playerData[0] = deadPlayerId;

		new Float:respawnAfter = get_pcvar_float(g_RespawnTime);
		set_task(respawnAfter, "RespawnPlayerTask", 0, playerData, sizeof(playerData));
	}
}

public RespawnPlayerTask(playerData[])
{
	new playerId = playerData[0];

	if (!is_user_connected(playerId))
		return;
	
	if (is_user_alive(playerId))
		return;
	
	ExecuteHamB(Ham_CS_RoundRespawn, playerId);
	
	SetGodmode(playerId, true);

	new Float:godmodeDuration = get_pcvar_float(g_GodmodeTime);
	
	new godmodeData[1];
	godmodeData[0] = playerId;
	set_task(godmodeDuration, "RemoveGodmodeTask", g_GodmodeTaskOffset + playerId, godmodeData, sizeof(godmodeData));
	
	StartGodmodeEffects(playerId);

	if (get_pcvar_num(g_HUDEnabled))
	{
		new message[128];
		formatex(message, charsmax(message), "Incomsystem дарует режим бога на %.1f секунд(ы)", godmodeDuration);
		ShowHudMessage(playerId, message);
	}
	
	set_task(0.2, "ShowWeaponsMenu", playerId);
}

public RemoveGodmodeTask(godmodeData[])
{
	new playerId = godmodeData[0];
	
	if (is_user_connected(playerId) && is_user_alive(playerId))
	{
		SetGodmode(playerId, false);
		StopGodmodeEffects(playerId);
	
		if (get_pcvar_num(g_HUDEnabled))
		{
			ShowHudMessage(playerId, "Режим бога закончился");
		}
	}
}

public OnPlayerTakeDamage(victim, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(victim) || !is_user_alive(victim))
		return HAM_IGNORED;

	if (task_exists(g_GodmodeTaskOffset + victim))
	{
		// Блокируем урон
		SetHamParamFloat(4, 0.0); // Устанавливаем урон в 0
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

stock ShowHudMessage(id, const message[])
{
	if (!is_user_connected(id))
		return;
	
	ClearHudMessages(id);

	new hudColorStr[32], Float:hudColor[3];
	get_pcvar_string(g_HUDColor, hudColorStr, charsmax(hudColorStr));
	ParseRGBColor(hudColorStr, hudColor);

	set_hudmessage(
		floatround(hudColor[0]),
		floatround(hudColor[1]),
		floatround(hudColor[2]),
		-1.0, 0.3, 0, 6.0, 3.0, 0.1, 0.2, -1
	);
	show_hudmessage(id, message);
}

stock ClearHudMessages(id)
{
	if (!is_user_connected(id))
		return;
	
	// Показываем пустое сообщение на всех каналах
	for (new i = 1; i <= 4; i++)
	{
		set_hudmessage(0, 0, 0, 0.0, 0.0, 0, 0.0, 0.0, 0.0, 0.0, i);
		show_hudmessage(id, "");
	}
}

stock SetGodmode(playerId, bool:godmodeEnabled)
{
	if (godmodeEnabled)
	{
		set_pev(playerId, pev_takedamage, DAMAGE_NO);
	}
	else
	{
		set_pev(playerId, pev_takedamage, DAMAGE_AIM);
	}
}

stock StartGodmodeEffects(playerId)
{
	// Получаем цвет из параметра
	new glowColorStr[32], Float:glowColor[3];
	get_pcvar_string(g_GlowColor, glowColorStr, charsmax(glowColorStr));
	ParseRGBColor(glowColorStr, glowColor);
	
	// Подсветка игрока
	set_pev(playerId, pev_renderfx, kRenderFxGlowShell);
	set_pev(playerId, pev_rendercolor, glowColor);
	set_pev(playerId, pev_renderamt, 25.0);
	
	// Подсветка оружия
	new weaponEnt = get_pdata_cbase(playerId, 373, 5); // m_pActiveItem
	if (pev_valid(weaponEnt))
	{
		set_pev(weaponEnt, pev_renderfx, kRenderFxGlowShell);
		set_pev(weaponEnt, pev_rendercolor, glowColor);
		set_pev(weaponEnt, pev_renderamt, 15.0);
	}
}

stock StopGodmodeEffects(playerId)
{
	// Убираем подсветку игрока
	set_pev(playerId, pev_renderfx, kRenderFxNone);
	set_pev(playerId, pev_rendercolor, {0.0, 0.0, 0.0});
	set_pev(playerId, pev_renderamt, 0.0);
	
	// Убираем подсветку с оружия
	new weaponEnt = get_pdata_cbase(playerId, 373, 5);
	if (pev_valid(weaponEnt))
	{
		set_pev(weaponEnt, pev_renderfx, kRenderFxNone);
		set_pev(weaponEnt, pev_rendercolor, {0.0, 0.0, 0.0});
		set_pev(weaponEnt, pev_renderamt, 0.0);
	}
}

stock ParseRGBColor(const colorStr[], Float:color[3])
{
	new tempStr[4];
	
	// Красный компонент (первые 3 символа)
	copy(tempStr, 3, colorStr);
	color[0] = floatstr(tempStr);
	
	// Зеленый компонент (следующие 3 символа)
	copy(tempStr, 3, colorStr[3]);
	color[1] = floatstr(tempStr);
	
	// Синий компонент (последние 3 символа)
	copy(tempStr, 3, colorStr[6]);
	color[2] = floatstr(tempStr);
	
	// Ограничиваем значения 0-255
	for (new i = 0; i < 3; i++)
	{
		if (color[i] > 255.0) color[i] = 255.0;
		if (color[i] < 0.0) color[i] = 0.0;
	}
}

public ShowWeaponsMenu(playerId)
{
	if (get_pcvar_num(g_RespawnEnabled))
	{
		new menu = menu_create("\y>>>>> \rWeapon selection menu \y<<<<<^n \dby >>\rTonitaga\d<<", "WeaponCase")
		
		menu_additem(menu, "\yAK47 & Deagle", "1", 0);
		menu_additem(menu, "\yM4A1 & Deagle", "2", 0);
		menu_additem(menu, "\yAWP  & Deagle", "3", 0);
		
		menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(playerId, menu, 0);
	}

	return PLUGIN_HANDLED;
}

public WeaponCase(playerId, menu, item)
{
	if (item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	
	if (!is_user_alive(playerId))
	{
		client_print(playerId, print_chat, "[Weapon Menu] Вы должны быть живы для получения оружия!");
		return PLUGIN_HANDLED;
	}
	
	strip_user_weapons(playerId);
	
	give_item(playerId, "weapon_knife");
	
	new data[6], name[64], access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new weapon_set = str_to_num(data);
	
	switch (weapon_set)
	{
		case 1:
		{
			give_item(playerId, "weapon_ak47");
			give_item(playerId, "weapon_deagle");

			GiveAmmo(playerId, "ak47");
			GiveAmmo(playerId, "deagle");
		}
		case 2:
		{
			give_item(playerId, "weapon_m4a1");
			give_item(playerId, "weapon_deagle");

			GiveAmmo(playerId, "m4a1");
			GiveAmmo(playerId, "deagle");
		}
		case 3:
		{
			give_item(playerId, "weapon_awp");
			give_item(playerId, "weapon_deagle");
			
			GiveAmmo(playerId, "awp");
			GiveAmmo(playerId, "deagle");
		}
	}
	
	return PLUGIN_HANDLED;
}

stock GiveAmmo(id, const weapon[])
{
	new ammo_type[32];
	
	if (equal(weapon, "ak47"))
	{
		ammo_type = "762Nato";
	}
	else if (equal(weapon, "m4a1"))
	{
		ammo_type = "556Nato";
	}
	else if (equal(weapon, "awp"))
	{
		ammo_type = "338Magnum";
	}
	else if (equal(weapon, "deagle"))
	{
		ammo_type = "50AE";
	}
	else
	{
		return;
	}

	new max_ammo = 120;

	if (equal(weapon, "awp"))
	{
		max_ammo = 20;
	}

	else if (equal(weapon, "deagle"))
	{
		max_ammo = 28;
	}

	ExecuteHamB(Ham_GiveAmmo, id, max_ammo, ammo_type, max_ammo);
}
