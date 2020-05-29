net.Receive("PHDayZ_ConfigUpdate", function(len)
	PHDayZ = net.ReadTable()	
	//PrintTable(PHDayZ)
end)

hook.Add("OnReloaded", "RequestConfig", function()

	if ( nextAutoReload or 0 ) > CurTime() then return end -- to prevent spamming, this hook is ran many times!

	nextAutoReload = CurTime() + 0.1
	chat.AddText( Color( 100, 100, 255 ), "Received request, updating gamemode..." )

	print("[PHDayZ] Requesting Config due to Auto-Refresh event!")
	RunConsoleCommand("dz_requestconfig")
end)
