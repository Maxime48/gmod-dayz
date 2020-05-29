include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH


function ENT:Draw()
	--ang.y = 1040296

	self:DrawModel()
end

function ENT:Initialize()
end

function ENT:IsTranslucent()
end

function ENT:DrawTranslucent()
    if !IsValid(self) then return end

	local ang = LocalPlayer():EyeAngles()
	local pos = self:GetPos() + Vector(0, 0, 25) + ang:Up()
    
    if LocalPlayer():GetPos():DistToSqr(pos) > (800*800) then return end

	ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Right(), 90 )

    if self:GetPLevel() >= 20 then -- 100%
    	pos = pos + Vector(0,0,20)
    end

    local rarity = 1
    if isfunction(self.GetRarity) then
        rarity = self:GetRarity()
    end

    local item = self:GetItem()
    local name = "Tree"
    if item == "item_food2" then
        name = "Plant"
    elseif item == "item_cactus" then
        name = "Plant"
    elseif item == "item_wheat" then
        name = "Plant"
    end

	cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.1 )
        local color = Color(255, 255, 255, 255)

        if GetRarity(rarity).color then
            color = GetRarity(rarity).color
        end
        draw.DrawText( GetRarity(rarity).t .. " " .. GAMEMODE.DayZ_Items[ self:GetItem() ].Name.." "..name, "char_title", 2, 22, color, TEXT_ALIGN_CENTER )
        if IsValid(self) && self:GetPLevel() < 20 then
            draw.DrawText( (self:GetPLevel() * 5).."%", "char_title1", 2, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_CENTER )
        end
    cam.End3D2D()
end

function ENT:OnRestore()
end

function ENT:Think()
end