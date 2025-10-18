#if defined _chatmanager_included
	#endinput
#endif
#define _chatmanager_included

forward cm_player_send_message(id, message[], is_team_msg);

native cm_set_player_message(const new_message[]);
native cm_set_prefix(const player, const prefix[]);
native cm_get_prefix(const player, dest[], const length);
native cm_reset_prefix(const player);
