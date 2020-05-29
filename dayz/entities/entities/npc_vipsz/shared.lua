ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.Author		= "Phoenixf129"
ENT.Contact		= ""

ENT.AutomaticFrameAdvance = true
   
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.PrintName = "Trader Mike"
function ENT:SetAutomaticFrameAdvance( bUsingAnim )
 
	self.AutomaticFrameAdvance = bUsingAnim
 
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end