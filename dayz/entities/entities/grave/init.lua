AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("UpdateBackpack")
util.AddNetworkString("UpdateBackpackChar")

util.AddNetworkString("net_CloseLootMenu")
util.AddNetworkString("net_LootMenu")

function ENT:Initialize()
	self:SetModel("models/props_c17/gravestone004a.mdl")	

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	--self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		
	--self:SetAngles(Angle(90,0,0))
	
	--self:SetPos(self:GetPos()+Vector(0,0,5))
	
	self:GetPhysicsObject():Wake()

	self:SetUseType(SIMPLE_USE)

	self:SetPerish( CurTime() + (PHDayZ.GravePerishTime or 300) )
end

function ENT:OnTakeDamage(dmginfo)
end
function ENT:Detach()
end
function ENT:StartTouch(ent) 
end
function ENT:EndTouch(ent)
end
function ENT:AcceptInput(name,activator,caller)
end
function ENT:KeyValue(key,value)
end
function ENT:OnRemove()
end
function ENT:OnRestore()
end
function ENT:Touch(hitEnt) 
end

function ENT:Think()
	if (self.DoNextThink or 0) > CurTime() then return end

	if !self:IsInWorld() then -- If for some reason it's spawned outside the map or falls out.

		MsgC( Color(0,255,0), "[PHDayZ] ", Color(255, 255, 0), self:GetStoredName().." 's Grave - Removed, Outside Map!\n" ) 

		self:Remove()
		return
	end

	if self:GetPerish() < CurTime() then
		ItemDestroyed( self:GetPos() )
		self:Remove()
	end

	if IsValid(self.ply) then
		self:SetColor( Color(255,0,0,255) )
	else
		self:SetColor( Color(255,255,255,255) )
	end
	
	self.DoNextThink = CurTime() + 1 -- Let's check once a second, for performances sake.
end

function ENT:Use(activator,caller)
	return	
end

function ENT:OnTakeDamage(dmginfo)
end

function SendBackpack(backpack, player)
	local anyItems = 0

	backpack.ItemTable = backpack.ItemTable or DZ_LootablesItems[ backpack:EntIndex() ] or {}
	backpack.CharTable = backpack.CharTable or {}

    for k, items in pairs(backpack.ItemTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
        end
    end
    for k, items in pairs(backpack.CharTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
        end
    end

	backpack.players_int = backpack.players_int or {}
	if !table.HasValue(backpack.players_int, player:EntIndex()) then
		table.insert(backpack.players_int, player:EntIndex())
	end

	player.LootingBackpack = backpack:EntIndex()

	if anyItems < 1 then
		--backpack:Remove()

		backpack.ItemTable = {} -- removes any count of 0, incase entity is re-used.
		backpack.CharTable = {} -- removes any count of 0, incase entity is re-used.
		
		player:ChatPrint("There be nothing to take here.")
		--umsg.Start("CloseLootMenu", player)
		--umsg.End()		
		net.Start("net_CloseLootMenu")
		net.Send(player)

		if backpack:GetClass() == "prop_ragdoll" then
			--backpack:SetModel("models/player/skeleton.mdl")
		end

		player.LootingBackpack = nil

		for k, plyindex in pairs(backpack.players_int) do
			local ply = Entity(plyindex)
			if !IsValid(ply) then continue end

			if ply.LootingBackpack == backpack:EntIndex() then
				ply.LootingBackpack = nil
			end
		end
		backpack.players_int = {}

		return false
	end

	for k, plyindex in pairs(backpack.players_int) do
		local ply = Entity(plyindex)
		if !IsValid(ply) then continue end

		if ply.LootingBackpack != nil && ply.LootingBackpack != backpack:EntIndex() then continue end -- only network the backpack they are looting...

		if ply:GetPos():DistToSqr( backpack:GetPos() ) > ( 300 * 300 ) then continue end

		net.Start("UpdateBackpack")
			net.WriteTable(backpack.ItemTable)
			--net.WriteEntity(backpack)
		net.Send(ply)
		
		net.Start("UpdateBackpackChar")
			net.WriteTable(backpack.CharTable)	
			--net.WriteEntity(backpack)	
		net.Send(ply)

	end
	
	--umsg.Start("LootMenu", player)
		--umsg.Float(tonumber(backpack:EntIndex()))
	--umsg.End()
	
	net.Start("net_LootMenu")
		net.WriteFloat( tonumber(backpack:EntIndex()) )
	net.Send(player)
	
end

function SendBackpackFromCon(ply)
	if !ply.LootingBackpack then return end
	local backpack = Entity(ply.LootingBackpack)
	if !IsValid( backpack ) then return end
	SendBackpack(backpack, ply)
end

concommand.Add("SendBackpack",function(ply, cmd, args) 
	SendBackpackFromCon(ply) 
end)

