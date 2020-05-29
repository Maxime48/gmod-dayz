ITEM = {}
ITEM.Name = "Empty Water Bottle"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "It's empty, shame. Refill by looking at water/snow!"
ITEM.Model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Food" }
ITEM.Price = 10
ITEM.SpawnChance = 5
ITEM.OverrideUseMenu = "Fill"
ITEM.NoConsumeFromFloor = true
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.ReqCraft = { "item_plastic", "item_plastic", "item_plastic" }
ITEM.Rarity = 1
ITEM.PreProcessFunction = 
	function(ply, item, class)
	local tr = util.TraceLine( {
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 200,
        filter = function( ent ) if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "base_item" ) then return true end end
    } )

	if !DZ_IsInWater(tr.HitPos) then ply:Tip(3, "Fill water bottles by aiming at a water source!") return false end

	return true
end
ITEM.ProcessFunction = 
	function(ply, item, class) 

		local qual, rarity = 1
		if ply.InvTable[class] && ply.InvTable[class][item] && ply.InvTable[class][item].quality then
			rarity = ply.InvTable[class][item].rarity
			qual = ply.InvTable[class][item].quality - 10
			ply.InvTable[class][item].quality = qual

			ply:UpdateItem( ply.InvTable[class][item] )
		end

		ply:GiveItem("item_water_dirty", 1, nil, qual, rarity)
		ply:Tip(3, "You filled up your water bottle!")
		ply:EmitSound("ambient/water/water_splash3.wav")
	return false
end