local NotTheseEnts = { "base_item", "npc_*", "weapon_*", "bank", "item_healthcharger", "backpack", "prop_*", "money" }
hook.Add("PlayerUse", "ClosingTheDoors", function(ply, ent)

	if !(table.HasValue( NotTheseEnts, ent:GetClass() ) and ent:IsVehicle() and ent:IsNPC() ) then 
		ent.DoorOpen = false
		timer.Destroy( "DoorClose_"..ent:EntIndex() )
		timer.Create( "DoorClose_"..ent:EntIndex(), 30, 1, function() if IsValid(ent) then ent:Fire("close") ent.DoorOpen = false end end )
	end

end)