SafeZoneTbl = {}

local foldernames = { "barriers", "vipbarriers", "safezoneareas", "safezoneedgeareas" } 
Msg("======================================================================\n")
for k, v in pairs(foldernames) do 
	file.CreateDir("dayz/safezones/"..v)

	if !file.Exists("dayz/safezones/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") then
		file.Write("dayz/safezones/"..v.."/"..string.lower(game.GetMap())..".txt", util.TableToJSON( {} ) )
		MsgC(Color(255,255,0), "[PHDayZ] No safezone '"..v.."' file was detected. Empty file has been created.\n")
	else
	
		local config = util.JSONToTable( file.Read("dayz/safezones/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") )
		
		if not istable(config) then
			--MsgC(Color(255,0,0), "[PHDayZ] Safezones spawntype '"..v.."' failed to load, check consistency!")
			table.insert(PHDayZ_StartUpErrors, "Safezones spawntype '"..v.."' failed to load, check file consistency!")
			return
		end
			
		SafeZoneTbl[k] = config
		MsgC(Color(0, 255, 0), "[PHDayZ] Safezone '", Color(255,255,0), v, Color(0,255,0), "' found and loaded!\n")
	end
end
Msg("======================================================================\n")

local function SaveSafeZones(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end

	for k, v in pairs(ents.GetAll()) do
		if v:GetClass() == "safezone" then
			local min, max = v:GetMinWorldBound(), v:GetMaxWorldBound()

			MsgAll(min, max)
		elseif v:GetClass() == "radzone" then
			local min, max = v:GetMinWorldBound(), v:GetMaxWorldBound()
			MsgAll("rad:")

			MsgAll(min, max)
		end
	end
end
concommand.Add("dz_savesz", SaveSafeZones)

local function ReloadSafezones(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsAdmin() then return end -- If it's ran from command.
	if ply:EntIndex() != 0 then
		MsgC(Color(255,255,0), "[NOTICE] "..ply:Nick().." has reloaded the safezones data!\n")
	end
	
	for k, v in ipairs( foldernames ) do
		if file.Size("dayz/safezones/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
			MsgAll("[PHDayZ] Safezones spawntype '"..v.."' not yet setup!\n")
		else
		
			local config = util.JSONToTable( file.Read("dayz/safezones/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") )
		
			if not istable(config) then
				MsgC(Color(255,0,0), "[PHDayZ] Safezones spawntype '", Color(255,255,0), v, Color(255,0,0), "' failed to load, check consistency!\n")
				return
			end
				
			SafeZoneTbl[k] = config
			MsgAll("[PHDayZ] Safezones spawntype '"..v.."' found and loaded!\n")
		end
	end

	SpawnTheSZ()
	
	MsgAll("[PHDayZ] Safezones have been reloaded.\n")
end
concommand.Add("dz_reloadsafezones", ReloadSafezones)

local entnames = {"no_entry", "no_entry_vip", "safezone"}
function SpawnTheSZ()
	Msg("======================================================================\n")

	MsgC(Color(0,255,0), "[PHDayZ] Calling PostGamemodeLoaded->SafeZone Setup!\n\n" )

	-- Remove all the old entities, and make the new ones :)
	for k, v in pairs(ents.GetAll()) do
		if table.HasValue(entnames, v:GetClass()) then
			
			if !v:GetPersistent() then
				if PHDayZ.DebugMode then
					MsgAll("[PHDayZ] Entity "..v:GetClass().." removed due to config reload!\n")
				end
				v:Remove()
			end
		end
	end
	if !SafeZoneTbl[1] then return end
	
	--[[ DEBUG ANGLES ]]
	local test_debug = false
	
	for k, v in pairs(SafeZoneTbl[1]) do
		local barrier = ents.Create("no_entry")
		barrier:SetModel(v.mdl)
		barrier:SetPos(v.pos)
		if test_debug then
			print(v.ang)
		end
		barrier:SetAngles(v.ang)
		barrier:Spawn()
		if IsValid(barrier:GetPhysicsObject()) then
			barrier:GetPhysicsObject():EnableMotion(false)
		end
		barrier:SetMoveType( MOVETYPE_NONE )
	end
	MsgC(Color(0,255,0), "[PHDayZ] Barriers spawned successfully!\n")
	
	for k, v in pairs(SafeZoneTbl[2]) do
		local barrier = ents.Create("no_entry_vip")
		barrier:SetModel(v.mdl)
		barrier:SetPos(v.pos)
		if test_debug then
			print(v.ang)
		end
		barrier:SetAngles(v.ang)
		barrier:Spawn()
		if IsValid(barrier:GetPhysicsObject()) then
			barrier:GetPhysicsObject():EnableMotion(false)
		end
		barrier:SetMoveType( MOVETYPE_NONE )
	end
	MsgC(Color(0,255,0), "[PHDayZ] VIPBarriers spawned successfully!\n")

	for k, v in pairs(SafeZoneTbl[3]) do
		local safezone = ents.Create("safezone")
		safezone:SetMinWorldBound(v.spos)
		safezone:SetMaxWorldBound(v.epos)
		safezone:SetSafezoneEdge(false)
		safezone:SetVIPSZ(v.vip or false)
		safezone:SetArena(v.arena or false)
		safezone:Spawn()
		safezone:Activate()
	end
	MsgC(Color(0,255,0), "[PHDayZ] SafeZones spawned successfully!\n")
	
	for k, v in pairs(SafeZoneTbl[4]) do
		local safezone = ents.Create("safezone")
		safezone:SetMinWorldBound(v.spos)
		safezone:SetMaxWorldBound(v.epos)
		safezone:SetSafezoneEdge(true)
		safezone:Spawn()
		safezone:Activate()
	end
	MsgC(Color(0,255,0), "[PHDayZ] SafeZone Edges spawned successfully!\n")

	Msg("======================================================================\n")

end
hook.Add( "DZ_FullyLoaded", "SpawnTheSZ", SpawnTheSZ )

local function SetTagged(target, dmginfo)
	local tagtime = 300

	if dmginfo:GetAttacker():IsNPC() and target:IsPlayer() then
		local tag = tagtime / 5
		if target:IsVIP() then tag = tag - (tag / 3) end
		if target:GetInArena() then return end

		if ( CurTime() + tag ) < target:GetPVPTime() then return end
		target:SetPVPTime( CurTime() + tag )
	end

	if dmginfo:GetAttacker():IsPlayer() and target:IsPlayer() then
		
		if target:GetInArena() or dmginfo:GetAttacker():GetInArena() then return end 

		if dmginfo:GetAttacker() == target then return end

		if target:GetSafeZoneEdge() or dmginfo:GetAttacker():GetSafeZoneEdge() then 
			if dmginfo:GetAttacker():GetPVPTime() > CurTime() then
			
			else
				dmginfo:SetDamage(0)
			end
		end
		
		local tag = tagtime
		if dmginfo:GetAttacker():IsVIP() then tag = tag - (tag / 3) end
		dmginfo:GetAttacker():SetPVPTime( CurTime() + tag )
		
		if !( (target:GetSafeZoneEdge() or target:GetSafeZone()) or (dmginfo:GetAttacker():GetSafeZoneEdge() or dmginfo:GetAttacker():GetSafeZone()) ) then
			
			tag = tagtime -- reset var
			if target:IsVIP() then tag = tag - (tag / 3) end

			if ( CurTime() + tag ) < target:GetPVPTime() then return end
			target:SetPVPTime( CurTime() + tag )
			
		end
	end
		
	if target:IsVehicle() or (target:GetClass() == "sent_sakariashelicopter") then
		if dmginfo:GetAttacker():IsPlayer() and (dmginfo:GetAttacker():GetSafeZone() or dmginfo:GetAttacker():GetSafeZoneEdge()) then
			dmginfo:SetDamage(0)
		end
	end
	
end
hook.Add("EntityTakeDamage", "Tagging", SetTagged)

local particles = {}
particles.model = "models/hunter/triangles/05x05.mdl"
particles.scale = 1
particles.xSpeed = 55
particles.ySpeed = 10
particles.zSpeed = 75
particles.solid = SOLID_NONE
particles.ent = "prop_physics"
particles.move = MOVETYPE_FLY
particles.material = matRefract


function SafezoneTeleport(ply, world, time, arena)
	if !PHDayZ.SafeZoneTeleportEnabled then return end

	if ply:GetPVPTime() > CurTime() then ply:Tip(3, "You cannot teleport while in PVP!", Color(255,0,0,255)) return end
	local pos = PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ]

	if arena && PHDayZ.SafeZoneArenaPos[ string.lower( game.GetMap() ) ] then
		pos = PHDayZ.SafeZoneArenaPos[ string.lower( game.GetMap() ) ]
	end

	if !PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] then
		MsgAll("[PHDayZ] ERROR! dz_setszteleportpos not set! Nowhere to teleport player!\n")
		return
	end

	ply:EmitSound("ambient/machines/teleport1.wav", 75, 100, 0.5)
	--NetEffect(ply, "playerspawneffect", ply:EyePos())
	--ply:Lock()

	timer.Simple(0.1, function()

		if !time or time < 1 then
			if not IsValid(ply) or not ply:Alive() then return end

	        if world then
				if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
					pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
				end
			
			end

			ply:SetPos(pos)
			ply:SetEyeAngles(Angle(0,-76,0))
			--timer.Simple(3, function() if IsValid(ply) then ply:UnLock() end end)
			ply.nextSZTeleport = CurTime() + 60
		else
			ply:DoModelProcess("models/Gibs/HGIBS.mdl", "Teleporting...", time or 3, "", 0, "", true, function(ply)
		        if not IsValid(ply) or not ply:Alive() then return end

				--NetEffect(ply, "playerspawneffect", ply:GetPos())

		        if world then
					if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
						pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
					end
				
				end

				ply:SetPos(pos)
				ply:SetEyeAngles(Angle(0,-76,0))
				--timer.Simple(3, function() if IsValid(ply) then ply:UnLock() end end)
				ply.nextSZTeleport = CurTime() + 60
		    end)
		end
	end)
end

util.AddNetworkString("DZ_DrawEffect")
function NetEffect(caller, ef, pos, ang, att, col, dmgt, ei, mag, rad, scale, start) // because util.Effect is broken serverside.
	if(ef == "testeff3") then ef = nil end //cmd manual
	if(type(pos) != "Vector") then pos = nil end

	ef = ef or "playerspawneffect"
	pos = pos or caller:GetPos()

	net.Start("DZ_DrawEffect")
		if IsValid(caller) then
        	net.WriteEntity(caller)
        end
        net.WriteString(ef)
        net.WriteVector(pos)
        /*if ang then
	        net.WriteAngle(ang)
	    end
	    if att then
        	net.WriteInt(att, 32)
        end
        if col then
	        net.WriteInt(col, 32)
	    end
	    if dmgt then
        	net.WriteInt(dmgt, 32)
        end
        if ei then
        	net.WriteVector(ei)
        end
        if mag then
        	net.WriteInt(mag, 32)
        end
        if rad then
        	net.WriteInt(rad, 32)
        end
        if scale then
        	net.WriteInt(scale, 32)
        end
        if start then
        	net.WriteVector(start)
        end*/
    net.Broadcast()

end
--concommand.Add("testeff3", NetEffect)

function TeleportToSZ(ply, cmd, args)
	if !PHDayZ.SafeZoneTeleportEnabled then return end

	if !IsValid(ply) then return end
	if !ply:CanPerformAction() then return end
	if ply:InVehicle() then return end -- no teleport in cars.

	if ply:GetPVPTime() > CurTime() then
		ply:PrintMessage(HUD_PRINTTALK, "You cannot teleport to the safezone while in pvp!")
		return
	end

	/*if ply:GetSick() then
		ply:PrintMessage(HUD_PRINTTALK, "You cannot teleport to the safezone while sick!")
		return
	end

	if ply:GetRadiation() > 0 then
		ply:PrintMessage(HUD_PRINTTALK, "You cannot teleport to the safezone while irradiated!")
		return
	end*/ -- lol

	if !( ply:GetSafeZone() or ply:GetInArena() ) && ( ply.nextSZTeleport or 0 ) > CurTime() then
		local time = math.Round( ply.nextSZTeleport - CurTime() )
		ply:PrintMessage(HUD_PRINTTALK, "You are currently on safezone cooldown. Wait "..time.." second/s!")
		return
	end

	if ( ply:GetSafeZone() or ply:GetInArena() ) then
		
		ply:DoModelProcess("models/Gibs/HGIBS.mdl", "Returning to Overworld...", 2, "", 0, "", true, function(ply)
	        if not IsValid(ply) or not ply:Alive() then return end

	        SafezoneTeleport(ply, true)
	    end)
	    

		return
	end

	ply:DoModelProcess("models/Gibs/HGIBS.mdl", "Teleporting to SafeZone...", 27, "", 0, "", true, function(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        SafezoneTeleport(ply)
    end)

end

local function safezoneText(ply, text, team)
    if ( string.sub( string.lower(text), 2, 9 ) == "safezone" ) or ( string.sub( string.lower(text), 2, 4 ) == "sz" ) or ( string.sub( string.lower(text), 2, 7 ) == "leave") then
        if !PHDayZ.SafeZoneTeleportEnabled then ply:PrintMessage(HUD_PRINTTALK, "Teleporting to safezone is disabled on this server") return "" end
		if !PHDayZ.SafeZoneTeleportChat then ply:PrintMessage(HUD_PRINTTALK, "!sz is disabled. Go find a teleporter!") return "" end -- for entities only

        TeleportToSZ(ply)
        return ""
    end
end
hook.Add("PlayerSay", "safezoneText", safezoneText)

function DZ_SpawnNPC(ply, cmd, args)
	if !ply:IsAdmin() then return end

	ply:PrintMessage(HUD_PRINTTALK, "[PHDayZ] Move! Spawning trader with your position/angles...")

	local pos = ply:GetPos()
	local ang = ply:GetAngles()

	local class = "npc_sz"
	if args[1] then
		class = "npc_vipsz"
	end

	timer.Simple(3, function()
		local npc = ents.Create( class )
		npc:SetPos( pos )
		npc:SetAngles( ang )
		npc:Spawn()
		npc:SetPersistent(true)
	end)

end
concommand.Add("dz_maketrader", DZ_SpawnNPC)