#include <amxmodx>
#include <reapi>

#define PLUGIN  "Incomsystem music"
#define VERSION "5.0"
#define AUTHOR  "Tonitaga"

new amx_incom_music_enable;
new amx_incom_music_type;
new amx_incom_music_request_timeout;
new amx_incom_music_request_enable;

#define ADMIN_FLAG ADMIN_IMMUNITY

#define MUSIC_COMMAND_SAY           "say /music"
#define MUSIC_COMMAND_SAY_TEAM      "say_team /music"
#define MUSIC_STOP_COMMAND_SAY      "say /stop_music"
#define MUSIC_STOP_COMMAND_SAY_TEAM "say_team /stop_music"

new g_SongRequested = false;
new g_SongRequestCounter = 0;
new g_SongRequestMenuOnHud = false;

new g_CurrentMusicPackId = -1;

new const g_SondRequestTaskId = 20000;
new const g_MenuDestroyTaskId = 20500;

// Идентификаторы секций
enum Sections {
    MUSIC_NONE_SECTION,
    MUSIC_PACK_SECTION,
    MUSIC_ROUNDEND_SECTION,
    MUSIC_SONG_REQUEST_SECTION
};

#define MAX_STR_LENGTH 256

// Текущая обрабатываемая секция
new Sections:g_CurrentIniSection = MUSIC_NONE_SECTION;
new g_CurrentSectionName[MAX_STR_LENGTH]

// Динамические массивы для звуков и их названий
new Array:g_SongRequestSounds;
new Array:g_SongRequestSoundNames;
new Array:g_RoundendSounds;
new Array:g_RoundendSoundNames;

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    register_logevent("round_end", 2, "1=Round_End")

    register_clcmd(MUSIC_COMMAND_SAY, "ShowAdminMusicMenu")
    register_clcmd(MUSIC_COMMAND_SAY_TEAM, "ShowAdminMusicMenu")
    register_clcmd(MUSIC_STOP_COMMAND_SAY, "HandleStopSound")
    register_clcmd(MUSIC_STOP_COMMAND_SAY_TEAM, "HandleStopSound")

    register_dictionary("incom_music.txt")
}

public plugin_cfg()
{
    bind_pcvar_num(
        create_cvar(
            "amx_incom_music_enable", "1",
            .has_min = true, .min_val = 0.0,
            .has_max = true, .max_val = 1.0,
            .description = "Статус плагина^n\
                            0 - Отключен^n\
                            1 - Включен"
        ),
        amx_incom_music_enable
    );

    bind_pcvar_num(
        create_cvar(
            "amx_incom_music_type", "1",
            .has_min = true, .min_val = 1.0,
            .has_max = true, .max_val = 2.0,
            .description = "Тип музыки^n\
                            1 - Incomsystem [Default]^n\
                            2 - Incomsystem [XMas]"
        ),
        amx_incom_music_type
    );

    bind_pcvar_num(
        create_cvar(
            "amx_incom_music_request_timeout", "60",
            .has_min = true, .min_val = 30.0,
            .has_max = true, .max_val = 180.0,
            .description = "Максимальное время ожидания между двумя заказами песен"
        ),
        amx_incom_music_request_timeout
    );

    bind_pcvar_num(
        create_cvar(
            "amx_incom_music_request_enable", "1",
            .has_min = true, .min_val = 0.0,
            .has_max = true, .max_val = 1.0,
            .description = "Возможность заказать песню^n\
                            0 - Отключен^n\
                            1 - Включен"
        ),
        amx_incom_music_request_enable
    );

    AutoExecConfig();
}

public plugin_precache()
{
    CreateArrays();
    LoadMusicConfig();
}

public plugin_end()
{
	DestroyArrays();
}

stock CreateArrays()
{
    g_SongRequestSounds = ArrayCreate(MAX_STR_LENGTH);
    g_SongRequestSoundNames = ArrayCreate(MAX_STR_LENGTH);
    g_RoundendSounds = ArrayCreate(MAX_STR_LENGTH);
    g_RoundendSoundNames = ArrayCreate(MAX_STR_LENGTH);
}

stock DestroyArrays()
{
	if (g_SongRequestSounds != Invalid_Array)
		ArrayDestroy(g_SongRequestSounds);

	if (g_SongRequestSoundNames != Invalid_Array)
		ArrayDestroy(g_SongRequestSoundNames);

	if (g_RoundendSounds != Invalid_Array)
		ArrayDestroy(g_RoundendSounds);

	if (g_RoundendSoundNames != Invalid_Array)
		ArrayDestroy(g_RoundendSoundNames);
}

stock LoadMusicConfig()
{
    new INIParser:parser = INI_CreateParser();

    INI_SetParseEnd(parser, "OnIniParseEnd");
    INI_SetReaders(parser, "OnIniKeyValue", "OnIniNewSection");

    new bool:result = INI_ParseFile(parser, "addons/amxmodx/configs/incom_music.ini");
    if(!result)
    {
        server_print("[IncomMusic] Failed to read ini file")
    }

    INI_DestroyParser(parser);
}

public OnIniNewSection(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket, bool:extra_tokens, curtok, any:data)
{
    if(equal(section, "music_pack")) 
    {
        g_CurrentIniSection = MUSIC_PACK_SECTION;
        g_CurrentMusicPackId = -1;
    }
    else if(strfind(section, "request_songs_") != -1) 
    {
        g_CurrentIniSection = MUSIC_SONG_REQUEST_SECTION;
    }
    else if(strfind(section, "roundend_") != -1) 
    {
        g_CurrentIniSection = MUSIC_ROUNDEND_SECTION;
    }
    else 
    {
        g_CurrentIniSection = MUSIC_NONE_SECTION;
    }

    copy(g_CurrentSectionName, charsmax(g_CurrentSectionName), section);
    return true;
}

public OnIniKeyValue(INIParser:handle, const key[], const value[], bool:invalid_tokens, bool:equal_token, bool:quotes, curtok, any:data)
{
    new quotelessKey[MAX_STR_LENGTH], quotelessValue[MAX_STR_LENGTH];

    copy(quotelessKey, charsmax(quotelessKey), key);
    copy(quotelessValue, charsmax(quotelessValue), value);

    remove_quotes(quotelessKey);
    remove_quotes(quotelessValue);

    switch(g_CurrentIniSection)
    {
        case MUSIC_PACK_SECTION:
        {
            if(equal(quotelessKey, "music_pack"))
            {
                g_CurrentMusicPackId = str_to_num(quotelessValue);
            }
        }
        case MUSIC_SONG_REQUEST_SECTION:
        {
            new musicId = -1;
            if(strfind(g_CurrentSectionName, "request_songs_") != -1)
            {
                new idStr[8];
                copy(idStr, charsmax(idStr), g_CurrentSectionName[strlen("request_songs_")]);
                musicId = str_to_num(idStr);
            }
            
            if(musicId == g_CurrentMusicPackId)
            {
                ArrayPushString(g_SongRequestSounds, quotelessValue);
                ArrayPushString(g_SongRequestSoundNames, quotelessKey);
            }
        }
        
        case MUSIC_ROUNDEND_SECTION:
        {
            new musicId = -1;
            if(strfind(g_CurrentSectionName, "roundend_") != -1)
            {
                new idStr[8];
                copy(idStr, charsmax(idStr), g_CurrentSectionName[strlen("roundend_")]);
                musicId = str_to_num(idStr);
            }
            
            if(musicId == g_CurrentMusicPackId)
            {
                ArrayPushString(g_RoundendSounds, quotelessValue);
                ArrayPushString(g_RoundendSoundNames, quotelessKey);
            }
        }
    }
    
    return true;
}

public OnIniParseEnd(INIParser:handle, bool:halted, any:data)
{
    if(!halted && g_CurrentMusicPackId != -1)
    {
        new sound[MAX_STR_LENGTH];

        new songRequestCount = ArraySize(g_SongRequestSounds);
        for (new i = 0; i < songRequestCount; i++)
        {
            ArrayGetString(g_SongRequestSounds, i, sound, charsmax(sound));
            precache_sound(sound);
        }

        new roundEndCount = ArraySize(g_RoundendSounds);
        for (new i = 0; i < roundEndCount; i++)
        {
            ArrayGetString(g_RoundendSounds, i, sound, charsmax(sound));
            precache_sound(sound);
        }
        
        server_print("[IncomMusic] MusicPack: <%d>, SongRequests: <%d>, RoundEnds: <%d>"
            , g_CurrentMusicPackId
            , songRequestCount
            , roundEndCount
        );
    }
}

public client_connect(playerId)
{
    if (amx_incom_music_enable)
    {
        StopSound(playerId);

        new size = ArraySize(g_SongRequestSounds);
        if (size <= 0)
        {
            return;
        }

        PlaySound(playerId, g_SongRequestSounds, 0)
    }
}

public client_disconnected(playerId)
{
    StopSound(playerId);
}

public client_putinserver(playerId)
{
    StopSound(playerId);
}

public round_end()
{
    if (amx_incom_music_enable)
    {
        // Пока песня запрошена, то песни конца раунда не будет
        if (IsSongAlreadyRequested())
        {
            return;
        }

        // Останавливаем музыку у всех
        StopSound(0);

        // Запускаем новую через 0.25с
        set_task(0.25, "PlayRoundEndSound")
    }
}

public PlayRoundEndSound()
{
    new size = ArraySize(g_RoundendSounds);
    if (size > 0)
    {
        PlaySound(0, g_RoundendSounds, random_num(0, size - 1))
    }
}

public PlaySound(playerId, Array:arr, soundId)
{
    new sound[MAX_STR_LENGTH];
    ArrayGetString(arr, soundId, sound, charsmax(sound));

    new command[MAX_STR_LENGTH + 32];
    formatex(command, charsmax(command), "mp3 play sound/%s", sound);

    client_cmd(playerId, command);
}

public HandleStopSound(playerId)
{
    if (get_user_flags(playerId) & ADMIN_FLAG)
    {
        StopSound(0);

        if (!IsSongAlreadyRequested())
        {
            return;
        }

        SetSongRequested(false);

        new name[128];
        get_user_name(playerId, name, charsmax(name));

        client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "ADMIN_STOP_SOUND", name);
    }
    else
    {
        StopSound(playerId);
        client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "PLAYER_STOP_SOUND");
    }
}

stock StopSound(playerId)
{
    client_cmd(playerId, "stopsound; mp3 stop");
}

stock IsSongRequestMenuOnHud()
{
    return g_SongRequestMenuOnHud;
}

stock SongRequestMenuOnHud(value)
{
    g_SongRequestMenuOnHud = value;
}

stock IsSongAlreadyRequested()
{
    return g_SongRequested;
}

stock SetSongRequested(value)
{
    new data[1];

    data[0] = value;
    SetSongRequestedData(data);
}

public SetSongRequestedData(data[])
{
    new value = data[0];

    g_SongRequested = value;
    if (task_exists(g_SondRequestTaskId))
    {
        remove_task(g_SondRequestTaskId);
    }

    if (value)
    {
        g_SongRequestCounter = amx_incom_music_request_timeout;
        set_task(1.0, "PollSongRequest", g_SondRequestTaskId, .flags="b");
        return;
    }
}

public PollSongRequest()
{
    --g_SongRequestCounter;
    if (g_SongRequestCounter <= 0)
    {
        client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "SOUND_AVAILABLE");
        SetSongRequested(false);
        return;
    }
}

public pointBonus_RequestSong(playerId)
{
    if (!amx_incom_music_request_enable)
    {
        client_print_color(playerId, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "REQUEST_DISABLED");
        return false;
    }

    if (IsSongAlreadyRequested())
    {
        client_print_color(playerId, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "SOUND_NOT_AVAILABLE", g_SongRequestCounter);
        return false;
    }

    if (IsSongRequestMenuOnHud())
    {
        client_print_color(playerId, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "SOMEONE_SELECTING_SOUND");
        return false;
    }

    ShowMusicRequestMenu(playerId);
    return true;
}

stock MakeInactiveMenuCanceler(playerId, Float:timeout)
{
    set_task(timeout, "InactiveMenuCanceler", g_MenuDestroyTaskId + playerId)
}

stock RemoveInvactiveMenuCanceler(playerId)
{
    remove_task(g_MenuDestroyTaskId + playerId);
}

public InactiveMenuCanceler(taskId)
{
    new playerId = taskId - g_MenuDestroyTaskId;

    menu_cancel(playerId);
    show_menu(playerId, 0, "^n", 1);

    SongRequestMenuOnHud(false);

    client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "SOUND_AVAILABLE");
}

public ShowMenu(playerId, const callback[])
{
    SongRequestMenuOnHud(true);

    new menu = menu_create("\y>>>>> \rIncomsystem Music Menu \y<<<<<^n \dby >>\rTonitaga\d<<", callback)

    new data[8];
    new menuItem[MAX_STR_LENGTH], soundName[MAX_STR_LENGTH];

    new soundsCount = ArraySize(g_SongRequestSounds);
    for (new i = 0; i < soundsCount; i++)
    {
        num_to_str(i, data, charsmax(data));

        ArrayGetString(g_SongRequestSoundNames, i, soundName, charsmax(soundName))
        if (equal(soundName, ""))
        {
            continue;
        }

        formatex(menuItem, charsmax(menuItem), "\y%s", soundName);
        menu_additem(menu, menuItem, data, 0)
    }
    
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
    menu_display(playerId, menu, 0)

    MakeInactiveMenuCanceler(playerId, 15.0);
}

public ShowAdminMusicMenu(playerId)
{
    if (get_user_flags(playerId) & ADMIN_FLAG)
    {
        ShowMusicRequestMenu(playerId);
    }
}

public ShowMusicRequestMenu(playerId)
{
    ShowMenu(playerId, "MenuCase");
}

public MenuCase(playerId, menu, item)
{
    SongRequestMenuOnHud(false);
    RemoveInvactiveMenuCanceler(playerId);

    if(item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    return CommonMenuCase(playerId, menu, item);
}

public CommonMenuCase(playerId, menu, item)
{
    SetSongRequested(true);

    new data[6], name[128];
    new access, callback;

    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)
    new soundId = str_to_num(data)

    StopSound(0);
    PlaySound(0, g_SongRequestSounds, soundId);

    get_user_name(playerId, name, charsmax(name));

    new soundName[MAX_STR_LENGTH];
    ArrayGetString(g_SongRequestSoundNames, soundId, soundName, charsmax(soundName))

    client_print_color(0, print_team_default, "[%L] %L", LANG_PLAYER, "INCOM_MUSIC", LANG_PLAYER, "SOUND_REQUESTED", name, soundName);
    menu_destroy(menu)
    return PLUGIN_HANDLED
}