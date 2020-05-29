
ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName		= "Helicopter (no weapons)"
ENT.Author			= "Sakarias88"
ENT.Category 		= "Air Vehicles"
ENT.Contact    		= ""
ENT.Purpose 		= ""
ENT.Instructions 	= "" 

ENT.Spawnable			= true
ENT.AdminSpawnable		= true

function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "Fuel")
	self:NetworkVar("Bool", 0, "SafeZone")
	self:NetworkVar("Bool", 1, "SafeZoneEdge")

end