ITEM = {}
ITEM.Name = "Fruit Smoothie"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "More than one of your five a day!"
ITEM.Model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.Color = Color(255,200,0)
ITEM.Weight = 2
ITEM.LootType = { "Food" }
ITEM.Price = 500
ITEM.NoFire = true
ITEM.SpawnChance = 1
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.DrinkFor = 35
ITEM.EatFor = 35
ITEM.GiveItemOnProcess = "item_water_empty"
ITEM.ReqCook = { "item_water_empty", "item_food3", "item_food2", "item_food4" }
ITEM.Rarity = 1
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local item = ents.Create( "base_item" )
		item:SetItem("item_water_empty")
		item:SetAmount( 1 )
		item:SetQuality(math.random(200, 400))
		item.Dropped = true
		item:SetRarity( ent:GetRarity() )
		item:SetPos( ent:GetPos() + Vector(0,1,10) )
		item:SetAngles( ent:GetAngles() )
		item:Spawn()

		if IsValid(item:GetPhysicsObject()) then
			item:PhysWake()
		end
	else
		ent:ChangeItem("item_water_empty", 1)
	end
end
