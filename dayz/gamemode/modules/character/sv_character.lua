util.AddNetworkString( "UpdateCharFull" )
util.AddNetworkString( "UpdateBluePrintsFull" )
util.AddNetworkString( "UpdateBluePrint" )
util.AddNetworkString( "RefreshShopInv" )

function PMETA:SetMaxRealHealth( amount )
	self.MaxRealHealth = amount
end

function PMETA:GetHealth()
	return self:Health() -- Yes. I am that autistic.
end

function PMETA:GetMaxRealHealth( amount )
	return self.MaxRealHealth or 100
end

function PMETA:TakeBlood(amount, attacker, inflictor, dmgtype)
	local ohealth = self:Health()
	attacker = attacker or self
	if !IsValid(attacker) then attacker = self end
	
	inflictor = inflictor or self
	if !IsValid(inflictor) then inflictor = self end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(amount)
	dmginfo:SetDamageType(dmgtype or DMG_GENERIC)
	dmginfo:SetAttacker(attacker or self)
	dmginfo:SetInflictor(inflictor or self)

	self:TakeDamageInfo(dmginfo)

	if self:Health() == ohealth then	
		self:SetHealth(self:Health() - amount)
		if self:Health() <= 0 then self:SetHealth(0) end
	end
end

function PMETA:GiveBlood(amount)
	self:SetHealth(self:Health() + amount)
end

function PMETA:UpdateCharModel( face, clothes, gender )	
	face = face or 1
	clothes = clothes or 1
	gender = gender or 0
	
	if face == 99 then
		face = math.random( 1, 4 )
	end
	
	if tonumber( gender ) == 0 then
		self:SetModel( MaleModels[ tonumber( face ) ][ tonumber( clothes ) ] )
	else
		self:SetModel( FemaleModels[ tonumber( face ) ][ tonumber( clothes ) ] )
	end

	self:GodDisable() -- character created disable godmode
	UpdateHat(self)

	self.gender = tonumber(gender)
	self.face = tonumber(face)
	self.clothes = tonumber(clothes)
	
	-- self:SetNWInt( "gender", tonumber( gender ) )
	-- self:SetNWInt( "face", tonumber( face ) )
	-- self:SetNWInt( "clothes", tonumber( clothes ) )
	
	self.oPModel = self:GetModel()
end
concommand.Add( "UpdateCharModel", function( ply, cmd, args ) 
	ply:UpdateCharModel( args[ 1 ], args[ 2 ], args[ 3 ] )
end )

function PMETA:GiveBluePrint( item, silent, cook )

	if !GAMEMODE.DayZ_Items[item] then 
		--MsgAll(item.." doesn't exist in gamemode!")
		return 
	end -- If the item doesn't exist, why give a blueprint for it?

	if self.BPTable[item] then return end -- They already have the blueprint.

	self.BPTable[item] = true

	PLib:QuickQuery( "INSERT INTO `players_blueprints` ( `user_id`, `item` ) VALUES ( " .. self.ID .. ", \"" .. item .. "\" );" )

	if silent then return end

	net.Start( "UpdateBluePrint" )
		net.WriteString( item )
		net.WriteBit( cook )
	net.Send( self )

	local text = cook and "recipe" or "blueprint"
	self:ChatPrint("You have learned the "..text.." for "..GAMEMODE.DayZ_Items[item].Name)

	if ( self.LastEmitBP or 0 ) < CurTime() then
		self:EmitSound("vo/coast/odessa/male01/nlo_cheer0"..math.random(1,4)..".wav", 75, 100, 0.4)
		self.LastEmitBP = CurTime() + 1
	end
end

function PMETA:TakeBluePrint( item )

	if !GAMEMODE.DayZ_Items[item] then return end -- If the item doesn't exist, why take a blueprint for it?

	self.BPTable[item] = nil

	net.Start( "UpdateBluePrintsFull" )
		net.WriteTable( self.BPTable )
	net.Send( self )

end

function PMETA:SendBluePrints()

	net.Start( "UpdateBluePrintsFull" )
		net.WriteTable( self.BPTable )
	net.Send( self )

end

function PMETA:UpdateChar( item, ItemKey, noupdate, reload_weps )
	
	if !noupdate then
		if item then
			self:UpdateWeapons(item, ItemKey, reload_weps)
		else
			self:UpdateWeapons(nil, nil, reload_weps)
		end
	end

	local cat
	if ItemKey then
		cat = GAMEMODE.DayZ_Items[ItemKey].Category
		if !cat then cat = "none" end
    end
    
	net.Start( "UpdateCharFull" )
		net.WriteTable( self.CharTable )
		if cat then
			net.WriteString( cat )
		end
	net.Send( self )
	
	if !noupdate then
		self:CalculateWeight()	
	end
end

function PMETA:GiveMoney( amount )
	if tonumber( amount ) < 0 then
		return false
	end

	self:GiveItem( "item_money", math.Round( amount ), true, 1000, nil, nil, nil, true ) // item_money
end

function PMETA:GiveCredits( amount )
	if tonumber( amount ) < 0 then
		return false
	end

	self:GiveItem( "item_credits", math.Round( amount ), true, 1000, nil, nil, nil, true ) // item_credits
end
