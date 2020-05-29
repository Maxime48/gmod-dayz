ITEM = {}
ITEM.Name = "DIY Book"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "The hardback version of the P-A DIY handbook.\nReading this will grant some crafting blueprints."
ITEM.Model = "models/dayz/misc/dayz_bookdiy.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Basic" }
ITEM.Price = 2500
ITEM.CanIgnite = true
ITEM.OverrideUseMenu = "Read Book"
ITEM.SpawnChance = 5
ITEM.ViewAngle = Angle(0,90,0)
ITEM.SpawnOffset = Vector(0,0,3)
ITEM.NoConsumeFromFloor = true
ITEM.Rarity = 1
ITEM.ProcessFunction = function(ply, item)
	--ply:DoCustomProcess(item, "Reading", 5, "", 100, "", true, function(ply, item)

		local max = 2
		if ply:HasPerk("perk_quicklearner") then
			local rand = math.random(2, 5)
			max = rand
		end

		local bptab = table.Copy(GAMEMODE.DayZ_Items)
		for k, v in pairs( bptab ) do
			if ply.BPTable[k] then bptab[k] = nil end
		end

		local bptab = table.Copy(GAMEMODE.DayZ_Items)
		for k, v in pairs( bptab ) do
			if ply.BPTable[k] then bptab[k] = nil continue end
			if !v.ReqCraft or v.CantCraft or v.NoBlueprint then bptab[k] = nil continue end
		end

		local noblueprints = true
		for i=1, max do

			local blueprint = table.Random( bptab )

			if blueprint then -- 1 in 10 chance of learning nothing!! MUHAAHAH
				noblueprints = false
				ply:GiveBluePrint( blueprint.ID, false, true )	
			end

		end

		if noblueprints then
			ply:PrintMessage(HUD_PRINTTALK, "DIY Books have no more knowledge for you.")
		end

		--ply:TakeItem(item, 1)
	--end)
	return false -- to prevent default functionality.
end