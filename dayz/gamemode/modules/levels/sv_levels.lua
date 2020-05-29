util.AddNetworkString( "net_XPAward" )
util.AddNetworkString( "net_LevelUp" )
util.AddNetworkString( "net_AddUnlock" )

function PMETA:XPAward( amount, name, awarded )
	amount = tonumber( amount )
	name = name or ""

	if amount != nil and amount > 0 then

		local perc = PHDayZ.GroupXPBonusPerc
		if perc > 0 && !awarded then
			local tm = self:Team()
			if tm > 1 and tm < 255 then

				for k, v in pairs( team.GetPlayers( tm ) ) do
					if v == self then continue end -- ignore 

					v:XPAward( math.Round( ( amount / 100 ) * perc), name, self:Nick() )
				end

			end
		end

		if self:IsVIP() then
			amount = amount * 2
		end

		local OldLevel = self:GetLevel()

		self:SetXP( self:GetXP() + math.Round( amount ) )
		
		if name != "" and awarded then
			name = name .. " - " .. awarded
		end

		net.Start( "net_XPAward" )
			net.WriteFloat( math.Round(amount) )
			net.WriteString( name )
		net.Send( self )
		
		if self:GetXP() >= ( PHDayZ.Player_XPLevelMultiplier * OldLevel ) then

			if OldLevel == 99 then
				self:SetXP( ( PHDayZ.Player_XPLevelMultiplier * OldLevel ) - 1 )
				self:EmitSound("npc/crow/alert"..math.random(2,3)..".wav", 75, 100)
				return
			end

			self:SetLevel( self:GetLevel() + 1 )
			self:SetXP( 0 )
		end
		
		-- LEVEL UP!
		local NewLevel = self:GetLevel()
		if NewLevel > OldLevel then
			self:LevelUp()
		end
		
		hook.Call( "DZ_OnXPAward", GAMEMODE, self, amount )

	end
end

function PMETA:GiveLevels( amount )
	local OldLevel = self:GetLevel()

	self:SetLevel( self:GetLevel() + amount )

	if self:GetLevel() > OldLevel then
		self:LevelUp()
	end
end

local function CommandLevels(ply, cmd, args)
	local isconsole = ply:EntIndex() == 0 and true or false
	if !isconsole and !ply:IsSuperAdmin() then return end

	local target = args[1]

	if target then target = GAMEMODE.Util:GetPlayerByName(target) end

	if !args[2] then if isconsole then	
			print("No Levels specified.")
		else
			ply:PrintMessage(HUD_PRINTCONSOLE, "No Levels specified.")
		end
		return
	end
	
	if !target then
		if isconsole then	
			print("No Target specified.")
		else
			ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
		end
		return
	end

	target:GiveLevels( args[2] )
end
concommand.Add("dz_givelevels", CommandLevels)

function PMETA:LevelUp()

	net.Start( "net_LevelUp" )
	net.Send( self )
 
	self:GiveCredits( 5 )

	if self.GiveSkillPoints then
		self:GiveSkillPoints(2)
	end
			
	self:EmitSound( "smb3_powerup.wav", 35, 100 )

	hook.Call( "DZ_OnLevelUp", GAMEMODE, self )
	
end