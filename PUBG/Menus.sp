public int pubg_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char Item[32];
		menu.GetItem(position, Item, sizeof(Item));
		if (StrEqual(Item, "Start", false))
		{
			if (OyuncuSayisiAl(CS_TEAM_T) != 1)
			{
				if (gozukuyor)
				{
					YeriTemizle(3);
					gozukuyor = false;
				}
				LokasyonlariYukle();
				if (g_pubg_spawn.IntValue == 1)
				{
					if (oyuncuspawn_sayisi + 1 < OyuncuSayisiAl(CS_TEAM_T))
					{
						PrintToChat(client, "[SM] \x01Oyuncu spawn sayısı yetersiz.");
						delete menu;
						return;
					}
				}
				if (OyuncuSayisiAl(CS_TEAM_T) <= g_pubg_limit.IntValue)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda oyuncu bulunmadığı için oyun iptal edildi.");
					delete menu;
					return;
				}
				if (oyuncuspawn_sayisi + 1 <= 0)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda Oyuncu spawnı bulunmadığı için oyun iptal edildi. Pubg menüsünden spawn noktaları oluşturabilirsiniz.");
					delete menu;
					return;
				}
				if (silahspawn_sayisi + 1 <= 0)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda Silah spawnı bulunmadığı için oyun iptal edildi. Pubg menüsünden spawn noktaları oluşturabilirsiniz.");
					delete menu;
					return;
				}
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
					{
						CS_RespawnPlayer(i);
						int randomnumber = GetRandomInt(0, oyuncuspawn_sayisi);
						if (konumlar_spawn[randomnumber][0] != 0 || g_pubg_spawn.IntValue == 0)
						{
							TeleportEntity(i, konumlar_spawn[randomnumber], NULL_VECTOR, NULL_VECTOR);
							if (g_pubg_spawn.IntValue != 0)
								konumlar_spawn[randomnumber][0] = 0.0;
						}
						else
						{
							do
							{
								randomnumber = GetRandomInt(0, oyuncuspawn_sayisi);
							} while (konumlar_spawn[randomnumber][0] == 0);
							TeleportEntity(i, konumlar_spawn[randomnumber], NULL_VECTOR, NULL_VECTOR);
							konumlar_spawn[randomnumber][0] = 0.0;
						}
						EmitSoundToClientAny(i, "Plugin_Merkezi/PUBG/pubg_game_start.mp3", SOUND_FROM_PLAYER, 1, 40);
					}
				}
				PUBG_Baslat_Pre();
			}
			else
			{
				PrintHintText(client, "[PUBG] Yaşayan sadece 1 oyuncu var!");
				delete menu;
				return;
			}
		}
		else if (StrEqual(Item, "Stop", false))
		{
			basladi = false;
			YeriTemizle(1);
			YeriTemizle(2);
			FFAyarla(0);
			PrintToChatAll("[SM] \x02PUBG \x01Oyunu \x0E%N \x01Tarafından Bitirildi!", client);
			SetCvar("sv_enablebunnyhopping", 1);
			SetCvar("sv_autobunnyhopping", 1);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					Ekran_Renk_Olustur(i, { 255, 0, 0, 150 } );
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						Silahlari_Sil(i);
						GivePlayerItem(i, "weapon_knife");
						CanWalk(i, true);
					}
				}
			}
		}
		else if (StrEqual(Item, "AirDrop", false))
		{
			if (basladi)
			{
				float AimCoords[3];
				GetAimCoords(client, AimCoords);
				SendAirDrop(AimCoords);
				PrintHintText(client, "[PUBG] Air drop yola çıktı!");
			}
			else
			{
				PrintHintText(client, "[PUBG] Oyun oynanmıyor iken drop gönderemezsin!");
			}
		}
		else if (StrEqual(Item, "Ayarlar", false))
		{
			PUBG_AyarMenu_Ac().Display(client, MENU_TIME_FOREVER);
		}
	}
	if (action == MenuAction_Cancel)
	{
		delete menu;
	}
}

Menu PUBG_AyarMenu_Ac()
{
	Menu menu = new Menu(pubg_genelayarmenu);
	menu.SetTitle("[PUBG] Ayar Menüsü\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("spawn", "Spawn Ayarları");
	if (bac)
		menu.AddItem("bunny", "Bunny: Pasif");
	else
		menu.AddItem("bunny", "Bunny: Aktif");
	menu.ExitBackButton = false;
	menu.ExitButton = true;
	
	return menu;
}

public int pubg_genelayarmenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (StrEqual(item, "spawn"))
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		if (StrEqual(item, "bunny"))
		{
			bac = !bac;
			PUBG_AyarMenu_Ac().Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Exit)
			command_pubg(client, 0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

Menu PUBG_AyarMenu_Ac2(int client)
{
	Menu menu = new Menu(pubg_spawnayarmenu);
	menu.SetTitle("[PUBG] Spawn Ayar Menüsü\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("1", "Oyuncu spawn noktası belirle");
	menu.AddItem("2", "Silah spawn noktası belirle\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("3", "Oyuncu spawn noktalarını sıfırla");
	menu.AddItem("4", "Silah spawn noktalarını sıfırla\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	if (gozukuyor)
		menu.AddItem("Hide", "Spawn Noktalarını: Gizle\nHaritanıza göre sunucunuzu çökertebilir!");
	else
	{
		menu.AddItem("Show", "Spawn Noktalarını: Göster\nHaritanıza göre sunucunuzu çökertebilir!");
	}
	gorenoyuncu = client;
	menu.ExitBackButton = false;
	menu.ExitButton = true;
	return menu;
}

public int pubg_spawnayarmenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (StrEqual(item, "Hide"))
		{
			YeriTemizle(3);
			gozukuyor = false;
			gorenoyuncu = -1;
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(item, "Show"))
		{
			ShowModels();
			gozukuyor = true;
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			int sayi = StringToInt(item);
			LokasyonKaydet(client, sayi);
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Exit)
			PUBG_AyarMenu_Ac().Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
} 