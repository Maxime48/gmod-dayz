include( 'shared.lua' )

function GM:Initialize()
   MsgN("DayZ Client initializing...")

   LANG.Init()
end

function GM:InitPostEntity()
   MsgN("DayZ Client post-init...")

   RunConsoleCommand("_dz_request_serverlang")
end

-- Load modules..
modules_loaded = modules_loaded or false
local function LoadModules()
	--if modules_loaded then return end -- autorefresh aids.

	local root = GM.FolderName.."/gamemode/modules/"
	include(root.."config/sh_config.lua")

	local _, folders = file.Find(root.."*", "LUA")
	
	if !PHDayZ.DisableStartupInfo then
		MsgC( Color(255,0,255), "[PHDayZ] Legend: ", Color(0,255,255), "Server ", Color(147,112,219), "Shared ", Color(255,165,0), "Client\n" )
		Msg("======================================================================\n")
	end

	for _, folder in SortedPairs(folders, true) do
		if folder == "." or folder == ".." then continue end
	
		for _, File in SortedPairs(file.Find(root .. folder .."/sh_*.lua", "LUA"), true) do
			
			if !PHDayZ.DisableStartupInfo then
				MsgC( Color(255,255,0), "[PHDayZ] Loading SHARED file: " .. File .. "\n" )
			end

			include(root.. folder .. "/" ..File)
		end

		if !PHDayZ.DisableStartupInfo then
			Msg("======================================================================\n")
		end
	end
	
	for _, folder in SortedPairs(folders, true) do
		for _, File in SortedPairs(file.Find(root .. folder .."/cl_*.lua", "LUA"), true) do
			
			if !PHDayZ.DisableStartupInfo then
				MsgC( Color(0,255,255), "[PHDayZ] Loading CLIENT file: " .. File .. "\n" )
			end

			include(root.. folder .. "/" ..File)
		end

		if !PHDayZ.DisableStartupInfo then
			Msg("======================================================================\n")
		end

	end

	if !PHDayZ.DisableStartupInfo then
		MsgC( Color(255,0,255), "[PHDayZ] Legend: ", Color(0,255,255), "Server ", Color(255,255,0), "Shared ", Color(255,100,0), "Client\n" )
	end

	hook.Add("InitPostEntity", "zWelcomeTo", function()
		timer.Simple(3, function()
			Msg("\n")
			MsgC(Color(255,255,0), [[	```___```````````___Welcome To: _____]]) Msg("\n")
			MsgC(Color(255,255,0), [[	``/`_`\ /\/\````/```\__`_`_```_/`_``/]]) Msg("\n")
			MsgC(Color(255,255,0), [[	`/`/_\//````\``/`/\`/`_``|`|`|`\//`/`]]) Msg("\n")
			MsgC(Color(255,255,0), [[	/`/_\\/`/\/\`\/`/_//`(_|`|`|`|`|/`//\]]) Msg("\n")
			MsgC(Color(255,255,0), [[	\____/\/````\/____/ \__,_|\__,`/____/]]) Msg("\n")	
			MsgC(Color(255,255,0), [[	````Made by Phoenixf129```|___/ v]] .. PHDayZ.version)
			Msg("\n\n")

			hook.Run("DZ_FullyLoaded")
			modules_loaded = true
		end)


		hook.Remove("CalcViewModelView", "prone.ViewTransitions") -- reasons.
		hook.Remove("CalcView", "prone.ViewTransitions")
		hook.Remove("HUDShouldDraw", "CW_HUDShouldDraw") -- no

	end)

	hook.Remove("HUDShouldDraw", "CW_HUDShouldDraw") -- no

	hook.Run("DZ_InitialLoad")

	hook.Run("DZ_PostInitialLoad")

	if !PHDayZ.DisableStartupInfo then
		MsgC(Color(0,255,0), "[PHDayZ] Loading Complete!\n")
	end
end

if prone then
	RunConsoleCommand("prone_bindkey_enabled", "0")
end

--if !modules_loaded then
	LoadModules()
--end