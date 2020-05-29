include("shared.lua")

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function ENT:Draw()
    self.Entity:DrawModel()
	self.Entity:SetColor( Color(205, 150, 0, 255) )

	local dist = LocalPlayer():GetPos():DistToSqr( self:GetPos() )
    
	if dist > ( 128 * 128 ) then return end
	
	local ang = EyeAngles()
	local class = self:GetNWString("Resources")
	
	local alpha = 255 - ( math.Clamp( ( dist / (125*125) )*255, 0, 255 ) )
	ang.x = 90

	if alpha < 1 then return end -- Optimisation. Don't bother drawing if you shouldn't see it.

 	ang:RotateAroundAxis( ang:Up(), 90 )

 	local maxs, mins, center = self:OBBMaxs(), self:OBBMins(), self:OBBCenter()
	local height = maxs - mins
 	local vec = Vector(0,0, center)

 	local buttoncol = Color(255, 255, 255, alpha)

	cam.Start3D2D( self:LocalToWorld( self:OBBCenter() ) + vec, ang - Angle(0,-180,0), 0.1 )
		render.SuppressEngineLighting()

		surface.SetDrawColor( buttoncol )
		surface.SetMaterial( ButtonMaterial )

		surface.SetFont("SafeZone_INFO")
		local textx, texty = surface.GetTextSize( class )

		surface.DrawTexturedRect( -textx/2 - 50, -5, 64, 51 )
		draw.DrawText( string.upper(input.LookupBinding("+use") or "NA"), "Cyb_HudTEXT", -textx/2-30, 5, Color(0, 0, 0, alpha),TEXT_ALIGN_LEFT)										

		draw.DrawText(class, "SafeZone_INFO", 10, 5, buttoncol,TEXT_ALIGN_CENTER)

	cam.End3D2D()
end

function ENT:Initialize()
end

function ENT:IsTranslucent()
end

function ENT:OnRestore()
end

function ENT:Think()
end