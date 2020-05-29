/*---------------------------------------------------------
 Sandbox override functions
 ---------------------------------------------------------*/
PlayerEnts = PlayerEnts or {}

local entmeta = FindMetaTable("Entity")
function entmeta:CPPISetOwner(ply)
	self.SID = ply:SteamID64()
	-- Already better than FPP.
	PlayerEnts[ self.SID ] = PlayerEnts[ self.SID ] or {}
	
	table.insert( PlayerEnts[ self.SID ], self )
	self.OwningEnt = ply -- Because fuck table.HasValue(PlayerEnts[ply.SID], ent)

	for k, v in pairs( PlayerEnts[ self.SID ] ) do
		if !IsValid( v ) then
			table.RemoveByValue( PlayerEnts[ self.SID ], v )
		end
	end

end

function entmeta:CPPIGetOwner()
	return self.OwningEnt
end

function PlayerRemoveProps(ply)
	local SID = ply:SteamID64()
	if PHDayZ.PropRemoveTimer == 0 then return end
	
	if !PlayerEnts[SID] then return end
	
	timer.Simple(PHDayZ.PropRemoveTimer or 120, function()
		for k,v in pairs(player.GetAll()) do
			if v:SteamID64() == SID then
				return
			end
		end
				
		for k, v in pairs(PlayerEnts[SID]) do
			if IsValid(v) then
				v:Remove()
			end
		end		
		
	end)
end
hook.Add("PlayerDisconnected", "PlayerRemoveProps", PlayerRemoveProps)
 
function GM:PhysgunDrop( ply, ent )
	if !IsValid(ent) then return end
	
	local phys = ent:GetPhysicsObject()
	--if IsValid(phys) then phys:EnableMotion(false) end
end

function GM:OnPhysgunFreeze( wep, phys, ent, ply )
	if !IsValid(ent) then return end

	if IsValid(phys) then phys:EnableMotion(false) end
end

function GM:OnPhysgunReload( wep, ply )
	local tr = ply:GetEyeTraceNoCursor()
	local ent = tr.Entity
	if !IsValid(ent) then return end
	if ent:GetPersistent() then return end
	if table.HasValue( PHDayZ.BlockedEntities, ent:GetClass() ) then return false end
	
	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then phys:EnableMotion(true) end
end
 
function GM:PlayerSpawnProp(ply, model)
	-- If prop spawning is enabled or the user has admin or prop privileges
	local allowed = ((PHDayZ.AllowPropSpawn or ply:IsAdmin()) and true) or false

	model = string.gsub(tostring(model), "\\", "/")
	model = string.gsub(tostring(model), "//", "/")

	if not allowed then return false end
	
	if ply:GetPVPTime() > CurTime() then 
		ply:Tip(3, "nospawntagged", Color(255,255,0))
		return false
	end
	
	if (ply:GetSafeZone() or ply:GetSafeZoneEdge()) and !ply:IsAdmin() then 
		ply:Tip(3, "nospawnsz", Color(255,255,0))
		return false
	end

	return self.BaseClass:PlayerSpawnProp(ply, model)
end

function GM:PlayerSpawnedProp(ply, model, ent)
	if !PHDayZ.AllowPropSpawn then 
		SafeRemoveEntity(ent)
		return false
	end

	if !ply.Noclip && ent.CPPISetOwner then ent:CPPISetOwner(ply) end
	
	local phys = ent:GetPhysicsObject()
	if phys and phys:IsValid() then
		ent.RPOriginalMass = phys:GetMass()
		phys:EnableMotion(false)
	end

		-- Do volume in cubic "feet"
	local min, max = ent:OBBMins(), ent:OBBMaxs()
	local vol = math.abs(max.x-min.x) * math.abs(max.y-min.y) * math.abs(max.z-min.z)
	vol = vol/(24^3)

	ent:SetHealth((vol*10) * PHDayZ.PropHealthMultiplier)
	ent:SetMaxHealth((vol*10) * PHDayZ.PropHealthMultiplier)
		
	if vol > PHDayZ.MaxPropSize && !ply.Noclip then
		ply:Tip(3, "nospawnlarge", Color(255,255,0))
		SafeRemoveEntity(ent)
		return false
	end

	local allowed = true
	if !PHDayZ.AllowShareItemModel then
		for k, v in pairs(GAMEMODE.DayZ_Items) do
			if string.lower(v.Model) == string.lower(model) && !ply.Noclip then
				ply:Tip(3, "nospawnsamemodel", Color(255,255,0)) 
				allowed = false
				break
			end
		end
	end

	if !ply.Noclip then -- propspawning is intentionally disabled here as it was removed in 5.4.
		allowed = false
	end

	if not allowed then 
		
		SafeRemoveEntity(ent) 
		return false 
	end

	if vol < 1 then vol = 1 end

	vol = math.Round(vol)
	
	local PropPrice = math.ceil(vol)

	local tr = ply:GetEyeTraceNoCursor()
	local res = GAMEMODE.MaterialResources[tr.MatType]

	local pos, ang, model, class, materialtype = ent:GetPos(), ent:GetAngles(), ent:GetModel(), ent:GetClass(), ent:GetMaterialType()
	
	if !GAMEMODE.MaterialResources[materialtype] then 
		return false
	end

	if PropPrice > ply:GetItemAmount( GAMEMODE.MaterialResources[materialtype] ) && !ply.Noclip then

		--if ply:GetBuildingSite() and ply:GetBuildingSite():IsValid() then ply:GetBuildingSite():Remove() end
		ply:DoModelProcess(model, "Constructing Prop", 5, "physics/metal/metal_sheet_impact_bullet1.wav", 0, "", true, function(ply)

			local site = ply:MakeBuildSite( pos, ang, model, class )
			site:CPPISetOwner(ply)
			site:AddCost( GAMEMODE.MaterialResources[materialtype], vol )

			ply:Tip(3, "nospawnbuildsite", Color(255,255,255,255))	
			
			undo.Create( "prop" )
			   undo.AddEntity( site )
			   undo.SetPlayer( ply )
			undo.Finish()

		end)

		ent:Remove()

		return true
	else

		if !ply.Noclip then
				
			ent:Remove()

			ply:DoModelProcess(model, "Constructing Prop", 5, "physics/metal/metal_sheet_impact_bullet1.wav", 0, "", true, function(ply)

				local site = ply:MakeBuildSite( pos, ang, model, class )
				site:CPPISetOwner(ply)
				site:Finish()

				if !ply.Noclip then
					ply:TakeItem( GAMEMODE.MaterialResources[materialtype], vol )
				end

				undo.Create( "prop" )
				   undo.AddEntity( site )
				   undo.SetPlayer( ply )
				undo.Finish()

			end)

		end

		return true
	end

	self.BaseClass:PlayerSpawnedProp(ply, model, ent)
end

local function checkAdminSpawn(ply, configVar, errorStr)

	if IsValid(ply) && ply:EntIndex() ~= 0 and not ( ply:IsAdmin() or ply:IsSuperAdmin() ) then
		return false
	end

	if IsValid(ply) && !PHDayZ.AdminsCanUseSpawnMenu then 
		return false 
	end

	return true
end

function GM:PlayerSpawnSENT(ply, class)
	return checkAdminSpawn(ply, "Entities", "gm_spawnsent") and self.BaseClass:PlayerSpawnSENT(ply, class)
end

function GM:PlayerSpawnSWEP(ply, class, info)
	return checkAdminSpawn(ply, "Weapons", "gm_spawnswep") and self.BaseClass:PlayerSpawnSWEP(ply, class, info)
end

function GM:PlayerGiveSWEP(ply, class, info)
	return checkAdminSpawn(ply, "Weapons", "gm_giveswep") and self.BaseClass:PlayerGiveSWEP(ply, class, info)
end

function GM:PlayerSpawnEffect(ply, model)
	return false
end

function GM:PlayerSpawnVehicle(ply, model, class, info)
	return checkAdminSpawn(ply, "Vehicles", "gm_spawnvehicle") and self.BaseClass:PlayerSpawnVehicle(ply, model, class, info)
end

function GM:CanPlayerEnterVehicle(ply, veh, role)
	return true	
end

-- this runs seperately to CanPlayerEnterVehicle...
function GM:PlayerUse( ply, ent )
	if !ply:CanPerformAction() && !ply:InVehicle() then return false end

	if ent:IsVehicle() && !ply:InVehicle() then 
		if ( ply.nextCarUse or 0 ) > CurTime() then return false end

    	if ent.ExplosionImminent then return false end

		local speed = ent:GetVelocity():Length()
		if speed > 50 then
			ply:Tip(3, "You cannot enter a moving vehicle!", Color(255,255,0))
			return false
		end

		ply:EmitSound("doors/handle_pushbar_open1.wav", 75, 100, 0.5)
		local class = ent.GetVehicleClass and ent:GetVehicleClass() != "" and ent:GetVehicleClass() or ent:GetClass()
	    local name = getNiceName( class )
		name = firstToUpper(name)

    	ply:DoModelProcess(ent:GetModel(), "Entering "..name, 2, "", 0, "doors/default_stop.wav", true, function(ply)
			if !IsValid(ply) or !ply:Alive() then return end
			if !IsValid(ent) then return end

			speed = ent:GetVelocity():Length()
			if ent:GetParent():IsValid() then
				speed = ent:GetParent():GetVelocity():Length()
			end

			if speed < 50 then 

	      		local driver = ent:GetDriver()
	      		if ( IsValid(driver) && driver:InVehicle() ) or ent:GetClass() == "sent_sakariashelicopter" then
	      			local seatNum = GetNextEmptySeat( ent, 1 )

	      			if !seatNum or seatNum == 0 then return end
	                
	                ply:EnterVehicle( ent.Seats[seatNum] )   
	      		else
	                ply:EnterVehicle( ent ) 
	      		end
	      		MsgAll(ply:Nick().." entered vehicle "..name.."\n" )
	      	else
	      		ply:Tip(3, "You cannot enter a moving vehicle!", Color(255,255,0))
	      	end
		end)
		
  		ply.nextCarUse = CurTime() + 0.5

		return false 
	end
end

function GM:PlayerSpawnNPC(ply, type, weapon)
	return checkAdminSpawn(ply, "NPCs", "gm_spawnnpc") and self.BaseClass:PlayerSpawnNPC(ply, type, weapon)
end

function GM:PlayerSpawnedNPC(ply, ent)
	self.BaseClass:PlayerSpawnedNPC(ply, ent)
	//ent:AddRelationship( "npc_nb_common D_HT 99" )
	//ent:AddFlags(8192)
end

function GM:PlayerSpawnRagdoll(ply, model)
	if IsValid(ply) and !ply:IsAdmin() then 
		return false 
	else 
		return true
	end
end

function GM:KeyPress(ply, code)
	self.BaseClass:KeyPress(ply, code)
end


local function selectDefaultWeapon(ply)
	-- Switch to prefered weapon if they have it
	local cl_defaultweapon = ply:GetInfo("cl_defaultweapon")

	if ply:HasWeapon(cl_defaultweapon) then
		ply:SelectWeapon(cl_defaultweapon)
	end
end