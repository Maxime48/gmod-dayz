ITEM = {}
ITEM.Name = "Water Bottle (Clean)"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Boiled for cleanliness."
ITEM.Model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Food" }
ITEM.Price = 126
ITEM.SpawnChance = -1
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.DrinkFor = 25
ITEM.GiveItemOnProcess = "item_water_empty"
ITEM.Rarity = 1
ITEM.ReqCook = { "item_water_dirty" }
ITEM.NoBlueprint = true
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local it = ents.Create( "base_item" )
		it:SetItem("item_water_empty")
		it:SetAmount( 1 )
		item:SetQuality(math.random(200, 400))
		it.Dropped = true
		it:SetRarity( ent:GetRarity() )
		it:SetPos( ent:GetPos() + Vector(0,1,10) )
		it:SetAngles( ent:GetAngles() )
		it:Spawn()

		if IsValid(it:GetPhysicsObject()) then
			it:PhysWake()
		end
	else
		ent:ChangeItem("item_water_empty", 1)
	end
end