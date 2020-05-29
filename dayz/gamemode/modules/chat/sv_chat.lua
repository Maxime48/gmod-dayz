util.AddNetworkString( "GlobalChat" )
util.AddNetworkString( "LocalChat" )
util.AddNetworkString( "MeChat" )
util.AddNetworkString( "TradeChat" )
util.AddNetworkString( "GroupChat" )


DZ_GlobalCommands = {}
DZ_GlobalCommands[1] = "/"
DZ_GlobalCommands[2] = "ooc"

DZ_TradeCommands = {}
DZ_TradeCommands[1] = "t"
DZ_TradeCommands[2] = "trade"

DZ_GroupCommands = {}
DZ_GroupCommands[1] = "group"
DZ_GroupCommands[2] = "gr"
DZ_GroupCommands[3] = "g"

function GM:PlayerSay( ply, text, teamonly, is_dead )
	
	local name = ply:Name()
	local pentid = ply:EntIndex()
	
	local sub = ""
	local chattype = "LocalChat"
	for k, v in pairs(DZ_GlobalCommands) do
		if string.StartWith(string.lower(text), "/"..v.."") then
			chattype = "GlobalChat"
			sub = "/"..v..""
			break
		end
	end
	
	for k, v in pairs(DZ_TradeCommands) do
		if string.StartWith(string.lower(text), "/"..v.."") then
			chattype = "TradeChat"
			sub = "/"..v..""
			break
		end
	end

	for k, v in pairs(DZ_GroupCommands) do
		if string.StartWith(string.lower(text), "/"..v.."") then
			chattype = "GroupChat"
			sub = "/"..v..""
			break
		end
	end

	if teamonly then
		chattype = "GroupChat"
	end

	if string.StartWith(string.lower(text), "/me") then
		chattype = "MeChat"
		sub = "/me"
	end
	
	local tosub = 0
	local len = string.len( sub )
	
	text = string.gsub(text, sub, "", 1) -- remove command
	if string.StartWith(text, " ") then text = string.Right( text, string.len(text) - 1  ) end -- remove whitespace.
	
	print(string.upper(string.gsub(chattype, "Chat", ""))..": "..ply:Nick()..": "..text )

	if chattype == "LocalChat" or chattype == "MeChat" then
	
		for k, v in pairs( player.GetAll() ) do 
			if !IsValid(v) or !v:IsPlayer() then continue end
			local dist = ply:GetPos():Distance(v:GetPos())

			local meters = math.Round(dist * 1.905 / 100)
			if meters > PHDayZ.MaxChatDistance then continue end

			net.Start( chattype )
				net.WriteUInt( pentid, 32 )	
				net.WriteUInt( dist, 32 )
				net.WriteString( text )
			net.Send( v )
		end

		return false
	end

	local sendto = player.GetAll()
	if chattype == "GroupChat" then
		sendto = team.GetPlayers( ply:Team() )
		if ply:Team() == TEAM_NEUTRAL then 
			ply:Tip(3, "nogroup")
			return ""
		end
	end

	net.Start(chattype)
		net.WriteUInt( pentid, 32 )	
		net.WriteString( text )				
	net.Send(sendto)
		
	return false
end