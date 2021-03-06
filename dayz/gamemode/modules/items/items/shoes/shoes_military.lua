ITEM = {}
ITEM.Name = "Military Boots"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "Standard Edition Military Boots."
ITEM.Model = "models/props_junk/Shoe001a.mdl"
ITEM.Weight = 2
ITEM.Price = 200
ITEM.SpawnChance = 1
ITEM.SpawnOffset = Vector(0,0,10)
ITEM.WeightFor = 15
ITEM.EquipFunc = function(ply, item, class, rarity) ply:AddAdditionalWeight( rarity, 15) end
ITEM.DEquipFunc = function(ply, item, class, rarity) ply:AddAdditionalWeight( rarity, -15) end
ITEM.Shoes = true
ITEM.SpawnAngle = Angle(0,0,0)
ITEM.LootType = { "Industrial", "Weapon" }
ITEM.Rarity = 1
ITEM.ReqCraft = {"item_ironbar", "item_ironbar", "item_fabric", "item_fabric"}
ITEM.LevelReq = 7