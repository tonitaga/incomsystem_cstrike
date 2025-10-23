#include <amxmodx>

#define PLUGIN  "Incomsystem music"
#define VERSION "2.1"
#define AUTHOR  "Tonitaga"

public plugin_init() 
{ 
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    // Используем logevent вместо SendAudio
    register_logevent("round_end", 2, "1=Round_End")

    register_clcmd("joinclass", "OnAgentChoose");
    
    // Блокируем стандартные звуки через SendAudio
    register_event("SendAudio", "block_standard_sounds", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
}

public block_standard_sounds()
{
    return PLUGIN_HANDLED // Полностью блокируем стандартные звуки
}

public client_connect(playerId)
{
    client_cmd(playerId, "spk incom/greeting")
    return 0;
}

public OnAgentChoose(playerId)
{
    client_cmd(playerId,"stopsound")
}

public round_end()
{
    new rand = random_num(1,10)
    
    client_cmd(0,"stopsound")
    set_task(0.5, "play_round_sound", rand)
}

public play_round_sound(sound_id)
{
    switch(sound_id)
    {
        case 1:  client_cmd(0,"spk incom/roundend1")
        case 2:  client_cmd(0,"spk incom/roundend2")
        case 3:  client_cmd(0,"spk incom/roundend3")
        case 4:  client_cmd(0,"spk incom/roundend4")
        case 5:  client_cmd(0,"spk incom/roundend5")
        case 6:  client_cmd(0,"spk incom/roundend6")
        case 7:  client_cmd(0,"spk incom/roundend7")
        case 8:  client_cmd(0,"spk incom/roundend8")
        case 9:  client_cmd(0,"spk incom/roundend9")
        case 10: client_cmd(0,"spk incom/roundend1_fonk_montagem_xonada")
    }
}

public plugin_precache()
{
    precache_sound("incom/greeting.wav")
    precache_sound("incom/roundend1.wav")
    precache_sound("incom/roundend2.wav")
    precache_sound("incom/roundend3.wav")
    precache_sound("incom/roundend4.wav")
    precache_sound("incom/roundend5.wav")
    precache_sound("incom/roundend6.wav")
    precache_sound("incom/roundend7.wav")
    precache_sound("incom/roundend8.wav")
    precache_sound("incom/roundend9.wav")
    precache_sound("incom/roundend1_fonk_montagem_xonada.wav")
    
    return PLUGIN_CONTINUE
}