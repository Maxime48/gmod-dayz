function PMETA:GiveStamina(num)
	local Stamina = self:GetStamina()
	self:SetStamina(Stamina + num)
	if ( Stamina + num ) > 100 then
		self:SetStamina(100)
	end

	self.stamTick = self.stamTick or 0
	if self.stamTick > 9 then
		self.stamTick = 0
		if ( self:GetSafeZoneEdge() or self:GetSafeZone() ) and PHDayZ.Safezone_NoDrain then return end
		
		local hunger, thirst = math.Clamp( self:GetHunger() - 1, 0, 1000 ), math.Clamp( self:GetThirst() - 1, 0, 1000 )
		if hunger > 0 then
			self:SetHunger( hunger )
		end
		if thirst > 0 then
			self:SetThirst( thirst )
		end
	end
end

function PMETA:TakeStamina(num)
	local Stamina = self:GetStamina()
	self:SetStamina( Stamina - num )
	if ( Stamina - num ) < 1 then
		self:SetStamina(0)
	end
end

function SprintDecay(ply, data)
	ply.ChargeInt = ply.ChargeInt or 0 
	
	if ply:KeyPressed(IN_JUMP) and ply:OnGround() then
		ply:TakeStamina(2)
	end

	local weight, max_weight = ply:GetWeight(), ply:GetWeightMax()

	if ply:GetStamina() > 0 and ply:GetRealHealth() > 10 and ply:Health() > 10 && weight < max_weight then
		local a = PHDayZ.Player_DefaultRunSpeed
		local b = PHDayZ.Player_DefaultWalkSpeed
		local c = PHDayZ.Player_DefaultJumpPower

		if ply:GetRunSpeed() != a then ply:SetRunSpeed( a ) end
		if ply:GetWalkSpeed() != b then	ply:SetWalkSpeed( b ) end
		if ply:GetJumpPower() != c then ply:SetJumpPower( c ) end
	else
		ply:SetRunSpeed( 100 )
		ply:SetWalkSpeed( 100 )
		ply:SetJumpPower( 150 )
	end

    if weight > ( max_weight + (max_weight/10) ) then
		ply:SetRunSpeed( 60 )
		ply:SetWalkSpeed( 60 )
		ply:SetJumpPower( 150 )
    end

	if ply:KeyDown(IN_SPEED) and ply:OnGround() and !ply:InVehicle() && !ply.Noclip then
		if math.abs(data:GetForwardSpeed()) > 0 || math.abs(data:GetSideSpeed()) > 0 then
								
			if ply:GetStamina() > 0 && (ply.ChargeInt or 0) <= CurTime() && ply:HasPerk("perk_cheetah") then
				ply:TakeStamina(1)
				ply.ChargeInt = CurTime() + 0.4		
			elseif ply:GetStamina() > 0 && (ply.ChargeInt or 0) <= CurTime()  then
				ply:TakeStamina(1)
				ply.ChargeInt = CurTime() + 0.2		
			end		
		end
	else
	
		if (ply:GetStamina() or 0) < 100 and (ply.ChargeInt or 0) <= CurTime() and ply:OnGround() and ply:GetHunger() > 0 and ply:GetThirst() > 0 then
			ply.stamTick = ( ply.stamTick or 0 ) + 1
			ply:GiveStamina(1)
			ply.ChargeInt = CurTime() + 0.4
			if ply:GetRadiation() > 60 then
				ply.ChargeInt = ply.ChargeInt + 0.5
			end
		end
		
	end
	
	if ply:GetStamina() > 0 and !ply.CanSprint and ply:GetRealHealth() > 10 then
		ply.CanSprint = true
	elseif ply:GetStamina() <= 0 && ply.CanSprint then
		ply.CanSprint = false
		ply.ChargeInt = CurTime() + 3
	end

	data:SetMoveAngles(data:GetMoveAngles())
end
hook.Add("SetupMove", "SprintDecay",  SprintDecay)

local function SprintExploit(ply, key)
	if !ply:InVehicle() and key == IN_SPEED && !ply.Noclip then
		ply:TakeStamina(2)
	end
end
hook.Add("KeyPress", "SprintDecay", SprintExploit)

//local Old_OnPlayerHitGround = GM.OnPlayerHitGround
function GM:OnPlayerHitGround( ply, inWater, onFloater, speed )
	local vel = ply:GetVelocity()
	ply:SetVelocity( Vector( -( vel.x / 2 ), -( vel.y / 2 ), 0 ) )
	//return Old_OnPlayerHitGround( self, ply, inWater, onFloater, speed )
end