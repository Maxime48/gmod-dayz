ITEM = {}
ITEM.Name = "NPC slayer"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "50% more damage against NPCs"
ITEM.Model = "models/bowie_knife.mdl"
ITEM.Color = Color(255, 210, 0)
ITEM.Material = "models/shiny"
ITEM.Weight = 0
ITEM.Credits = 500
ITEM.SpawnChance = -1
ITEM.SpawnOffset = Vector(0,0,3.5)
ITEM.NoConsumeFromFloor = true
ITEM.ProcessFunction = function(ply, item, class) ply:GivePerk(class) end