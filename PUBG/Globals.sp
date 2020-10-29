 //ConVar
ConVar g_pubg_sure = null;
ConVar g_pubg_spawn = null;
ConVar g_pubg_limit = null;
ConVar g_Yetkiliflag = null;
ConVar g_AirDrops = null;
ConVar g_AirDrops_Time = null;

// Char
char datayolu[PLATFORM_MAX_PATH];

//Int
int oyuncuspawn_sayisi = 0;
int silahspawn_sayisi = 0;
int m_flSimulationTime = 0;
int m_flProgressBarStartTime = 0;
int m_iProgressBarDuration = 0;
int m_iBlockingUseActionInProgress = 0;
int gorenoyuncu = 0;
int g_BeamSprite = -1;
int g_HaloSprite = -1;
int g_model = -1;
int g_WeaponParent;
int gerisayim_sure = -1;
int g_iPlayerPrevButtons[MAXPLAYERS + 1] =  { 0, ... };
int client_airdrop[MAXPLAYERS + 1] =  { -1, ... };
int takim[MAXPLAYERS + 1][3]; //0 = Client Indexi, 1 = Rengi alıp almadığı, 2 = Onay gönderip göndermediği

// Bool
bool gozukuyor = false;
bool bac = false;
bool duo = false;
bool basladi = false;
bool g_OnceStopped[MAXPLAYERS + 1] = false;
bool sdkhooklandi[MAXPLAYERS + 1] = false;

// Float
float konumlar_spawn[200][3];
float konumlar_silah[200][3];

// Handle
Handle airdrop_timer[MAXPLAYERS + 1] = null; 