GM = GM or GAMEMODE

GM.DayZ_Items = GM.DayZ_Items or {}

function DayZ_LoadItem( filepath, filename, category )
	local fileName = string.StripExtension( filename )
	category = string.gsub( category, GAMEMODE.FolderName.."/gamemode/modules/items/", "")
	category = string.gsub( category, "items", "")
	category = string.gsub( category, "/", "")
	category = string.Trim(category)

	if category == "" then category = nil end
	
	local itemID = fileName
	--Set up the environment for the function
	local environment = {}
	--make it accessible via ITEM
	environment.ITEM = {}
	setmetatable( environment, { __index = _G } ) --make sure that func can access the real _G

	local func = CompileFile( filepath )
	if not func then
		--MsgC(Color(255,0,0), "[PHDayZ] Couldn't load item file "..fileName)
		if SERVER then
			table.insert(PHDayZ_StartUpErrors, "Couldn't load item file "..fileName)
		end
		GAMEMODE.DayZ_Items[itemID] = nil -- remove the class
		return
	end

	setfenv( func, environment ) -- _G for func now becomes environment
	func( )
	
	GAMEMODE.DayZ_Items[itemID] = environment.ITEM
	GAMEMODE.DayZ_Items[itemID].ID = itemID
	
	GAMEMODE.DayZ_Items[itemID].Category = environment.ITEM.Category or category
	if GAMEMODE.DayZ_Items[itemID].Category == "" then GAMEMODE.DayZ_Items[itemID].Category = nil end

	if !environment.ITEM.Rarity then
		GAMEMODE.DayZ_Items[itemID].Rarity = 1 -- common.
	end

	if !environment.ITEM.LevelReq then
		GAMEMODE.DayZ_Items[itemID].LevelReq = 0 -- Default
	end
end

function DayZ_IncludeFolder( folder )
	local files, folders = file.Find( folder .. "/*", "LUA" )
	for k, filename in pairs( files ) do
		local fullpath = folder .. "/" .. filename
		if SERVER then
			AddCSLuaFile( fullpath )
			include(fullpath)
			if !PHDayZ.DisableStartupInfo then
				MsgC(Color(255,255,0), "[PHDayZ] Loaded item file "..filename.."\n")
			end
		end
		DayZ_LoadItem( fullpath, filename, folder )
	end

	for k, v in pairs( folders ) do
		DayZ_IncludeFolder( folder .. "/" .. v )
	end
end

function ReloadAllItems()
	GAMEMODE.DayZ_Items = {}

	Msg("[PHDayZ] Loading items...\n")
	
	DayZ_IncludeFolder( GAMEMODE.FolderName.."/gamemode/modules/items/items" )
	DayZ_IncludeFolder( "items" ) -- Custom Item support from addons :)
	
	hook.Run( "DayZ_ItemsLoaded" )
end

hook.Add("InitPostEntity", "DayZ_LoadItems", function()
	--timer.Simple(0.1, function()
		ReloadAllItems()
	--end)
end)

/*ItemD = ItemD or false
hook.Add("DZ_FullyLoaded", "DayZ_LoadItems", function()
	if !ItemD then
		ItemD = true
		ReloadAllItems()
	end
end)*/

hook.Add("DayZ_ItemsLoaded", "PrintItems", function()
	MsgC(Color(0,255,0), "[PHDayZ] Loaded "..table.Count(GAMEMODE.DayZ_Items).." items!\n")
end)

hook.Add( "OnReloaded", "DayZ_LoadItems", function( )
	--ReloadAllItems()
end )

if SERVER then
	concommand.Add("dz_reloaditems", function(ply, cmd, args)
		if !ply:IsSuperAdmin() then return false end

		MsgC(Color(0,255,0), "[PHDayZ] Reloading items...\n")
		ReloadAllItems()

		for k, v in pairs(player.GetAll()) do
			v:SendLua([[ReloadAllItems()]]) -- lazy.
		end

	end)
end