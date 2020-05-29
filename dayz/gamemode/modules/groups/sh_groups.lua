/////////////////////////////////////////////
//////////////// DayZ Groups ////////////////
/////////////////////////////////////////////
////////// Created by my_hat_stinks /////////
/////////////////////////////////////////////
// sh_groups.lua                    SHARED //
//                                         //
// Handles all shared group stuff.         //
/////////////////////////////////////////////

TEAM_SOLO = 1
team.tblLeaders = team.tblLeaders or {}

//
// Setup
local function CreateTeams()
	team.SetUp( TEAM_SOLO, "Neutral", Color( 150, 150, 150 ), true )
	
	return true
end
hook.Add( "CreateTeams", "DayZGroups SetupTeams", CreateTeams)

//
// Invite
function team.IsInvited( tm, ply )
	if tm==TEAM_SOLO then return true end
	
	return ply.DayzGroup_TeamInvites and ply.DayzGroup_TeamInvites[tm] and (ply.DayzGroup_TeamInvites[tm]>CurTime())
end

//
// Leaders
function team.GetLeader( tm )
	if tm==TEAM_SOLO then return end
	if team.NumPlayers(tm)==0 then return end
	
	local leader = team.tblLeaders[tm]
	if IsValid(leader) and leader:Team()==tm then return leader end
	
	if CLIENT then return end
	
	local newLeader = table.Random( team.GetPlayers(tm) )
	if IsValid(newLeader) then
		team.SetLeader( tm, newLeader )
		
		return newLeader
	end
end
function team.IsLeader( tm, ply )
	return ply==team.GetLeader(tm)
end

//
// Team variable updates
function team.UpdateColor( tm, col )
	team.SetUp( tm, team.GetName( tm ), col, team.Joinable( tm ) )
end
function team.UpdateName( tm, name )
	team.SetUp( tm, tostring(name), team.GetColor( tm ), team.Joinable( tm ) )
end
function team.UpdateJoinable( tm, joinable )
	team.SetUp( tm, team.GetName( tm ), team.GetColor( tm ), tobool(joinable) )
end

//
// GetAll
oGetAllTeams = oGetAllTeams or team.GetAllTeams
function team.GetAllTeams()
	local tbl = oGetAllTeams()
	local ret = {}
	
	for k,v in pairs(tbl) do
		if team.NumPlayers(k)>0 or k>255 then
			ret[k] = tbl[k]
			if k>1 and k<256 then
				local lead = team.GetLeader(k)
				if (not IsValid(lead)) or lead:Team()~=k then
					if CLIENT then continue end
					
					team.SetLeader( k, table.Random( team.GetPlayers(k) ) )
					lead = team.GetLeader( k )
				end
				ret[k].Leader = lead
			end
		end
	end
	
	// Defaults
	ret[TEAM_CONNECTING] = tbl[TEAM_CONNECTING] // 0
	ret[TEAM_SOLO] = tbl[TEAM_SOLO] // 1
	ret[TEAM_UNASSIGNED] = tbl[TEAM_UNASSIGNED] // 1001
	ret[TEAM_SPECTATOR] = tbl[TEAM_SPECTATOR] // 1002
	ret[TEAM_JOINING] = tbl[TEAM_JOINING] // 256

	return ret
end
