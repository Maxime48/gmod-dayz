ITEM = {}
ITEM.Name = "Water Bottle (Dirty)"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Dirty water that came from ???\nBoil to make clean water."
ITEM.Model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Food" }
ITEM.Price = 93
ITEM.SpawnChance = 2
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.DrinkFor = 15
ITEM.HurtFor = 10
ITEM.GiveItemOnProcess = "item_water_empty"
ITEM.Rarity = 1
ITEM.FloorFunc = function(ply, item, ent) 
	if ent:GetAmount() > 1 then

		ent:SetAmount( ent:GetAmount() - 1 )
		
		local it = ents.Create( "base_item" )
		it:SetItem("item_water_empty")
		it:SetAmount( 1 )
		item:SetQuality(math.random(200, 400))
		it.Dropped = true
		item:SetRarity(1)
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