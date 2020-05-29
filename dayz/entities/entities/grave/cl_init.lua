include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
--ENT.RenderGroup 		= RENDERGROUP_OPAQUE

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function ENT:Draw()
	self:DrawModel()

	local dist = LocalPlayer():GetPos():DistToSqr( self:GetPos() )

	if dist > ( 512 * 512 ) then return end
	
	local pos = self:GetPos()
	local ang = self:GetAngles()

	--local ang = EyeAngles()

	local alpha = 255 - ( math.Clamp( ( dist / (510*510) )*255, 0, 255 ) )
	--ang.x = 90

	if alpha < 1 then return end -- Optimisation. Don't bother drawing if you shouldn't see it.

 	ang:RotateAroundAxis( ang:Up(), 90 )
 	ang:RotateAroundAxis( ang:Forward(), 90)

 	local buttoncol = Color(255, 255, 255, alpha)

	cam.Start3D2D( pos + ang:Up() * 4.8, ang, 0.11 )
		self:Do3DDraw( alpha )	
	cam.End3D2D()

	cam.Start3D2D( pos + ang:Up() * 10.2, ang, 0.11 )
		self:Do3DDraw2( alpha )	
	cam.End3D2D()

	ang:RotateAroundAxis(ang:Right(), 180)
	cam.Start3D2D( pos + ang:Up() * 4.8, ang, 0.11 )
		self:Do3DDraw( alpha )	
	cam.End3D2D()

	cam.Start3D2D( pos + ang:Up() * 10.2, ang, 0.11 )
		self:Do3DDraw2( alpha )	
	cam.End3D2D()

end

function ENT:Do3DDraw2( alpha )
	surface.SetDrawColor( Color( 255, 255, 255, alpha ) )
	surface.SetMaterial( ButtonMaterial )

	surface.DrawTexturedRect( -145, 95, 64, 51 )
	draw.DrawText( "F", "Cyb_HudTEXT", -126, 105, Color(0, 0, 0, alpha),TEXT_ALIGN_LEFT)		
	draw.DrawText("to pay your respects (:", "SafeZone_INFO", 30, 100, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
end

function ENT:Do3DDraw( alpha )

	local OwnerNick = self:GetStoredName() or "Unknown"
	local DeathMsg = self:GetStoredReason() or "Unknown Reason for Death"
	render.SuppressEngineLighting()

	local pos = -120

	surface.SetDrawColor( Color( 255, 255, 255, alpha) )
	surface.SetMaterial( ButtonMaterial )

	surface.SetFont("SafeZone_INFO")
	local textx, texty = surface.GetTextSize( "Here lies the mighty" )
	local perish = "Perishes in "..math.Round( self:GetPerish() + 1 - CurTime() ).." seconds"

	surface.DrawTexturedRect( -textx/2, pos + 105, 64, 51 )
	draw.DrawText( string.upper(input.LookupBinding("+use") or "NA"), "Cyb_HudTEXT", -textx/2+20, pos + 115, Color(0, 0, 0, alpha),TEXT_ALIGN_LEFT)										

	draw.DrawText("- Here lies the mighty -", "SafeZone_INFO", 0, pos + 5, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
	draw.DrawText(OwnerNick, "SafeZone_INFO", 0, pos + 40, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
	draw.DrawText(DeathMsg, "SafeZone_INFO", 0, pos + 75, Color(255,178,178,alpha), TEXT_ALIGN_CENTER) 
	draw.DrawText("to steal his shit", "SafeZone_INFO", 30, pos + 110, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)

	if self.GetPerish and self:GetPerish() then
		draw.DrawText(perish, "Cyb_Inv_Bar", 0, 40, Color(200, 200, 0, alpha), TEXT_ALIGN_CENTER)
	end
end