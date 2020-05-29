AddCSLuaFile("shared.lua")
include("shared.lua")

local fol = GM.FolderName.."/gamemode/modules/"

PHDayZ = PHDayZ or {} -- Setup Config Table Early!

PHDayZ_StartUpErrors = PHDayZ_StartUpErrors or {}
PHDayZ_CriticalErrors = PHDayZ_CriticalErrors or {}

-- Load modules...
local files, folders = file.Find(fol .. "*", "LUA")
for k,v in pairs(files) do
	include(fol .. v)
end

if !PHDayZ.DisableStartupInfo then
	MsgC( Color(255,0,255), "[PHDayZ] Legend: ", Color(0,255,255), "Server ", Color(147,112,219), "Shared ", Color(255,165,0), "Client\n" )
end

for _, folder in SortedPairs(folders, true) do
	if folder == "." or folder == ".." then continue end

	for _, File in SortedPairs(file.Find(fol .. folder .."/sh_*.lua", "LUA"), true) do
		if !PHDayZ.DisableStartupInfo then
			MsgC( Color(255,255,0), "[PHDayZ] Loading+Pooling SHARED file: " .. File .. "\n" )
		end
		AddCSLuaFile(fol..folder .. "/" ..File)
		include(fol.. folder .. "/" ..File)
	end
end

hook.Run("DZ_PreInitialLoad")

if !PHDayZ.DisableStartupInfo then
	Msg("======================================================================\n")
end

for _, folder in SortedPairs(folders, true) do
	if folder == "." or folder == ".." then continue end

	for _, File in SortedPairs(file.Find(fol .. folder .."/sv_*.lua", "LUA"), true) do
		if !PHDayZ.DisableStartupInfo then
			MsgC( Color(0,255,255), "[PHDayZ] Loading SERVER file: " .. File .. "\n" )
		end
		include(fol.. folder .. "/" ..File)
	end
end

if !PHDayZ.DisableStartupInfo then
	Msg("======================================================================\n")
end

for _, folder in SortedPairs(folders, true) do
	if folder == "." or folder == ".." then continue end

	for _, File in SortedPairs(file.Find(fol .. folder .."/cl_*.lua", "LUA"), true) do
		if !PHDayZ.DisableStartupInfo then
			MsgC( Color(255,100,0), "[PHDayZ] Pooling CLIENT file: " .. File .. "\n" )
		end
		AddCSLuaFile(fol.. folder .. "/" ..File)
	end
end
if !PHDayZ.DisableStartupInfo then
	Msg("======================================================================\n")
	MsgC( Color(255,0,255), "[PHDayZ] Legend: ", Color(0,255,255), "Server ", Color(255,255,0), "Shared ", Color(255,100,0), "Client\n" )
end

hook.Run("DZ_InitialLoad")

function GM:Initialize()
   MsgN("[PHDayZ] DayZ Server initializing...")
   --RunConsoleCommand("_dz_request_serverlang")
end

function DZ_OR()

	if string.lower(game.GetMap()) == "rp_pripyat" then
		resource.AddWorkshop(254639395) -- RP_Pripyat Map
		resource.AddWorkshop(258864663) -- RP_Pripyat Map Content
	elseif string.lower(game.GetMap()) == "rp_pripyat_fixed" then
		resource.AddWorkshop(276686583) -- rp_pripyat_fixed Map
	elseif string.lower(game.GetMap()) == "rp_evocity2_v2p_fixed" then
		--resource.AddWorkshop(250337605) -- Evocity2 Map
		resource.AddWorkshop(250346846) -- Evocity2 Map Content
	elseif string.lower(game.GetMap()) == "rp_stalker" then
		resource.AddWorkshop(129589968) -- RP_Stalker Map
		resource.AddWorkshop(165772389) -- RP_Stalker Map Content
	elseif string.lower(game.GetMap()) == "rp_headattackcity_v1_linux" then
		resource.AddWorkshop(502181213) -- Map Content
		resource.AddWorkshop(502154494) -- Map
	elseif string.lower(game.GetMap()) == "zs_headattackcity_v1_linux" then
		resource.AddWorkshop(501255467) -- Map Content
		resource.AddWorkshop(501251608) -- Map
	elseif string.lower(game.GetMap()) == "gm_fork" then
		resource.AddWorkshop(326332456) -- GM_Fork Map
	elseif string.lower(game.GetMap()) == "rp_stalker_thatgmodzserver" then
		resource.AddWorkshop(487172831) -- stalker_thatgmodzserver Map
	elseif string.lower(game.GetMap()) == "gm_boreas" then 
		resource.AddWorkshop(1572373847) -- gm_boreas Map
		resource.AddWorkshop(1572873581) -- gm_boreas Map Content
	elseif string.lower(game.GetMap()) == "rp_chaos_city_v33x_03" then
		resource.AddWorkshop(296403366) -- map
		resource.AddWorkshop(296391343) -- c 1
		resource.AddWorkshop(296396662) -- c 2
		resource.AddWorkshop(296399858) -- c 3
	elseif string.lower(game.GetMap()) == "dayz_ghosttown_fixed" then
		resource.AddWorkshop(1701759215)
	end

	resource.AddWorkshop(349050451) -- CW2.0 Main
	resource.AddWorkshop(707343339) -- CW2.0 Melee
	resource.AddWorkshop(358608166) -- CW2.0 Extra
	resource.AddWorkshop(737076540) -- CW2.0 Apocalyptic Machete

	if VJBASE_VERSION != nil then
		-- vjbase is loaded.
		resource.AddWorkshop(131759821) -- vjbase
		resource.AddWorkshop(152529683) -- zombie snpcs
	end

	resource.AddWorkshop(431067405) -- GMod DayZ Content Pack - Part #1
	resource.AddWorkshop(431069048) -- GMod DayZ Content Pack - Part #2
	resource.AddWorkshop(804903699) -- Hazmat
	resource.AddWorkshop(1591779626) -- DangerZone sweps by Shekelstein
	resource.AddWorkshop(1586738099) -- csgo kevlar armor
	resource.AddWorkshop(233864270) -- css fish

	-- khris weapons for cw2.0
	resource.AddWorkshop(886156547) -- revolvers
	resource.AddWorkshop(886125449) -- pistols
	resource.AddWorkshop(886132509) -- smgs
	resource.AddWorkshop(886148959) -- shotguns
	resource.AddWorkshop(886451400) -- shared content
	resource.AddWorkshop(886137508) -- rifles
	resource.AddWorkshop(886146194) -- ranged rifles
	resource.AddWorkshop(886153712) -- heavy weapons

	if game.GetIPAddress() == "176.57.128.5:27055" then
		--print("Detected Official server, adding extra resources...")

		resource.AddWorkshop(549224132) -- skateboards
		resource.AddWorkshop(246756300) -- radio
		resource.AddWorkshop(104540875) -- trampoline

		resource.AddWorkshop(522764555) -- vj animals
		resource.AddWorkshop(1302342357) -- vj insurgents
		resource.AddWorkshop(1202342807) -- insurgents content
		resource.AddWorkshop(708225419) -- ladder tool
		resource.AddWorkshop(331192490) -- buildings/roads pack
		resource.AddWorkshop(503326467) -- Houses prop pack

	end

end

function GM:InitPostEntity()
   MsgN("[PHDayZ] DayZ Server post-init...")

   --RunConsoleCommand("_dz_request_serverlang")
end

hook.Add("InitPostEntity", "zWelcomeTo", function()
	DZ_OR() -- if game.GetIPAddress is called too early, resource again, who cares.
	
	timer.Create( "reresource", 10, 0, function() DZ_OR() end ) -- for some reason they're not always resourced.

	PHDayZ_CheckDBSetup() -- Make sure the database is setup automatically and connected.

	local mapindex = table.KeyFromValue( MapIndex, 	string.lower(game.GetMap()) )
	if !mapindex then
		table.insert(PHDayZ_CriticalErrors, "Database MapIndex not set! Modify config/sh_models.lua")
	end
	
	if !PLib then
		table.insert(PHDayZ_CriticalErrors, "PLib not found!")
		table.insert(PHDayZ_CriticalErrors, "MySQL Database is not connected! PLib module missing!")
	end

	if FilesMissing then
		table.insert(PHDayZ_CriticalErrors, "Missing Files! ABORT!")
	end
	
	if CustomizableWeaponry then CustomizableWeaponry.suppressOnSpawnAttachments = true end

	hook.Run("DZ_PostInitialLoad")

	timer.Simple(3, function()
	
		if PLib and !PLib.MySQLActive then
			table.insert(PHDayZ_CriticalErrors, "MySQL Database is not connected! Incorrect credentials? See errors above.")
		end
	
		Msg("\n")
		MsgC(Color(255,255,0), [[	```___```````````___Welcome To: _____]]) Msg("\n")
		MsgC(Color(255,255,0), [[	``/`_`\ /\/\````/```\__`_`_```_/`_``/]]) Msg("\n")
		MsgC(Color(255,255,0), [[	`/`/_\//````\``/`/\`/`_``|`|`|`\//`/`]]) Msg("\n")
		MsgC(Color(255,255,0), [[	/`/_\\/`/\/\`\/`/_//`(_|`|`|`|`|/`//\]]) Msg("\n")
		MsgC(Color(255,255,0), [[	\____/\/````\/____/ \__,_|\__,`/____/]]) Msg("\n")	
		MsgC(Color(255,255,0), [[	````Made by Phoenixf129```|___/ v]]..PHDayZ.version)
		Msg("\n\n")
		Msg("======================================================================\n")
		MsgC(Color(255,255,0), "ERRORS:\n")
		
		for k, v in pairs(PHDayZ_CriticalErrors) do
			MsgC(Color(255,0,0,255), v.."\n")
		end
		
		for k, v in pairs(PHDayZ_StartUpErrors) do
			MsgC(Color(255,255,0,255), v.."\n")
		end
		
		if #PHDayZ_StartUpErrors < 1 and #PHDayZ_CriticalErrors < 1 then
			MsgC(Color(0,255,0), "NONE! :D\n")
		end
		Msg("======================================================================\n")
		
		hook.Run("DZ_FullyLoaded")
	end)
end)
MsgC(Color(0,255,0), "[PHDayZ] Loading Complete!\n")

if PHDayZ.Skybox_ForcePainted then 
	RunConsoleCommand("sv_skyname", "painted")
end

-- Console Commands
RunConsoleCommand("sv_kickerrornum", "0");
RunConsoleCommand("sbox_godmode", "0");
RunConsoleCommand("sbox_playershurtplayers", "1");
RunConsoleCommand("sbox_persist", "1");
RunConsoleCommand("mp_falldamage", "1");
RunConsoleCommand("sv_allowcslua", "0"); -- Unlike you falco, i don't want people cheating.

if VJBASE_VERSION != nil then

	RunConsoleCommand("vj_npc_noproppush", "1")
	RunConsoleCommand("vj_npc_nopropattack", "1")
	RunConsoleCommand("vj_npc_corpsefade", "1")
	RunConsoleCommand("vj_npc_dropweapon", "0")
	RunConsoleCommand("vj_npc_seedistance", "2500")

	
	hook.Remove("PlayerInitialSpawn", "VJ_PLAYER_INITIALSPAWN") -- bullshit lag #1
	hook.Remove("OnEntityCreated","VJ_ENTITYCREATED") -- bullshit lag #2

	local function func(ent)
		-- vjbase errors with above hook removal so we create vars
		--if !ent:IsNPC() then return end

		ent.VJ_LastInvestigateSdLevel = 0
	end
	hook.Add("OnEntityCreated", "VJ_ENTITYCREATED", func)
end

-- Load official resources
DZ_OR()

hook.Add("DZ_OnGiveItem", "SetupAttachments", function(ply, item, amount)
	
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end
	
	if ItemTable == nil then return end

	if ply:HasPerk("perk_gunking") then 
		if ply.hasallattachments then return end

		for key, attData in ipairs(CustomizableWeaponry.registeredAttachments) do
			local name = attData.name

			CustomizableWeaponry:giveAttachment( ply, name )
			
			ply.hasallattachments = true
		end

		return 
	end

	if ItemTable.Attachment != nil then
		//ply:FAS2_PickUpAttachment(ItemTable.Attachment, true)
		CustomizableWeaponry:giveAttachment( ply, ItemTable.Attachment )
	end
end)

hook.Add("DZ_OnUpdateItem", "SetupAttachments", function(ply, item, amount)
	
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end
	
	if ItemTable == nil then return end
	if ply:HasPerk("perk_gunking") then return end

	if ItemTable.Attachment != nil then
		//ply:FAS2_PickUpAttachment(ItemTable.Attachment, true)
		CustomizableWeaponry:giveAttachment( ply, ItemTable.Attachment )
	end
end)

hook.Add("DZ_OnTakeItem", "SetupAttachments", function(ply, item, amount)
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end
	
	if ply:HasPerk("perk_gunking") then return end
	if ItemTable == nil then return end

	if ItemTable.Attachment != nil then
		//ply:FAS2_RemoveAttachment(ItemTable.Attachment)
		umsg.Start("CW20_DETACHALL", ply)
			umsg.Entity(ply:GetActiveWeapon())
		umsg.End()
		CustomizableWeaponry:removeAttachment( ply, ItemTable.Attachment )
	end

end)