PMETA = FindMetaTable("Player")

function GM:OnEntityCreated( ent )
	if ent:IsPlayer() then

		ent:InstallDataTable()
		ent:NetworkVar("Int", 0, "Hunger")
		ent:NetworkVar("Int", 1, "Thirst")
		ent:NetworkVar("Int", 2, "RealHealth")
		ent:NetworkVar("Int", 3, "Stamina")
		ent:NetworkVar("Int", 4, "XP")
		ent:NetworkVar("Int", 5, "Level") 
		-- deliberately missing 6, seems to conflict with EnterVehicle?
		ent:NetworkVar("Int", 7, "PVPTime")
		ent:NetworkVar("Int", 8, "Radiation")
		ent:NetworkVar("Int", 9, "AdditionalWeight")
		ent:NetworkVar("Int", 10, "PArmor")
		ent:NetworkVar("Int", 11, "FreshSpawn")
		ent:NetworkVar("Int", 12, "PFrags") -- Permanent frags, tracked on scoreboard

		ent:NetworkVar("Bool", 0, "Bleed")
		ent:NetworkVar("Bool", 1, "Sick")
		ent:NetworkVar("Bool", 3, "SafeZone")
		ent:NetworkVar("Bool", 4, "SafeZoneEdge")
		ent:NetworkVar("Bool", 5, "InRadZone")
		ent:NetworkVar("Bool", 6, "BleedingOut")
		ent:NetworkVar("Bool", 7, "InArena")

		ent:NetworkVar("String", 0, "ProcessName")
		ent:NetworkVar("String", 1, "ProcessItem")
		ent:NetworkVar("String", 2, "RPName") -- Yes, RP elements... it was requested

	elseif ent:IsVehicle() then
		
       	timer.Simple(0.1, function()  -- we need to do this next frame..
       		if !IsValid(ent) then return end

			ent:InstallDataTable()
			ent:NetworkVar("Int", 0, "Fuel", { KeyName = "Fuel", Edit = { type = "Int", order = 1, min = 0, max = 100 } } )
			--ent:NetworkVar("Bool", 0, "SafeZone")
			--ent:NetworkVar("Bool", 1, "SafeZoneEdge")

       		if !SERVER then return end
       		if ent.bSlots then return end 

       		ent:SetFuel( math.random(20, 60) )
			ent:SetHealth(PHDayZ.VehicleMaxHealth or 500)	
			ent:SetMaxHealth(PHDayZ.VehicleMaxHealth or 500)

           	--MsgAll( ent.MetaBaseClass, ent.ClassName )


           	if !ent.GetVehicleClass then return end

 			local veh_list = list.Get( "Vehicles" )
            local veh_table = veh_list[ ent:GetVehicleClass() ]
            local seatdata = veh_table

          	ent.Seats = ent.Seats or {}
	
            if seatdata then

	           	if table.Count(ent.Seats) > 0 then MsgAll("Seats for car already created") return end -- something else has made seats already.

	            local vcextraseats = seatdata.VC_ExtraSeats
	           	
	           	if !vcextraseats then return end
	            for a, b in pairs(vcextraseats) do

	            	local Seat = ents.Create("prop_vehicle_prisoner_pod")
    				Seat:SetModel("models/props_phx/carseat2.mdl")
    				Seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt") 
    				Seat:SetKeyValue("limitview", "0")
	                Seat:SetAngles( AngleCombCalc( ent:GetAngles(), b.Ang or Angle(0,0,0) ) )
	                Seat:SetPos( VToWorld( ent, b.Pos ) + Vector( 0, 0, 11 ) )
	                Seat:SetParent( ent )
	                Seat.SeatNum = a
	                Seat.DriveBy = true -- DayZ support allowing weapons in passenger seats.
	                Seat:SetNoDraw(false)

	                if b.Hide then
	                    Seat:SetColor(Color(255,255,255, 0))
	                    Seat:SetRenderMode( RENDERMODE_TRANSALPHA )
	                end
	               
	                --constraint.Weld(Seat, ent, 0,0,0,0)
	                                 
	                Seat.VehicleName = "Seat"
	                Seat.ClassOverride = "prop_vehicle_prisoner_pod"

	                Seat:Spawn()
	                
	                Seat:SetNotSolid(true)
	                

	                --Seat:DeleteOnRemove( ent )
	                table.insert(ent.Seats, Seat)
	            end

	        end

        	--local hasengine = ent:LookupAttachment( "vehicle_engine" )
			--if hasengine != 0 then

				ent.ArmorThreshold = 5

				ent.Smoking = false
				ent.Flaming = false
				ent.ExplosionImminent = false

				ent:AddCallback( "PhysicsCollide", VehicleDamage_Collide )
				--ent:AddCallback( "Think", VehicleDamage_DoThink )

				if ent.CrashResist == nil then
					ent.CrashResist = 0.5
				end

				ent.OriginalTexture = ent:GetMaterial()
			--end	

			-- addcallback doesn't work for think??
			ent.oThink = ent.Think
			ent.Think = function(...)

				VehicleDamage_DoThink( ent )							
				--if ent.oThink then ent.oThink() end

				timer.Simple(0.5, function() if ent:IsValid() then ent:Think() end end)
			end

			ent:Think()
	   
		end)


	elseif ent:GetClass() == "prop_ragdoll" then
		ent:InstallDataTable()
		ent:NetworkVar("String", 0, "StoredModel")
		ent:NetworkVar("String", 1, "StoredName")
		ent:NetworkVar("String", 2, "StoredReason")
		ent:NetworkVar("Int", 0, "Perish")
	elseif ent:GetClass() == "prop_physics" then
		ent.RenderGroup = RENDERGROUP_OPAQUE
	elseif ent:IsNPC() then

		timer.Simple(0.1, function() -- stump this because it can't create datatables earlier than next frame.
			if !IsValid(ent) then return end
			
			ent:InstallDataTable()
			ent:NetworkVar("Int", 0, "Level")
		end)
	end
end

function RPSetName(ply, name)

	local old_name = ply:Nick()

	local f_name = string.match(name, "[%a%s%p%d_]+")

	if string.lower(f_name or "") != string.lower(name) then
		if SERVER then
 			ply:Tip(3, "This Name contains invalid characters, remove them!")
 		else
 			MakeTip(3, "This Name contains invalid characters, remove them!", Color(255,255,0,255))
 		end		
		return false
	end

	name = f_name

	name = firstToUpper(name)
    name = string.Trim( name, " " )

    if string.len(name) < 2 then 
		if SERVER then
 			ply:Tip(3, "This RPName is too short, min 2!")
 		else
 			MakeTip(3, "This RPName is too short, min 2!", Color(255,255,0,255))
 		end
    	return false 
    end

	if string.len( name ) < 2 or string.len( name ) > 30 then
 		if SERVER then
 			ply:Tip(3, "This RPName is too long, max 30!")
 		else
 			MakeTip(3, "This RPName is too long, max 30!", Color(255,255,0,255))
 		end
        return false
    end

    local foundply
    for k, v in pairs( player.GetAll() ) do
    	local nick = string.lower(v:Nick())
    	if nick == string.lower(name) && ply != v then
    		foundply = v
    		break
    	end
    end

    if foundply then
    	if SERVER then
    		ply:Tip(3, "This RPName is taken, choose another!")
    	else
    		MakeTip(3, "This RPName is taken, choose another!", Color(255,255,0,255))
    	end
    	return false
    end

    if SERVER then
    	if old_name == name then return true end 

	    MsgAll("[PHDayZ] Player ("..ply:Nick(true)..") - "..old_name.."["..ply:SteamID().."] changed name to "..name.."\n")

		ply:SetRPName(name)
	end

	return true
end

PMETA.oName = PMETA.oName or PMETA.Name
function PMETA:Name(old)
	if !old && self.GetRPName && self:GetRPName() != "" then
		if self:GetRPName() == "nil" then self:SetRPName( self:Nick(true) ) end
		
		return (self:GetAFK() and "[AFK] " or "")..self:GetRPName()
	end
	return (self:GetAFK() and "[AFK] " or "")..self:oName()
end

PMETA.oNick = PMETA.oNick or PMETA.Nick
function PMETA:Nick(old)
	if !old && self.GetRPName && self:GetRPName() != "" then
		if self:GetRPName() == "nil" then self:SetRPName( self:Nick(true) ) end

		return self:GetRPName()
	end
	return self:oNick()
end

PMETA.oGetName = PMETA.oGetName or PMETA.GetName
function PMETA:GetName(old)
	if !old && self.GetRPName && self:GetRPName() != "" then
		if self:GetRPName() == "nil" then self:SetRPName( self:Nick(true) ) end

		return self:GetRPName()
	end
	return self:oGetName()
end

function PMETA:PFrags()
	return isfunction(self.GetPFrags) and self:GetPFrags() or 0
end

-- just some helper functions
function PMETA:AddPFrags(amt)
	local c_amt = self:GetPFrags()

	self:SetPFrags( c_amt + amt )
end

function PMETA:TakePFrags(amt)
	local c_amt = self:GetPFrags()

	self:SetPFrags( c_amt - amt )
end

function PMETA:GetThirdPerson()
	if GetConVar( "simple_thirdperson_enabled" ):GetBool() && !self:KeyDown(IN_ATTACK2) then
		return false
	end
	return false
end

/*                                                                                                             
 ,---. ,--.              ,--.          ,--------,--.    ,--.        ,--,------.                                 
'   .-'`--,--,--,--.,---.|  |,---.     '--.  .--|  ,---.`--,--.--.,-|  |  .--. ',---.,--.--.,---. ,---.,--,--,  
`.  `-.,--|        | .-. |  | .-. :       |  |  |  .-.  ,--|  .--' .-. |  '--' | .-. |  .--(  .-'| .-. |      \ 
.-'    |  |  |  |  | '-' |  \   --.       |  |  |  | |  |  |  |  \ `-' |  | --'\   --|  |  .-'  `' '-' |  ||  | 
`-----'`--`--`--`--|  |-'`--'`----'       `--'  `--' `--`--`--'   `---'`--'     `----`--'  `----' `---'`--''--'
By FailCake :D (edunad)
*/

// SHARED
CreateConVar("simple_thirdperson_maxdistance", "200", { FCVAR_REPLICATED } , "Sets the max distance the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_maxpitch", "0", { FCVAR_REPLICATED } , "Sets the max pitch the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_maxright", "100", { FCVAR_REPLICATED } , "Sets the max right the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_maxyaw", "0", { FCVAR_REPLICATED } , "Sets the max yaw the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_maxup", "100", { FCVAR_REPLICATED } , "Sets the min up the player can go (0 = disabled)")

CreateConVar("simple_thirdperson_mindistance", "0", { FCVAR_REPLICATED } , "Sets the min distance the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_minpitch", "0", { FCVAR_REPLICATED } , "Sets the min pitch the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_minright", "0", { FCVAR_REPLICATED } , "Sets the min right the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_minyaw", "0", { FCVAR_REPLICATED } , "Sets the min yaw the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_minup", "0", { FCVAR_REPLICATED } , "Sets the min up the player can go (0 = disabled)")

CreateConVar("simple_thirdperson_shoulder_maxdist", "100", { FCVAR_REPLICATED } , "Sets the max shoulder distance the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_shoulder_mindist", "0", { FCVAR_REPLICATED } , "Sets the min shoulder distance the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_shoulder_maxup", "100", { FCVAR_REPLICATED } , "Sets the max shoulder up the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_shoulder_minup", "0", { FCVAR_REPLICATED } , "Sets the min shoulder up the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_shoulder_maxright", "100", { FCVAR_REPLICATED } , "Sets the max shoulder right the player can go (0 = disabled)")
CreateConVar("simple_thirdperson_shoulder_minright", "0", { FCVAR_REPLICATED } , "Sets the min shoulder right the player can go (0 = disabled)")

CreateConVar("simple_thirdperson_forcecollide", "1", { FCVAR_REPLICATED } , "Forces the player to use collide or not (0 = disabled,1 = on,2 = off)")
CreateConVar("simple_thirdperson_forceshoulder", "0", { FCVAR_REPLICATED } , "Forces the player to use shoulder view or not (0 = disabled,1 = on,2 = off)")
CreateConVar("simple_thirdperson_forcesmooth", "1", { FCVAR_REPLICATED } , "Forces the player to use smooth view or not (0 = disabled,1 = on,2 = off)")

if CLIENT then
	CreateClientConVar( "simple_thirdperson_enabled", "0", true, false )
	
	CreateClientConVar( "simple_thirdperson_smooth", "1", true, false )
	CreateClientConVar( "simple_thirdperson_smooth_mult_x", "0.3", true, false )
	CreateClientConVar( "simple_thirdperson_smooth_mult_y", "0.3", true, false )
	CreateClientConVar( "simple_thirdperson_smooth_mult_z", "0.3", true, false )
	CreateClientConVar( "simple_thirdperson_smooth_delay", "10", true, false )
	
	CreateClientConVar( "simple_thirdperson_collision", "1", true, false )
	CreateClientConVar( "simple_thirdperson_cam_distance", "100", true, false )
	CreateClientConVar( "simple_thirdperson_cam_right", "0", true, false )
	CreateClientConVar( "simple_thirdperson_cam_up", "0", true, false )
	
	CreateClientConVar( "simple_thirdperson_cam_pitch", "0", true, false )
	CreateClientConVar( "simple_thirdperson_cam_yaw", "0", true, false )
	
	CreateClientConVar( "simple_thirdperson_shoulderview_dist", "50", true, false )
	CreateClientConVar( "simple_thirdperson_shoulderview_up", "0", true, false )
	CreateClientConVar( "simple_thirdperson_shoulderview_right", "40", true, false )
	CreateClientConVar( "simple_thirdperson_shoulderview", "0", true, false )
	CreateClientConVar( "simple_thirdperson_shoulderview_bump", "0", true, false )
	
	CreateClientConVar( "simple_thirdperson_fov_smooth", "1", true, false )
	CreateClientConVar( "simple_thirdperson_fov_smooth_mult", "0.3", true, false )
	
	CreateClientConVar( "simple_thirdperson_hide_crosshair", "0", true, false )
	CreateClientConVar( "simple_thirdperson_enable_custom_crosshair", "0", true, false )
	
	CreateClientConVar( "simple_thirdperson_custom_crosshair_r", "255", true, false )
	CreateClientConVar( "simple_thirdperson_custom_crosshair_g", "230", true, false )
	CreateClientConVar( "simple_thirdperson_custom_crosshair_b", "0", true, false )
	CreateClientConVar( "simple_thirdperson_custom_crosshair_a", "240", true, false )
end

if CLIENT then	
	
	local Editor = {}

	Editor.DelayPos = nil
	Editor.ViewPos = nil

	function ServerBool(cmd_server,cmd_client)
		
		local srv_shoulder = GetConVar(cmd_server):GetInt()
		
		if srv_shoulder == 0 then
			return IntToBool(GetConVar( cmd_client ):GetInt())
		elseif srv_shoulder == 1 then
			return true
		elseif srv_shoulder == 2 then
			return false
		end
	end
	
	function ServerNumber(cmd_server_max,cmd_server_min,cmd_client,default)
	
		local value = default
		
		local SrvMax = GetConVar( cmd_server_max ):GetFloat() or 0
		local SrvMin = GetConVar( cmd_server_min ):GetFloat() or 0
		
		local ClnVal = GetConVar( cmd_client ):GetFloat()
		
		if SrvMin > SrvMax then return ClnVal end
		
		if SrvMax != 0 and SrvMin != 0 then
			if ClnVal <= SrvMax and ClnVal >= SrvMin then
				value = ClnVal
			else
				value = SrvMax
			end
		else
			value = ClnVal
		end
		
		return value
	end
	
	function IntToBool(int)
		if int == 1 then
			return true
		else
			return false
		end
	end
	
	function BoolToInt(bol)
		if bol then
			return 1
		else
			return 0
		end
	end

	hook.Add("ShouldDrawLocalPlayer", "SimpleTP.ShouldDraw", function(ply)
		if GetConVar( "simple_thirdperson_enabled" ):GetBool() && !ply:KeyDown(IN_ATTACK2) && PHDayZ.ThirdPerson then
			return true
		end
	end)
		
	hook.Add("CalcView","SimpleTP.CameraView",function(ply, pos, angles, fov)
	
		if GetConVar( "simple_thirdperson_enabled" ):GetBool() and IsValid(ply) && !ply:KeyDown(IN_ATTACK2) && PHDayZ.ThirdPerson then
			if Editor.DelayPos == nil then
				Editor.DelayPos = ply:EyePos()
			end
			
			if Editor.ViewPos == nil then
				Editor.ViewPos = ply:EyePos()
			end
			

			Editor.DelayFov = fov
			
			local view = {}
		
			local Forward = ServerNumber("simple_thirdperson_maxdistance","simple_thirdperson_mindistance","simple_thirdperson_cam_distance")
			
			local Up = ServerNumber("simple_thirdperson_maxup","simple_thirdperson_minup","simple_thirdperson_cam_up")
			local Right = ServerNumber("simple_thirdperson_maxright","simple_thirdperson_minright","simple_thirdperson_cam_right")
			
			local Pitch = ServerNumber("simple_thirdperson_maxpitch","simple_thirdperson_minpitch","simple_thirdperson_cam_pitch")
			local Yaw = ServerNumber("simple_thirdperson_maxyaw","simple_thirdperson_minyaw","simple_thirdperson_cam_yaw")
			
			if ServerBool("simple_thirdperson_forceshoulder","simple_thirdperson_shoulderview") then
			
				if GetConVar( "simple_thirdperson_shoulderview_bump" ):GetBool() and ply:GetMoveType() != MOVETYPE_NOCLIP then
					angles.pitch = angles.pitch + (ply:GetVelocity():Length() / 300) * math.sin(CurTime() * 10)
					angles.roll = angles.roll + (ply:GetVelocity():Length() / 300) * math.cos(CurTime() * 10)
				end
				
				Forward = ServerNumber("simple_thirdperson_shoulder_maxdist","simple_thirdperson_shoulder_mindist","simple_thirdperson_shoulderview_dist")
				Up = ServerNumber("simple_thirdperson_shoulder_maxup","simple_thirdperson_shoulder_minup","simple_thirdperson_shoulderview_up")
				Right = ServerNumber("simple_thirdperson_shoulder_maxright","simple_thirdperson_shoulder_minright","simple_thirdperson_shoulderview_right")
			else
			
				angles.p = angles.p + Pitch
				angles.y = angles.y + Yaw
			
			end
			
			if ServerBool("simple_thirdperson_forcesmooth","simple_thirdperson_smooth") then
			
				Editor.DelayPos = Editor.DelayPos + (ply:GetVelocity() * (FrameTime() / GetConVar( "simple_thirdperson_smooth_delay" ):GetFloat()))
				Editor.DelayPos.x = math.Approach(Editor.DelayPos.x, pos.x, math.abs(Editor.DelayPos.x - pos.x) * GetConVar( "simple_thirdperson_smooth_mult_x" ):GetFloat())
				Editor.DelayPos.y = math.Approach(Editor.DelayPos.y, pos.y, math.abs(Editor.DelayPos.y - pos.y) * GetConVar( "simple_thirdperson_smooth_mult_y" ):GetFloat())
				Editor.DelayPos.z = math.Approach(Editor.DelayPos.z, pos.z, math.abs(Editor.DelayPos.z - pos.z) * GetConVar( "simple_thirdperson_smooth_mult_z" ):GetFloat())

			else
				Editor.DelayPos = pos
			end
			
			if GetConVar( "simple_thirdperson_fov_smooth" ):GetBool() then
				Editor.DelayFov = Editor.DelayFov + 20
				fov = math.Approach(fov, Editor.DelayFov, math.abs(Editor.DelayFov - fov) * GetConVar( "simple_thirdperson_fov_smooth_mult" ):GetFloat())
			else
				fov = Editor.DelayFov
			end
			
			if ServerBool("simple_thirdperson_forcecollide","simple_thirdperson_collision") then
			
				local traceData = {}
				traceData.start = Editor.DelayPos
				traceData.endpos = traceData.start + angles:Forward() * -Forward
				traceData.endpos = traceData.endpos + angles:Right() * Right
				traceData.endpos = traceData.endpos + angles:Up() * Up
				traceData.filter = player.GetHumans()
				
				local trace = util.TraceLine(traceData)
				
				pos = trace.HitPos
				
				if trace.Fraction < 1.0 then
					pos = pos + trace.HitNormal * 5
				end
				
				view.origin = pos
			else
			
				local View = Editor.DelayPos + ( angles:Forward()* -Forward )
				View = View + ( angles:Right() * Right )
				View = View + ( angles:Up() * Up )
				
				view.origin = View
				
			end

			view.angles = angles
			view.fov = fov
		 
			return view

		else
			Editor.DelayPos = pos
		end
	end)
end