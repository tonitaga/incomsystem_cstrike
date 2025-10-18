//
//	Advanced Experience System
//	by serfreeman1337	http://gf.hldm.org/
//

//
// AES 0.4 BACKWARD SUPPORT
//

enum _: {
	AES_ST_EXP,
	AES_ST_LEVEL,
	AES_ST_BONUSES,
	AES_ST_NEXTEXP,

	AES_ST_END
}

native aes_get_max_level()
native aes_get_level_name(level,level_name[],len,idLang = LANG_SERVER)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_add_player_exp_f() instead.
#endif
native aes_add_player_exp(id,exp,override = 0)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_add_player_bonus_f() instead.	
#endif
native aes_add_player_bonus(id,bonus)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_get_player_*() instead.
#endif
native aes_get_player_stats(id,data[4])

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_set_player_*() instead.
#endif
native aes_set_player_stats(id,stats[3])

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_get_exp_level() instead.
#endif
native aes_get_level_for_exp(exp)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_get_level_reqexp() instead.
#endif
native aes_get_exp_to_next_level(lvl)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_find_stats_thread() instead.
#endif
native Array:aes_get_stats(Array:trackIds)

#if AMXX_VERSION_NUM >= 183
	#pragma deprecated Use aes_get_exp_for_stats_f() instead.
#endif
native aes_get_exp_for_stats(stats[8],stats2[4])

forward aes_on_anew_command(id)
forward aes_player_levelup(id,new_level,old_level)
forward aes_player_leveldown(id,new_level,old_level)