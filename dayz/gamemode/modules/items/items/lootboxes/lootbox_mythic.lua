ITEM = {}
ITEM.Name = "Mythic Lootbox"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Can be opened with a Mythic Keypad"
ITEM.Model = "models/Items/item_item_crate.mdl"
ITEM.Weight = 1
ITEM.DontStock = true
ITEM.Price = 10000
ITEM.CantSell = true
ITEM.Modelscale = 0.5
ITEM.SpawnChance = -1
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.Rarity = 7
--ITEM.Color = GetRarity(ITEM.Rarity).color
ITEM.NoConsumeFromFloor = true
ITEM.OverrideCamPos = Vector(50, 50, 50)
ITEM.Function = 
function(ply, item)
	if DZ_CanLootbox(ply, item, ITEM.Rarity) then 
		ply:DoProcess(item, "Opening", 5, "HL1/fvox/beep.wav", 10, "physics/wood/wood_crate_break1.wav")
	end
end
ITEM.ProcessFunction = 
function(ply,item)
	return DZ_DoLootbox(ply, item, ITEM.Rarity)
end