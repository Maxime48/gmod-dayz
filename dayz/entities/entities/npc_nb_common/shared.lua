AddCSLuaFile()

ENT.Base             = "base_nextbot"
ENT.Spawnable        = false
ENT.AdminSpawnable   = false
ENT.RenderGroup 	 = RENDERGROUP_BOTH

--Stats--
ENT.Speed = 115
ENT.Skins = 22
ENT.SpottedSpeed = 335
ENT.WalkSpeedAnimation = 1
ENT.FlinchSpeed = 0
ENT.IsZombie = true

ENT.health = 200
ENT.Damage = math.random(2,5) -- This is multiplied anyway.

ENT.AttackWaitTime = 0.8
ENT.AttackFinishTime = 0.2
ENT.HitRange = 65

--Model Settings--
ENT.Models = { 
	Model( "models/Zed/malezed_04.mdl" ), 
	Model( "models/Zed/malezed_06.mdl" ), 
	Model( "models/Zed/malezed_08.mdl" ) 
}

ENT.VoiceSounds = {}

ENT.VoiceSounds.Death = { 
	Sound( "cyb_zombies/death1.wav" ),
	Sound( "cyb_zombies/death2.wav" )
}
 
ENT.VoiceSounds.Pain = {
	Sound( "cyb_zombies/pain1.wav" ),
	Sound( "cyb_zombies/pain2.wav" ),
	Sound( "cyb_zombies/pain3.wav" ),
	Sound( "cyb_zombies/pain4.wav" )
}

ENT.VoiceSounds.Idle = {
	Sound( "cyb_zombies/idle1.wav" ),
	Sound( "cyb_zombies/idle2.wav" ),
	Sound( "cyb_zombies/idle3.wav" )
}

ENT.VoiceSounds.Attack = {
	Sound( "cyb_zombies/roar1.wav" ),
	Sound( "cyb_zombies/roar2.wav" ),
	Sound( "cyb_zombies/screech1.wav" ),
	Sound( "cyb_zombies/screech2.wav" ),
	Sound( "zombies/zombie_hit.wav" ),
	Sound( "zombies/zombie_pound_door.wav" )
}

ENT.AttackAnims = { 2059, 2067, 2079 }
ENT.AttackAnimSeq = { "attack01", "attack02", "attack03" }

ENT.WalkAnim = ACT_WALK
ENT.IdleAnim = ACT_IDLE
ENT.RunAnim = ACT_RUN
ENT.FlinchAnim = ACT_COWER

ENT.DoorBreak = Sound("npc/zombie/zombie_pound_door.wav")

ENT.Hit = Sound("npc/zombie/claw_strike1.wav")
ENT.Miss = Sound("npc/zombie/claw_miss1.wav")

function ENT:Initialize()
	
	ZombieTbl = ZombieTbl or {}
	
   	if self.Models then
		local model = table.Random( self.Models )
		self:SetModel( model )
	else	
		self:SetModel( self.Model )
	end	
	
	self:SetSkin(math.random(1, self.Skins))

	self.IsFlinching = false
	self.IsAttacking = false
	self.IsReviving = false
	
	if SERVER then
		self:SetLagCompensated(true)

		self.loco:SetStepHeight(35)	

		self.loco:SetDeceleration(900)
		
		self.modelscale = math.random(6, 10) / 10

		self.loco:SetDeathDropHeight( 300 )	
		self.loco:SetAcceleration( math.random(150, 300) )	
		self.MoveSpeed = math.random(170, 240)

		self.loco:SetJumpHeight( 35 )
		
		local percentage = math.random(1, 100)
		if percentage > 80 then

			self:SetHealth( self.health*2 )
			--self:SetColor( Color(255,0,0,255) )
			self:SetModelScale(1.3, 0)
			self.OPZombie = true
			self.Damage = self.Damage * 1.5

		elseif percentage < 10 then 

			self:SetHealth( self.health/2 )
			self.MoveSpeed = math.random(200, 300)
			self.loco:SetAcceleration( math.random( 300, 400 ) )
			self:SetModelScale( 0.6 , 0 )
			self.MiniZombie = true
			self.Damage = self.Damage / 2 
			
		else
			self:SetHealth( self.health )
		end
	
		self:PhysicsInitBox( Vector(-4,-4,0), Vector(4,4,64) )
		self:SetTrigger( true )

	end

	self:SetSaveValue("fademindist", 2048)
	self:SetSaveValue("fademaxdist", 4096)

	--self:SetCollisionBounds( Vector(-4,-4,0), Vector(4,4,64) ) // nice fat shaming

	self.LoseTargetDist	= 1000	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 500	-- How far to search for enemies
	
	--Animations--
	--self.AttackAnims = { self.AttackAnim1, self.AttackAnim2 }
	
	self.WalkSpeedAnimation = 0.8
	
	--Misc--
	--self:Precache()

	--self.loco:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		
end

function ENT:VoiceSound( tbl )
	if ( self.VoiceTime or 0 ) > CurTime() then return end
	self.VoiceTime = CurTime() + 1.5
	
	local snd = table.Random( tbl )
	if DayZ_NightTime then
		sound.Play( snd, self:GetPos() + Vector(0,0,50), 100, ( self.SoundOverride or math.random( 75, 125 ) ), 0.3 )
	else
		sound.Play( snd, self:GetPos() + Vector(0,0,50), 75, ( self.SoundOverride or math.random( 75, 125 ) ), 0.2 )
	end	
end

function ENT:OnRemove()
	table.RemoveByValue( ZombieTbl, self )
end

////////////////////////////////////////////// Attack //////////////////////////////////////////////
ENT.nxtAttack = 0
function ENT:Attack()

	if !self.nxtAttack then self.nxtAttack = 0 end
    if CurTime() < self.nxtAttack then return end

    self.nxtAttack = CurTime() + 1.4
		
	if ( (self:GetEnemy():IsValid() and self:GetEnemy():Health() > 0 ) ) then
		
		if self.IsReviving or self.IsFlinching then
		else
			self:StartActivity(ACT_RUN)
			if SERVER then
				self:VoiceSound( self.VoiceSounds.Attack )
			end

			self.IsAttacking = true

			--self:RestartGesture( self:GetSequenceActivity( 5 ) )
			--self:StartActivity(ACT_IDLE)
			--self:PlaySequenceAndWait(table.Random( self.AttackAnimSeq ) )
			local name = table.Random( self.AttackAnimSeq )
			local seq = self:LookupSequence(name)

			self.loco:FaceTowards( self:GetEnemy():GetPos() )

			self:PlaySequenceAndWait( seq, 0.9 )
			self:StartActivity( ACT_RUN ) 

			--print()
			--self:SetPoseParameter("move_x",0)

			--timer.Simple(0.4, function() 
				if !self:IsValid() then return end
				if self:Health() < 0 then return end
				if !self:GetEnemy() then return end

				if !IsValid(self:GetEnemy()) then 
					self:StartActivity( self.WalkAnim )
					self.loco:SetDesiredSpeed(self.Speed)
					self:SetPoseParameter("move_x",self.WalkSpeedAnimation)

					self:EmitSound(self.Miss)
					return 
				end
				
				if self:GetEnemy():Health() < 0 then 
					self:StartActivity( self.WalkAnim )
					self.loco:SetDesiredSpeed(self.Speed)
					self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
					
					self:EmitSound(self.Miss)
					return 
				end
				
				self.IsAttacking = false

				if self.IsFlinching or self.IsReviving then return end
				
				if (self:GetRangeTo(self:GetEnemy()) < self.HitRange) then

					local dir = ( self:GetEnemy():GetPos() - self:GetPos() ):GetNormal(); -- replace with eyepos if you want
					local canSee = dir:Dot( self:GetForward() ) > -0.3; -- -1 is directly opposite, 1 is self:GetForward(), 0 is orthogonal
					
					if canSee && ( self:GetEnemy():IsPlayer() or self:GetEnemy():IsNPC() ) then

						local en = self:GetEnemy()
						if en:InVehicle() then
							en = en:GetVehicle()
						end
						self:EmitSound(self.Hit)
						en:TakeDamage(self.Damage, self)
						if self:GetEnemy():IsPlayer() then
							self:GetEnemy():ViewPunch(Angle(math.random(-1, 1)*self.Damage, math.random(-1, 1)*self.Damage, math.random(-1, 1)*self.Damage))
						end
						local bleed = ents.Create("info_particle_system")
						bleed:SetKeyValue("effect_name", "blood_impact_red_01")
						bleed:SetPos(self:GetEnemy():GetPos() + Vector(0,0,70)) 
						bleed:Spawn()
						bleed:Activate() 
						bleed:Fire("Start", "", 0)
						bleed:Fire("Kill", "", 0.2)
						
						local moveAdd=Vector(0,0,150)
						if not en:IsOnGround() then
							moveAdd=Vector(0,0,0)
						end
						en:SetVelocity(moveAdd+((self:GetEnemy():GetPos()-self:GetPos()):GetNormal()*100)) -- apply the velocity
					end
				end
				self:EmitSound(self.Miss)
			--end)
			
			--self:StartActivity( self.WalkAnim )
			--self.loco:SetDesiredSpeed(self.Speed)
			self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
		
		end
	end
end

function ENT:EmitVoiceSound( snd )
	if ( self.VoiceTime or 0 ) > CurTime() then return end
	self.VoiceTime = CurTime() + 1.5
	
	if DayZ_NightTime then
		sound.Play( snd, self:GetPos() + Vector(0,0,50), 100, ( self.SoundOverride or math.random( 75, 125 ) ), 0.3 )
	else
		sound.Play( snd, self:GetPos() + Vector(0,0,50), 75, ( self.SoundOverride or math.random( 75, 125 ) ), 0.2 )
	end
end

function ENT:AttackProp()
	local vec = Vector(self.HitRange,self.HitRange,self.HitRange)
	local entstoattack = ents.FindInBox(self:GetPos()+vec, self:GetPos()-vec)
	for _,v in pairs(entstoattack) do
	
		if ( v:GetClass() == "prop_physics" || v:GetClass() == "prop_physics_multiplayer" ) then
			if v:Health() < 1 or v.ZombPunched or v:GetPersistent() then continue end
			
			if SERVER then
				self:VoiceSound( self.VoiceSounds.Attack )
			end
			self:RestartGesture( self:GetSequenceActivity( 5 ) )
			self:SetPoseParameter("move_x",0)

			if v:GetMoveType() == MOVETYPE_VPHYSICS and IsValid( v:GetPhysicsObject() ) and v:GetPhysicsObject():IsMotionEnabled() then
				v:SetPos( self:GetPos() + Vector(0, 0, 50) + self:GetForward()*10 )
				v.ZombFreeze = true
				v:GetPhysicsObject():EnableMotion(false)
			end

			coroutine.wait(self.AttackWaitTime-0.5)
			self:EmitSound(self.Miss)
			
			if !self:IsValid() then break end
			if self:Health() < 0 then break end
			
			if !v:IsValid() then 
				self:StartActivity( self.WalkAnim )
				self.loco:SetDesiredSpeed(self.Speed)
				self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
				
				self:EmitSound(self.Miss)
				continue 
			end
		
			if v:Health() < 0 then 
				--self:StartActivity( self.WalkAnim )
				--self.loco:SetDesiredSpeed(self.Speed)
				self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
			
				self:EmitSound(self.Miss)
				continue 
			end
		
			if (self:GetRangeTo(v) < self.HitRange) then

				local phys = v:GetPhysicsObject()
				if (phys != nil && phys != NULL && phys:IsValid()) then

					if v.ZombFreeze then
						phys:EnableMotion(true)
					end

					if phys:GetMass() < 500 then
						local postohit = self:GetForward():GetNormalized()*1000 + Vector(0, 0, 10)

						if IsValid(self:GetEnemy()) then

							-- Thanks James! :D
							postohit = ( ( self:GetEnemy():GetPos() - self:GetPos() ):GetNormalized()*phys:GetMass() ) * 700 + Vector(0, 0, 10)

						end

						phys:ApplyForceCenter( postohit )
					end

					v:EmitSound( self.DoorBreak )
					v:TakeDamage( self.Damage, self )	
					v.ZombPunched = true
					timer.Simple(5, function() if IsValid(v) then v.ZombPunched = false end end)
				end
				
			end
			coroutine.wait(self.AttackFinishTime)	
			self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
			--self:StartActivity( self.WalkAnim )
			--self.loco:SetDesiredSpeed(self.Speed)
		
			return true
		end
	end
	return false
end

function ENT:AttackBreakable()
	local vec = Vector(self.HitRange,self.HitRange,self.HitRange)
	local entstoattack = ents.FindInBox(self:GetPos()+vec, self:GetPos()-vec)
	for _,v in pairs(entstoattack) do
	
		if ( v:GetClass() == "func_breakable" || v:GetClass() == "func_physbox" || v:GetClass() == "func_door_rotating" || v:GetClass() == "prop_door_rotating" || v:GetClass() == "func_door" || v:GetClass() == "prop_vehicle_jeep" ) then
		
			if v.DoorOpen then 
				return
			end

			if SERVER then
				self:VoiceSound( self.VoiceSounds.Attack )
			end

			self:RestartGesture( self:GetSequenceActivity( 5 ) )
			self:SetPoseParameter("move_x",0)
			coroutine.wait(self.AttackWaitTime)
			self:EmitSound(self.Miss)
			
			if !self:IsValid() then return end
			if self:Health() < 0 then return end
			
			if !v:IsValid() then 
				--self:StartActivity( self.WalkAnim )
				self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
				
				self:EmitSound(self.Miss)
				return 
			end
			
			if v:Health() < 0 then 
				--self:StartActivity( self.WalkAnim )
				self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
				
				self:EmitSound(self.Miss)
				return
			end
			
			v:EmitSound(self.DoorBreak)
			v:TakeDamage(self.Damage, self)	
			
			v:Fire("open")
			v.DoorOpen = true
			timer.Simple(5, function() if IsValid(v) then v.DoorOpen = false end end)
			
			coroutine.wait(self.AttackFinishTime)
			self:SetPoseParameter("move_x",self.WalkSpeedAnimation)		
			--self:StartActivity( self.WalkAnim )
		
			return true
		end
	end
	return false
end


////////////////////////////////////////////// Enemy //////////////////////////////////////////////
function ENT:GetEnemy()
	return self.Enemy
end

function ENT:SetEnemy( ent )
	if ent then
		self:StopMovingToPos()
	end
	--print(ent:GetClass().." called SetEnemy")
	self.Enemy = ent
end

function ENT:CanTarget(ent)
	if !IsValid(ent) then return false end

	if !ent:IsPlayer() then return false end
	if !ent:Alive() then return false end
	if ( ent.Noclip or ent:GetSafeZoneEdge() or ent:GetSafeZone() or ent.Loading ) then 
		return false
	end

	local dir = ( ent:GetPos() - self:GetPos() ):GetNormal(); -- replace with eyepos if you want
	local canSee = dir:Dot( self:GetForward() ) > -0.5; -- -1 is directly opposite, 1 is self:GetForward(), 0 is orthogonal

	local length = ent:GetVelocity():Length()
	if !self:IsLineOfSightClear( ent ) and length > 100 then canSee = true end -- if the fool is running, chase them!

	return canSee
end

function ENT:HaveEnemy()
	if ( self:GetEnemy() and IsValid( self:GetEnemy() ) ) then
		if ( self:GetRangeTo( self:GetEnemy():GetPos() ) > self.LoseTargetDist ) then
			return self:FindEnemy()
		elseif !self:CanTarget( self:GetEnemy() ) then
			return self:FindEnemy()
		end	
		return self:GetEnemy()
	else
		return self:FindEnemy()
	end
end

function ENT:FindEnemy()
	self:SetEnemy(nil)
	local vec = Vector(self.SearchRadius, self.SearchRadius, self.SearchRadius)
	--local _ents = ents.FindInCone( self:GetPos() + self:GetUp()*15, self:GetForward(), 70, 70 )
	local _ents = ents.FindInBox( self:GetPos() + vec, self:GetPos() - vec )	
	local found = nil
	for k, v in pairs( _ents ) do
		if self:CanTarget( v ) then
			self:StopMovingToPos()
			self:EmitVoiceSound( "cyb_zombies/alertroar.wav" )
			found = v
			break
		end
	end	
	if IsValid(found) then
		self:SetEnemy(found)
	end
	return self:GetEnemy()
end

function ENT:RunBehaviour()
	while ( true ) do
		self.wait = 0.1

		if #player.GetAll() < 1 then coroutine.wait( self.wait ) continue end

		if ( self:HaveEnemy() ) then
			
			self:StartActivity( self.RunAnim )
			
			self:SetPoseParameter("move_x", self.WalkSpeedAnimation)
			self.loco:SetDesiredSpeed( self.MoveSpeed )
			
			--self:StopMovingToPos()

			self.HasMovePos = self:GetEnemy():GetPos()

			self:ChaseEnemy()
			self:StartActivity( self.RunAnim )

		elseif self.HasMovePos then
			
			self:StartActivity( self.RunAnim )
			
			self:SetPoseParameter("move_x", self.WalkSpeedAnimation)
			self.loco:SetDesiredSpeed( self.MoveSpeed )

			self:StopMovingToPos()
			self:MoveToPos( self.HasMovePos, { tolerance = 30, maxage = 0.1, lookahead = 10, repath = 2 } )

			self.HasMovePos = nil

		else

			self.HasMovePos = nil

			-- Wander around			
			self:StartActivity( self.WalkAnim )
			
			self:SetPoseParameter("move_x", self.WalkSpeedAnimation)
			self.loco:SetDesiredSpeed( self.Speed / 2 )
			
			self:VoiceSound( self.VoiceSounds.Idle )

			--self:StopMovingToPos()
			//self:MoveToSpot( self:GetPos() + Vector( math.random( -1, 1 ), math.random( -1, 1 ), 0 ) * math.random(150, 500) )

			if !self.AlreadyMoving then
				self:MoveSomeWhere(1000);
			end

			self:SetPoseParameter("move_x",0)
			self:StartActivity( ACT_IDLE ) 
			self.wait = 0.5
			
		end
		
		if math.random( 1,3 ) == 1 then
			self:VoiceSound( self.VoiceSounds.Idle )
		end

		coroutine.wait( self.wait )
		
	end
end	

ENT._AllowedToMove = true
function ENT:StopMovingToPos( )
	self._AllowedToMove = false
end	

function ENT:Think()
	if CLIENT then return end

	if (self.nextMovePhys or 0) < CurTime() then
		local phys = self:GetPhysicsObject() -- YES. Nextbots DO NOT move their physics object. It's stored at origin 0,0,0
		if IsValid(phys) then
			phys:EnableMotion( false )
			phys:SetPos( self:GetPos() )
			phys:SetAngles( self:GetAngles() )
		else
			CreateCorpse(self)
		end

		self.nextMovePhys = CurTime() + 0.1
	end

	if ( self.NextDoThink or 0 ) > CurTime() then return end

	if #player.GetAll() < 1 then return end
	local pos = self:GetPos()

	if pos == self.LastPos and !self.IsAttacking then
		self.removecount = ( self.removecount or 0 ) + 1
	else
		self.removecount = 0
	end
	
	self.LastPos = pos

	if ( self.removecount or 0 ) > 2 then
		CreateCorpse(self)
		return
	end

	local tr = {}
	tr.start = pos 
	tr.endpos = tr.start - Vector(0, 0, 100)
	tr.filter = self
	tr = util.TraceLine(tr)
	
	if tr.HitNoDraw then
		CreateCorpse(self)
		return
	end

	self.NextDoThink = CurTime() + 5
end

function ENT:MoveSomeWhere(distance)
    distance = distance or 1000
    self.loco:SetDesiredSpeed( self.Speed / 2 )
    local navs = navmesh.Find(self:GetPos(), distance, 120, 120)
    local nav = navs[math.random(1,#navs)]
    if !IsValid(nav) then return end
    if nav:IsUnderwater() then return end -- we dont want them to go into water
    local pos = nav:GetRandomPoint()

    local tr = {}
	tr.start = pos 
	tr.endpos = tr.start + Vector(0, 0, 1000)
	tr.filter = self
	tr = util.TraceLine(tr)
	if tr.Hit && !tr.HitSky then return end -- something is above us, don't spawn the zombie.

    local maxAge = math.Clamp(pos:Distance(self:GetPos())/120, 0.1,10)
    self:MoveToPos( pos, { tolerance = 30, maxage = maxAge, lookahead = 10, repath = 2 })
end

function ENT:MoveToPos( pos, options )

	local options = options or {}
	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or self.HitRange )
	path:Compute( self, pos )

	if ( !path:IsValid() ) then return "failed" end
	-- We just called this function so of course we want to move
	self._AllowedToMove = true
	-- While the path is still valid and the bot is allowed to move
	while ( path:IsValid() and self._AllowedToMove and !self:HaveEnemy() ) do
		path:Update( self )
		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then
			path:Draw()
		end
		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck();
			self:StopMovingToPos()
			return "stuck"
		end
		-- If they set maxage on options then make sure the path is younger than it
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end
		-- If they set repath then rebuild the path every x seconds
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos ) end
		end


		if (self:AttackProp()) then
			else
			if (self:AttackBreakable()) then
			end 
		end

		coroutine.yield()
	end
	return "ok"
	
end

function ENT:OnOtherKilled()
	
end

function ENT:ChaseEnemy( options )
	local options = options or {}
	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or self.HitRange )
	
	local computedPath = path:Compute( self, self:GetEnemy():GetPos() )
	if !computedPath then CreateCorpse(self) return "failed" end
	
	if ( !path:IsValid() ) then path:Invalidate() print("aaa") return "failed" end

	self._AllowedToMove = true
	self.HasMovePos = self:GetEnemy():GetPos()

	while ( path:IsValid() and self:HaveEnemy() ) do

		if ( path:GetAge() > 0.2 ) then	
			path:Compute( self, self:GetEnemy():GetPos() )
		end

		path:Update( self )

		self.loco:FaceTowards( self:GetEnemy():GetPos() )

		if ( options.draw ) then path:Draw() end
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end

		if math.random( 1,200 ) == 5 then
			self:VoiceSound( self.VoiceSounds.Idle )
		end
				
		if self:GetRangeTo(self:GetEnemy()) < self.HitRange then
			if self:CanTarget(self:GetEnemy()) then
				self:Attack()
			end
		else
			self:AttackProp() 
			self:AttackBreakable()
		end
			
		coroutine.yield()
	end	
	
	return "ok"
end

////////////////////////////////////////////// Damage Info //////////////////////////////////////////////
function ENT:OnKilled( dmginfo )
	self:VoiceSound( self.VoiceSounds.Death )
	
	CreateCorpse(self, dmginfo)
end

function ENT:OnInjured( dmginfo )

	if ( dmginfo:GetAttacker():IsPlayer() or dmginfo:GetAttacker():IsNPC() ) then
		if self:IsValid() and self:Health() > 0 then
			local attacker = dmginfo:GetAttacker()
			self.SearchRadius = self:GetRangeTo(attacker) + 1000
			self:SetEnemy(attacker)
		end
	end

	if dmginfo:IsExplosionDamage() then
		dmginfo:ScaleDamage(3)
	end

	if math.random(1, 15) > 10 then
	
		if !self:IsValid() then return end
		if self:Health() < 0 then return end

		self:StartActivity( self.FlinchAnim )
		self:VoiceSound( self.VoiceSounds.Pain )
		self.loco:SetDesiredSpeed( self.FlinchSpeed )	
	
		timer.Simple(0.6, function() 
			if !self:IsValid() then return end
			if self:Health() < 0 then return end
			self.loco:SetDesiredSpeed(self.MoveSpeed)		
			self:StartActivity( self.RunAnim )
			self:SetPoseParameter("move_x",self.WalkSpeedAnimation)
		end)
		
	end
	
	if math.random(1,3) == 1 then
		self:VoiceSound( self.VoiceSounds.Pain )
	end
	
end