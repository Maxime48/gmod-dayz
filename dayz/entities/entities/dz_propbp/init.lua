AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--Called when an entity is no longer touching this SENT.
--Return: Nothing
function ENT:EndTouch(entEntity)
end

--Called when the SENT is spawned
--Return: Nothing
function ENT:Initialize()
	self:DropToFloor( )
	self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )

 	self:SetMaterial("models/wireframe")
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

 	self.LastUsed = CurTime()

    self.Costs = self.Costs or {}

    if IsValid(self.Owner.PropBluePrint) then 
        self.Owner.PropBluePrint:Remove()
    end
    self.Owner.PropBluePrint = self

    self:CPPISetOwner(self.Owner)

end

function ENT:AddItem(ply, item, amount)
    self.Costs[item] = self.Costs[item] - amount
    if self.Costs[item] <= 0 then
        self.Costs[item] = nil
    end
	
    local str = ""
    for item, amount in pairs(self.Costs) do
        str = str.." "..GAMEMODE.DayZ_Items[item].Name.." ("..amount.."x)"
    end
    self:SetNetworkedString('Resources', str)   
end

function ENT:Setup(model, itemclass)
    self:SetModel(model)
    self.ResultClass = itemclass

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetColor( Color(255,255,255,255) )

 	local phys = self:GetPhysicsObject()
 	if phys != NULL and phys then 
		phys:EnableMotion(false) 
	end
end

function ENT:Finish()
    local ent = ents.Create(self.ResultClass)	 
	if self.NormalProp == true then
		ent.NormalProp = true
	end
    ent:SetPos(self:GetPos())
    ent:SetAngles(self:GetAngles())
    ent:SetModel(self:GetModel())

    ent:Spawn()

    ent:CPPISetOwner(self.Owner)

    undo.Create( "prop" )
       undo.AddEntity( ent )
       undo.SetPlayer( self.Owner )
    undo.Finish()

    local min, max = ent:OBBMins(), ent:OBBMaxs()
    local vol = math.abs(max.x-min.x) * math.abs(max.y-min.y) * math.abs(max.z-min.z)
    vol = vol/(24^3)

    if vol < 1 then vol = 1 end

    vol = math.Round(vol)
    
    ent:SetHealth((vol*10) * PHDayZ.PropHealthMultiplier)
    ent:SetMaxHealth((vol*10) * PHDayZ.PropHealthMultiplier)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
 
    self.Owner.HasBuildingSite = false
	self:Remove( )
end

function ENT:AddCost( item, amount )
    self.Costs = self.Costs or {}

    self.Costs[item] = amount

    local str = ""
    for item, amount in pairs(self.Costs) do
        str = str.." "..GAMEMODE.DayZ_Items[item].Name.." ("..amount.."x)"
    end
    self:SetNetworkedString('Resources', str)   
end

function ENT:Use(ply)
    if CurTime() - self.LastUsed < 0.5 then return end
	self.LastUsed = CurTime()

    for k,v in pairs(self.Costs) do
        local amount = ply:GetItemAmount(k, nil, true)
        if amount >= 0 then
            if amount < v then
                self:AddItem( ply, k, amount )
                ply:TakeItem( k, amount, true )
            else
                self:AddItem( ply, k, v )
                ply:TakeItem( k, v, true )
            end
        end
    end
    if table.Count(self.Costs) > 0 then
        local str = ""
        for item, amount in pairs(self.Costs) do
            str = str.." "..GAMEMODE.DayZ_Items[item].Name.." ("..amount.."x)"
        end
        --ply:TipParams(3, "youneed", Color(255,255,255,255), str)
    else
		self:Finish()            
    end
end

function ENT:AcceptInput(input, ply)
end

function ENT:KeyValue(k,v)
end

function ENT:OnRestore()
end

function ENT:OnTakeDamage(dmginfo)
end

function ENT:PhysicsSimulate(phys, num)
end

function ENT:StartTouch(ent)
end

function ENT:Think()
end

function ENT:Touch(ent)
end

function ENT:UpdateTransmitState(ent)
end