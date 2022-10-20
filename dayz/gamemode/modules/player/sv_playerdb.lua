--GM = GM or GAMEMODE
util.AddNetworkString( "CharSelect" )
util.AddNetworkString( "ShopTable" )
util.AddNetworkString( "AliveChar" )
util.AddNetworkString( "PlayerPerks" )

function PMETA:UpdatePerks( ignoresql )
	self.PerkTable = {}
	
	if ignoresql then return end
	
	PLib:RunPreparedQuery({ sql = "SELECT `perk` FROM `players_perks` WHERE `user_id` = " .. self.ID .. ";", callback = function( data )
		for i = 1, #data do
			local perkid = data[ i ][ "perk" ]
			
			perkid = tonumber(perkid) or perkid
			if isnumber(perkid) then
				if perkid == 0 then continue end
				PLib:QuickQuery( "UPDATE `players_perks` SET `perk` = \"" .. GAMEMODE.DayZ_Items[ perkid ].ID .. "\" WHERE `user_id` = " .. self.ID .. " AND `perk` = \"" .. perkid .. "\";" )
				MsgC(Color(255,255,0), "Converted Perks for "..self:Nick().."\n")
				perkid = GAMEMODE.DayZ_Items[ perkid ].ID
			end

			self.PerkTable[ perkid ] = true
		end

		local tabl = self.PerkTable

		if self:IsVIP() && PHDayZ.VIPHasAllPerks then
			tabl = {}
			for k, v in pairs(GAMEMODE.DayZ_Items) do
				if v.Category == "perks" then
					tabl[ v.ID ] = true
				end
			end
		end

		net.Start("PlayerPerks")
			net.WriteTable(tabl)
		net.Send(self)

		if self:HasPerk("perk_gunking") then 
			if !self.hasallattachments then 
				for key, attData in ipairs(CustomizableWeaponry.registeredAttachments) do
					local name = attData.name

					CustomizableWeaponry:giveAttachment( self, name )
				end
				self.hasallattachments = true
			end
		end

	end })
end

function PMETA:UpdateBluePrints( ignoresql )

	self.BPTable = {}

	PLib:RunPreparedQuery({ sql = "SELECT `item` FROM `players_blueprints` WHERE `user_id` = " .. self.ID .. ";", 
	callback = function( data )
		for i = 1, #data do
			local item = data[ i ]
			local item_key = item[ "item" ]
			item_key = tonumber(item_key) or item_key
			local item_table = GAMEMODE.DayZ_Items[ item_key ]

			if item_table != nil then					
				self.BPTable[ item_key ] = true
			end
		end

		self:SendBluePrints()
	end })

end

/*
concommand.Add("dz_updatedb", function(ply, cmd, args)
	local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE, "dz_setupdb: Superadmin access required!") return end

	PHDayZ_UpdateDatabase()
end)
*/

function PHDayZ_UpdateDatabase()
	local x = 0
	/* 
	I have deprecated the updating from 5.3 -> 6.56 as there is nobody with the older databases. 
	If i am wrong, these queries exist for history below:

	-- 5.9 -> 6.0
	PLib:RunPreparedQuery({ sql = [[
		ALTER TABLE `players_inventory` ADD `quality` INT(100) NOT NULL DEFAULT '500' AFTER `amount`, ADD `durability` INT(100) NOT NULL DEFAULT '1' AFTER `quality`;
		ALTER TABLE `players_bank` ADD `quality` INT(100) NOT NULL DEFAULT '500' AFTER `amount`, ADD `durability` INT(100) NOT NULL DEFAULT '1' AFTER `quality`;
		ALTER TABLE `players_character` ADD `quality` INT(100) NOT NULL DEFAULT '500' AFTER `amount`, ADD `durability` INT(100) NOT NULL DEFAULT '1' AFTER `quality`;
	]]})
	
	-- 5.3+
	PLib:RunPreparedQuery({ sql = [[
		ALTER TABLE `players_bank` CHANGE `item` `item` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
	]]})
	
	PLib:RunPreparedQuery({ sql = [[
		ALTER TABLE `players_character` CHANGE `item` `item` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
	]]})
	
	PLib:RunPreparedQuery({ sql = [[
		ALTER TABLE `players_perks` CHANGE `perk` `perk` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
	]]}) 

	*/

	-- 6.56 + (permakills)
	if ( PHDayZ_OldConfigVer or 0 ) < 6.56 then
		MsgAll("[PHDayZ] Detected version < 6.56, upgrading database...")
		PLib:QuickQuery( "ALTER TABLE `players` ADD `deaths` INTEGER NOT NULL DEFAULT '0' AFTER `sickness`;" );
		PLib:QuickQuery( "ALTER TABLE `players` ADD `pkills` INTEGER NOT NULL DEFAULT '0' AFTER `deaths`;" );
		x = x + 1
	end

	if ( PHDayZ_OldConfigVer or 0 ) < 6.61 then
		MsgAll("[PHDayZ] Detected version < 6.61, upgrading database to 6.61...")
		PLib:QuickQuery( "ALTER TABLE `players_bank` ADD `foundtype` INTEGER NULL DEFAULT NULL AFTER `durability`, ADD `found_id` INTEGER NULL DEFAULT NULL AFTER `foundtype`;" );
		PLib:QuickQuery( "ALTER TABLE `players_character` ADD `foundtype` INTEGER NULL DEFAULT NULL AFTER `durability`, ADD `found_id` INTEGER NULL DEFAULT NULL AFTER `foundtype`;" );
		PLib:QuickQuery( "ALTER TABLE `players_inventory` ADD `foundtype` INTEGER NULL DEFAULT NULL AFTER `durability`, ADD `found_id` INTEGER NULL DEFAULT NULL AFTER `foundtype`;" );
		x = x + 1
	end

	if ( PHDayZ_OldConfigVer or 0 ) < 6.62 then
		MsgAll("[PHDayZ] Detected version < 6.62, upgrading database to 6.62...")
		PLib:QuickQuery( "ALTER TABLE `players` ADD `lastdeath` VARCHAR(256) NOT NULL DEFAULT '' AFTER `pkills`;" );
		PLib:QuickQuery( "ALTER TABLE `players` ADD `lastnick` VARCHAR(256) NULL DEFAULT NULL AFTER `lastdeath`;" );
		x = x + 1
	end

	if ( PHDayZ_OldConfigVer or 0 ) < 6.65 then
		MsgAll("[PHDayZ] Detected version < 6.65, upgrading database to 6.65...")
		PLib:QuickQuery( "ALTER TABLE `players_inventory` ADD `foundwhen` BIGINT NOT NULL DEFAULT '0' AFTER `found_id`;" )
		PLib:QuickQuery( "ALTER TABLE `players_bank` ADD `foundwhen` BIGINT NOT NULL DEFAULT '0' AFTER `found_id`;" )
		PLib:QuickQuery( "ALTER TABLE `players_character` ADD `foundwhen` BIGINT NOT NULL DEFAULT '0' AFTER `found_id`;" )
		x = x + 1
	end

	Msg("[PHDayZ] MySQL update check complete, "..x.." changes!\n")
end

/*
concommand.Add("dz_setupdb", function(ply, cmd, args)
	local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then ply:PrintMessage(HUD_PRINTCONSOLE, "dz_setupdb: Superadmin access required!") return end

	PHDayZ_SetupDatabase()
end)
*/

function PHDayZ_CheckDBSetup()
	if !PLib.MySQLActive then
		Msg("[PHDayZ] WARNING! MYSQL IS NOT CONNECTED. SETUP /DATA/PLIB/CONFIG.TXT AND RESTART!\n")
		return
	end

	Msg("[PHDayZ] Checking Database...\n")
	PLib:RunPreparedQuery({ sql = "SELECT 1 FROM `players` LIMIT 1", 
	callback = function( data )
		--PrintTable(data)
		if data == false or ( istable(data) and !data[1] ) then
			Msg("[PHDayZ] No data in database, running initial setup...\n")
			PHDayZ_SetupDatabase() -- connected but no data
		else
			Msg("[PHDayZ] Database detected as setup, checking version...\n")
			PHDayZ_UpdateDatabase() -- connected and data, update
		end
	end,
	onerror = function( e, sql )
		--Msg("GOTERROR: "..e)
		if string.find(e, "doesn't exist") or string.find(e, "no such table") then -- this quick hack of the century.
			Msg("[PHDayZ] Detected tables not existing, running initial setup...\n")
			PHDayZ_SetupDatabase() -- call setup!
		end
	end })

end
hook.Add("PLib_DatabaseConnected", "check_dz_database", PHDayZ_CheckDBSetup) -- this will call when the database is connected.

function PHDayZ_SetupDatabase()
	if !PLib.MySQLActive then
		--Msg("[PHDayZ] WARNING! MYSQL IS NOT CONNECTED. PLEASE SETUP DATA/PLIB/CONFIG.TXT PRIOR TO RUNNING THIS!\n")
		return
	end

	if _DatabaseSetup then
		Msg("[PHDayZ] Waiting on first player join...\n")
		return
	end

	Msg("[PHDayZ] Creating table `players`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`steamid` varchar(64) NOT NULL,
			`gender` tinyint(1) unsigned NOT NULL,
			`face` smallint(3) unsigned NOT NULL,
			`hat` smallint(3) unsigned NOT NULL,
			`clothes` smallint(3) unsigned NOT NULL,
			`alive` tinyint(1) unsigned NOT NULL,
			`health` smallint(4) unsigned NOT NULL,
			`thirst` smallint(4) unsigned NOT NULL,
			`hunger` smallint(4) unsigned NOT NULL,
			`xpos` int(10) NOT NULL,
			`ypos` int(10) NOT NULL,
			`zpos` int(10) NOT NULL,
			`mapindex` tinyint(3) unsigned NOT NULL,
			`xp` smallint(4) unsigned NOT NULL,
			`lvl` tinyint(3) unsigned NOT NULL,
			`kills` smallint(3) unsigned NOT NULL,
			`credits` int(10) unsigned NOT NULL,
			`extraslots` tinyint(3) unsigned NOT NULL,
			`realhealth` smallint(3) unsigned NOT NULL DEFAULT '100',
			`bleeding` smallint(3) unsigned NOT NULL DEFAULT '0',
			`sickness` smallint(3) unsigned NOT NULL DEFAULT '0',
			`deaths` int(100) NOT NULL DEFAULT '0',
			`pkills` int(100) NOT NULL DEFAULT '0',
			PRIMARY KEY (`id`),
			KEY `steamid` (`SteamID`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]]})

	Msg("[PHDayZ] Creating table `players_bank`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players_bank` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`user_id` int(10) unsigned NOT NULL,
			`item` text(64) NOT NULL,
			`amount` int(100) unsigned NOT NULL,
			`quality` int(11) NOT NULL DEFAULT '500',
			`durability` int(11) NOT NULL DEFAULT '1',
			PRIMARY KEY (`id`),
			KEY `user_id` (`user_id`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })

	Msg("[PHDayZ] Creating table `players_blueprints`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players_blueprints` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`user_id` int(10) unsigned NOT NULL,
			`item` text(64) NOT NULL,
			PRIMARY KEY (`id`),
			KEY `user_id` (`user_id`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })

	Msg("[PHDayZ] Creating table `players_character`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players_character` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`user_id` int(10) unsigned NOT NULL,
			`item` text(64) NOT NULL,
			`quality` int(11) NOT NULL DEFAULT '500',
			`durability` int(11) NOT NULL DEFAULT '1',
			PRIMARY KEY (`id`),
			KEY `user_id` (`user_id`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })
	
	Msg("[PHDayZ] Creating table `players_inventory`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players_inventory` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`user_id` int(10) unsigned NOT NULL,
			`item` text(64) NOT NULL,
			`amount` int(100) unsigned NOT NULL,
			`quality` int(11) NOT NULL DEFAULT '500',
			`durability` int(11) NOT NULL DEFAULT '1',
			PRIMARY KEY (`id`),
			KEY `user_id` (`user_id`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })

	Msg("[PHDayZ] Creating table `players_perks`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `players_perks` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`user_id` int(10) unsigned NOT NULL,
			`perk` text(64) NOT NULL,
			PRIMARY KEY (`id`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })

	-- 5.0.2 update
	Msg("[PHDayZ] Creating table `shop_inventory`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `shop_inventory` (
			`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			`item` varchar(64) NOT NULL,
			`amount` int(100) unsigned NOT NULL,
			PRIMARY KEY (`id`),
			KEY `item` (`item`)
		)
	DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]] })

	-- 6.2 skills
	Msg("[PHDayZ] Creating table `player_skills`...\n")
	PLib:RunPreparedQuery({ sql = [[
		CREATE TABLE IF NOT EXISTS `player_skills` (
		  `id` int(11) NOT NULL AUTO_INCREMENT,
		  `user_id` int(11) NOT NULL,
		  `intel` int(11) NOT NULL DEFAULT '0',
		  `end` int(11) NOT NULL DEFAULT '0',
		  `dex` int(11) NOT NULL DEFAULT '0',
		  `str` int(11) NOT NULL DEFAULT '0',
		  PRIMARY KEY (`id`)
		) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
	]]})

	Msg("[PHDayZ] MySQL Initial Setup Complete!\n")
	_DatabaseSetup = true -- Don't call this twice, relies on player data being in table, so a player must join otherwise this would be called multiple times.
end

function get_stats( ply, reqid )
	local mapindex = 0
	for k, v in pairs( MapIndex ) do
		if v == string.lower( game.GetMap() ) then
			mapindex = tonumber( k )
			break
		end
	end

	local alive = 1
	if ply.Dead == true then
		alive = 0
	end

	local stats = {
		ply.gender or 0,
		ply.face or 1,
		0,
		ply.clothes or 1,
		math.Clamp( ply:Health(), 0, ply:GetMaxHealth() ) or 100,

		ply:GetThirst() or 100,
		ply:GetHunger() or 100,
		alive or 0,
		ply:GetPos()[1],
		ply:GetPos()[2],

		ply:GetPos()[3],
		mapindex,
		ply:GetXP() or 0,
		ply:GetLevel() or 1,
		ply:Frags() or 0,

		ply:GetNWInt( "credits" ) or 0,
		ply:GetNWInt( "extraslots" ) or 0,
		math.Clamp(ply:GetRealHealth(), 0, 100) or 100,
		ply:GetBleed() and 1 or 0,
		ply:GetSick() and 1 or 0,
		ply:Deaths(),
		isfunction(ply.GetPFrags) and ply:GetPFrags() or 0,
		ply.LastDeathMsg or "",
		ply:Nick()
	}

	if reqid then
		table.insert(stats, ply.ID)
	end
	
	return stats
end

function save_player( ply, func )
	if !IsValid(ply) then return false end
	
	if ply.New or !ply.ID then return false end

	local ban = SIDBlacklist[ply:SteamID()]
	if ban then
		ply:Kick("You ("..ban.n..") are banned from GMod DayZ. Reason: "..ban.r)
		return false
	end

	--"UPDATE `players` SET `gender` = " .. stats[ 1 ] .. ", `face` = " .. stats[ 2 ] .. ", `hat` = " .. stats[ 3 ] .. ", `clothes` = " .. stats[ 4 ] .. ", `health` = " .. stats[ 5 ] .. ", `thirst` = " .. stats[ 6 ] .. ", `hunger` = " .. stats[ 7 ] .. ", `alive` = " .. stats[ 8 ] .. ", `xpos` = " .. stats[ 9 ].x .. ", `ypos` = " .. stats[ 9 ].y .. ", `zpos` = " .. stats[ 9 ].z .. ", `mapindex` = " .. stats[ 10 ] .. ", `xp` = " .. stats[ 11 ] .. ", `lvl` = " .. stats[ 12 ] .. ", `kills` = " .. stats[ 13 ] .. ", `credits` = " .. stats[ 14 ] .. ", `extraslots` = " .. stats[ 15 ] .. ", `realhealth` = ".. stats[ 16 ]..", `bleeding` = ".. stats[ 17 ]..", `sickness` = ".. stats[ 18 ].." WHERE `id` = " .. ply.ID .. ";"

	local stats = get_stats( ply, true )
	--PrintTable(stats)

	local query = string.format("UPDATE `players` SET `gender` = %s, `face` = %s, `hat` = %s, `clothes` = %s, `health` = %s, `thirst` = %s, `hunger` = %s, `alive` = %s, `xpos` = %s, `ypos` = %s, `zpos` = %s, `mapindex` = %s, `xp` = %s, `lvl` = %s, `kills` = %s, `credits` = %s, `extraslots` = %s, `realhealth` = %s, `bleeding` = %s, `sickness` = %s, `deaths` = %s, `pkills` = %s, `lastdeath` = \"%s\", `lastnick` = \"%s\" WHERE `id` = %s;", unpack(stats) )
	PLib:RunPreparedQuery({ sql = query, 
	callback = function( data )
		if isfunction( func ) then
			func()
		end
	end })

	if PHDayZ.DebugMode then
		print("[PHDayZ] Saved player data for "..ply:Nick())
	end
end

local function save_players()
	for k, v in pairs( player.GetAll() ) do
		if IsValid( v ) then
			save_player( v )
		end
	end
end
hook.Add("ShutDown", "save_players", save_players)

local function new_player( ply, func )
	local stats = get_stats( ply )
 	--"INSERT INTO `players` ( `steamid`, `gender`, `face`, `hat`, `clothes`, `health`, `thirst`, `hunger`, `alive`, `xpos`, `ypos`, `zpos`, `mapindex`, `xp`, `lvl`, `kills`, `credits`, `extraslots`, `realhealth`, `bleeding`, `sickness` ) VALUES ( '" .. ply:SteamID() .. "', " .. stats[ 1 ] .. ", " .. stats[ 2 ] .. ", " .. stats[ 3 ] .. ", " .. stats[ 4 ] .. ", " .. stats[ 5 ] .. ", " .. stats[ 6 ] .. ", " .. stats[ 7 ] .. ", " .. stats[ 8 ] .. ", " .. stats[ 9 ].x .. ", " .. stats[ 9 ].y .. ", " .. stats[ 9 ].z .. ", " .. stats[ 10 ] .. ", " .. stats[ 11 ] .. ", " .. stats[ 12 ] .. ", " .. stats[ 13 ] .. ", " .. stats[ 14 ] .. ", " .. stats[ 15 ] .. ", " .. stats[ 16 ] .. ", " .. stats[ 17 ] .. ", " .. stats[ 18 ] .. " );

	local query = string.format("INSERT INTO `players` ( `steamid`, `gender`, `face`, `hat`, `clothes`, `health`, `thirst`, `hunger`, `alive`, `xpos`, `ypos`, `zpos`, `mapindex`, `xp`, `lvl`, `kills`, `credits`, `extraslots`, `realhealth`, `bleeding`, `sickness`, `deaths`, `pkills`, `lastdeath`, `lastnick` ) VALUES ( '%s', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, \"%s\", \"%s\" );", ply:SteamID(), unpack(stats) )
	PLib:RunPreparedQuery({ sql = query, 
	callback = function( data )
		ply.ID = data
		ply.New = nil

		if isfunction( func ) then
			func()
		end
	end })
end

function player_defaults( ply, reset )

	if !IsValid(DZ_MENUCAM) then
		
		DZ_MENUCAM = ents.Create("dz_menucam")
		DZ_MENUCAM:SetPos(PHDayZ.MenuCamPos)
		DZ_MENUCAM:SetAngles(PHDayZ.MenuCamAngles)
		
	end

	ply.Loading = true
	ply:SetSick(false)
	ply:SetColor( Color(255, 255, 255, 255) ) -- They shouldn't be sick or some shit.
	ply.DeathMsg = nil -- because they respawned

	ply:SetBleed(false)
	ply:SetPArmor(0)
	
	ply:SetHealth( math.random(90, 100) )
	ply:SetMaxHealth( 100 )
	if ply.AntiViralist then
		ply:SetRealHealth( 125 )
		ply:SetMaxRealHealth( 125 )
	else
		ply:SetRealHealth( 100 )
		ply:SetMaxRealHealth( 100 )
	end
	
	ply:SetThirst( math.random(300, 600) )
	ply:SetHunger( math.random(300, 600) )
	

	local mapspawns = ents.FindByClass( "info_player_start" )
	local mappos
	if table.Count(mapspawns) > 0 then
		mappos = table.Random( mapspawns )
		mappos = mappos:GetPos() -- lazy!
		pos = mappos
	end
	if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
		pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
	end

	local initial = false
	if PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ] then
		ply:SetPos( PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ] )
	else
		print("[PHDayZ] WARNING! No InitialSpawn set, setup with dz_setinitialspawn")
		ply:SetPos( mappos )
	end
	
	if ply:IsInWorld() then
		ply:DropToFloorAlt()
	else
		local mapspawns = ents.FindByClass( "info_player_start" )
		if table.Count(mapspawns) > 0 then
			pos = table.Random( mapspawns )
			pos = pos:GetPos() -- lazy!
		end
		if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
			pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
		end
		MsgAll("[PHDayZ] WARNING!: InitialSpawn outside the map, requires update!")
		ply:SetPos(pos) -- not setup yet.
	end

	local time = PHDayZ.Player_FreshSpawnTime
	if ply:HasPerk("perk_freshforless") then
		time = time / 2
	end
	
	ply:SetFreshSpawn( CurTime() + time )
		
	if reset or ply:GetLevel() < 1 then
		ply:SetLevel( 0 )
	end
	
	if reset or ply:GetNWInt( "extraslots", 0 ) == 0 then
		ply:SetNWInt( "extraslots", 0 )
	end
	
	--ply:SetFrags( 0 )
	
	if reset or ply:GetNWInt( "credits", 0 ) == 0 then
		ply:SetNWInt( "credits", 0 )
	end

	ply:SetAdditionalWeight(0)
	
	-- if not reset then
		-- net.Start( "CharSelect" )
		-- net.Send( ply )
	-- end

	if ( ply.StartedControlling or 0 ) > CurTime() then return end

	ply:ConCommand("dz_menu")
	ply:SetViewEntity(DZ_MENUCAM) 
	
end

local function load_player( ply )
	ply.InvTable = {}
	ply.CharTable = {}
	ply.BackWeapons = {}
	ply.BankTable = {}

	ply.BPTable = {}
	ply.PerkTable = {}

	ply.Ready = ply.Ready or false
	ply:SetMaxHealth( 100 )

	local mapindex = table.KeyFromValue( MapIndex, 	string.lower(game.GetMap()) )
	PLib:RunPreparedQuery({ sql = "SELECT * FROM `players` WHERE `steamid` = '" .. ply:SteamID() .. "';", 
	callback = function( data )
		if !data or data[ 1 ] == nil then
			ply.New = true
			player_defaults( ply )

			net.Start("AliveChar")
				net.WriteBool(false)
				net.WriteString("")
			net.Send(ply)

		else
			data = data[ 1 ]
			
			ply.ID = data[ "id" ]

			hook.Call("DZ_LoadPlayer", GAMEMODE, ply)

			net.Start("AliveChar")
				net.WriteBool(tobool(data["alive"]))
				net.WriteString(data[ "lastdeath" ] or "")
			net.Send(ply)
			
			ply:SetLevel( tonumber( data[ "lvl" ] ) or 0 )
			
			ply:SetNWInt( "extraslots", tonumber( data[ "extraslots" ] ) or 0 )

			ply:SetDeaths( data[ "deaths" ] or 0 )
			ply:SetXP( tonumber( data[ "xp" ] ) or 0 )
			
			if tonumber( data[ "alive" ] ) == 0 then
				player_defaults( ply )
			else
				ply:Spectate( OBS_MODE_NONE )

				if !ply.Ready then
					--ply:UnLock() --incase
					ply:SetViewEntity(DZ_MENUCAM) 
					ply:KillSilent() 
					--return
				else 
					ply:SetViewEntity(ply) 

					ply:Spawn()
				end
							
				local pos = PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ]
				
				local mapspawns = ents.FindByClass( "info_player_start" )

				if table.Count(mapspawns) > 0 then
					pos = table.Random( mapspawns )
					pos = pos:GetPos() -- lazy!
				end

				if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
					pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
				end
				
				if PHDayZ.SafeZoneForceInitial && PHDayZ.SafeZoneSpawnEnabled then
					if PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] then
						ply:SetPos( PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] + Vector(0,0,10) )
					else
						MsgAll("[PHDayZ] ERROR! dz_setszteleportpos not set! Nowhere to teleport player!\n")
					end
				else
					if data[ "mapindex" ] != mapindex then
						if PHDayZ.SafeZoneSpawnEnabled then
							if PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] then
								ply:SetPos( PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] ) -- safezone
							else
								MsgAll("[PHDayZ] ERROR! dz_setszteleportpos not set! Nowhere to teleport player!\n")
							end
						else
							ply:SetPos( pos + Vector( 0, 0, 30 ) )
						end
					else
						ply:SetPos( Vector( tonumber( data[ "xpos" ] ), tonumber( data[ "ypos" ] ), tonumber( data[ "zpos" ] ) ) + Vector( 0, 0, 10 ) )

						timer.Simple(0.1, function() if !IsValid(ply) then return end if ply:IsInWorld() then ply:DropToFloorAlt() end end)
					end
				end

				local gender = tonumber( data[ "gender" ] )
				ply.gender = gender

				local face = tonumber( data[ "face" ] )
				ply.face = face
				--ply:SetNWInt( "hat", tonumber( data[ 5 ] ) )

				local clothes = tonumber( data[ "clothes" ] )
				ply.clothes = clothes

				ply:SetHealth( data[ "health" ] )
				if ply:Health() > ply:GetMaxHealth() then
					ply:SetHealth(ply:GetMaxHealth())
				end

				ply:SetThirst( tonumber( data[ "thirst" ] ) )
				ply:SetHunger( tonumber( data[ "hunger" ] ) )

				ply:SetFrags( tonumber( data[ "kills" ] ) )
				ply:SetPFrags( tonumber( data[ "pkills" ] ) ) -- permanent kills tracked
					

				ply:SetRPName( tostring( data[ "lastnick" ] ) or "" ) -- their last nickname while playing.

				--ply:SetNWInt( "credits", tonumber( data[ 18 ] ) )
				
				ply:SetRealHealth( data[ "realhealth" ] )
				
				ply:SetBleed( util.tobool(data[ "bleeding" ]) )
				ply:SetSick( util.tobool(data[ "sickness" ]) )

				ply:SetColor( Color(255, 255, 255, 255) ) -- They shouldn't be sick or some shit.

				ply:UpdateCharModel( face, clothes, gender )
				ply:SetAdditionalWeight(0)
				
				local col = ply:GetInfo( "cl_playercolor" )
				ply:SetPlayerColor( Vector( col ) )
			end

			PLib:RunPreparedQuery({ sql = "SELECT `id`, `item`, `amount`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` FROM `players_inventory` WHERE `user_id` = " .. ply.ID .. ";", 
			callback = function( data )
				if data then
					for i = 1, #data do
						local item = data[ i ]
						local item_id = tonumber(item[ "id" ])
						local item_key = item[ "item" ]
						local item_amount = tonumber(item[ "amount" ])
						local item_quality = tonumber(item[ "quality" ])
						local item_rarity = tonumber(item[ "durability" ])
						local item_foundtype = tonumber(item[ "foundtype" ])
						local item_foundid = tonumber(item[ "found_id" ])
						local item_foundwhen = tonumber(item[ "foundwhen" ])

						item_key = tonumber(item_key) or item_key
						if isnumber(item_key) then
							if item_key == 0 then continue end
							PLib:QuickQuery( "UPDATE `players_inventory` SET `item` = \"" .. GAMEMODE.DayZ_Items[ item_key ].ID .. "\" WHERE `user_id` = " .. ply.ID .. " AND `item` = \"" .. item_key .. "\";" )
							MsgC(Color(255,255,0), "Converted Items for "..ply:Nick().."\n")
							item_key = GAMEMODE.DayZ_Items[ item_key ].ID
						end
						local item_table = GAMEMODE.DayZ_Items[ item_key ]

						if item_quality == 0 then
							item_quality = math.random(100, 700) -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_inventory` SET `quality` = "..item_quality.." WHERE `id` = " .. item_id .. ";" )
						end
						if item_rarity > 8 or item_rarity < 1 then
							item_rarity = 1 -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_inventory` SET `durability` = "..item_rarity.." WHERE `id` = " .. item_id .. ";" )
						end

						-- 6.61 item ownership
						if !item_foundtype then
							item_foundtype = 1
							PLib:QuickQuery( "UPDATE `players_inventory` SET `foundtype` = 1 WHERE `id` = " .. item_id .. ";" )
						end

						if !item_foundid then
							item_foundid = ply.ID
							PLib:QuickQuery( "UPDATE `players_inventory` SET `found_id` = " .. item_foundid .. " WHERE `id` = " .. item_id .. ";" )
						end

						if !item_foundwhen or item_foundwhen == 0 then
							item_foundwhen = os.time()
							PLib:QuickQuery( "UPDATE `players_inventory` SET `foundwhen` = " .. item_foundwhen .. " WHERE `id` = " .. item_id .. ";" )
						end
						
						if item_table != nil then

							local item = {}
							item.id = item_id
							item.class = item_key
							item.amount = item_amount
							item.quality = item_quality
							item.rarity = item_rarity
							item.foundtype = item_foundtype
							item.found_id = item_foundid
							item.foundwhen = item_foundwhen

							ply.InvTable[ item_key ] = ply.InvTable[ item_key ] or {}
							ply.InvTable[ item_key ][ item_id ] = item
						end
					end
				end
				
				ply:UpdateItem()
			end })

			PLib:RunPreparedQuery({ sql = "SELECT `id`, `item`, `amount`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` FROM `players_bank` WHERE `user_id` = " .. ply.ID .. ";", 
			callback = function( data )

				if data then
					for i = 1, #data do
						local item = data[ i ]
						local item_id = tonumber(item[ "id" ])
						local item_key = item[ "item" ]
						local item_amount = tonumber(item[ "amount" ])
						local item_quality = tonumber(item[ "quality" ])
						local item_rarity = tonumber(item[ "durability" ])
						local item_foundtype = tonumber(item[ "foundtype" ])
						local item_foundid = tonumber(item[ "found_id" ])
						local item_foundwhen = tonumber(item[ "foundwhen" ])

						item_key = tonumber(item_key) or item_key
						if isnumber(item_key) then
							if item_key == 0 then continue end
							PLib:QuickQuery( "UPDATE `players_bank` SET `item` = \"" .. GAMEMODE.DayZ_Items[ item_key ].ID .. "\" WHERE `user_id` = " .. ply.ID .. " AND `item` = \"" .. item_key .. "\";" )
							MsgC(Color(255,255,0), "Converted Bank for "..ply:Nick().."\n")
							item_key = GAMEMODE.DayZ_Items[ item_key ].ID
						end
						local item_table = GAMEMODE.DayZ_Items[ item_key ]

						if item_quality == 0 then
							item_quality = math.random(100, 700) -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_bank` SET `quality` = "..item_quality.." WHERE `id` = " .. item_id .. ";" )
						end
						if item_rarity > 8 or item_rarity < 1 then
							item_rarity = 1 -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_bank` SET `durability` = "..item_rarity.." WHERE `id` = " .. item_id .. ";" )
						end

						-- 6.61 item ownership
						if !item_foundtype then
							item_foundtype = 1
							PLib:QuickQuery( "UPDATE `players_bank` SET `foundtype` = 1 WHERE `id` = " .. item_id .. ";" )
						end

						if !item_foundid then
							item_foundid = ply.ID
							PLib:QuickQuery( "UPDATE `players_bank` SET `found_id` = " .. item_foundid .. " WHERE `id` = " .. item_id .. ";" )
						end

						if !item_foundwhen or item_foundwhen == 0 then
							item_foundwhen = os.time()
							PLib:QuickQuery( "UPDATE `players_bank` SET `foundwhen` = " .. item_foundwhen .. " WHERE `id` = " .. item_id .. ";" )
						end

						if item_table != nil then

							local item = {}
							item.id = item_id
							item.class = item_key
							item.amount = item_amount
							item.quality = item_quality
							item.rarity = item_rarity
							item.foundtype = item_foundtype
							item.found_id = item_foundid
							item.foundwhen = item_foundwhen

							ply.BankTable[ item_key ] = ply.BankTable[ item_key ] or {}
							ply.BankTable[ item_key ][ item_id ] = item
						end
					end
				end

				ply:UpdateBank()
			end })
			
			PLib:RunPreparedQuery({ sql = "SELECT `id`, `item`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` FROM `players_character` WHERE `user_id` = " .. ply.ID .. ";", 
			callback = function( data )
				if data then
					for i = 1, #data do
						local item = data[ i ]
						local item_id = tonumber(item[ "id" ])
						local item_key = item[ "item" ]
						local item_quality = tonumber(item[ "quality" ])
						local item_rarity = tonumber(item[ "durability" ])
						local item_foundtype = tonumber(item[ "foundtype" ])
						local item_foundid = tonumber(item[ "found_id" ])
						local item_foundwhen = tonumber(item[ "foundwhen" ])

						item_key = tonumber(item_key) or item_key
						if isnumber(item_key) then
							if item_key == 0 then continue end
							PLib:QuickQuery( "UPDATE `players_character` SET `item` = \"" .. GAMEMODE.DayZ_Items[ item_key ].ID .. "\" WHERE `user_id` = " .. ply.ID .. " AND `item` = \"" .. item_key .. "\";" )
							MsgC(Color(255,255,0), "Converted Character for "..ply:Nick().."\n")
							item_key = GAMEMODE.DayZ_Items[ item_key ].ID
						end
						local item_table = GAMEMODE.DayZ_Items[ item_key ]

						if item_quality == 0 then
							item_quality = math.random(100, 700) -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_character` SET `quality` = "..item_quality.." WHERE `id` = " .. item_id .. ";" )
						end
						if item_rarity > 8 or item_rarity < 1 then
							item_rarity = 1 -- remove at some point. backwards compat 5.9-
							PLib:QuickQuery( "UPDATE `players_character` SET `durability` = "..item_rarity.." WHERE `id` = " .. item_id .. ";" )
						end

						-- 6.61 item ownership
						if !item_foundtype then
							item_foundtype = 1
							PLib:QuickQuery( "UPDATE `players_character` SET `foundtype` = 1 WHERE `id` = " .. item_id .. ";" )
						end

						if !item_foundid then
							item_foundid = ply.ID
							PLib:QuickQuery( "UPDATE `players_character` SET `found_id` = " .. item_foundid .. " WHERE `id` = " .. item_id .. ";" )
						end
						
						if !item_foundwhen or item_foundwhen == 0 then
							item_foundwhen = os.time()
							PLib:QuickQuery( "UPDATE `players_character` SET `foundwhen` = " .. item_foundwhen .. " WHERE `id` = " .. item_id .. ";" )
						end

						if item_table != nil then	

							local item = {}
							item.id = item_id
							item.class = item_key
							item.amount = 1
							item.quality = item_quality
							item.rarity = item_rarity
							item.foundtype = item_foundtype
							item.found_id = item_foundid
							item.foundwhen = item_foundwhen

							ply.CharTable[ item_key ] = ply.CharTable[ item_key ] or {}
							ply.CharTable[ item_key ][ item_id ] = item
						end
					end
				end
				ply:UpdateChar()

				-- Run the initial equip functions.
				if !ply.Dead then
					for class, items in pairs(ply.CharTable) do
						for _, item in pairs(items) do
							if GAMEMODE.DayZ_Items[class].EquipFunc then
								GAMEMODE.DayZ_Items[class].EquipFunc( ply, item, class )
							end
						end
					end
				end

				if ply.Ready then -- This function runs twice.
					ply:FillClips() -- let's be nice and auto-fill their clips (since they get emptied into inventory on disconnect)
				end
			end })

			ply:UpdatePerks()

			ply:UpdateBluePrints()
			
			if ply.UpdateSkills then ply:UpdateSkills() end

			if PHDayZ.DebugMode then
				print("[PHDayZ] Loaded player-data for "..ply:Nick())
			end
		end
	end })
end

local function spawn_loadout( ply )
	ply:Give( "weapon_emptyhands" )

	if ply:IsAdmin() then
		ply:Give( "weapon_physgun" )
		ply:Give("gmod_tool")
	end
end

local function spawn_defaults( ply )	
	ply:Spectate( OBS_MODE_NONE )
	ply:Spawn()
	ply:SetHealth( math.random(90, 100) )
	ply:SetMaxHealth( 100 )
	ply:SetRealHealth( 100 )
	ply:SetMaxRealHealth( 100 )
	ply:SetSick(false)
	ply:SetColor( Color(255, 255, 255, 255) ) -- They shouldn't be sick or some shit.
	ply:SetPArmor(0)

	if ply:Team() == TEAM_JOINING then ply:SetTeam( TEAM_NEUTRAL ) end

	ply:SetBleed(false)

	ply:SetPos( ply.SpawnPos )

	ply.SpawnPos = nil
		
	for k, v in pairs(PHDayZ.Player_SpawnItems) do
		ply:GiveItem( v.item, v.amt )
	end

	if EVENT_CHRISTMAS then
		ply:GiveItem("item_santahat", 1, true, 800, 7, nil, nil, true, true )
	end

	if ply:HasPerk("perk_violentbackground") then
		ply:GiveItem( "item_crowbar", 1, nil, nil, nil, nil, nil, true, true )
	end

	if ply:HasPerk("perk_enlightenment") then
		--ply:GiveItem( "item_flashlight", 1 )
	end
	
	local col = ply:GetInfo( "cl_playercolor" )
	ply:SetPlayerColor( Vector( col ) )

	if ply.CheckSkills then ply:CheckSkills(true) end
end

local function confirm_ready( ply, cmd, args )
	if ply:Team() == TEAM_JOINING then ply:SetTeam( TEAM_NEUTRAL ) end
	if !ply.Ready or !ply.Dead then
		ply.Ready = true
		
		if ply.Loading then

			local pos = PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ]
			local mapspawns = ents.FindByClass( "info_player_start" )

			if table.Count(mapspawns) > 0 then
				pos = table.Random( mapspawns )
				pos = pos:GetPos() -- lazy!
			end

			if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
				pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
			end
			
			if PHDayZ.SafeZoneSpawnEnabled then
				ply.SpawnPos = PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ]
			else
				ply.SpawnPos = pos + Vector( 0, 0, 30 )
			end

			if PHDayZ.SafeZoneSpawnEnabled && !PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] then 
				ply.SpawnPos = pos + Vector( 0, 0, 30 )
				MsgAll("[PHDayZ] ERROR! dz_setszteleportpos not set! Nowhere to teleport player!\n")
			end
			
			ply:SetPos( ply.SpawnPos )
			ply:SetViewEntity(ply)

			if ply.New == true then
				new_player( ply, function()	
					spawn_defaults( ply )
				end )
			else
				save_player( ply, function()
					spawn_defaults( ply )
				end )
			end
			--ply.Loading = nil
		elseif !ply:Alive() then
			load_player( ply )
		end

		ply:SetViewEntity(ply) -- incase it didnt run, this isn't 100%
		
		if !ply.mademenu then
			--ply:ConCommand("mainmenu_reload 1")

			ply.mademenu = true
		end

		hook.Call( "DZ_PlayerReady", GAMEMODE, ply )
	end
end
concommand.Add( "ConfirmReady", confirm_ready )

local function confirm_player( ply, cmd, args )
end
concommand.Add( "ConfirmCharacter", confirm_player )

function reset_ent( ply )
	ply:StripWeapons()	

	PLib:QuickQuery( "DELETE FROM `players_perks` WHERE `user_id` = " .. ply.ID .. ";" )
	ply:UpdatePerks( true )

	ply.InvTable = {}
	ply.BackWeapons = {}
	PLib:QuickQuery( "DELETE FROM `players_inventory` WHERE `user_id` = " .. ply.ID .. ";" )
	ply:UpdateItem()
	
	ply.BankTable = {}
	PLib:QuickQuery( "DELETE FROM `players_bank` WHERE `user_id` = " .. ply.ID .. ";" )
	ply:UpdateBank()

	ply.CharTable = {}	
	PLib:QuickQuery( "DELETE FROM `players_character` WHERE `user_id` = " .. ply.ID .. ";" )
	ply:UpdateChar()

	ply.BPTable = {}
	PLib:QuickQuery( "DELETE FROM `players_blueprints` where `user_id` = " .. ply.ID .. ";" )
	ply:SendBluePrints()

	ply:KillSilent()
	ply.Dead = true
	
	player_defaults( ply, true )

	local pos = PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ]
	local mapspawns = ents.FindByClass( "info_player_start" )
	
	if table.Count(mapspawns) > 0 then
		pos = table.Random( mapspawns )
		pos = pos:GetPos() -- lazy!
	end

	if table.Count( Spawns[ string.lower( game.GetMap() ) ] ) > 0 then
		pos = table.Random( Spawns[ string.lower( game.GetMap() ) ] )
	end
	
	ply.SpawnPos = pos + Vector( 0, 0, 30 )

	save_player( ply, function()
		spawn_defaults( ply )
	end )
end

local function reset_all_ent()
	for k, v in pairs( player.GetAll() ) do
		reset_ent( v )
	end
end

function reset_steamid( steamid )
	PLib:RunPreparedQuery({ sql = "SELECT `id` FROM `players` WHERE `steamid` = '" .. steamid .. "';", 
	callback = function( data )
		if data[ 1 ] then
			local id = data[ 1 ][ "id" ]

			MySQL:Query( "UPDATE `players` SET `health` = 100, `alive` = 0, `xp` = 0, `lvl` = 0, `kills` = 0, `credits` = 0 WHERE `id` = " .. id .. ";" )

			MySQL:Query( "DELETE FROM `players_perks` WHERE `user_id` = " .. id .. ";" )

			MySQL:Query( "DELETE FROM `players_inventory` WHERE `user_id` = " .. id .. ";" )

			MySQL:Query( "DELETE FROM `players_bank` WHERE `user_id` = " .. id .. ";" )

			MySQL:Query( "DELETE FROM `players_character` WHERE `user_id` = " .. id ..";" )
		end
	end })
end

function GM:PlayerInitialSpawn( ply )
	ply:SetPVPTime( 0 )

	ply:SetCustomCollisionCheck(true) -- For ShouldCollide rules.
	
	ply:SetTeam( TEAM_JOINING )
end

function GM:PlayerSpawn( ply )

	ply:SetMaxHealth(100)
	ply.DeathMsg = nil -- because they respawned
	ply.Noclip = false -- just in case they died in noclip (admin noobs)
	timer.Remove( ply:EntIndex().."_noclip" ) -- this for anti-esp.
	ply:ScreenFade(SCREENFADE.IN, color_black, 5, 1)
	
	local a = PHDayZ.Player_DefaultRunSpeed
	local b = PHDayZ.Player_DefaultWalkSpeed
	local c = PHDayZ.Player_DefaultJumpPower

	if ply:GetRunSpeed() != a then ply:SetRunSpeed( a ) end
	if ply:GetWalkSpeed() != b then	ply:SetWalkSpeed( b ) end
	if ply:GetJumpPower() != c then ply:SetJumpPower( c ) end

	ply.IronStomach = ply.IronStomach or false
	ply.Pickpocket = ply.Pickpocket or false
	ply.UndeadSlayer = ply.UndeadSlayer or false
		
	if !ply.BleedOutWin then
		
		ply:SetStamina( 100 )

		ply:SetPVPTime( 0 )
		ply.Drowning = 0
		
		ply:SetNWBool( "friendly", false )
				
		net.Start("AliveChar")
			net.WriteBool(!ply.Dead)
			net.WriteString(ply.LastDeathMsg or "")
		net.Send(ply)
				
		if ply.Dead == true then
			player_defaults( ply )

			ply.Dead = nil
		elseif ply.Loading == true then
			ply:Tip( 10, "Press [CONVAR] or F1 to open your inventory.", nil, "", nil, "cyb_invkey" )

			timer.Create( "Content_Tip", 8, 1, function()
				if IsValid( ply ) then
					ply:Tip( 3, "contentmissingtip", Color(255, 255, 0) )
				end
			end )
			
			timer.Create( "Donate_Tip", 16, 1, function()
				if IsValid( ply ) then
					ply:Tip( 3, "donatetip", Color(255, 255, 0) )	
				end
			end )

			ply.Loading = nil
		end

	end
		
	ply:SetupHands()

	if !ply.BleedOutWin then
		--ply:SetFrags( 0 )

		ply:SetHunger( math.random(300, 600) )
		ply:SetThirst( math.random(300, 600) )
	end

	if IsValid(ply.touchZ) then ply.touchZ:Remove() end
	--ply.touchZ = ents.Create("touchzone")
	--ply.touchZ:SetPos(ply:GetPos())
	--ply.touchZ:SetParent(ply)
	--ply.touchZ:Spawn()
	
	spawn_loadout(ply)

	-- if they die in the arena, endtouch will not run as they are dead, so...
	--ply:SetInArena(false)

	if !ply.BleedOutWin then
		--NetEffect(ply, "playerspawneffect")
	end
	
	if !ply.BleedOutWin then
		ply.grave = nil -- don't want this anymore.
	end

	ply.BleedOutWin = nil


	--ply:Lock()
	--timer.Simple(3, function() if IsValid(ply) then ply:UnLock() end end)
end

function GM:PlayerSetHandsModel( ply, ent )
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

function GM:PlayerAuthed( ply )
	ply.Loading = true
	
	local ban = SIDBlacklist[ply:SteamID()]
	if ban then
		MsgAll( ply:Nick().."["..ban.n.."] was kicked as they are banned: "..ban.r.."\n" )
		ply:Kick("You ("..ban.n..") are banned from GMod DayZ. Reason: "..ban.r)
		return
	end
	
	load_player( ply )
	ply:Spectate( OBS_MODE_NONE )
	
	--ply:SetPVPTime( 0 )
end

local function SaveStats( ply )
	if ply.NextDataSave and ( ply.NextDataSave > CurTime() ) then return end
	ply.NextDataSave = CurTime() + 60
	
	if ply.Loading or !ply.Ready or ply.Dead or !ply:Alive() then return end -- Don't save if they're dead, loading or otherwise!
	
	if ply:GetAFK() then ply:SetAFK(false) end
	
	save_player( ply )
end
hook.Add( "PlayerTick", "SaveStats", SaveStats )
hook.Add( "VehicleMove", "SaveStats", SaveStats )

local function DisconSave( ply )
	if !ply:IsValid() then return end
	if ply.Loading or !ply.Ready then return end

	save_player( ply )
end
hook.Add( "PlayerDisconnected", "SaveStats", DisconSave )
