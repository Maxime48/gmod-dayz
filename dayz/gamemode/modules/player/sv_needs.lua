local function StupidPlayers( ply )

	if ply.Dead == true then return end
	if ply.Loading == true then return end
	if !ply.Ready then return end
	if ply.Noclip then return end
		
	ply.NextFireCheck = ply.NextFireCheck or 0

	if ply.NextFireCheck < CurTime() then
		if IsValid( ply:GetGroundEntity() ) and ply:GetGroundEntity():IsOnFire() and !( ply:GetSafeZone() or ply:GetSafeZoneEdge() ) then ply:Ignite(10) end
		
		if ply:IsOnFire() then 
			
			if ply:WaterLevel() > 1 then 
				ply:Extinguish()
				return
			end

			if !( ply:GetSafeZone() or ply:GetSafeZoneEdge() ) then return end

			ply:TakeBlood(1, self, self, DMG_BURN) 
			ply:EmitSound( "player/pl_burnpain"..math.random(1,3)..".wav", 75, 100, 0.2 ) 
			
			if ply:Health() <= 1 then -- If their blood is lower than 1, they die.
				ply.DeathMsg = "died from blood loss."
				ply:Kill()
			end

		end	

		ply.NextFireCheck = CurTime() + 0.3
	end

	ply.NextDrownCheck = ply.NextDrownCheck or 0

	ply.Drowning = ply.Drowning or 0

	if ( ply.nextGeiger or 0 ) < CurTime() then
		if ply:GetRadiation() > 20 then
			ply:EmitSound("player/geiger1.wav", 75, 100, 0.2)
		end

		if ply:GetRadiation() > 40 then
			ply:EmitSound("player/geiger2.wav", 75, 100, 0.2)
		end

		if ply:GetRadiation() > 60 then
			ply:EmitSound("player/geiger3.wav", 75, 100, 0.2)
		end
		ply.nextGeiger = CurTime() + math.random(0.1, 1)
	end
	if ply.NextDrownCheck < CurTime() then

		if ply:WaterLevel() > 2 and ply:Alive() then
			
			ply.Drowning = math.Clamp(ply.Drowning + 1, 0, 30)

			if ply.Drowning > 20 then
				
				ply:TakeBlood(3, self, self, DMG_DROWN)
				ply:EmitSound("player/pl_drown"..math.random(1,3)..".wav", 75, 100, 0.2)

			end

			if ply:Health() <= 1 then
				ply.DeathMsg = "forgot to breathe."
				ply:Kill()
				ply.Drowning = 0
			end

		else

			ply.Drowning = math.Clamp(ply.Drowning - 3, 0, 30)

		end

		ply.NextDrownCheck = CurTime() + 1
	end

end
hook.Add( "SetupMove", "StupidPlayers", StupidPlayers )

local function BloodRegen( ply )

	if ( ply.NextBloodRegen or 0 ) > CurTime() then return end
	
	if ply.Dead == true then return end
	if ply.Loading == true then return end
	if !ply.Ready then return end
	if ply.Noclip then return end

	ply.NextBloodRegen = CurTime() + 5

	if ply:Alive() && ply:Health() <= 1 then -- If their blood is lower than 1, they die.
		ply.DeathMsg = "Died from blood loss."
		ply:Kill()
		return
	end

	if ply:Alive() && ply:GetRealHealth() <= 1 then -- If their health is lower than 1, they die.
		ply.DeathMsg = "Died from sickness."
		ply:Kill()
		return
	end
	
	ply.NextBleedTip = ply.NextBleedTip or 0
	if ply.NextBleedTip < CurTime() and ply:GetBleed() then 
		ply:Tip( 3, "youbleed", Color(255,0,0) )
		ply.NextBleedTip = CurTime() + 10
	end
	
	ply.NextSickTip = ply.NextSickTip or 0
	if ply.NextSickTip < CurTime() and ply:GetSick() then 
		ply:Tip( 3, "yousick", Color(255,0,0) )
		ply.NextSickTip = CurTime() + 10
	end

	local rads = ply:GetRadiation()

	if rads > 25 then
		ply:EmitSound("ambient/voices/cough"..math.random(1,4)..".wav")
		ply:SetRealHealth( ply:GetRealHealth() - 2 )
	end

	if ( ply:GetSafeZoneEdge() or ply:GetSafeZone() ) and PHDayZ.Safezone_NoRegen then return end

	local it = GAMEMODE.Util:GetItemIDByClass(ply.CharTable, "item_hazmat_1")
	
	if ply:GetInRadZone() then
		if it then
			it.quality = it.quality - math.random(3, 6)
			if it.quality < 200 then
				ply:SetRadiation( rads + 1 )
			end
			if it.quality < 100 then 
				ply:BreakItem(it.id, true) -- break it.
			end

            if it.quality < (PHDayZ.AlertQualityLevel or 300) then
        		if (ply.NextTipDegrade or 0) < CurTime() then
        			local name = GAMEMODE.DayZ_Items[it.class].Name
					ply:Tip(3, name.." condition low ["..it.quality.."] - Consider repair!", Color(255,0,0))
        			ply.NextTipDegrade = CurTime() + 10
        		end
       		end

			ply:UpdateChar(it.id, it.class, true)
		else
			ply:SetRadiation( rads + math.random(2,4) )
		end
	else
		if rads > 0 then
			ply:SetRadiation( math.Clamp( rads - 1, 0, 1000) )
		end
	end

	if ply:GetSick() then
		//ply:SetColor( Color(0,255,0,255) )
		ply:EmitSound("ambient/voices/cough"..math.random(1,4)..".wav")
		ply:SetRealHealth( ply:RealHealth() - 2 )

		if math.random(1,50) > 49 then -- Random chance of not being sick anymore
			ply:SetSick( false )
		end
	else
		ply:SetColor( Color(255,255,255,255) )
	end

	local health, hunger, thirst = 0, ply:GetHunger(), ply:GetThirst()

	if ( ply:Health() > 50 ) and rads < 25 then
		if ( ply.NextHealthRegen or 0 ) > CurTime() then return end -- wait

		if ( hunger > 700 ) and ( thirst > 700 ) then -- well fed bonus
			health = 2
		elseif  ( hunger > 500 ) and ( thirst > 500 ) then -- fed bonus
			health = 1
		end

		if health > 0 then

			local maxhealth = ply:GetMaxRealHealth()
			
			if ply:GetRealHealth() >= maxhealth then
				ply:SetRealHealth( maxhealth )
			else
				ply:SetRealHealth( ply:GetRealHealth() + health )
				hunger = math.Clamp( hunger - 2, 0, 1000 ) 
				thirst = math.Clamp( thirst - 2, 0, 1000 )
				--if hunger > 0 then
					ply:SetHunger( hunger > 0 and hunger or 0 )
				--end
				--if thirst > 0 then
					ply:SetThirst( thirst > 0 and thirst or 0 )
				--end
			end

		end
		ply.NextHealthRegen = CurTime() + 10
	end

	if ply:GetBleed() then 
		ply:SetHealth( ply:Health() - 1 )

		local bleed = ents.Create("info_particle_system")
		bleed:SetKeyValue("effect_name", "blood_impact_red_01")
		bleed:SetPos(ply:GetPos() + Vector(0,0,40)) 
		bleed:Spawn()
		bleed:Activate() 
		bleed:Fire("Start", "", 0)
		bleed:Fire("Kill", "", 0.2)
		
		if math.random( 1, 50 ) > 49 then -- Random chance of blood clot stopping bloodloss
			ply:SetBleed( false )
		end
		
		if math.random( 1,50 ) > 49 then -- Random chance of sickness
			ply:SetSick( true )
		end

	end 

	if ply:GetHunger() > 200 and ply:GetThirst() > 200 && ply:GetRealHealth() > 20 then -- not starving, not unhealthy
		
		if ply:Health() != ply:GetMaxHealth() then 

			if ( ply:Health() + 1 ) >= ply:GetMaxHealth() then
				ply:SetHealth( ply:GetMaxHealth() )
			else		
				ply:SetHealth( ply:Health() + 1 )
				hunger = math.Clamp( hunger - 1, 0, 1000 )
				thirst = math.Clamp( thirst - 1, 0, 1000 )
				if hunger > 0 then
					ply:SetHunger( hunger )
				end
				if thirst > 0 then
					ply:SetThirst( thirst )
				end
			end
		end
	end

end
hook.Add( "SetupMove", "BloodRegen", BloodRegen )

local function HungerNeed(ply)
	if !IsValid(ply) then return end
	if ply.Dead or ply.Loading or !ply.Ready or !ply:Alive() or ply.Noclip then return end
	if ply.NextHunger and ( ply.NextHunger > CurTime() ) then return end

	if ply:Alive() and ply:GetHunger() <= 1 and ( ply.nextStarve or 0 ) < CurTime() then
			
		local hp = math.Clamp( ply:GetRealHealth() - PHDayZ.Player_StarvedHit, 0, 1000 )
		if hp >= 0 then
			ply:SetRealHealth( hp )
		end
					
		if PHDayZ.Player_HungerThirstSounds then
			ply:EmitSound( table.Random(HungerSounds), 40 )
		end
		
		ply:Tip( 1, "youstarve", Color(255, 0, 0) )
		ply.nextStarve = CurTime() + 5
	end			

	if ( ply:GetSafeZoneEdge() or ply:GetSafeZone() or ply:GetInArena() ) and PHDayZ.Safezone_NoDrain then return end

	local hunger = math.Clamp( ply:GetHunger() - PHDayZ.Player_StarvedHit, 0, 1000 )
	--if hunger > 0 then
		ply:SetHunger( hunger > 0 and hunger or 0 )
	--end

	ply.NextHunger = CurTime() + PHDayZ.Player_HungerTimer
end
hook.Add( "SetupMove", "HungerNeed", HungerNeed )

local function ThirstNeed(ply)
	if !IsValid(ply) then return end
	if ply.NextThirst and ( ply.NextThirst > CurTime() ) then return end
	if ply.Dead or ply.Loading or !ply.Ready or !ply:Alive() or ply.Noclip then return end
	
	if ply:Alive() and ply:GetThirst() <= 1 and ( ply.nextDry or 0 ) < CurTime() then

		local hp = math.Clamp( ply:GetRealHealth() - PHDayZ.Player_ParchedHit, 0, 1000 )

		if hp >= 0 then
			ply:SetRealHealth( hp )
		end

		if PHDayZ.Player_HungerThirstSounds then
			ply:EmitSound( table.Random(ThirstSounds), 40 )
		end
		
		ply:Tip( 1, "youparched", Color(255, 0, 0) )
		ply.nextDry = CurTime() + 5
	end

	if ( ply:GetSafeZoneEdge() or ply:GetSafeZone() or ply:GetInArena() ) and PHDayZ.Safezone_NoDrain then return end

	local thirst = math.Clamp( ply:GetThirst() - PHDayZ.Player_ParchedHit, 0, 1000 )
	--if thirst > 0 then
		ply:SetThirst( thirst > 0 and thirst or 0 )
	--end
	
	ply.NextThirst = CurTime() + PHDayZ.Player_ThirstTimer
end
hook.Add( "SetupMove", "ThirstNeed", ThirstNeed )