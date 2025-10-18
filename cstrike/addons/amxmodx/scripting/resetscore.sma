#include <amxmodx>
#include <reapi>

#define PLUGIN     "resetscore(ReAPI)"
#define VERSION "1.0"
#define AUTHOR  "Phantom"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_clcmd("say /rs", "resetscore"); register_clcmd("say_team /rs", "resetscore");
}

public resetscore(id) {
    if(!is_user_connected(id)) return;

    set_entvar(id, var_frags, 0.0);
    set_member(id, m_iDeaths, 0);

    message_begin(MSG_ONE_UNRELIABLE, 76, .player = id);
    write_byte(id);
    write_string("^1Счет обнулен");
    client_cmd(id, "spk buttons/blip1.wav");
    message_end();

    message_begin(MSG_ALL, 85);
    write_byte(id);
    write_short(0); write_short(0); write_short(0); write_short(0);
    message_end();
}