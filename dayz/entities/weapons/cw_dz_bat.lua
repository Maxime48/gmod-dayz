AddCSLuaFile()
AddCSLuaFile("sh_sounds.lua")
include("sh_sounds.lua")

if CLIENT then
	SWEP.DrawCrosshair = false
	SWEP.PrintName = "Baseball Bat"
	SWEP.CSMuzzleFlashes = true
	
	SWEP.DisableSprintViewSimulation = true
	
	SWEP.DrawTraditionalWorldModel = true
	SWEP.WM = "models/weapons/w_basebt2.mdl"

	SWEP.IconLetter = "j"
	killicon.Add("cw_ws_pamachete", "vgui/kills/cw_ws_pamachete", Color(255, 80, 0, 150))
	SWEP.SelectIcon = surface.GetTextureID("vgui/kills/cw_ws_pamachete")
end

SWEP.Animations = {
	slash_primary = "hitcenter1",
	slash_secondary = "hitcenter2",
	draw = "draw"
}

SWEP.Sounds = {
	hitcenter1 = {{time = 0.05, sound = "CW_CROWBAR_ATTACK"}},
	hitcenter3 = {{time = 0.05, sound = "CW_KNIFE_SLASH"}},
	hitcenter2 = {{time = 0.1, sound = "CW_CROWBAR_ATTACK"}},
	draw = {{time = 0.1, sound = "CW_KNIFE_DRAW"}},
}
SWEP.PlayerHitSounds = {"CW_CROWBAR_HIT"}
SWEP.MiscHitSounds = {"CW_CROWBAR_HITWALL"}

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
SWEP.ViewModel = "models/weapons/v_basebt2.mdl"
SWEP.WorldModel = "models/weapons/w_basebt2.mdl"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.Primary.ClipSize		= 0
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ""

SWEP.PrimaryAttackDelay = 0.95
SWEP.SecondaryAttackDelay = 1.10

SWEP.PrimaryAttackDamage = {10, 30}
SWEP.SecondaryAttackDamage = {20, 40}
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
	//Vector(-10, -5, -5),
	//Vector(10, 5, 5)
	Vector(-25, -20, -20),
	Vector(25, 20, 20)
}