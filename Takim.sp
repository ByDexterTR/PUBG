public Action command_pubgtakim(int client, int args)
{
	if(basladi) //Şimdilik test için !basladi yapıyorum siz düzeltirsiniz.
	{
		if(takim[client][2] != 1 && duo)
		{
			takim[client][2] = 1;
			takim_OyuncuMenusuAc(client);
		}
		else if(!duo)
			ReplyToCommand(client, " \x0B[PUBG] \x01Pubg şuanda takımsız modda oynanıyor.");
		else if(takim[client][0] != -1)
			ReplyToCommand(client, " \x0B[PUBG] \x01Zaten bir takımdasın.");
		else
			ReplyToCommand(client, " \x0B[PUBG] \x01Bir oyuncuya takım isteği göndermişsin. Cevap vermesini beklemelisin.");
	}
	else
		ReplyToCommand(client, " \x0B[PUBG] \x01Bu komutu sadece \x07PUBG \x01oynanırken kullanabilirsin.");
}

void TakimlariBoya()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && takim[i][0] != -1 && takim[i][1] == -1)
		{
			int r = GetRandomInt(0, 255), g = GetRandomInt(0, 255), b = GetRandomInt(0, 255);
			SetEntityRenderColor(i, r, g, b, 255);
			SetEntityRenderColor(takim[i][0], r, g, b, 255);
			takim[i][1] = 1;
		}		
	}
}


public Action damagealinca(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(takim[attacker][0] == victim)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void TakimSifirla()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		takim[i][0] = -1;
		takim[i][1] = -1;
		takim[i][2] = -1;
		sdkhooklandi[i] = false;
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			SetEntityRenderColor(i, 255, 255, 255);
	}
}


