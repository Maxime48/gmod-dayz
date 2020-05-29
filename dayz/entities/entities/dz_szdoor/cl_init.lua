include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize2()
end

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function ENT:Draw2()
	self:DrawModel()
end

function ENT:DrawTranslucent2()
	local dist = LocalPlayer():GetPos():DistToSqr( self:GetPos() )

	local maxdist = 1024

	if dist > ( maxdist * maxdist ) then return end
	
	local pos = self:GetPos()
	local ang = self:GetAngles()

	--local ang = EyeAngles()

	local alpha = 255 - ( math.Clamp( ( dist / (maxdist*maxdist) )* 255, 0, 255 ) )
	--ang.x = 1040296

	if alpha < 1 then return end -- Optimisation. Don't bother drawing if you shouldn't see it.


 	local buttoncol = Color(255, 255, 255, alpha)

	cam.Start3D2D( pos + ang:Up() * -1.8, ang, 0.1 )
		self:Do3DDraw( alpha )	
	cam.End3D2D()
end

function ENT:Do3DDraw( alpha )


	local DoText = "ENTER [E]"

	local OwnerNick = "Portal to the Overworld"
	render.SuppressEngineLighting()

	local pos = -300

	surface.SetDrawColor( Color( 255, 255, 255, alpha) )

	surface.SetFont("SafeZone_INFO")

	draw.DrawText(DoText, "char_title64", 0, pos-20, HSVToColor( CurTime() * 60 % 360, 1, 1 ), TEXT_ALIGN_CENTER)
	draw.DrawText(OwnerNick, "SafeZone_INFO", 0, pos + 40, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)

	local txt = "Type !sz to return"
	if SafeZoneTeleportEnabled then
		draw.DrawText(txt, "SafeZone_INFO", 0, pos + 70, Color(178,178,178,alpha), TEXT_ALIGN_CENTER)
	end
end