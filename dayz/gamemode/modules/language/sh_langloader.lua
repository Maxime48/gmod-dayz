--GM = GM or GAMEMODE

function DayZ_IncludeLangFolder( folder )
	local files, folders = file.Find( folder .. "/*", "LUA" )
	for k, filename in pairs( files ) do
		local fullpath = folder .. "/" .. filename
		if SERVER then
			AddCSLuaFile( fullpath )

			if !PHDayZ.DisableStartupInfo then
				MsgC(Color(255,255,0), "[PHDayZ] Loaded lang file "..filename.."\n")
			end
		else
			include(fullpath)
		end
	end

	for k, v in pairs( folders ) do
		DayZ_IncludeLangFolder( folder .. "/" .. v )
	end
end

hook.Add("PostGamemodeLoaded", "DayZ_LoadLangs", function()

	DayZ_IncludeLangFolder( engine.ActiveGamemode().."/gamemode/modules/language/lang" )
	DayZ_IncludeLangFolder( "lang" ) -- Custom Level support from addons :)

	hook.Run( "DayZ_LangsLoaded" )
end)

hook.Add( "OnReloaded", "DayZ_LoadLangs", function( )
	DayZ_IncludeLangFolder( engine.ActiveGamemode().."/gamemode/modules/language/lang" )
	DayZ_IncludeLangFolder( "lang" ) -- Custom Lang support from addons :)

	hook.Run( "DayZ_LangsLoaded" )

	if CLIENT then LANG.Init() end
end )
