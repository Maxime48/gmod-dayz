VehicleSpawnConfig = {}
VehicleSpawnConfig.CarSpawnTime = 5 * 60

-- expects hl2 vehicles setup on the server via workshop addon.
VehicleSpawnConfig.Cars = {}
-- model, carscript. Carscript left empty for vehicles, expected to setup automatically.
VehicleSpawnConfig.Cars["models/source_vehicles/car004a.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car004b/vehicle.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car005a.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car005b/vehicle.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car005b_armored/vehicle.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/truck002a_cab.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/truck003a_01.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/van001a_01.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/van001a_01_nodoor.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/van001b_01.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car001a_hatchback_skin0.mdl"] = ""
VehicleSpawnConfig.Cars["models/source_vehicles/car001a_hatchback_skin1.mdl"] = ""


VehicleSpawns = {}
VehicleSpawns[string.lower(game.GetMap())] = {}

local foldernames = { "hl2jeep", "helicopter" }
Msg("======================================================================\n")
for k, v in ipairs( foldernames ) do
	
	file.CreateDir("dayz/spawns_vehicle/"..v)

	if !file.Exists("dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") then
		file.Write("dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", util.TableToJSON( {}, true ))
	end
	
	VehicleSpawns[string.lower(game.GetMap())][ k ] = {} -- A bit of validation never hurt anybody.
	if file.Size("dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
		--MsgC(Color(255,0,0), "[PHDayZ] Vehicle spawntype '"..v.."' not yet setup!\n")
		table.insert(PHDayZ_StartUpErrors, "Vehicle spawntype '"..v.."' not yet setup!")
	else
		
		local config = util.JSONToTable( file.Read( "dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA" ) )
	
		if not istable(config) then
			--MsgC(Color(255,0,0), "[PHDayZ] Vehicle spawns failed to load, check consistency!")
			table.insert(PHDayZ_StartUpErrors, "Vehicle spawns failed to load, check file consistency!")
			return
		end
		
		VehicleSpawns[string.lower(game.GetMap())][ k ] = config
		MsgC(Color(0,255,0), "[PHDayZ] Vehicle spawntype '", Color(255,255,0), v, Color(0,255,0), "' found and loaded!\n")
	end
	
end
Msg("======================================================================\n")

local function ReloadVehicles(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.
	MsgC(Color(255, 255, 0), "[PHDayZ] "..ply:Nick().." has reloaded the vehicles data!")
	
	for k, v in ipairs( foldernames ) do
		if file.Size("dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
			MsgAll("[PHDayZ] Vehicle spawntype ", Color(255,255,0), "'"..v.."'", Color(255,0,0), " not yet setup!\n")
		else
		
			local config = util.JSONToTable( file.Read( "dayz/spawns_vehicle/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA" ) )
		
			if not istable(config) then
				MsgC(Color(255,0,0), "[PHDayZ] Vehicle spawntype '", Color(255,255,0), v, Color(255,0,0), "' failed to load, check consistency!\n")
				return
			end
	
			VehicleSpawns[string.lower(game.GetMap())][ k ] = config
			MsgAll("[PHDayZ] Vehicle spawntype '"..v.."' found and loaded!\n")
		end
	end
	
	ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Vehicles have been reloaded.")
end
concommand.Add("dz_reloadvehicles", ReloadVehicles)

TotalVehicles = TotalVehicles or 0
TotalVehiclesHeli = TotalVehiclesHeli or 0

local function DZ_MakeVehicle(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end

	local tr = ply:GetEyeTraceNoCursor()

	local pos = tr.HitPos

	SpawnVehicle(pos)

end
concommand.Add("dz_makevehicle", DZ_MakeVehicle)

function SpawnVehicle(pos)

	local vec = Vector(100, 100, 100)

	local foundcar = false
	for k, v in pairs(ents.FindInBox(pos + vec, pos - vec) ) do
		if v:IsVehicle() then foundcar = true break end
	end

	if foundcar then return end -- no spawn inside each, or near each other.

	local car_script, car_model = table.Random(VehicleSpawnConfig.Cars)

	local car = ents.Create("prop_vehicle_jeep") 

	local veh_list = list.Get( "Vehicles" )
	car_script = car_script or "scripts/vehicles/jeep_test.txt"

	local this_veh
	for k, v in pairs(veh_list) do
		if v.Model == car_model then
			this_veh = k
			car_script = v.KeyValues.vehiclescript 
			break
		end
	end

	car:SetModel(car_model) 

	if this_veh then
		car:SetVehicleClass(this_veh)
	end

	car:SetKeyValue("vehiclescript", car_script)

	car:SetPos(pos)
	car:Spawn()

	TotalVehicles = TotalVehicles + 1

end

resource.AddWorkshop(104648051)

function AddCars()
	print("Calling InitPostEntity->Car Creation!")
	
	timer.Create( "Car_Respawn", 60, 0, function()
		if TotalVehicles < PHDayZ.TotalAllowedCars + 1 then
			local pos = table.Random(VehicleSpawns[string.lower(game.GetMap())][1])
			if !pos then return end
			
			SpawnVehicle(pos)
		end
	end)
	
	timer.Create( "Heli_Respawn", 5, 0, function()	
		if TotalVehiclesHeli == 0 then
			local pos = table.Random( VehicleSpawns[string.lower( game.GetMap() )][2] )
			if !pos then return end
			SpawnHelicopter( pos, Angle(0,90,0))
		end		
	end)
	
end

hook.Add("InitPostEntity", "CarLoad", AddCars)

function SpawnHelicopter(Location,HAngle)
	
	--MsgAll("Creating a Helicopter!")

	local HeliCopter = ents.Create(PHDayZ.HelicopterEnt or "sent_sakariashelicopter")
	HeliCopter:SetPos( Location or table.Random( VehicleSpawns[string.lower( game.GetMap() )][2] ) )
	HeliCopter:SetAngles(HAngle or Angle(0,90,0))
	HeliCopter:Spawn()
	HeliCopter:SetFuel( math.random(25, 50) )
	TotalVehiclesHeli = TotalVehiclesHeli + 1
	
	HeliCopter.Seats[1].FuelCheck = 0				
			
	HeliCopter.Seats[1].Think = function()
		DoFuelCheck(HeliCopter.Seats[1])

		timer.Simple(1,function() if HeliCopter.Seats[1]:IsValid() then HeliCopter.Seats[1]:Think() end end)
	end			
	HeliCopter.Seats[1]:Think() 		
		
end

function VehicleDamage_Collide( collider, data )
	local dmgamt = math.floor( data.Speed * 0.1 )

	if dmgamt < 1 then
		dmgamt = dmgamt * -1 -- make it positive if they're reversing.
	end
	--local dmgamt = math.floor( collider:GetVelocity():Length() * 0.1 )

    if collider.SeatNum then return end -- no work on chairs kthx.

    if (collider.nextCollide or 0) > CurTime() then return end

    collider.nextCollide = CurTime() + 0.5

    local dmgtype = DMG_CRUSH

    if data.HitEntity:IsNPC() then
    	dmgtype = DMG_DIRECT
    	dmgamt = 2
    	collider.nextCollide = CurTime() + 0.1
    end

    if ( dmgamt >= 25 ) or dmgtype == DMG_DIRECT then 

		if dmgamt > collider:Health() then
			CarExplode(collider)
			return
		end

        local DamageTable = DamageInfo()

        DamageTable:SetDamage( dmgamt )
        DamageTable:SetDamageType( dmgtype )
		DamageTable:SetInflictor( data.HitEntity )

        collider:TakeDamageInfo( DamageTable )
	end
end

function VehicleDamage_DoThink( ent )
	--if ( ent.nextThink or 0 > CurTime() ) then return end

	if ( ent.Flaming or ent:WaterLevel() > 1 ) && !ent.ExplosionImminent then

		local DamageTable = DamageInfo()

        DamageTable:SetDamage( 2 )
        DamageTable:SetDamageType( DMG_DIRECT )
		DamageTable:SetInflictor( ent )

        ent:TakeDamageInfo( DamageTable )

	end
				
	DoFuelCheck(ent)	

	CheckSwapToNextSeat(ent)

	ent.nextThink = CurTime() + 1				
end

hook.Add("EntityTakeDamage", "VehicleDamage_Taken", function(ent, dmginfo)
	if !ent:IsValid() then return end
	if !ent:IsVehicle() then return end
	if ent.SeatNum then return end

	if (ent.ArmorThreshold == nil) then return end
	
	if dmginfo:IsBulletDamage() then
		dmgmult = 0.25
	elseif dmginfo:IsExplosionDamage() then
		dmgmult = 2
	elseif dmginfo:IsDamageType( DMG_BURN ) then
		dmgmult = 50
	else
		dmgmult = 1
	end

	local ig = false
	if dmginfo:IsDamageType(DMG_DIRECT) then
		ig = true
	end

	local infl = dmginfo:GetInflictor()

	
	if ( ent.ArmorThreshold >= dmginfo:GetDamage() * dmgmult) && !ig then
		if ent.ExplosionImminent == false then
			ent:EmitSound( "physics/metal/metal_box_impact_bullet".. math.random(1, 3).. ".wav")
		end
	else
		if ig then
			ent:SetHealth( ent:Health() - dmginfo:GetDamage() )
		elseif ent.ExplosionImminent == false then
			ent:SetHealth( ent:Health() - (dmginfo:GetDamage() * dmgmult))
			ent:EmitSound( "physics/metal/metal_sheet_impact_bullet".. math.random(1, 2).. ".wav")
		end
	end
	
	if ent:Health() <= (ent:GetMaxHealth() / 2) then
		if ent.Smoking == false then
			local Engine = ent:LookupAttachment( "vehicle_engine" )
			ent.Smoking = true
			ParticleEffectAttach( "smoke_burning_engine_01", PATTACH_POINT_FOLLOW, ent, Engine )
		end
	end
	
	if ent:Health() <= ( ent:GetMaxHealth() / 5 ) then
		if ent.Flaming == false then
			local Engine = ent:LookupAttachment( "vehicle_engine" )
			ent.Flaming = true
			ParticleEffectAttach( "env_fire_small", PATTACH_POINT_FOLLOW, ent, Engine )
		end
		
	end
		
	if ent:Health() <= 0 then
		ent:SetHealth(0)

		if ent.ExplosionImminent then return end

		ent.ExplosionImminent = true
		ent:Ignite(100)
		ent:EnableEngine( false )

		timer.Create( ent:EntIndex().."_explode", math.random(1,15), 1, function()
			if ent.ExplosionImminent == true then

				CarExplode(ent)

			end

		end)

	end
end)

function CarExplode(Car)

	local OwnerEnt = Car
	if IsValid(Car:GetDriver()) then
		OwnerEnt = Car:GetDriver()
	end

	if Car.AlreadyExploded then return end

	Car.AlreadyExploded = true

	--if Car.ExplosionImminent then return end

	Car:EmitSound( "ambient/explosions/explode_".. math.random(1, 9).. ".wav" )

	Car:SetMaterial( "models/props_pipes/GutterMetal01a" )
	Car:Extinguish()

	Car:SetColor( Color( 72, 72, 72, 255 ) )
	
	local effectdata = EffectData()
	effectdata:SetOrigin( Car:GetPos() )

	util.Effect( "HelicopterMegaBomb", effectdata )	 -- Big flame
	
	local explo = ents.Create( "env_explosion" )
		explo:SetOwner( OwnerEnt )
		explo:SetPos( Car:GetPos() )
		explo:SetKeyValue( "iMagnitude", "150" )
		explo:Spawn()
		explo:Activate()
		explo:Fire( "Explode", "", 0 )
	
	util.BlastDamage(OwnerEnt, Car, Car:GetPos(), 150, 500)

	local shake = ents.Create( "env_shake" )
		shake:SetOwner( OwnerEnt )
		shake:SetPos( Car:GetPos() )
		shake:SetKeyValue( "amplitude", "2000" )	-- Power of the shake
		shake:SetKeyValue( "radius", "900" )	-- Radius of the shake
		shake:SetKeyValue( "duration", "2.5" )	-- Time of shake
		shake:SetKeyValue( "frequency", "255" )	-- How har should the screenshake be
		shake:SetKeyValue( "spawnflags", "4" )	-- Spawnflags( In Air )
		shake:Spawn()
		shake:Activate()
		shake:Fire( "StartShake", "", 0 )
	
	local ar2Explo = ents.Create( "env_ar2explosion" )
		ar2Explo:SetOwner( OwnerEnt )
		ar2Explo:SetPos( Car:GetPos() )
		ar2Explo:Spawn()
		ar2Explo:Activate()
		ar2Explo:Fire( "Explode", "", 0 )

	TotalVehicles = TotalVehicles - 1


	timer.Simple( 120, function()
		if !IsValid(Car) then return end

		if Car.ExplosionImminent == true then
			Car:Remove()
		end
	end)

	Car:SetFuel(0) -- fuel go byebye
end

function DoFuelCheck(Vehicle)
	if IsValid(Vehicle:GetParent()) && Vehicle:GetParent():IsVehicle() then
		Vehicle = Vehicle:GetParent()
	end 

	if ( Vehicle.FuelCheck or 0 ) > CurTime() then return end

	if !Vehicle.GetFuel then return end

	local speed = Vehicle:GetVelocity():Length()

	if speed > 15 then 
		if IsValid(Vehicle:GetDriver()) && Vehicle:GetDriver():IsPlayer() then
			Vehicle:SetFuel( Vehicle:GetFuel() - 1 )
		end
	end

	if IsValid(Vehicle:GetDriver()) && Vehicle:GetFuel() < 5 && Vehicle:GetDriver():IsPlayer() then
		if Vehicle:GetDriver():HasItem("item_gasoline") then
			Vehicle:GetDriver():TakeItem("item_gasoline", 1)
			Vehicle:SetFuel( Vehicle:GetFuel() + 20 )
			Vehicle:EmitSound("ambient/water/water_spray1.wav",75,100, 1)
		end
	end

	if Vehicle:GetFuel() <= 0 then
		Vehicle:Fire("turnoff", "", 0)
		Vehicle:SetFuel( 0 )
		if Vehicle.IsOn == true or Vehicle.AboutToTurnOn == true then
            Vehicle.IsOn = false
            Vehicle.AboutToTurnOn = false
            Vehicle.StartDelayTime = 0

            Vehicle.Sounds.RotorAlarm:Stop()
            Vehicle.Sounds.LowHealthAlarm:Stop()
            Vehicle.Sounds.CrashAlarm:Stop()            
            Vehicle.Sounds.Start:Stop()
            Vehicle.Sounds.Exterior:Stop()
            Vehicle.Sounds.Interior:Stop()            
            Vehicle.Sounds.Stop:Stop()
            Vehicle.Sounds.Stop:Play()
            Vehicle.Sounds.ShootSound:Stop()
            Vehicle:LampOff()
            Vehicle:SetNetworkedBool("IsOn", false)
            Vehicle.ShouldFire = false
            
            if IsValid( Vehicle.WashEffect ) then
                Vehicle.WashEffect:Remove()
            end
            
            if IsValid( Vehicle.LaserSprite ) then
                Vehicle.LaserSprite:Remove()
            end            
            
        end
	end

	Vehicle.FuelCheck = CurTime() + 5
end	 

function EnteredVehicleJ( player, vehicle, role )
	local class = vehicle:GetVehicleClass() != "" and vehicle:GetVehicleClass() or vehicle:GetClass()

	--print(player:Nick().." entered vehicle: "..class)
	if !vehicle.GetFuel then return end
	
	if vehicle:GetFuel() <= 0 then 
		vehicle:Fire("turnoff", "", 0)
	else
		vehicle:Fire("turnon", "", 0)
	end	
	vehicle.InSeat = player
end 
hook.Add( "PlayerEnteredVehicle", "EnteredVehicleJ", EnteredVehicleJ );

function CanExit(vehicle, ply)

	local speed = vehicle:GetVelocity():Length()
	if vehicle:GetParent():IsValid() then
		speed = vehicle:GetParent():GetVelocity():Length()
	end

	if speed > 250 then ply:Tip(3, "You cannot exit a moving vehicle!", Color(255,255,0)) return false end

	local class = vehicle:GetVehicleClass() != "" and vehicle:GetVehicleClass() or vehicle:GetClass()

	--print(ply:Nick().." exited vehicle: "..class)
end

function ExitedVehicleJ( ply, vehicle, role )
	vehicle.InSeat = nil
	ply.nextCarUse = CurTime() + 0.5
end 
hook.Add( "PlayerLeaveVehicle", "ExitedVehicleJ", ExitedVehicleJ );
hook.Add("CanExitVehicle", "DoExit", CanExit )