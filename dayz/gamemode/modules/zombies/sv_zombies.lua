ZombieSpawns = ZombieSpawns or {}
ZombieTbl = ZombieTbl or {}

file.CreateDir("dayz/spawns_zombie/")

if !file.Exists("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt", "DATA") then
	file.Write("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt", util.TableToJSON({}, true))
end

ZombieSpawns[ string.lower(game.GetMap()) ] = {} -- A bit of validation never hurt anybody.
Msg("======================================================================\n")
if file.Size("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
	MsgC(Color(255,0,0), "[PHDayZ] Zombie spawns not yet setup!\n")
else
	local config = util.JSONToTable( file.Read("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt") )
	
	if not istable(config) then
		table.insert(PHDayZ_StartUpErrors, "Zombie spawns failed to load, check file consistency!")
		return
	end
	
	ZombieSpawns[ string.lower(game.GetMap()) ] = config
	MsgC(Color(0,255,0), "[PHDayZ] Zombie spawns found and loaded!\n")
	Msg("======================================================================\n")
end

local function ReloadZombies(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsAdmin() then return end -- If it's ran from command.
	if ply:EntIndex() != 0 then
		Msg("[NOTICE] "..ply:Nick().." has reloaded the zombies spawn data!")
	end
	
	if file.Size("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
		MsgAll("[PHDayZ] Zombie spawns not yet setup!\n")
	else
	
		local config = util.JSONToTable( file.Read("dayz/spawns_zombie/"..string.lower(game.GetMap())..".txt") )
	
		if not istable(config) then
			MsgC(Color(255,0,0), "[PHDayZ] Zombie spawns failed to load, check consistency!\n")
			return
		end
		
		for k, v in pairs(ents.GetAll()) do	
			if v.IsZombie then
				v:Remove()
			end
		end
		ZombieTbl = {}
		
		ZombieSpawns[ string.lower(game.GetMap()) ] = config
		MsgAll("[PHDayZ] Zombie spawns found and loaded!\n")
	end
	
	MsgAll("[PHDayZ] Zombies have been reloaded.")

	ZombieLoad()
end
concommand.Add("dz_reloadzombies", ReloadZombies)

function ZombieLoad()
	print("Calling InitPostEntity->Zombie Creation!")
	timer.Create( "SpawnTheZombies", 2, 0, function()
		SpawnAZombie()
	end)
end
hook.Add("InitPostEntity", "ZombieLoad", ZombieLoad)

DayZ_NightTime = true

local function recurseFindPos(ply)
	local plypos = ply:GetPos()
	local navs = navmesh.Find(plypos, 2000, 200, 200)
    local nav = navs[math.random(1,#navs)]
    if !IsValid(nav) then return recurseFindPos(ply) end
    if nav:IsUnderwater() then return recurseFindPos(ply) end -- we dont want them to go into water

	local pos = nav:GetRandomPoint()

	local dist = plypos:DistToSqr(pos)

	if dist < ( 1000 * 1000 ) then
		pos = recurseFindPos(ply)
	end

	return pos
end

local function GetNearZombieSpawn(ply)
	--PrintTable(ZombieSpawns)
	local npos
	for k, v in pairs(ZombieSpawns[string.lower(game.GetMap())]) do
		local dist = ply:GetPos():DistToSqr( v )

		if ( dist > ( 500 * 500 ) && dist < ( 1500 * 1500 ) ) then
			npos = v + Vector(0,0,10)
			break
		end
	end

	return npos
end

VJInsurgents = {}
VJInsurgents["npc_vj_ins2_insheavy"] = 20
VJInsurgents["npc_vj_ins2_inslight"] = 20
VJInsurgents["npc_vj_ins2_insmed"] = 20

NPCWeapons = { "weapon_vj_ins2_fal", "weapon_vj_ins2_m4a1", "weapon_vj_ins2_toz", "weapon_vj_ins2_m16a4", "weapon_vj_ins2_m40a1", "weapon_vj_ins2_mosin", "weapon_vj_ins2_ump45", "weapon_vj_ins2_mp5k", "weapon_vj_ins2_aks74u", "weapon_vj_ins2_akm" }

VJAnimals = {}
VJAnimals["npc_animal_bear"] = 5
VJAnimals["npc_animal_cave_bear"] = 5
VJAnimals["npc_animal_crocodile"] = 5
VJAnimals["npc_animal_lionm"] = 5
VJAnimals["npc_animal_monkey"] = 10
VJAnimals["npc_animal_lynx"] = 10

function SpawnAZombie(pos, ignore, ply, forceclass, removenear, wep, lvl)
  	
	local ZombieCount = table.Count(ZombieTbl)
	if !ignore and ZombieCount > PHDayZ.TotalAllowedZombies then return end

    local doSpawn = true

    if !pos && PHDayZ.ZombieSpawnNearPlayers then
    	ply = ply or player.GetAll()[ math.random(1, #player.GetAll()) ]
    	if !IsValid(ply) then return end
    	
    	if ( ply.nextZombieNear or 0 ) > CurTime() then doSpawn = false return end

    	pos = GetNearZombieSpawn(ply)
		ply.nextZombieNear = CurTime() + PHDayZ.ZombiePerPlayerTimer or 20 
    end

    pos = pos or table.Random( ZombieSpawns[ string.lower( game.GetMap() ) ] )
    if !pos then return end

    if PHDayZ.ZombieSpawnCheckNear then
    	
    	local vec = Vector(30, 30, 30)
    	local entz = ents.FindInBox(pos - vec, pos + vec)

	    if !ignore && !removenear then
		    for k, v in pairs( entz ) do
		    	if v.IsZombie then doSpawn = false break end
		    end
		end

		if removenear then
			for k, v in pairs( entz ) do
		    	if v.IsZombie then v:Remove() end
		    end
		end

	end
	
    if !doSpawn then return end

	if PHDayZ.VJBaseSupport then
		PHDayZ.ZombieTypes = {}
		PHDayZ.ZombieTypes["npc_vj_zss_zombie*"] = 100
		PHDayZ.ZombieTypes["npc_vj_zss_burnzie"] = 5
		PHDayZ.ZombieTypes["npc_vj_zss_cfastzombie"] = 10
		PHDayZ.ZombieTypes["npc_vj_zss_cpzombie"] = 20
		PHDayZ.ZombieTypes["npc_vj_zss_czombie"] = 20
		PHDayZ.ZombieTypes["npc_vj_zss_czombietors"] = 20
		PHDayZ.ZombieTypes["npc_vj_zss_zombguard"] = 20
		PHDayZ.ZombieTypes["npc_vj_zss_zp*"] = 20	
		PHDayZ.ZombieTypes["npc_vj_zss_zhulk"] = 4
		PHDayZ.ZombieTypes["npc_vj_zss_zombfast*"] = 10
		PHDayZ.ZombieTypes["npc_vj_zss_zminiboss"] = 2	
		PHDayZ.ZombieTypes["npc_vj_zss_zboss"] = 1	
		if PHDayZ.NPCS_AnimalsEnabled then
			table.Merge(PHDayZ.ZombieTypes, VJAnimals)
 		end
 		if PHDayZ.NPCS_EnemiesEnabled then
 			table.Merge(PHDayZ.ZombieTypes, VJInsurgents)
 		end
 	end
	
	local num = math.random(1, 100)
	local rarity, class = table.Random(PHDayZ.ZombieTypes) 

	if num > rarity then class = PHDayZ.VJBaseSupport and "npc_vj_zss_zombie"..math.random(1, 12) or "npc_nb_common" end -- don't spawn rare zombies. 
	
	if math.random(1,10) >= 9 and PHDayZ.NPCS_AnimalsEnabled then
		rarity, class = table.Random(VJAnimals)
	end

	if math.random(1,20) >= 19 and PHDayZ.NPCS_EnemiesEnabled then
		rarity, class = table.Random(VJInsurgents)
	end

	if class == "npc_vj_zss_zombfast*" then class = "npc_vj_zss_zombfast"..math.random(1, 6) end
	if class == "npc_vj_zss_zp*" then class = "npc_vj_zss_zp"..math.random(1, 4) end
	if class == "npc_vj_zss_zombie*" then class = "npc_vj_zss_zombie"..math.random(1, 12) end

	if forceclass then class = forceclass end

	local newzombie = ents.Create( class )
	newzombie:SetPos( pos + Vector(0,0,10) )
	//newzombie:SetHealth( newzombie:Health() ) -- sometimes nextbot fails to apply health, so here we are.
	newzombie.IsZombie = true

	newzombie.zclass = class

	newzombie:Spawn()

	if lvl then
		newzombie.doSetLvl = lvl
	end

	--timer.Simple(5, function() newzombie:Spawn() end) -- let's give the players a chance to move away, incase it spawns WAY too close.

	if PHDayZ.DebugMode then
		PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Zombie["..class..":"..ZombieCount.."] was spawned!")	
	end
	--MsgC( Color(0,255,0), "[PHDayZ] ", Color(255, 255, 0), "Zombie["..class..":"..ZombieCount.."] was spawned!\n" ) 

	if wep or VJInsurgents[class] then
		wep = wep or table.Random(NPCWeapons)
		newzombie:Give(wep)
	end

	return newzombie
end

hook.Add("OnEntityCreated", "SetupZombies", function(ent)
	
    timer.Simple(0.5, function() -- next frame, as always with OnEntityCreated

    	if IsValid(ent) and ent:GetClass() == "prop_ragdoll" && !ent:GetPersistent() && ( ent.IsVJBaseCorpse or ent.IsVJBase_Gib ) then
    		ent:Fire("FadeAndRemove", "", 5)
    	end

    	if IsValid(ent) and ent:GetClass() == "modulus_skateboard" then
    		ent:SetSpeed( 15 )
    		ent:SetJumpPower( 300 )
    	end

    	if ent.IsZombie or ent.VJ_NPC_Class then

    		ent.SetupLevels = function()
				local lvl = 1
				if math.random(1, 10) > 9 then
					lvl = 2
				end

				if VJInsurgents[ ent:GetClass() ] then
					lvl = 3
				end

				if ent.doSetLvl then
					lvl = ent.doSetLvl
				end

				ent:SetLevel(lvl)
			end

			ent.CheckLevel = function()

				ent.oMeleeAttackDamage = ent.oMeleeAttackDamage or ent.MeleeAttackDamage

				local ldiff = 3 * ent:GetLevel()
	            ent.MeleeAttackDamage = ent.oMeleeAttackDamage + ldiff

	           	ent.orMaxHealth = ent.orMaxHealth or ent:GetMaxHealth()
	           	local ldiff = 20 * ent:GetLevel()
	            ent:SetMaxHealth( ent.orMaxHealth + ldiff )

		        if ( ent.Frags or 0 ) >= ( 2 ) then
		            ent.Frags = 0

		            ent:SetLevel( ent:GetLevel() + 1 )

		            ent:EmitSound( "smb3_powerup.wav", 55, 100 )

                    local hp = math.Clamp( ent:Health() + ( ent:GetMaxHealth() / 4 ), 0, ent:GetMaxHealth() )
			        ent:SetHealth( hp )
			        ent:EmitSound( "items/medshot4.wav", 55, 100 )

		        end 

			end

			timer.Simple(0.1, function() ent:SetupLevels() ent:CheckLevel() ent:SetHealth( ent:GetMaxHealth() ) end)

			ent.rarity = PHDayZ.ZombieTypes[ent.zclass] or 100
			if VJInsurgents[class] then
				ent.rarity = 1
			end
			
			ent.FadeCorpse = true -- VJ
			ent.FadeCorpseTime = 5 -- VJ

			ZombieTbl[ent] = true

			if PHDayZ.VJBaseSupport then

				timer.Simple(1, function()
					if !IsValid(ent) then return end

					if ent.VJ_TASK_IDLE_WANDER then
						ent:VJ_TASK_IDLE_WANDER()
					end

					ent.IsZombie = true -- for system purposes.
					
					-- vj overrides and creates extra ragdolls in animals addon, this reverts his function to the original.
					local originalBase = scripted_ents.GetStored( "npc_vj_creature_base" ).t
					local originalCreateCorpse = originalBase.CreateDeathCorpse
					local oCreateCorpse = ent.CreateDeathCorpse
					ent.CreateDeathCorpse = originalCreateCorpse

					ent.DeathNotice_PlayerPoints = function(self, dmginfo, hitgroup) 
						local DamageInflictor = dmginfo:GetInflictor()
						local DamageAttacker = dmginfo:GetAttacker()
						gamemode.Call("OnNPCKilled",self,DamageAttacker,DamageInflictor,dmginfo)
					end -- override, we need this to call OnNPCKilled for that npc.
				end)
			end

		end

	end)
end)