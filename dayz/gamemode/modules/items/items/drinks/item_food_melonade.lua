ITEM = {}

ITEM.Name = "Melonade"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "More than one of your five a day!"
ITEM.Model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.Color = Color( 0, 255, 0 )
ITEM.Weight = 2
ITEM.LootType = { "Food" }
ITEM.Price = 50
ITEM.NoFire = true
ITEM.SpawnChance = 2
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.DrinkFor = 25
ITEM.EatFor = 25
ITEM.GiveItemOnProcess = "item_water_empty"
ITEM.ReqCook = { "item_water_empty", "item_food2", "item_food2" }
ITEM.Rarity = 1
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local item = ents.Create( "base_item" )
		item:SetItem("item_water_empty")
		item:SetQuality(math.random(200, 400))
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
		ent:ChangeItem("item_water_empty", 1)
	end
end
