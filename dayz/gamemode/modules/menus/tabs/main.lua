function Concept_Build_Main(parent)
	
	local PlayerHelp = vgui.Create("DHTML", parent)
	PlayerHelp:Dock(FILL)
	PlayerHelp:DockMargin(5, 0, 5, 0)
	PlayerHelp:OpenURL(PHDayZ.GuideURL or "https://gmoddayz.net/docs/forplayers/")
	PlayerHelp:SetScrollbars(true)
	PlayerHelp:SetMouseInputEnabled(true)
	PlayerHelp:SetKeyBoardInputEnabled(true)
	PlayerHelp:RequestFocus()
	
	local ctrls = vgui.Create( "DHTMLControls", parent ) -- Navigation controls
	ctrls:Dock(BOTTOM)
	ctrls:DockMargin(5, 0, 5, 0)
	ctrls:SetHTML( PlayerHelp ) -- Links the controls to the DHTML window
	ctrls.AddressBar:SetText( PHDayZ.GuideURL or "https://gmoddayz.net/docs/forplayers/" ) -- Address bar isn't updated automatically

end

DayZ_AddMenuTab( { order = 0, name = "Guide", type = "DPanel", icon = "cyb_mat/cyb_home.png", desc = "A brief introduction to GMod DayZ", func = Concept_Build_Main } )
