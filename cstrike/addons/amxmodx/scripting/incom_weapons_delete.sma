#include <amxmodx>
#include <fakemeta>

new PLUGIN[] = "Incomsystem Weapons Delete"
new VERSION[] = "1.0"
new AUTHOR[] = "Tonitaga"

#define KEY_ENABLED     "amx_incom_weapons_delete_enable"
#define KEY_DELETE_TIME "amx_incom_weapons_delete_time"

#define DEFAULT_ENABLED     "1"
#define DEFAULT_DELETE_TIME "30.0"

new g_Enabled;
new g_DeleteTime;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_Enabled    = register_cvar(KEY_ENABLED,     DEFAULT_ENABLED)
	g_DeleteTime = register_cvar(KEY_DELETE_TIME, DEFAULT_DELETE_TIME)
	
	register_forward(FM_SetModel, "Fw_SetModel")
}

public Fw_SetModel(entity, const model[])
{
	if (get_pcvar_num(g_Enabled))
	{
		static Float:deleteAfter
		deleteAfter = get_pcvar_float(g_DeleteTime)

		set_task(deleteAfter, "RemoveItems", entity)
	}
}

public RemoveItems(entity)
{
	if (pev_valid(entity))
	{
		static Class[10]
		pev(entity, pev_classname, Class, sizeof Class - 1)
			
		if (equal(Class, "weaponbox"))
		{
			set_pev(entity, pev_nextthink, get_gametime())
			return;
		}
	}
}