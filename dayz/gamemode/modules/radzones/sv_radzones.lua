RadZoneTbl = {}

Msg("======================================================================\n")
file.CreateDir("dayz/radzones")

if !file.Exists("dayz/radzones/"..string.lower(game.GetMap())..".txt", "DATA") then
	file.Write("dayz/radzones/"..string.lower(game.GetMap())..".txt", util.TableToJSON( {} ) )
	MsgC(Color(255,255,0), "[PHDayZ] No radzone file was detected. Empty file has been created.\n")
else

	local config = util.JSONToTable( file.Read("dayz/radzones/"..string.lower(game.GetMap())..".txt", "DATA") )
	
	if not istable(config) then
		--MsgC(Color(255,0,0), "[PHDayZ] Safezones spawntype '"..v.."' failed to load, check consistency!")
		table.insert(PHDayZ_StartUpErrors, "RadZones failed to load, check file consistency!")
		return
	end
		
	RadZoneTbl = config
	MsgC(Color(0, 255, 0), "[PHDayZ] RadZones found and loaded!\n")
end
Msg("======================================================================\n")

local function ReloadRadzones(ply, cmd, args)
	if ply:EntIndex() != 0 and !ply:IsAdmin() then return end -- If it's ran from command.
	if ply:EntIndex() != 0 then
		MsgC(Color(255,255,0), "[NOTICE] "..ply:Nick().." has reloaded the RadZones data!\n")
	end
	
	if file.Size("dayz/radzones/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
		MsgAll("[PHDayZ] RadZones spawntype '"..v.."' not yet setup!\n")
	else
	
		local config = util.JSONToTable( file.Read("dayz/radzones/"..string.lower(game.GetMap())..".txt", "DATA") )
	
		if not istable(config) then
			MsgC(Color(255,0,0), "[PHDayZ] RadZones failed to load, check consistency!\n")
			return
		end
			
		RadZoneTbl = config
		MsgAll("[PHDayZ] RadZones found and loaded!\n")
	end
	
	MsgAll("[PHDayZ] RadZones have been reloaded.\n")

	SpawnTheRZ()
end
concommand.Add("dz_reloadradzones", ReloadRadzones)

function SpawnTheRZ()
	Msg("======================================================================\n")

	MsgC(Color(0,255,0), "[PHDayZ] Calling PostGamemodeLoaded->RadZone Setup!\n\n" )

	for k,v in pairs(ents.GetAll()) do if v:GetClass() == "radzone" then v:Remove() end end

	for k, v in pairs(RadZoneTbl) do
		local radzone = ents.Create("radzone")
		radzone:SetMinWorldBound(v.spos)
		radzone:SetMaxWorldBound(v.epos)
		radzone:Spawn()
		radzone:Activate()
	end
	MsgC(Color(0,255,0), "[PHDayZ] Radzones spawned successfully!\n")
end
hook.Add( "DZ_FullyLoaded", "SpawnTheRZ", SpawnTheRZ )
