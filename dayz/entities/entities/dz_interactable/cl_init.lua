include('shared.lua')
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw()
    self:DrawModel()    
end

function ENT:Think()

    if self:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then
        if ( self.t2 or 0 ) <= CurTime() then
            self.t2 = CurTime() + math.random(0.2,0.5)
            local dlight = DynamicLight( self:EntIndex() )
            if ( dlight ) then
                dlight.pos = self:LocalToWorld(Vector(math.random(-5,5), math.random(-5,5), 40))
                dlight.r = 255
                dlight.g = math.random(155,200)
                dlight.b = 0
                dlight.brightness = 1
                dlight.Decay = 0
                dlight.Size = 256 * 3
                dlight.DieTime = self.t2
            end
        end
    end
    
end


function ENT:DrawTranslucent()
    local ang = LocalPlayer():GetAngles()
    local apos = self:LocalToWorld( self:OBBCenter() )
    local pos = apos + Vector(0, 0, 40)

    ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Right(), 90 )

    if LocalPlayer():GetPos():DistToSqr(pos) > (500*500) then return end

    if self:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then

        cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.2 )
            draw.DrawText( "Fire [AutoLit]", "char_title", 80, 22, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT )
            draw.DrawText( "[E] Open Crafting Menu", "char_title1", 80, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_LEFT )
        cam.End3D2D()

    elseif self:GetModel() == "models/combine_helicopter/helicopter_bomb01.mdl" then
        
        pos = pos + Vector(0,0,0)
        cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.2 )
            draw.DrawText( "Safezone Teleporter", "char_title", 80, 22, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT )
            draw.DrawText( "[E] Teleport to Safezone...", "char_title1", 80, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_LEFT )
        cam.End3D2D()

    elseif self:GetModel() == "models/props_junk/trafficcone001a.mdl" then

        pos = pos + Vector(0,0,-30)
        cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.2 )
            draw.DrawText( "Practice Teleporter", "char_title", 80, 22, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT )
            draw.DrawText( "[E] Teleport to Arena...", "char_title1", 80, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_LEFT )
        cam.End3D2D()

    else

        pos = pos + Vector(0,0,20)
        cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.2 )
            draw.DrawText( "Upgrades Bench", "char_title", 80, 22, Color( 255, 0, 0, 255 ), TEXT_ALIGN_LEFT )
            draw.DrawText( "[E] Item Rarities & More...", "char_title1", 80, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_LEFT )
        cam.End3D2D()

    end
end

function ENT:Initialize()
    hook.Add("PostDrawTranslucentRenderables", "draw_"..self:EntIndex(), function() -- hack of the year award goes to me!
        if !IsValid(self) then return end

        self:DrawTranslucent()
    end)
end