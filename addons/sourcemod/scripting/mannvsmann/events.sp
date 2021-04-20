/*
 * Copyright (C) 2021  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

void Events_Initialize()
{
	HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
	HookEvent("teamplay_point_captured", Event_TeamplayPointCaptured);
	HookEvent("teamplay_broadcast_audio", Event_TeamplayBroadcastAudio, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Create an upgrade station
	int resupply = MaxClients + 1;
	while ((resupply = FindEntityByClassname(resupply, "func_regenerate")) != -1)
	{
		int upgrades = CreateEntityByName("func_upgradestation");
		if (IsValidEntity(upgrades) && DispatchSpawn(upgrades))
		{
			float origin[3], mins[3], maxs[3];
			GetEntPropVector(resupply, Prop_Data, "m_vecAbsOrigin", origin);
			GetEntPropVector(resupply, Prop_Data, "m_vecMins", mins);
			GetEntPropVector(resupply, Prop_Data, "m_vecMaxs", maxs);
			
			TeleportEntity(upgrades, origin, NULL_VECTOR, NULL_VECTOR);
			SetEntityModel(upgrades, UPGRADE_STATION_MODEL);
			SetEntPropVector(upgrades, Prop_Send, "m_vecMins", mins);
			SetEntPropVector(upgrades, Prop_Send, "m_vecMaxs", maxs);
			
			SetEntProp(upgrades, Prop_Send, "m_nSolidType", SOLID_BBOX);
			SetEntProp(upgrades, Prop_Send, "m_fEffects", (GetEntProp(upgrades, Prop_Send, "m_fEffects") | EF_NODRAW));
			
			ActivateEntity(upgrades);
		}
	}
	
	//Required for some upgrades to work
	CreateEntityByName("info_populator");
}

public void Event_TeamplayPointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	int cpIndex = event.GetInt("cp");
	char[] cappers = new char[MaxClients];
	event.GetString("cappers", cappers, MaxClients);
	
	int cp = MaxClients + 1;
	while ((cp = FindEntityByClassname(cp, "team_control_point")) > -1)
	{
		int pointIndex = GetEntProp(cp, Prop_Data, "m_iPointIndex");
		if (pointIndex == cpIndex)
		{
			float origin[3];
			GetEntPropVector(cp, Prop_Data, "m_vecAbsOrigin", origin);
			
			CreateCurrencyPacks(origin, mvm_currency_capture.IntValue, cappers[0]);
		}
	}
}

public Action Event_TeamplayBroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	
	if (StrEqual(sound, "Game.YourTeamWon"))
	{
		event.SetString("sound", "music.mvm_end_mid_wave");
		return Plugin_Changed;
	}
	else if (StrEqual(sound, "Game.YourTeamLost") || StrEqual(sound, "Game.Stalemate"))
	{
		event.SetString("sound", "music.mvm_lost_wave");
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		//Allow medics to revive
		TF2Attrib_SetByName(client, "revive", 1.0);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int weaponid = event.GetInt("weaponid");
	
	if (victim == attacker)
		return;
	
	bool forceDistribute = IsValidClient(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Sniper && WeaponID_IsSniperRifleOrBow(weaponid);
	DropCurrencyPack(victim, mvm_currency_elimination.IntValue, forceDistribute, attacker);
}
