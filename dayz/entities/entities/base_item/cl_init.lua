include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function ENT:Draw()
	local ItemTable = GAMEMODE.DayZ_Items[self:GetItem()]
	local act, dodraw = self.GetActivator && self:GetActivator() or nil, true
	if IsValid(act) then
		if act:GetProcessItem() == self:GetItem() then dodraw = false end -- invisibile if you're picking up, or dropping clientside.
	end

	if dodraw then
    	self:DrawModel()	
   	end
    local pos = self:LocalToWorld( self:OBBCenter() )
    local offset = self:OBBMaxs().z

   	if dodraw and GUI_ItemGlow == 1 && LocalPlayer():GetPos():DistToSqr( pos ) < (1000*1000) then
		local ang = LocalPlayer():GetAngles()
   	 	ang:RotateAroundAxis( ang:Forward(), 90 )
    	ang:RotateAroundAxis( ang:Right(), 90 )
    	local rar = GetRarity(self:GetRarity())
    	local txt = ""
    	if ItemTable.Weapon then
    		txt = "'"..rar.wep.."' "
    	end
      local color = Color(255,255,255,255)
      if rar && rar.color then
        color = rar.color
      end

   		cam.Start3D2D( pos , Angle( 0, ang.y, 90 ), 0.3 )
          draw.DrawText( txt..ItemTable.Name.." x"..self:GetAmount().." ["..math.Round(self:GetPerish() - CurTime()).."s]", "char_title24", 0, -50, color, TEXT_ALIGN_CENTER)
          draw.DrawText( "↓", "char_title24", 0, -35, color, TEXT_ALIGN_CENTER)
      cam.End3D2D()
   	end

end