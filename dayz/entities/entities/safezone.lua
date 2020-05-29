AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.RenderGroup		= RENDERGROUP_TRANSLUCENT

local cyb_mat = Material("cyb_mat/cyb_noentry")

function ENT:GetRotatedVec(vec)
	local v = self:WorldToLocal(vec)
	v:Rotate(self:GetAngles())
	return self:LocalToWorld( v )
end

if CLIENT then
	ShowZonesCvar = CreateClientConVar("cyb_showsz", 0, true, false)

	local ShowZones = 0
	function UpdateShowZones(str, old, new)
		ShowZones = math.floor(new)
	end
	cvars.AddChangeCallback(ShowZonesCvar:GetName(), UpdateShowZones)

	hook.Add("Initialize", "InitShowZones", function()
		ShowZones = ShowZonesCvar:GetInt() or 0
	end)

	function ENT:Draw()
		if ShowZones ~= 0 then
			if not LocalPlayer():IsAdmin() then return end
			render.DrawWireframeBox( self:GetPos(), self:GetAngles(), self:GetNWVector("min"), self:GetNWVector("max"), Color( 255, 255, 0 ), false )
		end
		
		self:DestroyShadow()

		local pl = LocalPlayer()
		
		if (not self:ShouldCollide(pl) and not IsValid(LocalPlayer():GetVehicle())) then return end
		
		render.SetMaterial( Material( "color" ) )
		
		render.DrawBox( self:GetPos(), self:GetAngles(), self:GetNWVector("min"), self:GetNWVector("max"), Color( 255, 0, 0, 2 ), false )
		
	end

end

AccessorFunc(ENT, "MinWorldBound", "MinWorldBound")
AccessorFunc(ENT, "MaxWorldBound", "MaxWorldBound")
AccessorFunc(ENT, "SafezoneEdge", "SafezoneEdge", FORCE_BOOL)
AccessorFunc(ENT, "VIPSZ", "VIPSZ", FORCE_BOOL)
AccessorFunc(ENT, "Arena", "Arena", FORCE_BOOL)

function ENT:Initialize()
	if CLIENT then self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000)) end
	if not SERVER then return end

	self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )

	local pos = LerpVector(0.5, self:GetMinWorldBound(), self:GetMaxWorldBound())
	self:SetPos(pos)
	self.min = self:WorldToLocal(self:GetMinWorldBound())
	self.max = self:WorldToLocal(self:GetMaxWorldBound())
	self.nextThink = 0

	self:SetNWVector("min", self.min)
	self:SetNWVector("max", self.max)

	self:PhysicsInitBox( self.min, self.max )
	self:SetCollisionBounds( self.min, self.max )

	self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
	self:SetMoveType(MOVETYPE_NONE)

	self:SetTrigger(true)	
end

function ENT:Think()
	if SERVER then
		if self.nextThink > CurTime() then return end
		
		self.nextThink = CurTime() + 1
	end
end

function ENT:StartTouch(ply)
	if not IsValid(ply) then return end
	//if ply.IsZombie then CreateCorpse(ply) end -- StartTouch doesn't run for NPCs :(
	if not ply:IsPlayer() then 
		if ply:IsVehicle() then

			ply:GetPhysicsObject():SetVelocity( ( ply:GetVelocity() * -3 ) )
			return
		end

		if ply:GetClass() == "base_item" then
			if !self:GetSafezoneEdge() then
				ply:SetSafeZone(true)
			end
			return
		end
		
		if ply:GetClass() == "prop_physics" and IsValid(ply:CPPIGetOwner()) then
			if ply:CPPIGetOwner():IsAdmin() then return end
			ItemDestroyed(ply:GetPos())
			ply:Remove()
		end
		return 
	end

	if ply:GetSafeZone() then ply:SetSafeZone(false) end
	if ply:GetSafeZoneEdge() then ply:SetSafeZoneEdge(false) end

	if self:GetArena() then
		if !ply:GetInArena() then
			ply:SetInArena(true)
			ply.arenaEnterHP = ply:Health()
		end
		return
	end

	if self:GetSafezoneEdge() then
		ply:SetSafeZoneEdge(true)
		ply:SetInArena(false)
	else
		ply:SetSafeZone(true)
		ply:SetInArena(false)
	end
end

function ENT:ShouldCollide(ply)
	if ply:IsPlayer() then
		if ply:GetPVPTime() > CurTime() or ( self:GetVIPSZ() and !ply:IsVIP() ) && !self:GetArena() then
			return true
		else
			return false
		end
	end
	return false
end

ENT.NextTouchCheck = 0
function ENT:Touch(ply)
	if not IsValid(ply) then return end

	if ply:GetClass() == "base_item" then
		
		return
	end

	if not ply:IsPlayer() then return end
	
	if ply.NextSZTouchCheck and ply.NextSZTouchCheck > CurTime() then return end
	ply.NextSZTouchCheck = CurTime() + 0.1
	
	if ( not ply:GetSafeZone() and not ply:GetSafeZoneEdge() and not ply:GetInArena() ) then
		self:StartTouch(ply)
	end

	local TagTime = ply:GetPVPTime()

	if !self:GetSafezoneEdge() and TagTime > CurTime() && !self:GetArena() then
		--local vel = ply:GetVelocity() * -8
		--vel[3] = math.Clamp(vel[3], 0, 10)
		--ply:SetVelocity( vel )
		
		ply.SZTipTime = ply.SZTipTime or 0
		
		if ply.SZTipTime > CurTime() then return end
		ply.SZTipTime = CurTime() + 5
		ply:Tip(3, "youaretagged", Color(255, 0, 0))
		return
	end

	if self:GetArena() then
		return
	end

	if TagTime > CurTime() then
		ply:GodDisable()
	end

	if self:GetSafezoneEdge() then
		ply:SetSafeZoneEdge(true)

		ply.TouchedNewSZEdge = true

		if TagTime < CurTime() then
			ply:GodEnable()
		end
		--ply:ChatPrint("Entered SafeZone Edge")
	else
		ply:SetSafeZone(true)

		if TagTime < CurTime() then
			ply:GodEnable()

			--local wep = ply:GetActiveWeapon()
			--if ( ply:GetMoveType() != MOVETYPE_NOCLIP ) and IsValid( wep ) and ( wep:GetClass() != "weapon_emptyhands" ) then
				--wep.GlobalDelay = CurTime() + 1
				--if wep.dt && !wep.dt.Safe then
					--wep:SelectFiremode("safe")
				--end
				--ply:SelectWeapon( "weapon_emptyhands" )
			--end
			--ply:ChatPrint("Entered SafeZone")
			--ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		end

	end
	//ply.oldTeam = ply.oldTeam or ply:Team();
	//if ply.oldTeam == TEAM_SAFEZONE then ply.oldTeam = TEAM_NEUTRAL end
	//ply:SetTeam(TEAM_SAFEZONE);
	
end

function ENT:EndTouch(ply)
	if not IsValid(ply) then return end
	if ply:GetClass() == "base_item" then
		ply:SetSafeZone(false)
		return
	end
	if not ply:IsPlayer() then return end

	if self:GetSafezoneEdge() then
		ply:SetSafeZoneEdge(false)
	elseif self:GetArena() then
		if !ply:Alive() then return end -- doesn't allow you to leave when you die, which is what you do. If you DC it doesn't matter.
		ply:SetInArena(false)

		if ply.arenaEnterHP then
			ply:SetHealth( ply.arenaEnterHP )
		end
		if ply:GetSafeZone() then ply:SetSafeZone(false) end
		if ply:GetSafeZoneEdge() then ply:SetSafeZoneEdge(false) end
		return
	else
		if ply.SetSafeZone then ply:SetSafeZone(false) end
	end

	ply:GodDisable()
	--ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
end