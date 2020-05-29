util.AddNetworkString( "Thirst" )
util.AddNetworkString( "Hunger" )

Spawns = {}
Spawns[ string.lower(game.GetMap()) ] = {}

file.CreateDir("dayz/spawns_player/")
Msg("======================================================================\n")

if !file.Exists("dayz/spawns_player/"..string.lower(game.GetMap())..".txt", "DATA") then
	file.Write("dayz/spawns_player/"..string.lower(game.GetMap())..".txt", util.TableToJSON( {}, true ))
end

if file.Size("dayz/spawns_player/"..string.lower(game.GetMap())..".txt", "DATA") == 3 then
	MsgC(Color(255,255,0), "[PHDayZ] Player spawns not yet setup!\n")
else
	
	local config = util.JSONToTable(file.Read("dayz/spawns_player/"..string.lower(game.GetMap())..".txt", "DATA" ))
	
	if not istable(config) then
		table.insert(PHDayZ_StartUpErrors, "Player spawns failed to load, check file consistency!")
		return
	end
	
	Spawns[ string.lower(game.GetMap()) ] = config
	
	MsgC(Color(0,255,0), "[PHDayZ] Player spawns found and loaded!\n")
end
Msg("======================================================================\n")


local function RefreshSpawns(ply)
	if ply:EntIndex() != 0 and !ply:IsSuperAdmin() then return end -- If it's ran from command.
	MsgAll("[PHDayZ] Reloading Player Spawns...\n")
	
	local config = util.JSONToTable(file.Read("dayz/spawns_player/"..string.lower(game.GetMap())..".txt", "DATA" ))
	
	if not istable(config) then
		MsgAll("[PHDayZ] Player Spawns file failed to load, check consistency!\n")
		return
	end
	
	Spawns[ string.lower( game.GetMap() ) ] = config
	
	MsgAll("[PHDayZ] Player spawns found and loaded!\n")
end
concommand.Add("dz_reloadspawns", RefreshSpawns)

HungerSounds = {
	"vo/npc/male01/mygut02.wav"
}

ThirstSounds = {
	"vo/npc/male01/moan01.wav",
	"vo/npc/male01/moan02.wav",
	"vo/npc/male01/moan03.wav",
	"vo/npc/male01/moan04.wav",
	"vo/npc/male01/moan05.wav"
}

PMETA = FindMetaTable("Player")
function PMETA:SetAFK( bool )
	self:SetNW2Bool("dz_afk", bool)
end

hook.Add("PlayerInitialSpawn", "DZAFK_PlayerInitialSpawn", function( ply )
	ply.dzafk_la = CurTime()
end )

hook.Add("DZ_PlayerReady", "DZAFK_PlayerReady", function( ply )
	ply.dzafk_la = CurTime()
end )

hook.Add("DZ_OnCraftItem", "DZAFK", function( ply )
	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

hook.Add("DZ_OnBankItem", "DZAFK", function( ply )
	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

hook.Add("DZ_OnWithdrawItem", "DZAFK", function( ply )
	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

hook.Add("DZ_OnUseItem", "DZAFK", function( ply )
	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

hook.Add( "PlayerSay", "DZAFK_Chat", function( ply, text, teamOnly )
	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

local allowedkeys = { IN_JUMP, IN_DUCK, IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT, IN_RELOAD, IN_SPEED }
hook.Add( "KeyPress", "DZAFK_KeyPress", function( ply, key )
	if !table.HasValue(allowedkeys, key) then return end -- don't run for other keys, incase of autoclickers/bots.

	ply.dzafk_la = CurTime()
	DZ_CheckAFK( ply )
end )

function DZ_CheckAFK( ply )
	if !PHDayZ.AFKSystem then return end

	if ply.Loading or !ply.Ready then if !ply:GetAFK() then return end ply:SetAFK(false) return end

	local afktime = PHDayZ.AFKTimer or 300
	if ( CurTime() - ( ply.dzafk_la or 0 ) ) > afktime then
		if ply:GetAFK() then return end
		ply:SetAFK(true)
		ply:Tip(3, "You are now AFK!", Color(0,255,0,255))
	else
		if !ply:GetAFK() then return end
		ply:SetAFK(false)
		ply:Tip(3, "You are no longer AFK!", Color(0,255,0,255))
	end
end

function DZAFK( ply )
	if CurTime() <= ( ply.dz_nextAFKThink or 0 ) then return end
	ply.dz_nextAFKThink = CurTime() + 5

	DZ_CheckAFK( ply )
end
hook.Add("PlayerTick", "DZAFK", DZAFK)
hook.Add("VehicleMove", "DZAFK", DZAFK)
