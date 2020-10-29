#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <warden>
#include <emitsoundany>

#pragma newdecls required
#pragma semicolon 1

#include "PUBG/Globals.sp"
#include "PUBG/Stocks.sp"
#include "PUBG/Airdrop.sp"
#include "PUBG/Menus.sp" // Tek kişi test için bu spdeki 9 Satırdaki != 1 yerine != 0 yazınız.
#include "PUBG/Locations.sp"
#include "PUBG/Takim.sp"

public Plugin myinfo = 
{
	name = "Playerunkown Battlegrounds - Jailbreak Game", 
	author = "quantum. - Emur - ByDexter(Mentally support)", 
	description = "PUBG plugin specially made for Turkish jailbreak servers.", 
	version = "0.8.1 - Beta", 
	url = "https://pluginmerkezi.com/"
};

public void OnPluginStart()
{
	g_pubg_sure = CreateConVar("sm_pubg_time", "20", "Pubg oyunu başlamadan önceki bekleme süresi kaç saniye olsun.", 0, true, 0.0, true, 60.0);
	g_pubg_spawn = CreateConVar("sm_pubg_spawn", "1", "Bir oyuncunun spawn olduğu yerde başka bir oyuncunun spawn olmamasını sağlar. Cpu tüketimini olumsuz etkileyecektir. Aktif = 1 Pasif = 0", 0, true, 0.0, true, 1.0);
	g_pubg_limit = CreateConVar("sm_pubg_minplayer", "0", "Oyun başlamadan önce en az kaç kişi olsun? (T TAKIMINDA)", 0, true, 0.0, true, 64.0);
	g_Yetkiliflag = CreateConVar("sm_pubg_admin_flag", "b", "Pubg oynunu komutçu harici verebilecek kişilerin yetkisi?", FCVAR_NOTIFY);
	g_AirDrops = CreateConVar("sm_pubg_airdrops", "1", "Pubg oynununda Komutçu air drop yollayabilsin mi?", 0, true, 0.0, true, 1.0);
	g_AirDrops_Time = CreateConVar("sm_pubg_airdrops_time", "5", "AirDrop kaç saniyede açılsın", 0, true, 1.0, true, 20.0);
	AutoExecConfig(true, "Pubg", "PluginMerkezi");
	
	RegConsoleCmd("sm_pubg", command_pubg);
	RegConsoleCmd("sm_pubgtakim", command_pubgtakim);
	
	CreateDirectory("addons/sourcemod/data/PluginMerkezi/Pubg", 3);
	BuildPath(Path_SM, datayolu, sizeof(datayolu), "data/PluginMerkezi/Pubg/locations.txt");
	
	HookEvent("player_death", OnClientDeath, EventHookMode_Post);
	HookEvent("round_start", RoundStartEnd);
	HookEvent("round_end", RoundStartEnd);
	g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity"); //For clear weapons on ground
	m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime"); // For AirDrop Opening Effect
	m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime"); // For AirDrop Opening Effect
	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration"); // For AirDrop Opening Effect
	m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress"); // For AirDrop Opening Effect----
	
	AddServerTag("PluginMerkezi");
}

public void OnMapStart()
{
	MapStartNameControl();
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

public Action command_pubg(int client, int args)
{
	char YetkiliflagString[2];
	g_Yetkiliflag.GetString(YetkiliflagString, sizeof(YetkiliflagString));
	if ((warden_iswarden(client) || YetkiDurum(client, YetkiliflagString))) {
		Menu menu = new Menu(pubg_Handle);
		menu.SetTitle("PUBG Menüsü\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
		if (basladi)
			menu.AddItem("Stop", "Oyunu Durdur!");
		else
			menu.AddItem("Start", "Oyunu Başlat!");
		
		menu.AddItem("AirDrop", "Bir AirDrop Gönder\n▬▬▬▬▬▬▬▬▬▬▬▬▬", g_AirDrops.IntValue == 1 ? basladi ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED : ITEMDRAW_DISABLED);
		
		menu.AddItem("Ayarlar", "Oyunun Ayarları!", basladi ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		
		menu.ExitBackButton = false;
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		ReplyToCommand(client, "[SM] \x02PUBG \x01Menüsüne Erişim Icin \x0CKomutçu \x01veya \x04Yetkili \x01olmalısın!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
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
	if (duo)
		TakimSifirla();
	YeriTemizle(1);
	basladi = true;
	gerisayim_sure = g_pubg_sure.IntValue;
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
	CreateTimer(1.0, gerisayim, _, TIMER_REPEAT);
}

public Action gerisayim(Handle timer)
{
	if (basladi && gerisayim_sure != 0)
	{
		gerisayim_sure--;
		if (gerisayim_sure == 0)
		{
			if (duo)
			{
				TakimlariBoya();
			}
			PrintHintTextToAll("[PUBG] PUBG Oyunu Başladı !!");
			SilahlariSpawnla();
			EmitSoundToAllAny("Plugin_Merkezi/PUBG/pubg_game_start.mp3", SOUND_FROM_PLAYER, 1, 30);
			FFAyarla(1);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
				{
					CanWalk(i, true);
					if (takim[i][0] != -1 && duo)
					{
						sdkhooklandi[i] = true;
						SDKHook(i, SDKHook_OnTakeDamage, damagealinca);
					}
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

public Action OnClientDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (duo)
	{
		if (OyuncuSayisiAl(CS_TEAM_T) == 2 && takim[attacker][0] != -1 && IsPlayerAlive(takim[attacker][0]))
		{
			FinishTheGame();
			if (IsValidClient(attacker))
			{
				Silahlari_Sil(attacker);
				GivePlayerItem(attacker, "weapon_knife");
			}
			if (IsValidClient(takim[attacker][0]))
			{
				Silahlari_Sil(takim[attacker][0]);
				GivePlayerItem(takim[attacker][0], "weapon_knife");
			}
			PrintToChatAll("[SM] \x04Oyunu \x0E%N ve \x0E%N \x01Kazandı!", attacker, takim[attacker][0]);
		}
		else if (OyuncuSayisiAl(CS_TEAM_T) == 1)
		{
			FinishTheGame();
			if (victim == attacker)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						attacker = i;
				}
			}
			if (IsValidClient(attacker))
			{
				Silahlari_Sil(attacker);
				GivePlayerItem(attacker, "weapon_knife");
				PrintToChatAll("[SM] \x04Oyunu \x0E%N \x01Kazandı!", attacker);
			}
		}
	}
	else
	{
		if (OyuncuSayisiAl(CS_TEAM_T) == 1)
		{
			FinishTheGame();
			if (victim == attacker)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						attacker = i;
				}
			}
			if (IsValidClient(attacker))
			{
				Silahlari_Sil(attacker);
				GivePlayerItem(attacker, "weapon_knife");
				PrintToChatAll("[SM] \x04Oyunu \x0E%N \x01Kazandı!", attacker);
			}
		}
	}
	return Plugin_Continue;
}

public Action RoundStartEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (basladi)
	{
		if (duo)
		{
			FinishTheGame();
			return Plugin_Continue;
		}
		FFAyarla(0);
		basladi = false;
	}
	return Plugin_Continue;
}

void SpawnModel(int Model, float Location[3])
{
	int s_model = CreateEntityByName("prop_dynamic");
	char propbuffer[256];
	if (Model == 1)
	{
		Format(propbuffer, sizeof(propbuffer), "models/player/custom_player/legacy/tm_balkan_variantg.mdl");
		SetEntPropFloat(s_model, Prop_Send, "m_flModelScale", 1.0);
	}
	else if (Model == 2)
	{
		Format(propbuffer, sizeof(propbuffer), "models/pluginmerkezi/pubg/pubg_birincil.mdl");
		SetEntPropFloat(s_model, Prop_Send, "m_flModelScale", 0.85);
	}
	DispatchKeyValue(s_model, "model", propbuffer);
	SetEntProp(s_model, Prop_Send, "m_usSolidFlags", 12);
	SetEntProp(s_model, Prop_Data, "m_nSolidType", 6);
	SetEntProp(s_model, Prop_Send, "m_CollisionGroup", 1);
	DispatchSpawn(s_model);
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