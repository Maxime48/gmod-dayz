ITEM = {}

ITEM.Name = "Blood Bag Kit"
ITEM.Angle = Angle(0,0,2)
ITEM.Desc = "Blood bag kit. Containing sanitised blood and a syringe."
ITEM.Model = "models/props_junk/garbage_bag001a.mdl"
ITEM.Color = Color(255,0,0,255)
ITEM.Weight = 1
ITEM.LootType = { "Medical" }
ITEM.Price = 148
ITEM.BloodFor = 20
ITEM.TimeToProcess = 8 -- Takes this long to use the item
ITEM.SpawnChance = 1 -- Out of 100
ITEM.SpawnOffset = Vector(0,0,0)
ITEM.Rarity = 1
ITEM.ProcessFunction = function(ply, item, class, it) if !IsValid(ply) then return end ply:GiveItem("item_medic3empty", 1, nil, it.quality - math.random(40, 60), it.rarity or nil) end		
