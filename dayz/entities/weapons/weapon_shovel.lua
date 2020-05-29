
AddCSLuaFile()

SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.Base = "weapon_base_process"
SWEP.PrintName = "Shovel"
SWEP.ViewModel = "models/weapons/c_gms_shovel.mdl"
SWEP.WorldModel = "models/weapons/w_gms_shovel.mdl"

SWEP.Purpose = "Dig"
SWEP.Instructions = "Use primary to dig"

SWEP.HoldType = "melee"
SWEP.UseHands = true

SWEP.Primary.Damage = 34
SWEP.Primary.Delay = 1.5
SWEP.HitDistance = 92

function SWEP:PlaySwingSound()
	self:PlaySound( "npc/vort/claw_swing" .. math.random( 1, 2 ) .. ".wav" )
end

function SWEP:PlayHitSound()
	self:PlaySound( "weapons/gms_shovel" .. math.random( 1, 4 ) .. ".wav" )
end

function SWEP:DoToolHit( tr )

	local item = "seed_cactus"

    if tr.MatType == MAT_DIRT or tr.MatType == MAT_SAND or tr.MatType == MAT_GRASS then 

	   	if !GAMEMODE.DayZ_Items[item] then return end

	 	local timetoprocess = 6
	 	if self.Owner:HasPerk("perk_fancyfarmer") then
	 		timetoprocess = timetoprocess/2
	 	end

	 	if self.Owner:GetSafeZone() or self.Owner:GetSafeZoneEdge() then return end
	 	
		if item and	!self.Owner:GetSafeZone() and !self.Owner:GetSafeZoneEdge() and !self.Owner.InProcess then
			self.Owner:DoModelProcess("models/weapons/w_gms_shovel.mdl", "Foraging", timetoprocess, "weapons/iceaxe/iceaxe_swing1.wav", 0, "physics/glass/glass_bottle_impact_hard" .. math.random( 1, 3 ) .. ".wav", false, function(ply)

				local seedtypes = {"item_stone", "seed_apple", "seed_banana", "seed_cactus", "seed_melon", "seed_orange", "seed_potato", "seed_wheat"}

				local rng = math.random(0, 100)
				if rng > 90 then
					local item = table.Random(seedtypes)
					
					ply:Tip(3, "youfound", Color(255,255,255,255), GAMEMODE.DayZ_Items[item].Name.."!")

					ply:GiveItem(item, 1, false, nil, nil, nil, nil, true)

					ply:XPAward(3, "Foraging")
				end

			end)
			timer.Create("WeaponSwing_"..self.Owner:EntIndex(), 1, timetoprocess, function() if IsValid(self.Owner) and self.Owner.InProcess then self:PrimaryAttack() end end) 
		else
			self:PlayHitSound()
		end

	end
end

function SWEP:DoAnimation( missed )
	if ( missed ) then self:SendWeaponAnim( ACT_VM_MISSCENTER ) return end
	self:SendWeaponAnim( ACT_VM_HITCENTER )
end

function SWEP:DoEffects( tr )
	if ( IsFirstTimePredicted() ) then
		self:PlaySwingAnimation( tr.HitWorld )
		self:PlaySwingSound()
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		if ( tr.HitWorld || ( tr.MatType != MAT_DIRT && tr.MatType != MAT_GRASS && tr.MatType != MAT_SAND ) ) then
			self:DoImpactEffects( tr )
		else
			util.Decal( "impact.sand", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )
		end
	end
end
