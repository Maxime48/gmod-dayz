/////////////////////////////////////////////
//////////////// DayZ Groups ////////////////
/////////////////////////////////////////////
////////// Created by my_hat_stinks /////////
/////////////////////////////////////////////
// sv_groups.lua                    SERVER //
//                                         //
// Handles all server group stuff.         //
/////////////////////////////////////////////

//
// Networking
util.AddNetworkString( "DayZGroups_UpdateTeamColor" )
util.AddNetworkString( "DayZGroups_UpdateTeamName" )
util.AddNetworkString( "DayZGroups_UpdateTeamJoinable" )

util.AddNetworkString( "DayZGroups_FullTeamUpdate" )

util.AddNetworkString( "DayZGroups_TeamInvite" )
util.AddNetworkString( "DayZGroups_UpdateTeamLeaders" )

util.AddNetworkString( "DayZGroups_JoinTeam" )
util.AddNetworkString( "DayZGroups_LeaveTeam" )

util.AddNetworkString( "DayZGroups_TeamJoined" )

TEAM_SOLO = TEAM_NEUTRAL -- lazy ass

//
// CanJoin
local function PlayerCanJoinTeam( ply, tm )
	return (tm==TEAM_SOLO) or (team.NumPlayers(tm)==0) or team.Joinable(tm) or team.IsInvited( tm, ply )
end
hook.Add( "PlayerCanJoinTeam", "DayZGroups CanJoin", PlayerCanJoinTeam)

//
// RequestTeam
local function PlayerRequestTeam( ply, tm )
	if tm<1 or tm>255 then
		ply:Tip( 3, "invalidgroup" )
		return
	end
	
	if (team.NumPlayers(tm)>0) and not (team.Joinable( tm ) or team.IsInvited( tm, ply )) then
		ply:Tip( 3, "nogroupinvite" )
		return false
	end
	
	if not hook.Call( "PlayerCanJoinTeam", GAMEMODE, ply, tm ) then
		ply:Tip( 3, "cantjoingroup" )
		return false
	end
	
	hook.Call( "PlayerJoinTeam", GAMEMODE, ply, tm )
	
	return true
end
hook.Add( "PlayerRequestTeam", "DayZGroups RequestTeam", PlayerRequestTeam)

function GM:OnPlayerChangedTeam( ply, oldteam, newteam ) -- override

	if newteam == TEAM_NEUTRAL then
		PrintMessage( HUD_PRINTTALK, Format( "%s has left '%s'", ply:Nick(), team.GetName( oldteam ) ) )
	else
		local word = "joined"
		if team.NumPlayers(newteam) <= 1 then
			word = "created"
		end
		PrintMessage( HUD_PRINTTALK, Format( "%s has %s '%s'", ply:Nick(), word, team.GetName( newteam ) ) )
	end

end

concommand.Remove("changeteam") -- because fuck this concommand.

//
// JoinTeam
local function PlayerJoinTeam( ply, tm )
	local oldTeam = ply:Team()
	local isLeader = team.IsLeader(oldTeam, ply)
	
	ply:SetTeam( tm )
	ply.LastTeamSwitch = RealTime()
	
	hook.Call( "OnPlayerChangedTeam", GAMEMODE, ply, oldTeam, tm )
	
	if isLeader and team.NumPlayers(oldTeam)>0 and oldTeam>1 and oldTeam<=255 then
		team.SetLeader( oldTeam, table.Random( team.GetPlayers(oldTeam) ) )
	end

	net.Start( "DayZGroups_TeamJoined" )
		net.WriteUInt( tm, 8 )
	net.Send( ply )
	
	return true
end
hook.Add( "PlayerJoinTeam", "DayZGroups JoinTeam", PlayerJoinTeam)
//
// Create Team
function team.Create()
	for i=2,math.min(#player.GetAll()+1, 255) do
		if team.NumPlayers(i)>0 then continue end
		
		team.UpdateName( i, "Group #"..tostring(i-1) )
		team.UpdateColor( i, Color( math.random(100,200),math.random(100,200),math.random(100,200) ) )
		team.UpdateJoinable( i, false )
		
		team.SendFullUpdate( i )
		
		return i
	end
	
	return false
end
local function CreateTeam( ply, name )
	if not IsValid(ply) then return end
	
	local tm = team.Create()
	if not tm then
		ply:Tip( 3, "cantmakegroup" )
		return
	end

	team.SetName( tm, name )
	
	hook.Call( "PlayerJoinTeam", GAMEMODE, ply, tm )
	if ply:Team()~=tm then ply:Tip( 3, "failedgroup" ) end
	
	timer.Simple(0, function() team.SetLeader( tm, ply ) end)

	net.Start( "DayZGroups_TeamJoined" )
		net.WriteUInt( tm, 8 )
	net.Send( ply )
end
concommand.Add( "dz_makegroup", function(p,c,a) CreateTeam(p, a[1]) end)

//
// Invite
function team.Invite( tm, ply )
	if tm==TEAM_SOLO then return end
	
	ply.DayzGroup_TeamInvites = ply.DayzGroup_TeamInvites or {}
	
	ply.DayzGroup_TeamInvites[ tm ] = CurTime()+30
	
	net.Start( "DayZGroups_TeamInvite" )
		net.WriteUInt( tm, 8 )
		net.WriteFloat( CurTime()+30 )
	net.Send( ply )
end

//
// Leader
local function UpdateTeamLeader( tm, ply )
	if tm<=1 or tm>255 then return end
	
	local leader = (IsValid(team.tblLeaders[tm]) and team.tblLeaders[tm]:Team()==tm and team.tblLeaders[tm]) or NULL
	
	net.Start( "DayZGroups_UpdateTeamLeaders" )
		net.WriteUInt( tm, 8 )
		net.WriteEntity( leader )
	if ply then net.Send(ply) else net.Broadcast() end
end
function team.SetLeader( tm, ply )
	if tm==TEAM_SOLO then return end
	if not (IsValid(ply) and ply:Team()==tm) then return end
	
	if not team.tblLeaders then team.tblLeaders = {} end
	team.tblLeaders[tm] = ply
	
	UpdateTeamLeader( tm )
end

//
// Team variable updates
function team.SetColor( tm, col )
	team.UpdateColor( tm, col )
	
	net.Start( "DayZGroups_UpdateTeamColor" )
		net.WriteUInt( tm, 8 )
		net.WriteTable( col )
	net.Broadcast()
end
function team.SetName( tm, name )
	local oldname = team.GetName(tm)
	
	if oldname != name then 

		team.UpdateName( tm, name )
		
		net.Start( "DayZGroups_UpdateTeamName" )
			net.WriteUInt( tm, 8 )
			net.WriteString( name )
		net.Broadcast()

		if team.GetLeader( tm ) then
			PrintMessage( HUD_PRINTTALK, Format( "Group '%s' was renamed to '%s'", oldname, name ) )
		end
	end

end
function team.SetJoinable( tm, joinable )
	team.UpdateJoinable( tm, joinable )
	
	net.Start( "DayZGroups_UpdateTeamJoinable" )
		net.WriteUInt( tm, 8 )
		net.WriteBit( joinable )
	net.Broadcast()
end

//
// Send team vars
local function AllTeamUpdate( ply )
	net.Start( "DayZGroups_FullTeamUpdate" )
		net.WriteUInt( 0, 8 )
		
		net.WriteTable( team.GetAllTeams() )
	if ply then net.Send(ply) else net.Broadcast() end
end
function team.SendFullUpdate( tm, ply )
	if (not tm) or tm<=0 then return AllTeamUpdate(ply) end
	
	net.Start( "DayZGroups_FullTeamUpdate" )
		net.WriteUInt( tm, 8 )
		
		net.WriteString( team.GetName(tm) )
		net.WriteTable( team.GetColor(tm) )
		net.WriteBit( team.Joinable(tm) )
	if ply then net.Send(ply) else net.Broadcast() end
end
concommand.Add( "dayzgroup_fullupdate", function( p,c,a ) if IsValid(p) then AllTeamUpdate(p) end end )

//
// Disconnect
local function PlayerDisconnected( ply )
	if team.IsLeader( ply:Team(), ply ) then
		if team.NumPlayers( ply:Team() ) > 1 then
			local teamPlayers = team.GetPlayers( ply:Team() )
			for i=1,#teamPlayers,-1 do
				if teamPlayers[i]==ply then table.remove(i) break end
			end
			
			local newLeader = table.Random( teamPlayers )
			if IsValid(newLeader) then
				team.SetLeader( ply:Team(), newLeader )
				newLeader:Tip( 3, "yougroupleader" )
			end
		end
	end
end
hook.Add( "PlayerDisconnected", "DayZGroups CanSeeChat", PlayerDisconnected)

//
// Kick player
local function KickFromTeam( ply, target )
	if not (IsValid(ply) and team.IsLeader( ply:Team(), ply )) then return end
	if not (IsValid(target) and target:Team()==ply:Team()) then ply:Tip( 3, "nogrouptarget" ) return end
	
	hook.Call( "PlayerJoinTeam", GAMEMODE, target, 1 )
	target:Tip( 3, "groupkicked" )
end
concommand.Add( "dz_kickgroup", function( p, c, a )
	local target = GAMEMODE.Util:GetPlayerByName(a[1])
	if not IsValid(target) then return end
	
	KickFromTeam( p, target )
end)

//
// Net Receive: Team Vars
net.Receive( "DayZGroups_UpdateTeamColor", function( len, ply )
	if not (IsValid(ply) and team.IsLeader( ply:Team(), ply )) then return end
	
	local col = net.ReadTable()
	if not (col and col.r and col.g and col.b and col.a) then return end // Not a colour
	
	team.SetColor( ply:Team(), col )
end)
net.Receive( "DayZGroups_UpdateTeamName", function( len, ply )
	if not (IsValid(ply) and team.IsLeader( ply:Team(), ply )) then return end
	
	local name = net.ReadString()
	if not name then return end
	
	name = string.gsub( name, "[^%a%d%p ]*", "" )
	if #name>25 then
		ply:Tip( 3, "groupnamelong" )
		return
	elseif #name<1 then
		ply:Tip( 3, "groupnameshort" )
		return
	end
	
	team.SetName( ply:Team(), name )
end)
net.Receive( "DayZGroups_UpdateTeamJoinable", function( len, ply )
	if not (IsValid(ply) and team.IsLeader( ply:Team(), ply )) then return end
	
	local joinable = tobool(net.ReadBit())
	
	team.SetJoinable( ply:Team(), joinable )
end)

local function BroadcastTeammates(ply) 
	local tm = ply:Team()
	if tm<=1 or tm>255 then return end

    if !isfunction(Adv_Compass_AddMarker) then 
        hook.Remove("PlayerTick", "BroadcastTeammates")
        hook.Remove("VehicleMove", "BroadcastTeammates")

        return 
    end
    
	if team.NumPlayers( tm ) > 1 and ( ply.nBroadT or 0 ) < CurTime() then
			
		for _, marker in pairs(ply.cMarkers or {}) do
			Adv_Compass_RemoveMarker(marker)
		end

		ply.cMarkers = {}

		local teamPlayers = team.GetPlayers( tm )
		--local tmc = team.GetColor( tm )
		--local color = Color( tmc.r, tmc.g, tmc.b, tmc.a )
		local color = Color(255,255,255,255)

		for _, tply in pairs(teamPlayers) do
			if mCompass_Settings then
				if tply == ply then continue end -- lol no marking yourself.

				local m_id = Adv_Compass_AddMarker(true, tply, CurTime() + 30, color, { ply }, "icon16/user.png", tply:Nick() )
				table.insert(ply.cMarkers, m_id)
			end
		end

		ply.nBroadT = CurTime() + 25

	end

end
hook.Add("PlayerTick", "BroadcastTeammates", BroadcastTeammates)
hook.Add("VehicleMove", "BroadcastTeammates", BroadcastTeammates)

//
// Net Receive: Join/Leave
net.Receive( "DayZGroups_JoinTeam", function( len, ply )
	if not IsValid(ply) then return end
	
	local tm = net.ReadUInt( 8 )
	if (not tm) or tm==0 then return end
	
	hook.Call( "PlayerRequestTeam", GAMEMODE, ply, tm )
end)
net.Receive( "DayZGroups_LeaveTeam", function( len, ply )
	if not IsValid(ply) then return end
	
	hook.Call( "PlayerRequestTeam", GAMEMODE, ply, 1 )
end)

//
// Net Receive: Invite
net.Receive( "DayZGroups_TeamInvite", function( len, ply )
	if not (IsValid(ply) and team.IsLeader( ply:Team(), ply )) then return end
	
	local target = net.ReadEntity()
	if not (IsValid(target) and target:IsPlayer()) then return end
	if target:Team()==ply:Team() then return end
	
	team.Invite( ply:Team(), target )
end)
