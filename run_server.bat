@echo off 
 cls 
 title StartUp 
 :hlds 
 echo (%time%) HLDS Started... 
 reg add "HKCU\Software\Valve\Steam\ActiveProcess" /v SteamClientDll /t REG_SZ /d "" /f 
 start /wait /high hlds.exe -autoupdate -console -game cstrike -secure -master -noipx +map de_dust2 +maxplayers 32 +port 27015 
 echo n| goto hlds 
 echo (%time%) HLDS Crashed, restarting... 
 goto hlds