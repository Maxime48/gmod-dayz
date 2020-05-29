util.AddNetworkString("SendCarePackageVectors")

CarePackageSpawns = CarePackageSpawns or {}

file.CreateDir("dayz/spawns_carepackage/")

if !file.Exists("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", "DATA") then
	file.Write("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", util.TableToJSON({}, true))
end

function SpawnCarePackageCommand(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end

	local ptr = ply:GetEyeTrace()

	local pos = ptr.HitPos

	if not pos then return end

	local tr = util.TraceLine( {
		start = pos, 
		endpos = pos + Vector(0, 0, 10000),
		filter = ents.GetAll()
	} )

	local rand = math.random(1, 25)

	local cratetype = ""
	if rand >= 15 and rand < 20 then 
		cratetype = "weapon"
	elseif rand > 20 then
		cratetype = "food"	
	end

	local carepackage = ents.Create("dz_carepackage")
	carepackage:SetPos( tr.HitPos - Vector(0,0, 156) )
	if cratetype ~= "" then
		carepackage.LootType = cratetype
	end
	carepackage:Spawn()

	if args[1] then carepackage.Boomy = true end

	local text = "A carepackage has arrived! Find it to get goodies!"
	if EVENT_CHRISTMAS then
		text = "Santa has lost a present! Find it to get goodies!"
	end

	if mCompass_Settings then
		text = text .. " Check your compass!"
	end

	TipAll( 3, text, Color(255,255,0) )

	timer.Simple(600, function()
		if IsValid(carepackage) then
			carepackage:Remove()
		end
	end)

end
concommand.Add("dz_makecarepackage", SpawnCarePackageCommand)

function SpawnCarePackage(boom)

	local pos = table.Random( CarePackageSpawns[ string.lower(game.GetMap()) ] )

	if not pos then return end

	local tr = util.TraceLine( {
		start = pos, 
		endpos = pos + Vector(0, 0, 10000),
		filter = ents.GetAll()
	} )

	local rand = math.random(1, 25)

	local cratetype = ""
	if rand >= 15 and rand < 20 then 
		cratetype = "weapon"
	elseif rand > 20 then
		cratetype = "food"	
	end

	local carepackage = ents.Create("dz_carepackage")
	carepackage:SetPos( tr.HitPos - Vector(0,0, 156) )
	if cratetype ~= "" then
		carepackage.LootType = cratetype
	end
	carepackage:Spawn()

	if boom then carepackage.Boomy = true end
	
	local text = "A carepackage has arrived! Find it to get goodies!"
	if EVENT_CHRISTMAS then
		text = "Santa has lost a present! Find it to get goodies!"
	end

	if mCompass_Settings then
		text = text .. " Check your compass!"
	end

	TipAll( 3, text, Color(255,255,0) )

	timer.Simple(600, function()
		if IsValid(carepackage) then
			carepackage:Remove()
		end
	end)

	if mCompass_Settings then
		Adv_Compass_AddMarker(true, carepackage, CurTime() + 300, Color(255,165,0,255))
	end

end

local function AddCarePackageSpawn( ply, pos, spawntype )

	if spawntype == "carepackage" then
		table.insert( CarePackageSpawns[ string.lower( game.GetMap() ) ], pos )
		file.Write("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", util.TableToJSON(CarePackageSpawns[ string.lower( game.GetMap() ) ], true))

		ply:PrintMessage(HUD_PRINTTALK, "CarePackage Spawntype successful")
	end

end
hook.Add("DZ_AddSpawn", "AddCarePackage", AddCarePackageSpawn)

local function RemoveCarePackageSpawn( ply, vector )

	for k, v in pairs(CarePackageSpawns[ string.lower( game.GetMap() ) ]) do

		if vector:DistToSqr(v) < 2*2 then
			
			table.RemoveByValue( CarePackageSpawns[ string.lower( game.GetMap() ) ], v )	

			file.Write( "dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", util.TableToJSON(CarePackageSpawns[ string.lower( game.GetMap() ) ], true) )

			ply:PrintMessage(HUD_PRINTTALK, "Removed CarePackage Spawn successfully!")	

			break
		end
	end

end
hook.Add("DZ_RemoveSpawn", "RemoveCarePackage", RemoveCarePackageSpawn)


local function MakeItRain(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.

	local message = "Someone donated and made it rain! Spawning carepackages everywhere!"
	TipAll( 3, message, Color(255,255,0) )

	PrintMessage(HUD_PRINTCENTER, message)

	for k, v in pairs(player.GetAll()) do
		v:EmitSound("npc/attack_helicopter/aheli_megabomb_siren1.wav", 75, 100, 1)
	end

	local rain = "MAKEITRAIN_"..math.random(1, 1000)
	timer.Create(rain, 3, 5, function()

		for k, v in pairs(player.GetAll()) do
			v:EmitSound("vo/coast/odessa/male01/nlo_cheer0"..math.random(1,4)..".wav", 75, 100, 1)
		end

		SpawnCarePackage()
	end)

end
concommand.Add("dz_don_c", MakeItRain)

local function MakeItRain2(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.

	local message = "Anomaly Detected, Time Warp! ETA 30 seconds! Take Cover!"
	TipAll( 3, message, Color(255,255,0) )

	PrintMessage(HUD_PRINTCENTER, message)

	for k, v in pairs(player.GetAll()) do
		v:EmitSound("npc/attack_helicopter/aheli_megabomb_siren1.wav", 75, 100, 1)
	end
	

end
concommand.Add("dz_tw", MakeItRain2)

CarePackageSpawns[ string.lower(game.GetMap()) ] = {} -- A bit of validation never hurt anybody.
Msg("======================================================================\n")
if file.Size("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
	MsgC(Color(255,0,0), "[PHDayZ] Care Package spawns not yet setup! [ScriptFodder DLC]\n")
else
	local config = util.JSONToTable( file.Read("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt") )
	
	if not istable(config) then
		table.insert(PHDayZ_StartUpErrors, "Care Package spawns failed to load, check file consistency!")
		return
	end
	
	CarePackageSpawns[ string.lower(game.GetMap()) ] = config
	MsgC(Color(0,255,0), "[PHDayZ] Care Package spawns found and loaded!\n")
	Msg("======================================================================\n")
end

local function ReloadCarePackages(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.
	Msg("[NOTICE] "..ply:Nick().." has reloaded the Care Package spawn data!")
	
	if file.Size("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
		MsgAll("[PHDayZ] Care Package spawns not yet setup!\n")
	else
	
		local config = util.JSONToTable( file.Read("dayz/spawns_carepackage/"..string.lower(game.GetMap())..".txt") )
	
		if not istable(config) then
			MsgC(Color(255,0,0), "[PHDayZ] Care Package spawns failed to load, check consistency!\n")
			return
		end
		
		CarePackageSpawns[ string.lower(game.GetMap()) ] = config
		MsgAll("[PHDayZ] Care Package spawns found and loaded!\n")
	end
	
	MsgAll("[PHDayZ] Care Packages have been reloaded.")
end
concommand.Add("dz_reloadcarepackages", ReloadCarePackages)

local function UpdateCarePackageClient( ply )

	net.Start("SendCarePackageVectors")
		net.WriteTable(CarePackageSpawns[ string.lower( game.GetMap() ) ] )
	net.Send(ply)

end
hook.Add("DZ_SendMapSpawnUpdate", "UpdateCarePackageClient", UpdateCarePackageClient)

local function LoadCarePackageSystem()
	table.insert(DZ_AddSpawntypes, "carepackage")

	print( "Calling InitPostEntity->CarePackageSystem" )
	
	timer.Create( "CarePackageSpawnTimer", (PHDayZ.CarePackage_Timer or 1800), 0, function()
		if isfunction(SpawnCarePackage) then 
			if #player.GetAll() > ( PHDayZ.CarePackage_PlayerLimit or 0 ) then
				SpawnCarePackage() 
			end
		end
	end )
end
hook.Add( "InitPostEntity", "LoadCarePackageSystem", LoadCarePackageSystem )
