#include <a_samp>
#include <dc_cmd>
#include <sscanf2>

#define UpdatePlayerMoney(%0) ResetPlayerMoney(%0), GivePlayerMoney(%0, pdata[%0][money])
#define UpdatePlayerScore(%0) SetPlayerScore(%0, pdata[%0][exp]/100)
#define playername(%0) pdata[%0][nickname]
#define playerip(%0) pdata[%0][playerip]
#define rand(%1,%2) (random(%2-%1)+%1)

#define LOGIN_TEXT "Введите пароль:"
#define REG_TEXT "Введите пароль:"
#define LOGIN_WRONG_PASSWORD_TEXT "Вы ввели неверный пароль"
#define REG_WRONG_LENGHT_TEXT "Пароль должен быть от 6 до 32 символов длинной"

#define COLOR_PURPLE "{a55eea}"
#define COLOR_GREEN "{0be881}"
#define COLOR_RED "{f53b57}"
#define COLOR_WHITE "{ffffff}"
#define COLOR_ORANGE "{f1c40f}"
#define COLOR_GRAY "{C0C4CC}"
#define COLOR_BLUE "{409EFF}"

#define MODE_NAME "MP 0.0.1"

#undef MAX_PLAYERS
#define MAX_PLAYERS 50

forward GlobalTimer();
forward OnPlayerCommandReceived(playerid, cmdtext[]);

new DB:db_handle;

enum
{
	DIALOG_LOGIN,
	DIALOG_REG,
	DIALOG_CAR_OPTIONS,
}

enum player_data
{
	nickname[MAX_PLAYER_NAME],
	money,
	skin,
	exp,
	admin,
	moderator,
	hashed_password[64+1],
	password_salt[11+1],
	prefix[16],
	playtime,
	bool:logged,
	playerip[16],
	rank,
	member,
	leader,
	bool:spawned,
}

static pdata[MAX_PLAYERS][player_data];

enum vehicle_parameters
{
	modelid,
	Float:pos_x,
	Float:pos_y,
	Float:pos_z,
	Float:rotate,
	color_1,
	color_2,
	respawn_delay,
	siren
}

new sapd_cars_array[][vehicle_parameters] = {
	{596, 1535.7053, -1667.1376, 13.0650, 0.0000, 0, 1, -1},
	{596, 1535.7175, -1673.3705, 13.0650, 0.0000, 0, 1, -1}
};

new sapd_car[sizeof(sapd_cars_array)];

new hours, minutes, ClockUpdateTimer;

new fraction_name[][32] = {"", "SAPD", "LAPD"};
new sapd_ranks[][32] = { "", "Recruit", "Officer", "Sergant", "Lieutenant", "Captain", "Colonel", "Chief Assistant", "Chief" };

main()
{
	print("\n----------------------------------");
	print(" Blank Gamemode by your name here");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
	db_handle = db_open("data.db");
	SetGameModeText(MODE_NAME);
	SetTimer("GlobalTimer", 250, 1);
	ClockUpdateTimer = gettime()+1;
	SetWeather(3);
	AddPlayerClass(2, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(3, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(56, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(12, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(25, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(72, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(37, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(41, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(6, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(193, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(48, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(20, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(67, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(7, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(192, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(21, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
	AddPlayerClass(101, 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);

	ManualVehicleEngineAndLights();
	// Загрузка авто SAPD
	for(new i = sizeof(sapd_car)-1; i != -1; --i)
    {
    	sapd_car[i] = CreateVehicle(sapd_cars_array[i][modelid], sapd_cars_array[i][pos_x], \
    		sapd_cars_array[i][pos_y], sapd_cars_array[i][pos_z], sapd_cars_array[i][rotate], \
    		sapd_cars_array[i][color_1], sapd_cars_array[i][color_2], sapd_cars_array[i][respawn_delay], sapd_cars_array[i][siren]);
    }
	return 1;
}

public OnGameModeExit()
{
	if(db_handle) db_close(db_handle);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(!pdata[playerid][logged]) return Kick(playerid);
	if(pdata[playerid][spawned])
	{
		SetSpawnInfo(playerid, 0, pdata[playerid][skin], 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(playerid);
	}
	else
	{
		SetPlayerInterior(playerid, 14);
		SetPlayerPos(playerid, 258.9263, -41.7078, 1002.0217);
		SetPlayerFacingAngle(playerid, 46);
		SetPlayerCameraPos(playerid, 255.9922, -40.0980, 1002.0680);
		SetPlayerCameraLookAt(playerid, 256.7953, -40.6936, 1002.1498);
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, pdata[playerid][nickname], MAX_PLAYER_NAME);
	GetPlayerIp(playerid, pdata[playerid][playerip], 16);
	SetPVarInt(playerid, "ChatClearTimer", gettime()+1);
	TogglePlayerSpectating(playerid, 1);
	new DBResult:db_result;
    new query[44 - 2 + MAX_PLAYER_NAME];
    format(query, sizeof(query), "SELECT * FROM `players` WHERE `nickname` = '%s'", playername(playerid));
    db_result = db_query(db_handle, query);
	if(db_num_rows(db_result))
	{
		db_get_field_assoc(db_result, "password",  pdata[playerid][hashed_password], 64);
		db_get_field_assoc(db_result, "salt",  pdata[playerid][password_salt], 11);
		pdata[playerid][money] = db_get_field_assoc_int(db_result, "money");
		pdata[playerid][skin] = db_get_field_assoc_int(db_result, "skin");
		pdata[playerid][exp] = db_get_field_assoc_int(db_result, "exp");
		pdata[playerid][admin] = db_get_field_assoc_int(db_result, "admin");
		pdata[playerid][moderator] = db_get_field_assoc_int(db_result, "moderator");
		pdata[playerid][playtime] = db_get_field_assoc_int(db_result, "playtime");
		pdata[playerid][leader] = db_get_field_assoc_int(db_result, "leader");
		pdata[playerid][member] = db_get_field_assoc_int(db_result, "member");
		pdata[playerid][rank] = db_get_field_assoc_int(db_result, "rank");
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Авторизация", LOGIN_TEXT, "Войти", "Отмена");
	}
	else ShowPlayerDialog(playerid, DIALOG_REG, DIALOG_STYLE_PASSWORD, "Регистрация", REG_TEXT, "Регистр.", "Отмена");
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SavePlayerData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!pdata[playerid][logged]) return Kick(playerid);
	UpdatePlayerMoney(playerid);
	UpdatePlayerScore(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	SetVehicleParamsEx(vehicleid, 0, 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(pdata[playerid][logged] == false) return false;
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(!IsPlayerInRangeOfPoint(i, 15, x, y, z)) continue;
		static const fstr[] = "%s (%d): %s";
    	new str[sizeof(fstr) -2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 128];
    	format(str, sizeof(str), fstr, playername(playerid), playerid, text);
    	SendClientMessage(i, -1, str);
	}
	return 0;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	SetPlayerInterior(playerid, 0);
	pdata[playerid][skin] = GetPlayerSkin(playerid);
	pdata[playerid][spawned] = true;
	db_save_field_int(playerid, pdata[playerid][skin], "skin");
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_REG:
		{
			if(!response) return KickPlayer(playerid);
			if(strlen(inputtext) < 6 || strlen(inputtext) > 32) return ShowPlayerDialog(playerid, DIALOG_REG, DIALOG_STYLE_INPUT, "Регистрация", REG_WRONG_LENGHT_TEXT, "Регистр", "Отмена");
			new salt[11];
			new password_hash[64 + 1];
	        for(new i; i < 10; i++)
	        {
	            salt[i] = random(79) + 47;
	        }
	        SHA256_PassHash(inputtext, salt, password_hash, sizeof(password_hash));
    		static const fquery[] = "INSERT INTO `players` \
    		(`nickname`, `password`, `salt`, `reg_ip`) \
    		VALUES \
    		('%s', '%s', '%s', '%s')";
    		new qstr[sizeof(fquery) - 2 + MAX_PLAYER_NAME - 2 + sizeof(password_hash) - 2 + sizeof(salt) - 2 + 16];
    		format(qstr, sizeof(qstr), fquery, playername(playerid), password_hash, salt, playerip(playerid));
    		db_free_result(db_query(db_handle, qstr));
	        TogglePlayerSpectating(playerid, 0);
	        pdata[playerid][logged] = true;
		}	
		case DIALOG_LOGIN:
		{
			if(!response) return KickPlayer(playerid);
			if(strlen(inputtext) < 6 || strlen(inputtext) > 32) return ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Авторизация", LOGIN_TEXT, "Войти", "Отмена");
			new password_hash[64 + 1];
			SHA256_PassHash(inputtext, pdata[playerid][password_salt], password_hash, sizeof(password_hash));
			if(strcmp(password_hash, pdata[playerid][hashed_password], false)) return  ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Авторизация", LOGIN_WRONG_PASSWORD_TEXT, "Войти", "Отмена");
			TogglePlayerSpectating(playerid, 0);
			pdata[playerid][logged] = true;
			SetSpawnInfo(playerid, 0, pdata[playerid][skin], 2233.3674,-1260.6019,23.9298,267.9533, 0, 0, 0, 0, 0, 0);
			pdata[playerid][spawned] = true;
			SpawnPlayer(playerid);
			db_save_field_str(playerid, playerip(playerid), "last_ip");
			if(pdata[playerid][admin] || pdata[playerid][moderator])
			{
				format(pdata[playerid][prefix], 16, "%s", (pdata[playerid][admin]) ? ("Администратор") : ("Модератор"));
				static const fstr[] = ""COLOR_RED"%s %s авторизовался (ID: %i; IP: %s)";
				new str[sizeof(fstr) - 2 + 16 -2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 16];
				format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, playerip(playerid));
				SendAdminMessage(str);
			}
		}
		case DIALOG_CAR_OPTIONS:
		{
			if(!response) return 0;
			new vehicleid = GetPlayerVehicleID(playerid);
			new engine, lights, alarm, doors, bonnet, boot, objective;
			GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
			switch(listitem)
			{
				case 0:
				{
					printf("LIGHTS before %i", lights);
					if(lights == VEHICLE_PARAMS_UNSET) lights = VEHICLE_PARAMS_OFF;
					lights = !lights;
					SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
					printf("LIGHTS AFTER %i", lights);
				}
				case 1:
				{
					if(doors == VEHICLE_PARAMS_UNSET) doors = VEHICLE_PARAMS_OFF;
					doors = !doors;
					SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				}
				case 2:
				{
					if(engine == VEHICLE_PARAMS_UNSET) engine = VEHICLE_PARAMS_OFF;
					engine = !engine;
					SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);				
				}
				case 3:
				{
					if(bonnet == VEHICLE_PARAMS_UNSET) bonnet = VEHICLE_PARAMS_OFF;
					bonnet = !bonnet;
					SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				}
				case 4:
				{
					if(boot == VEHICLE_PARAMS_UNSET) boot = VEHICLE_PARAMS_OFF;
					boot = !boot;
					SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
				}

			}
			new str[128];
			format(str, sizeof(str), "Фары\t%s\n", (lights != VEHICLE_PARAMS_ON) ? ("Выключены") : ("Включены"));
			format(str, sizeof(str), "%sДвери\t%s\n", str, (doors != VEHICLE_PARAMS_ON) ? ("Закрыты") : ("Открыты"));
			format(str, sizeof(str), "%sДвигатель\t%s\n", str, (engine != VEHICLE_PARAMS_ON) ? ("Заглушен") : ("Работает"));
			format(str, sizeof(str), "%sКапот\t%s\n", str, (bonnet != VEHICLE_PARAMS_ON) ? ("Закрыт") : ("Открыт"));
			format(str, sizeof(str), "%sБагажник\t%s\n", str, (boot != VEHICLE_PARAMS_ON) ? ("Закрыт") : ("Открыт"));
			ShowPlayerDialog(playerid, DIALOG_CAR_OPTIONS, DIALOG_STYLE_TABLIST, "Управление автомобилем", str, "Выбрать", "Отмена");
		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if(pdata[playerid][logged] == false) return false;
    return 1; // разрешить выполнение команды
} 

public GlobalTimer()
{
	new currenttime = gettime();
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(GetPVarInt(i, "ChatClearTimer") <= currenttime && GetPVarInt(i, "ChatClearTimer") != 0)
		{
			for(new a = 20; a != -1; --a) SendClientMessage(i, -1, "");
			DeletePVar(i, "ChatClearTimer");
			SendClientMessage(i, -1, "Добро пожаловать на сервер. Приятной игры.");
		}
		if(GetPVarInt(i, "KickTimer") <= gettime() && GetPVarInt(i, "KickTimer") != 0) Kick(i);
	}
	if(ClockUpdateTimer <= currenttime && ClockUpdateTimer != 0)
	{
		ClockUpdateTimer = currenttime+1;
		minutes++;
		if(minutes > 59) { minutes = 0; hours++; }
		if(hours > 23) { hours = 0; }
		for(new i = GetPlayerPoolSize(); i != -1; --i)
		{
			if(!IsPlayerConnected(i)) continue;
			SetPlayerTime(i, hours, minutes);
		}
	}
	return 1;
}

static stock db_save_field_int(const playerid, const data, const rowname[])
{
	new microtime = GetTickCount();
	static const query_str[] = "UPDATE `players` SET `%s` = %i WHERE `nickname` = '%s'";
	static query[sizeof(data) + sizeof(rowname[]) + MAX_PLAYER_NAME + sizeof(query_str) - 6];
	format(query, sizeof(query), query_str, rowname, data, pdata[playerid][nickname]);
	db_free_result(db_query(db_handle, query));
	// Debug
	printf("[SQLite]: %s сохранено, значение: %i, запрос занял %i мс.", rowname, data, GetTickCount()-microtime);
	printf("DEBUG SIZEOF QUERY %i, QUERY %s", sizeof(query), query);
	return 1;
}

static stock db_save_field_str(const playerid, const data[], const rowname[])
{
	printf("SIZEOF DATA %i", sizeof(data[]));
	printf("SIZEOF ROWNAME %i", sizeof(rowname[]));
	new microtime = GetTickCount();
	static const query_str[] = "UPDATE `players` SET `%s` = '%s' WHERE `nickname` = '%s'";
	static query[32 + 16 + MAX_PLAYER_NAME + sizeof(query_str) - 6];
	format(query, sizeof(query), query_str, rowname, data, pdata[playerid][nickname]);
	db_free_result(db_query(db_handle, query));
	// Debug
	printf("[SQLite]: %s сохранено, значение: %s, запрос занял %i мс.", rowname, data, GetTickCount()-microtime);
	printf("DEBUG SIZEOF QUERY %i, QUERY %s", sizeof(query), query);
	return 1;
}

static stock db_save_field_float(const playerid, const Float:data, const rowname[])
{
	new microtime = GetTickCount();
	static const query_str[] = "UPDATE `players` SET `%s` = %f WHERE `nickname` = '%s'";
	static query[sizeof(data) + sizeof(rowname[]) + MAX_PLAYER_NAME + sizeof(query_str) - 6];
	format(query, sizeof(query), query_str, rowname, data, pdata[playerid][nickname]);
	db_free_result(db_query(db_handle, query));
	// Debug
	printf("[SQLite]: %s сохранено, значение: %f, запрос занял %i мс.", rowname, data, GetTickCount()-microtime);
	printf("DEBUG SIZEOF QUERY %i, QUERY %s", sizeof(query), query);
	return 1;
}

static stock KickPlayer(playerid)
{
	SetPVarInt(playerid, "KickTimer", gettime()+1);
	return 1;
}

static stock SavePlayerData(playerid)
{
	static const query_str[] = "UPDATE `players` SET `money` = %d, \
	`exp` = %d \
	WHERE `nickname` = '%s'";
	static query[MAX_PLAYER_NAME + sizeof(query_str) - 10 + 32];
	format(query, sizeof(query), query_str, pdata[playerid][money], pdata[playerid][exp], playername(playerid));
	db_free_result(db_query(db_handle, query));
	return 1;
}

static stock SendAdminMessage(text[])
{
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(pdata[i][admin] == 1 || pdata[i][moderator] == 1)
		{
			if(pdata[i][logged] == false) continue;
			SendClientMessage(i, -1, text);
		}
		else continue;

	}
	return true;
}

CMD:car(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, -1, "Вы должны быть в автомобиле");
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, -1, "Вы не водитель");
	new engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(GetPlayerVehicleID(playerid), engine, lights, alarm, doors, bonnet, boot, objective);
	new str[128];
	format(str, sizeof(str), "Фары\t%s\n", (lights != VEHICLE_PARAMS_ON) ? ("Выключены") : ("Включены"));
	format(str, sizeof(str), "%sДвери\t%s\n", str, (doors != VEHICLE_PARAMS_ON) ? ("Закрыты") : ("Открыты"));
	format(str, sizeof(str), "%sДвигатель\t%s\n", str, (engine != VEHICLE_PARAMS_ON) ? ("Заглушен") : ("Работает"));
	format(str, sizeof(str), "%sКапот\t%s\n", str, (bonnet != VEHICLE_PARAMS_ON) ? ("Закрыт") : ("Открыт"));
	format(str, sizeof(str), "%sБагажник\t%s\n", str, (boot != VEHICLE_PARAMS_ON) ? ("Закрыт") : ("Открыт"));
	ShowPlayerDialog(playerid, DIALOG_CAR_OPTIONS, DIALOG_STYLE_TABLIST, "Управление автомобилем", str, "Выбрать", "Отмена");
	printf("STRLEN %i", strlen(str));
	return true;
}

CMD:time(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new hour, minute;
	if(sscanf(params, "dd", hour, minute)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/time {часы (0-23)} {минуты (0-59)}");
	if(hour > 23 || hour < 0) return SendClientMessage(playerid, -1, "Часы могут быть быть установлены в диапазоне от 0 до 23");
	if(minute > 59 || minute < 0) return SendClientMessage(playerid, -1, "Минуты могут быть установлены в диапазоне от 0 до 59");
	hours = hour;
	minutes = minute;
	SendClientMessage(playerid, 0x0be881FF, "Время изменено");
	static const fstr[] = ""COLOR_GREEN"%s %s (%i) изменил время на %02i:%02i";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, hours, minutes);
	SendAdminMessage(str);
    return true;
}

CMD:weather(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new weatherid;
	if(sscanf(params, "d", weatherid)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/weaither {ID погоды (0-255)}");
	if(weatherid > 255 || weatherid < 0) return SendClientMessage(playerid, -1, "Погода может быть установлена в диапазоне от 0 до 255");
	SetWeather(weatherid);
	SendClientMessage(playerid, 0x0be881FF, "Погода изменена");
	static const fstr[] = ""COLOR_GREEN"%s %s (%i) изменил погоду на %02i";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, weatherid);
	SendAdminMessage(str);
    return true;
}

CMD:a(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new text[128];
	if(sscanf(params, "s[128]", text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/a {текст}");
	static const fstr[] = ""COLOR_GREEN"{A}%s %s (%d): "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + sizeof(text)];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, text);
	SendAdminMessage(str);
	return true;
}


CMD:kick(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new targetid, reason[128];
	if(sscanf(params, "is[128]", targetid, reason)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/kick {ID} {причина}");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, ""COLOR_RED" Игрок не найден");
	static const fstr[] = ""COLOR_RED"%s %s (%d) кикнул %s (%d). Причина: %s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + sizeof(reason)];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, playername(targetid), targetid, reason);
	SendAdminMessage(str);
	SendClientMessage(targetid, -1, str);
	KickPlayer(targetid);
	return true;
}

CMD:report(playerid, params[])
{
	new report_text[128];
	if(sscanf(params, "s[128]", report_text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/report {текст}");
	static const fstr[] = ""COLOR_ORANGE"{REPORT} %s (%d): "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + MAX_PLAYER_NAME -2 + 4 - 2 + sizeof(report_text)];
	format(str, sizeof(str), fstr, playername(playerid), playerid, report_text);
	SendAdminMessage(str);
	SendClientMessage(playerid, 0xC0C4CCFF, "Ваше сообщение отправлено администрации");
	return true;
}

CMD:re(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new targetid, report_text[128];
	if(sscanf(params, "is[128]", targetid, report_text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/re {ID} {текст}");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, ""COLOR_RED" Игрок не найден");
	static const fstr[] = ""COLOR_GREEN"{RE} %s %s (%d): "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME -2 + 4 - 2 + sizeof(report_text) + 16];
	printf("SIZEOF STR %i", sizeof(str));
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, report_text);
	SendClientMessage(targetid, 0xC0C4CCFF, str);
	static const to_fstr[] = ""COLOR_GREEN"{RE} %s %s (%d) для %s (%i)";
	printf("SIZEOF REPORT TEST %i", sizeof(report_text));
	new to_str[sizeof(to_fstr) - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 16 - 2 + MAX_PLAYER_NAME -2 + 4];
	printf("SIZEOF tofstr %i", sizeof(to_str));
	format(to_str, sizeof(to_str), to_fstr, pdata[playerid][prefix], playername(playerid), playerid, playername(targetid), targetid);
	SendAdminMessage(to_str);
	SendAdminMessage(report_text);
	return true;
}

CMD:me(playerid, params[])
{
	new action[128];
	if(sscanf(params, "s[128]", action)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/me {действие}");
	SetPlayerChatBubble(playerid, action, 0xa55eeaFF, 15, 7000);
	static const fstr[] = "%s %s";
    new str[sizeof(fstr) -2 + MAX_PLAYER_NAME - 2 + 128];
   	format(str, sizeof(str), fstr, playername(playerid), action);
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(!IsPlayerInRangeOfPoint(i, 15, x, y, z)) continue;
    	SendClientMessage(i, 0xa55eeaFF, str);
	}
    return true;
}

CMD:b(playerid, params[])
{
	new text[128];
	if(sscanf(params, "s[128]", text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/b {текст}");
	static const fstr[] = "(( %s (%d): %s ))";
    new str[sizeof(fstr) -2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 128];
    format(str, sizeof(str), fstr, playername(playerid), playerid, text);
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(!IsPlayerInRangeOfPoint(i, 15, x, y, z)) continue;
    	SendClientMessage(i, 0xC0C4CCFF, str);
	}
	SetPlayerChatBubble(playerid, str, 0xC0C4CCFF, 15, 7000);
    return true;
}


CMD:am(playerid, params[])
{
	if(pdata[playerid][admin] == 0 && pdata[playerid][moderator] == 0) return false;
	new text[128];
	if(sscanf(params, "s[128]", text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/am {текст}");
	static const fstr[] = ""COLOR_GREEN"%s %s (%i): "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + sizeof(text)];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, text);
	SendClientMessageToAll(-1, str);
	return true;
}




CMD:makeleader(playerid, params[])
{
	if(pdata[playerid][admin] == 0) return false;
	new targetid, fraction_id;
	if(sscanf(params, "dd", targetid, fraction_id)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/makeleader {ID} {ID организации}");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, ""COLOR_RED" Игрок не найден");
	if(fraction_id < 1 || fraction_id > 1) return SendClientMessage(playerid, -1, "ID организации может быть в диапазоне от 1 до 1");

	pdata[targetid][leader] = fraction_id;
	pdata[targetid][member] = fraction_id;
	pdata[targetid][rank] = 8;
	db_save_field_int(targetid, pdata[targetid][leader], "leader");
	db_save_field_int(targetid, pdata[targetid][member], "member");
	db_save_field_int(targetid, pdata[targetid][rank], "rank");
	static const fstr[] = ""COLOR_GREEN"%s %s (%i) назначил вас лидером организации %s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 16];
	format(str, sizeof(str), fstr, pdata[playerid][prefix], playername(playerid), playerid, fraction_name[fraction_id]);
	SendClientMessage(targetid, -1, str);
	static const to_fstr[] = ""COLOR_GREEN"%s %s (%i) назначил %s (%d) лидером организации %s";
	new to_str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 16];
	format(to_str, sizeof(to_str), to_fstr, pdata[playerid][prefix], playername(playerid), playerid, playername(targetid), targetid, fraction_name[fraction_id]);
	SendAdminMessage(to_str);
	return true;
}

CMD:r(playerid, params[])
{
	if(pdata[playerid][member] == 0) return false;
	new text[128];
	if(sscanf(params, "s[128]", text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/r {текст}");
	static const fstr[] = ""COLOR_BLUE"{R} %s %s: "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + 16 - 2 + MAX_PLAYER_NAME - 2 + 4 - 2 + 128];
	if(pdata[playerid][member] == 1)
	{
		format(str, sizeof(str), fstr, sapd_ranks[pdata[playerid][rank]], playername(playerid), text);
	}
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(pdata[i][member] != pdata[playerid][member]) continue;
    	SendClientMessage(i, -1, str);
    	PlayCrimeReportForPlayer(i, 0, rand(3, 22));
	}
	return true;
}

CMD:m(playerid, params[])
{
	if(!IsPlayerInAnyVehicle(playerid)) return false;
	new vehicleid = GetPlayerVehicleID(playerid);
	printf("VEHICLE MODEL %i", GetVehicleModel(vehicleid));
	if(GetVehicleModel(vehicleid) != 596 && \
		GetVehicleModel(vehicleid) != 597 && \
		GetVehicleModel(vehicleid) != 598 && \
		GetVehicleModel(vehicleid) != 599 && \
		GetVehicleModel(vehicleid) != 427 && \
		GetVehicleModel(vehicleid) != 490 && \
		GetVehicleModel(vehicleid) != 528 && \
		GetVehicleModel(vehicleid) != 601) return false;
	print("СОВПАДАЕТ");
	new text[128];
	if(sscanf(params, "s[128]", text)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/m {текст}");
	static const fstr[] = ""COLOR_ORANGE"{M} %s: "COLOR_WHITE"%s";
	new str[sizeof(fstr) - 2 + MAX_PLAYER_NAME - 2 + 128];
	format(str, sizeof(str), fstr, playername(playerid), text);
	new Float:vehx, Float:vehy, Float:vehz;
    GetVehiclePos(vehicleid, vehx, vehy, vehz);
	for(new i = GetPlayerPoolSize(); i != -1; --i)
	{
		if(!IsPlayerConnected(i)) continue;
		if(!IsPlayerInRangeOfPoint(i, 50, vehx, vehy, vehz)) continue;
    	SendClientMessage(i, -1, str);
	}
	return true;
}

CMD:play(playerid, params[])
{
	new soundid;
	if(sscanf(params, "d", soundid)) return SendClientMessage(playerid, -1, "Введите "COLOR_GREEN"/play {ID}");
	PlayerPlaySound(playerid, soundid, 0, 0, 0);
	printf("Playing sound ID: %i", soundid);
	return true;
}

