ITEM = {}

ITEM.Name = "Empty Blood Bag Kit"
ITEM.Angle = Angle(0,0,2)
ITEM.Desc = "Blood bag kit. Containing an empty blood bag and a syringe."
ITEM.Model = "models/props_junk/garbage_bag001a.mdl"
ITEM.Color = Color(127,0,0,255)
ITEM.Weight = 1
ITEM.LootType = { "Medical" }
ITEM.Price = 100
ITEM.BloodFor = -20
ITEM.SpawnChance = 25 -- Out of 100
ITEM.SpawnOffset = Vector(0,0,0)
ITEM.ReqCraft = { "item_fabric", "item_fabric", "item_plastic" }
ITEM.NoBlueprint = true
ITEM.NoConsumeFromFloor = true
ITEM.ProcessFunction = function(ply, item, class, it) if !IsValid(ply) then return end if ply:GetInArena() then return true end if it.quality < 400 then if math.random(1, 20) > 19 then ply:SetSick(true) end end ply:GiveItem("item_medic3", 1, nil, it.quality - math.random(10, 30), it.rarity or nil) end		
ITEM.Rarity = 1