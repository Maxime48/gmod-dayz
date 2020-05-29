include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

function ENT:Initialize()
	--self:SetRenderBounds( Vector(-10000,-10000,-10000), Vector(10000,10000,10000) )
	self.ItemTable = GAMEMODE.DayZ_Items[self:GetItem()]
	self:DrawShadow( false )
end

function ENT:Think()
	self:DrawModel()	
end

function ENT:Draw()
	if !IsValid(LocalPlayer()) then return false end
	local OwnerBack = self:GetParent()
	if !IsValid(OwnerBack) then return false end

	if OwnerBack.SpawnEffect then return false end

	if !self.ItemTable then return false end -- draw before init

	local mode = 0
	if OwnerBack:IsPlayer() then mode = 1 end
	if OwnerBack:GetClass() == "prop_ragdoll" then mode = 2 end
	if mode == 1 then 
		if OwnerBack:GetMoveType() != MOVETYPE_WALK then mode = 0 end 
		if !OwnerBack:Alive() then mode = 0 end
	end

	if mode == 0 then return false end

	local bone = self.ItemTable.AttachBone or "ValveBiped.bip01_spine2"
	local ang = 4
	local up = -10
	local fwd = 4
	local boneang = Angle(0,0,0)

	fwd = fwd + ( self.ItemTable.AttachPosFwd or 0 )
	up = up + ( self.ItemTable.AttachPosUp or 0 )
	ang = ang + ( self.ItemTable.AttachPosAng or 0 )

	self.setcol = self.setcol or self:GetColor()

	if self.ItemTable.BodyArmor then
		self:SetModel("models/minic23/csgo/dz_kevlar.mdl")
		self:SetColor(self.setcol)

		local scale = Vector( 1.01, 1.01, 1.01 )

		local mat = Matrix()
		mat:Scale( scale )
		self:EnableMatrix( "RenderMultiply", mat )
		
		ang = 0
		up = -49
		fwd = 3

	end

	if self.ItemTable.Secondary then
		bone = "ValveBiped.Bip01_R_Thigh"
		ang = 4
		up = -4
		fwd = 8
	end

	if self.ItemTable.Melee then
		ang = 4
		up = 4
		fwd = 2

		if self.ItemTable.ID == "item_yamato" then
			ang = -2
			up = -6
			fwd = -4
		end

		if self.ItemTable.ID == "item_knife" then
			ang = 2
			up = -4
			fwd = 2
			bone = "ValveBiped.Bip01_L_Thigh"
		end

		if self.ItemTable.ID == "item_bowie" then
			ang = 2
			up = -8
			fwd = 4
		end

	end

	self.BoneIndex = OwnerBack:LookupBone(bone);
	if self.BoneIndex then
		if OwnerBack:GetBonePosition( self.BoneIndex ) then
			self.BonePos , self.BoneAng = OwnerBack:GetBonePosition( self.BoneIndex )
		else
			return false
		end
	else
		return false
	end

	if self.ItemTable.BodyArmor then
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), 90)
	end

	if self.ItemTable.Secondary then
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), 90)
		self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), 90)
	end

	if self.ItemTable.Melee then
		if self.ItemTable.ID == "item_yamato" then
			self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
			self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -35)
		end

		if self.ItemTable.ID == "item_knife" then
			self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -90)
			self.BoneAng:RotateAroundAxis(self.BoneAng:Right(), -90)
			self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		end

		if self.ItemTable.ID == "item_bowie" then
			self.BoneAng:RotateAroundAxis(self.BoneAng:Forward(), -90)
			self.BoneAng:RotateAroundAxis(self.BoneAng:Up(), -90)
		end
	end

	local WepPos = self.BonePos;
	local WepAng = self.BoneAng + boneang;
	local WepNewPos = WepPos + (WepAng:Forward() * fwd) + (WepAng:Right() * ang) + (WepAng:Up() * up);
	self:SetPos(WepNewPos)
	self:SetAngles(WepAng)
	
	if LocalPlayer():GetThirdPerson() or OwnerBack != LocalPlayer() then
		if mode == 1 then
			if IsValid(OwnerBack:GetActiveWeapon()) and OwnerBack:GetActiveWeapon():GetClass() != self.ItemTable.Weapon then
				self:DrawModel()	
			end
		else
			self:DrawModel()
		end
	end
end

