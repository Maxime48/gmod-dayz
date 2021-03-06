ITEM = {}
ITEM.Name = "Upgrades Table"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "A deployable upgrades table."
ITEM.Model = "models/props_c17/furnituretable002a.mdl"
ITEM.Modelscale = 0.3
ITEM.Weight = 5
ITEM.LootType = { "" }
ITEM.Price = 45
ITEM.SpawnChance = -1
ITEM.NoBlueprint = true
ITEM.OverrideUseMenu = "Deploy"
ITEM.DeployEnt = "dz_interactable"
ITEM.ReqCraft = { "item_plank", "item_plank", "item_ironbar", "item_ironbar", "item_plastic", "item_plastic" }
ITEM.SpawnOffset = Vector(0,0,3.5)
ITEM.ProcessFunction = function(ply, item, class) return ply:DeployItem(item, class) end
