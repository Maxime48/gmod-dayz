AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("UpdateBackpack")
util.AddNetworkString("UpdateBackpackChar")

util.AddNetworkString("net_CloseLootMenu")
util.AddNetworkString("net_LootMenu")

function ENT:Initialize()
	if EVENT_CHRISTMAS then
		self:SetModel("models/katharsmodels/present/type-1/big/present2.mdl")	
	else
		self:SetModel("models/fallout 3/campish_pack.mdl")	
	end
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self:SetHealth(300)

	self:SetColor(Color(127,127,127))
	
	--self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		
	--self:SetAngles(Angle(90,0,0))
	
	--self:SetPos(self:GetPos()+Vector(0,0,5))
	
	self:GetPhysicsObject():Wake()

	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(0.5)
		phys:AddVelocity( Vector(math.random(0,32), math.random(0,32), 0) )
	end

	self:MakeChute()

	self:DoConstraints()

	self.ItemTable = {}
	self.CharTable = {}

	self:RandomItems()

	self.Found = false

	if self.LootType == "weapon" then

		if EVENT_CHRISTMAS then
			self:SetModel("models/katharsmodels/present/type-1/big/present2.mdl")
		else
			self:SetColor(Color(255,0,0))
		end
		
	elseif self.LootType == "food" then

		if EVENT_CHRISTMAS then
			self:SetModel("models/katharsmodels/present/type-1/big/present3.mdl")
		else
			self:SetColor(Color(255,255,0))
		end

	elseif self.LootType == "hat" then

		if EVENT_CHRISTMAS then
			self:SetModel("models/katharsmodels/present/type-1/big/present.mdl")
		else
			self:SetColor(Color(0,255,255))
		end

	end

	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:RandomItems()
	self.ItemTable = {}
	self.CharTable = {}

	local maxitems = math.random( 5, PHDayZ.CarePackage_MaxItems )
	local itemamount = 0

	if self.LootType and LootItems[self.LootType] then

		for k, v in RandomPairs(LootItems[ self.LootType ]) do
			
			if itemamount > maxitems then break end
			local ItemTable = GAMEMODE.DayZ_Items[v]

			if ItemTable.SpawnChance < 1 then continue end -- Don't add items that don't spawn in the gamemode... at all! (Like Perks!)

			local max = math.random(1, PHDayZ.CarePackage_MaximumQuantity)
			if ItemTable.SpawnChance < 10 then max = math.random(1, 2) elseif GAMEMODE.DayZ_Items[v].Weapon then max = math.random(1, 3) end
			if ItemTable.ClipSize then max = math.random(ItemTable.ClipSize, ItemTable.ClipSize * 5) end
			if ItemTable.Weapon then max = 1 end -- limit weapons to 1

			local rar = GenerateRarity( ItemTable )

			local it = {}
			it.id = itemamount + 1
			it.amount = max
			it.class = v
			it.quality = math.random(300, 700)
			it.rarity = rar

			self.ItemTable[v] = self.ItemTable[v] or {}
			self.ItemTable[ v ][it.id] = it
			itemamount = itemamount + 1
		end

		return
	end

	for k, v in RandomPairs(GAMEMODE.DayZ_Items) do
		if itemamount > maxitems then break end

		if v.SpawnChance < 1 then continue end -- Don't add items that don't spawn in the gamemode... at all! (Like Perks!)

		local max = math.random(1, PHDayZ.CarePackage_MaximumQuantity)
		if v.SpawnChance < 10 then max = math.random(1, 2) elseif v.Weapon then max = math.random(1, 3) end
		if v.ClipSize then max = v.ClipSize end
		if v.Weapon then max = 1 end -- limit weapons to 1

		local rar = GenerateRarity( v )

		local it = {}
		it.id = itemamount + 1
		it.amount = max
		it.class = k
		it.quality = math.random(300, 700)
		it.rarity = rar

		self.ItemTable[k] = self.ItemTable[k] or {}
		self.ItemTable[ k ][it.id] = it
		itemamount = itemamount + 1
	end

end

function ENT:DoConstraints()
	if !IsValid(self.Chute) then return end

	constraint.Rope( self.Chute, self, 0, 0, Vector(45, 0, 0), Vector(0,0,20), 96, 0, 0, 1 )
	constraint.Rope( self.Chute, self, 0, 0, Vector(-45, 0, 0), Vector(0,0,20), 96, 0, 0, 1 )

	constraint.Rope( self.Chute, self, 0, 0, Vector(0, 45, 0), Vector(0,0,20), 96, 0, 0, 1 )
	constraint.Rope( self.Chute, self, 0, 0, Vector(0, -45, 0), Vector(0,0,20), 96, 0, 0, 1 )
end

function ENT:MakeChute()
	
	self.Chute = ents.Create("prop_physics")
	self.Chute:SetModel( "models/hunter/misc/shell2x2a.mdl" )
	self.Chute:SetMaterial( "models/props_c17/FurnitureFabric003a" )
	self.Chute:SetHealth(100)
	self.Chute:SetPos( self:GetPos() + Vector(0,0,96) )
	self.Chute:Spawn()

	local phys = self.Chute:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableGravity( false )
		phys:SetMass(1)
	end

end

function ENT:OnTakeDamage(dmginfo)
	if IsValid(self.Chute) then
		self.Chute:TakeDamageInfo(dmginfo)
	end
end

function ENT:SpawnContents()
	if IsValid(self.Chute) then self.Chute:Remove() end

	if self.Boomy then
		local explo = ents.Create( "env_explosion" )
		explo:SetPos( self:GetPos() )
		explo:SetKeyValue( "iMagnitude", "150" )
		explo:Spawn()
		explo:Activate()
		explo:Fire( "Explode", "", 0 )
	else
		for k, v in pairs(self.ItemTable) do

			for _, item in pairs(v) do
				if item.amount > 0 then
					local ent = ents.Create("base_item")
					ent:SetItem( item.class )
					ent.Amount = item.amount
					ent:SetQuality(item.quality)
					ent:SetRarity( item.rarity )
					ent:SetAmount( ent.Amount )
					ent:SetPos( self:GetPos() )
					ent:Spawn()
					ent:PhysWake()
				end
			end
		end
	end
	
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
	self:SpawnContents()
end

function ENT:OnRestore()
end

function ENT:Touch(hitEnt) 
end

function ENT:OnGroundC()
	local tr = util.TraceLine( {
		start = self:GetPos(),
		endpos = self:GetPos() - Vector( 0, 0, 500),
		filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
	} )

	if tr.Hit then
		if IsValid(self.Chute) then 
			self.Chute:Remove() 
			local phys = self:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetMass(50)
			end
		end
	end

end

function ENT:Think()
	if self:OnGroundC() then
		if IsValid(self.Chute) then self.Chute:Remove() end
	end

	if mCompass_Settings then
		self.nextAlert = self.nextAlert or 0

		if self.nextAlert < CurTime() then
			self.nextAlert = CurTime() + 20

			if table.Count(self.ItemTable) < 1 then return end -- there is no point continuing broadcasting an empty care package.
			
			if self.MarkerID then
				Adv_Compass_RemoveMarker(self.MarkerID)
			end

			self.MarkerID = Adv_Compass_AddMarker(true, self, CurTime() + 25, Color(255,165,0,255), nil, "cyb_mat/cyb_backpack.png", "Care Package" )
		end
	end
end

function ENT:Use(activator,caller)
	if !activator:IsPlayer() then return end

	local booby = ""
	if !self.Found and !activator.Noclip then
		TipAll(3, activator:Nick().." has found a"..booby.." carepackage!", Color(255,255,0) )
		self.Found = true
	end

	if self:IsOnFire() then
		activator:Tip(3, "Ouch! This is on fire!", Color(255,0,0) ) 
		activator:TakeBlood(5)
		activator:Ignite( math.random(2, 5) )
		activator:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
		activator:ViewPunch(Angle(-10, 0, 0))
		return false 
	end

	activator:DoModelProcess(self:GetModel(), "Searching", 3, "", 0, "", false, function(activator)
		if !IsValid(self) or !IsValid(activator) then return end

		SendBackpack(self, activator)
	end)

	
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth( self:Health() - dmginfo:GetDamage() )
	if self:Health() < 1 then
		ItemDestroyed(self:GetPos())
		self:Remove()
	end
end