ENT.Type 		= "anim"
ENT.PrintName	= ""
ENT.Author		= ""
ENT.Contact		= ""

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "StoredModel" )
	self:NetworkVar( "String", 1, "StoredName" )
	self:NetworkVar( "String", 2, "StoredReason" )
	self:NetworkVar( "Int", 0, "Perish" )
	--self:NetworkVar( "Vector", 1, "UrinePos" )

end