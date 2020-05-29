ITEM = {}
ITEM.Name = "Cook Book"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "...give your meat a good ol' rub.\nReading this will grant some cooking recipes."
ITEM.Model = "models/dayz/misc/dayz_bookdiy.mdl"
ITEM.Skin = 1
ITEM.Weight = 1
ITEM.LootType = { "Basic" }
ITEM.Price = 1500
ITEM.SpawnChance = 5
ITEM.OverrideUseMenu = "Read Book"
ITEM.CanIgnite = true
ITEM.ViewAngle = Angle(0,-90,0)
ITEM.SpawnOffset = Vector(0,0,3)
ITEM.NoConsumeFromFloor = true
ITEM.Rarity = 1
ITEM.ProcessFunction = function(ply, item)
	--ply:DoCustomProcess(item, "Reading", 5, "", 100, "", true, function(ply, item)

		local max = 5
		if ply:HasPerk("perk_quicklearner") then
			local rand = math.random(5, 10)
			max = rand
		end

		local bptab = table.Copy(GAMEMODE.DayZ_Items)
		local cats = { "food", "drinks", "seeds" }
		for k, v in pairs( bptab ) do
			if v.Category and !table.HasValue(cats, string.lower(v.Category) ) then bptab[k] = nil continue end
			if ply.BPTable[k] then bptab[k] = nil continue end
			if !v.ReqCook or v.CantCook or v.NoBlueprint then bptab[k] = nil continue end
		end
		
		local noblueprints = true
		for i=1, max do

			local blueprint = table.Random( bptab )
			if blueprint then
				noblueprints = false
				ply:GiveBluePrint( blueprint.ID, false, true )
			end
		end	

		if noblueprints then
			ply:PrintMessage(HUD_PRINTTALK, "Cook Books have no more knowledge for you.")
		end

		--ply:TakeItem(item, 1)
	--end)
	return false -- to prevent default functionality.
end
