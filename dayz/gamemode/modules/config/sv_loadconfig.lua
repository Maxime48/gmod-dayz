util.AddNetworkString( "PHDayZ_ConfigUpdate" )
util.AddNetworkString( "PHDayZ_ServerErrors" )

PHDayZ_OldConfigVer = PHDayZ_OldConfigVer or PHDayZ.version
local function LoadConfig()

	if !file.Exists("dayz/config.txt", "DATA") then
		file.Write("dayz/config.txt", util.TableToJSON(PHDayZ, true))
		Msg("======================================================================\n")
		MsgC(Color(255,255,0), "[PHDayZ]", Color(255,255,255)," No config file was detected. Default values have been applied and file has been created.\n")
		Msg("======================================================================\n")
	else
		local config = util.JSONToTable(file.Read("dayz/config.txt", "DATA"))
		
		if not istable(config) then
			MsgC(Color(255,0,0), "[PHDayZ] Config file failed to load, check consistency! Using defaults...\n")
			table.insert(PHDayZ_StartUpErrors, "Config file failed to load, check file consistency! Using defaults...")
			return
		end
		
		if config.version < PHDayZ.version then 
			Msg("======================================================================\n")
			MsgC(Color(255,255,0), "[PHDayZ] Config file v"..config.version.." out of date! Updating this for you...\n")

			PHDayZ_OldConfigVer = config.version
			config.version = PHDayZ.version

			for k, v in SortedPairs(PHDayZ) do
				if (config[k] == nil) then
					MsgC(Color(255,255,0), "[PHDayZ] ", Color(255,255,255), string.format("Adding Config Option: %s = %s (Not Found)\n", k, v ) );
					config[k] = v;
				end
			end

			file.Write("dayz/config.txt", util.TableToJSON(config, true))
			MsgC(Color(0,255,0), "[PHDayZ] Config file successfully updated to v"..config.version.."!\n")
			Msg("======================================================================\n")
		else
			Msg("======================================================================\n")	
			MsgC(Color(255,255,0), "[PHDayZ] Loading found Config file...\n")
			for k, v in SortedPairs(PHDayZ) do
				if (config[k] == nil) then
					MsgC(Color(255,255,0), "[PHDayZ] ", Color(255,255,255), string.format("Re-adding Config Option: %s = %s (Not Found)\n", k, v ) );
					config[k] = v;
				end
			end
			
			PHDayZ = config

			file.Write("dayz/config.txt", util.TableToJSON(config, true))
			MsgC(Color(0,255,0), "[PHDayZ]", " Config file v"..config.version.." loaded!\n")
			Msg("======================================================================\n")		
		end

		-- Lets make sure if you change these options, that the new ones are sent to the client properly...

		resource.AddFile("materials/"..PHDayZ.hungermaterial)
		resource.AddFile("materials/"..PHDayZ.thirstmaterial)
		
		for k, v in pairs(PHDayZ.TipIcons) do
			resource.AddFile("materials/"..v)
		end

	end

end
hook.Add("DZ_InitialLoad", "LoadConfig", LoadConfig)

local function RequestConfig(ply, cmd, args)
	if ( ply.NextConfigRequest or 0 ) > CurTime() then return end

	net.Start( "PHDayZ_ConfigUpdate" )
		net.WriteTable( PHDayZ )
	net.Send(ply)

	ply.NextConfigRequest = CurTime() + 5
	ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Config Request Sent.")
end
concommand.Add("dz_requestconfig", RequestConfig)
	
local function RefreshConfig(ply)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.
	Msg("======================================================================\n")
	MsgAll("[PHDayZ] Reloading Config...\n")
	
	local config = util.JSONToTable(file.Read("dayz/config.txt", "DATA"))
	
	if not istable(config) then
		MsgAll("[PHDayZ] Config file failed to load, check consistency! Using defaults...\n")
		return
	end
	
	PHDayZ = config
	
	--PrintTable(PHDayZ)
	
	net.Start( "PHDayZ_ConfigUpdate" )
		net.WriteTable( PHDayZ )
	net.Broadcast()
	Msg("======================================================================\n")
	
    if PHDayZ.scoreboardtitle != GetConVarString("hostname") then
        if PHDayZ.scoreboardhostname then
            Msg("Changing server hostname...\n")
            RunConsoleCommand("hostname", PHDayZ.scoreboardtitle)
        end
    end

end
concommand.Add("dz_reloadconfig", RefreshConfig)

hook.Add("OnReloaded", "ResendConfig", function()
	MsgAll("[PHDayZ] Resending Config due to Auto-Refresh event!\n")
	RefreshConfig( Entity(0) )
end)

local function SendConfig(ply)
	if !ply:IsValid() then return end
		
	if #PHDayZ_CriticalErrors > 0 then
		net.Start("PHDayZ_ServerErrors")
			net.WriteTable(PHDayZ_CriticalErrors)
		net.Send(ply)
	end

	net.Start( "PHDayZ_ConfigUpdate" )
		net.WriteTable( PHDayZ )
	net.Send( ply )
end
hook.Add("PlayerInitialSpawn", "UpdateConfig", SendConfig)
hook.Add("PlayerAuthed", "UpdateConfig", SendConfig)