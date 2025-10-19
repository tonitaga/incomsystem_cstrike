#include <amxmodx>
#include <parse_color>

#define PLUGIN  "Incomsystem HUD Info"
#define VERSION "1.0"
#define AUTHOR  "Tonitaga"

#define KEY_ENABLE                      "incom_hud_info_enable"
#define KEY_MESSAGE_HOLD_TIME           "incom_hud_info_hold_time"
#define KEY_MESSAGE_SHOW_PERIOD         "incom_hud_info_show_period"
#define KEY_MAIN_MESSAGE_HUD_COLOR      "incom_hud_info_main_message_color"
#define KEY_SECONDARY_MESSAGE_HUD_COLOR "incom_hud_info_secondary_message_color"

#define DEFAULT_ENABLE                      "1"
#define DEFAULT_MESSAGE_HOLD_TIME           "5.0"
#define DEFAULT_MESSAGE_SHOW_PERIOD         "60.0"
#define DEFAULT_MAIN_MESSAGE_HUD_COLOR      "177018038"
#define DEFAULT_SECONDARY_MESSAGE_HUD_COLOR "060060060"

new g_Enabled;
new g_MessageHoldTime;
new g_MessageShowPeriod;
new g_MainMessageHudColor;
new g_SecondaryMessageHudColor;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("incom_hud_info.txt")

    register_clcmd("joinclass", "OnAgentChoose");
}

new g_HudInfoTaskOffset = 10000

public plugin_cfg()
{
    g_Enabled                  = create_cvar(KEY_ENABLE, DEFAULT_ENABLE, _, "Статус плагина^n0 - Отключен^n1 - Включен", true, 0.0, true, 1.0);
    g_MessageHoldTime          = create_cvar(KEY_MESSAGE_HOLD_TIME, DEFAULT_MESSAGE_HOLD_TIME, _, "Время отображения информации на экране клиента", true, 1.0, true, 30.0);
    g_MessageShowPeriod        = create_cvar(KEY_MESSAGE_SHOW_PERIOD, DEFAULT_MESSAGE_SHOW_PERIOD, _, "Период отображения информации на экране клиента", true, 1.0, true, 120.0);
    g_MainMessageHudColor      = create_cvar(KEY_MAIN_MESSAGE_HUD_COLOR, DEFAULT_MAIN_MESSAGE_HUD_COLOR, _, "Цвет основного HUD сообщения")
    g_SecondaryMessageHudColor = create_cvar(KEY_SECONDARY_MESSAGE_HUD_COLOR, DEFAULT_SECONDARY_MESSAGE_HUD_COLOR, _, "Цвет дополнительного HUD сообщения")

    AutoExecConfig(true, "incom_hud_info");
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

        new Float:repeatTime = get_pcvar_float(g_MessageShowPeriod)
        set_task(repeatTime, "ShowHudTask", playerId, playerData, sizeof(playerData), .flags ="b")
    }
}

public ShowHudTask(playerData[])
{
    new playerId = playerData[0]

    new hudColorStr[32], Float:hudColor[3];
    get_pcvar_string(g_MainMessageHudColor, hudColorStr, charsmax(hudColorStr));
    ParseColor_RGB(hudColorStr, hudColor);

    new Float:messageHoldTime = get_pcvar_float(g_MessageHoldTime)

    set_hudmessage(
        floatround(hudColor[0]),
        floatround(hudColor[1]),
        floatround(hudColor[2]),
        -1.0, 0.01, 0, 6.0, messageHoldTime, 0.1, 0.5
    )

    show_hudmessage(playerId, "%L", LANG_PLAYER, "MAIN_MESSAGE")

    get_pcvar_string(g_SecondaryMessageHudColor, hudColorStr, charsmax(hudColorStr));
    ParseColor_RGB(hudColorStr, hudColor);

    set_hudmessage(
        floatround(hudColor[0]),
        floatround(hudColor[1]),
        floatround(hudColor[2]),
        -1.0, 0.03, 0, 6.0, messageHoldTime, 0.1, 0.5
    )
    show_hudmessage(playerId, "%L", LANG_PLAYER, "SECONDARY_MESSAGE")
}
