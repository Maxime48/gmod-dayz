ENT.Type = "Anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Fruit Seed"
ENT.Spawnable = false
ENT.AdminSpawnable = false


function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "Item" )
	self:NetworkVar( "Int", 0, "PLevel" )
	self:NetworkVar( "Int", 1, "Rarity" )
end