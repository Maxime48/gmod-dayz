ITEM = {}

ITEM.Name = "Fishing Rod"
ITEM.Angle = Angle(90,90,90)
ITEM.Desc = "Aim in water to fish."
ITEM.Model = "models/props_junk/harpoon002a.mdl"
ITEM.Weight = 1
ITEM.NoTakeItem = true
ITEM.LootType = { "Industrial" }
ITEM.SpawnChance = 25 -- Out of 100
ITEM.SpawnOffset = Vector(0,0,14)
ITEM.ReqCraft = { "item_plank", "item_plank" }
ITEM.Rarity = 1
ITEM.UseName = "Fishing with"
ITEM.UseSound = "npc/vort/claw_swing"..math.random(1,2)..".wav"
ITEM.UseEndSound = ""
ITEM.ProcessFunction = 
function(ply, item, class) 
	if ply.SafeZone or ply.SafeZoneEdge then ply:Tip(3, "You cannot do this in the safezone!") return true end

	local tr = util.TraceLine( {
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 200,
        filter = function( ent ) if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "base_item" ) then return true end end
    } )

	if !DZ_IsInWater(tr.HitPos) then ply:Tip(3, "You need to be aiming at water!") return true end

	local rng = math.random(0, 25)
	if rng > 15 and rng < 25 then
		local rarity = GenerateRarity()

		ply:Tip(3, "You caught a fish!")
		ply:EmitSound(Sound("ambient/water/water_splash"..math.random(1,3)..".wav"))
		local item = "item_food5"
		if rng >= 20 then
			item = "item_ffish"
		end
		ply:GiveItem(item, 1, nil, math.random(700, 900), rarity, nil, nil, true)
	elseif rng > 24 then
		local item = table.Random(GAMEMODE.DayZ_Items)
		if item.SpawnChance > 0 then 
			local rarity = GenerateRarity( GAMEMODE.DayZ_Items[item] )
			ply:Tip(3, "You caught a "..item.Name.."!")
			ply:EmitSound(Sound("ambient/water/water_splash"..math.random(1,3)..".wav"))
			ply:GiveItem(item.ID, 1, nil, nil, rarity, nil, nil, true)
		else
			ply:Tip(3, "You caught nothing this time!")
		end
	else
		ply:Tip(3, "You caught nothing this time!")
	end

	local qual
	if ply.InvTable[class] && ply.InvTable[class][item] && ply.InvTable[class][item].quality then
		qual = ply.InvTable[class][item].quality - math.random(5,15)
		ply.InvTable[class][item].quality = qual

		ply:UpdateItem(ply.InvTable[class][item])
	end
	return true
end