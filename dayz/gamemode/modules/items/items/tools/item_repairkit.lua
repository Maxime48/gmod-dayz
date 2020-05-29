ITEM = {}
ITEM.Name = "Repair Kit"
ITEM.Angle = Angle(-180,-90,-90)
ITEM.Desc = "Used to repair items & vehicles, decompile and stuff."
ITEM.Model = "models/props_c17/tools_wrench01a.mdl"
ITEM.Weight = 1
ITEM.LootType = { "Industrial", "Weapon" }
ITEM.SpawnChance = 15
ITEM.SpawnOffset = Vector(0,0,5)
ITEM.ReqCraft = {"item_ironbar", "item_ironbar", "item_plank"}
ITEM.Rarity = 1
ITEM.NoBlueprint = true
ITEM.OverrideUseMenu = "Repair Vehicle"
ITEM.NoConsumeFromFloor = true
ITEM.PreProcessFunction = 
	function(ply, item, class, it)
	local tr = ply:GetEyeTrace()

	local ent = tr.Entity

	if !IsValid(ent) then return false end
	if !ent:IsVehicle() then return false end

	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end

	ply:DoModelProcess(ent:GetModel(), "Repairing Vehicle", 5, "physics/metal/metal_barrel_impact_soft"..math.random(1,4)..".wav", 5, "", true, function(ply)
		if !IsValid(ent) then return end

		local rep_amt = 50

		local hp = ent:Health()

		local buff = 0
		if it.rarity > 1 then
			buff = it.rarity * 2
		end

		ent:SetHealth(hp + rep_amt + buff)
		if ent:Health() > ent:GetMaxHealth() then
			ent:SetHealth( ent:GetMaxHealth() )
		end

		local qual = it.quality - math.Round( rep_amt / it.amount )

		ply:SetItem( it.id, it.amount, qual, it.rarity, false )
	end)

	return false -- to prevent default functionality.
end
ITEM.ProcessFunction = function(ply, item)
	-- stub to do nothing, just to add option to menu.
end