ITEM = {}
ITEM.Name = "Leather Shoes"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "Leather Shoes."
ITEM.Model = "models/props_junk/Shoe001a.mdl"
ITEM.Weight = 1
ITEM.Price = 200
ITEM.SpawnChance = 1
ITEM.SpawnOffset = Vector(0,0,10)
ITEM.WeightFor = 10
ITEM.EquipFunc = function(ply, item, class, rarity) ply.BatteredShoes = true ply:AddAdditionalWeight( rarity, 10) end
ITEM.DEquipFunc = function(ply, item, class, rarity) ply.BatteredShoes = false ply:AddAdditionalWeight( rarity, -10) end
ITEM.Shoes = true
ITEM.SpawnAngle = Angle(0,0,0)
ITEM.LootType = { "Industrial", "Weapon" }
ITEM.Rarity = 1
ITEM.ReqCraft = {"item_ironbar", "item_fabric", "item_fabric"}
ITEM.LevelReq = 4