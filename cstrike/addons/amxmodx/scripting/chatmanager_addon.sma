/**
 * Credits: Subb98.
 */
#include <amxmodx>
#include <regex>

#define PLUGIN "Chat Manager: Addon"
#define VERSION "0.0.4-70"
#define AUTHOR "Mistrick"

#pragma semicolon 1

enum
{
    MESSAGE_IGNORED,
    MESSAGE_CHANGED,
    MESSAGE_BLOCKED
};

forward cm_player_send_message(id, message[], team_chat);
native cm_set_player_message(message[]);

#define FUNCTION_BLACK_LIST
//#define FUNCTION_BLOCK_IDENTICAL_MSG
#define FUNCTION_BLOCK_ADVERTISING
#define FUNCTION_BLOCK_CAPS

// TODO: Remove this func from main plugin
//#define FUNCTION_LOG_MESSAGES

#define MAX_IDENTICAL_MESSAGES 3
#define MIN_MESSAGE_DELAY 0.1 // seconds
#define MAX_WARNINGS_TO_BLOCK_CHAT 5
#define BLOCK_CHAT_TIME 15.0 // seconds
#define MAX_CAPS_PERCENT 90

#define IP_LEN 22
#define DOMAIN_LEN 32

new Float:g_fLastMsgTime[33];
new g_iWarnings[33];
new Float:g_fBlockTime[33];

#if defined FUNCTION_BLACK_LIST
new const FILE_BLACK_LIST[] = "chatmanager_blacklist.ini";
new Array:g_aBlackList;
new g_iBlackListSize;
#endif // FUNCTION_BLACK_LIST

#if defined FUNCTION_BLOCK_IDENTICAL_MSG
new g_sLastMessage[33][128];
new g_iRepeatWarn[33];
#endif // FUNCTION_BLOCK_IDENTICAL_MSG

#if defined FUNCTION_BLOCK_ADVERTISING
new const FILE_WHITE_LIST[] = "chatmanager_whitelist.ini";
new Array:g_aWhiteListIp;
new Array:g_aWhiteListDomain;
new g_iWhiteListIpSize;
new g_iWhiteListDomainSize;
new Regex:g_rIpPattern;
new Regex:g_rDomainPattern;
#endif // FUNCTION_BLOCK_ADVERTISING

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_cfg()
{
    #if defined FUNCTION_BLACK_LIST
    LoadBlackList();
    #endif // FUNCTION_BLACK_LIST

    #if defined FUNCTION_BLOCK_ADVERTISING
    new error[2], ret;
    g_rIpPattern = regex_compile("(?:\s*\d+\s*\.){3}", ret, error, charsmax(error));
    g_rDomainPattern = regex_compile("(?:[A-z]){2,}\.(?:[A-z]){2,}", ret, error, charsmax(error));
    LoadWhiteList();
    #endif // FUNCTION_BLOCK_ADVERTISING
}

#if defined FUNCTION_BLACK_LIST
LoadBlackList()
{
    g_aBlackList = ArrayCreate(64, 1);

    new file_path[128]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
    format(file_path, charsmax(file_path), "%s/%s", file_path, FILE_BLACK_LIST);

    new file = fopen(file_path, "rt");

    if(file)
    {
        new buffer[64], wchar[64];
        while(!feof(file))
        {
            fgets(file, buffer, charsmax(buffer));
            trim(buffer); remove_quotes(buffer);

            if(!buffer[0] || buffer[0] == ';' || strlen(buffer) < 3) continue;

            normalize_string(buffer);
            multibyte_to_wchar(buffer, wchar);
            wchar_tolower_rus(wchar);
            wchar_to_multibyte(wchar, buffer);

            ArrayPushString(g_aBlackList, buffer);
            g_iBlackListSize++;
        }
        fclose(file);
    }
}
#endif // FUNCTION_BLACK_LIST

#if defined FUNCTION_BLOCK_ADVERTISING
LoadWhiteList()
{
    g_aWhiteListIp = ArrayCreate(IP_LEN, 1);
    g_aWhiteListDomain = ArrayCreate(DOMAIN_LEN, 1);

    new file_path[128]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
    format(file_path, charsmax(file_path), "%s/%s", file_path, FILE_WHITE_LIST);

    new file = fopen(file_path, "rt");

    enum
    {
        READ_NON,
        READ_DOMAIN,
        READ_IP
    };

    if(file)
    {
        new buffer[64], type = READ_NON;
        while(!feof(file))
        {
            fgets(file, buffer, charsmax(buffer));
            trim(buffer); remove_quotes(buffer);

            if(!buffer[0] || buffer[0] == ';') continue;

            if(contain(buffer, "[ips]") > -1)
            {
                type = READ_IP;
                continue;
            }
            if(contain(buffer, "[domains]") > -1)
            {
                type = READ_DOMAIN;
                continue;
            }

            if(type)
            {
                ArrayPushString(type == READ_IP ? g_aWhiteListIp : g_aWhiteListDomain, buffer);
            }
        }
        fclose(file);

        g_iWhiteListIpSize = ArraySize(g_aWhiteListIp);
        g_iWhiteListDomainSize = ArraySize(g_aWhiteListDomain);
    }
}
#endif // FUNCTION_BLOCK_ADVERTISING


public client_connect(id)
{
    g_fLastMsgTime[id] = 0.0;
    g_iWarnings[id] = 0;
    g_fBlockTime[id] = 0.0;

    #if defined FUNCTION_BLOCK_IDENTICAL_MSG
    g_iRepeatWarn[id] = 0;
    #endif // FUNCTION_BLOCK_IDENTICAL_MSG
}

public cm_player_send_message(id, message[])
{
    new Float:gametime = get_gametime();

    if(gametime < g_fBlockTime[id])
    {
        return MESSAGE_BLOCKED;
    }

    if(gametime < g_fLastMsgTime[id] + MIN_MESSAGE_DELAY)
    {
        client_print(id, print_chat, "[CMA] Stop spamming!");
        add_warning(id);
        return MESSAGE_BLOCKED;
    }
    g_fLastMsgTime[id] = gametime;

    #if defined FUNCTION_BLOCK_IDENTICAL_MSG
    if(equal(message, g_sLastMessage[id]))
    {
        if(++g_iRepeatWarn[id] >= MAX_IDENTICAL_MESSAGES)
        {
            client_print(id, print_chat, "[CMA] Stop spamming! Identical msg.");
            add_warning(id);
            return MESSAGE_BLOCKED;
        }
    }
    else if(g_iRepeatWarn[id])
    {
        g_iRepeatWarn[id]--;
    }
    copy(g_sLastMessage[id], charsmax(g_sLastMessage[]), message);
    #endif // FUNCTION_BLOCK_IDENTICAL_MSG

    #if defined FUNCTION_BLOCK_CAPS
    static _wchar_msg[128];

    normalize_string(message);
    multibyte_to_wchar(message, _wchar_msg);

    new i, uppercase;
    while(_wchar_msg[i])
    {
        if(wchar_is_uppercase(_wchar_msg[i]))
            uppercase++;
        i++;
    }

    if(uppercase * 100.0 / i >= MAX_CAPS_PERCENT)
    {
        client_print(id, print_chat, "[CMA] Stop using caps!");
        add_warning(id);
        return MESSAGE_BLOCKED;
    }
    #endif // FUNCTION_BLOCK_CAPS

    #if defined FUNCTION_BLOCK_ADVERTISING
    static temp[128];
    new ret;
    // TODO: Add white list
    if(regex_match_c(message, g_rIpPattern, ret))
    {
        copy(temp, charsmax(temp), message);
        for(new i, whiteip[IP_LEN]; i < g_iWhiteListIpSize; i++)
        {
            ArrayGetString(g_aWhiteListIp, i, whiteip, charsmax(whiteip));
            while(replace(temp, charsmax(temp), whiteip, "")){}
        }

        if(regex_match_c(temp, g_rIpPattern, ret))
        {
            client_print(id, print_chat, "[CMA] Founded ip pattern!");
            add_warning(id);
            return MESSAGE_BLOCKED;
        }
    }
    if(regex_match_c(message, g_rDomainPattern, ret))
    {
        copy(temp, charsmax(temp), message);
        for(new i, whitedomain[DOMAIN_LEN]; i < g_iWhiteListDomainSize; i++)
        {
            ArrayGetString(g_aWhiteListDomain, i, whitedomain, charsmax(whitedomain));
            while(replace(temp, charsmax(temp), whitedomain, "")){}
        }

        if(regex_match_c(temp, g_rDomainPattern, ret))
        {
            client_print(id, print_chat, "[CMA] Founded domain pattern!");
            add_warning(id);
            return MESSAGE_BLOCKED;
        }
    }
    #endif // FUNCTION_BLOCK_ADVERTISING

    #if defined FUNCTION_BLACK_LIST
    static new_message[128], wchar_msg[128], low_message[128];

    new changed = false;

    copy(new_message, charsmax(new_message), message);
    copy(low_message, charsmax(low_message), message);

    normalize_string(low_message);
    multibyte_to_wchar(low_message, wchar_msg);
    wchar_tolower_rus(wchar_msg);
    wchar_to_multibyte(wchar_msg, low_message);

    for(new i, len, place, word[64]; i < g_iBlackListSize; i++)
    {
        ArrayGetString(g_aBlackList, i, word, charsmax(word));
        len = strlen(word);
        while((place = containi(low_message, word)) > -1)
        {
            changed = true;
            replace_blocked_word(new_message, strlen(new_message), place, len);
            replace_blocked_word(low_message, strlen(low_message), place, len);
        }
    }

    if(changed)
    {
        cm_set_player_message(new_message);
        return MESSAGE_CHANGED;
    }
    #endif // FUNCTION_BLACK_LIST

    return MESSAGE_IGNORED;
}

add_warning(id)
{
    if(++g_iWarnings[id] >= MAX_WARNINGS_TO_BLOCK_CHAT)
    {
        g_fBlockTime[id] = get_gametime() + BLOCK_CHAT_TIME;
        g_iWarnings[id] = 0;
        client_print(id, print_chat, "[CMA] Your chat has been blocked for %.0f seconds!", BLOCK_CHAT_TIME);
    }
    SendAudio(id, "sound/fvox/beep.wav", PITCH_NORM);
}

#if defined FUNCTION_BLACK_LIST
replace_blocked_word(string[], length, start, word_length)
{

    for(new i = start; i < start + 3; i++)
    {
        string[i] = '*';
    }
    if(length > 3)
    {
        new len = start + word_length;
        new diff = word_length - 3;
        while(len <= length)
        {
            string[len - diff] = string[len];
            len++;
        }
    }
}
#endif // FUNCTION_BLACK_LIST

stock normalize_string(str[])
{
    for (new i; str[i] != EOS; i++)
    {
        str[i] &= 0xFF;
    }
}

stock wchar_tolower_rus(str[])
{
    for (new i; str[i] != EOS; i++)
    {
        if(str[i] == 0x401)
        {
            str[i] = 0x451;
        }
        else if(0x410 <= str[i] <= 0x42F)
        {
            str[i] += 0x20;
        }
    }
}

stock wchar_is_uppercase(ch)
{
    if(0x41 <= ch <= 0x5A || ch == 0x401 || 0x410 <= ch <= 0x42F)
    {
        return true;
    }
    return false;
}

// Converts MultiByte (UTF-8) to WideChar (UTF-16, UCS-2)
// Supports only 1-byte, 2-byte and 3-byte UTF-8 (unicode chars from 0x0000 to 0xFFFF), because client can't display 2-byte UTF-16
// charsmax(wcszOutput) should be >= strlen(mbszInput)
stock multibyte_to_wchar(const mbszInput[], wcszOutput[]) {
    new nOutputChars = 0;
    for (new n = 0; mbszInput[n] != EOS; n++) {
        if (mbszInput[n] < 0x80) { // 0... 1-byte ASCII
            wcszOutput[nOutputChars] = mbszInput[n];
        } else if ((mbszInput[n] & 0xE0) == 0xC0) { // 110... 2-byte UTF-8
            wcszOutput[nOutputChars] = (mbszInput[n] & 0x1F) << 6; // Upper 5 bits
            
            if ((mbszInput[n + 1] & 0xC0) == 0x80) { // Is 10... ?
                wcszOutput[nOutputChars] |= mbszInput[++n] & 0x3F; // Lower 6 bits
            } else { // Decode error
                wcszOutput[nOutputChars] = '?';
            }
        } else if ((mbszInput[n] & 0xF0) == 0xE0) { // 1110... 3-byte UTF-8
            wcszOutput[nOutputChars] = (mbszInput[n] & 0xF) << 12; // Upper 4 bits
            
            if ((mbszInput[n + 1] & 0xC0) == 0x80) { // Is 10... ?
                wcszOutput[nOutputChars] |= (mbszInput[++n] & 0x3F) << 6; // Middle 6 bits
                
                if ((mbszInput[n + 1] & 0xC0) == 0x80) { // Is 10... ?
                    wcszOutput[nOutputChars] |= mbszInput[++n] & 0x3F; // Lower 6 bits
                } else { // Decode error
                    wcszOutput[nOutputChars] = '?';
                }
            } else { // Decode error
                wcszOutput[nOutputChars] = '?';
            }
        } else { // Decode error
            wcszOutput[nOutputChars] = '?';
        }
        
        nOutputChars++;
    }
    wcszOutput[nOutputChars] = EOS;
}

// Converts WideChar (UTF-16, UCS-2) to MultiByte (UTF-8)
// Supports only 1-byte UTF-16 (0x0000 to 0xFFFF), because client can't display 2-byte UTF-16
// charsmax(mbszOutput) should be >= wcslen(wcszInput) * 3
stock wchar_to_multibyte(const wcszInput[], mbszOutput[]) {
    new nOutputChars = 0;
    for (new n = 0; wcszInput[n] != EOS; n++) {
        if (wcszInput[n] < 0x80) {
            mbszOutput[nOutputChars++] = wcszInput[n];
        } else if (wcszInput[n] < 0x800) {
            mbszOutput[nOutputChars++] = (wcszInput[n] >> 6) | 0xC0;
            mbszOutput[nOutputChars++] = (wcszInput[n] & 0x3F) | 0x80;
        } else {
            mbszOutput[nOutputChars++] = (wcszInput[n] >> 12) | 0xE0;
            mbszOutput[nOutputChars++] = ((wcszInput[n] >> 6) & 0x3F) | 0x80;
            mbszOutput[nOutputChars++] = (wcszInput[n] & 0x3F) | 0x80;
        }
    }
    mbszOutput[nOutputChars] = EOS;
} 

stock SendAudio(id, audio[], pitch)
{
    static msg_send_audio; if(!msg_send_audio) msg_send_audio = get_user_msgid("SendAudio");

    message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msg_send_audio, _, id);
    write_byte(id);
    write_string(audio);
    write_short(pitch);
    message_end();
}
