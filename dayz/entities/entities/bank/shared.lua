------------------------------------
ENT.Type 			= "anim"
ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
------------------------------------

function ENT:Initialize()

	if SERVER then

		--self:SetModel("models/props/cs_militia/footlocker01_closed.mdl")
		self:SetModel("models/griim/vaultdoor.mdl")

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)

	end
	
end