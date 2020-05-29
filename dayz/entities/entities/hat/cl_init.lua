include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

-- {{ userid || 76561198039418021 }}
function ENT:Initialize()
	--self:SetRenderBounds( Vector(-10000,-10000,-10000), Vector(10000,10000,10000) )
	self:DrawShadow( false )
end

function ENT:Think()
end

function ENT:Draw()
	if !IsValid(LocalPlayer()) then return false end
	local OwnerBack = self:GetParent()
	if !IsValid(OwnerBack) then return false end

	if OwnerBack.SpawnEffect then return false end

	local mode = 0
	if OwnerBack:IsPlayer() then mode = 1 end
	if OwnerBack:GetClass() == "prop_ragdoll" then mode = 2 end
	if mode == 1 then 
		if OwnerBack:GetMoveType() != MOVETYPE_WALK then mode = 0 end 
		if !OwnerBack:Alive() then mode = 0 end
	end

	if mode == 0 then return false end
	
	self.BoneIndex = OwnerBack:LookupBone("ValveBiped.Bip01_Head1");
	if self.BoneIndex then
		if OwnerBack:GetBonePosition( self.BoneIndex ) then
			self.BonePos , self.BoneAng = OwnerBack:GetBonePosition( self.BoneIndex )
		else
			return false
		end
	else
		return false
	end
			
	if self:GetModel() == "models/props_interiors/pot02a.mdl" then
		
        local WepNewPos = self.BonePos + (self.BoneAng:Forward() * 7) + self.BoneAng:Right() * -3 + self.BoneAng:Up() * 4
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), 90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 135)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/player/items/humans/top_hat.mdl" then
		
		self:SetModelScale(0.9, 0)
	
        local WepNewPos = self.BonePos +((self.BoneAng:Forward() * 1.5) + (self.BoneAng:Right() * 1) + self.BoneAng:Up() * -0.1)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/props_junk/metalbucket01a.mdl" then
		
		self:SetModelScale(0.6, 0)
		
		local WepNewPos = self.BonePos +((self.BoneAng:Forward() * 9) + (self.BoneAng:Right() * 0.9))
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), 90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/props_c17/metalpot001a.mdl" then
	
		self:SetModelScale(0.6, 0)
	
        local WepNewPos = self.BonePos +((self.BoneAng:Forward() *8.5) + (self.BoneAng:Right() * 1))
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), 90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif string.lower(self:GetModel()) == "models/props_junk/trafficcone001a.mdl" then
		
		self:SetModelScale(0.5, 0)
		
		local WepNewPos = self.BonePos +((self.BoneAng:Forward() *14.4) + (self.BoneAng:Right() * 1))
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), 270)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 270)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)	
						
	elseif string.lower(self:GetModel()) == "models/cloud/kn_santahat.mdl" then

		self:SetModelScale(1, 0)

		local WepNewPos = self.BonePos + ( (self.BoneAng:Forward() * 1.5) + (self.BoneAng:Right() * -1.5) )
		self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -90)

		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -20)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 270)

		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)

	elseif string.find( string.lower(self:GetModel()), "models/cloud/kn_paperhat_") then

		self:SetModelScale(1, 0)

		local WepNewPos = self.BonePos + ( (self.BoneAng:Forward() * 2.5) + (self.BoneAng:Right() * -1.5) )
		self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -90)

		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -20)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 270)

		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
	end
				
	if LocalPlayer():GetThirdPerson() or OwnerBack != LocalPlayer() then
		self:DrawModel()	
	end
end

