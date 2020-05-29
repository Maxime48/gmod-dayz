AddCSLuaFile()

if CLIENT then
	SWEP.DrawCrosshair = false
	SWEP.PrintName = "Iron Pickaxe"
	SWEP.CSMuzzleFlashes = true
	
	SWEP.DisableSprintViewSimulation = true
	
	SWEP.DrawTraditionalWorldModel = true
	SWEP.WM = "models/weapons/w_gms_pickaxe.mdl"
	SWEP.WMPos = Vector(0.25, -1, 1.25)
	SWEP.WMAng = Vector(-10, 90, 180)
	
	SWEP.IconLetter = "j"
	killicon.AddFont("cw_iron_pickaxe", "CW_KillIcons", SWEP.IconLetter, Color(255, 80, 0, 150))
end

SWEP.Skin = 2

SWEP.NormalHoldType = "melee"
SWEP.RunHoldType = "melee"

SWEP.Animations = {
	slash_primary = "hitcenter1",
	slash_secondary = "hitcenter2",
	draw = "draw"
}

SWEP.Sounds = {
	hitcenter1 = {{time = 0.05, sound = "CW_CROWBAR_ATTACK"}},
	hitcenter3 = {{time = 0.05, sound = "CW_CROWBAR_ATTACK"}},
	hitcenter2 = {{time = 0.1, sound = "CW_CROWBAR_ATTACK"}},
	draw = {{time = 0.1, sound = "CW_KNIFE_DRAW"}},
}

SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.Base = "cw_melee_base"
SWEP.Category = "CW 2.0"

SWEP.Author			= "Phoenixf129"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
SWEP.ViewModel = "models/weapons/c_gms_pickaxe.mdl"
SWEP.WorldModel = "models/weapons/w_gms_pickaxe.mdl"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.Primary.ClipSize		= 0
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ""

SWEP.PrimaryAttackDelay = 1.5
SWEP.SecondaryAttackDelay = 1.75

SWEP.PrimaryAttackDamage = {20, 25}
SWEP.SecondaryAttackDamage = {20, 25}

SWEP.PrimaryAttackRange = 80

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