#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN  "Incomsystem Respawn"
#define VERSION "1.0"
#define AUTHOR  "Tonitaga"

#define ENABLED       "1"
#define DISABLED      "0"
#define DEFAULT_STATE ENABLED

// Время неуязвимости по умолчанию в секундах
#define DEFAULT_GODMODE_TIME "3.0"

// Цвет подсветки по умолчанию (Золотой)
#define DEFAULT_GLOW_COLOR   "255215000"

// Время воскрешения по умолчанию в секундах
#define DEFAULT_RESPAWN_TIME "1.5"

new g_RespawnEnabled;
new g_GodmodeTime;
new g_RespawnTime;
new g_GlowColor;
new g_GodmodeTaskOffset = 1000; // Базовый оффсет для задач неуязвимости

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("DeathMsg", "OnPlayerDeath", "a");
	register_event("ShowMenu", "OnTeamSelection", "b", "4&Team_Select");
	register_event("VGUIMenu", "OnTeamSelection", "b", "1=2");

	g_RespawnEnabled = register_cvar("amx_incom_respawn_enable", DEFAULT_STATE);
	g_GodmodeTime = register_cvar("amx_incom_respawn_godmode", DEFAULT_GODMODE_TIME);
	g_RespawnTime = register_cvar("amx_incom_respawn_time", DEFAULT_RESPAWN_TIME);
	g_GlowColor = register_cvar("amx_incom_respawn_glow_color", DEFAULT_GLOW_COLOR);

	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage");
}

public OnTeamSelection(playerId)
{
	if (get_pcvar_num(g_RespawnEnabled))
	{
		new playerData[1];
		playerData[0] = playerId;
		set_task(1.0, "RespawnPlayerTask", 0, playerData, sizeof(playerData));
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

	if (!is_user_connected(playerId) || cs_get_user_team(playerId) == CS_TEAM_SPECTATOR)
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
	
	client_print(playerId, print_chat, "[Respawn] Вы воскрешены с неуязвимостью на %.1f секунд!", godmodeDuration);
}

public RemoveGodmodeTask(godmodeData[])
{
	new playerId = godmodeData[0];
	
	if (is_user_connected(playerId) && is_user_alive(playerId))
	{
		SetGodmode(playerId, false);
		StopGodmodeEffects(playerId);
		client_print(playerId, print_chat, "[Respawn] Неуязвимость закончилась!");
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