ITEM = {}
ITEM.Name = "Gasoline Can"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "Used to fuel various machines."
ITEM.Model = "models/props_junk/gascan001a.mdl"
ITEM.Price = 25
ITEM.GasFor = 50
ITEM.Weight = 1
ITEM.LootType = { "Industrial" }
ITEM.SpawnChance = 35
ITEM.NoConsumeFromFloor = true
ITEM.SpawnOffset = Vector(0,0,14)
ITEM.Rarity = 1
ITEM.ReqCraft = { "item_jerrycan", "item_grainalcohol", "item_grainalcohol" }
ITEM.PreProcessFunction = 
	function(ply, item, class, it)
	local tr = ply:GetEyeTrace()

	local ent = tr.Entity

	if !IsValid(ent) then return false end
	if !ent:IsVehicle() then return false end

	if ent:GetPos():Distance(ply:GetPos()) > 200 then return false end

	if !ent.GetFuel then return false end

	ply:DoModelProcess(ent:GetModel(), "Fueling Vehicle", 5, "physics/metal/metal_barrel_impact_soft"..math.random(1,4)..".wav", 5, "", true, function(ply)
		if !IsValid(ent) then return end

		local fuel = ent:GetFuel()
		if fuel + 50 <= 100 then
			ent:SetFuel( fuel + 50 )
			ply:Tip(3, "Refueled 50%")
		else
			ent:SetFuel(100)
			ply:Tip(3, "The fuel tank is now full")
		end
		ply:EmitSound("ambient/water/water_spray1.wav",100,100)
		ent.GasCheck = CurTime()	


		local qual
		if ply.InvTable[class] && ply.InvTable[class][item] && ply.InvTable[class][item].quality then
			qual = ply.InvTable[class][item].quality - math.random(10, 40)
			ply.InvTable[class][item].quality = qual

			ply:UpdateItem( ply.InvTable[class][item] )
		end

		ply:TakeItem(item, 1)
		ply:GiveItem("item_jerrycan", 1, nil, qual, it.rarity)

	end)

	return false -- to prevent default functionality.
end
ITEM.ProcessFunction = function(ply, item)
	-- stub to do nothing, just to add option to menu.
end