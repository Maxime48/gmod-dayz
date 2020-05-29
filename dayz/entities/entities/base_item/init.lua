AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

util.AddNetworkString("base_ItemAction")
util.AddNetworkString("net_Money")

function ENT:ChangeItem( item, amount )
	item = GAMEMODE.DayZ_Items[item]

	self.ItemTable = item
	self:SetModel(item.Model)

	if item.Material then
		self:SetMaterial( item.Material )
	end

	if item.Color then
		self:SetColor( item.Color )
	end
	
	if item.Skin then
		self:SetSkin( item.Skin )
	end

	if item.BodyGroups then
		self:SetBodyGroups( item.BodyGroups )
	end

	local rarity = GetRarity( self:GetRarity() or 1 )
	if rarity && item.Weapon then
		self:SetColor(rarity.color)
	end

	self:SetAmount( amount or 1 )
	self:SetItem( item.ID )

	self:SetHealth( 300 )

	if item.EEgg then
		self:SetHealth(1)
	end

	self:SetPerish( CurTime() + PHDayZ.ItemPerishTime or 300 )
end

function ENT:StartTouch( ent )
	if not IsValid(ent) then return end
	if not ent.ItemTable then return end
	if ent.RanTouch then return end
	
	if ent.ItemTable.ID == self.ItemTable.ID then 
		if ( self:GetQuality() < 100 and ent:GetQuality() > 100 ) or ( self:GetQuality() > 100 and ent:GetQuality() < 100 ) then return end

		if self:GetRarity() != ent:GetRarity() then return end
		
		ent.RanTouch = true -- Duplication due to more than one Touch running if you're lucky enough.

		local q1 = ( self:GetQuality() * self:GetAmount() ) 
		local q2 = ( ent:GetQuality() * ent:GetAmount() ) 

		self:SetAmount( self:GetAmount() + ( ent:GetAmount() or 1 ) )
		local qual = math.Round( (q1 + q2) / self:GetAmount() ) 

		self:SetQuality(qual)

		ent:Remove()
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth( self:Health() - dmginfo:GetDamage() )
	if self:Health() < 1 then
		ItemDestroyed(self:GetPos())
		self:Remove()
	end
end

function ENT:Think()
	if (self.DoNextThink or 0) > CurTime() then return end

	if SERVER then

		local max = self:OBBMaxs()

		local tr = {}
		tr.start = self:GetPos() + max 
		tr.endpos = tr.start - Vector(0, 0, 1000)
		tr.filter = self
		tr = util.TraceLine(tr)
		
		if tr.HitNoDraw and !self.noNetwork and !self:GetSafeZone() then -- If for some reason it's spawned outside the map or falls out.
			if PHDayZ.DebugMode then
				MsgC( Color(0,255,0), "[PHDayZ] ", Color(255, 255, 0), self.ItemTable.Name.." | "..self.ItemTable.ID.." - Removed, Outside Map!\n" ) 
			end
			self:Remove()
			return
		end
	end

	if self:GetPerish() < CurTime() && !self.noperish then
		if !self:IsOnFire() then

			ItemDestroyed( self:GetPos() )
		
			if PHDayZ.DebugMode then
				MsgC( Color(0,255,0), "[PHDayZ] ", Color(255, 255, 0), self.ItemTable.Name.." | "..self.ItemTable.ID.." - Perished!\n" ) 
			end

			self:Remove()
		end
	end

	self.DoNextThink = CurTime() + 1 -- Let's check once a second, for performances sake.
end

function ENT:OnRemove()
	if self.SpawnLoot then
		TotalSpawnedLoot = TotalSpawnedLoot - 1
	end
end

function ENT:Consume(activator, ty)
	if !activator:IsPlayer() then return end
	if !activator:CanPerformAction() then return end

	activator:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_PLACE)

	activator.ProcessAmt = self:GetAmount()
	local time = 1 
	if activator:HasPerk("perk_scavenger") then
		time = time / 2
	end
	if activator:HasSkill("dex_slightofhand") then
		time = time - (time / 5)
	end

	if self.ItemTable.EatFunction and ty == 1 then
		self.ItemTable.EatFunction(activator, { id=self.ItemTable.ID, ent=self } )
	elseif self.ItemTable.DrinkFunction and ty == 2 then
		self.ItemTable.DrinkFunction(activator, { id=self.ItemTable.ID, ent=self } )
	elseif self.ItemTable.Function and ty == 3 then
		self.ItemTable.Function(activator, { id=self.ItemTable.ID, ent=self } )
	end

	activator.ProcessEnt = self
end

function ENT:CustomFunc( activator )
	if !activator:IsPlayer() then return end

	if self.ItemTable.CustomFunc then self.ItemTable.CustomFunc(activator, self.ItemTable.ID, self) end
end

function ENT:IgniteFunc( activator )
	if !IsValid(activator) then return end

	local time = 3
	if !activator:HasItem("item_firestarter", true) then 
		time = 20
		activator:Tip(3, "You need a firestarter to start fires quickly!", Color(255,255,0,255))
	end

	activator:DoCustomProcess(self.ItemTable.ID, "Igniting", time, "", 0, "", true, function(activator, item)

		if !IsValid(activator) or !activator:Alive() then return end
		if !IsValid(self) then return end

		self:Ignite( 15 )
		timer.Create( "DZ_EntityIgnite"..self:EntIndex(), 15, 0, function() 

			if IsValid(self) then 

				local charcoal = ents.Create("base_item")
				charcoal:SetPos( self:GetPos() + Vector(0,0,5) )
		        charcoal:SetItem( "item_charcoal" )
		        charcoal.Amount = 1
		        charcoal:SetAmount(1)
		        charcoal:SetQuality(self:GetQuality() or 500 )
		        charcoal:SetRarity( self:GetRarity() or 1 )
		        
		        charcoal:Activate()
		        charcoal:Spawn()

				if self:GetAmount() > 1 then
					self:SetAmount( self:GetAmount() - 1 )

					self:Ignite( 15 )
					self:SetHealth(1000)
				else
					timer.Remove( "DZ_EntityIgnite"..self:EntIndex() )
					self:Remove() 
				end
			end 

		end)

		--if math.random(1, 100) > 90 && activator:HasItem("item_firestarter", true) then
			--activator:TakeItem("item_firestarter", 1)
		--end

	end)
end

/*
function ENT:PhysicsCollide( data, phys )
	if DZ_Quests && IsValid(self.gThrower) && self.ItemTable.EEgg && ( self:GetVelocity():Length() > 50 ) then 
		local c = self:GetColor()

		local ply = data.HitEntity

		if IsValid(ply) and ply:IsPlayer() then

			local hun, thi = ply:GetHunger(), ply:GetThirst()

			ply:SetHunger( math.Clamp(hun + 50, 0, 1000) )
			ply:SetThirst( math.Clamp(thi + 50, 0, 1000) )

			ply:Tip(3, "You just got Egged!", Color(0,255,0,255) )

			if !self.gThrower:GetSafeZone() and !self.gThrower:GetInArena() and !self.gThrower:GetSafeZoneEdge() then 
				self.gThrower:Tip(3, "You just Egged "..ply:Nick().."!", Color(0,255,0,255) )
				self.gThrower:DoQuestProgress("quest_easter3", 1)

				if self.gThrower:InQuest("quest_easter3") then
					self.gThrower:XPAward(25, "Easter Event")
				end
			end

			local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
			effectdata:SetStart( Vector( c.r, c.g, c.b ) )
			util.Effect( "balloon_pop", effectdata )
			self:Remove()

		end
	end
end
*/

function ENT:Use( activator, caller ) 
	if self.noNetwork then return end
	if self:GetPos():DistToSqr( caller:GetPos() ) > (300*300) then return end
	if IsValid(caller) and caller:IsPlayer() then 
		timer.Simple(0.1, function()
			if !IsValid(caller) then return end
			if !caller:KeyDown(IN_USE) and ( caller:HasPerk("perk_scavenger") ) then 
				if !IsValid(self) then return end
				self:Pickup(caller) 
			end 
		end)
	end 
end

function ENT:Pickup( activator )
	if !activator:IsPlayer() then return end
	if !activator:CanPerformAction() then return end

	if self.noNetwork then return end
	if self:GetPos():DistToSqr( activator:GetPos() ) > (300*300) then return end

	if IsValid(self:GetActivator()) then return end -- sucks to be you, someone else is using item right now.

	activator:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_PLACE)
	self:SetActivator(activator)

	activator.ProcessAmt = self:GetAmount()
	local time = 1 
	if activator:HasSkill("dex_grabngo") then
		time = time - ( time / 5 )
	end

	timer.Simple(time, function()
		if IsValid(self) then 
			self:SetActivator(nil) 
		end
	end)

	local xp = 0
	if self.SpawnLoot then
		xp = 2
	end
	
	activator:DoCustomProcess(self.ItemTable.ID, "Collecting", time, "", xp, "", true, function(activator, item)

		if !IsValid(activator) or !activator:Alive() then return end
		if !IsValid(self) then return end

		if self.noNetwork then return end

		if activator.Noclip == true then
			activator:Tip( 1, "noclipweightrestriction" )	
		end

		local amount = self:GetAmount() or 1

		if self.ItemTable.Attachment != nil then
			if CustomisableWeaponry then CustomizableWeaponry:giveAttachment( activator, ItemTable.Attachment ) end
		end
		
		if self.ItemTable.ID == "item_money" then
			net.Start("net_Money")
				net.WriteFloat( amount )
			net.Send(activator)

			if self.NPCDropped && DZ_Quests then
				activator:DoQuestProgress("quest_inshell", amount)
			end
		end
		
		if activator:Crouching() then
			activator:EmitSound( "items/itempickup.wav", 25, 100 )
		else
			activator:EmitSound( "items/itempickup.wav", 50, 100 )
		end

		local it = {}
		it.found_id = self:GetFounder()
		it.foundtype = self:GetFoundType()
		it.foundwhen = self:GetFoundWhen()

		activator:GiveItem( self.ItemTable.ID, amount, nil, self:GetQuality(), self:GetRarity(), nil, false, true, nil, nil, it )

		if amount < ( self:GetAmount() or 1 ) then
			self:SetAmount( self:GetAmount() - amount )		
			return
		end

		if !self.Dropped && self.ItemTable.Weapon then
			local wep = weapons.GetStored( self.ItemTable.Weapon )
			local ammotype = wep.Primary.Ammo
			if ammotype then
				local aItemTable, aItemKey = GAMEMODE.Util:GetItemByAmmoType( ammotype )
				if aItemTable && aItemTable.ClipSize then
					local amount = math.Rand(0, aItemTable.ClipSize) 
					if amount > 0 then
						activator:GiveItem(aItemKey, amount)
					end
				end
			end
		end

		self:Remove()
	end)
end

net.Receive("base_ItemAction", function(len, ply)
	local usetype = net.ReadUInt(4) 
	local entindex = net.ReadUInt(32)
	local ty = net.ReadUInt(4)

	local ent = Entity(entindex)
	if !IsValid(ent) then return end

	if ent:GetClass() != "base_item" then return end -- Incase some fucker starts exploiting.
	if ent.noNetwork then return end -- it's not being networked, so it's not usable, fuck off.

	if ent:GetPos():DistToSqr( ply:GetPos() ) > (300*300) then return end

	if ent:IsOnFire() then
		ply:Tip(3, "ouchfire", Color(255,0,0) ) 
		ply:TakeBlood(5)
		ply:Ignite( math.random(2, 5) )
		ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
		ply:ViewPunch(Angle(-10, 0, 0))
		return false 
	end

	if usetype == 1 then
		ent:Consume( ply, ty )
	elseif usetype == 2 then
		ent:Pickup( ply )
	elseif usetype == 3 then
		ent:CustomFunc( ply )
	elseif usetype == 4 then
		ent:IgniteFunc( ply )
	elseif usetype == 5 then
		
		ply:EquipItem( ent.ItemTable.ID, ent )

	end

end)

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end