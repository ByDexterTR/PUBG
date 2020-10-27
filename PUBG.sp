#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <warden>
#include <emitsoundany>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Playerunkown Battlegrounds - Jailbreak Game", 
	author = "quantum. - ByDexter - Emur", 
	description = "PUBG plugin specially made for Turkish jailbreak servers.", 
	version = "0.6 - Beta", 
	url = "https://pluginmerkezi.com/"
};

//KV
static char datayolu[PLATFORM_MAX_PATH];

//ConVar
ConVar g_pubg_sure = null, g_pubg_spawn = null, g_pubg_limit = null, g_Yetkiliflag = null, g_AirDrops = null;
char YetkiliflagString[32];

//Konum Şeyleri
float konumlar_spawn[200][3], konumlar_silah[200][3];
int oyuncuspawn_sayisi = 0, silahspawn_sayisi = 0;
bool gozukuyor = false, bac = false;

bool basladi = false;
int gerisayim_sure = -1;
int gorenoyuncu = 0;
//Beamler
int g_BeamSprite = -1;
int g_HaloSprite = -1;
int g_iSmoke = -1;
int g_model = -1;
int g_WeaponParent;

#include "PUBG/Stocks.sp"
#include "PUBG/airdrop.sp"

public void OnPluginStart()
{
	CreateDirectory("addons/sourcemod/data/PluginMerkezi/Pubg", 3);
	BuildPath(Path_SM, datayolu, sizeof(datayolu), "data/PluginMerkezi/Pubg/locations.txt");
	
	RegConsoleCmd("sm_pubg", command_pubg);
	HookEvent("player_death", event_death, EventHookMode_Post);
	HookEvent("round_end", event_end);
	g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity"); //For clear weapons on ground
	AddServerTag("PluginMerkezi");
	
	g_pubg_sure = CreateConVar("sm_pubg_time", "20", "Pubg oyunu başlamadan önceki bekleme süresi kaç saniye olsun.", 0, true, 0.0, true, 60.0);
	g_pubg_spawn = CreateConVar("sm_pubg_spawn", "0", "Bir oyuncunun spawn olduğu yerde başka bir oyuncunun spawn olmamasını sağlar. Cpu tüketimini olumsuz etkileyecektir. Aktif = 1 Pasif = 0", 0, true, 0.0, true, 1.0);
	g_pubg_limit = CreateConVar("sm_pubg_minplayer", "0", "Oyun başlamadan önce en az kaç kişi olsun? (T TAKIMINDA)", 0, true, 0.0, true, 64.0);
	g_Yetkiliflag = CreateConVar("sm_pubg_admin_flag", "b", "Pubg oynunu komutçu harici verebilecek kişilerin yetkisi?");
	g_AirDrops = CreateConVar("sm_pubg_airdrops", "1", "Pubg oynununda Komutçu air drop yollayabilsin mi?", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "Pubg", "Plugin_Merkezi");
	
	m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime");
   	m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
   	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
   	m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress");
}

public void OnMapStart()
{
	MapStartNameControl();
	PrecacheModel("pluginmerkezi/pubg/pubg_Birincil.mdl");
	PrecacheModel("pluginmerkezi/pubg/pubg_Ikincil.mdl");
	PrecacheModel("pluginmerkezi/pubg/pubg_Ex.mdl");
	PrecacheModel("pluginmerkezi/pubg/pubg_bomb.mdl");
	PrecacheModel("player/custom_player/legacy/tm_balkan_variantg.mdl");
	PrecacheModel("props/de_nuke/hr_nuke/metal_crate_001/metal_crate_003_48_low.mdl");
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	g_iSmoke = PrecacheDecal("materials/sprites/smoke.vmt");
	
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_weapon_pickup.mp3");
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_game_end.mp3");
	PrecacheSoundAny("Plugin_Merkezi/PUBG/pubg_game_start.mp3");
}

public Action command_pubg(int client, int args)
{
	g_Yetkiliflag.GetString(YetkiliflagString, sizeof(YetkiliflagString));
	if ((warden_iswarden(client) || YetkiDurum(client, YetkiliflagString)))
	{
		Menu menu = new Menu(pubg_Handle);
		menu.SetTitle("PUBG Menüsü\n▬▬▬▬▬▬▬▬▬▬");
		if (basladi)
			menu.AddItem("Stop", "Oyunu Durdur!\n▬▬▬▬▬▬▬▬▬▬");
		else
			menu.AddItem("Start", "Oyunu Başlat!\n▬▬▬▬▬▬▬▬▬▬");
		
		menu.AddItem("AirDrop", "Bir AirDrop Gönder", g_AirDrops.IntValue == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		if (YetkiDurum(client, "z"))
		{
			if (basladi)
				menu.AddItem("Ayarlar", "Oyunun Ayarları!", ITEMDRAW_DISABLED);
			else
				menu.AddItem("Ayarlar", "Oyunun Ayarları!");
		}
		
		menu.ExitBackButton = false;
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		ReplyToCommand(client, "[SM] \x02PUBG \x01Oyununu Başlatabilmek Için \x0CKomutçu \x01veya \x04Yetkili \x01olmalısın!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int pubg_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char Item[32];
		menu.GetItem(position, Item, sizeof(Item));
		if (StrEqual(Item, "Start", false))
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
			float AimCoords[3];
			GetAimCoords(client, AimCoords);
			SendAirDrop(AimCoords);
			PrintHintText(client, "[PUBG] Air drop yola çıktı!");
		}
		else if (StrEqual(Item, "Ayarlar", false))
		{
			PUBG_AyarMenu_Ac(client);
		}
	}
	if (action == MenuAction_Cancel)
	{
		delete menu;
	}
}

void PUBG_AyarMenu_Ac(int client)
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
	menu.Display(client, MENU_TIME_FOREVER);
}

public int pubg_genelayarmenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (StrEqual(item, "spawn"))
			PUBG_AyarMenu_Ac2(client);
		if (StrEqual(item, "bunny"))
		{
			bac = !bac;
			PUBG_AyarMenu_Ac(client);
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

void PUBG_AyarMenu_Ac2(int client)
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
	menu.Display(client, MENU_TIME_FOREVER);
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
			PUBG_AyarMenu_Ac2(client);
		}
		else if (StrEqual(item, "Show"))
		{
			ShowModels();
			gozukuyor = true;
			PUBG_AyarMenu_Ac2(client);
		}
		else
		{
			int sayi = StringToInt(item);
			LokasyonKaydet(client, sayi);
			PUBG_AyarMenu_Ac2(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Exit)
			PUBG_AyarMenu_Ac(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void SilahlariSpawnla()
{
	for (int i = 0; i < 200; i++)
	{
		if (i <= silahspawn_sayisi)
		{
			g_model = CreateEntityByName("prop_dynamic_override");
			
			char propbuffer[256];
			int sans = GetRandomInt(1, 10);
			if (1 <= sans <= 3)
				Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_birincil.mdl");
			else if (4 <= sans <= 6)
				Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_ikincil.mdl");
			else if (7 <= sans <= 8)
				Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_ex.mdl");
			else if (9 <= sans <= 10)
				Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_bomb.mdl");
			
			DispatchKeyValue(g_model, "model", propbuffer);
			SetEntProp(g_model, Prop_Send, "m_usSolidFlags", 12);
			SetEntProp(g_model, Prop_Data, "m_nSolidType", 6);
			SetEntProp(g_model, Prop_Send, "m_CollisionGroup", 1);
			SetEntPropFloat(g_model, Prop_Send, "m_flModelScale", 0.85);
			DispatchSpawn(g_model);
			
			SetVariantString("challenge_coin_idle");
			AcceptEntityInput(g_model, "SetAnimation");
			TeleportEntity(g_model, konumlar_silah[i], NULL_VECTOR, NULL_VECTOR);
			SDKHook(g_model, SDKHook_StartTouch, OnStartTouch);
			continue;
		}
		else
			break;
	}
}

public Action OnStartTouch(int entity, int client)
{
	if (!(0 < client <= MaxClients) || GetClientTeam(client) != CS_TEAM_T)
		return;
	EmitSoundToClientAny(client, "Plugin_Merkezi/PUBG/pubg_weapon_pickup.mp3", SOUND_FROM_PLAYER, 1, 60);
	
	char modelyolu[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelyolu, sizeof(modelyolu));
	if (StrContains(modelyolu, "pubg_birincil", true) != -1)
	{
		RastgeleSilahCikar(client, 1);
		Ekran_Renk_Olustur(client, { 207, 117, 0, 255 } );
	}
	else if (StrContains(modelyolu, "pubg_bomb", false) != -1)
	{
		RastgeleSilahCikar(client, 2);
		Ekran_Renk_Olustur(client, { 255, 65, 77, 255 } );
	}
	else if (StrContains(modelyolu, "pubg_ikincil", false) != -1)
	{
		RastgeleSilahCikar(client, 3);
		Ekran_Renk_Olustur(client, { 0, 88, 122, 255 } );
	}
	else if (StrContains(modelyolu, "pubg_ex", false) != -1)
	{
		RastgeleSilahCikar(client, 4);
		Ekran_Renk_Olustur(client, { 184, 59, 94, 255 } );
	}
	
	int m_iRotator = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
	if (m_iRotator && IsValidEdict(m_iRotator))
		AcceptEntityInput(m_iRotator, "Kill");
	CreateTimer(0.0, Remove_Entity, entity);
	SDKUnhook(entity, SDKHook_StartTouch, OnStartTouch);
}

public Action Remove_Entity(Handle timer, int entity)
{
	if (IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

void PUBG_Baslat_Pre()
{
	YeriTemizle(1);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			Silahlari_Sil(i);
			CanWalk(i, false);
			SetEntProp(i, Prop_Data, "m_ArmorValue", 0);
			SetEntProp(i, Prop_Send, "m_bHasHelmet", 0);
			int iMelee = GivePlayerItem(i, "weapon_fists");
			EquipPlayerWeapon(i, iMelee);
		}
	}
	basladi = true;
	if (bac)
	{
		SetCvar("sv_enablebunnyhopping", 0);
		SetCvar("sv_autobunnyhopping", 0);
	}
	else
	{
		SetCvar("sv_enablebunnyhopping", 1);
		SetCvar("sv_autobunnyhopping", 1);
	}
	gerisayim_sure = g_pubg_sure.IntValue;
	CreateTimer(1.0, gerisayim, _, TIMER_REPEAT);
}

public Action gerisayim(Handle timer)
{
	if (basladi && gerisayim_sure != 0)
	{
		gerisayim_sure--;
		if (gerisayim_sure == 0)
		{
			PrintHintTextToAll("[PUBG] PUBG Oyunu Başladı !!");
			SilahlariSpawnla();
			EmitSoundToAllAny("Plugin_Merkezi/PUBG/pubg_game_start.mp3", SOUND_FROM_PLAYER, 1, 30);
			FFAyarla(1);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
				{
					CanWalk(i, true);
				}
			}
		}
		else
		{
			PrintHintTextToAll("[PUBG] Oyunun başlamasına son %d saniye.", gerisayim_sure);
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action event_death(Event event, const char[] name, bool dontBroadcast)
{
	if (OyuncuSayisiAl(CS_TEAM_T) == 1)
	{
		FFAyarla(0);
		YeriTemizle(1);
		YeriTemizle(2);
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int victim = GetClientOfUserId(event.GetInt("userid"));
		if (victim == attacker)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					attacker = i;
			}
		}
		basladi = false;
		Silahlari_Sil(attacker);
		GivePlayerItem(attacker, "weapon_knife");
		PrintToChatAll("[SM] \x04Oyunu \x0E%N \x01Kazandı!", attacker);
	}
	return Plugin_Continue;
}

public Action event_end(Event event, const char[] name, bool dontBroadcast)
{
	if (basladi)
	{
		FFAyarla(0);
		basladi = false;
	}
	return Plugin_Continue;
}

void SpawnModel(int Model, float Location[3])
{
	int s_model = CreateEntityByName("prop_dynamic");
	if (Model == 1)
	{
		char propbuffer[256];
		Format(propbuffer, sizeof(propbuffer), "models/player/custom_player/legacy/tm_balkan_variantg.mdl");
		DispatchKeyValue(s_model, "model", propbuffer);
		SetEntPropFloat(s_model, Prop_Send, "m_flModelScale", 1.0);
		SetVariantString("surrender");
	}
	else if (Model == 2)
	{
		char propbuffer[256];
		Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_birincil.mdl");
		DispatchKeyValue(s_model, "model", propbuffer);
		SetEntPropFloat(s_model, Prop_Send, "m_flModelScale", 0.85);
		SetVariantString("none");
	}
	SetEntProp(s_model, Prop_Send, "m_usSolidFlags", 12);
	SetEntProp(s_model, Prop_Data, "m_nSolidType", 6);
	SetEntProp(s_model, Prop_Send, "m_CollisionGroup", 1);
	DispatchSpawn(s_model);
	AcceptEntityInput(s_model, "SetAnimation");
	TeleportEntity(s_model, Location, NULL_VECTOR, NULL_VECTOR);
	SDKHook(s_model, SDKHook_SetTransmit, SetTransmit);
}

public Action SetTransmit(int entity, int client)
{
	if (client == gorenoyuncu)
		return Plugin_Continue;
	else
		return Plugin_Handled;
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
			{
				if (StrContains(weapon, "weapon_") != -1)
					AcceptEntityInput(i, "kill");
			}
		}
		else if (mode == 2)
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", modelyolu, sizeof(modelyolu));
			if (StrContains(modelyolu, "pubg_") != -1 || StrContains(modelyolu, "metal_crate_003_48_low.mdl") != -1)
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

void LokasyonKaydet(int client, int mode)
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