if CLIENT then
	game.AddParticles("particles/dust_rumble.pcf")
	game.AddParticles("particles/steampuff.pcf")
	game.AddParticles("particles/vehicle.pcf")
end

PrecacheParticleSystem("steam_jet_80")
PrecacheParticleSystem("steam_large_01")
PrecacheParticleSystem("dust_bridge_crack")
PrecacheParticleSystem("WheelSplash")
PrecacheParticleSystem("WheelDust")

hook.Add("DayZ_ItemsLoaded", "PrecacheModels", function()
	for k, v in pairs(GAMEMODE.DayZ_Items) do
		
		if v.Model then
			util.PrecacheModel(v.Model)
		end

		if v.BodyModel then
			util.PrecacheModel(v.BodyModel)
		end

	end

end)

if CustomizableWeaponry then
	function CustomizableWeaponry:initCWVariables()
		if !IsValid(self) then return end -- spy you turd
		if not self.CWAttachments then
			self.CWAttachments = {}
		end
	end
end

properties = properties or {} -- override time... adding just this fixed it, something overriding perhaps?
properties.CanBeTargeted = function( ent, ply )
	if ( !IsValid( ent ) ) then return false end
	if ( ent:IsPlayer() ) then return false end
	-- Check the range if player object is given
	-- This is not perfect, but it is close enough and its definitely better than nothing
	if ( IsValid( ply ) ) then
		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local maxRange = math.max( math.abs( mins.x ) + maxs.x, math.abs( mins.y ) + maxs.y, math.abs( mins.z ) + maxs.z )
		if ( ent:GetPos():Distance( ply:GetShootPos() ) > maxRange + 1024 ) then return false end
	end

	return !( ent:GetPhysicsObjectCount() < 1 && ent:GetSolid() == SOLID_NONE && bit.band( ent:GetSolidFlags(), FSOLID_USE_TRIGGER_BOUNDS ) == 0 && bit.band( ent:GetSolidFlags(), FSOLID_CUSTOMRAYTEST ) == 0 )
end

properties.Add( "remove", {
	MenuLabel = "#remove",
	Order = 1000,
	MenuIcon = "icon16/delete.png",

	Filter = function( self, ent, ply )

		if ( !gamemode.Call( "CanProperty", ply, "remover", ent ) ) then return false end
		if ( !IsValid( ent ) ) then return false end
		if ( ent:IsPlayer() ) then return false end

		return true

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )
		if ( !IsValid( ply ) ) then return end

		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end

		-- Don't allow removal of players or objects that cannot be physically targeted by properties
		if ( !properties.CanBeTargeted( ent, ply ) ) then return end 
		if ( !self:Filter( ent, ply ) ) then return end

		-- Remove all constraints (this stops ropes from hanging around)
		constraint.RemoveAll( ent )

		-- Remove it properly in 1 second
		timer.Simple( 1, function() if ( IsValid( ent ) ) then ent:Remove() end end )

		-- Make it non solid
		ent:SetNotSolid( true )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:SetNoDraw( true )

		-- Send Effect
		local ed = EffectData()
		ed:SetEntity( ent )
		util.Effect( "entity_remove", ed, true, true )

		ply:SendLua( "achievements.Remover()" )

	end

} )

function GM:CanTool(ply, trace, mode)
	if not self.BaseClass:CanTool(ply, trace, mode) then return false end

	if IsValid(trace.Entity) then
		if mode != "nodegrapheditor" && table.HasValue( PHDayZ.BlockedEntities, trace.Entity:GetClass() ) then return false end

		if trace.Entity.onlyremover then
			if mode == "remover" then
				return (ply:IsAdmin() or ply:IsSuperAdmin())
			else
				return false
			end
		end

		if trace.Entity.nodupe and (mode == "weld" or
					mode == "weld_ez" or
					mode == "spawner" or
					mode == "duplicator" or
					mode == "adv_duplicator") then
			return false
		end

		if trace.Entity:IsVehicle() and mode == "nocollide" then
			return false
		end
	end
	return true
end

function GM:CanDrive(ply, ent)
	if table.HasValue( PHDayZ.BlockedEntities, ent:GetClass() ) then return false end

	if ply:IsSuperAdmin() then return true end

	return false -- Disabled until people can't minge with it anymore
end

function GM:PhysgunPickup( ply, ent )
	if !IsValid(ent) then return end

	if table.HasValue( PHDayZ.BlockedEntities, ent:GetClass() ) then return false end

	if ent:GetPersistent() then return false end
	
	if ply:IsAdmin() then return true end
	if ply:SteamID64() == ent.SID then return true end
	ply.NextPhysTip = ply.NextPhysTip or 0
	
	if ply.NextPhysTip > CurTime() then return false end
	ply.NextPhysTip = CurTime() + 3
	ply:Tip(3, "notownedent")
	
	return false
end

function GM:CanProperty(ply, property, ent)
	if table.HasValue( PHDayZ.BlockedEntities, ent:GetClass() ) then return false end

	if ply:IsAdmin() then
		if SERVER then
			DzLog(2, "Player '"..ply:Nick().."'("..ply:SteamID()..") used property: "..property.." on ent: "..ent:GetClass() )
		end
		return true
	end
	return false -- Disabled until antiminge measure is found
end

if SERVER then
	
	util.AddNetworkString("serverTimeoutPing")

	--if !timer.Exists("serverTimeoutPing") then 
		
		timer.Create("serverTimeoutPing", 5, 0, function()

			for k, v in pairs(player.GetAll()) do
				if !v.Ready then continue end

				net.Start("serverTimeoutPing")
				net.Send(v)
			end
			
		end)

	--end
end

if CLIENT then return end 

-- TODO: unstuck
---------------------------------------------------------------
-- WeHateGarbage
local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
function PlayerNotStuck( ply )

	t.start = ply:GetPos()
	t.endpos = t.start
	t.filter = ply
	
	return util.TraceEntity(t,ply).StartSolid == false
	
end

NewPos = NewPos or nil
function FindPassableSpace( ply, direction, step )

	local i = 0
	while ( i < 100 ) do
		local origin = ply:GetPos()

		--origin = VectorMA( origin, step, direction )
		origin = origin + step * direction
		
		ply:SetPos( origin )
		if PlayerNotStuck( ply ) then
			NewPos = ply:GetPos()
			return true
		end
		i = i + 1
	end
	return false
end

-- 	
--	Purpose: Unstucks player
--	Note: Very expensive to call, you have been warned!
--
function UnstuckPlayer( ply )

	NewPos = ply:GetPos()
	local OldPos = NewPos
	
	if not PlayerNotStuck( ply ) then
	
		local angle = ply:GetAngles()
		
		local forward = angle:Forward()
		local right = angle:Right()
		local up = angle:Up()
		
		local SearchScale = 4 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12

		if	not FindPassableSpace( ply, forward, SearchScale ) and	-- forward
			not FindPassableSpace( ply, right, SearchScale ) and  	-- right
			not FindPassableSpace( ply, right, -SearchScale ) and 	-- left
			not FindPassableSpace( ply, up, SearchScale ) and    	-- up
			not FindPassableSpace( ply, up, -SearchScale ) and   	-- down
			not FindPassableSpace( ply, forward, -SearchScale )   	-- back
		then								
			MsgAll( "Can't find the world for player "..tostring(ply).."\n" )
			return false
		end
		
		if OldPos == NewPos then 
			return true -- Not stuck?
		else
			ply:SetPos( NewPos )
			if SERVER and ply and ply:IsValid() and ply:GetPhysicsObject():IsValid() then
				if ply:IsPlayer() then
					ply:SetVelocity(vector_origin)
				end
				ply:GetPhysicsObject():SetVelocity(vector_origin) -- prevents bugs :s
			end
		
			return true
		end
		
	end
	
	
end

---------------------------------------------------------------

local meta = FindMetaTable( "Player" )
if not meta then return end

--	Unstucks a player
-- returns:
--	true:	Unstucked
--	false:	Could not UnStuck
--	else:	Not stuck 
--
function meta:UnStuck()
	return UnstuckPlayer(self)
end

---------------------------------------------------------------
-- CONFIG -----------------------------------------------------
---------------------------------------------------------------

local config = {} -- ignore

-- Available chat commands for us_unstuck console command
config.ChatCommands = {
		
		"!unstuck",
		"!stuck",
		"/unstuck",
		"/stuck"
		
}

-- Players of these teams are not allowed to use the unstuck command
config.ExcludedTeams = {}

-- Number of seconds a player has to wait until (s)he can use the unstuck command again
config.Wait = 60

---------------------------------------------------------------

concommand.Add( "dz_unstuck", function( ply )

	if not IsValid( ply ) then return end

	if not ply:Alive() then
		return
	end

	local stuck = PlayerNotStuck(ply)
	if stuck == true then ply:Tip(3, "You are not stuck!", Color(255,0,0,255)) return end

	if ply:GetPVPTime() > CurTime() then ply:Tip(3, "You cannot do this while in PVP!", Color(255,0,0,255)) return end

	ply:DoModelProcess(ply:GetModel(), "Unsticking...", 120, "npc/combine_soldier/gear"..math.random(1,6)..".wav", 0, "", true, function(ply)
		if !IsValid(ply) or !ply:Alive() then return end

		local pos = PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ]

		if !PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] then
			MsgAll("[PHDayZ] ERROR! dz_setszteleportpos not set! Nowhere to teleport player, /unstuck fail!\n")
			return
		end

		ply:EmitSound("ambient/machines/teleport1.wav", 75, 100, 0.5)

		ply:SetPos(pos)

		ply:Tip(3, "Unstuck successful!", Color(255,0,0,255))

		MsgAll(ply:Nick().." teleported to safezone via /stuck\n")

	end)

end )

hook.Add( "PlayerSay", "Unstuck Command", function( pl, text )
	
	if table.HasValue( config.ChatCommands, string.lower(text) ) then
		pl:ConCommand("dz_unstuck")
		return ""
	end
	
end )