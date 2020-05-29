
AddCSLuaFile()

SWEP.PrintName				= "Hands"
SWEP.Author					= "Kilburn, robotboy655, MaxOfS2D & Tenrys"
SWEP.Purpose				= "Well we sure as hell didn't use guns! We would just wrestle Hunters to the ground with our bare hands! I used to kill ten, twenty a day, just using my fists."

SWEP.Slot					= 0
SWEP.SlotPos				= 4

SWEP.Spawnable				= true

SWEP.ViewModel				= Model( "models/weapons/c_arms_citizen.mdl" )
SWEP.WorldModel				= ""
SWEP.ViewModelFOV			= 54
SWEP.UseHands				= true
SWEP.HoldType				= "normal"
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.DrawAmmo				= false

SWEP.HitDistance			= 48

local SwingSound = Sound( "WeaponFrag.Throw" )
local HitSound = Sound( "Flesh.ImpactHard" )

function SWEP:Initialize()

	self:SetEnabled( false )

	self:SetHoldType( self.HoldType )

end

function SWEP:PreDrawViewModel( vm, wep, ply )
	
	vm:SetMaterial( "engine/occlusionproxy" ) -- Hide that view model with hacky material

end

function SWEP:SetupDataTables()

	self:NetworkVar( "Float", 0, "NextMeleeAttack" )
	self:NetworkVar( "Float", 1, "NextIdle" )
	self:NetworkVar( "Int", 2, "Combo" )
	self:NetworkVar( "Bool", 0, "Enabled" )

end

if CLIENT then
	function SWEP:DoDrawCrosshair( x, y )
		return !self:GetEnabled()
	end
end

function SWEP:Reload()
	if !PHDayZ.Player_FistsEnabled then return end

	if (self.NextReload or 0) > CurTime() then return end
	self.NextReload = CurTime() + 1

	self:SetEnabled( !self:GetEnabled() )

	--self:SetHoldType( self.HoldType )
	self:SetHoldType( self:GetEnabled() and "fist" or self.HoldType )
	self.PrintName = self:GetEnabled() and "Fists" or "Hands"

	
end

function SWEP:GetViewModelPosition( pos, ang )
	self.LastVMMod = math.Approach( self.LastVMMod or 0, self:GetEnabled() and 0 or 30, 30*FrameTime() ) // Change by 30 units per second, to either 0 or 30 units (Depending on fists raised)
	ang:RotateAroundAxis( ang:Right(), -self.LastVMMod )
	
	return pos, ang
end

function SWEP:UpdateNextIdle()

	local vm = self.Owner:GetViewModel()
	self:SetNextIdle( CurTime() + vm:SequenceDuration() )

end

function SWEP:PrimaryAttack( right )

	if self.Owner:GetSafeZone() then return end

	if !self:GetEnabled() then return end
	
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	local anim = "fists_left"
	if ( right ) then anim = "fists_right" end
	if ( self:GetCombo() >= 2 ) then
		anim = "fists_uppercut"
	end

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( anim ) )

	self:EmitSound( SwingSound )

	self:UpdateNextIdle()
	self:SetNextMeleeAttack( CurTime() + 0.2 )
	
	self:SetNextPrimaryFire( CurTime() + 0.9 )
	self:SetNextSecondaryFire( CurTime() + 0.9 )

	if CLIENT then return end

	if self.Owner:GetVelocity():Length() > 5 then return end

	if self.Owner:GetInArena() then return end

	local trace = {}
    trace.start = self.Owner:GetShootPos()
    trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
    trace.filter = self.Owner

    local tr = util.TraceLine(trace)

    if tr.HitNonWorld then return end
    --PrintTable(tr)

    local item
    if string.find(string.lower(tr.HitTexture), "stone") then item = "item_stone" end
    if string.find(string.lower(tr.HitTexture), "cement") then item = "item_stone" end
    if string.find(string.lower(tr.HitTexture), "concrete") then item = "item_stone" end
    if string.find(string.lower(tr.HitTexture), "brick") then item = "item_stone" end
    if string.find(string.lower(tr.HitTexture), "metal") then item = "item_metal" end
    if tr.MatType == MAT_WOOD or ( tr.MatType == 67 && tr.HitTexture == "**studio**" ) then item = "item_wood" end
    if string.find(string.lower(tr.HitTexture), "wood") then item = "item_wood" end

    if !item then return end

 	if item == "item_stone" then

		self.Owner:DoCustomProcess(item, "Mining", 8, "npc/vort/claw_swing"..math.random(1,2)..".wav", 2, "npc/vort/claw_swing"..math.random(1,2)..".wav", false, function(ply)

			ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))
			
			--local rng = math.random(0, 25)
			--if rng > 20 and rng < 25 then
				if DZ_Quests then
					ply:DoQuestProgress("quest_monkeyminer", 1)
				end
				ply:Tip(3, "minedstone")
				ply:GiveItem("item_stone", 1, nil, nil, nil, nil, true)
			--end

			if math.random(0, 25) < 23 then
				ply:TakeBlood(5)
				ply:EmitSound("vo/npc/male01/myarm0"..math.random(1,2)..".wav")
			end

		end)

	elseif item == "item_wood" then
		
		self.Owner:DoCustomProcess(item, "Chopping", 8, "npc/vort/claw_swing"..math.random(1,2)..".wav", 2, "npc/vort/claw_swing"..math.random(1,2)..".wav", false, function(ply)

			ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))
			
			--local rng = math.random(0, 25)
			--if rng > 20 and rng < 25 then
				ply:Tip(3, "gotwood")
				ply:GiveItem("item_wood", 1, nil, nil, nil, nil, true)
			--end
				if DZ_Quests then
					ply:DoQuestProgress("quest_monkeychopper", 1)
				end

			if math.random(0, 25) < 23 then
				ply:TakeBlood(5)
				ply:EmitSound("vo/npc/male01/myarm0"..math.random(1,2)..".wav")
			end

		end)

	elseif item == "item_metal" then
		
		self.Owner:DoCustomProcess(item, "Collecting", 15, "npc/vort/claw_swing"..math.random(1,2)..".wav", 2, "npc/vort/claw_swing"..math.random(1,2)..".wav", false, function(ply)

			ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))

			--local rng = math.random(0, 25)
			--if rng > 20 and rng < 25 then
				ply:Tip(3, "gotmetal")
				ply:GiveItem("item_metal", 1, nil, nil, nil, nil, true)
			--end

			if math.random(0, 25) < 23 then
				ply:TakeBlood(5)
				ply:EmitSound("vo/npc/male01/myarm0"..math.random(1,2)..".wav")
			end

		end)

	end

end

function SWEP:SecondaryAttack()

	self:PrimaryAttack( true )

end

function SWEP:DealDamage()
	if !self:GetEnabled() then return end

	local anim = self:GetSequenceName(self.Owner:GetViewModel():GetSequence())

	self.Owner:LagCompensation( true )
	
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
		filter = self.Owner
	} )

	if ( !IsValid( tr.Entity ) ) then 
		tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
			filter = self.Owner,
			mins = Vector( -10, -10, -8 ),
			maxs = Vector( 10, 10, 8 )
		} )
	end

	-- We need the second part for single player because SWEP:Think is ran shared in SP
	if ( tr.Hit && !( game.SinglePlayer() && CLIENT ) ) then
		self:EmitSound( HitSound )
	end

	local hit = false

	if ( SERVER && IsValid( tr.Entity ) && ( tr.Entity:IsNPC() || tr.Entity:IsPlayer() || tr.Entity:Health() > 0 ) ) then
		local dmginfo = DamageInfo()
		dmginfo:SetDamageType(DMG_CLUB)
		local attacker = self.Owner
		if ( !IsValid( attacker ) ) then attacker = self end
		dmginfo:SetAttacker( attacker )

		dmginfo:SetInflictor( self )
		dmginfo:SetDamage( math.random( 6, 10 ) )

		if ( anim == "fists_left" ) then
			--dmginfo:SetDamageForce( self.Owner:GetRight() * 4912 + self.Owner:GetForward() * 9998 ) -- Yes we need those specific numbers
		elseif ( anim == "fists_right" ) then
			--dmginfo:SetDamageForce( self.Owner:GetRight() * -4912 + self.Owner:GetForward() * 9989 )
		elseif ( anim == "fists_uppercut" ) then
			--dmginfo:SetDamageForce( self.Owner:GetUp() * 5158 + self.Owner:GetForward() * 10012 )
			dmginfo:SetDamage( math.random( 8, 12 ) )
		end

		tr.Entity:TakeDamageInfo( dmginfo )
		hit = true

	end

	if ( SERVER && IsValid( tr.Entity ) ) then
		local phys = tr.Entity:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:ApplyForceOffset( self.Owner:GetAimVector() * 80 * phys:GetMass(), tr.HitPos )
		end
	end

	if ( SERVER ) then
		if ( hit && anim != "fists_uppercut" ) then
			self:SetCombo( self:GetCombo() + 1 )
		else
			self:SetCombo( 0 )
		end
	end

	self.Owner:LagCompensation( false )

end

function SWEP:OnRemove()

	if ( IsValid( self.Owner ) && CLIENT && self.Owner:IsPlayer() ) then
		local vm = self.Owner:GetViewModel()
		if ( IsValid( vm ) ) then vm:SetMaterial( "" ) end
	end

end

function SWEP:OnDrop()

	self:Remove() -- You can't drop fists

end

function SWEP:Holster()

	self:OnRemove()

	return true

end

function SWEP:Deploy()

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_draw" ) )
	
	self:UpdateNextIdle()
	
	if ( SERVER ) then
		self:SetCombo( 0 )
	end

	return true

end

function SWEP:Think()

	local vm = self.Owner:GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if ( idletime > 0 && CurTime() > idletime ) then

		vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_idle_0" .. math.random( 1, 2 ) ) )
		
		self:UpdateNextIdle()

	end

	local meleetime = self:GetNextMeleeAttack()

	if ( meleetime > 0 && CurTime() > meleetime ) then

		self:DealDamage()
		
		self:SetNextMeleeAttack( 0 )

	end

	if ( SERVER && CurTime() > self:GetNextPrimaryFire() + 0.1 ) then
		
		self:SetCombo( 0 )
		
	end

end