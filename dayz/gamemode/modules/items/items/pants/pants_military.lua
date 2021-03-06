ITEM = {}
ITEM.Name = "Military Pants"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "Standard Edition Military Pants."
ITEM.Model = "models/props_junk/garbage_bag001a.mdl"
ITEM.Material = "phoenix_storms/plastic"
ITEM.Weight = 1
ITEM.WeightFor = 20
ITEM.Price = 200
ITEM.SpawnChance = 1
ITEM.SpawnOffset = Vector(0,0,10)
ITEM.EquipFunc = function(ply, item, class, rarity) ply:AddAdditionalWeight( rarity,  20 ) end
ITEM.DEquipFunc = function(ply, item, class, rarity) ply:AddAdditionalWeight( rarity,  -20 ) end
ITEM.Pants = true
ITEM.ReqCraft = {"item_fabric", "item_fabric", "item_ironbar", "item_plastic", "item_plastic"}
ITEM.SpawnAngle = Angle(0,0,0)
ITEM.LootType = { "Basic", "Industrial", "Weapon" }
ITEM.Rarity = 1
ITEM.LevelReq = 7