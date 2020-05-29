
AddCSLuaFile()

SWEP.PrintName = "Base Weapon"
SWEP.Author = "Stranded Team"
SWEP.Contact = ""

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.ViewModelFOV = 54
SWEP.Slot = 0
SWEP.SlotPos = 1

SWEP.Spawnable = false

SWEP.Primary.Damage = 4
SWEP.Primary.Delay = 0.7
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "fist"
SWEP.Skin = 0
SWEP.HitDistance = 75

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
	if ( self.Skin ) then self:SetSkin( self.Skin ) end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:PreDrawViewModel( vm )
	if ( self.Skin && IsValid( vm ) ) then vm:SetSkin( self.Skin ) end
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	
	self:Idle()

	return true
end

function SWEP:Holster()
	if ( self.Owner.InProcess || ProcessCompleteTime ) then return false end
	if ( self.Skin && self.Owner.GetViewModel && IsValid( self.Owner:GetViewModel() ) ) then self.Owner:GetViewModel():SetSkin( 0 ) end

	timer.Destroy( "rb655_idle" .. self:EntIndex() )

	return true
end

function SWEP:Equip( newOwner )
	self:SetHoldType( self.HoldType )
end

function SWEP:OnDrop()
	timer.Destroy( "rb655_idle" .. self:EntIndex() )
end

function SWEP:PrimaryAttack()
	self:SetHoldType( self.HoldType )

	if self.Owner:GetSafeZone() or self.Owner:GetSafeZoneEdge() then return end
	
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
		filter = self.Owner,
		mask = self.Mask
	} )

	if ( !IsValid( tr.Entity ) && !self.NoTraceFix ) then 
		tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
			filter = self.Owner,
			mask = self.Mask
		} )
	end

	if ( tr.Hit or tr.HitWorld ) then
		self:OnHit( tr )
	end

	self:DoEffects( tr )

	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )

end

function SWEP:DoImpactEffects( tr )
	if ( !tr.MatType ) then return end
	if ( tr.MatType == MAT_GRATE ) then tr.Entity:EmitSound( "physics/metal/metal_chainlink_impact_hard" .. math.random( 1, 3 ) .. ".wav" ) return end

	local vecSrc = tr.StartPos
	local vecDirection = tr.Normal
	local pPlayer = self.Owner

	if ( pPlayer && pPlayer:IsPlayer() ) then
		vecSrc = pPlayer:GetShootPos()
		vecDirection = pPlayer:GetAimVector()
	else
		pPlayer = GetWorldEntity()
	end

	local bullet = {}
	bullet.Src = vecSrc
	bullet.Dir = vecDirection
	bullet.Num = 1
	bullet.Damage = 0
	bullet.Force = 0
	bullet.Tracer = 0
	bullet.Callback = function( attacker, tr, dmginfo )
		local doEffects = true
		if ( tr.HitPos:Distance( vecSrc ) > self.HitDistance ) then doEffects = false end
		if ( tr.HitPos:Distance( vecSrc ) > 96 ) then doEffects = false end

		return {
			damage = false,
			effects = doEffects
		}
	end

	pPlayer:FireBullets( bullet )
end

function SWEP:DoEffects( tr )
	if !IsValid(self.Owner) or !IsValid(self) then return end
	if ( IsFirstTimePredicted() ) then
		self:PlaySwingAnimation( !tr.Hit )
		self:PlaySwingSound()
		self:DoImpactEffects( tr )		
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
	end
end

function SWEP:PlaySound( snd )
	if ( CLIENT ) then return end
	if !IsValid(self.Owner) then return end
	
	self.Owner:EmitSound( snd )
end

function SWEP:PlaySwingAnimation( missed )
	timer.Destroy( "rb655_idle" .. self:EntIndex() )
	self:DoAnimation( missed )
	self:Idle()
end

function SWEP:DoAnimation( missed )
	if ( missed ) then self:SendWeaponAnim( ACT_VM_MISSCENTER ) return end
	self:SendWeaponAnim( ACT_VM_HITCENTER )
end

function SWEP:OnHit( tr )
	local ent = tr.Entity

	if ( CLIENT ) then return end

	if IsValid(ent) and ( ent:Health() > 0 ) then
		if ( ent:IsNPC() || ent:IsPlayer() ) then ent:TakeDamage( self.Primary.Damage, self.Owner, self ) end
		self:PlayHitSound()
	else
		self:DoToolHit( tr )
	end
end

function SWEP:DoToolHit( tr )
	self:PlayHitSound()
end

function SWEP:PlaySwingSound()
	self:PlaySound( "weapons/slam/throw.wav" )
end

function SWEP:PlayHitSound()
	self:PlaySound( "Flesh.ImpactHard" )
end

function SWEP:DoIdleAnimation()
	self:SendWeaponAnim( ACT_VM_IDLE )
end

--------------------- IDLE ANIMS ---------------------

function SWEP:DoIdle()
	if !IsValid(self) then return end

	self:DoIdleAnimation()
	timer.Adjust( "rb655_idle" .. self:EntIndex(), self:GetAnimationTime(), 0, function()
		if ( !IsValid( self ) ) then timer.Destroy( "rb655_idle" .. self:EntIndex() ) return end
		self:DoIdleAnimation()
	end )
end

function SWEP:GetAnimationTime()
	local time = self:SequenceDuration()
	if !self.Owner.GetViewModel then return 1 end

	if ( time == 0 ) then time = self.Owner:GetViewModel():SequenceDuration() end
	return time
end

function SWEP:Idle()
	if ( CLIENT ) then return end
	if !IsValid(self) then return end

	timer.Create( "rb655_idle" .. self:EntIndex(), self:GetAnimationTime(), 1, function()
		if ( !IsValid( self ) ) then return end
		self:DoIdle()
	end )
end

if ( SERVER ) then return end

SWEP.FixWorldModel = false
SWEP.FixWorldModelPos = Vector( 0, 0, 0 )
SWEP.FixWorldModelAng = Angle( 0, 0, 0 )
SWEP.FixWorldModelScale = 1

function SWEP:RevertModel()
	self:SetRenderOrigin( self:GetNetworkOrigin() )
	self:SetRenderAngles( self:GetNetworkAngles() )
end

function SWEP:DoFixWorldModel()
	if ( !self.FixWorldModel ) then return end
	if ( !IsValid( self.Owner ) ) then self:RevertModel() return end

	local bone = self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" )
	if ( !bone ) then self:RevertModel() return end

	local pos, ang = self.Owner:GetBonePosition( bone )
	ang:RotateAroundAxis( ang:Forward(), 180 )

	ang:RotateAroundAxis( ang:Forward(), self.FixWorldModelAng.p )
	ang:RotateAroundAxis( ang:Right(), self.FixWorldModelAng.y )
	ang:RotateAroundAxis( ang:Up(), self.FixWorldModelAng.r )

	pos = pos + ang:Forward() * self.FixWorldModelPos.x + ang:Right() * self.FixWorldModelPos.y + ang:Up() * self.FixWorldModelPos.z

	self:SetModelScale( self.FixWorldModelScale, 0 )

	self:SetRenderOrigin( pos )
	self:SetRenderAngles( ang )
end

function SWEP:DrawWorldModel()
	self:DoFixWorldModel()
	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
	self:DrawWorldModel()
end
