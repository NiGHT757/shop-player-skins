#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>
#include <karyuu>

int g_iPreviewDelay;
int g_iPreviewEntity[MAXPLAYERS+1];
int g_iDelay[MAXPLAYERS+1];
int g_iPreviewGlowColors[4];

char g_sDefaultModelCT[PLATFORM_MAX_PATH];	// default ct model
char g_sDefaultModelT[PLATFORM_MAX_PATH]; // default t model
char g_sModelCT[MAXPLAYERS+1][64];
char g_sModelT[MAXPLAYERS+1][64];
char g_sCategoryCT[64];
char g_sCategoryT[64];
char g_sPreviewRotateSpeed[8];

float g_fDelayBeforeSpawn;

bool g_bPreviewRotateModel;
bool g_bPreviewGlowModel;

StringMap g_hModels;
StringMap g_hArmsModels;
StringMap g_hFlags;

public Plugin myinfo = 
{
	name = "Shop - Player Skin Module (gloves support(somehow))",
	author = "NiGHT, nuclear silo, AiDN™, azalty, R1ko",
	description = "",
	version = "1.1",
	url = "github.com/NiGHT757/shop-player-skins"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	if (Shop_IsStarted()) Shop_Started();

	LoadTranslations("shop_skins.phrases");
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

Action cmd_reloadmodels(int client, int args)
{
	if (Shop_IsStarted())
	{
		Shop_UnregisterMe();
		Shop_Started();
		
		CReplyToCommand(client, "%T", "1", client);
		return Plugin_Handled;
	}

	CReplyToCommand(client, "%T", "2", client);
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	g_sModelCT[client][0] = '\0';
	g_sModelT[client][0] = '\0';
}

public void OnMapStart()
{	
	if(!g_hModels)
		return;
	
	if(g_sDefaultModelCT[0])
		PrecacheModel(g_sDefaultModelCT, true);
	if(g_sDefaultModelT[0])
		PrecacheModel(g_sDefaultModelT, true);
	
	char sModel[PLATFORM_MAX_PATH], sKey[64];

	StringMapSnapshot hSnapShot;

	hSnapShot = g_hModels.Snapshot();
	for(int i = 0, iLength = hSnapShot.Length; i < iLength; i++)
	{
		hSnapShot.GetKey(i, sKey, sizeof(sKey));
		if(g_hModels.GetString(sKey, sModel, sizeof(sModel)))
			PrecacheModel(sModel, true);
	}
	delete hSnapShot;


	hSnapShot = g_hArmsModels.Snapshot();
	for(int i = 0, iLength = hSnapShot.Length; i < iLength; i++)
	{
		hSnapShot.GetKey(i, sKey, sizeof(sKey));
		if(g_hArmsModels.GetString(sKey, sModel, sizeof(sModel)))
			PrecacheModel(sModel, true);
	}
	delete hSnapShot;
}

public void Shop_Started()
{
	delete g_hModels;
	delete g_hArmsModels;
	delete g_hFlags;

	g_hModels 		= new StringMap();
	g_hArmsModels 	= new StringMap();
	g_hFlags 		= new StringMap();

	char _buffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(_buffer, sizeof(_buffer), "skins.txt");

	KeyValues kv = new KeyValues("Skins");
	if(!kv.ImportFromFile(_buffer))
		SetFailState("Config %s doesn't exist", _buffer);

	char sName[64], sDescription[64], sCommands[256];


// **************************************** REGISTER COMMANDS **************************************** //
	kv.GetString("reload_config_commands", sCommands, sizeof(sCommands), "sm_shop_reloadmodels");
	kv.GetString("reload_config_commands_acces", sName, sizeof(sName), "z");
	kv.GetString("reload_config_commands_description", sDescription, sizeof(sDescription), "Reload 'Shop - Player Skin Module' config");

	Karyuu_RegMultipleCommand(sCommands, cmd_reloadmodels, sDescription, ReadFlagString(sName));
// **************************************** REGISTER COMMANDS **************************************** //

// **************************************** REGISTER CATEGORY **************************************** //
	kv.GetString("category_ct", g_sCategoryCT, sizeof(g_sCategoryCT));
	kv.GetString("category_ct_display_name", sName, sizeof(sName), "Counter-Terrorists");
	kv.GetString("category_ct_description", sDescription, sizeof(sDescription), "");

	CategoryId category_id_ct;
	if(g_sCategoryCT[0])
	{
		category_id_ct = Shop_RegisterCategory(g_sCategoryCT, sName, sDescription);
	}

	kv.GetString("category_t", g_sCategoryT, sizeof(g_sCategoryT));
	kv.GetString("category_t_display_name", sName, sizeof(sName), "Terrorists");
	kv.GetString("category_t_description", sDescription, sizeof(sDescription), "");

	CategoryId category_id_t;
	if(g_sCategoryT[0])
	{
		category_id_t = Shop_RegisterCategory(g_sCategoryT, sName, sDescription);
	}
// **************************************** REGISTER CATEGORY **************************************** //


// **************************************** LOAD SETTINGS **************************************** //
	g_fDelayBeforeSpawn 	= kv.GetFloat("delay_before_set_spawn");
	g_iPreviewDelay 		= kv.GetNum("preview_delay");
	g_bPreviewGlowModel		= !!kv.GetNum("preview_glow_model", 1);
	g_bPreviewRotateModel	= !!kv.GetNum("preview_rotate_model", 1);

	kv.GetColor4("preview_glow_color", g_iPreviewGlowColors);
	kv.GetString("preview_rotate_speed", g_sPreviewRotateSpeed, sizeof(g_sPreviewRotateSpeed), "60");

	//PrintToServer("Settings loaded: g_fDelayBeforeSpawn[%.2f] - g_iPreviewDelay[%d] - g_bPreviewGlowModel[%d] - g_bPreviewRotateModel[%d] - g_iPreviewGlowColors[%d %d %d %d]", g_fDelayBeforeSpawn, g_iPreviewDelay, g_bPreviewGlowModel, g_bPreviewRotateModel, g_iPreviewGlowColors[0], g_iPreviewGlowColors[1], g_iPreviewGlowColors[2], g_iPreviewGlowColors[3]);
// **************************************** LOAD SETTINGS **************************************** //


// **************************************** DEFAULT MODELS **************************************** //
	kv.GetString("default_model_ct", g_sDefaultModelCT, sizeof(g_sDefaultModelCT));
	TrimString(g_sDefaultModelCT);
	if(g_sDefaultModelCT[0])
	{
		TrimString(g_sDefaultModelCT);
		if(!FileExists(g_sDefaultModelCT) || !PrecacheModel(g_sDefaultModelCT, true))
		{
			LogAction(-1, -1, "Arms model %s doesn't exist, skipping...", g_sDefaultModelCT);
			g_sDefaultModelCT[0] = '\0';
		}
	}

	kv.GetString("default_model_t", g_sDefaultModelT, sizeof(g_sDefaultModelT));
	TrimString(g_sDefaultModelT);
	if(g_sDefaultModelT[0])
	{
		TrimString(g_sDefaultModelT);
		if(!FileExists(g_sDefaultModelT) || !PrecacheModel(g_sDefaultModelT, true))
		{
			LogAction(-1, -1, "Arms model %s doesn't exist, skipping...", g_sDefaultModelT);
			g_sDefaultModelT[0] = '\0';
		}
	}
// **************************************** DEFAULT MODELS **************************************** //


// **************************************** REGISTER ITEMS **************************************** //
	char sItemName[64], sFlags[8];

	if(kv.GotoFirstSubKey())
	{
		do{
			kv.GetSectionName(sName, sizeof(sName));

			kv.GetString("model", _buffer, sizeof(_buffer));
			if(_buffer[0])
			{
				TrimString(_buffer);
				if(!FileExists(_buffer) || !PrecacheModel(_buffer, true))
				{
					LogAction(-1, -1, "Model %s doesn't exist, skipping...", _buffer);
					continue;
				}

				g_hModels.SetString(sName, _buffer);
			}

			kv.GetString("arms", _buffer, sizeof(_buffer));
			if(_buffer[0])
			{
				TrimString(_buffer);
				if(!FileExists(_buffer) || !PrecacheModel(_buffer, true))
				{
					LogAction(-1, -1, "Arms model %s doesn't exist, skipping...", _buffer);
					continue;
				}

				g_hArmsModels.SetString(sName, _buffer);
			}

			kv.GetString("name", sItemName, sizeof(sItemName), sName);
			kv.GetString("description", sDescription, sizeof(sDescription), "");
			kv.GetString("flags", sFlags, sizeof(sFlags));

			if(sFlags[0])
				g_hFlags.SetValue(sName, ReadFlagString(sFlags));

			switch(kv.GetNum("team"))
			{
				case 2:
				{
					if(category_id_t && Shop_StartItem(category_id_t, sName))
					{
						Shop_SetInfo(sItemName, sDescription, kv.GetNum("price", 1000), kv.GetNum("sell_price", 500), Item_Togglable, kv.GetNum("duration", 86400), kv.GetNum("gold_price", -1), kv.GetNum("gold_sell_price", -1));
						Shop_SetLuckChance(kv.GetNum("luckchance", 10));
						Shop_SetHide(view_as<bool>(kv.GetNum("hide", 0)));

						Shop_SetCallbacks(INVALID_FUNCTION, OnEquipItem, INVALID_FUNCTION, sFlags[0] ? OnItemDisplay : INVALID_FUNCTION, INVALID_FUNCTION, kv.GetNum("preview") == 1 ? OnPreviewItem : INVALID_FUNCTION, sFlags[0] ? OnItemBuy : INVALID_FUNCTION);
						Shop_EndItem();
					}
				}
				case 3:
				{
					if(category_id_ct && Shop_StartItem(category_id_ct, sName))
					{
						Shop_SetInfo(sItemName, sDescription, kv.GetNum("price", 1000), kv.GetNum("sell_price", 500), Item_Togglable, kv.GetNum("duration", 86400), kv.GetNum("gold_price", -1), kv.GetNum("gold_sell_price", -1));
						Shop_SetLuckChance(kv.GetNum("luckchance", 10));
						Shop_SetHide(view_as<bool>(kv.GetNum("hide", 0)));
						Shop_SetCallbacks(INVALID_FUNCTION, OnEquipItem, INVALID_FUNCTION, sFlags[0] ? OnItemDisplay : INVALID_FUNCTION, INVALID_FUNCTION, kv.GetNum("preview") == 1 ? OnPreviewItem : INVALID_FUNCTION, sFlags[0] ? OnItemBuy : INVALID_FUNCTION);
						Shop_EndItem();
					}
				}
			}
		}
		while(kv.GotoNextKey());
	}
// **************************************** REGISTER ITEMS **************************************** //

	delete kv;
}


bool OnItemDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
	int iFlags;
	g_hFlags.GetValue(item, iFlags);
	if(iFlags && GetUserFlagBits(client) & iFlags != iFlags)
	{
		disabled = true;
		return true;
	}
	return false;
}

ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		if(strcmp(category, g_sCategoryCT) == 0)
		{
			g_sModelCT[client][0] = '\0';
		}
		else if(strcmp(category, g_sCategoryT) == 0)
		{
			g_sModelT[client][0] = '\0';
		}

		return Shop_UseOff;
	}

	int iFlags;
	g_hFlags.GetValue(item, iFlags);
	if(iFlags && GetUserFlagBits(client) & iFlags != iFlags)
	{
		CPrintToChat(client, "%T", "3", client);
		return Shop_UseOff;
	}

	if(strcmp(category, g_sCategoryCT) == 0)
	{
		strcopy(g_sModelCT[client], sizeof(g_sModelCT), item);
	}
	else if(strcmp(category, g_sCategoryT) == 0)
	{
		strcopy(g_sModelT[client], sizeof(g_sModelT), item);
	}

	Shop_ToggleClientCategoryOff(client, category_id);

	return Shop_UseOn;
}

bool OnItemBuy(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value)
{
	int iFlags;
	g_hFlags.GetValue(item, iFlags);
	if(iFlags && GetUserFlagBits(client) & iFlags != iFlags)
	{
		CPrintToChat(client, "%T", "4", client);
		return false;
	}
	return true;
}

void OnPreviewItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item)
{
	int entity = CreateEntityByName("prop_dynamic_override");
	if(entity == -1)
		return;

	int iTime = GetTime();
	if(g_iDelay[client] > iTime)
	{
		CPrintToChat(client, "%T", "5", client, g_iDelay[client] - iTime);
		return;
	}
	g_iDelay[client] = iTime + g_iPreviewDelay;

	char sModel[PLATFORM_MAX_PATH];
	g_hModels.GetString(item, sModel, sizeof(sModel));

	float fOrigin[3], fAngles[3], fRad[2], fPosition[3];

	GetClientAbsOrigin(client, fOrigin);
	GetClientAbsAngles(client, fAngles);

	fRad[0] = DegToRad(fAngles[0]);
	fRad[1] = DegToRad(fAngles[1]);

	fPosition[0] = fOrigin[0] + 64 * Cosine(fRad[0]) * Cosine(fRad[1]);
	fPosition[1] = fOrigin[1] + 64 * Cosine(fRad[0]) * Sine(fRad[1]);
	fPosition[2] = fOrigin[2] + 4 * Sine(fRad[0]);

	fAngles[0] *= -1.0;
	fAngles[1] *= -1.0;
	
	DispatchKeyValue(entity, "model", sModel);
	DispatchKeyValue(entity, "spawnflags", "64");
	TeleportEntity(entity, fPosition, fAngles, NULL_VECTOR);
	DispatchSpawn(entity);

	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

	SetVariantString("OnUser1 !self:FadeAndKill::5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	int offset;
	if(g_bPreviewGlowModel && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) != -1)
	{
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
		SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
		SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 2000.0);

		SetEntData(entity, offset, g_iPreviewGlowColors[0], _, true);
		SetEntData(entity, offset + 1, g_iPreviewGlowColors[1], _, true);
		SetEntData(entity, offset + 2, g_iPreviewGlowColors[2], _, true);
		SetEntData(entity, offset + 3, g_iPreviewGlowColors[3], _, true);
	}

	int iRotator;
	if(g_bPreviewRotateModel && (iRotator = CreateEntityByName("func_rotating")) != -1)
	{
		DispatchKeyValueVector(iRotator, "origin", fPosition);

		DispatchKeyValue(iRotator, "maxspeed", g_sPreviewRotateSpeed);
		DispatchKeyValue(iRotator, "spawnflags", "64");
		DispatchSpawn(iRotator);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", iRotator, iRotator);
		AcceptEntityInput(iRotator, "Start");
	}
	g_iPreviewEntity[client] = EntIndexToEntRef(entity);

	SDKHook(entity, SDKHook_SetTransmit, SetTransmitSkin);
}

Action SetTransmitSkin(int entity, int client)
{
	if (g_iPreviewEntity[client] == INVALID_ENT_REFERENCE)
	{
		return Plugin_Handled;
	}

	if (entity == EntRefToEntIndex(g_iPreviewEntity[client]))
		return Plugin_Continue;

	return Plugin_Handled;
}

void Event_PlayerSpawn(Event event, const char[] name, bool db)
{
	static int client;
	client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsPlayerAlive(client))
		return;
	
	CreateTimer(g_fDelayBeforeSpawn, timer_setmodel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action timer_setmodel(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(!client)
		return Plugin_Stop;

	static char sModel[PLATFORM_MAX_PATH];

	switch(GetClientTeam(client))
	{
		case 2:
		{
			if(g_sModelT[client][0])
			{
				g_hModels.GetString(g_sModelT[client], sModel, sizeof(sModel));
				SetEntityModel(client, sModel);

				if(GetEntPropEnt(client, Prop_Send, "m_hMyWearables") == -1 && g_hArmsModels.GetString(g_sModelT[client], sModel, sizeof(sModel)))
					SetEntPropString(client, Prop_Send, "m_szArmsModel", sModel);

				return Plugin_Stop;
			}

			if(g_sDefaultModelT[0])
			{
				SetEntityModel(client, g_sDefaultModelT);
				return Plugin_Stop;
			}
		}
		case 3:
		{
			if(g_sModelCT[client][0])
			{
				g_hModels.GetString(g_sModelCT[client], sModel, sizeof(sModel));
				SetEntityModel(client, sModel);

				if(GetEntPropEnt(client, Prop_Send, "m_hMyWearables") == -1 && g_hArmsModels.GetString(g_sModelCT[client], sModel, sizeof(sModel)))
					SetEntPropString(client, Prop_Send, "m_szArmsModel", sModel);

				return Plugin_Stop;
			}

			if(g_sDefaultModelCT[0])
			{
				SetEntityModel(client, g_sDefaultModelCT);
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Stop;
}