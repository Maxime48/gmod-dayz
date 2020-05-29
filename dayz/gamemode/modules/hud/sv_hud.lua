util.AddNetworkString( "TipSend" )
util.AddNetworkString( "TipSendParams" )

PMETA.TipCooldowns = PMETA.TipCooldowns or {}
function PMETA:Tip( icontype, str1, col1, str2, col2, convar )
	if str1 then
		if ( self.TipCooldowns[str1] or 0 ) > CurTime() then return end

		self.TipCooldowns[str1] = CurTime() + 10 -- Don't receive the same tip again for at least 15 seconds

		str2 = str2 or ""
		net.Start( "TipSend" )
			net.WriteUInt(icontype, 3)
			net.WriteString( str1 )
			net.WriteTable( col1 or Color(255,255,255,255) )
			net.WriteString( str2 )
			net.WriteTable( col2 or Color(255,255,255,255) )
			net.WriteString( convar or "" )
		net.Send( self )	
	end
end

function TipAll( icontype, str1, col1, str2, col2 )
	if str1 then
		icontype = icontype or 3
		str2 = str2 or ""
		net.Start("TipSend")
			net.WriteUInt(icontype, 3)
			net.WriteString( str1 )
			net.WriteTable( col1 or Color(255,255,255,255) )
			net.WriteString( str2 )
			net.WriteTable( col2 or Color(255,255,255,255) )
			net.WriteString("")
		net.Broadcast()
	end
end

function PMETA:TipParams(...)
	net.Start( "TipSendParams" )
		net.WriteTable({...})
	net.Send(self)
end