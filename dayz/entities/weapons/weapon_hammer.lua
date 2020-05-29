AddCSLuaFile()
AddCSLuaFile("sh_sounds.lua")
include("sh_sounds.lua")

if CLIENT then
	SWEP.DrawCrosshair = true
	SWEP.PrintName = "Hammer"
	SWEP.CSMuzzleFlashes = true
	
	SWEP.DisableSprintViewSimulation = true
	
	SWEP.DrawTraditionalWorldModel = true
	SWEP.WM = "models/weapons/w_dangerzone_hammer.mdl"
	
	SWEP.IconLetter = "j"
	killicon.Add("cw_ws_pamachete", "vgui/kills/cw_ws_pamachete", Color(255, 80, 0, 150))
	SWEP.SelectIcon = surface.GetTextureID("vgui/kills/cw_ws_pamachete")
end

SWEP.Animations = {
	slash_primary = {"hit", "hit1"},
	slash_secondary = "hit2",
	draw = "draw"
}

CustomizableWeaponry:addFireSound("CW_KNIFE_DZDRAW", "weapons/dzhammer/draw1.wav", 1, 80, CHAN_STATIC)

CustomizableWeaponry:addFireSound("CW_KNIFE_DZSLASH1", "weapons/dzhammer/knife_slash1.wav", 1, 80, CHAN_STATIC)
CustomizableWeaponry:addFireSound("CW_KNIFE_DZSLASH2", "weapons/dzhammer/knife_slash2.wav", 1, 80, CHAN_STATIC)

CustomizableWeaponry:addFireSound("CW_KNIFE_DZHIT1", "weapons/dzhammer/knife_hit1.wav", 1, 80, CHAN_STATIC)
CustomizableWeaponry:addFireSound("CW_KNIFE_DZHIT2", "weapons/dzhammer/knife_hit2.wav", 1, 80, CHAN_STATIC)


CustomizableWeaponry:addFireSound("CW_KNIFE_DZHITWALL1", "weapons/dzhammer/knife_hit_01.wav", 1, 80, CHAN_STATIC)
CustomizableWeaponry:addFireSound("CW_KNIFE_DZHITWALL2", "weapons/dzhammer/knife_hit_02.wav", 1, 80, CHAN_STATIC)

SWEP.Sounds = {
	hit = {{time = 0.05, sound = "CW_KNIFE_DZSLASH1", "CW_KNIFE_DZSLASH2"}},
	hit1 = {{time = 0.05, sound = "CW_KNIFE_DZSLASH2", "CW_KNIFE_DZSLASH1"}},
	hit2 = {{time = 0.05, sound = "CW_KNIFE_DZSLASH2", "CW_KNIFE_DZSLASH1"}},
	draw = {{time = 0.2, sound = "CW_KNIFE_DZDRAW"}},
}

SWEP.PlayerHitSounds = {"CW_KNIFE_DZHIT1", "CW_KNIFE_DZHIT2"}
SWEP.MiscHitSounds = {"CW_KNIFE_DZHITWALL1", "CW_KNIFE_DZHITWALL2"}

SWEP.Slot = 0
SWEP.SlotPos = 0
SWEP.Base = "cw_melee_base"
SWEP.Category = "CW 2.0 GMDayZ"
SWEP.NormalHoldType = "melee"

SWEP.Author			= "Phoenixf129"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 55
SWEP.ViewModelFlip	= false
SWEP.ViewModel = "models/weapons/v_dangerzone_hammer.mdl"
SWEP.WorldModel = "models/weapons/w_dangerzone_hammer.mdl"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.Primary.ClipSize		= 0
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ""

SWEP.PrimaryAttackDelay = 0.95
SWEP.SecondaryAttackDelay = 1.10

SWEP.PrimaryAttackDamage = {10, 30}
SWEP.SecondaryAttackDamage = {10, 30}
SWEP.CanBackstab = false
SWEP.ImpactDecal = "Impact.Concrete"

SWEP.PrimaryAttackRange = 65

SWEP.HolsterTime = 0.4
SWEP.DeployTime = 0.6

SWEP.PrimaryAttackImpactTime = 0.2
SWEP.PrimaryAttackDamageWindow = 0.15

SWEP.SecondaryAttackImpactTime = 0.2
SWEP.SecondaryAttackDamageWindow = 0.15

SWEP.PrimaryHitAABB = {
	Vector(-10, -5, -5),
	Vector(10, 5, 5)
}

function SWEP:PrimaryAttack()
	if not self:canAttack() then
		return
	end

	local time = CurTime() + self.PrimaryAttackDelay
	
	if IsFirstTimePredicted() then
		
		local tr = self.Owner:GetEyeTraceNoCursor()
		
		local dontattack = false
		local ent = tr.Entity

		if IsValid(ent) && ( ent:GetClass() == "prop_physics" or ent:GetClass() == "dz_interactable" ) && !ent.NoNails && !ent:GetPersistent() then 
			dontattack = true

			time = CurTime() + self.PrimaryAttackDelay * 2

			if SERVER then  -- no further client realm!

				local hp = ent:Health()
				local add = hp/40
				if add < 50 then add = 50 end -- min heal is 50.

				local to_add = math.Clamp(hp + add, 0, ent:GetMaxHealth() )
				if hp != to_add then 
					ent:SetHealth( to_add )
					self.Owner:EmitSound("plats/tram_hit1.wav", 75, 180, 0.2)
				end

				local it = GAMEMODE.Util:GetItemByDBID(self.Owner.CharTable, self.itemid)
				if it == nil then return end
				
				it.quality = it.quality - add/2

				self.Owner:UpdateChar(it.id, it.class)
			end

		end 
		if !dontattack then
			self:beginAttack(self.PrimaryAttackImpactTime, self.PrimaryAttackDamageWindow, self.PrimaryAttackDamage, self.PrimaryAttackRange, self.PrimaryHitAABB)
		end
		self:sendWeaponAnim("slash_primary", self.FireAnimSpeed)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end
	
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
	self.ReloadWait = time
end

function SWEP:SecondaryAttack()
	if not self:canAttack(true) then
		return
	end
	
	if IsFirstTimePredicted() then
		local tr = self.Owner:GetEyeTraceNoCursor()
		
		local dontattack = false
		local ent = tr.Entity

		ent.Nails = ent.Nails or {}
		
		local aimvec = self.Owner:GetAimVector()

		local tr2 = util.TraceLine({start = tr.HitPos, endpos = tr.HitPos + aimvec * 24, filter = {self.Owner, ent}})

		if !tr2.HitSky then
			local ent2 = tr2.Entity

			if tr2.HitWorld	or IsValid(ent2) then
				if SERVER then

					if ent:GetClass() == "prop_physics" && !ent.NoNails && !ent:GetPersistent() then
						local phys = ent:GetPhysicsObject()

						if IsValid(phys) && !ent.Nailed then

							if self.Owner:HasItem("item_nail", true) then

								phys:EnableMotion(false)
								ent.Nailed = true
								self.Owner:EmitSound("weapons/crossbow/hit1.wav", 75, 140, 0.3)

								local nail = ents.Create("prop_physics")
								nail:SetModel("models/crossbow_bolt.mdl")
								--nail:SetActualOffset(tr.HitPos, trent)
								nail:SetPos(tr.HitPos - aimvec * 8)
								nail:SetAngles( aimvec:Angle() )

								nail:Spawn()
								local phys = nail:GetPhysicsObject()
								if IsValid(phys) then
									phys:EnableMotion(false)
									phys:Sleep()
								end

								ent:DeleteOnRemove( nail )

								table.insert(ent.Nails, nail)

								self.Owner:TakeItem("item_nail", 1, true)

							else
								self.Owner:Tip(3, "You need nails to do this!", Color(255,255,0,255) )
							end
							
						end

					end
				end
			end
		end
		--self:beginAttack(self.SecondaryAttackImpactTime, self.SecondaryAttackDamageWindow, self.SecondaryAttackDamage, self.SecondaryAttackRange, self.SecondaryHitAABB)

		self:sendWeaponAnim("slash_secondary", self.FireAnimSpeed)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end
	
	local time = CurTime() + self.SecondaryAttackDelay
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
	self.ReloadWait = time
end

function SWEP:Reload()
	if not self:canAttack(true) then
		return
	end
	
	if IsFirstTimePredicted() then
		local tr = self.Owner:GetEyeTraceNoCursor()
		
		local dontattack = false
		local ent = tr.Entity

		if SERVER then
			if ent:GetClass() == "prop_physics" && !ent.NoNails && !ent:GetPersistent() then
				local phys = ent:GetPhysicsObject()

				if IsValid(phys) && ent.Nailed then
					phys:EnableMotion(true)
					phys:Wake()
					ent.Nailed = false

					for k, v in pairs(ent.Nails or {}) do
						if IsValid(v) then 
							v:Remove() 
							self.Owner:GiveItem("item_nail", 1, nil, 200)
						end
					end
					ent.Nails = {}

					self.Owner:EmitSound("weapons/crossbow/hit1.wav", 75, 140, 0.3)
				end

			end
		end
	end

	local time = CurTime() + 0.1
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
	self.ReloadWait = time
end