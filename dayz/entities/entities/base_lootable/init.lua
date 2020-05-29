AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )


DZ_LootablesPool = DZ_LootablesPool or {}
DZ_LootablesItems = DZ_LootablesItems or {}

function ENT:Initialize()
	-- set model before spawning this entity

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	--self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:SetUseType( SIMPLE_USE )
	self:SetHealth( 20000 )

	--self:SetSaveValue("fademindist", 256)
	--self:SetSaveValue("fademaxdist", 2048)

	DZ_LootablesItems[ self:EntIndex() ] = {}
	DZ_LootablesPool[ self:EntIndex() ] = {}

	self:ChangeItems()
end


function ENT:ChangeItems()
	if !self:IsValid() then return end

	local model = string.lower( self:GetModel() )

	local categories = PHDayZ.LootableItemSetup[ model ]

	if !categories or table.Count(categories) < 1 then 
		categories = PHDayZ.LootableItemSetup[ "default" ] or {"Food", "Drinks", "Medical", "Clothes", "Pants", "Shoes", "Misc", "Parts", "Tools", "Resources"}
	end

	DZ_LootablesPool[ self:EntIndex() ] = DZ_LootablesPool[ self:EntIndex() ] or {}

	if table.Count( DZ_LootablesPool[ self:EntIndex() ] ) < 1 then 
		for _, cat in pairs(categories) do
			local tab = GAMEMODE.Util:GetItemsByCategory( string.lower(cat) )

			for _, t in pairs(tab) do

				local Item = GAMEMODE.DayZ_Items[t.ID]
				if !Item then continue end
				
				table.insert( DZ_LootablesPool[ self:EntIndex() ], t)
			end
		end
	end

	self.nextRespawn = CurTime() + PHDayZ.LootableRespawnTimer or 900

	local near = false
	local PlayerRadius = Vector(150, 150, 150)
	local pos = self:GetPos()
	for _, ent in pairs( ents.FindInBox( pos + PlayerRadius, pos - PlayerRadius ) ) do
		if IsValid( ent ) and ent:IsPlayer() then
			near = true
			break
		end
	end

	if near then return end -- don't spawn near players ;D

	self.ItemTable = nil
	self.itemPool = nil 

	DZ_LootablesItems[ self:EntIndex() ] = {}
	local noitems = true
	for i=1, PHDayZ.LootablesMaxItems or 6 do
		local ItemTable = DZ_LootablesPool[ self:EntIndex() ][ math.random( #DZ_LootablesPool[ self:EntIndex() ] ) ]
		local amount, canSpawn = 1, true

		if !ItemTable then continue end

		if !GAMEMODE.DayZ_Items[ItemTable.ID] then continue end -- it should exist but whatever

		if ItemTable.SpawnChance < math.random( 0, 100 ) then canSpawn = false end -- items are not guaranteed to spawn.
		if !canSpawn then continue end

		if ItemTable.ClipSize then amount = math.random(1, ItemTable.ClipSize) end

		local it = {}
		it.id = i
		it.amount = amount
		it.class = ItemTable.ID
		it.quality = math.random(300, 700)
		it.rarity = GenerateRarity(ItemTable)
		local rn = math.random(1, 4)
		if rn > 2 or ItemTable.ClipSize then
			it.rarity = 1 
		end
		noitems = false
		DZ_LootablesItems[ self:EntIndex() ][ ItemTable.ID ] = DZ_LootablesItems[ self:EntIndex() ][ ItemTable.ID ] or {}
		DZ_LootablesItems[ self:EntIndex() ][ ItemTable.ID ][it.id] = it

	end

	if noitems then self.nextRespawn = CurTime() + 1 return end

	--MsgAll("------------------[ID: "..self:EntIndex().."]Changing items ("..model..")------------------\n")
	--PrintTable(self.ItemTable)

end

function ENT:StartTouch( ent )
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth( self:Health() )
	return false
end

function ENT:Think()

	if ( self.nextRespawn or 0 ) < CurTime() then		
		self:ChangeItems()		
	end
	
end

function ENT:OnRemove()
	if self.SpawnLoot then
		TotalSpawnedLootables = TotalSpawnedLootables - 1
	end
end

function ENT:Use( activator, caller ) 
	if self:GetPos():DistToSqr( caller:GetPos() ) > (300*300) then return end
	if IsValid(caller) and caller:IsPlayer() then 

		if !caller:CanPerformAction() then return end

		local anyItems = 0
		for k, items in pairs( DZ_LootablesItems[ self:EntIndex() ] ) do
	        for _, it in pairs(items) do
	            if it.amount < 1 then continue end
	            anyItems = anyItems + 1
	        end
	    end

	    local name = getNiceName( self:GetModel() )
	    name = firstToUpper(name)

	    if anyItems < 1 then
			caller:PrintMessage(HUD_PRINTTALK, name.." is empty.")	    	
	    	return
	    end

		caller:DoModelProcess(self:GetModel(), "Searching "..name, 2, "npc/combine_soldier/gear"..math.random(1,6)..".wav", 0, "", true, function(caller)
			if !IsValid(caller) or !caller:Alive() then return end
			if !IsValid(self) then return end

			if DZ_Quests && name == "Toilet" && ( caller.lastToilet or 0 ) != self:EntIndex() then
				caller:DoQuestProgress("quest_toilettrasher", 1)
				caller.lastToilet = self:EntIndex()
			end

			SendBackpack( self, caller )
		end)
	end 
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end 

hook.Add("DZ_FullyLoaded", "RefreshLootables", function()
	MsgAll("[PHDayZ] Refreshing Lootables...\n")
	for k, v in pairs( ents.FindByClass("base_lootable") ) do 
		v:ChangeItems() 
	end
end)