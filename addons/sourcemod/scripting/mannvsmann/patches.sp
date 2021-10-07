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

static MemoryPatch g_MemoryPatchRadiusCurrencyCollectionCheck;
static MemoryPatch g_MemoryPatchUpdateMissionDestroySentries;
static MemoryPatch g_MemoryPatchUpdateMissionDestroySentries2;

void Patches_Initialize(GameData gamedata)
{
	MemoryPatch.SetGameData(gamedata);
	
	//Allows players not on RED to collect credits in a radius
	//Not done using a DHook because of nested function calls that depend on the proper team
	CreateMemoryPatch(g_MemoryPatchRadiusCurrencyCollectionCheck, "MemoryPatch_RadiusCurrencyCollectionCheck");
	CreateMemoryPatch(g_MemoryPatchUpdateMissionDestroySentries, "MemoryPatch_UpdateMissionDestroySentries");
	CreateMemoryPatch(g_MemoryPatchUpdateMissionDestroySentries2, "MemoryPatch_UpdateMissionDestroySentries1");
}

void Patches_Destroy()
{
	if (g_MemoryPatchRadiusCurrencyCollectionCheck)
		g_MemoryPatchRadiusCurrencyCollectionCheck.Disable();
	
	if (g_MemoryPatchUpdateMissionDestroySentries)
		g_MemoryPatchUpdateMissionDestroySentries.Disable();
	
	if (g_MemoryPatchUpdateMissionDestroySentries2)
		g_MemoryPatchUpdateMissionDestroySentries2.Disable();
}

static void CreateMemoryPatch(MemoryPatch &patch, const char[] name)
{
	patch = new MemoryPatch(name);
	if (patch)
		patch.Enable();
	else
		LogError("Failed to create memory patch %s", name);
}
