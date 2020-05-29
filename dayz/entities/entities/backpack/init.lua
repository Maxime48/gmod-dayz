AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("UpdateBackpack")
util.AddNetworkString("UpdateBackpackChar")

util.AddNetworkString("net_CloseLootMenu")
util.AddNetworkString("net_LootMenu")

function ENT:Initialize()
	--self:SetModel("models/props_c17/gravestone004a.mdl")	

	if SERVER then
		for k, v in pairs( player.GetAll() ) do
	        self:SetPreventTransmit(v, true)
	    end
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetHealth(300)
	self.Name = "Backpack"
	
	--self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		
	--self:SetAngles(Angle(90,0,0))
	
	--self:SetPos(self:GetPos()+Vector(0,0,5))
	
	self:GetPhysicsObject():Wake()

	self:SetUseType(SIMPLE_USE)
		
	self:SetPerish( CurTime() + (PHDayZ.BackpackPerishTime or 300) )
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

		MsgC( Color(0,255,0), "[PHDayZ] ", Color(255, 255, 0), self:GetStoredName().." 's Backpack - Removed, Outside Map!\n" ) 

		self:Remove()
		return
	end

	if self:GetPerish() < CurTime() then
		ItemDestroyed( self:GetPos() )
		self:Remove()
	end

	self.DoNextThink = CurTime() + 1 -- Let's check once a second, for performances sake.
end

function ENT:Use(activator,caller)
	if !activator:IsPlayer() then return end
	if !activator:CanPerformAction() then return end

	if self:IsOnFire() then
		activator:Tip(3, "ouchfire", Color(255,0,0) ) 
		activator:TakeBlood(5)
		activator:Ignite( math.random(2, 5) )
		activator:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
		activator:ViewPunch(Angle(-10, 0, 0))
		return false 
	end

	local anyItems = 0
	self.ItemTable = self.ItemTable or {}
	self.CharTable = self.CharTable or {}

	for k, amt in pairs(self.ItemTable) do
		anyItems = anyItems + amt
	end
	for k, amt in pairs(self.CharTable) do
		anyItems = anyItems + amt
	end

	if anyItems < 1 then
		activator:ChatPrint("There be nothing to take here.")
		activator.LootingBackpack = nil
		return false
	end
	
	activator:DoModelProcess(self:GetModel(), "Searching "..self.Name, 1, "", 0, "", true, function(activator)
		if !IsValid(activator) or !activator:Alive() then return end
		if !IsValid(self) then return end

		SendBackpack( self, activator )
	end)
	
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth( self:Health() - dmginfo:GetDamage() )
	if self:Health() < 1 then
		ItemDestroyed(self:GetPos())
		self:Remove()
	end
end