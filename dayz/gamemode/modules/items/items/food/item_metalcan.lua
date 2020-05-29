ITEM = {}
ITEM.Name = "Can of beans"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Eat this to restore hunger."
ITEM.Model = "models/props_junk/garbage_metalcan001a.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Food" }
ITEM.Price = 101
ITEM.SpawnChance = 55
ITEM.EatFor = 10
ITEM.SpawnOffset = Vector(0,0,3.5)
ITEM.GiveItemOnProcess = "item_emptycan"
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local item = ents.Create( "base_item" )
		item:SetItem("item_emptycan")
		item:SetAmount( 1 )
		item.Dropped = true
		item:SetRarity(1)
		item:SetPos( ent:GetPos() + Vector(0,1,10) )
		item:SetAngles( ent:GetAngles() )
		item:Spawn()

		if IsValid(item:GetPhysicsObject()) then
			item:PhysWake()
		end
	else
		ent:ChangeItem("item_emptycan", 1)
	end

end
