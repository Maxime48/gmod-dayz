-- Xavier is a butthurt scrub.

net.Receive("CharSelect", function(len)
	GUI_Select_Model()
end)

net.Receive("CharReady", function(len)
	GUI_ReadyToPlay()
end)

PlayMusicOnce = 1

AliveChar = AliveChar or false
LastDeathMsg = LastDeathMsg or ""
net.Receive("AliveChar", function(len)
	AliveChar = net.ReadBool()
	LastDeathMsg = net.ReadString()
end)

local function wrap(current, step, min, max)
	current = current + step;
	if (current > max) then
		current = min;
	elseif (current < min) then
		current = max;
	end
	return current;
end

local btnMarginRight = 120;
local btnMarginLeft = 170;
local Outfit, Head = 1, 1;
local Gender = 0;
local UsingCustomModel = false;
local PlayerModels = MaleModels;

local IsInitialized = false
local ShouldSelectModel = false

local cyb_mouseover = Color(41,128,185,80)
local cyb_mouseover_menu = Color(41, 128, 185, 255)
local cyb_cat_mouseover = Color(220,220,220,10)
local cyb_cat_mouseover_menu = Color(120,120,120,255)
local cyb_cat_mouseover_text = Color(255,255,255,255)
local cyb_cat_mouseover_text_menu = Color(140,140,140,255)

local function GUI_ShowColorPicker()
	if IsValid(GUI_Color_SwitcherFrame) then GUI_Color_SwitcherFrame:Remove() return end
	
	local x, y = GUI_Model_Frame:GetPos()
	local w, h = GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall()
	
	GUI_Color_SwitcherFrame = vgui.Create("DFrame")
	GUI_Color_SwitcherFrame:SetTitle("")
	GUI_Color_SwitcherFrame:SetSize( 210, 270 )
	GUI_Color_SwitcherFrame:SetDraggable(false)
	GUI_Color_SwitcherFrame:MakePopup()
	GUI_Color_SwitcherFrame:ShowCloseButton(false)
	GUI_Color_SwitcherFrame.Paint = function(self, w, h)
		DrawBlurPanel(self)
		draw.RoundedBoxEx( 6, 0, 0, w, h, Color(0,0,0,200), false, true, false, true )
	end
	GUI_Color_SwitcherFrame:SetPos(x+w, ScrH()+300)
	GUI_Color_SwitcherFrame:MoveTo(x+w, (ScrH()/2-GUI_Color_SwitcherFrame:GetTall()/2), 1.01, 0.1, -1)
	--GUI_Model_Frame:MoveTo(350, ScrH()/2-GUI_Model_Frame:GetTall()/2, 1, 0.1, -1)
	
	GUI_Color_Switcher = vgui.Create( "DColorMixer", GUI_Color_SwitcherFrame )
	GUI_Color_Switcher:SetAlphaBar( false )
	GUI_Color_Switcher:SetPalette( false )
	GUI_Color_Switcher:SetSize( 200, 260 )
	GUI_Color_Switcher:SetPos(5, 5)
	GUI_Color_Switcher:SetVector( Vector( GetConVarString( "cl_playercolor" ) ) )
	GUI_Color_Switcher.ValueChanged = function()
		--GUI_Player_Model.Entity:SetPlayerColor( GUI_Color_Switcher:GetVector() )
		RunConsoleCommand( "cl_playercolor", tostring( GUI_Color_Switcher:GetVector() ) )
	end
end

function GUI_Select_Model()

	PlayerModels = PlayerModels or MaleModels;

	local CurModel = LocalPlayer():GetModel()

	if CurModel == "" then 

		CurModel = nil 

		Gender = math.random(0, 1)

		if Gender == 1 then -- Female.
			Outfit = math.random( 1, #FemaleModels )
			Head = math.random( 1, #FemaleModels[Outfit] )
		else -- Male
			Outfit = math.random( 1, #MaleModels )
			Head = math.random( 1, #MaleModels[Outfit] )
		end

	end

	if IsValid(GUI_Model_Frame) then return end
	
	GUI_Model_Frame = vgui.Create("DFrame")
	GUI_Model_Frame:SetTitle("")
	GUI_Model_Frame:SetSize(400, 600)
	GUI_Model_Frame.Think = function(self)
		self:MakePopup()
	end
	GUI_Model_Frame:SetPos(350,ScrH())
	GUI_Model_Frame:SetDraggable(false)
	GUI_Model_Frame.Paint = function(self, w, h)
		DrawBlurPanel(self)
		draw.RoundedBoxEx( 6, 0, 0, w, h, Color(0,0,0,200), true, true, true, true )
	end
	
	GUI_Model_Frame:MakePopup()
	GUI_Model_Frame:ShowCloseButton(false)	

	GUI_ShowColorPicker()
	GUI_Model_Frame:MoveTo(350, ScrH()/2-GUI_Model_Frame:GetTall()/2, 1, 0.1, -1)

	GUI_Player_Model = vgui.Create( "DModelPanel", GUI_Model_Frame )
	GUI_Player_Model:SetModel(CurModel or PlayerModels[Outfit][Head] )
	GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	GUI_Player_Model:SetSize( GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall() )
	GUI_Player_Model:SetPos( GUI_Model_Frame:GetWide()/2-GUI_Player_Model:GetWide()/2, GUI_Model_Frame:GetTall()/2-GUI_Player_Model:GetTall()/2 )

	--GUI_Player_Model:SetCamPos( Vector( 47, 0, 35 ) )
	--GUI_Player_Model:SetLookAt( Vector( 0, 0, 35 ) )	
	GUI_Player_Model:SetFOV(36000/GUI_Model_Frame:GetTall())	
	
	GUI_Model_Content = vgui.Create("DPanel", GUI_Model_Frame)
	GUI_Model_Content:SetSize(GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall())
	GUI_Model_Content:MoveToFront()
	GUI_Model_Content:SetPos(0,0)

	GUI_Model_Content.Paint = function(self, w, h)

		draw.SimpleText("CREATE YOUR CHARACTER", "char_title1", GUI_Model_Frame:GetWide() / 2, 20, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.RoundedBoxEx( 6, 0, 0, GUI_Model_Frame:GetWide(), 40, cyb_cat_mouseover, true, true, false, false )
		
	end

	GUI_Model_Cat_Body = vgui.Create("DPanel", GUI_Model_Content)
	GUI_Model_Cat_Body:SetSize( GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall() / 3 )
	GUI_Model_Cat_Body:SetPos( 0 , 0 )

	GUI_Model_Cat_Body.Paint = function(self, w, h)

		if self.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_cat_mouseover, true, true, false, false )
			draw.SimpleText("BODY", "char_options1", self:GetWide() / 3, self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText((!UsingCustomModel and  "("..Head.."/"..#PlayerModels[Outfit]..")" or ""), "char_options1", self:GetWide() - (self:GetWide() / 3), self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		end

	end

	GUI_Model_Cat_Clothes = vgui.Create("DPanel", GUI_Model_Content)
	GUI_Model_Cat_Clothes:SetSize( GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall() / 3 )
	GUI_Model_Cat_Clothes:SetPos( 0 , GUI_Model_Frame:GetTall() - ((GUI_Model_Frame:GetTall() / 3)*2) )

	GUI_Model_Cat_Clothes.Paint = function(self, w, h)

		if self.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_cat_mouseover, false, false, false, false )
			draw.SimpleText("CLOTHES", "char_options1", self:GetWide() / 3, self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText((!UsingCustomModel and  "("..Outfit.."/"..#PlayerModels..")" or "") , "char_options1", self:GetWide() - (self:GetWide() / 3), self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		end
		
	end

	GUI_Model_Cat_Sex = vgui.Create("DPanel", GUI_Model_Content)
	GUI_Model_Cat_Sex:SetSize( GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall() / 3 )
	GUI_Model_Cat_Sex:SetPos( 0 , GUI_Model_Frame:GetTall() - ((GUI_Model_Frame:GetTall() / 3)) )

	GUI_Model_Cat_Sex.Paint = function(self, w, h)

		if self.Hovered then
			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_cat_mouseover, false, false, true, true )
			draw.SimpleText("GENDER", "char_options1", self:GetWide() / 3, self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText((!UsingCustomModel and  "("..(Gender == 1 and "Female" or "Male")..")" or ""), "char_options1", self:GetWide() - (self:GetWide() / 3), self:GetTall() / 2, cyb_cat_mouseover_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		
	end

	local GUI_HeadLeft_Button = vgui.Create( "DButton")
	GUI_HeadLeft_Button:SetParent(GUI_Model_Frame)	
	GUI_HeadLeft_Button:SetSize( 50, GUI_Model_Frame:GetTall()/3 )
	GUI_HeadLeft_Button:SetPos( 0, 0 )
	GUI_HeadLeft_Button:SetText( "" )

	GUI_HeadLeft_Button.Paint = function(self, w, h)

		if GUI_HeadLeft_Button.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, true, false, false, false )

		end

		draw.SimpleText("<", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local GUI_HeadRight_Button = vgui.Create( "DButton")
	GUI_HeadRight_Button:SetParent(GUI_Model_Frame)	
	GUI_HeadRight_Button:SetSize( 50, GUI_Model_Frame:GetTall()/3 )
	GUI_HeadRight_Button:SetPos( GUI_Model_Frame:GetWide() - 50, 0)
	GUI_HeadRight_Button:SetText( "" )

	GUI_HeadRight_Button.Paint = function(self, w, h)

		if GUI_HeadRight_Button.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, false, true, false, false )

		end

		draw.SimpleText(">", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end

	local GUI_GenderLeft_Button = vgui.Create( "DButton")
	GUI_GenderLeft_Button:SetParent(GUI_Model_Frame)	
	GUI_GenderLeft_Button:SetSize( 50, GUI_Model_Frame:GetTall()/3 )
	GUI_GenderLeft_Button:SetPos( 0, GUI_Model_Frame:GetTall()-GUI_Model_Frame:GetTall()/3 )
	GUI_GenderLeft_Button:SetText( "" )

	GUI_GenderLeft_Button.Paint = function(self, w, h)

		if GUI_GenderLeft_Button.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, false, false, true, false )

		end

		draw.SimpleText("<", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end

	local GUI_GenderRight_Button = vgui.Create( "DButton")
	GUI_GenderRight_Button:SetParent(GUI_Model_Frame)	
	GUI_GenderRight_Button:SetSize( 50, GUI_Model_Frame:GetTall()/3 )
	GUI_GenderRight_Button:SetPos( GUI_Model_Frame:GetWide() - 50, GUI_Model_Frame:GetTall() - ( GUI_Model_Frame:GetTall()/3 ) )
	GUI_GenderRight_Button:SetText( "" )

	GUI_GenderRight_Button.Paint = function(self, w, h)

		if GUI_GenderRight_Button.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, false, false, false, true )

		end

		draw.SimpleText(">", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end

	local GUI_OutfitLeft_Button = vgui.Create( "DButton")
	GUI_OutfitLeft_Button:SetParent(GUI_Model_Frame)	
	GUI_OutfitLeft_Button:SetSize( 50, GUI_Model_Frame:GetTall()/3 )
	GUI_OutfitLeft_Button:SetPos( 0, GUI_Model_Frame:GetTall()-((GUI_Model_Frame:GetTall()/3)*2) )
	GUI_OutfitLeft_Button:SetText( "" )

	GUI_OutfitLeft_Button.Paint = function(self, w, h)

		if GUI_OutfitLeft_Button.Hovered then
			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, false, false, false, false )
		end

		draw.SimpleText("<", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end

	local GUI_OutfitRight_Button = vgui.Create( "DButton")
	GUI_OutfitRight_Button:SetParent(GUI_Model_Frame)	
	GUI_OutfitRight_Button:SetSize( 50,  GUI_Model_Frame:GetTall()/3 )
	GUI_OutfitRight_Button:SetPos(  GUI_Model_Frame:GetWide() - 50, GUI_Model_Frame:GetTall() - ((GUI_Model_Frame:GetTall()/3)*2) )
	GUI_OutfitRight_Button:SetText( "" )

	GUI_OutfitRight_Button.Paint = function(self, w, h)

		if GUI_OutfitRight_Button.Hovered then

			draw.RoundedBoxEx( 6, 0, 0, w, h, cyb_mouseover, false, false, false, false )

		end

		draw.SimpleText(">", "char_title1", self:GetWide() / 2, self:GetTall() / 2, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	end
	
	local GUI_ConfirmChoice_Button = vgui.Create( "DButton")
	GUI_ConfirmChoice_Button:SetParent(GUI_Model_Frame)	
	GUI_ConfirmChoice_Button:SetSize( 250, 50 )
	GUI_ConfirmChoice_Button:SetPos( GUI_Model_Frame:GetWide() / 2 - 125, GUI_Model_Frame:GetTall() - 60 )
	GUI_ConfirmChoice_Button:SetText( "" )

	GUI_ConfirmChoice_Button.Paint = function(self)

		if self.Hovered then

			surface.SetDrawColor( cyb_mouseover )
			surface.DrawRect( 0, 0, self:GetWide(), self:GetTall())

		else

			surface.SetDrawColor( cyb_cat_mouseover )
			surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() )

		end

		draw.SimpleText("CONFIRM", "char_title1", self:GetWide() / 2, 5, Color(255,255,255,255), TEXT_ALIGN_CENTER)

	end

	RPName_Entry = vgui.Create("DTextEntry", GUI_Model_Frame)
	RPName_Entry:Dock(TOP)
	RPName_Entry:DockMargin(0, 15, 0, 0)
	RPName_Entry:SetPlaceholderText("Enter your character name")
	if LocalPlayer():GetRPName() != "" then
		RPName_Entry:SetText( LocalPlayer():GetRPName() )
	end
	RPName_Entry.AllowInput = function(self)
		if string.len(self:GetValue()) >= 30 then
			surface.PlaySound("Resource/warning.wav")
			return true
		end
	end
	
	GUI_HeadLeft_Button.DoClick = function()
		UsingCustomModel = false
		Head = wrap(Head, -1, 1, #PlayerModels[Outfit])
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_HeadRight_Button.DoClick = function()
		UsingCustomModel = false
		Head = wrap(Head, 1, 1, #PlayerModels[Outfit])
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_GenderLeft_Button.DoClick = function()
		UsingCustomModel = false
		Gender = wrap(Gender, -1, 0, 1)
		Outfit, Head = 1, 1;
		PlayerModels = Gender == 0 and MaleModels or FemaleModels
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_GenderRight_Button.DoClick = function()
		UsingCustomModel = false
		Gender = wrap(Gender, 1, 0, 1)
		Outfit, Head = 1, 1;
		PlayerModels = Gender == 0 and MaleModels or FemaleModels
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_OutfitLeft_Button.DoClick = function()
		UsingCustomModel = false
		Outfit = wrap(Outfit, -1, 1, #PlayerModels)
		Head = math.Clamp(Head, 1, #PlayerModels[Outfit])
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_OutfitRight_Button.DoClick = function()
		UsingCustomModel = false
		Outfit = wrap(Outfit, 1, 1, #PlayerModels)
		Head = math.Clamp(Head, 1, #PlayerModels[Outfit])
		GUI_Player_Model:SetModel(PlayerModels[Outfit][Head])
		GUI_Player_Model.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end

	GUI_ConfirmChoice_Button.DoClick = function()

		--if IsValid( RPName_Entry ) then

		if RPName_Entry:GetText() == "" then 
			MakeTip(3, "You need to set a Name to continue!", Color(255,0,0,255))
			LocalPlayer():PrintMessage(HUD_PRINTCENTER, "") 
			return false
		end

		local canSet = RPSetName(LocalPlayer(), RPName_Entry:GetText())

		if !canSet then 
			MakeTip(3, "This Name is not possible, try another!", Color(255,0,0,255))
			return false 
		end

		if RPName_Entry:GetText() != LocalPlayer():GetRPName() then
			LocalPlayer():ConCommand("rpname " .. RPName_Entry:GetText() )
		end
		--end

		if IsValid(GUI_Color_SwitcherFrame) then
			local x, y = GUI_Model_Frame:GetPos()
			local w, h = GUI_Model_Frame:GetWide(), GUI_Model_Frame:GetTall()
			GUI_Color_SwitcherFrame:MoveTo(x+w, ScrH()+200, 1, 0.1, -1, function(anim, pnl)
				GUI_Color_SwitcherFrame:Remove()
			end)
		end

		RunConsoleCommand("UpdateCharModel", Outfit, Head, Gender)
		
		GUI_Model_Frame:MoveTo(350, ScrH(), 1, 0.1, -1, function(anim, pnl)
			GUI_Model_Frame:Remove()
		end)				

		if !IsValid(Menu_Frame) then
			RunConsoleCommand("ConfirmReady")

			hook.Call( "DZ_PlayerReady" )

			gui.EnableScreenClicker(false)
			DZ_MENUBLUR = false
			return 
		end
		
		Menu_Frame:AlphaTo(0, 1, 0.1, function(anim, pnl)
			RunConsoleCommand("ConfirmReady")

			hook.Call( "DZ_PlayerReady" )

			gui.EnableScreenClicker(false)
			RemoveMenuFrames()
			DZ_MENUBLUR = false
		end)
		
	end
end

FirstJoin = true
DZ_MenuFrames = DZ_MenuFrames or {}
function RemoveMenuFrames()

	for k, v in pairs(DZ_MenuFrames) do
		if !IsValid(v) then continue end
		v:Remove()
	end

	FirstJoin = false

end

DZ_MENUBLUR = false
local logo = Material("cyb_mat/gmoddayz.png", "smooth")
local glow = Material("cyb_mat/gmoddayz.png")

local ButtonMat = Material("models/combine_soldier/camouflage")
local function GUI_ReadyToPlay(ply, cmd, args)
		
	if DZ_MENUBLUR then return end
	--if !ply and LocalPlayer():GetLevel() > 0 then return end
	--gui.EnableScreenClicker(true)
		
	Menu_Frame = vgui.Create("DFrame")
	Menu_Frame:SetTitle("")
	Menu_Frame:SetSize(ScrW(), ScrH())
	Menu_Frame:SetPos(0, 0)
	Menu_Frame:SetDraggable(false)
	Menu_Frame.Think = function(self)
		gui.EnableScreenClicker(true)
	end
	Menu_Frame.Paint = function(self, w, h)
			
		local s = h/6
		local hr = h - s
		
		surface.SetDrawColor( Color(0,0,0,240) )
		surface.DrawRect( 0, 0, w, s )

		local ws, hs = 2604/4, 654/4

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(glow)
		surface.DrawTexturedRect(ScrW()/2 - ws/2, 0, ws, hs)
		
		surface.SetDrawColor( Color(0,0,0,240) )
		surface.DrawRect( 0, hr, w, s )

		if !AliveChar && LastDeathMsg != "" then
			draw.SimpleText("Last Death:", "char_title24", ScrW() / 2, hr + 10, Color(255,255,255,255), TEXT_ALIGN_CENTER)
			draw.SimpleText(LastDeathMsg, "char_title", ScrW() / 2, hr + 30, Color(255,0,0,255), TEXT_ALIGN_CENTER)
		end
	end
	DZ_MENUBLUR = true

	ButtonMenu = vgui.Create("DPanel", Menu_Frame)
	ButtonMenu:SetSize(400, 200)
	ButtonMenu:SetPos(0, (ScrH()/2)-(ButtonMenu:GetTall()/2))

	ButtonMenu.Paint = function(self, w, h)
		draw.RoundedBoxEx( 6, 0, 0, w-100, h, Color(0,0,0,200), false, true, false, true )
	end

	Menu_Frame:MakePopup()
	Menu_Frame:SetZPos(-1)
	Menu_Frame:ShowCloseButton(false)
	table.insert(DZ_MenuFrames, Menu_Frame)

	GuidePanel = vgui.Create("DPanel", Menu_Frame)
	GuidePanel:SetSize(800, 600)
	GuidePanel:SetPos(ScrW()/2-GuidePanel:GetWide()/2, -GuidePanel:GetTall())
	GuidePanel:Hide()
	--GuidePanel:SetPos(ScrW()/2-GuidePanel:GetWide()/2, ScrH()/2 - GuidePanel:GetTall()/2 )
	local close = vgui.Create("DButton", GuidePanel)
	close:SetTall(32)
	close:Dock(TOP)
	close:SetText( "" )
	close.Paint = function(self, w, h)

		if self.Hovered then
			surface.SetDrawColor( cyb_mouseover_menu )
			surface.DrawRect( 0, 0, w, h)
		else
			surface.SetDrawColor( cyb_cat_mouseover_menu )
			surface.DrawRect( 0, 0, w, h )
		end
		draw.SimpleText("Close Guide", "tab_title", self:GetWide() / 2, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER)
		
	end
	close:SetTextColor( Color(255,255,255,255) )
	close.DoClick = function()
		GuidePanel.Moving = true
		GuidePanel:MoveTo(ScrW()/2-GuidePanel:GetWide()/2, -GuidePanel:GetTall(), 1, 0.1, -1, function(anim, pnl)
			GuidePanel:Hide()
			GuidePanel.Moving = false
		end)
	end

	GuidePanel.GuideH = vgui.Create("HTML", GuidePanel)
	GuidePanel.GuideH:Dock(FILL)
	GuidePanel.GuideH:OpenURL( PHDayZ.GuideURL )
	
	if PHDayZ.ShowGSAdvert then
	
		GS_Frame = vgui.Create( "DFrame" )
		GS_Frame:SetTitle("")
		GS_Frame:SetSize(520, 120)
		GS_Frame:SetPos(ScrW(), 50)
		GS_Frame.Paint = function(self, w, h)
			draw.RoundedBoxEx( 6, 0, 0, w, h, Color(255,255,255,200), true, false, true, false )
		end
		GS_Frame:MakePopup()
		GS_Frame:ShowCloseButton(false)
		
		local GS_Img = vgui.Create("DImageButton", GS_Frame)
		GS_Img:SetSize(512,512)
		GS_Img:SetPos(8,8)
		--GS_Img:Center()
		GS_Img.Paint = function(self, w, h)
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial(Material("cyb_mat/gs1.png", "vertexlitgeneric nocull mips"))
			surface.DrawTexturedRect( 0, 0, w, h )
		end
		GS_Img.DoClick = function()
			gui.OpenURL("http://gameswitchers.co.uk")
		end
		
		GS_Frame:MoveTo(ScrW()-GS_Frame:GetWide(), 50, 1, 1, -1)
		table.insert(DZ_MenuFrames, GS_Frame)

	end
	
	local TitleLabel = vgui.Create("DLabel", ButtonMenu)
	TitleLabel:SetText("Welcome to GMod DayZ")
	TitleLabel:SetFont("char_title24")
	TitleLabel:SizeToContents()
	TitleLabel:SetPos(5, 5)
	
	local VersionLabel = vgui.Create("DLabel", ButtonMenu)
	VersionLabel:SetText("v"..PHDayZ.version)
	VersionLabel:SetFont("char_title24")
	VersionLabel:SizeToContents()
	VersionLabel:SetPos(5, 175)
	
	local ConfirmButton = vgui.Create( "DButton", ButtonMenu)
	ConfirmButton:SetSize( btnMarginLeft*2, 50 )
	ConfirmButton:SetPos( 0, 50 )
	ConfirmButton:SetText( "" )
	ConfirmButton.Paint = function(self, w, h)

		if self.Hovered then
			surface.SetDrawColor( cyb_mouseover_menu )
			surface.DrawRect( 0, 0, w, h)
		else
			surface.SetDrawColor( cyb_cat_mouseover_menu )
			surface.DrawRect( 0, 0, w, h )
		end

		if AliveChar then
			draw.SimpleText("Load Character", "char_title", self:GetWide() / 2, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Create Character", "char_title", self:GetWide() / 2, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER)
		end
	end
	
	ConfirmButton:SetTextColor( Color(255,255,255,255) )
	ConfirmButton.DoClick = function()
		if !AliveChar then
			GUI_Select_Model()
		else
			Menu_Frame:AlphaTo(0, 1, 0.1, function(anim, pnl)
				RunConsoleCommand("ConfirmReady")

				hook.Call( "DZ_PlayerReady" )
				
				gui.EnableScreenClicker(false)
				RemoveMenuFrames()
				DZ_MENUBLUR = false
			end)
		end
		if PHDayZ.ShowGSAdvert then
			GS_Frame:MoveTo(ScrW(), 50, 1, 0.1, -1)
		end
		
	end
	
	local LeaveButton = vgui.Create( "DButton", ButtonMenu) -- no more leaving :P
	LeaveButton:SetSize( btnMarginLeft*2, 50 )
	LeaveButton:SetPos( 0, 105 )
	LeaveButton:SetText( "" )
	LeaveButton.Paint = function(self, w, h)

		if self.Hovered then
			surface.SetDrawColor( cyb_mouseover_menu )
			surface.DrawRect( 0, 0, w, h)
		else
			surface.SetDrawColor( cyb_cat_mouseover_menu )
			surface.DrawRect( 0, 0, w, h )
		end
		draw.SimpleText("Player Guide", "char_title", self:GetWide() / 2, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER)
		
	end
	LeaveButton:SetTextColor( Color(255,255,255,255) )
	LeaveButton.DoClick = function()

		if GuidePanel.Moving then return end
		GuidePanel.Moving = true
		if GuidePanel:IsVisible() then
			GuidePanel:MoveTo(ScrW()/2-GuidePanel:GetWide()/2, -GuidePanel:GetTall(), 1, 0.1, -1, function(anim, pnl) GuidePanel.Moving = false GuidePanel:Hide() end)
		else
			GuidePanel:Show()
			GuidePanel:MoveTo(ScrW()/2-GuidePanel:GetWide()/2, ScrH()/2 - GuidePanel:GetTall()/2, 1, 0.1, -1, function(anim, pnl) GuidePanel.Moving = false end)
		end

		GuidePanel.GuideH:OpenURL( PHDayZ.GuideURL )

		if PHDayZ.ShowGSAdvert then
			GS_Frame:MoveTo(ScrW(), 50, 1, 0.1, -1)
		end
	end

	table.insert(DZ_MenuFrames, HTML_Frame)

	LocalPlayer():EmitSound("buttons/blip1.wav", 160, 51)

end
concommand.Add("dz_menu", GUI_ReadyToPlay)
--hook.Add("InitPostEntity", "GetReady", GUI_ReadyToPlay)

--GM = GM or GAMEMODE

DZ_loadScreenAlpha = DZ_loadScreenAlpha or 255
DZ_loadAlpha = DZ_loadAlpha or 0 

local ModelRand = {
	"models/Humans/Group01/Female_01.mdl",
	"models/Humans/Group01/Female_02.mdl",
	"models/Humans/Group01/Female_03.mdl",
	"models/Humans/Group01/Female_04.mdl",
	"models/Humans/Group01/Female_06.mdl",
	"models/Humans/Group01/Female_07.mdl",
	"models/Humans/Group01/Female_08.mdl",
	"models/Humans/Group01/Female_09.mdl",

	"models/Humans/Group01/Male_01.mdl",
	"models/Humans/Group01/Male_02.mdl",
	"models/Humans/Group01/Male_03.mdl",
	"models/Humans/Group01/Male_04.mdl",
	"models/Humans/Group01/Male_05.mdl",
	"models/Humans/Group01/Male_06.mdl",
	"models/Humans/Group01/Male_07.mdl",
	"models/Humans/Group01/Male_08.mdl",
	"models/Humans/Group01/Male_09.mdl"
}

local RunnersMade = false
local function DrawRunners()
	if RunnersMade then return end

	local PRun = vgui.Create("DModelPanel")
	PRun:SetSize(300, 300)
	PRun:SetPos(0, ScrH()-280)
	PRun:SetModel( "models/Humans/Group01/Male_01.mdl" )
	PRun:SetDrawOnTop(true)
	PRun:SetZPos(32767)
	PRun:GetEntity():SetAngles(Angle(0,135,0))
	PRun:GetEntity():SetSequence("Startle_behind")

	timer.Simple(2, function() if IsValid(PRun) then PRun:GetEntity():SetSequence("sprint_all") end end)

	PRun.LayoutEntity = function(ent)
		PRun:RunAnimation()
	end

	local ZRun = vgui.Create("DModelPanel")
	ZRun:SetSize(300, 300)
	ZRun:SetPos(-300, ScrH()-280)
	ZRun:SetModel("models/zed/malezed_04.mdl")
	ZRun:SetDrawOnTop(true)
	ZRun:SetZPos(32767)
	ZRun:GetEntity():SetAngles(Angle(0,135,0))
	ZRun.LayoutEntity = function(ent)
		--ZRun:RunAnimation()
		ZRun:GetEntity():SetSequence("sprint_all")
		ZRun:RunAnimation()
	end

	PRun:MoveTo(ScrW()+200, ScrH()-280, 8, 1.8, -1, function(anim, pnl)
		if IsValid(PRun) then PRun:Remove() end
	end)
	ZRun:MoveTo(ScrW()+100, ScrH()-280, 8, 2, -1, function(anim, pnl)
		if IsValid(ZRun) then ZRun:Remove() end
	end)

	RunnersMade = true
end

local BleedMat = {
	Material("cyb_mat/blood1.png"),
	Material("cyb_mat/blood2.png"),
	Material("cyb_mat/blood3.png")
}

local BloodPos = {}
local NextDrawBlood = 0
local function DrawBlood(alpha)

	for i = #BloodPos, 1, -1 do
		surface.SetDrawColor( 140, 0, 0, alpha )
		surface.SetMaterial( BloodPos[i].mat )
		surface.DrawTexturedRect( BloodPos[i].xpos, BloodPos[i].ypos, BloodPos[i].sizex, BloodPos[i].sizey ) 
	end

	if NextDrawBlood > CurTime() then return end
	if alpha < 255 then return end

	local x, y = math.random( 0, ScrW() ), math.random( 0, ScrH() )
	local sx, sy = math.random(16, 128), math.random(16, 128)
	local m = BleedMat[ math.random(1, 3) ]

	table.insert(BloodPos, { xpos = x, ypos = y, sizex = sx, sizey = sy, mat = m } )

	LocalPlayer():EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1,4)..".wav", 75, 100, 0.1)

	NextDrawBlood = CurTime() + math.random(0.1, 0.6)
end

--local DZ_loadScreenAlpha = 255
--local DZ_loadAlpha = 0 

local CalledMenu = false

DZ_loadingText = { "Welcome to:" }
function DZ_LoadingScreen()
	if (!gui.IsGameUIVisible() and DZ_loadScreenAlpha > 0) then

		local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()
		local goal = 0

		if (FirstJoin) then
			goal = 255
		end

		DZ_loadAlpha = math.Approach(DZ_loadAlpha, goal, FrameTime() * 30)

		if (DZ_loadAlpha == 255 and goal == 255) then
			if (DZ_loadScreenAlpha == 255) then
				LocalPlayer():EmitSound("buttons/lightswitch2.wav", 160, 51)
			end

			DZ_loadScreenAlpha = math.Approach(DZ_loadScreenAlpha, 0, FrameTime() * 60)

		end

		if (DZ_loadScreenAlpha > 0) then

			surface.SetDrawColor(10, 10, 14, DZ_loadScreenAlpha)
			surface.DrawRect(0, 0, scrW, scrH)

			local shake = 0
			local x, y, w, h = scrW*0.5 - 401, scrH*0.3, 2604/3, 654/3

			DrawBlood(DZ_loadScreenAlpha)

			DrawRunners()

			surface.SetDrawColor(255, 255, 255, DZ_loadScreenAlpha)
			surface.SetMaterial(logo)
			surface.DrawTexturedRect(x-shake, y, w, h)

			for i = #DZ_loadingText, 1, -1 do
				local alpha2 = (1-i / #DZ_loadingText) * DZ_loadScreenAlpha

				draw.SimpleText(DZ_loadingText[i], "SafeZone_NAME", scrW * 0.5, scrH * 0.6 + (i * 36), Color(255, 255, 255, alpha2), 1, 1)
			end

			draw.SimpleText("A Gamemode by Phoenixf129", "Cyb_HudTEXT", scrW-5-shake, scrH-10, Color(30, 30, 30, DZ_loadScreenAlpha), 2, 1)

			hook.Run("DZ_DrawLoadingScreen")

			if DZ_loadScreenAlpha < 50 then
				if !CalledMenu then
					GUI_ReadyToPlay()
					CalledMenu = true
				end
			end
			timer.Simple(10, function() DZ_loadScreenAlpha = 0 DZ_loadAlpha = 255 if !CalledMenu then GUI_ReadyToPlay() CalledMenu = true end end) // hacky ik

			--do return end			
		end
	end
end