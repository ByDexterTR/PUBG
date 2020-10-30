/*										*/
/*				 VOID					*/
/*										*/

void MapStartNameControl()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_", false) == -1)
		{
			SetFailState("[PUBG] Pubg sadece Jailbreak modunda oynanabilir.");
		}
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_", 3, false) != 0)
	{
		SetFailState("[PUBG] Pubg sadece Jailbreak modunda oynanabilir.");
	}
	else
	{
		MapStartDownload();
	}
}

void MapStartDownload()
{
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Birincil.vmt");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Birincil.vtf");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Bomb.vmt");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Bomb.vtf");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Ex.vmt");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Ex.vtf");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Ikincil.vmt");
	AddFileToDownloadsTable("materials/models/PluginMerkezi/pubg/pubg_Ikincil.vtf");
	
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_birincil.mdl");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Birincil.dx90.vtx");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Birincil.phy");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_birincil.vvd");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_ikincil.mdl");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Ikincil.dx90.vtx");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Ikincil.phy");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_ikincil.vvd");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_ex.mdl");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Ex.dx90.vtx");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Ex.phy");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_ex.vvd");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_bomb.mdl");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Bomb.dx90.vtx");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_Bomb.phy");
	AddFileToDownloadsTable("models/pluginmerkezi/pubg/pubg_bomb.vvd");
	
	AddFileToDownloadsTable("sound/Plugin_Merkezi/PUBG/pubg_weapon_pickup.mp3");
	AddFileToDownloadsTable("sound/Plugin_Merkezi/PUBG/pubg_game_end.mp3");
	AddFileToDownloadsTable("sound/Plugin_Merkezi/PUBG/pubg_game_start.mp3");
	
	PrecacheModel("pluginmerkezi/pubg/pubg_Birincil.mdl", true);
	PrecacheModel("pluginmerkezi/pubg/pubg_Ikincil.mdl", true);
	PrecacheModel("pluginmerkezi/pubg/pubg_Ex.mdl", true);
	PrecacheModel("pluginmerkezi/pubg/pubg_bomb.mdl", true);
	PrecacheModel("player/custom_player/legacy/tm_balkan_variantg.mdl", true);
	PrecacheModel("props/de_nuke/hr_nuke/metal_crate_001/metal_crate_001_76_low.mdl", true);
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_weapon_pickup.mp3");
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_game_end.mp3");
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_game_start.mp3");
}

void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null)return;
	
	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
	
	SetConVarInt(IntCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}

void Ekran_Renk_Olustur(int client, int Renk[4])
{
	int clients[1];
	clients[0] = client;
	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0);
	Protobuf pb = UserMessageToProtobuf(message);
	pb.SetInt("duration", 200);
	pb.SetInt("hold_time", 40);
	pb.SetInt("flags", 17);
	pb.SetColor("clr", Renk);
	EndMessage();
}

public void GetAimCoords(int client, float vector[3])
{
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(vector, trace);
	trace.Close();
}

void RastgeleSilahCikar(int client, int class)
{
	char silahlar[11][32] =  { "weapon_ak47", "weapon_m4a1_silencer", "weapon_m4a1", "weapon_famas", "weapon_mag7", "weapon_mp7", "weapon_ump45", "weapon_bizon", "weapon_mp5sd", "weapon_mac10", "weapon_mp9" };
	char bombalar[5][32] =  { "weapon_hegrenade", "weapon_molotov", "weapon_smokegrenade", "weapon_flashbang", "weapon_decoy" };
	char tabancalar[7][32] =  { "weapon_deagle", "weapon_tec9", "weapon_hkp2000", "weapon_cz75a", "weapon_usp_silencer", "weapon_fiveseven", "weapon_glock" };
	char ekstralar[4][32] =  { "weapon_shield", "weapon_taser", "weapon_healthshot", "pm_armor" };
	char airdrop[5][32] =  { "weapon_awp", "weapon_scar20", "weapon_g3sg1", "weapon_negev", "weapon_m249" };
	if (IsValidClient(client, true))
	{
		if (class == 1)
			GivePlayerItem(client, silahlar[GetRandomInt(0, 10)]);
		else if (class == 2)
			GivePlayerItem(client, bombalar[GetRandomInt(0, 4)]);
		else if (class == 3)
			GivePlayerItem(client, tabancalar[GetRandomInt(0, 6)]);
		else if (class == 4)
		{
			int ex = GetRandomInt(0, 3);
			if (ex == 3)
			{
				SetEntProp(client, Prop_Data, "m_ArmorValue", 100, 1);
				SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
				PrintHintText(client, "[PUBG] Armor Kazandın Ve Kuşanıldı!");
			}
			else
				GivePlayerItem(client, ekstralar[ex]);
		}
		else if (class == 5)
		{
			SetEntProp(client, Prop_Data, "m_ArmorValue", 100, 1);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			PrintHintText(client, "[PUBG] Level 3 Armor Ve Kask Buldun!");
			
			GivePlayerItem(client, airdrop[GetRandomInt(0, 4)]);
			GivePlayerItem(client, "weapon_healthshot");
		}
	}
}

void Silahlari_Sil(int client)
{
	if (IsValidClient(client, true))
	{
		int wpnEnt;
		for (int wpnSlotIndex = 0; wpnSlotIndex <= 13; wpnSlotIndex++)
		{
			while ((wpnEnt = GetPlayerWeaponSlot(client, wpnSlotIndex)) != -1 && IsValidEntity(wpnEnt))
			{
				if (!RemovePlayerItem(client, wpnEnt))
					break;
				AcceptEntityInput(wpnEnt, "kill");
			}
			
			if (wpnSlotIndex == 3)
			{
				int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
				
				for (int j = 0; j < size; j++)
				{
					int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", j);
					
					if (weapon > 4096 && weapon != INVALID_ENT_REFERENCE)
					{
						weapon = EntRefToEntIndex(weapon);
					}
					
					if (IsValidEdict(weapon) && IsValidEntity(weapon))
					{
						char classname[32];
						if (GetEntityClassname(weapon, classname, sizeof(classname)))
						{
							if (strcmp(classname, "weapon_shield") == 0 || strcmp(classname, "weapon_tablet") == 0)
							{
								if (RemovePlayerItem(client, weapon))
								{
									AcceptEntityInput(weapon, "kill");
								}
							}
						}
					}
				}
			}
		}
	}
}

void CanWalk(int client, bool durum)
{
	if (durum)
		SetEntityMoveType(client, MOVETYPE_WALK);
	else
		SetEntityMoveType(client, MOVETYPE_NONE);
}

void FFAyarla(int durum)
{
	if (GetConVarInt(FindConVar("mp_teammates_are_enemies")) != durum || GetConVarInt(FindConVar("mp_friendlyfire")) != durum)
	{
		SetCvar("mp_teammates_are_enemies", durum);
		SetCvar("mp_friendlyfire", durum);
	}
}

void FinishTheGame()
{
	FFAyarla(0);
	YeriTemizle(1);
	YeriTemizle(2);
	basladi = false;
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (sdkhooklandi[i])
		{
			sdkhooklandi[i] = false;
			SDKUnhook(i, SDKHook_OnTakeDamage, damagealinca);
		}
	}
}

void ShowModels()
{
	YeriTemizle(3);
	LokasyonlariYukle();
	for (int i = 0; i < 200; i++)
	{
		if (i <= silahspawn_sayisi)
		{
			SpawnModel(2, konumlar_silah[i]);
			continue;
		}
		else
			break;
	}
	for (int i = 0; i < 200; i++)
	{
		if (i <= oyuncuspawn_sayisi)
		{
			SpawnModel(1, konumlar_spawn[i]);
			continue;
		}
		else
			break;
	}
}

void YeriTemizle(int mode)
{
	char weapon[64];
	char modelyolu[PLATFORM_MAX_PATH];
	for (int i = MaxClients; i < GetMaxEntities(); i++)
	if (IsValidEdict(i) && IsValidEntity(i))
	{
		if (mode == 1)
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (GetEntDataEnt2(i, g_WeaponParent) == -1)
				if (StrContains(weapon, "weapon_") != -1)
				AcceptEntityInput(i, "kill");
		}
		else if (mode == 2)
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", modelyolu, sizeof(modelyolu));
			if (StrContains(modelyolu, "pubg_") != -1 || StrContains(modelyolu, "de_nuke/hr_nuke/metal_crate_001/metal_crate_001_76_low") != -1)
				AcceptEntityInput(i, "kill");
		}
		else if (mode == 3)
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", modelyolu, sizeof(modelyolu));
			if (StrContains(modelyolu, "tm_balkan_variantg.mdl", false) != -1)
				AcceptEntityInput(i, "kill");
			if (StrContains(modelyolu, "pubg_") != -1)
				AcceptEntityInput(i, "kill");
		}
	}
}

/*										*/
/*				 BOOL					*/
/*										*/


public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

bool YetkiDurum(int client, char[] sFlags)
{
	if (StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
		return true;
	if (StrEqual(sFlags, "none", false))
		return false;
	AdminId id = GetUserAdmin(client);
	if (id == INVALID_ADMIN_ID)
		return false;
	if (CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
		return true;
	int iCount, iFound, flags;
	if (StrContains(sFlags, ";", false) != -1)
	{
		int c = 0, iStrCount = 0;
		while (sFlags[c] != '\0')
		{
			if (sFlags[c++] == ';')
				iStrCount++;
		}
		iStrCount++;
		char[][] sTempArray = new char[iStrCount][30];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 30);
		for (int i = 0; i < iStrCount; i++)
		{
			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for (int j = 0; j <= 20; j++)
			{
				if (flags & (1 << j))
				{
					iCount++;
					
					if (GetAdminFlag(id, view_as<AdminFlag>(j)))
						iFound++;
				}
			}
			if (iCount == iFound)
				return true;
		}
	}
	else
	{
		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for (int i = 0; i <= 20; i++)
		{
			if (flags & (1 << i))
			{
				iCount++;
				if (GetAdminFlag(id, view_as<AdminFlag>(i)))
					iFound++;
			}
		}
		if (iCount == iFound)
			return true;
	}
	return false;
}


/*										 */
/*				 INTEGER				 */
/*										 */

int OyuncuSayisiAl(int team)
{
	int oyuncusayisi = 0;
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			oyuncusayisi++;
		}
	}
	return oyuncusayisi;
} 