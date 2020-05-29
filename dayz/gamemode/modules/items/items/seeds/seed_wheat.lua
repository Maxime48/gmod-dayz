ITEM = {}

ITEM.Name = "Seed (Wheat)"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "A seed. Plant in Dirt/Grass and wait."
ITEM.Model = "models/props_lab/box01a.mdl"
ITEM.Color = Color(255, 220, 0, 255)
ITEM.Weight = 0.1
ITEM.LootType = { "Industrial", "Food" }
ITEM.SpawnChance = 0.1 -- Out of 100
ITEM.SpawnOffset = Vector(0,0,14)
ITEM.ReqCook = { "item_wheat" }
ITEM.Modelscale = 0.4
ITEM.NoFire = true
ITEM.NoBlueprint = true
ITEM.NoConsumeFromFloor = true
ITEM.EatFunction = function(ply, item) ply:Eat(item, 1) end
ITEM.Rarity = 1
ITEM.TimeToProcess = 2
ITEM.Function = 
function(ply,item)
	DZ_MakePlant(ply, item)
end
ITEM.ProcessFunction = 
function(ply, item, class, itdata) 
	return DZ_MakePlant(ply, item, "item_wheat", itdata)
end