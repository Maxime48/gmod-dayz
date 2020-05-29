util.AddNetworkString("DoProcessBar")
util.AddNetworkString("StopProcessBar")
util.AddNetworkString("process_DoStop")

PMETA = FindMetaTable("Player")

function GM:PlayerSwitchFlashlight( ply, SwitchOn )
	if ply:IsBot() then return false end -- apparently bots attempt to turn their flashlights on?

	if ply:HasItem("item_flashlight", true) or ply:HasPerk("perk_enlightenment") then return true end
	return false
end

-- Taken from DarkRP, credits to FPtje.
local threed = true
local vrad = true
local dynv = true
-- proxy function to take load from PlayerCanHearPlayersVoice, which is called a quadratic amount of times per tick,
-- causing a lagfest when there are many players
local function calcPlyCanHearPlayerVoice(listener)
	if not IsValid(listener) then return end
	listener.DayZCanHear = listener.DayZCanHear or {}
	for _, talker in pairs(player.GetAll()) do
		listener.DayZCanHear[talker] = ( not vrad or -- Voiceradius is off, everyone can hear everyone
		listener:GetShootPos():DistToSqr(talker:GetShootPos()) < 605000 ) --and ( talker:Alive() or !talker.Dead ) -- voiceradius is on and the two are within hearing distance
	end
end

local function DoHorn( ply, key )
	if !SERVER then return end

	if key == IN_RELOAD && ply:InVehicle() then
		local veh = ply:GetVehicle()
		if veh.bSlots then return end 

		if ply == veh:GetDriver() && !veh.SeatNum then

			if ( veh.nextHorn or 0 ) < CurTime() then 

				veh:EmitSound("HL1/fvox/beep.wav", 75, 60, 1)

				veh.nextHorn = CurTime() + 0.3
			end

			-- do horn
		end

	end

    if key == IN_USE && !ply:InVehicle() then

      	local tr = util.TraceLine( {
	        start = ply:EyePos(),
	        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 200,
	        filter = ply
	    } )

      	local ent = tr.Entity

	    if IsValid(ent) && ent:IsVehicle() then
  			

      	end
    end
end
hook.Add("KeyPress", "TurnOnHorn", DoHorn)

hook.Add( "PlayerTick", "playerxpaward", function(ply)
	if !ply:Alive() or ply.Loading or !ply.Ready then return end
	if ( ply.nextXPOverTime or 0 ) > CurTime() then return end

	if PHDayZ.Player_XPPerMin == 0 then return end

	ply:XPAward(PHDayZ.Player_XPPerMin, "Play Bonus")
	ply.nextXPOverTime = CurTime() + 60
end)

/*hook.Add( "PlayerTick", "playerNetworking", function(ply)
	if ( ply.nextNetworkCheck or 0 ) > CurTime() then return end

	for k, v in pairs(player.GetHumans()) do
		if !IsValid(v) then continue end
		if v == ply then continue end

		local numHitBoxGroups = ply:GetHitBoxGroupCount()
		local canSee = false

		for group=0, numHitBoxGroups - 1 do
			local numHitBoxes = ply:GetHitBoxCount( group )

			for hitbox=0, numHitBoxes - 1 do
				local bone = ply:GetHitBoxBone( hitbox, group )

				if v:IsLineOfSightClear( ply:GetBonePosition(bone) + Vector(0,0,15) ) then canSee = true break end
			end
		end

		if v:IsLineOfSightClear( ply:EyePos() + Vector(0,0,15) ) then canSee = true end

		if !v.Ready or v.Loading or v:InVehicle() then canSee = true end

		if v:Team() < 1 or v:Team() > 255 then canSee = true end

		if ply:Team() < 1 or ply:Team() > 255 then canSee = true end

		if !ply.Ready or ply.Loading or ply:InVehicle() then canSee = true end

		if canSee then
		--if ply:IsLineOfSightClear( v ) then
			-- start networking
			StopNetworkingEntity(ply, false, true, v)
		else
			-- stop networking
			StopNetworkingEntity(ply, true, true, v)
		end
	end
	ply.nextNetworkCheck = CurTime() + 0.1

end)
*/
hook.Remove( "PlayerTick", "playerNetworking") -- this was a nice attempt but it's too laggy.


local function canHearVoice(ply, cmd)

	if ( ply.nextVoiceCheck or 0 ) > CurTime() then return end
	ply.nextVoiceCheck = CurTime() + 1
	
	if ply:IsValid() then 
		calcPlyCanHearPlayerVoice(ply) 
	end

	local g = ply:GetGroundEntity()
	if IsValid( g ) && g:IsNPC() && !ply:GetSafeZone() then

		local dmginfo = DamageInfo()
		dmginfo:SetDamage( math.random( 5, 10 ) )
		dmginfo:SetAttacker( g )
		dmginfo:SetDamageType( DMG_SLASH )
		dmginfo:SetDamagePosition( g:GetPos() )

		ply:TakeDamageInfo( dmginfo )

		ply:ScreenFade( SCREENFADE.IN, Color( 200, 0, 0, 128 ), 0.3, 0 )
	end
end
hook.Add("PlayerTick", "DayZCanHearVoice", canHearVoice)
hook.Add("VehicleMove", "DayZCanHearVoice", canHearVoice)

local AbletoHold = {}
AbletoHold["base_item"] = true
AbletoHold["grave"] = true
AbletoHold["backpack"] = true
AbletoHold["prop_physics"] = true
AbletoHold["dz_interactable"] = true
AbletoHold["modulus_skateboard"] = true
hook.Add( "PlayerTick", "PickupObjects", function(ply)
	if !PHDayZ.Player_PickupObjectsWithAlt then return end

	if ply:KeyPressed( IN_WALK ) and !ply.HoldingEnt then
		local tr = ply:GetEyeTraceNoCursor()
		local ent = tr.Entity
		if !IsValid(ent) then return end
		if !AbletoHold[ent:GetClass()] then return end
		
		local min, max = ent:OBBMins(), ent:OBBMaxs()
		local vol = math.abs(max.x-min.x) * math.abs(max.y-min.y) * math.abs(max.z-min.z)
		vol = vol/(4^4)
		--MsgAll(vol)
		if ent.GetPersistent and ent:GetPersistent() then return end
		
		if ent:GetClass() == "prop_physics" && vol > PHDayZ.MaxPropSize then return end

		if ent:IsPlayerHolding() then return end

		if ply:GetPos():DistToSqr(ent:GetPos()) > 100*100 then return end

		if ent:IsOnFire() then
			ply:Tip(3, "ouchfire", Color(255,0,0) ) 
			ply:TakeBlood(5)
			ply:Ignite( math.random(2, 5) )
			ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
			ply:ViewPunch(Angle(-10, 0, 0))
			return false 
		end

		if !ent.Nailed then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then phys:Wake() phys:EnableMotion(true) end
		end
		
		ply:PickupObject(ent)
		ply.HoldingEnt = ent
	end

	if ( !ply:KeyDown( IN_WALK ) ) and ply.HoldingEnt then
		ply:DropObject(ply.HoldingEnt)
		local ent = ply.HoldingEnt
		ply.HoldingEnt = nil

		if !IsValid(ent) then return end

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then 
			phys:Sleep()
			phys:EnableMotion(false) 

			timer.Simple(1, function() if IsValid(ent) && !ent.Nailed then phys:Wake() phys:EnableMotion(true) end end)
		end
	end
end )

local function adminRPName(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end

    local target = args[1]
    table.remove( args, 1 )

	local name = table.concat(args, " ")
	name = firstToUpper(name)
    name = string.Trim( name, " " )

	if string.len( name ) < 2 or string.len( name ) > 30 then
        return 
    end

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if !IsValid(target) then 

    	return 
    end

    target:SetRPName( name )
end
concommand.Add("dz_rpname", adminRPName)

local function setRPName(ply, cmd, args)
	--if !ply.Loading then return end

   	if ( ply.nextRPName or 0 ) > CurTime() then ply:Tip(3, "You cannot set your RPName this quickly! Please wait ".. math.Round( ply.nextRPName - CurTime() ).."s before changing.") return "" end

	local name = table.concat(args, " ")

	RPSetName(ply, name)

    ply.nextRPName = CurTime() + 10

end
concommand.Add("rpname", setRPName)

local function rpnameText(ply, text, team)

    if ( string.sub( text, 2, 7 ) == "rpname" ) or ( string.sub( text, 2, 5 ) == "name" ) or ( string.sub( text, 2, 5 ) == "nick" ) then

     	local tab = string.Explode(" ", text)
     	table.remove(tab, 1) -- remove first entry, since it's the command..
     	
     	if table.Count(tab) == 0 then return "" end 
     	
     	setRPName(ply, nil, tab)
        return ""
    end
end
hook.Add("PlayerSay", "rpnameText", rpnameText)

hook.Add("PlayerDisconnected", "DayZCanHearVoice", function(ply)
	if not ply.DayZCanHear then return end
	for k,v in pairs(player.GetAll()) do
		if not v.DayZCanHear then continue end
		v.DayZCanHear[ply] = nil
	end
end)

function GM:PlayerCanHearPlayersVoice(listener, talker)
	local canHear = listener.DayZCanHear and listener.DayZCanHear[talker]
	return canHear, threed
end

function PMETA:DoProcess(item, name, time, snd, xp, esnd, lock )
	snd = snd or ""
	esnd = esnd or ""
	xp = xp or 2
	
	if self.InProcess then
		self:Tip(3, "cantperform",Color(255,255,0))
		return 
	end

	local donttake 
	local i = item
	if istable(item) then
		i = item.id
	end

	local it
	if isstring(item) then
		it = GAMEMODE.Util:GetItemIDByClass( self.InvTable, item )
		item = it.id
		i = it.class
	end

	if isnumber(i) then
		i = GAMEMODE.Util:GetItemByDBID(self.InvTable, i).class
	end
	
	local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ i ], i

	local func = ItemTable.ProcessFunction
		
	if PHDayZ.InstantProcesses then
		func( self, item, ItemKey )
		return
	end

	local str = name.." "..( ItemTable.Name or "Unknown Item" )
	if self.SetProcessName then self:SetProcessName(str) end
		
	if not lock then lock = true end
	if !self.NoCancelProcess then
		self:Freeze(lock)
	end	
	self.InProcess = true
	self.ItemInHand = ItemKey
	if self.SetProcessItem then self:SetProcessItem(ItemKey) end
	
	timer.Create("DayZ_ProcessTimer_"..self:UniqueID(), time, 1, function() 
		if !IsValid(self) then return end 
		self.InProcess = false 

		if self.ProcessEnt and !IsValid(self.ProcessEnt) then self.ProcessEnt = nil return end 

		self.ProcessEnt = nil
		self.ItemInHand = nil 
		self:XPAward(xp, str) 
		self:EmitSound(esnd, 75, 100, 0.1) 
		if self.SetProcessName then self:SetProcessName("") end
		if self.SetProcessItem then self:SetProcessItem("") end
		self:UnLock()
		func(self, item, ItemKey) 
	end)
	
	timer.Create("DayZ_ProcessSounds_"..self:UniqueID(), (time/3)-0.2, 3, function() 
		if !IsValid(self) then return end 
		self:EmitSound(snd, 75, 100, 0.1) 
	end)
	
	local amount = self.DayZ_MultiCraft_Limit and self.DayZ_MultiCraft_Limit or 1
	net.Start("DoProcessBar")
		net.WriteString(name)
		net.WriteInt(amount, 16)
		net.WriteFloat(time) -- In case of decimals!
		net.WriteString(ItemKey)
	net.Send(self)

	hook.Call("DZ_StartProcess", GAMEMODE, self, item, name, time)
end

net.Receive("process_DoStop", function(len, ply)
	if !IsValid(ply) then return end
	
	local bind = net.ReadString()

	if ply.InProcess && !ply.NoCancelProcess then
		ply:StopProcess()
	end

end)

function PMETA:DoNoItemProcess(name, time, snd, xp, esnd, lock, func)

	snd = snd or ""
	esnd = esnd or ""
	xp = xp or 2
	
	if self.InProcess then
		self:Tip(3, "cantperform",Color(255,255,0))
		return 
	end
	
	if PHDayZ.InstantProcesses then
		func( self )
		return
	end

	local str = name.." "..( ItemTable.Name or "Unknown Item" )
	if self.SetProcessName then self:SetProcessName(str) end
		
	if not lock then lock = true end
	if !self.NoCancelProcess then
		self:Freeze(lock)
	end	
		
	self.InProcess = true

	local vol = 0.3
	if self:Crouching() then vol = 0.1 end
	
	timer.Create("DayZ_ProcessTimer_"..self:UniqueID(), time, 1, function() 
		if !IsValid(self) then return end 
		self.InProcess = false 

		if self.ProcessEnt and !IsValid(self.ProcessEnt) then self.ProcessEnt = nil return end 

		self.ProcessEnt = nil
		self:XPAward(xp, str) 
		self:EmitSound(esnd, 75, 100, vol) 
		if self.SetProcessName then self:SetProcessName("") end
		self:Freeze(false)
		func(self) 
	end)
	
	timer.Create("DayZ_ProcessSounds_"..self:UniqueID(), (time/3)-0.2, 3, function() 
		if !IsValid(self) then return end 
		self:EmitSound(snd, 75, 100, vol) 
	end)
	
	self.ProcessAmt = self.ProcessAmt or 1 -- Validation is always good.
	local amount = self.DayZ_MultiCraft_Limit and self.DayZ_MultiCraft_Limit or self.DayZ_MultiDecompile_Limit and self.DayZ_MultiDecompile_Limit or self.ProcessAmt
	self.ProcessAmt = 1

	net.Start("DoProcessBar")
		net.WriteString(name)
		net.WriteInt(amount, 16)
		net.WriteFloat(time) -- In case of decimals.
		net.WriteString("item_wood")
	net.Send(self)

	--hook.Call("DZ_StartProcess", GAMEMODE, self, item, name, time)

end

function PMETA:DoModelProcess(model, name, time, snd, xp, esnd, lock, func)

	snd = snd or ""
	esnd = esnd or ""
	xp = xp or 2

	if self.InProcess then
		self:Tip(3, "cantperform",Color(255,255,0))
		return 
	end
	
	if PHDayZ.InstantProcesses then
		func( self )
		return
	end

	if self.SetProcessName then self:SetProcessName(name) end
		
	if not lock then lock = true end
	if !self.NoCancelProcess then
		self:Freeze(lock)
	end	
		
	self.InProcess = true

	local vol = 0.3
	if self:Crouching() then vol = 0.1 end
	
	timer.Create("DayZ_ProcessTimer_"..self:UniqueID(), time, 1, function() 
		if !IsValid(self) then return end 
		self.InProcess = false 

		if self.ProcessEnt and !IsValid(self.ProcessEnt) then self.ProcessEnt = nil return end

		self.ProcessEnt = nil
		self:XPAward(xp, name)
		self:EmitSound(esnd, 75, 100, vol) 
		if self.SetProcessItem then self:SetProcessItem(self:GetModel()) end
		if self.SetProcessName then self:SetProcessName("") end
		self:Freeze(false)
		func(self) 
	end)
	
	timer.Create("DayZ_ProcessSounds_"..self:UniqueID(), (time/3)-0.2, 3, function()
		if !IsValid(self) then return end 
		self:EmitSound(snd, 75, 100, vol) 
	end)
	
	self.ProcessAmt = self.ProcessAmt or 1 -- Validation is always good.
	local amount = self.DayZ_MultiCraft_Limit and self.DayZ_MultiCraft_Limit or self.DayZ_MultiDecompile_Limit and self.DayZ_MultiDecompile_Limit or self.ProcessAmt
	self.ProcessAmt = 1

	net.Start("DoProcessBar")
		net.WriteString(name)
		net.WriteInt(amount, 16)
		net.WriteFloat(time) -- In case of decimals.
		net.WriteString(model)
	net.Send(self)

	--hook.Call("DZ_StartProcess", GAMEMODE, self, item, name, time)

end

function PMETA:DoCustomProcess(item, name, time, snd, xp, esnd, lock, func)
	snd = snd or ""
	esnd = esnd or ""
	xp = xp or 2

	if self.InProcess then
		self:Tip(3, "cantperform",Color(255,255,0))
		return 
	end
	
	local ItemTable, ItemKey
	if isnumber( item ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
	elseif ( isstring( item ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
	end

	if istable(item) then
		ItemKey = item.id
	end

	local it, i
	if isstring(item) then
		it = GAMEMODE.Util:GetItemIDByClass( self.InvTable, item )
		if !it then 
			i = item 
		else 
			item = it.id
			i = it.class
		end
	end

	if isnumber(item) then
		i = GAMEMODE.Util:GetItemByDBID(self.InvTable, item).class
	end
	
	local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ i ], i
		
	if PHDayZ.InstantProcesses then
		func( self )
		return
	end

	local str = name.." "..( ItemTable.Name or "Unknown Item" )
	if self.SetProcessName then self:SetProcessName(str) end
		
	if not lock then lock = true end
	if !self.NoCancelProcess then
		self:Freeze(lock)
	end	
		
	self.InProcess = true

	self.ItemInHand = ItemKey
	if self.SetProcessItem then self:SetProcessItem(ItemKey) end

	local vol = 0.3
	if self:Crouching() then vol = 0.1 end
	
	timer.Create("DayZ_ProcessTimer_"..self:UniqueID(), time, 1, function() 
		if !IsValid(self) then return end 
		self.InProcess = false 
	
		if self.ProcessEnt and !IsValid(self.ProcessEnt) then self.ProcessEnt = nil return end 

		self.ProcessEnt = nil
		self.ItemInHand = nil 
		self:XPAward(xp, str) 
		self:EmitSound(esnd, 75, 100, vol) 
		if self.SetProcessName then self:SetProcessName("") end
		if self.SetProcessItem then self:SetProcessItem("") end
		self:Freeze(false)
		func(self, item) 
	end)
	
	timer.Create("DayZ_ProcessSounds_"..self:UniqueID(), (time/3)-0.2, 3, function() 
		if !IsValid(self) then return end 
		self:EmitSound(snd, 75, 100, vol) 
	end)
	
	self.ProcessAmt = self.ProcessAmt or 1 -- Validation is always good.
	local amount = self.DayZ_MultiCraft_Limit or self.DayZ_MultiDecompile_Limit or self.DayZ_MultiCook_Limit or self.DayZ_MultiStudy_Limit or self.ProcessAmt
	self.ProcessAmt = 1

	net.Start("DoProcessBar")
		net.WriteString(name)
		net.WriteInt(amount, 16)
		net.WriteFloat(time) -- In case of decimals.
		net.WriteString(ItemKey)
	net.Send(self)

	hook.Call("DZ_StartProcess", GAMEMODE, self, item, name, time)
end


function PMETA:StopProcess()
	timer.Destroy("DayZ_ProcessTimer_"..self:UniqueID())
	timer.Destroy("DayZ_ProcessSounds_"..self:UniqueID())
	self.InProcess = false

	self.ItemInHand = nil

	self:Freeze(false)
	
	net.Start("StopProcessBar")
	net.Send(self)
	
	if self.SetProcessItem then self:SetProcessItem("") end
	if self.SetProcessName then self:SetProcessName("") end
	hook.Call("DZ_StopProcess", GAMEMODE, self)
end

--Gmods spawn function already autocorrects. Would be a waste to not use it.
function PMETA:MakeBuildSite(pos, angle, model, class, cost)
	local ent = ents.Create("dz_propbp")
	ent.Owner = self

	ent:SetAngles(angle)
	ent.Costs = cost

	ent:Setup(model, class)

	ent:SetPos(pos)
	ent:Spawn()

	return ent
end