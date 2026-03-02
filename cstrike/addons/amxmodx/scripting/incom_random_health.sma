#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

new const PLUGIN[]  = "Incomsystem Random Health";
new const VERSION[] = "1.0";
new const AUTHOR[]  = "Tonitaga";

new health_changed = false;
new health_value = 100;

new       amx_incom_random_health_enable;
new Float:amx_incom_random_health_change_percent;
new       amx_incom_random_health_min_value;
new       amx_incom_random_health_max_value;
new Float:amx_incom_random_health_max_duration;

new pcvar_amx_incom_random_health_enable;
new pcvar_amx_incom_random_health_max_duration;

new const HEALTH_TASKID = 14600;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_dictionary("incom_random_health.txt");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1);
}

public plugin_cfg()
{
	pcvar_amx_incom_random_health_enable = create_cvar(
		"amx_incom_random_health_enable", "1",
		.has_min = true, .min_val = 0.0,
		.has_max = true, .max_val = 1.0,
		.description = "0 - Плагин отключен^n\
						1 - Плагин включен"
	);

	bind_pcvar_num(pcvar_amx_incom_random_health_enable, amx_incom_random_health_enable);

	bind_pcvar_float(
		create_cvar(
			"amx_incom_random_health_change_percent", "7.0",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 100.0,
			.description = "Шанс (%) запуска события случайного HP"
		),
		amx_incom_random_health_change_percent
	);

	bind_pcvar_num(
		create_cvar(
			"amx_incom_random_health_min_value", "50",
			.has_min = true, .min_val = 1.0,
			.has_max = true, .max_val = 255.0,
			.description = "Нижний порог выдаваемого HP"
		),
		amx_incom_random_health_min_value
	);

	bind_pcvar_num(
		create_cvar(
			"amx_incom_random_health_max_value", "250",
			.has_min = true, .min_val = 1.0,
			.has_max = true, .max_val = 255.0,
			.description = "Верхний порог выдаваемого HP"
		),
		amx_incom_random_health_max_value
	);

	pcvar_amx_incom_random_health_max_duration = create_cvar(
		"amx_incom_random_health_max_duration", "120.0",
		.has_min = true, .min_val = 10.0,
		.has_max = true, .max_val = 600.0,
		.description = "Максимальная длительность события случайного HP"
	);

	bind_pcvar_float(pcvar_amx_incom_random_health_max_duration, amx_incom_random_health_max_duration);

	hook_cvar_change(pcvar_amx_incom_random_health_enable, "OnRandomHealthVariableChange");
	hook_cvar_change(pcvar_amx_incom_random_health_max_duration, "OnRandomHealthVariableChange");

	AutoExecConfig();
	
	// Запускаем задачу на выполнение события
	StartProcessRandomHealthTaskOnce();
}

public OnRandomHealthVariableChange(cvar, const old_value[], const new_value[])
{
	if (cvar == pcvar_amx_incom_random_health_enable)
	{
		if (new_value[0] == '0')
		{
			DisableRandomHealth();
		}
		else
		{
			ProcessRandomHealth();
		}
	}
	else if (cvar == pcvar_amx_incom_random_health_max_duration)
	{
		ReplaceProcessRandomHealthTask();
	}
}

public ProcessRandomHealth()
{
	if (!amx_incom_random_health_enable)
	{
		return;
	}

	DisableRandomHealth();

	new Float:rand = random_float(0.0, 100.0);
	if (rand < amx_incom_random_health_change_percent)
	{
		EnableRandomHealth();
		UpdatePlayerHealth();
	}
}

stock EnableRandomHealth()
{
	if (health_changed)
	{
		return;
	}

	health_changed = true;

	new min_value = amx_incom_random_health_min_value;
	new max_value = amx_incom_random_health_max_value;
	if (min_value > max_value)
	{
		new temp = min_value;
		min_value = max_value;
		max_value = temp;
	}

	health_value = random_num(min_value, max_value);

	client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_RANDOM_HEALTH", LANG_PLAYER, "RANDOM_HEALTH_ENABLED", health_value, amx_incom_random_health_max_duration);
}

stock UpdatePlayerHealth()
{
	new players[32], count;
	get_players(players, count);

	for (new i = 0; i < count; i++)
	{
		new playerId = players[i];
		new health = get_user_health(playerId)

		// Изменяем здоровье, только в меньшую сторону
		if (health_value < health && is_user_alive(playerId))
		{
			set_user_health(playerId, health_value);
		}
	}
}

stock DisableRandomHealth()
{
	if (health_changed)
	{
		health_changed = false;
	}
}

public OnPlayerSpawn(playerId)
{
	if (health_changed && is_user_alive(playerId))
	{
		set_user_health(playerId, health_value);
	}
}

stock ReplaceProcessRandomHealthTask()
{
	if (task_exists(HEALTH_TASKID))
	{
		remove_task(HEALTH_TASKID);
	}

	StartProcessRandomHealthTask();
}

stock StartProcessRandomHealthTaskOnce()
{
	if (!task_exists(HEALTH_TASKID))
	{
		StartProcessRandomHealthTask();
	}
}

stock StartProcessRandomHealthTask()
{
	set_task(amx_incom_random_health_max_duration, "ProcessRandomHealth", HEALTH_TASKID, .flags = "b");
}