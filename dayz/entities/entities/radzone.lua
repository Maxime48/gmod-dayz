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
			render.SetMaterial( Material( "color" ) )

			if not LocalPlayer():IsAdmin() then return end
			render.DrawBox( self:GetPos(), self:GetAngles(), self:GetNWVector("min"), self:GetNWVector("max"), Color( 0, 255, 0, 5 ), false )
		end

		render.SetMaterial( Material( "color" ) )
		local curTime = CurTime()
		
		//render.DrawBox( self:GetPos(), self:GetAngles(), self:GetNWVector("min"), self:GetNWVector("max"), Color( 0, 255, 0, 5 ), false )

		if curTime > ( self.lastE or 0 ) + 0.2 then
			//print("effect for radiation code goes here")
			self.lastE = curTime

			local min = self:GetNWVector("min")
			local max = self:GetNWVector("max")
			local pos = Vector( self:GetPos().x + math.random(min.x, max.x), self:GetPos().y + math.random(min.y, max.y), self:GetPos().z + math.random(min.z, max.z) )

			local emitter = ParticleEmitter( pos ) -- Particle emitter in this position

			for i = 0, PHDayZ.MaxRadzoneParticles or 100 do -- Do 100 particles
				pos = Vector( self:GetPos().x + math.random(min.x, max.x), self:GetPos().y + math.random(min.y, max.y), self:GetPos().z + math.random(min.z, max.z) )
				local part = emitter:Add( "particle/particle_smokegrenade", pos ) -- Create a new particle at pos
				if ( part ) then
					part:SetDieTime( 5 ) -- How long the particle should "live"
					part:SetColor(0,150,0)
					part:SetRollDelta(2)
					part:SetBounce(0.8)
					part:SetCollide(true)
					part:SetStartAlpha( 205 ) -- Starting alpha of the particle
					part:SetEndAlpha( 0 ) -- Particle size at the end if its lifetime

					part:SetStartSize( 15 ) -- Starting size
					part:SetEndSize( 0 ) -- Size when removed

					part:SetVelocity( VectorRand() * math.random(100, 500) ) -- Initial velocity of the particle
					part:SetGravity( Vector( 0, 0, -150 ) ) -- Gravity of the particle

				end
			end

			emitter:Finish()
			

		end
		
		self:DestroyShadow()		
	end

end

AccessorFunc(ENT, "MinWorldBound", "MinWorldBound")
AccessorFunc(ENT, "MaxWorldBound", "MaxWorldBound")

function ENT:Initialize()
	if CLIENT then self:SetRenderBounds(Vector(-10000, -10000, -10000), Vector(10000, 10000, 10000)) end
	if not SERVER then return end

	self:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )

	local pos = LerpVector(0.5, self:GetMinWorldBound(), self:GetMaxWorldBound())
	self:SetPos(pos)
	local min = self:WorldToLocal(self:GetMinWorldBound())
	local max = self:WorldToLocal(self:GetMaxWorldBound())

	self:SetNWVector("min", min)
	self:SetNWVector("max", max)

	self:PhysicsInitBox( min, max )
	self:SetCollisionBounds( min, max )

	self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
	self:SetMoveType(MOVETYPE_NONE)

	self:SetTrigger(true)	
end

function ENT:StartTouch(ply)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end

	ply:SetInRadZone(true)
end

function ENT:ShouldCollide(ply)
	return false
end

ENT.NextTouchCheck = 0
function ENT:Touch(ply)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end
	
	if (ply.NextTouchCheck or 0) > CurTime() then return end
	ply.NextTouchCheck = CurTime() + 0.01
	
	if not ply:GetInRadZone() then
		self:StartTouch(ply)
	end	
end

function ENT:EndTouch(ply)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end

	ply:SetInRadZone(false)
end