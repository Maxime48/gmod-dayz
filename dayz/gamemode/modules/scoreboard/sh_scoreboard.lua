
DZ_Supporters = DZ_Supporters or {}

net.Receive("supporter_Tags", function(len)
   DZ_Supporters = net.ReadTable()
end)

local fol = GM.FolderName.."/gamemode/modules/scoreboard/"

if SERVER then

	AddCSLuaFile()

	AddCSLuaFile(fol.."override_score.lua")

	AddCSLuaFile(fol.."main_score.lua")
	AddCSLuaFile(fol.."team_score.lua")
	AddCSLuaFile(fol.."row_score.lua")
	AddCSLuaFile(fol.."info_score.lua")
	
	return
end

hook.Add("OnReloaded", "loadScoreboard", function()

	include(fol.."override_score.lua")

end)

hook.Add("PostGamemodeLoaded", "LoadScoreboard", function()

	timer.Simple(3, function()

		include(fol.."override_score.lua")

	end)

end)