local function ZombiePModel()
    local zombie = net.ReadEntity()
    local zmodel = net.ReadString()
    zombie.mdl = ClientsideModel(zmodel)
    zombie.mdl:SetPos(zombie:GetPos())
    zombie.mdl:SetParent(zombie)
    zombie.mdl:AddEffects(EF_BONEMERGE)
end

net.Receive("ZombiePModel", ZombiePModel)

local function RZombiePModel()
    local zombie = net.ReadEntity()

    if IsValid(zombie.mdl) then
        zombie.mdl:Remove()
    end
end

net.Receive("RZombiePModel", RZombiePModel)

local view = {
    origin = Vector(0, 0, 0),
    angles = Angle(0, 0, 0),
    fov = 90,
    znear = 1
}

hook.Add("CalcView", "deathPOV", function(ply, origin, angles, fov)
    -- Entity:Alive() is being slow as hell, we might actually see ourselves from third person for frame or two
    if not PHDayZ.Player_FirstPersonDeath or ply:Health() > 0 then return end
    local Ragdoll = ply:GetRagdollEntity()
    if not IsValid(Ragdoll) then return end
    local head = Ragdoll:LookupAttachment("eyes")
    head = Ragdoll:GetAttachment(head)
    if not head or not head.Pos then return end

    if not Ragdoll.BonesRattled then
        Ragdoll.BonesRattled = true
        Ragdoll:InvalidateBoneCache()
        Ragdoll:SetupBones()
        local matrix

        for bone = 0, (Ragdoll:GetBoneCount() or 1) do
            if Ragdoll:GetBoneName(bone):lower():find("head") then
                matrix = Ragdoll:GetBoneMatrix(bone)
                break
            end
        end

        if IsValid(matrix) then
            matrix:SetScale(Vector(0, 0, 0))
        end
    end

    view.origin = head.Pos + head.Ang:Up() * 8
    view.angles = head.Ang

    return view
end)