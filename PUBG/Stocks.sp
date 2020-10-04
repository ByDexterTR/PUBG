/*										*/
/*				 VOID					*/
/*										*/

void MapStartNameControl()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if (StrContains(map, "workshop/") == -1)
		if (StrContains(map, "/jb_") == -1 || StrContains(map, "/jail_") == -1 || StrContains(map, "/ba_") == -1)
		SetFailState("[PUBG] Pubg sadece Jailbreak modunda oynanabilir.");
	if (StrContains(map, "jb_") == -1 || StrContains(map, "jail_") == -1 || StrContains(map, "ba_") == -1)
		SetFailState("[PUBG] Pubg sadece Jailbreak modunda oynanabilir.");
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