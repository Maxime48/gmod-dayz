local function LoadTabs()

	local root = GM.FolderName.."/gamemode/modules/menus/tabs"
	
	for _, File in SortedPairs(file.Find(root .."/*.lua", "LUA"), true) do
		if !PHDayZ.DisableStartupInfo then
			MsgC( Color(0,255,255), "[PHDayZ] Loading CLIENT tab: " .. File .. "\n" )
		end
		include(root .. "/" ..File)
	end

	hook.Call( "DZ_MakeMenuTabs", GAMEMODE )
	if !PHDayZ.DisableStartupInfo then
		Msg("======================================================================\n")
	end
end

local vgui = vgui
local draw = draw
local surface = surface
local gradient = Material("gui/gradient")

GUI_Main_Frame = GUI_Main_Frame or nil
DayZ_MenuTabs = DayZ_MenuTabs or {}
function DayZ_AddMenuTab(t)
	local tabfound
	for k,v in pairs(DayZ_MenuTabs) do
		if v.name == t.name then tabfound = k break end 
	end
	
	if tabfound then 
		DayZ_MenuTabs[tabfound] = t
		if !PHDayZ.DisableStartupInfo then
			print("[PHDayZ] A Menu-Tab has been found with this name ("..t.name..") already! Replacing tab!")
		end
		return
	end
	
	table.insert(DayZ_MenuTabs, { order = t.order, name = t.name, type = t.type, icon = t.icon, desc = t.desc, func = t.func, updatefunc = t.updatefunc } )
	
end

DZ_MENUVISIBLE = DZ_MENUVISIBLE or false
function ToggleInventory(force)

	if IsValid(GUI_Main_Frame) then

		if force then
			if DZ_MENUVISIBLE then return end
			if !LocalPlayer():Alive() then return end
				
			RemoveOpenedMenus()
			RestoreCursorPosition()

			GUI_Main_Frame:Show()
			LocalPlayer():EmitSound("buttons/combine_button1.wav", 75, 100, 0.2)
			DZ_MENUVISIBLE = true

			if isfunction(GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc) then GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel():MoveToFront()GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc() end

			return true
		end

		if GUI_Main_Frame:IsVisible() then
			DZ_MENUVISIBLE = false
			
			RemoveOpenedMenus()

			RememberCursorPosition()
			
			GUI_Main_Frame:Hide()
			LocalPlayer():EmitSound("buttons/combine_button2.wav", 75, 100, 0.2)
		else
			if !LocalPlayer():Alive() then return end
			
			RemoveOpenedMenus()		
			
			RestoreCursorPosition()

			GUI_Main_Frame:Show()
			LocalPlayer():EmitSound("buttons/combine_button1.wav", 75, 100, 0.2)
			DZ_MENUVISIBLE = true

			if isfunction(GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc) then GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel():MoveToFront()GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc() end
			
		end

	else
		GUI_MainMenu() // Create menu
	end
end
concommand.Add("dz_togglemenu", ToggleInventory)

function DayZ_GetTab(name)
	local tabfound
	if !IsValid(GUI_Main_Frame) then return end

	local sheet = GUI_Main_Frame.IconSheet
	for k, v in pairs( sheet.tabBar:GetTabs( ) ) do
		if !IsValid(v:GetPanel()) then continue end

		if string.lower( v:GetPanel().name ) == name then 
			tabfound = v 
			break 
		end
	end

	return tabfound
end

function SetActiveTab(name)
	if !IsValid(GUI_Main_Frame) then GUI_MainMenu() end
	name = string.lower(name)
	local tab = DayZ_GetTab(name)
	if tab then
		GUI_Main_Frame.IconSheet:SetActiveTab( tab )
			
		sound.Play( "select", LocalPlayer( ):GetPos( ) )

		ToggleInventory(true)

		if !DayZ_Tabs[name].created then DayZ_Tabs[name].func( DayZ_Tabs[name] ) DayZ_Tabs[name].created = true end
	end
end
concommand.Add("menu_tab", function(ply, cmd, args) SetActiveTab(args[1]) end)

DayZ_Tabs = DayZ_Tabs or {}
function GUI_MainMenu( hide )
	DayZ_Tabs = {}
	--if LocalPlayer():InVehicle() then return end
	if !IsValid( LocalPlayer() ) then return end -- sometimes this loads too early.
	if !LocalPlayer():Alive() then return end
	if IsValid(GUI_Main_Frame) then GUI_Main_Frame:Remove() end

	RemoveOpenedMenus()
	
	GUI_Main_Frame = vgui.Create("DPanel")
	GUI_Main_Frame:SetSize(800, 600)
	GUI_Main_Frame:Center()
	GUI_Main_Frame.Paint = function(self, w, h)	
		draw.RoundedBox( 0, 0, 0, w, h, CyB.barBg )
	end
	--GUI_Main_Frame:ShowCloseButton(false)
	--GUI_Main_Frame:SetTitle("")

	GUI_Main_Frame:MakePopup()
	
	GUI_Main_Frame.IconSheet = vgui.Create("DVerticalPropertySheet", GUI_Main_Frame)
	GUI_Main_Frame.IconSheet:Dock(FILL)
	GUI_Main_Frame.IconSheet.Paint = function() 
		
	end

	table.sort(DayZ_MenuTabs, function(a, b)
		return (a.order < b.order)
	end)
	
	if !IsValid(GUI_Main_Frame.title) then
		GUI_Main_Frame.title = vgui.Create("DPanel", GUI_Main_Frame) -- So docking works properly on each page, without duplicated code.
		GUI_Main_Frame.title:Dock(TOP)
		GUI_Main_Frame.title:SetTall(40)
		GUI_Main_Frame.title.Paint = function(self, w, h)

			local name = LANG.GetTranslation(string.lower(GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().name)) or "Unknown"
			local desc = GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().desc

			surface.SetFont("char_title36")
			local x, y = surface.GetTextSize(name)

			draw.RoundedBox( 0, 0, 0, w, h, CyB.barBg )
			draw.DrawText( name, "char_title36", 40, 0, Color(200,200,200), TEXT_ALIGN_LEFT )


			draw.DrawText( "- " ..GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().desc or "", "char_title16", 45 + x, 16, Color(200,200,200), TEXT_ALIGN_LEFT )
		end
	end

	if !IsValid(GUI_Main_Frame.icon) then
		local mat = Material( "cyb_mat/cyb_home.png", "noclamp smooth mips alphatest" )

		GUI_Main_Frame.icon = vgui.Create( "DImage", GUI_Main_Frame )
		GUI_Main_Frame.icon:SetMaterial(mat)
		GUI_Main_Frame.icon:SetImageColor(Color(200,200,200,255))
		GUI_Main_Frame.icon:SetPos(3, 3)
		GUI_Main_Frame.icon:SetSize( 32, 32 )
		GUI_Main_Frame.icon.Think = function(self) 
			self:SetImage( GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().icon or "cyb_mat/cyb_home.png" )
		end
	end

	local CBut2 = vgui.Create("DButton", GUI_Main_Frame)
	CBut2:SetColor(Color(200,200,200,255))
	CBut2:SetFont("Cyb_Inv_Bar")
	CBut2:SetText("X")
	CBut2.Paint = function() end
	CBut2:SetSize(32,32)
	CBut2:SetPos(CBut2:GetParent():GetWide()-CBut2:GetWide()-5, 5)
	CBut2.DoClick = function() if GUI_Main_Frame:IsValid() then DZ_MENUVISIBLE = false GUI_Main_Frame:Hide() RemoveOpenedMenus() end end

	local mat = Material("cyb_mat/cyb_analyse.png", "smooth noclamp")
	local CBut = vgui.Create("DButton", GUI_Main_Frame)
	CBut:SetColor(Color(200,200,200,255))
	CBut:SetFont("Cyb_Inv_Bar")
	CBut:SetText("")
	CBut:SetTooltip("Reload UI")
	CBut.Paint = function(self, w, h) 
		local color = Color(200,200,200,255)
		if self:IsHovered() then
			color = Color(255,255,255,255)
		end
		surface.SetMaterial( mat )
		surface.SetDrawColor( color )
		surface.DrawTexturedRect( 2, 2, 24, 24 )
	end
	CBut:SetSize(28,28)
	CBut:SetPos(CBut:GetParent():GetWide()-CBut:GetWide()-35, 7)
	CBut.DoClick = function() RunConsoleCommand("mainmenu_reload") RemoveOpenedMenus() end

	local mat2 = Material("cyb_mat/cyb_equipment.png", "smooth noclamp")
	local SZBut = vgui.Create("DButton", GUI_Main_Frame)
	SZBut:SetColor(Color(200,200,200,255))
	SZBut:SetFont("Cyb_Inv_Bar")
	SZBut:SetText("")
	SZBut.Paint = function() end
	SZBut:SetSize(28,28)
	SZBut:SetToolTip("Teleport to Safezone")
	SZBut.Paint = function(self, w, h) 
		local color = Color(200,200,200,255)
		if self:IsHovered() then
			color = Color(255,255,255,255)
		end
		surface.SetMaterial( mat2 )
		surface.SetDrawColor( color )
		surface.DrawTexturedRect( 2, 2, 24, 24 )
	end
	SZBut:SetPos(CBut2:GetParent():GetWide()-CBut2:GetWide()-60, 7)
	SZBut.DoClick = function() RunConsoleCommand("say", "!sz") end

	for k, v in pairs(DayZ_MenuTabs) do
		local name = string.lower(v.name)
		DayZ_Tabs[name] = vgui.Create(v.type, GUI_Main_Frame)
		DayZ_Tabs[name].name = v.name
		DayZ_Tabs[name].desc = v.desc
		DayZ_Tabs[name].icon = v.icon

		DayZ_Tabs[name]:Dock(FILL)
		DayZ_Tabs[name]:DockMargin(5, 10, 5, 10)
		DayZ_Tabs[name].Paint = function() end
				
		GUI_Main_Frame.IconSheet:AddSheet( v.name, DayZ_Tabs[name], v.icon, true, true, v.desc )
		if v.func then DayZ_Tabs[name].func = v.func end

		if name == "guide" then v.func( DayZ_Tabs[name] ) DayZ_Tabs[name].created = true end

		DayZ_Tabs[name].updatefunc = v.updatefunc

	end

	if args and tonumber(args[1]) == 1 then
		GUI_Main_Frame:Hide()
		RemoveOpenedMenus()
	end

	DZ_MENUVISIBLE = true

	LocalPlayer():EmitSound("buttons/combine_button3.wav", 75, 100, 0.5)

	if hide then
		DZ_MENUVISIBLE = false
			
		RemoveOpenedMenus()

		RememberCursorPosition()
		
		GUI_Main_Frame:Hide()
	end
end
concommand.Add( "mainmenu_reload", function(ply, cmd, args) GUI_MainMenu() end)

local function DisallowSpawnMenu()
	if GUI_InputInvKey == KEY_Q then
		return false
	end
	if !LocalPlayer():IsAdmin() then return false end
	--return false
end
hook.Add( "SpawnMenuOpen", "DisallowSpawnMenu", DisallowSpawnMenu)

local nextToggle = 0
local function InvKeyPress()
	--if LocalPlayer():InVehicle() then return end
	if !LocalPlayer():Alive() then return end
	
	--print(vgui.GetKeyboardFocus())
	if LocalPlayer():IsTyping() or (IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName( ) == "TextEntry") or gui.IsGameUIVisible() or gui.IsConsoleVisible()  then return end
	
	if ( input.IsKeyDown(GUI_InputInvKey) or input.IsKeyDown(KEY_F4) ) && nextToggle < CurTime() then
		ToggleInventory()
		nextToggle = CurTime() + 0.5
	end

	if input.IsKeyDown(KEY_F2) && nextToggle < CurTime() then
		local cvar = GetConVar( "simple_thirdperson_enabled" )
		local bool = cvar:GetBool()

		cvar:SetBool( !bool )
		nextToggle = CurTime() + 0.5
	end
end
hook.Add("Think","InvKeyPress",InvKeyPress)

function PaintBoxToScreen()
	if DrawMap == true then
		local BoxSize = 1024;
		local Offset = BoxSize / 2;
	
		draw.RoundedBox( 0, 0, 0, ScrW(), ScrH(), Color( 0, 0, 0, 225 ) )
		surface.SetDrawColor( 255, 255, 255, 255 );
		surface.SetTexture( surface.GetTextureID("gui/map") );
		surface.DrawTexturedRect( ( ScrW() / 2 ) - Offset, ( ScrH() / 2 ) - Offset, BoxSize, BoxSize );	
		
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset, (BoxSize/5), BoxSize, 1, Color( 255, 255, 255, 225 ) )
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset, (BoxSize/5)*2, BoxSize, 1, Color( 255, 255, 255, 225 ) )	
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset, (BoxSize/5)*3, BoxSize, 1, Color( 255, 255, 255, 225 ) )	
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset, (BoxSize/5)*4, BoxSize, 1, Color( 255, 255, 255, 225 ) )	

		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset + (BoxSize/5), ( ScrH() / 2 ) - Offset, 1, BoxSize, Color( 255, 255, 255, 225 ) )
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset + (BoxSize/5)*2, ( ScrH() / 2 ) - Offset, 1, BoxSize, Color( 255, 255, 255, 225 ) )	
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset + (BoxSize/5)*3, ( ScrH() / 2 ) - Offset, 1, BoxSize, Color( 255, 255, 255, 225 ) )	
		draw.RoundedBox( 0, ( ScrW() / 2 ) - Offset + (BoxSize/5)*4, ( ScrH() / 2 ) - Offset, 1, BoxSize, Color( 255, 255, 255, 225 ) )	
		
	end
end
hook.Add( "HUDPaint", "PaintBoxToScreen", PaintBoxToScreen );

LoadTabs()