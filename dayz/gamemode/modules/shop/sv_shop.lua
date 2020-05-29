function LoadShopItems()
	GAMEMODE.DayZ_Shops["shop_buy"] = {}
	GAMEMODE.CurrentShopInv = {}

	PLib:RunPreparedQuery({ sql = "SELECT `item`, `amount` FROM `shop_inventory`;", 
	callback = function( data )
		if !data then return end

		for i = 1, table.Count(data) do
			local item = data[ i ]
			local item_key = item[ "item" ]
			local item_amount = item[ "amount" ]
			item_key = tonumber(item_key) or item_key

			local item_table = GAMEMODE.DayZ_Items[ item_key ]
			
			if item_table != nil and item_amount then
				GAMEMODE.DayZ_Shops["shop_buy"][ item_key ] = tonumber( item_amount )
			end
		end

		MsgC(Color(0,255,0), "[SUCCESS] ", Color(255,255,0), "Loaded "..table.Count(data).." items from Shop Database!\n")

	end })
end
hook.Add("DZ_FullyLoaded", "LoadShopItems", LoadShopItems)

local function SendTable(ply)
	net.Start( "ShopTable" )
		net.WriteTable( GAMEMODE.CurrentShopInv or {} )
	net.Send( ply )
end
hook.Add("PlayerInitialSpawn", "SendShopTable", SendTable)

local function UpdateShopQuery(ItemKey, amount)
	amount = GAMEMODE.DayZ_Shops["shop_buy"][ItemKey]
	-- Commence query..
	//if oldamount then
		//PLib:QuickQuery( "UPDATE `shop_inventory` SET `amount` = " .. GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] .. " WHERE `item` = \"" .. ItemKey .. "\";" )
	//else
		PLib:QuickQuery( "INSERT INTO `shop_inventory` ( `item`, `amount` ) VALUES ( \"" .. ItemKey .. "\", " .. amount .. " ) ON DUPLICATE KEY UPDATE `amount` = " .. amount .. ";" )
	//end
end

function ChangeShop(ply)
	if IsValid(ply) and !ply:EntIndex() == 0 and !ply:IsAdmin() then return end

	if !PHDayZ.ShopBuyEnabled then return end
	
	GAMEMODE.DayZ_Shops[ "shop_buy" ] = GAMEMODE.DayZ_Shops[ "shop_buy" ] or {}

	GAMEMODE.CurrentShopInv = {}

	local tab = {}
	for k, v in pairs(GAMEMODE.DayZ_Items) do
		
		if v.IsCurrency or v.Category == "ammo" then 
			if !PHDayZ.ShopAlwaysSellCredits && v.ID == "item_credits" then continue end
			table.insert(tab, v)
		end

	end

	for k, v in pairs(tab) do
		GAMEMODE.DayZ_Shops[ "shop_buy" ][v.ID] = 1337 -- preset amount of ammo always available.
		GAMEMODE.CurrentShopInv[v.ID] = 1337
	end

	local amt = 0
	for k, v in RandomPairs( GAMEMODE.DayZ_Shops[ "shop_buy" ] ) do
		if !GAMEMODE.DayZ_Items[k] then continue end
		if v < 1 and PHDayZ.ShopAllowSoldOutStock then continue end -- Let's not add stuff that's sold out anymore, haha!
		
		if !GAMEMODE.DayZ_Items[k].Price or GAMEMODE.DayZ_Items[k].DontStock or GAMEMODE.DayZ_Items[k].VIP then continue end
		
		if GAMEMODE.DayZ_Items[k].Attachment then continue end -- do not sell attachments. There are too many, and they take up too much space.

		local a = math.Clamp( v, 0, 50 )
		GAMEMODE.CurrentShopInv[k] = math.random(0, a)
		amt = amt + 1
		if amt >= math.random(PHDayZ.ShopMinItems, PHDayZ.ShopMaxItems) then break end
	end

	if PHDayZ.ShopSellAll then

		for k, v in pairs( GAMEMODE.DayZ_Shops[ "shop_buy" ] ) do
			if !GAMEMODE.DayZ_Items[k] then continue end

			if GAMEMODE.DayZ_Items[k].Attachment then
				GAMEMODE.DayZ_Shops[ "shop_buy" ][k] = nil
			end

		end
		GAMEMODE.CurrentShopInv = GAMEMODE.DayZ_Shops[ "shop_buy" ]
	end
	
	for k, v in pairs(player.GetAll()) do 
		if v:GetSafeZone() or v:GetSafeZoneEdge() then
			if v._VIPSHOP then continue end

			net.Start( "ShopTable" )
				net.WriteTable( GAMEMODE.CurrentShopInv )
				net.WriteString("")
			net.Send(v)

		end
	end
	
	TipAll( 3, "traderchanged", Color(255,255,0) )

	hook.Call( "DZ_OnShopChange", GAMEMODE, GAMEMODE.CurrentShopInv )
end
hook.Add("DZ_FullyLoaded", "ChangeShop", ChangeShop)

concommand.Add("dz_changeshop", ChangeShop)

timer.Create( "ChangeShop", 600, 0, ChangeShop )

function PMETA:BuyItemMoney( item, amount, vip )
	if item == nil and amount == nil then return false end
	vip = tonumber( vip ) or 0
	if vip > 0 and !self:IsVIP() then return false end
    if not self:CanPerformAction() then return false end

	item = tonumber( item ) or item

	amount = math.Round( amount ) or 1
	if amount < 1 then return false end
	
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end
	
	if ItemTable == nil then return false end

	local npc
	for k, v in pairs( ents.FindInBox( self:GetPos()+Vector(100,100,50), self:GetPos()-Vector(100,100,50) ) ) do
		if v:GetClass() == "npc_sz" or v:GetClass() == "npc_vipsz" then
			npc = v
			break
		end
	end
		
	if !IsValid(npc) then 
		return false 
	end
	
	GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] or 0

	if ItemTable.Category != "perks" and ItemTable.Category != "lootboxes" && ItemKey != "item_keypad" then
		local shop = GAMEMODE.DayZ_Shops[ "shop_buy" ][ItemKey] or false

		if GAMEMODE.DayZ_Shops[ "shop_buy" ][ItemKey] < 1 then
			self:Tip( 3, "nostock", Color(255,255,0) )
			
			net.Start( "ShopTable" )
				if self._VIPSHOP then
					net.WriteTable( GAMEMODE.DayZ_Shops["shop_buy"] )
				else
					net.WriteTable( GAMEMODE.CurrentShopInv )
				end
				net.WriteString( ItemTable.Category or "none" )
			net.Send(self)
			
			return false 
		end
	end

	if ItemTable.Category != "perks" && amount > GAMEMODE.DayZ_Shops[ "shop_buy" ][ItemKey] then 
		if ItemTable.Category == "lootboxes" && ItemKey != "item_keypad" then
			

		else
			return false 
		end
	end
	
	local TakePrice = GAMEMODE.Util:GetItemPrice(ItemKey, amount, true, true, nil, nil, vip > 0)

	local money_item = "item_money"
	local cur = "$"
	if !TakePrice or TakePrice < 1 then 
		if !ItemTable.Credits then return false end

		TakePrice = ItemTable.Credits
		money_item = "item_credits"
		cur = "¢"
	end

	local money = GAMEMODE.Util:GetItemIDByClass(self.InvTable, money_item)

	if !money or money.amount < TakePrice then self:Tip( 3, "cantafford", Color(255,255,0) ) return false end
					
	self:TakeItem( money.id, TakePrice ) // take item_money
	
	local rarity = 1
    if ( vip > 0 ) and !ItemTable.AmmoType && !ItemTable.IsCurrency then
        rarity = 2
    end
    
	if ItemTable.Category == "lootboxes" && ItemKey != "item_keypad" then
		rarity = ItemTable.Rarity
	end

	local it = {}
	it.found_id = self.ID
	it.foundtype = 5
	self:GiveItem( ItemKey, amount, nil, 800, rarity, nil, nil, nil, nil, nil, it )

	if !( ItemTable.Category == "perks" ) then -- ignore perks as bought with credits..
		if ItemTable.Category == "lootboxes" and ItemKey != "item_keypad" then return end

		local shopamount = GAMEMODE.DayZ_Shops["shop_buy"][ItemKey]
		GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = (shopamount or 0) - amount

		if GAMEMODE.CurrentShopInv[ItemKey] != GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] then -- If it's currently for sale then make sure it's changing!
			if GAMEMODE.CurrentShopInv[ItemKey] != nil then 
				GAMEMODE.CurrentShopInv[ItemKey] = GAMEMODE.CurrentShopInv[ItemKey] - amount
			end
		end

		if ( PHDayZ.ShopAlwaysSellCredits && ItemKey == "item_credits" ) or ItemKey == "item_goldbar" or ItemKey == "item_diamondbar" or ItemTable.AmmoType then -- override. Always have stock.
			GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = 1337
			GAMEMODE.CurrentShopInv[ItemKey] = 1337
		end

		local plys = {}
		for k, v in pairs(player.GetAll()) do 
			if !v:GetSafeZone() and !v:GetSafeZoneEdge() then continue end

			net.Start( "ShopTable" )
				if v._VIPSHOP then
					net.WriteTable( GAMEMODE.DayZ_Shops["shop_buy"] )
				else
					net.WriteTable( GAMEMODE.CurrentShopInv )
				end
				net.WriteString( ItemTable.Category or "none" )
			net.Send( v )

		end

		UpdateShopQuery(ItemKey, shopamount)

	end

	self:EmitSound( "item_buy.wav", 75, 100, 0.2 )
	
	DzLog(1, "Player '"..self:Nick().."' ("..self:SteamID()..") bought "..ItemTable.Name .. "' x"..amount.." for "..cur..TakePrice )
end
concommand.Add( "BuyItemMoney", function( ply, cmd, args )
	ply:BuyItemMoney( args[ 1 ], args[ 2 ], args[ 3 ] )
end )

function PMETA:SellItemMoney( item, amount, vip )
	if item == nil and amount == nil then return false end
	vip = tonumber( vip ) or 0
	if vip > 0 and !self:IsVIP() then return false end
    if not self:CanPerformAction() then return false end

	item = tonumber( item ) or item

	amount = math.Round(amount or 1)
	if amount < 1 then return false end

	local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
	if !it then
		it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, item)
	end
	if !it then return false end 
	
	local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
	
	if ItemTable == nil then return false end

	local npc 
	for k, v in pairs( ents.FindInBox( self:GetPos()+Vector(100,100,50), self:GetPos()-Vector(100,100,50) ) ) do
		if v:GetClass() == "npc_sz" or v:GetClass() == "npc_vipsz" then
			npc = v
			break
		end
	end

	if !IsValid(npc) then return false end

	if ItemTable.CantSell then return false end

	local maxshopstock = PHDayZ.ShopMaxStock or 50
	if ItemTable.AmmoType then
		maxshopstock = maxshopstock * 10
	end

	GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] or 0

	if ( maxshopstock > 0 ) and GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] > maxshopstock then -- Anything but ammo. He loves ammo.
		self:Tip( 3, "stocktoohigh", Color(255,0,0) )
		return false
	end

	if it.amount < amount then return false end
	--if !self:HasItemAmount( ItemKey, amount) then return false end
	
	local GivePrice = GAMEMODE.Util:GetItemPrice(ItemKey, amount, true, nil, nil, it.quality, vip > 0, it.rarity)
	
	if !GivePrice or GivePrice == 0 then return false end

	npc:ResetSequence("takepackage")	

	self:GiveItem( "item_money", GivePrice, nil, 1000 ) // give item_money
	self:TakeItem( it.id, amount )

	self:EmitSound( "item_buy.wav", 75, 100, 0.2 )
	DzLog(1, "Player '"..self:Nick().."' ("..self:SteamID()..") sold "..ItemTable.Name.."' x"..math.Round(amount).." for $" .. GivePrice )

	if it.quality < 200 then return end

	local shopamount = GAMEMODE.DayZ_Shops["shop_buy"][ItemKey]
	GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = (shopamount or 0) + amount  -- The entire table, whole values and all items.

	if GAMEMODE.CurrentShopInv[ItemKey] != GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] then
		if GAMEMODE.CurrentShopInv[ItemKey] != nil then 
			GAMEMODE.CurrentShopInv[ItemKey] = ( GAMEMODE.CurrentShopInv[ItemKey] or 0 ) + amount -- The fake table, with the smaller values and less items for sale.
		else
			GAMEMODE.CurrentShopInv[ItemKey] = amount
		end
	end

	if ( PHDayZ.ShopAlwaysSellCredits && ItemKey == "item_credits" ) or ItemKey == "item_goldbar" or ItemKey == "item_diamondbar" or ItemTable.AmmoType && !ItemTable.Tertiary then -- override. Always have stock.
		GAMEMODE.DayZ_Shops["shop_buy"][ItemKey] = 1337
		GAMEMODE.CurrentShopInv[ItemKey] = 1337
	end

	local plys = {}
	for k, v in pairs(player.GetAll()) do 
		if !v:GetSafeZone() and !v:GetSafeZoneEdge() then continue end

		net.Start( "ShopTable" )
			if v._VIPSHOP then
				net.WriteTable( GAMEMODE.DayZ_Shops["shop_buy"] )
			else
				net.WriteTable( GAMEMODE.CurrentShopInv )
			end
			net.WriteString( ItemTable.Category or "none" )
		net.Send( v )

	end

	UpdateShopQuery(ItemKey, shopamount)

	if ItemTable.Primary or ItemTable.Secondary or ItemTable.Melee then
		if DZ_Quests then 
			self:DoQuestProgress("quest_traderqsale3", amount)
			if self:InQuest("quest_traderqsale3") then return end
			self:DoQuestProgress("quest_traderqsale2", amount)
			if self:InQuest("quest_traderqsale2") then return end
			self:DoQuestProgress("quest_traderqsale", amount) 
		end
	end
end
concommand.Add( "SellItemMoney", function( ply, cmd, args )
	ply:SellItemMoney( args[ 1 ], args[ 2 ], args[ 3 ] )
end )