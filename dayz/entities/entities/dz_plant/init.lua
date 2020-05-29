AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/weapons/w_bugbait.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

 	self:SetColor(Color(0,255,0,255))

 	self:SetItem( self.FruitType or "item_food2" )
 	self:SetPLevel(-1)

 	self.OwnerID = self.Creator.ID
end

function ENT:Grow()
	local pos = self:GetPos()
	self.Fade = true

	local item = self:GetItem()

	self:MakeFruit( item, pos )

	self:EmitSound("garrysmod/balloon_pop_cute.wav")
end

function ENT:MakeFruit( item, pos )
	local plant = ents.Create("prop_physics")
	plant:SetAngles(Angle(0,math.random(1,360),0))

	local model = "models/props/de_dust/du_palm_tree01_skybx.mdl"
	local modeloffset = Vector(0,0,-3)
	local fruitoffset = Vector(0, 0, 80)
	local distvec = 7

	if item == "item_food2" then
		model = "models/props/cs_militia/fern01.mdl"
		modeloffset = Vector(0,0,33)
		fruitoffset = Vector(0, 0, 5)
		distvec = 25
	elseif item == "item_cactus" then
		model = "models/props/de_inferno/cactus2.mdl"
		modeloffset = Vector(0,0,0)
		fruitoffset = Vector(0,0,40)
		distvec = 12
	elseif item == "item_wheat" then
		model = "models/props_foliage/cattails.mdl"
		modeloffset = Vector(0,0,-30)
		fruitoffset = Vector(0,0,60)
		distvec = 20
	end

	plant:SetModel(model)
	plant:SetPos(pos + modeloffset)
	plant.Think = function()
		if plant.Fruit < 1 then
			plant:Remove()
		end
	end

	plant:Spawn()

	plant.Fruit = 0

	local f = 5
	local fa = false
	if IsValid(self.Creator) && self.Creator:HasPerk("perk_fancyfarmer") then
		f = 3
		fa = true
	end
	local num = 0

	local r = math.random(1, 10)
	if r > f then
		num = 1
		r = math.random(1, 10)
		if r > f then
			num = 2 
			r = math.random(1, 10)
			if r > f then
				num = 3
				r = math.random(1, 10)
				if r > f && fa then
					num = 4
					r = math.random(1, 10)
					if r > f && fa then
						num = 5
					end
				end
			end

		end
	end

	if IsValid(self.Creator) then
		if num < 2 then num = 2 end

		if DZ_Quests then
			self.Creator:DoQuestProgress("quest_fancyfarmer3", 1)
			if !self.Creator:InQuest("quest_fancyfarmer3") then
				self.Creator:DoQuestProgress("quest_fancyfarmer2", 1)
				if !self.Creator:InQuest("quest_fancyfarmer2") then
					self.Creator:DoQuestProgress("quest_fancyfarmer", 1)
				end
			end
		end
	end

	local forced_rarity = false
	if num > 0 then
		for i = 1, num do
			local ent = ents.Create("base_item")
			ent.NoCalcPos = true -- to stop the gamemode from setting it's position for realism.
			ent:SetItem( item )
			ent:SetQuality( 800 )

			ent:SetPerish( CurTime() + 600 )

			local rarity = GenerateRarity( GAMEMODE.DayZ_Items[item] )
			if self:GetRarity() > rarity then
				local rn = math.random(1, 100)
				if rn <= 15 then
					rarity = self:GetRarity()
				end
			end

			if !forced_rarity then -- force first plant to be the same rarity as the seed that was planted
				rarity = self:GetRarity()
				forced_rarity = true
			end

			if rarity < ( self:GetRarity() - 3 ) then
				rarity = ( self:GetRarity() - 3 )
			end

			ent:SetRarity(rarity)

			ent:SetFoundType(4)
			ent:SetFounder( self.OwnerID )

			ent.noperish = true -- Stops perishing system.

			ent:SetAngles( Angle(0, math.random(1,360), 0) )
			ent:SetAmount(1)
			ent:SetPos( pos + Vector( math.random(-distvec, distvec), math.random(-distvec, distvec), math.random(5, 7) ) + fruitoffset )
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys then 
				phys:EnableMotion(false) 
			end
			ent.PlantParent = plant
			plant.Fruit = plant.Fruit + 1
		end
	end

	if num == 0 then timer.Simple(15, function() if !IsValid(plant) then return end plant:Remove() end) end

	self:Remove()
end

function ENT:Think()
	self.DoNextThink = self.DoNextThink or 0
	if self.DoNextThink > CurTime() then return end
	local time = math.random(5,15)
	if IsValid(self.Creator) && self.Creator:HasPerk("perk_fancyfarmer") then
		time = time - ( time / 3 )
	end

	self.DoNextThink = CurTime() + time

	local plevel = self:GetPLevel() -- plant level
	
	plevel = plevel + 1
	self:SetPLevel( plevel )

	if plevel >= 20 then
		self:Grow()
	end
end

hook.Add("PlayerUse", "RemovePlants", function(ply, ent)
	local plant = ent.PlantParent

	if ent.FruitType && ply:HasPerk("perk_fancyfarmer") then
		if (ent.nextCanUpgrade or 0 )< CurTime() then
			if ent:GetPLevel() < 20 then
				ent.nextCanUpgrade = CurTime() + 3
				ent:SetPLevel( ent:GetPLevel() + 1 )
			end
		end
	end
	
	if IsValid(plant) then 
		if (plant.NextUse or 0) > CurTime() then return end
		plant.NextUse = CurTime() + 0.1

		plant.Fruit = plant.Fruit - 1

		if plant.Fruit < 1 then
			timer.Simple(15, function() if IsValid(plant) then plant:Remove() end end)
		end
	end
end)