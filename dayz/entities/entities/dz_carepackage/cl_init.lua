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
	--ang.x = 1040296

	if alpha < 1 then return end -- Optimisation. Don't bother drawing if you shouldn't see it.

 	ang:RotateAroundAxis( ang:Up(), 90 )
 	ang:RotateAroundAxis( ang:Forward(), 90)

 	local buttoncol = Color(255, 255, 255, alpha)

 	local angd = 9.8
	if EVENT_CHRISTMAS then angd = 1 end

	cam.Start3D2D( pos + ang:Up() * angd, ang, 0.11 )
		self:Do3DDraw( alpha )	
	cam.End3D2D()


	ang:RotateAroundAxis(ang:Right(), 180)
	cam.Start3D2D( pos + ang:Up() * (angd - 1), ang, 0.11 )
		self:Do3DDraw( alpha )	
	cam.End3D2D()
end

function ENT:Do3DDraw( alpha )

	local OwnerNick = "Care Package"
	render.SuppressEngineLighting()

	local pos = -240

	surface.SetDrawColor( Color( 255, 255, 255, alpha) )
	surface.SetMaterial( ButtonMaterial )

	surface.SetFont("SafeZone_INFO")
	local textx, texty = surface.GetTextSize( "Here lies the mighty" )

	surface.DrawTexturedRect( -textx/2, pos + 105, 64, 51 )
	draw.DrawText( string.upper(input.LookupBinding("+use") or "NA"), "Cyb_HudTEXT", -textx/2+20, pos + 115, Color(0, 0, 0, alpha),TEXT_ALIGN_LEFT)										

	draw.DrawText("- Here lies the mighty -", "SafeZone_INFO", 0, pos + 5, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
	draw.DrawText(OwnerNick, "SafeZone_INFO", 0, pos + 40, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
	draw.DrawText("to steal it's shit", "SafeZone_INFO", 30, pos + 110, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
end