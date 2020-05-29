include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH
 
/*---------------------------------------------------------
   Name: Draw
   Desc: Draw it!
---------------------------------------------------------*/
local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
    if !IsValid(self) then return end

	local ang = LocalPlayer():EyeAngles()
	local pos = self:GetPos() + Vector(0, 0, 90)

    if LocalPlayer():GetPos():DistToSqr(pos) > (800*800) then return end

	ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Right(), 90 )

    local perc = (PHDayZ.ShopSellPercentageVIP or 20)

	cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.1 )
        draw.DrawText( "Magic Mike", "char_title", 2, 22, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "[E] Open VIP Shop ["..perc.."% sale]", "char_title1", 2, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "Buy any pre-sold item as Uncommon! See !vip", "char_title1", 2, 102, Color( 255, 255, 0, 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "↓", "char_title1", 2, 142, Color( 127, 255, 127, 255 ), TEXT_ALIGN_CENTER )
    cam.End3D2D()
end

function ENT:Initialize()
    hook.Add("PostDrawTranslucentRenderables", "draw_"..self:EntIndex(), function() -- hack of the year award goes to me!
        if !IsValid(self) then return end

        self:DrawTranslucent()
    end)
end