include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function ENT:Draw()
    if ( self:GetRenderOrigin() == Vector(0, 0, 0) ) or ( self:GetPos() == Vector(0, 0, 0) ) then return end
    self:DrawModel()

    local dist = LocalPlayer():GetPos():DistToSqr( self:GetPos() )
    
    local text = self:GetStoredName().."'s Backpack"

	if dist > ( 128 * 128 ) then return end
	
	local ang = EyeAngles()
	
	local alpha = 255 - ( math.Clamp( ( dist / (125*125) )*255, 0, 255 ) )
	ang.x = 90

	if alpha < 1 then return end -- Optimisation. Don't bother drawing if you shouldn't see it.

 	ang:RotateAroundAxis( ang:Up(), 90 )

 	local maxs, mins = self:OBBMaxs(), self:OBBMins()
	local height = maxs - mins
 	local vec = Vector(0,0, height[3] + 5)

 	local buttoncol = Color(255, 255, 255, alpha)

	cam.Start3D2D( self:LocalToWorld( self:OBBCenter() ) + vec, ang - Angle(0,-180,0), 0.1 )
		render.SuppressEngineLighting()

		surface.SetDrawColor( buttoncol )
		surface.SetMaterial( ButtonMaterial )

		surface.SetFont("SafeZone_INFO")
		local textx, texty = surface.GetTextSize( text )
		local perish = "Perishes in "..math.Round( self:GetPerish() + 1 - CurTime() ).." seconds"

		surface.DrawTexturedRect( -textx/2 - 50, -5, 64, 51 )
		draw.DrawText( string.upper(input.LookupBinding("+use") or "NA"), "Cyb_HudTEXT", -textx/2-30, 5, Color(0, 0, 0, alpha),TEXT_ALIGN_LEFT)										

		draw.DrawText(text, "SafeZone_INFO", 10, 5, buttoncol,TEXT_ALIGN_CENTER)

		if self.GetPerish and self:GetPerish() then
			draw.DrawText(perish, "Cyb_Inv_Bar", -textx/2 + 10, -5, Color(200, 200, 0, alpha), TEXT_ALIGN_LEFT)
		end

	cam.End3D2D()
	
end
