include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

function ENT:Initialize()
	--self:SetRenderBounds( Vector(-10000,-10000,-10000), Vector(10000,10000,10000) )
	self:DrawShadow( false )
end

function ENT:Think()
	self.Entity:DrawModel()	
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
	
	self.BoneIndex = OwnerBack:LookupBone("valvebiped.bip01_spine2");
	if self.BoneIndex then
		if OwnerBack:GetBonePosition( self.BoneIndex ) then
			self.BonePos , self.BoneAng = OwnerBack:GetBonePosition( self.BoneIndex )
		else
			return false
		end
	else
		return false
	end
			
	if self:GetModel() == "models/fallout 3/backpack_1.mdl" then
		
        local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 3 ) + (self.BoneAng:Forward() * -15)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		--self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -40)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/fallout 3/backpack_2.mdl" then
		
		self:SetModelScale(1, 0)
	
        local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 8 ) + (self.BoneAng:Forward() * -3)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/fallout 3/backpack_3.mdl" then
		
		self:SetModelScale(1, 0)
		
		local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 10 ) + (self.BoneAng:Forward() * -3)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
		
	elseif self:GetModel() == "models/fallout 3/backpack_4.mdl" then
	
		self:SetModelScale(1, 0)


        local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 10 ) + (self.BoneAng:Forward() * -3)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)

	elseif self:GetModel() == "models/fallout 3/backpack_5.mdl" then
	
		self:SetModelScale(1, 0)


        local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 10 ) + (self.BoneAng:Forward() * -3)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
	elseif self:GetModel() == "models/fallout 3/backpack_6.mdl" then
	
		self:SetModelScale(1, 0)


        local WepNewPos = self.BonePos + ( self.BoneAng:Up() * 1.5 ) + ( self.BoneAng:Right() * 10 ) + (self.BoneAng:Forward() * -3)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		self:SetPos(WepNewPos)
		self:SetAngles(self.BoneAng)
	end

	if LocalPlayer():GetThirdPerson() or OwnerBack != LocalPlayer() then
		self.Entity:DrawModel()	
	end
end

