AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

util.AddNetworkString("net_UpgradeMenu")
function ENT:Initialize()
	-- set model before spawning this entity

	if self:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then
		self:SetAngles(Angle(0.379, -44.914, 31.420))
	end

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	--self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:SetUseType( SIMPLE_USE )
	self:SetHealth( 200 )

	if self:GetModel() == "models/combine_helicopter/helicopter_bomb01.mdl" then

	end

	self.DoNextThink = 0
	self.nextAlert = 0
end

function ENT:MakeFire()
	if !IsValid(self.fire) then
		self.fire = ents.Create("prop_physics")
		self.fire:SetModel("models/Gibs/HGIBS.mdl")
		--self.fire:SetNoDraw(true)
		local pos = self:LocalToWorld( self:OBBCenter() )
		self.fire:SetPos( pos + Vector( 0, 0, 5 ) )
		self.fire:SetParent(self)
		self.fire:Spawn()
	end

	if !self.fire:IsOnFire() then
		self.fire:Ignite(600)
	end
end

function ENT:StartTouch( ent )
end

function ENT:OnTakeDamage(dmginfo)
	if self:GetPersistent() then return false end
end

function ENT:Think()
	if (self.DoNextThink or 0) > os.time() then return end

	if self:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then
		self:MakeFire()
	end

	if self:GetModel() == "models/combine_helicopter/helicopter_bomb01.mdl" then
		if mCompass_Settings then
			self.nextAlert = self.nextAlert or 0

			if self.nextAlert < os.time() then
				self.nextAlert = os.time() + 60
				
				if self.MarkerID then
					Adv_Compass_RemoveMarker(self.MarkerID)
				end

				self.MarkerID = Adv_Compass_AddMarker(true, self, CurTime() + 60, Color(127,0,255,255), nil, "compass/compass_marker_02", "" )
			end
		end
	end

	if !self:GetPersistent() then
		--self:SetHealth( self:Health() - 1 ) 
		if self:Health() < 1 then
			ItemDestroyed(self:GetPos())
			self:Remove()
		end
	end

	self.DoNextThink = os.time() + 1 -- Let's check once a second, for performances sake.
end

function ENT:OnRemove()

end

function ENT:Use( activator, caller ) 
	if IsValid(caller) and caller:IsPlayer() then

		if self:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then
			caller:ConCommand("menu_tab crafting")

			self:MakeFire()
		elseif self:GetModel() == "models/combine_helicopter/helicopter_bomb01.mdl" then
			if caller:GetPVPTime() > CurTime() then caller:Tip(3, "You cannot teleport while in PVP!", Color(255,0,0,255)) return end

			self:EmitSound("HL1/fvox/bell.wav", 75, 100)
			local time = 10
			if caller:GetInArena() then time = 2 end

			caller:DoModelProcess("models/Gibs/HGIBS.mdl", "Teleporting to SafeZone...", time, "", 0, "", true, function(ply)
		        if not IsValid(caller) or not caller:Alive() then return end

		        SafezoneTeleport(caller)
		    end)
		elseif self:GetModel() == "models/props_junk/trafficcone001a.mdl" then
			if caller:GetPVPTime() > CurTime() then return end

			self:EmitSound("HL1/fvox/bell.wav", 75, 100)

			caller:DoModelProcess("models/Gibs/HGIBS.mdl", "Teleporting to Practice Arena...", 3, "", 0, "", true, function(ply)
		        if not IsValid(caller) or not caller:Alive() then return end

		        SafezoneTeleport(caller, nil, nil, true)
		    end)
		else
			net.Start("net_UpgradeMenu")
			net.Send(caller)
		end
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end 