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
	local ang = LocalPlayer():EyeAngles()
	local pos = self:GetPos() + Vector(0, 0, 86)

	ang:RotateAroundAxis( ang:Forward(), 90 )
  ang:RotateAroundAxis( ang:Right(), 90 )

  if LocalPlayer():GetPos():DistToSqr(pos) > (800*800) then return end

  local perc = (PHDayZ.ShopSellPercentage or 20)

	cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.1 )
        draw.DrawText( "Trader Nick", "char_title", 2, 22, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "[E] Open Shop ["..perc.."% sale]", "char_title1", 2, 62, Color( 127, 255, 127, 255 ), TEXT_ALIGN_CENTER )
        draw.DrawText( "↓", "char_title1", 2, 102, Color( 127, 255, 127, 255 ), TEXT_ALIGN_CENTER )
    cam.End3D2D()
end

function ENT:Initialize()
    hook.Add("PostDrawTranslucentRenderables", "draw_"..self:EntIndex(), function() -- hack of the year award goes to me!
        if !IsValid(self) then return end

        self:DrawTranslucent()
    end)
end

 
/*---------------------------------------------------------
   Name: BuildBonePositions
   Desc: 
---------------------------------------------------------*/
function ENT:BuildBonePositions( NumBones, NumPhysBones )
 
	// You can use this section to position the bones of
	// any animated model using self:SetBonePosition( BoneNum, Pos, Angle )
 
	// This will override any animation data and isn't meant as a 
	// replacement for animations. We're using this to position the limbs
	// of ragdolls.
 
end
 
 
 
/*---------------------------------------------------------
   Name: SetRagdollBones
   Desc: 
---------------------------------------------------------*/
function ENT:SetRagdollBones( bIn )
 
	// If this is set to true then the engine will call 
	// DoRagdollBone (below) for each ragdoll bone.
	// It will then automatically fill in the rest of the bones
 
	self.m_bRagdollSetup = bIn
 
end
 
 
/*---------------------------------------------------------
   Name: DoRagdollBone
   Desc: 
---------------------------------------------------------*/
function ENT:DoRagdollBone( PhysBoneNum, BoneNum )
 
	// self:SetBonePosition( BoneNum, Pos, Angle )
 
end