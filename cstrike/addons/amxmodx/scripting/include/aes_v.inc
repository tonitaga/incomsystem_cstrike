#define AES_MAX_LEVEL_LENGTH 64

enum _:
{
	AES_RT_NO,
	AES_RT_YES,
	AES_RT_LEVEL_DOWN,
	AES_RT_LEVEL_UP
};

/**
* Array structure for get stats with aes_find_stats_thread native
*/
enum _:aes_stats_struct
{
	AES_S_NAME[32],
	AES_S_STEAMID[30],
	AES_S_IP[16],

	Float:AES_S_EXP,
	AES_S_LEVEL,
	AES_S_BONUS,

	AES_S_ID
};

/**
* Returns player experience
*
* @param player			player id
*
* @return				player experience or -1.0 if player not tracked yet
*/
native Float:aes_get_player_exp(player);

/**
* Sets player experience
*
* @param player			player id
* @param exp			experience value
* @param no_forward		dont trigger forward functions on level up or level down
* @param force			force even if track paused
*
* @return				AES_RT_NO on track pause or player not tracked yet
*						AES_RT_YES on success
*						AES_RT_LEVLE_DOWN on level down
*						AES_RT_LEVEL_UP on level up
*/
native aes_set_player_exp(player,Float:exp,bool:no_forward = false,bool:force = false);

/**
* Returns player required experience to next level
* @param player			player id
*
* @return - required experience value
*/
native Float:aes_get_player_reqexp(player);

/**
* Returns player bonus points
*
* @param player			player id
*
* @return				player bonus points or -1 if player
*/
native aes_get_player_bonus(player);

/**
* Sets player bonus points
*
* @param player			player id
* @param bonus			bonus value
* @param force			force even if track paused
*
* @return				AES_RT_NO on track pause or player not tracked yet
*						AES_RT_YES on success
*/
native aes_set_player_bonus(player,bonus,bool:force = false);

/**
* Returns current player level
*
* @param player			player id
*
* @return				current player level or -1 if player not tracked yet
*/
native aes_get_player_level(player);

/**
* Sets player level
*
* @param player			player id
* @param level			level
* @param force			force even if track paused
*
* @return				AES_RT_NO on track pause or player not tracked yet
*						AES_RT_YES on success
*/
native aes_set_player_level(player,level,bool:force = false);

/**
* Returns maximum level
*
* @return				level
*/
native aes_get_max_level();

/**
* Returns level name for level num.
*
* @param level			level number
* @param level[]		Buffer to copy level name output to
* @param len			Maximum size of buffer
* @param idLang			language id
*
* @return 				len
*/
native aes_get_level_name(level,level_name[],len,idLang = LANG_SERVER);

/**
* Returns level for experience
*
* @param exp			experience value
*
* @return				level num or -1 of fail
*/
native aes_get_exp_level(Float:exp);

/**
* Returns required experience to pass level
*
* @param lvl			level
*
* @return				required experience value or -1.0 on fail
*/
native Float:aes_get_level_reqexp(level);

/**
* Thread search for aes stats witch given array track_ids
*
* @param id				player id
* @param track_ids		dynamic array with track ids for search
* @param callback		your callback function
*						public my_callback(id,Array:aes_stats,stats_data[])
* @param data[]			custom data
* @param data_size		custom data size
*
* @return				true or false
*/
native aes_find_stats_thread(id = 0,Array:track_ids,callback[],data[] = "",datasize = 0);

/**
* Called when player open bonus menu.
*
* @param id				player id
*
* @return      			PLUGIN_CONTINUE to let the player open menu
*              			PLUGIN_HANDLED or higher to stop
*/
forward aes_on_anew_command(id)

/**
* Called when player data is loaded.
*
* @param id				player id
*
* @noreturn
*/
forward aes_player_connect(id)

/**
* Called on player level up.
*
* @param id				player id
* @param new_level		new level
* @param old_level		old level
*
* @noreturn
*/
forward aes_player_levelup(id,new_level,old_level);

/**
* Called on player level down.
*
* @param id				player id
* @param new_level		new level
* @param old_level		old level
*
* @noreturn
*/
forward aes_player_leveldown(id,new_level,old_level);

#define aes_add_player_exp_f(%0,%1) aes_set_player_exp(%0,aes_get_player_exp(%0) + %1)
#define aes_add_player_bonus_f(%0,%1) aes_set_player_bonus(%0,aes_get_player_bonus(%0) + %1)
