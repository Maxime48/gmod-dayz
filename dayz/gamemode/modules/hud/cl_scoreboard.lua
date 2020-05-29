-- a much requested darker scoreboard

local table = table
local surface = surface
local draw = draw
local math = math
local team = team

local RankColors = {}
RankColors["owner"] = { txt = "Owner", col = Color(255,255,255,255) }
RankColors["superadmin"] = { txt = "SuperAdmin", col = Color(255,255,255,255) }
RankColors["admin"] = { txt = "Admin", col = Color(255,255,255,255) }
RankColors["vip"] = { txt = "VIP", col = Color(255,255,255,255) }
RankColors["user"] = { txt = "User", col = Color(255,255,255,255) }
RankColors["guest"] = { txt = "Guest", col = Color(255,255,255,255) }


function GM:HUDDrawScoreboard()
	local grad = Material("gui/gradient")
	local tagmat = Material("gui/icon_cyb_64_red.png")
	local edgemat = Material("gui/icon_cyb_64_orange.png")
	local safemat = Material("gui/icon_cyb_64_blue.png")
	
	GUI_ScoreBoard_Frame = vgui.Create( "DPanel" )
	GUI_ScoreBoard_Frame:SetTall( 800 )
	GUI_ScoreBoard_Frame:SetWide( 800 )
	GUI_ScoreBoard_Frame:SetVisible( true )
	GUI_ScoreBoard_Frame:Center()
	GUI_ScoreBoard_Frame.Paint = function(self, w, h)

		draw.RoundedBox(6, 0, 0, w, h, Color(0,0,0,100)) -- middle part	
												
		draw.DrawText(PHDayZ.scoreboardtitle, "SafeZone_NAME", w/2, 15, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)
		draw.DrawText("A GM by Phoenixf129", "Cyb_HudTEXTSmall", 5, h-15, Color(255, 255, 255, 150),TEXT_ALIGN_LEFT)	
		draw.DrawText("GM version v"..tonumber(PHDayZ.version), "Cyb_HudTEXTSmall", w-5, h-15, Color(255, 255, 255, 150),TEXT_ALIGN_RIGHT)	

		ScoreboardHeaderText = ScoreboardHeaderText or "Since Fudsine skiddyripped 'his' GM from OCRP and sold it, Credits go to Jake, Noobulator & Crap-Head"

		draw.DrawText(ScoreboardHeaderText, "Cyb_HudTEXTSmall", w/2, 0, Color(255, 255, 255, 150),TEXT_ALIGN_CENTER)
	end

	local SList = vgui.Create( "DScrollPanel", GUI_ScoreBoard_Frame )
	SList:SetPos( 2, 66 )					
	SList:SetTall( 715 )
	SList:SetWide( 796 )	
	SList.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(0,0,0,100)) end
	--SList:SetSpacing( 2 )
	--SList:EnableHorizontal( true )
	--SList:EnableVerticalScrollbar( true )
	--SList:GetVBar():SetEnabled(true)
	
	for k, v in pairs( player.GetAll() ) do
		if !IsValid(v) then continue end
		
		local teamcolor, teamtext, textcolor = Color(50,50,50,200), "[NEUTRAL]", Color(255,255,255)
		if v:Frags() >= PHDayZ.Player_BountyKillsReq then
			teamtext = "[BOUNTY]"	
			teamcolor = Color(255, 0, 0, 50)
			textcolor = Color(255, 0, 0, 255)
		elseif v:Frags() >= PHDayZ.Player_BanditKillsReq then
			teamtext = "[BANDIT]"
			teamcolor = Color(255, 178, 0, 50)
			textcolor = Color(200, 0, 0, 255)
		elseif v:GetNWBool("friendly") and v:Frags() < PHDayZ.Player_BanditKillsReq then
			teamtext = "[HERO]"
			teamcolor = Color(0, 200, 0, 50) 	
			textcolor = Color(0, 200, 0, 255)
		end

		local PList = vgui.Create( "DPanelList", SList )
		--PList:SetPos( 0, 0 )
		PList:Dock(TOP)
		PList:DockMargin(2, 1, 2, 1)
		PList:SetSize( SList:GetWide()-10, 35 )
		PList.Paint = function(self, w, h)
						
			surface.SetDrawColor(teamcolor)
			surface.DrawRect( 0, 0, w, h ) -- middle part
			
			if v:IsValid() then
			
				if v:IsSuperAdmin() then
					draw.RoundedBox(4,1,1,34,34,Color(0, 255, 0, 150))
				elseif v:IsVIP() then
					draw.RoundedBox(4,1,1,34,34,Color(0, 0, 255, 150))							
				else
					draw.RoundedBox(4,1,1,34,34,Color(0, 0, 0, 0))							
				end		
			end
		end
		PList:EnableHorizontal( true )
		PList:SetSpacing( 2 )

		local Avatar = vgui.Create( "AvatarImage", PList )
		Avatar:SetPos( 2, 2 )
		Avatar:SetSize( 32, 32 )
		Avatar:SetPlayer( v )
		
		local Name = vgui.Create( "DLabel", PList )
		Name:SetPos( 40, 8 )
		Name:SetText( "" )
		Name:SetSize( 200, 40 )
		Name.Paint = function()
			if v:IsValid() then
				if isfunction(v.GetHelperUserGroup) and RankColors[v:GetHelperUserGroup()] then
					surface.SetTextColor(RankColors[v:GetHelperUserGroup()].col)
				else
					surface.SetTextColor( Color(255, 255, 255, 255) )
				end
				if v:IsVIP() and PHDayZ.ShowVIPColors then
					surface.SetTextColor(RankColors["vip"].col)
				end
				if v:SteamID() == "STEAM_0:0:39587206" then
					surface.SetTextColor( Color(255,215,0) )		
				end
			else
				return
			end
			surface.SetTextPos( 0, -2 )
			surface.SetFont( "Cyb_HudTEXT" )
			if string.len( v:Nick() ) > 20 then
				TheName = string.sub(v:Nick(), 1, 17).."..."
				surface.DrawText(TheName)
			else
				surface.DrawText(v:Nick())
			end
			--surface.DrawText( v:Nick() )
		end
		
		local Rank = vgui.Create( "DLabel", PList )
		Rank:SetFont( "ScoreboardContent" )
		if isfunction(v.GetHelperUserGroup) and RankColors[v:GetHelperUserGroup()] then
			Rank:SetText(RankColors[v:GetHelperUserGroup()].txt)
			Rank:SetColor(RankColors[v:GetHelperUserGroup()].col)
		else
			Rank:SetText("Guest")	
			Rank:SetColor( Color(255, 255, 255, 255) )
		end
		if v:IsVIP() and !v:IsAdmin() then
			Rank:SetText(RankColors["vip"].txt)
			Rank:SetColor(RankColors["vip"].col)
		end

		if v:SteamID() == "STEAM_0:0:39587206" then
			Rank:SetText("Creator")
			Rank:SetColor(Color(255,215,0))
		end
		Rank:SizeToContents()
		Rank:SetPos( PList:GetWide()-(Rank:GetWide()+10), 2 )

		local Ping = vgui.Create( "DPanel", PList )
		--Ping:SetFont( "ScoreboardContent" )
		Ping.Paint = function(self, w, h)
			if v:IsValid() then
				if v:Ping() < 100 then
					draw.RoundedBox(0,35,10,4,4,Color(0, 255, 0, 255))
					draw.RoundedBox(0,40,6,4,8,Color(0, 255, 0, 255))
					draw.RoundedBox(0,45,2,4,12,Color(0, 255, 0, 255))
				elseif v:Ping() < 225 then
					draw.RoundedBox(0,35,10,4,4,Color(255, 255, 0, 255))
					draw.RoundedBox(0,40,6,4,8,Color(255, 255, 0, 255))
					draw.RoundedBox(0,45,2,4,12,Color(155, 155, 155, 255))
				else 
					draw.RoundedBox(0,35,10,4,4,Color(255, 0, 0, 255))
					draw.RoundedBox(0,40,6,4,8,Color(155, 155, 155, 255))
					draw.RoundedBox(0,45,2,4,12,Color(155, 155, 155, 255))
				end

				draw.DrawText(v:Ping().."ms", "Cyb_HudTEXTSmall", 33, 3, Color(255, 255, 255, 150),TEXT_ALIGN_RIGHT)	
			end
		end
		Ping:SetSize(50,50)
		Ping:SetPos(PList:GetWide()-Ping:GetWide()-10, 16)

		local Status = vgui.Create( "DLabel", PList )
		Status:SetFont( "ScoreboardContent" )
		Status:SetText("")
		Status:SetWide(100)
		Status:SetPos( 260, 8 )
		Status.Paint = function(self, w, h)
			if !IsValid(v) then return end
			draw.DrawText(teamtext, "ScoreboardContent", 33, 3, Color(255,255,255,255),TEXT_ALIGN_CENTER)	
		end

		local Level = vgui.Create("DPanel", PList)
		Level.Paint = function(self, w, h)
			if !IsValid(v) then return end
			draw.DrawText("[LVL "..v:GetLevel().."]", "ScoreboardContent", 33, 3, Color(255, 255, 255, 200),TEXT_ALIGN_CENTER)	
		end
		Level:SetSize(100,50)
		Level:SetPos((PList:GetWide()-PList:GetWide()/3)-Level:GetWide()+30, 7)

		--SList:AddItem( PList )	
	end	
	return true	
	
end

/*---------------------------------------------------------
   Name: GM:ScoreboardShow( )
   Desc: Sets the scoreboard to visible
---------------------------------------------------------*/
function GM:ScoreboardShow()
	if ( scoreboard == nil ) then
		GAMEMODE:HUDDrawScoreboard()
	else
		GUI_ScoreBoard_Frame:SetVisible( true )
		if GUI_AdminSB_Button then		
		GUI_AdminSB_Button:SetVisible( true )	
		end
	end
	gui.EnableScreenClicker(true)
	DZ_MENUBLUR = true
end

/*---------------------------------------------------------
   Name: GM:ScoreboardHide( )
   Desc: Hides the scoreboard
---------------------------------------------------------*/
function GM:ScoreboardHide()
	if INTRO then
		return
	end
	GUI_ScoreBoard_Frame:SetVisible( false )
	if GUI_AdminSB_Button then
	GUI_AdminSB_Button:SetVisible( false )	
	end
	gui.EnableScreenClicker(false)
	DZ_MENUBLUR = false
end

timer.Create("updatetext", 60, 0, function()

	http.Fetch("http://ph129.net/gmoddayz.php", function( body, len, headers, code ) ScoreboardHeaderText = body end)
	--print("[PHDayZ] Fetching new ScoreboardHeader from ph129.net")

end)