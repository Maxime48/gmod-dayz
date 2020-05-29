util.AddNetworkString( "LootItem" )

-- These are not used for anything really (only Acecool would do this), just here to show you the correct order.
local TYPE_BASIC = 1
local TYPE_FOOD = 2
local TYPE_INDUSTRIAL = 3
local TYPE_MEDICAL = 4
local TYPE_WEAPON = 5
local TYPE_HAT = 6

-- Keep these in order. If you're adding new types, make sure they are not replacing another's position in the table, or you'll get twonky results.
local foldernames = {"basic", "food", "industrial", "medical", "weapon", "hat"}

TotalSpawnedLoot = TotalSpawnedLoot or 0

LootVectors = {}
LootVectors[string.lower(game.GetMap())] = {}

Msg("======================================================================\n")
for k, v in pairs( foldernames ) do
	
	file.CreateDir("dayz/spawns_loot/"..v)

	if !file.Exists("dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") then
		file.Write( "dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", util.TableToJSON({}, true) )
	end
	
	LootVectors[string.lower(game.GetMap())][ k ] = {} -- A bit of validation never hurt anybody.
	if file.Size("dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
		--MsgC(Color(255,0,0), "[PHDayZ] Loot spawntype '", Color(255,255,0), v, Color(255,0,0), "' not yet setup!\n")
		table.insert(PHDayZ_StartUpErrors, "Loot spawntype '"..v.."' not yet setup!")
	else
		local config = util.JSONToTable( file.Read("dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") )
		
		if not istable(config) then
			table.insert(PHDayZ_StartUpErrors, "Loot spawntype '"..v.."' failed to load, check file consistency!")
			--MsgC(Color(255,0,0), "[PHDayZ] Loot spawntype '", Color(255,255,0), v, Color(255,0,0), "' failed to load, check consistency!\n")
			return
		end

		LootVectors[string.lower(game.GetMap())][k] = config	
		MsgC(Color(0,255,0), "[PHDayZ] Loot spawntype '", Color(255,255,0), v, Color(0,255,0), "' found and loaded!\n")
	end
	
end
Msg("======================================================================\n")

local function ReloadLoot(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.
	MsgC(Color(255,255,0), "[PHDayZ] "..ply:Nick().." has reloaded the loot data!\n")

	local reload = false
	if args[1] then
		reload = true
	end
	
	for k, v in ipairs( foldernames ) do
		if file.Size("dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
			MsgAll("[PHDayZ] Loot spawntype '"..v.."' not yet setup!\n")
		else
		
			local config = util.JSONToTable( file.Read("dayz/spawns_loot/"..v.."/"..string.lower(game.GetMap())..".txt", "DATA") )
		
			if not istable(config) then
				MsgC(Color(255,0,0), "[PHDayZ] Loot spawntype '", Color(255,255,0), v, Color(255,0,0), "' failed to load, check consistency!\n")
				return
			end
			
			LootVectors[string.lower(game.GetMap())][k] = config			
			MsgAll("[PHDayZ] Loot spawntype '"..v.."' found and loaded!\n")
		end
	end
	
	LoadLootSystem( reload )
	MsgAll("[PHDayZ] Loot has been reloaded.\n")
end
concommand.Add("dz_reloadloot", ReloadLoot)

LootItems = LootItems or {
	[ "basic" ] = {},
	[ "food" ] = {},
	[ "industrial" ] = {},
	[ "medical" ] = {},
	[ "weapon" ] = {},
	[ "hat" ] = {}
}

local LootRadius = Vector( 50, 50, 50 )

function LoadLootSystem( reload ) 

	LootItems = {
		[ "basic" ] = {},
		[ "food" ] = {},
		[ "industrial" ] = {},
		[ "medical" ] = {},
		[ "weapon" ] = {},
		[ "hat" ] = {}
	}
	
	for k, v in pairs(GAMEMODE.DayZ_Items) do
		local Item = v
		if Item.genRarity && !(Item.Weapon or Item.Body or Item.Pants or Item.Shoes or Item.Hat or Item.BackPack or Item.BodyArmor) then continue end

		if Item.SpawnChance == -1 then continue end -- No point adding the item if it won't spawn at all!
		
		if Item.LootType then
			for _, Type in pairs( Item.LootType ) do
				if !Type or ( string.lower(Type) == "none" ) or ( string.lower(Type) == "basic" ) then continue end -- Why the fuck did I put "None" when I could have nilled the system.

				table.insert( LootItems[ string.lower(Type) ], k )
			end
		end
		
		table.insert( LootItems[ "basic" ] , k ) -- Insert all items into basic table for spawning anywhere.
	end

	for k, v in pairs(ents.FindByClass("base_item")) do
		if !IsValid(v) then continue end
		v:Remove()
	end

	if !reload then for i=0, 100 do SpawnSomeLoot() end end
	
	timer.Create( "LootSpawnTimer", PHDayZ.LootTimer, 0, function()
		for i=1, ( PHDayZ.LootSpawnAmount or 1 ) do
			for itemtype=1, #foldernames do
				SpawnSomeLoot(itemtype)
			end
		end
	end )
end
hook.Add( "DZ_FullyLoaded", "LoadLootSystem", LoadLootSystem )

function SpawnSomeLoot(itemtype, setkey, pos)
	-- Choose type of loot to spawn
	if !itemtype then
		itemtype = TYPE_BASIC
			
		if math.random(1, 4) >= 2 then -- 1 in 2 chance of non-basic loot
			itemtype = math.random(1, #foldernames)
		end
		
	end

	local ftype = UpFirstLetter( foldernames[itemtype] )..":"..itemtype
	
	if TotalSpawnedLoot > PHDayZ.TotalAllowedLoot then 
		if PHDayZ.DebugMode then 
			PrintMessage(HUD_PRINTCONSOLE, "[FAIL] Loot-Type: "..ftype.." - Maximum loot criteria met ("..TotalSpawnedLoot..")!\n")
			MsgC( Color(255,0,0), "[FAIL] ", Color(255,255,0), "Loot-Type: "..foldernames[itemtype].." - Maximum loot criteria met ("..TotalSpawnedLoot..")!\n" ) 
		end 
		
		return 
	end

	pos = pos or table.Random( LootVectors[ string.lower( game.GetMap() ) ][ itemtype ] )
	if !pos then return end
	
	local nearitem = false
	for _, ent in pairs( ents.FindInBox( pos + LootRadius, pos - LootRadius ) ) do
		if IsValid( ent ) and ( ent:GetClass() == "base_item" or ent:IsPlayer() ) then
			nearitem = true

			break
		end
	end

	local PlayerRadius = Vector(150, 150, 150)
	for _, ent in pairs( ents.FindInBox( pos + PlayerRadius, pos - PlayerRadius ) ) do
		if IsValid( ent ) and ent:IsPlayer() then
			nearitem = true
			break
		end
	end

	local ammo_s = GAMEMODE.Util:GetItemsByCategory("ammo")

	local ItemKey = setkey or table.Random( LootItems[ foldernames[itemtype] ] )

	if math.random(1, 100) <= ( PHDayZ.AmmoSpawnRate or 10 ) then
		ItemTable = table.Random( ammo_s )
		ItemKey = ItemTable.ID
	end

	local ItemTable = GAMEMODE.DayZ_Items[ ItemKey ]
	
	if !ItemTable then 
		if PHDayZ.DebugMode then 
			MsgAll( "[PHDayZ] ItemTable is nil!\n" ) 
		end 
		return 
	end
	
	if nearitem then
		if PHDayZ.DebugMode then 
			PrintMessage(HUD_PRINTCONSOLE, "[FAIL] Loot-Type: "..ftype.." | "..ItemTable.Name.." | "..ItemTable.ID.." - Loot in Proximity!\n")
			MsgC( Color(255,0,0), "[FAIL] ", Color(255,255,0), "Loot-Type: "..ftype.." | "..ItemTable.Name.." | "..ItemTable.ID.." - Loot in Proximity!\n" ) 
		end 
		
		return 
	end
	
	local sc = math.random( 0, 100 )
	local spawnchance = ItemTable.SpawnChance
	if tonumber( spawnchance ) < sc then 
		if PHDayZ.DebugMode then 
			PrintMessage(HUD_PRINTCONSOLE, "[FAIL] Loot-Type: "..ftype.." | "..ItemTable.Name.." | "..ItemTable.ID.." - Spawnchance "..sc..">"..tonumber( spawnchance ).."!\n" ) 
			MsgC( Color(255,0,0), "[FAIL] ", Color(255, 255, 0), "Loot-Type: "..ftype.." | "..ItemTable.Name.." | "..ItemTable.ID.." - Spawnchance "..sc..">"..tonumber( spawnchance ).."!\n" ) 
		end 
		return 
	end
	
	local itement = ents.Create( "base_item" )
	itement:SetItem( ItemKey )
	--itement:SetPos( PHDayZ.AnticheatItempos or Vector(0,0,0) )
	--itement.noNetwork = true
	--for k, v in pairs( player.GetAll() ) do
		--if v:IsAdmin() then continue end -- ignores admins for ESP

		--StopNetworkingEntity(itement, true)
        //itement:SetPreventTransmit(v, true)
    --end

    --timer.Simple(2, function()
    	--if !IsValid(itement) then return end

    	itement:SetPos( pos + ( ItemTable.SpawnOffset or Vector(0,0,0) ) )
    	itement.noNetwork = nil
    	itement:SetFoundWhen( os.time() )
    	itement:Activate()
    	itement:Spawn()
    	
    --end)

	itement.LootPos = pos
	
	itement.Amount = ItemTable.ClipSize or 1
	
	itement:SetAmount( itement.Amount )
	itement:SetModelScale( ItemTable.Modelscale or 1 )
	itement:SetQuality( math.random(100, 700) )
	
	local rarity = GenerateRarity(ItemTable) or 1
	itement:SetRarity( rarity )

	if ItemTable.SpawnAngle then
		itement:SetAngles( ItemTable.SpawnAngle )
	end
	
	TotalSpawnedLoot = TotalSpawnedLoot + 1
	itement.SpawnLoot = true

	if PHDayZ.DebugMode then
		PrintMessage(HUD_PRINTCONSOLE, "[SUCCESS] Loot-Type: "..ftype.." | " .. ItemTable.Name.." | "..ItemTable.ID.."("..TotalSpawnedLoot..")\n" )
		MsgC( Color(0,255,0), "[SUCCESS] ", Color(255,255,0), "Loot-Type: "..ftype.." | " .. ItemTable.Name.." | "..ItemTable.ID.."("..TotalSpawnedLoot..")\n" )
	end
end

function SpawnSomeLoot_Admin(ply, cmd, args)
	if !ply:IsConsole() and !ply:IsSuperAdmin() then return end

	local itemtype = args[1]
	local ItemKey = args[2]
	local ItemTable = GAMEMODE.DayZ_Items[ ItemKey ]
	local tablenum = table.KeyFromValue(foldernames, itemtype)

	if !tablenum then 
		if ply:IsConsole() then
			Msg( "No such item type!\n" ) 
		else
			ply:PrintMessage(HUD_PRINTCONSOLE, "No such item type!\n" ) 
		end
		return
	end
	
	if !ItemTable then 
		if ply:IsConsole() then
			Msg( "This item doesn't exist!\n" ) 
		else
			ply:PrintMessage(HUD_PRINTCONSOLE, "This item doesn't exist!\n" ) 
		end
		return 
	end
	
	SpawnSomeLoot(tablenum, ItemKey)
end
concommand.Add("dz_spawnloot", SpawnSomeLoot_Admin)

function PMETA:LootItem( item, amount, backpack, char )

	item = tonumber(item) or item

	if !self.LootingBackpack then return end
	local backpack_ent = Entity( self.LootingBackpack ) 
	if !IsValid( backpack_ent ) then return false end
	
	local it
	if char == 1 then
		it = GAMEMODE.Util:GetItemByDBID(backpack_ent.CharTable or {}, item)
	else
		it = GAMEMODE.Util:GetItemByDBID(backpack_ent.ItemTable or {}, item)
	end
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[it.class], it.class

    if it.amount < 1 then return false end

	if !self:Alive() then return false end
		
	amount = tonumber( amount )

    if it.amount < amount then return false end

	if backpack_ent:IsOnFire() then
		net.Start( "net_CloseLootMenu" )
		net.Send( self )

		self:Tip(3, "ouchonfire", Color(255,0,0) ) 
		self:TakeBlood(5)
		self:Ignite( math.random(2, 5) )
		self:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
		self:ViewPunch(Angle(-10, 0, 0))
		
		return  
	end

	if self:GetPos():DistToSqr( backpack_ent:GetPos() ) > ( 200 * 200 ) then
		net.Start( "net_CloseLootMenu" )
		net.Send( self )

		return
	end
	
	it.amount = it.amount - math.Round( amount )
		
	self:EmitSound( "items/itempickup.wav", 110, 100, 0.3 )
	self:GiveItem( it.class, math.Round( amount ), nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it )
	
	if char == 1 then
		if it.amount < 1 then
			backpack_ent.CharTable[ it.class ][ it.id ] = nil
		else
			backpack_ent.CharTable[ it.class ][ it.id ] = it
		end
	else
		if it.amount < 1 then
			backpack_ent.ItemTable[ it.class ][ it.id ] = nil
		else
			backpack_ent.ItemTable[ it.class ][ it.id ] = it
		end
	end

	local itemCat = ItemTable.Category
	if !itemCat then itemCat = "none" end
	
	if char == 1 then
		net.Start( "UpdateBackpackChar" )
			net.WriteTable( backpack_ent.CharTable )
		net.Send( self )
	else
		net.Start( "UpdateBackpack" )
			net.WriteTable( backpack_ent.ItemTable )
			net.WriteString( itemCat )		
		net.Send( self )
	end

	if backpack_ent.players_int then
		for k, plyindex in pairs(backpack_ent.players_int) do
			local ply = Entity(plyindex)
			if !IsValid(ply) then continue end
			if ply == self then continue end -- ignore for player currently.

			if ply:GetPos():DistToSqr( backpack_ent:GetPos() ) > ( 300 * 300 ) then continue end

			if ply.LootingBackpack != nil && ply.LootingBackpack != backpack_ent:EntIndex() then continue end -- only network the backpack they are looting...

			if char == 1 then
				net.Start( "UpdateBackpackChar" )
					net.WriteTable( backpack_ent.CharTable )
				net.Send( ply )
			else
				net.Start( "UpdateBackpack" )
					net.WriteTable( backpack_ent.ItemTable )
					net.WriteString( itemCat )		
				net.Send( ply )
			end

		end
	end

	local anyItems = 0
    for k, items in pairs(backpack_ent.ItemTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
            break
        end
    end
    for k, items in pairs(backpack_ent.CharTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
            break
        end
    end

    if anyItems < 1 then
		if backpack_ent.players_int then
			for k, plyindex in pairs(backpack_ent.players_int) do
				local ply = Entity(plyindex)
				if !IsValid(ply) then continue end

				if ply:GetPos():DistToSqr( backpack_ent:GetPos() ) > ( 300 * 300 ) then continue end

				if ply.LootingBackpack != nil && ply.LootingBackpack != backpack_ent:EntIndex() then continue end -- only network the backpack they are looting...

				net.Start( "net_CloseLootMenu" )
				net.Send( ply )

				ply.LootingBackpack = nil
			end
		end

    end

	if backpack_ent:GetClass() == "prop_ragdoll" or backpack_ent:GetClass() == "grave" then
		local nick = backpack_ent:GetStoredName()
		DzLog(3, "Player '"..self:Nick().."'("..self:SteamID()..") Looted "..ItemTable.Name.." x"..math.Round(amount).." from "..nick.."'s body" )
	else
		DzLog(3, "Player '"..self:Nick().."'("..self:SteamID()..") Looted "..ItemTable.Name.." x"..math.Round(amount).." from entity" )
	end
end
concommand.Add( "LootItem", function( ply, cmd, args ) 
	ply:LootItem( args[ 1 ], args[ 2 ], args[ 3 ], args[ 4 ] ) 
end )

net.Receive( "LootItem", function( len, ply )
	local item = net.ReadString()
	local amount = net.ReadInt( 32 )
	local backpack = net.ReadInt( 32 )
	local char = net.ReadBit()
	
	ply:LootItem( item, amount, backpack, char )
end )