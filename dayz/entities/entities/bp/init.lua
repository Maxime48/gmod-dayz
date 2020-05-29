AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:DrawShadow( false )
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
end

function ENT:Think()
	if ( self.DoNextThink or 0 ) > CurTime() then return end

	self.DoNextThink = CurTime() + 1

	local OwnerBack = self:GetParent()
	if !IsValid(OwnerBack) then return end
	local item = self.class
	if !OwnerBack.CharTable[item] then self:Remove() return end
	if isbool(OwnerBack.CharTable[item]) then self:Remove() return end
	if table.Count(OwnerBack.CharTable[item]) < 1 then self:Remove() return end

	local amount = 0
	for _, item in pairs(OwnerBack.CharTable[item]) do
		amount = amount + item.amount
	end

	if amount < 1 then self:Remove() return end
	
	if OwnerBack.Noclip then -- admin
		self:SetNoDraw(true)
	else
		self:SetNoDraw(false)
	end
end

function ENT:OnTakeDamage(dmginfo)
end
function ENT:Detach()
end
function ENT:StartTouch(ent) 
end
function ENT:EndTouch(ent)
end
function ENT:AcceptInput(name,activator,caller)
end
function ENT:KeyValue(key,value)
end
function ENT:OnRemove()
end
function ENT:OnRestore()
end
function ENT:PhysicsCollide(data,physobj)
end
function ENT:PhysicsSimulate(phys,deltatime) 
end
function ENT:PhysicsUpdate(phys) 
end
function ENT:Touch(hitEnt) 
end
function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end
function ENT:Use(activator,caller)
end

