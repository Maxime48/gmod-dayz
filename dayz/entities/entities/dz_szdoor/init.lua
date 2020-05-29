AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:Initialize()

	--self:SetModel("models/props/cs_militia/footlocker01_closed.mdl")
	self:SetModel("models/props_junk/TrashDumpster02b.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetMaterial("debug/env_cubemap_model")

end

function ENT:KeyValue(key,value)
end

function ENT:Touch(activator)
	if !activator:IsPlayer() then return end
	if activator.CantUse then return end
	activator.CantUse = true
	
	timer.Simple(1, function() activator.CantUse = false end)

	SafezoneTeleport(activator, true, 0)
end

function ENT:SetType(strType)
end

function ENT:Use(activator, caller)
	if !activator:IsPlayer() then return end
	if activator.CantUse then return end
	activator.CantUse = true
	
	timer.Simple(1, function() activator.CantUse = false end)
	SafezoneTeleport(activator, true, 0)
end


