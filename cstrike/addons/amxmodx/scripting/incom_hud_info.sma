#include <amxmodx>
#include <parse_color>

#define PLUGIN  "Incomsystem HUD Info"
#define VERSION "1.0"
#define AUTHOR  "Tonitaga"

#define KEY_ENABLE            "amx_incom_hud_info_enable"
#define KEY_HUD_UPDATE_PERIOD "amx_incom_hud_info_update_period"
#define KEY_HUD_COLOR         "amx_incom_hud_info_color"

#define DEFAULT_ENABLE            "1"
#define DEFAULT_HUD_UPDATE_PERIOD "2.0"
#define DEFAULT_HUD_COLOR         "100100100"

new g_Enabled;
new g_UpdatePeriod;
new g_HudColor;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("incom_hud_info.txt")

    register_clcmd("joinclass", "OnAgentChoose");
}

new hudMessageSyncObj;

new Float:hudUpdatePeriod;
new Float:hudColor[3];
new hudMessage[256];

new g_HudInfoTaskOffset = 10000

public plugin_cfg()
{
    g_Enabled      = create_cvar(KEY_ENABLE, DEFAULT_ENABLE, _, "Статус плагина^n0 - Отключен^n1 - Включен", true, 0.0, true, 1.0);
    g_UpdatePeriod = create_cvar(KEY_HUD_UPDATE_PERIOD, DEFAULT_HUD_UPDATE_PERIOD, _, "Период отображения информации на экране клиента", true, 0.5, true, 120.0);
    g_HudColor     = create_cvar(KEY_HUD_COLOR, DEFAULT_HUD_COLOR, _, "Цвет HUD сообщения")

    AutoExecConfig(true, "incom_hud_info");

    hudMessageSyncObj = CreateHudSyncObj();

    hudUpdatePeriod = get_pcvar_float(g_UpdatePeriod)

    new hudColorStr[32];
    get_pcvar_string(g_HudColor, hudColorStr, charsmax(hudColorStr));

    ParseColor_RGB(hudColorStr, hudColor);

    new len;
    len = formatex(hudMessage,charsmax(hudMessage),"%L", LANG_PLAYER, "MAIN_MESSAGE");
    len = formatex(hudMessage[len],charsmax(hudMessage) - len,"^n%L", LANG_PLAYER, "SECONDARY_MESSAGE");
}

public OnAgentChoose(playerId)
{
    if (get_pcvar_num(g_Enabled))
    {
        new taskId = g_HudInfoTaskOffset + playerId;
        if (task_exists(taskId))
        {
            return;
        }

        new playerData[1];
        playerData[0] = playerId;

        set_task(hudUpdatePeriod, "ShowHudTask", taskId, playerData, sizeof(playerData), .flags ="b")
    }
}

public ShowHudTask(playerData[])
{
    if (get_pcvar_num(g_Enabled))
    {
        new playerId = playerData[0]

        if (hudMessageSyncObj != -1)
        {
            ClearSyncHud(playerId, hudMessageSyncObj);
        }

        set_hudmessage(
            floatround(hudColor[0]),
            floatround(hudColor[1]),
            floatround(hudColor[2]),
            -1.0, 0.01, 0, .holdtime = hudUpdatePeriod
        )

        ShowSyncHudMsg(playerId, hudMessageSyncObj, hudMessage);
    }
}
