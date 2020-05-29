// For SERVER use
concommand.Add( "MultiCraftItem", function(p,c,a)
	if not (a[1] and a[2]) then return end
	-- if IsValid item a[1] or something
	local num = tonumber(a[2])
	--if (not num) or num<=0 then p:ConCommand( "MultiCraftItem "..a[1].." NaN" ) return end // NaN will craft as long as possible
	
	p.DayZ_MultiCraft_Item = a[1]
	p.DayZ_MultiCraft_ItemIDs = { a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10] }
	p.DayZ_MultiCraft_Limit = num + 1
end)

local function ClearMultiCraft(ply)
	ply.DayZ_MultiCraft_Item = nil
	ply.DayZ_MultiCraft_ItemIDs = nil
	ply.DayZ_MultiCraft_Limit = nil
end

local function DoMultiCraft(ply)
	--for _, ply in pairs(player.GetAll()) do

		if ply.InProcess then return end

		if ply.DayZ_MultiCraft_Item or ply.DayZ_MultiCraft_Limit then

			if not (ply.DayZ_MultiCraft_Item and ply.DayZ_MultiCraft_Limit) then // Missing somethnig
				ClearMultiCraft( ply )
				return
			end

			ply.DayZ_MultiCraft_Limit = ply.DayZ_MultiCraft_Limit - 1

			if not ply:CraftItem( ply.DayZ_MultiCraft_Item, 1, unpack( ply.DayZ_MultiCraft_ItemIDs ) ) then // TODO:Replace with whatever the checks really are
				ClearMultiCraft( ply )
				return
			end

			if ply.DayZ_MultiCraft_Limit <= 1 then 
				ClearMultiCraft(ply) 
			end

		end
	--end
end
hook.Remove("Think", "DayZDoMultiCraft")
hook.Add( "PlayerTick", "DayZDoMultiCraft", DoMultiCraft )

hook.Add( "DZ_StopProcess", "DayZ StopMultiCraft", function(p) if IsValid(p) then ClearMultiCraft(p) end end)

local function ClearMultiDecompile(ply)
	ply.DayZ_MultiDecompile_Item = nil
	ply.DayZ_MultiDecompile_Limit = nil
end

concommand.Add( "MultiDecompileItem", function(p,c,a)
	if not (a[1] and a[2]) then return end
	-- if IsValid item a[1] or something
	local num = tonumber(a[2])
	--if (not num) or num<=0 then p:ConCommand( "MultiDecompileItem "..a[1].." NaN" ) return end // NaN will craft as long as possible
	
	p.DayZ_MultiDecompile_Item = a[1]
	p.DayZ_MultiDecompile_Limit = num + 1
end)

local function DoMultiDecompile( ply )
	if ply.InProcess then return end

	if ply.DayZ_MultiDecompile_Item or ply.DayZ_MultiDecompile_Limit then

		if not (ply.DayZ_MultiDecompile_Item and ply.DayZ_MultiDecompile_Limit) then // Missing somethnig
			ClearMultiDecompile( ply )
			return
		end

		ply.DayZ_MultiDecompile_Limit = ply.DayZ_MultiDecompile_Limit - 1

		if not ply:DecompileItem( ply.DayZ_MultiDecompile_Item, 1 ) then // TODO:Replace with whatever the checks really are
			ClearMultiDecompile( ply )
			return
		end

		if ply.DayZ_MultiDecompile_Limit <= 1 then 
			ClearMultiDecompile(ply) 
		end
	end
end
hook.Add( "PlayerTick", "DayZDoMultiDecompile", DoMultiDecompile )
hook.Remove( "Think", "DayZDoMultiDecompile" )

hook.Add( "DZ_StopProcess", "DayZ StopMultiDecompile", function(p) if IsValid(p) then ClearMultiDecompile(p) end end)

function PMETA:CraftItem( item, amount, item1, item2, item3, item4, item5, item6, item7, item8 )

	if item == nil and amount == nil then return false end

	item = tonumber(item) or item

	local itemids = { tonumber(item1), tonumber(item2), tonumber(item3), tonumber(item4), tonumber(item5), tonumber(item6), tonumber(item7), tonumber(item8) } -- hardcoded like this because i don't want more than 8 items in a recipe.

	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end

	if ItemTable == nil then return false end

	if !self:CanPerformAction() then return false end

	amount = math.Round( amount )
	if amount < 1 then return false end

	local amount2 = amount
	if ItemTable.GivePer then 
		amount2 = amount * ItemTable.GivePer 
	end

	if self:GetLevel() < ( ItemTable.LevelReq or 0 ) then 
		self:Tip( 3, "You need to be Level "..ItemTable.LevelReq.." to Craft this item!", Color(255,255,0) )
		return false 
	end

	if !( ItemTable.ReqCraft or ItemTable.ReqCook) or ItemTable.CantCraft then return false end

	if !self.BPTable[item] and !ItemTable.NoBlueprint then self:Tip( 3, "noblueprint", Color(255,255,0) ) return false end

	local craft_type = "Craft"
	local do_snd = "stranded/start_crafting.wav"
	if ItemTable.ReqCook then
		craft_type = "Cook"
		do_snd = "player/pl_burnpain3.wav"
	end

	local fire = false
	local vec = Vector(150,150,50)
	for k, v in pairs(ents.FindInBox(self:GetPos()+vec, self:GetPos()-vec)) do
		if v:IsOnFire() then fire = true break end
		if v:GetClass() == "env_fire" then fire = true break end -- lol
	end
		
	if !fire and ItemTable.ReqCook and !ItemTable.NoFire then
		self:Tip( 1, "needfire", Color(255,0,0) )
		
		return false
	end

	local tbl = ItemTable.ReqCraft or ItemTable.ReqCook
	local takeitems = {}

	local tbl_c = {}

	for k, v in pairs(tbl) do
		tbl_c[v] = ( tbl_c[v] or 0 ) + 1

		--table.insert(tbl_c, v)
	end

	if table.Count(itemids) != table.Count(tbl) then return false end -- no using less items than what is needed.

    local used_ids = {}

    local rarity = 0
    local it_c = {}
    for _, i in pairs(itemids) do
    	it_c[i] = ( it_c[i] or 0 ) + 1 

    	local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, i)

    	if !it then continue end
    	if it.amount < ( it_c[i] or 0 ) then continue end

    	rarity = rarity + it.rarity

       	local v_itemtable, v_key = GAMEMODE.DayZ_Items[ it.class ], it.class
   		if v_itemtable == nil then continue end

		local amt = self:GetItemAmount(it.id)

		if v_itemtable.NoTakeOnCraft then continue end
		
		local item_id = it.id
    	table.insert(takeitems, { id = item_id, quality = it.quality, take = 1 })
    	table.insert(used_ids, item_id)

    	local amt = tbl_c[it.class] or 0
    	tbl_c[it.class] = amt - 1
	end

	local total_req = 0
	for k, v in pairs(tbl_c) do
		total_req = total_req + v -- if more than 0, stop because materials are not correct.
	end

	if total_req > 0 then self:Tip( 3, "requiredmaterials", Color(255,255,0) ) return false end -- not empty.

	rarity = math.floor( rarity / table.Count(itemids) ) -- this is our median rarity.
	if rarity < 1 then rarity = 1 end


	local xp = 5 * table.Count(tbl)

	if ItemTable.AmmoType then
		xp = xp/5
	end

	if ItemTable.Category == "resources" then xp = xp / 2 end
	if ItemTable.NoBreakDecompile then xp = 0 end

	local vtab = { "vo/npc/male01/oneforme.wav", "vo/npc/male01/vanswer08.wav", "vo/npc/Barney/ba_ohyeah.wav" }
	local snd = vtab[ math.random( #vtab ) ]

	self:DoCustomProcess(item, craft_type.."ing", ItemTable.TimeToProcess or 5, do_snd, xp, "", true, function(ply, item)
		local quality = 0
		for _, v in pairs( takeitems ) do	
			quality = quality + v.quality	
			self:TakeItem( v.id, v.take )
		end

		quality = quality / table.Count( takeitems )
		
		local it = {}
		it.found_id = self.ID
		it.foundtype = 2 -- crafted

		self:GiveItem( ItemKey, amount2, nil, quality, rarity, nil, nil, nil, nil, nil, it )

		if string.lower( ItemTable.Category or "" ) == "medical" && DZ_Quests then
			
			self:DoQuestProgress("quest_medicinemaster3", amount2)
			if !self:InQuest("quest_medicinemaster3") then
				self:DoQuestProgress("quest_medicinemaster2", amount2)
				if !self:InQuest("quest_medicinemaster2") then 
					self:DoQuestProgress("quest_medicinemaster", amount2)
				end
			end

		end

		if ItemTable.Primary or ItemTable.Secondary or ItemTable.Melee && DZ_Quests then

			self:DoQuestProgress("quest_craftycutie3", amount2)
			if !self:InQuest("quest_craftycutie3") then
				self:DoQuestProgress("quest_craftycutie2", amount2)
				if !self:InQuest("quest_craftycutie2") then 
					self:DoQuestProgress("quest_craftycutie", amount2)
				end
			end

		end

		if ItemTable.ID == "item_ots33" && DZ_Quests then -- P99 quest
			self:DoQuestProgress("quest_learnthebasics", 1)
		end

		if ItemTable.ID == "item_dz_axe" && DZ_Quests then -- P99 quest
			self:DoQuestProgress("quest_learnthebasics2", 1)
		end

		if ItemTable.ID == "item_swb_famas" && DZ_Quests then -- AR15 quest
			self:DoQuestProgress("quest_learnthebasics4", 1)
		end

		hook.Call( "DZ_OnCraftItem", GAMEMODE, self, ItemKey, amount2 )

		DzLog(6, "Player '"..self:Nick().."'("..self:SteamID()..") ran "..craft_type.."Item with item: "..ItemKey.." and amount: "..amount2)

	end)

	return true

end
concommand.Add( "CraftItem", function( ply, cmd, args )
	ply:CraftItem( unpack(args) )
end )

function PMETA:DecompileItem( item, amount )
	if item == nil and amount == nil then return false end

	item = tonumber(item) or item
	local it
	if isstring(item) then
		it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, item)
	else
		it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
	end
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

	if it.amount < 1 then return false end

	if ItemTable.CantDecompile then return false end

	amount = math.Round( amount )
	if amount < 1 then return false end

	local amount2 = amount
	if ItemTable.GivePer then 
		amount2 = amount * ItemTable.GivePer 
	end

	if it.amount < amount2 then
		amount2 = it.amount
	end

	local r_it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, "item_repairkit")
	if r_it && r_it.amount < 1 then r_it = nil end

	local p_it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, "item_paper")

	if !p_it && !self.BPTable[it.class] && !self:HasSkill("int_bitsnbobs") && !ItemTable.NoBlueprint then
		self:Tip( 3, "You need paper to blueprint this item!", Color(255,255,0) )
		return false
	end

	if self:GetLevel() < ( ItemTable.LevelReq or 0 ) then 
		self:Tip( 3, "You need to be Level "..ItemTable.LevelReq.." to Decompile this item!", Color(255,255,0) )

		return false 
	end

	self:DoCustomProcess(it.class, "Decompiling", ItemTable.TimeToProcess or 5, "stranded/start_campfire.wav", 0, "items/itempickup.wav", true, function(ply, item)
		local items = { {}, {} } 
		
		local breakamt = 50

		if ItemTable.GivePer and ( ItemTable.GivePer > amount2 ) then

			ply:TipParams( 3, "decompiled", ItemTable.Name..".", "notenoughdecompile", Color(255,0,0) )

			ply:TakeItem( it.id, amount2 )
			return
		end

		if !ply.BPTable[it.class] && !ItemTable.CantCraft && !ItemTable.NoBlueprint then
			if !self:HasSkill("int_bitsnbobs") then
				ply:TakeItem("item_paper", 1, true)
			end

			ply:GiveBluePrint( ItemKey )
		end

		if self:HasPerk("perk_bulletbill") && ItemTable.AmmoType then
			local perc = breakamt / 100
			breakamt = math.Clamp( breakamt + (perc * 50) , 0, 100)
		end

		local tk = false
		for _, v in pairs( ItemTable.ReqCraft ) do
			
			local IT = GAMEMODE.Util:GetItemByID( v )

			local percentage = math.random(0, 100)
			if percentage > breakamt && !ItemTable.NoBreakDecompile then 
				if !r_it or r_it.quality < 100 then
					table.insert(items[2], IT.Name) 
					continue 
				else
					if !tk then 
						tk = true
						table.insert(items[2], "DoDmg")
					end
				end
			end
				
			it.found_id = ply.ID -- change owner as passing old item before removing
			it.foundtype = 2 -- made

			ply:GiveItem( v, amount, nil, it.quality, it.rarity, nil, nil, true, nil, nil, it )
			table.insert(items[1], IT.Name)
		end

		ply:TakeItem( it.id, amount2 )


		local found = 0
		for k, v in pairs(items[2]) do
			if v == "DoDmg" then
				items[2][k] = nil

				local dmgamt = math.random(49, 54)

				found = found + math.floor( dmgamt - ( 7 * r_it.rarity  ) ) -- damage amount
			end
		end

		if found > 0 then

			if r_it then
				r_it.quality = r_it.quality - math.Round( found / r_it.amount )

				PLib:QuickQuery( "UPDATE `players_inventory` SET `quality` = "..r_it.quality.." WHERE `id` = " .. r_it.id .. ";" )
				self:UpdateItem(r_it)
			end
			--ply:TakeItem("item_toolkit", 1, true) -- nerfed intentionally.
		end


		--ply:Tip( 3, "Decompiled '" .. ItemTable.Name .. "'.", Color(255,255,0), "Gained: "..table.concat(items[1], ", "), Color(0,255,0) )
		--ply:TipParams(3, "decompiled", ItemTable.Name..".", "gained", table.concat(items[1], ", ") )

		if #items[2] > 0 then
			ply:TipParams(3, "decompiled", ItemTable.Name..".", "destroyed", table.concat(items[2], ", ") )
			--ply:Tip( 3, "Decompiled '" .. ItemTable.Name .. "'.", Color(255,255,0), "Destroyed: "..table.concat(items[2], ", "), Color(255,0,0) )
		end 

		DzLog(6, "Player '"..self:Nick().."'("..self:SteamID()..") ran DecompileItem with item: "..it.class.." and amount: "..amount2)

	end)

	return true
end
concommand.Add( "DecompileItem", function( ply, cmd, args )
	ply:DecompileItem( args[ 1 ], 1 )
end )

// For SERVER use
concommand.Add( "MultiCookItem", function(p,c,a)
	if not (a[1] and a[2]) then return end
	-- if IsValid item a[1] or something
	local num = tonumber(a[2])
	--if (not num) or num<=0 then p:ConCommand( "MultiMultiCook "..a[1].." NaN" ) return end // NaN will craft as long as possible
	
	p.DayZ_MultiCook_Item = a[1]
	p.DayZ_MultiCook_ItemIDs = { a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10] }
	p.DayZ_MultiCook_Limit = num + 1
end)

local function ClearMultiCook(ply)
	ply.DayZ_MultiCook_Item = nil
	ply.DayZ_MultiCook_ItemIDs = nil
	ply.DayZ_MultiCook_Limit = nil
end

local function DoMultiCook(ply)
	--for _, ply in pairs(player.GetAll()) do

		if ply.InProcess then return end

		if ply.DayZ_MultiCook_Item or ply.DayZ_MultiCook_Limit then

			if not (ply.DayZ_MultiCook_Item and ply.DayZ_MultiCook_Limit) then // Missing somethnig
				ClearMultiCook( ply )
				return
			end

			ply.DayZ_MultiCook_Limit = ply.DayZ_MultiCook_Limit - 1

			if not ply:CraftItem( ply.DayZ_MultiCook_Item, 1, unpack( ply.DayZ_MultiCook_ItemIDs ) ) then // TODO:Replace with whatever the checks really are
				ClearMultiCook( ply )
				return
			end

			if ply.DayZ_MultiCook_Limit <= 1 then 
				ClearMultiCook(ply) 
			end

		end
	--end
end
hook.Remove("Think", "DayZDoMultiCook")
hook.Add( "PlayerTick", "DayZDoMultiCook", DoMultiCook )

hook.Add( "DZ_StopProcess", "DayZ StopMultiCook", function(p) if IsValid(p) then ClearMultiCook(p) end end)

local function ClearMultiStudy(ply)
	ply.DayZ_MultiStudy_Item = nil
	ply.DayZ_MultiStudy_Limit = nil
end

concommand.Add( "MultiStudyItem", function(p,c,a)
	if not (a[1] and a[2]) then return end
	-- if IsValid item a[1] or something
	local num = tonumber(a[2])
	--if (not num) or num<=0 then p:ConCommand( "MultiMultiStudy "..a[1].." NaN" ) return end // NaN will craft as long as possible
	
	p.DayZ_MultiStudy_Item = a[1]
	p.DayZ_MultiStudy = num + 1
end)

local function DoMultiStudy( ply )
	if ply.InProcess then return end

	if ply.DayZ_MultiStudy_Item or ply.DayZ_MultiStudy_Limit then

		if not (ply.DayZ_MultiStudy_Item and ply.DayZ_MultiStudy_Limit) then // Missing somethnig
			ClearMultiStudy( ply )
			return
		end

		ply.DayZ_MultiStudy_Limit = ply.DayZ_MultiStudy_Limit - 1

		if not ply:StudyItem( ply.DayZ_MultiStudy_Item, 1 ) then // TODO:Replace with whatever the checks really are
			ClearMultiStudy( ply )
			return
		end

		if ply.DayZ_MultiStudy_Limit <= 1 then 
			ClearMultiStudy(ply) 
		end
	end
end
hook.Add( "PlayerTick", "DayZDoMultiStudy", DoMultiStudy )
hook.Remove( "Think", "DayZDoMultiStudy" )

hook.Add( "DZ_StopProcess", "DayZ StopMultiStudy", function(p) if IsValid(p) then ClearMultiStudy(p) end end)

function PMETA:CookItem( item, amount )
	if item == nil and amount == nil then return false end
	
	item = tonumber(item) or item
	
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end
	
	if ItemTable == nil then return false end
	
	if !self:CanPerformAction() then return false end

	if self:GetLevel() < ( ItemTable.LevelReq or 0 ) then 
		self:Tip( 3, "You need to be Level "..ItemTable.LevelReq.." to Cook this item!", Color(255,255,0) )
		return false 
	end

	amount = 1
	if amount < 1 then return false end

	local amount2 = amount
	if ItemTable.GivePer then 
		amount2 = amount * ItemTable.GivePer 
	end
	
	if !ItemTable.ReqCook then return false end

	local hasitems = {}
	local tbl = {}
	for k, v in pairs( ItemTable.ReqCook ) do
		tbl[v] = tbl[v] or 0
		tbl[v] = tbl[v] + 1
	end

	local takeitems = {}
	for v, reqamt in pairs( tbl ) do
		if !hasitems[v] then hasitems[v] = false end

		local its = GAMEMODE.Util:GetItemIDsByClass(self.InvTable, v)
        if its == nil then return false end
       	local v_itemtable, v_key = GAMEMODE.DayZ_Items[ v ], v
        if v_itemtable == nil then return false end

        for _, it in pairs(its) do
        	if hasitems[v] then continue end

			local amt = self:GetItemAmount(it.id)
			if amt < reqamt then continue end

			if amt >= reqamt then hasitems[v] = true end

			if v_itemtable.NoTakeOnCook then continue end

			local item_id = it.id
		    table.insert(takeitems, { id = item_id, quality = it.quality, take = tbl[v] })
		end
	end	

	local passgo = true
	for k, v in pairs(hasitems) do
		if v == false then
			passgo = false
			break
		end
	end
		
	if !passgo then self:Tip( 3, "requiredfood", Color(255,255,0) ) return false end
		
	local fire
	local vec = Vector(150,150,50)
	for k, v in pairs(ents.FindInBox(self:GetPos()+vec, self:GetPos()-vec)) do
		if v:IsOnFire() or v:GetClass() == "env_fire" then fire = v break end -- lol
	end
		
	if !IsValid(fire) and !ItemTable.NoFire then
		self:Tip( 1, "needfire", Color(255,0,0) )
		
		return false
	end
	
	local xp = 5 * table.Count(ItemTable.ReqCook)

	local vtab = { "vo/npc/male01/oneforme.wav", "vo/npc/male01/vanswer08.wav", "vo/npc/Barney/ba_ohyeah.wav" }
	local snd = vtab[ math.random( #vtab ) ]
	
	self:DoCustomProcess(item, "Cooking", ItemTable.TimeToProcess or 5, "", xp, snd, true, function(ply, item)
		
		local quality = 0
		for _, v in pairs( takeitems ) do	
			quality = quality + v.quality	
			self:TakeItem( v.id, v.take )
		end

		quality = quality / table.Count( takeitems )
		
		local it = {}
		it.found_id = self.ID
		it.foundtype = 2 -- made

		self:GiveItem( ItemKey, amount2, nil, quality, nil, nil, nil, true, nil, nil, it )
		
		if IsValid(fire) && fire:GetClass() == "dz_interactable" then
			fire:SetHealth( fire:Health() - 20 )
		end
	end)

	return true		
end
concommand.Add( "CookItem", function( ply, cmd, args )
	ply:CraftItem( unpack(args) )
end )

function PMETA:StudyItem( item, amount )
	if item == nil and amount == nil then return false end

	item = tonumber(item) or item

	local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

	if self:GetItemAmount( item ) < 1 then return false end

	if ItemTable.CantDecompile then return false end

	if self:GetLevel() < ( ItemTable.LevelReq or 0 ) then 
		self:Tip( 3, "You need to be Level "..ItemTable.LevelReq.." to Study this item!", Color(255,255,0) )
		return false 
	end

	amount = math.Round( amount )
	if amount < 1 then return false end

	local amount2 = amount
	if ItemTable.GivePer then 
		amount2 = amount * ItemTable.GivePer 
	end

	if self:GetItemAmount( item ) < amount2 then
		amount2 = self:GetItemAmount( item )
	end

	self:DoCustomProcess(item, "Studying", ItemTable.TimeToProcess or 5, "stranded/start_campfire.wav", 0, "items/itempickup.wav", true, function(ply, item)
		local items = { {}, {} } 
			
		if !ItemTable.CantCook then
			ply:GiveBluePrint( ItemKey )
		end

		ply:TakeItem( item, amount2 )

		DzLog(6, "Player '"..self:Nick().."'("..self:SteamID()..") ran StudyItem with item: "..item.." and amount: "..amount2)

	end)

	return true
end
concommand.Add( "StudyItem", function( ply, cmd, args )
	ply:StudyItem( args[ 1 ], 1 )
end )