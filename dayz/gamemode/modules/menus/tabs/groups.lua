function Group_ShowColorPicker()
	if IsValid(GUI_Color_SwitcherFrame) then GUI_Color_SwitcherFrame:Remove() return end
	
	--if LocalPlayer():Team() == TEAM_NEUTRAL then return end

	GUI_Color_SwitcherFrame = vgui.Create("DFrame")
	GUI_Color_SwitcherFrame:SetTitle("Create/Modify Group")
	GUI_Color_SwitcherFrame:SetSize( 210, 300 )
	GUI_Color_SwitcherFrame:SetDraggable(true)
	GUI_Color_SwitcherFrame:ShowCloseButton(true)
	GUI_Color_SwitcherFrame.btnMaxim:Hide()
	GUI_Color_SwitcherFrame.btnMinim:Hide()
	GUI_Color_SwitcherFrame:MakePopup()
	GUI_Color_SwitcherFrame:Center()
	GUI_Color_SwitcherFrame.Paint = function(self, w, h)
		draw.RoundedBoxEx( 6, 0, 0, w, h, Color(0, 0, 0, 200), true, true, true, true )
	end
	--GUI_Model_Frame:MoveTo(350, ScrH()/2-GUI_Model_Frame:GetTall()/2, 1, 0.1, -1)
	
	local GroupName = vgui.Create("DLabel", GUI_Color_SwitcherFrame)
	GroupName:SetText("Name:")
	GroupName:Dock(TOP)

	local GroupNameBox = vgui.Create("DTextEntry", GUI_Color_SwitcherFrame)
	GroupNameBox:Dock(TOP)
	GroupNameBox:SetText( LocalPlayer():Team() == TEAM_NEUTRAL && "GroupName"..math.random(1, 100000) or team.GetName( LocalPlayer():Team() ) )
	GroupNameBox.AllowInput = function(self)
		if string.len(self:GetValue()) >= 25 then
			surface.PlaySound("Resource/warning.wav")
			return true
		end
	end

	local GroupColor = vgui.Create("DLabel", GUI_Color_SwitcherFrame)
	GroupColor:SetText("Color:")
	GroupColor:Dock(TOP)

	GUI_Color_Switcher = vgui.Create( "DColorMixer", GUI_Color_SwitcherFrame )
	GUI_Color_Switcher:SetAlphaBar( false )
	GUI_Color_Switcher:SetPalette( false )
	GUI_Color_Switcher:Dock(FILL)
	local MyGroupColor = LocalPlayer():Team() != TEAM_NEUTRAL && team.GetColor( LocalPlayer():Team() ) or Color(math.random(1,255), math.random(1,255), math.random(1,255))
	local RED = MyGroupColor.r / 255
	local GREEN = MyGroupColor.g / 255
	local BLUE = MyGroupColor.b / 255

	GUI_Color_Switcher:SetVector( Vector( RED, GREEN, BLUE ) )

	local ConfirmButton = vgui.Create("DButton", GUI_Color_SwitcherFrame)
	ConfirmButton:SetText("CONFIRM")
	ConfirmButton:Dock(BOTTOM)
	ConfirmButton.Paint = PaintButtons
	ConfirmButton.DoClick = function()

		if LocalPlayer():Team() == TEAM_NEUTRAL then
			RunConsoleCommand( "dz_makegroup", GroupNameBox:GetText() ) 
		end

		RunConsoleCommand( "dz_recolorgroup", GUI_Color_Switcher:GetVector()[1]*255, GUI_Color_Switcher:GetVector()[2]*255, GUI_Color_Switcher:GetVector()[3]*255 )
		RunConsoleCommand( "dz_renamegroup", GroupNameBox:GetText() )
		GUI_Color_SwitcherFrame:Remove()

		UpdateGroup()
	end
end

function UpdateGroup()
	
	if !IsValid(GUI_Group_Panel_List) then return end
	GUI_Group_Panel_List:Clear()

    local title_group = vgui.Create("DPanel", GUI_Group_Panel_List)
    title_group:Dock(TOP)
    title_group:SetTall(40)
    title_group:DockMargin(0, 0, 0, 5)
    title_group.Paint = function(self, w, h)
        paint_bg(self, w, h)

        draw.SimpleText("10% XP Bonus available for groups of 2 or more members!", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText("Group members are shown on your compass.", "char_title20", 5, 20, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

	local CreateGroup = vgui.Create("DButton", GUI_Group_Panel_List)
	CreateGroup:Dock(TOP)
	CreateGroup.Paint = PaintButtons
	CreateGroup:SetText(LANG.GetTranslation("creategroup"))
	CreateGroup.Think = function()
		if #team.GetPlayers( LocalPlayer():Team() ) > 0 and LocalPlayer():Team() != TEAM_NEUTRAL then
			CreateGroup:SetDisabled(true)
		else
			CreateGroup:SetDisabled(false)
		end
	end
	CreateGroup.DoClick = function() Group_ShowColorPicker() end

	local ModifyGroup = vgui.Create("DButton", GUI_Group_Panel_List)
	ModifyGroup:Dock(TOP)
	ModifyGroup:SetText(LANG.GetTranslation("modifygroup"))
	ModifyGroup.Think = function()
		ModifyGroup:SetDisabled( !team.IsLeader( LocalPlayer():Team(), LocalPlayer() ) )
	end
	ModifyGroup.Paint = PaintButtons
	ModifyGroup.DoClick = function() Group_ShowColorPicker() end
					
	local InviteGroup = vgui.Create("DButton", GUI_Group_Panel_List)
	InviteGroup:Dock(TOP)
	InviteGroup:SetText(LANG.GetTranslation("inviteplayer"))
	InviteGroup.Paint = PaintButtons
	InviteGroup:SetDisabled(NotOwner)
	InviteGroup.DoClick = function() 
		local DMenu = DermaMenu()
		for k, v in pairs(player.GetAll()) do 
			if !IsValid(v) then continue end
			if v == LocalPlayer() then continue end
			if table.HasValue(team.GetPlayers( LocalPlayer():Team() ), v) then continue end
			
			DMenu:AddOption(v:Nick(), function() RunConsoleCommand( "dz_invitegroup", v:Nick() ) UpdateGroup() end)
		end
		DMenu:Open()
	end
	
	local GroupIconList = vgui.Create( "DIconLayout", GUI_Group_Panel_List )
	GroupIconList:Dock(TOP)
	GroupIconList.Paint = function(self, w, h)
		surface.SetDrawColor( Color( 0, 0, 0, 200 ) )
		surface.DrawRect(0, 0, w, h)
	end
	
	local KickGroup = vgui.Create("DButton", GUI_Group_Panel_List)
	KickGroup:Dock(TOP)
	KickGroup:SetText(LANG.GetTranslation("kickplayer"))
	KickGroup.Think = function()
		if #team.GetPlayers( LocalPlayer():Team() ) > 1 then
			KickGroup:SetDisabled(false)
		else
			KickGroup:SetDisabled(true)
		end
	end
	KickGroup.Paint = PaintButtons
	KickGroup.DoClick = function() 
	
		local DMenu = DermaMenu()
		for k, v in pairs( team.GetPlayers( LocalPlayer():Team() ) ) do 
			if !IsValid(v) then continue end
			if v == LocalPlayer() then continue end
			
			DMenu:AddOption(v:Nick(), function() RunConsoleCommand( "dz_kickgroup", v:Nick() ) UpdateGroup() end)
		end
		DMenu:Open()
	end
	
	local LeaveGroup = vgui.Create("DButton", GUI_Group_Panel_List)
	LeaveGroup:Dock(TOP)
	LeaveGroup.Paint = PaintButtons
	LeaveGroup:SetText(LANG.GetTranslation("leavegroup"))
	LeaveGroup.Think = function()
		if #team.GetPlayers( LocalPlayer():Team() ) > 0 and LocalPlayer():Team() != TEAM_NEUTRAL then
			LeaveGroup:SetDisabled(false)
		else
			LeaveGroup:SetDisabled(true)
		end
	end
	LeaveGroup.DoClick = function() RunConsoleCommand("dz_leavegroup") UpdateGroup() end

end

function GUI_Rebuild_Groups(parent)
	GUI_Group_Panel_List = parent
	
	UpdateGroup()
end

DayZ_AddMenuTab( { order = 6, name = "Groups", type = "DPanel", icon = "cyb_mat/cyb_group.png", desc = "Create group, invite friends", func = GUI_Rebuild_Groups, updatefunc = UpdateGroup } )
