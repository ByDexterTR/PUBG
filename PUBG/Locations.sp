public void LokasyonKaydet(int client, int mode)
{
	KeyValues data = CreateKeyValues("Maps");
	data.ImportFromFile(datayolu);
	
	float konum[3];
	GetAimCoords(client, konum);
	
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	if (data.JumpToKey(map, true))
	{
		if (mode == 1)
			data.JumpToKey("Players", true);
		else if (mode == 2)
			data.JumpToKey("Weapons", true);
		else if (mode == 3)
			data.DeleteKey("Players");
		else if (mode == 4)
			data.DeleteKey("Weapons");
		if (mode == 1 || mode == 2)
		{
			for (int i = 1; i < 200; i++)
			{
				char buffer[16];
				IntToString(i, buffer, sizeof(buffer));
				if (data.GetNum(buffer, 0) == 0)
				{
					data.SetVector(buffer, konum);
					konum[2] += 8.0;
					TE_SetupBeamRingPoint(konum, 0.0, 32.0, g_BeamSprite, g_HaloSprite, 0, 60, 1.0, 5.0, 1.0, { 200, 120, 255, 255 }, 450, 0);
					TE_SendToClient(client);
					konum[2] -= 8.0;
					break;
				}
				else
					continue;
			}
		}
	}
	data.Rewind();
	data.ExportToFile(datayolu);
	delete data;
}

public void LokasyonlariYukle()
{
	KeyValues data = CreateKeyValues("Maps");
	data.ImportFromFile(datayolu);
	
	char map[32];
	GetCurrentMap(map, sizeof(map));
	
	oyuncuspawn_sayisi = -1, silahspawn_sayisi = -1;
	if (data.JumpToKey(map, false))
	{
		if (data.JumpToKey("Players", false))
		{
			for (int i = 1; i <= 200; i++)
			{
				char buffer[16];
				IntToString(i, buffer, sizeof(buffer));
				if (data.GetNum(buffer, -1) == -1)
				{
					data.GoBack();
					break;
				}
				else
				{
					data.GetVector(buffer, konumlar_spawn[i - 1]);
					oyuncuspawn_sayisi++;
					continue;
				}
			}
		}
		if (data.JumpToKey("Weapons", false))
		{
			for (int i = 1; i <= 200; i++)
			{
				char buffer[16];
				IntToString(i, buffer, sizeof(buffer));
				if (data.GetNum(buffer, -1) == -1)
					break;
				else
				{
					data.GetVector(buffer, konumlar_silah[i - 1]);
					konumlar_silah[i - 1][2] += 32;
					silahspawn_sayisi++;
					continue;
				}
			}
		}
	}
	data.Rewind();
	data.ExportToFile(datayolu);
	delete data;
}