-- SERVER invisible entity parented to the Nextbot which acts as the detection range
-- When the Nextbot is created, create that zone entity, call :SetSize(i) and parent it to the Nextbot and then reference the list of potential targets from there
-- Credits to shendow for this optimisation.
if CLIENT then return end

ENT.Type = "anim"

function ENT:Initialize()
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid(SOLID_BBOX)
	
	local vec = Vector(800, 800, 800)
	self:SetNotSolid(true)
	self:SetTrigger(true)
	self:SetCollisionBounds(vec * -1, vec)

	self:SetNotSolid(true)
	self:DrawShadow(false)

	self.parent = self:GetParent()

	self.foundEnts = self.foundEnts or {}
end

function ENT:Think()
	local min, max = self:GetCollisionBounds()
	debugoverlay.Box(self:GetPos(), min, max, 0.5, color_white)

	if !IsValid(self.parent) then self:Remove() return end
end

function ENT:doSetSize(a)
	MsgAll("setting size "..a)
end

function ENT:StartTouch(ent)
	if (!IsValid(ent)) then return end
	if !self.parent:Alive() then return end

	if ent:GetClass() == "base_item" or ent:GetClass() == "backpack" or ent:GetClass() == "grave" then 
		--MsgAll(self.parent:Nick().." touched "..item)
		ent:SetPreventTransmit(self.parent, false)

		self.foundEnts = self.foundEnts or {}
		self.foundEnts[ent] = ent 
	end

end

function ENT:EndTouch(ent)
	if (!IsValid(ent)) then return end
	if !IsValid(self.parent) then return end

	if ent:GetClass() == "base_item" or ent:GetClass() == "backpack" or ent:GetClass() == "grave" then 
		self.foundEnts = self.foundEnts or {}
		self.foundEnts[ent] = nil
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
