ITEM = {}
ITEM.Name = "Stone"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Can be ground into a multitude of resources."
ITEM.Model = "models/props_junk/rock001a.mdl"
ITEM.Weight = 0.1
ITEM.Price = 4	
ITEM.SpawnChance = -1
ITEM.CantDecompile = true
ITEM.SpawnOffset = Vector(0,0,4)
ITEM.NoBlueprint = true
ITEM.NoConsumeFromFloor = true
ITEM.OverrideUseMenu = "Grind"
ITEM.Function = function(ply, item) ply:DoProcess(item, "Grinding", 1, "player/footsteps/concrete1.wav", 2, "player/footsteps/chainlink2.wav") end
ITEM.ProcessFunction = 
	function(ply, item, class) 
		local tab = {"item_sand", "item_sulfur", "item_saltpeter"}

		local qual, amount = 1
		if ply.InvTable[class] && ply.InvTable[class][item] && ply.InvTable[class][item].quality then
			qual = ply.InvTable[class][item].quality
			amount = ply.InvTable[class][item].amount
		end

		ply:TakeItem(item, 1)
		ply:GiveItem(table.Random(tab), 1, nil, qual, nil, nil, nil, true )

		if amount > 1 then
			timer.Simple(1, function()
				if !IsValid(ply) then return end

				if ply:GetVelocity():Length() > 5 then return end

				GAMEMODE.DayZ_Items[class].Function(ply, item, class)
			end)
		end

		return true
	end