ITEM = {}
ITEM.Name = "Bread Ration"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "A slice of bread in a tin. Genius!"
ITEM.Model = "models/weapons/c_items/c_bread_ration.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Food" }
ITEM.Price = 25
ITEM.SpawnChance = 10
ITEM.SpawnOffset = Vector(0,0,6)
ITEM.ReqCook = { "item_emptycan", "item_breadslice" }
ITEM.TimeToProcess = 2
ITEM.NoFire = true
ITEM.EatFor = 16
ITEM.ProcessFunction = function(ply, item) ply:GiveItem("item_emptycan", 1) end
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local item = ents.Create( "base_item" )
		item:SetItem("item_emptycan")
		item:SetAmount( 1 )
		item:SetRarity(1)
		item.Dropped = true
		item:SetPos( ent:GetPos() + Vector(0,1,10) )
		item:SetAngles( ent:GetAngles() )
		item:Spawn()

		if IsValid(item:GetPhysicsObject()) then
			item:PhysWake()
		end
	else
		ent:ChangeItem("item_emptycan", 1)
	end
	ply:TakeItem("item_emptycan", 1)
end
ITEM.Rarity = 1