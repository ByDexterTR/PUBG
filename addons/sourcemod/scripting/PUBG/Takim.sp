public Action command_pubgtakim(int client, int args)
{
	if (basladi)
	{
		if (!duo)
			ReplyToCommand(client, "[SM] \x01Pubg şuanda takımsız oynanıyor.");
		else if (takim[client][2] != 1 && duo)
		{
			takim[client][2] = 1;
			takim_OyuncuMenusuAc().Display(client, MENU_TIME_FOREVER);
		}
		else if (takim[client][0] != -1)
			ReplyToCommand(client, "[SM] \x01Zaten bir takımdasın.");
		else
			ReplyToCommand(client, "[SM] \x01Bir oyuncuya takım isteği göndermişsin. Cevap vermesini beklemelisin.");
	}
	else
		ReplyToCommand(client, "[SM] \x01Bu komutu sadece \x02PUBG \x01oynanırken kullanabilirsin.");
}

void TakimlariBoya()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && takim[i][0] != -1 && takim[i][1] == -1)
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
	if (takim[attacker][0] == victim)
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
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			SetEntityRenderColor(i, 255, 255, 255);
	}
}


