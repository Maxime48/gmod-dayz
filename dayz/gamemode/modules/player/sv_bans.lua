DayZ_WeaponBans = {}
DZ_Supporters = DZ_Supporters or {}

-- Please do not modify this. Use your Admin Mod to ban people!
SIDBlacklist = SIDBlacklist or {}

function PMETA:IsWepBanned()
	if table.HasValue(DayZ_WeaponBans, self:SteamID()) then self:ChatPrint("You are banned from using weapons.") return true end
	return false
end

local function GetBans()
    if (nextBansUpdate or 0) > CurTime() then return end
    if !PHDayZ.UseCheatBanlist then return end

    http.Fetch("http://gmoddayz.net/api.php?type=1&server="..GetConVarString("hostport"),
        function(body, len, headers, code)
            if string.len(body) > 0 then
                local bans = util.JSONToTable( body )

                if istable(bans) then
                	SIDBlacklist = bans

                    for k, v in pairs(player.GetAll()) do
                        if SIDBlacklist[v:SteamID()] then
                            v:Kick("You have been globally convicted for cheating on GMod DayZ.")
                        end
                    end
                end
            end
        end
    )

    nextBansUpdate = CurTime() + 300
end
hook.Add("Think", "GetBans", GetBans)

local function GetSupporters()
    if (nextSupporterUpdate or 0) > CurTime() then return end
    if !PHDayZ.ScoreboardShowSupporters then return end

    http.Fetch("http://gmoddayz.net/api.php?type=2&server="..GetConVarString("hostport"),
        function(body, len, headers, code)
            if string.len(body) > 0 then
                local supporters = util.JSONToTable( body )

                if istable(supporters) then
                	DZ_Supporters = supporters
                end
            end
        end
    )

    nextSupporterUpdate = CurTime() + 300
end
hook.Add("Think", "GetSupporters", GetSupporters)

util.AddNetworkString("supporter_Tags")
function sendSupporters(ply)
	
	net.Start("supporter_Tags")
		net.WriteTable(DZ_Supporters)
	net.Send(ply)

end
hook.Add("PlayerInitialSpawn", "sendSupporters", sendSupporters)