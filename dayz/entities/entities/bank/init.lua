AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

util.AddNetworkString("net_BankMenu")

function ENT:KeyValue(key,value)
end

function ENT:SetType(strType)
end

function ENT:Use(activator, caller)
	if !activator:IsPlayer() then return end
	if activator.CantUse then return end
	activator.CantUse = true
	
	timer.Simple(1, function() activator.CantUse = false end)

	activator:ConCommand("menu_tab bank")
end


