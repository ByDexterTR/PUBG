int g_iPlayerPrevButtons[MAXPLAYERS + 1];
bool g_OnceStopped[MAXPLAYERS + 1];
int m_flSimulationTime, m_flProgressBarStartTime, m_iProgressBarDuration, m_iBlockingUseActionInProgress;

int client_airdrop[MAXPLAYERS + 1] = -1;
Handle airdrop_timer[MAXPLAYERS + 1] = null;
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	//İlk E basışı
	if(!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) 
	{
		int ent = GetClientAimTarget(client, false);
		if(IsValidEntity(ent))
		{
			char sName[33];
			GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));
		    if(StrEqual(sName, "airdrop"))
		    {
				if(GetEntitiesDistance(client, ent) < 50.0)
				{
					SetProgressBar(client, 10);
					client_airdrop[client] = ent;
					airdrop_timer[client] = CreateTimer(10.0, airdropac, client, TIMER_FLAG_NO_MAPCHANGE);
					g_OnceStopped[client] = true;
				}
			}
		}	
	}
	
	//E'ye basılı tutarken
	else if (iButtons & IN_USE) {
		
	}
	
	//E'ye basmayı bırakınca
	else if(g_OnceStopped[client]) {
		g_iPlayerPrevButtons[client] = 0;
		g_OnceStopped[client] = false;
		delete airdrop_timer[client];
		airdrop_timer[client] = null;
		ResetProgressBar(client);
	}
	
	g_iPlayerPrevButtons[client] = iButtons;
}

public Action airdropac(Handle timer, int client)
{
	ResetProgressBar(client);
	Ekran_Renk_Olustur(client, { 207, 117, 0, 255 });
	if(client_airdrop[client] && IsValidEdict(client_airdrop[client]))
		AcceptEntityInput(client_airdrop[client], "Kill");
	return Plugin_Handled;
}

public void OnClientConnected(int client)
{
	for (int i = 1; i < MaxClients; i++)
		if(IsClientInGame(i)) 
			SetListenOverride(client, i, Listen_Yes);

}

void SetProgressBar(int iClient, int iProgressTime)
{
    float flGameTime = GetGameTime();

    SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + float(iProgressTime), true);
    SetEntData(iClient, m_iProgressBarDuration, iProgressTime, 4, true);
    SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime, true);

    // Progress bar type 0-15
    SetEntData(iClient, m_iBlockingUseActionInProgress, 15, 4, true);
}
void ResetProgressBar(int iClient)
{
    SetEntDataFloat(iClient, m_flProgressBarStartTime, 0.0, true);
    SetEntData(iClient, m_iProgressBarDuration, 0, 1, true);
}

stock float GetEntitiesDistance(ent1, ent2)
{
	float orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	float orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
}