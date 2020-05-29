/////////////////////////////////////////////
//////////////// DayZ Groups ////////////////
/////////////////////////////////////////////
////////// Created by my_hat_stinks /////////
/////////////////////////////////////////////
// cl_groups.lua                    CLIENT //
//                                         //
// Handles all client group stuff.         //
/////////////////////////////////////////////

//
// Join/Leave
concommand.Add( "dz_joingroup", function( p,c,a )
	local tm = tonumber(a[1])
	if not (tm and tm==tm) then return end // nil or NaN
	if tm<1 or tm>255 then return end // Out of range

	DZ_MakeGroupHUD(tm)
	
	net.Start( "DayZGroups_JoinTeam" )
		net.WriteUInt( tm, 8 )
	net.SendToServer()
end)
concommand.Add( "dz_leavegroup", function()
	net.Start( "DayZGroups_LeaveTeam" ) net.SendToServer()
end)

net.Receive( "DayZGroups_TeamJoined", function()
	local tm = net.ReadUInt( 8 )
	if not tm then return end

	DZ_MakeGroupHUD(tm)
end)

// Rename
concommand.Add( "dz_renamegroup", function( p,c,a )
	net.Start( "DayZGroups_UpdateTeamName" )
		net.WriteString( table.concat( a, " " ) )
	net.SendToServer()
end)
concommand.Add( "dz_recolorgroup", function( p,c,a )
	local r,g,b = tonumber(a[1]),tonumber(a[2]),tonumber(a[3])
	if not (r and r==r and g and g==g and b and b==b) then return end
	
	local col = Color( r, g, b )
	net.Start( "DayZGroups_UpdateTeamColor" )
		net.WriteTable( col )
	net.SendToServer()
end)

//
// Invite
concommand.Add( "dz_invitegroup", function( ply,c,a )
	local target = GAMEMODE.Util:GetPlayerByName(a[1])
	if ply==target or not IsValid(target) then return end
	
	net.Start( "DayZGroups_TeamInvite" )
		net.WriteEntity( target )
	net.SendToServer()
end)

//
// Request update
hook.Add( "DZ_PlayerReady", "DayZGroups RequestUpdate", function()
	RunConsoleCommand( "dayzgroup_fullupdate" )
end)

//
// Net: Update Team Vars
net.Receive( "DayZGroups_UpdateTeamColor", function()
	local tm = net.ReadUInt( 8 )
	if (not tm) or tm<1 or tm>255 then return end
	
	local col = net.ReadTable()
	if not (col and col.a and col.r and col.g and col.b) then return end
	
	team.UpdateColor( tm, col )
end)
net.Receive( "DayZGroups_UpdateTeamName", function()
	local tm = net.ReadUInt( 8 )
	if (not tm) or tm<1 or tm>255 then return end
	
	local name = net.ReadString()
	if (not name) or name=="" then return end
	
	team.UpdateName( tm, name )
end)
net.Receive( "DayZGroups_UpdateTeamJoinable", function()
	local tm = net.ReadUInt( 8 )
	if (not tm) or tm<1 or tm>255 then return end
	
	team.UpdateJoinable( tm, tobool(net.ReadBit()) )
end)

//
// Net: Update Leader
net.Receive( "DayZGroups_UpdateTeamLeaders", function()
	local tm = net.ReadUInt( 8 )
	local leader = net.ReadEntity()
	
	if (not (tm and IsValid(leader))) or tm<=1 or tm>255 then return end
	
	team.tblLeaders = team.tblLeaders or {}
	team.tblLeaders[tm] = leader
end)

//
// Net: Full Update
net.Receive( "DayZGroups_FullTeamUpdate", function()
	local tm = net.ReadUInt( 8 )
	if not tm then return end
	
	if !tm or tm==0 then // Update All
		local tbl = net.ReadTable()
		if not tbl then return end
		
		team.tblLeaders = team.tblLeaders or {}
		for tm,v in pairs(tbl) do
			local teamCol = team.GetColor( tm )
			local teamName = team.GetName( tm )
			local teamJoinable = team.Joinable( tm )
			
			if teamName~=v.Name then
				team.UpdateName( tm, v.Name )
			end
			if teamCol.r~=v.Color.r or teamCol.g~=v.Color.g or teamCol.b~=v.Color.b or teamCol.a~=v.Color.a then
				team.UpdateColor( tm, v.Color )
			end
			if teamJoinable~=v.Joinable then
				team.UpdateJoinable( tm, v.Joinable )
			end
			
			team.tblLeaders[tm] = v.Leader
		end
		
		return
	end
	
	local newName = net.ReadString()
	local newCol = net.ReadTable()
	local newJoinable = tobool(net.ReadBit())
	
	if not (newName and newCol) then return end
	
	team.UpdateName( tm, newName )
	team.UpdateColor( tm, newCol )
	team.UpdateJoinable( tm, newJoinable )
end)

//
// Net: Invited
local InvitePanel
local Col = {
	Border = Color(20,20,20, 150), Main = Color(100,100,100, 100),
	
	Text = Color(255,255,255), TextShadow = Color(0,0,0),
	
	Accept = Color(150,255,150), Decline = Color(255,150,150),
}
surface.CreateFont( "DayZGroupsFontSmall", {
	font = "Arial",
	size = 20,
	weight = 700,
})
surface.CreateFont( "DayZGroupsFont", {
	font = "Arial",
	size = 25,
	weight = 700,
})
net.Receive( "DayZGroups_TeamInvite", function()
	local tm = net.ReadUInt( 8 )
	local inviteTime = net.ReadFloat()
	
	local ply = LocalPlayer()
	if not (tm and inviteTime and IsValid(ply)) then return end

	surface.PlaySound("friends/message.wav")

	timer.Create("invite_soundspam", 1, 0, function()
		if !IsValid(InvitePanel) then timer.Destroy("invite_soundspam") return end
		surface.PlaySound("friends/message.wav")
	end)
	
	ply.DayzGroup_TeamInvites = ply.DayzGroup_TeamInvites or {}
	ply.DayzGroup_TeamInvites[ tm ] = inviteTime
	
	if IsValid(InvitePanel) then return end
	InvitePanel = vgui.Create( "DPanel" )
	InvitePanel:SetSize( 300, 100 )
	InvitePanel:SetPos( (ScrW()/2)-150, ScrH()-225 )
	InvitePanel.Paint = function( s, w,h )
		local glow = math.abs(math.sin(CurTime() * 2) * 255); 

		surface.SetDrawColor( Color(glow, 10, 10, 255) )
		
		surface.DrawRect( 0,0, 2,h )
		surface.DrawRect( w-2,0, 2,h )
		surface.DrawRect( 2,0, w-4,2 )
		surface.DrawRect( 2,h-2, w-4,2 )
		
		surface.SetDrawColor( Col.Main )
		surface.DrawRect( 2,2, w-4,h-4 )
		
		draw.SimpleText( "You have been invited to join", "DayZGroupsFontSmall", (w/2)+1, 16, Col.TextShadow, TEXT_ALIGN_CENTER )
		draw.SimpleText( "You have been invited to join", "DayZGroupsFontSmall", w/2, 15, Col.Text, TEXT_ALIGN_CENTER )
		
		draw.SimpleText( team.GetName(tm), "DayZGroupsFont", (w/2)+1, 41, Col.TextShadow, TEXT_ALIGN_CENTER )
		draw.SimpleText( team.GetName(tm), "DayZGroupsFont", w/2, 40, team.GetColor(tm), TEXT_ALIGN_CENTER )
		
		local str = string.format( "%s to accept", (input.LookupBinding("gm_showhelp") or "[ShowHelp") )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)-4, 71, Col.TextShadow, TEXT_ALIGN_RIGHT )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)-5, 70, Col.Accept, TEXT_ALIGN_RIGHT )
		
		local str = string.format( "%s to decline", (input.LookupBinding("gm_showteam") or "[ShowTeam") )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)+6, 71, Col.TextShadow, TEXT_ALIGN_LEFT )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)+5, 70, Col.Decline, TEXT_ALIGN_LEFT )
	end
	
	hook.Add( "PlayerBindPress", InvitePanel, function(self,ply,bind,pressed)
		if not IsValid(self) then return end
		
		if bind=="gm_showhelp" and pressed then
			RunConsoleCommand( "dz_joingroup", tm )
			
			self:Remove()
			return true
		elseif bind=="gm_showteam" and pressed then
			self:Remove()
			return true
		end
	end)
	
	local pnl = InvitePanel
	timer.Simple( math.min(math.abs(inviteTime-CurTime()), 30), function()
		if IsValid(pnl) then pnl:Remove() end
	end)
end)

function DZ_MakeGroupHUD(tm)
	if IsValid(GroupHUD) then GroupHUD:Remove() end
	if tm < 2 or tm > 255 then return end

	GroupHUD = vgui.Create("DPanel")
	GroupHUD:SetPos(15,15)
	GroupHUD:SetSize(300,64)
	GroupHUD.Paint = function(self, w, h)
		//draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 200))
	end

	GroupHUD.title = vgui.Create("DPanel", GroupHUD)
	GroupHUD.title:SetTall(20)
	GroupHUD.title:Dock(TOP)
	GroupHUD.title:DockMargin(0,0,0,2)
	GroupHUD.title.Paint = function(self, w, h)

		local name = team.GetName(tm)
		local tmcolor = team.GetColor(tm)

		draw.RoundedBox(0, 0, 0, w, h, Color( tmcolor.r, tmcolor.g, tmcolor.b, 200) )
		draw.DrawText(name, "char_title16", 5, 4, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)	
	end

	GroupHUD.players = {}
	GroupHUD.curExtraSize = 20

	local leaderMat = Material("icon16/star.png")
	GroupHUD.Think = function(self)
		if ( self.nextThink or 0 ) > CurTime() then return end
		self.nextThink = CurTime() + 0.5
		for k, ply in pairs( team.GetPlayers( tm ) ) do
			
			if table.HasValue(GroupHUD.players, ply:EntIndex()) then continue end

			local player_panel = vgui.Create("DPanel", GroupHUD)
			player_panel.ply = ply
			player_panel:SetTall(64)
			player_panel:Dock(TOP)
			player_panel:DockMargin(0,0,0,2)
			player_panel.Think = function(self)
				if ( self.nextThink or 0 ) > CurTime() then return end
				self.nextThink = CurTime() + 1

				if !IsValid(self.ply) then 
					table.remove(GroupHUD.players, self.ply:EntIndex())

					self:Remove() 
					return
				end
				
				if self.ply:Team() != tm then 
					table.remove(GroupHUD.players, self.ply:EntIndex())

					self:Remove() 
				end
			end
			player_panel.Paint = function(self, w, h)
				local padding = 64
				local posX = 64
				local posY = 0
				local padW = 0
				local padY = 0
				local hpHeight = 24
				local hpWidth = ( w - posX ) - 5
				if !IsValid(self.ply) then return end



				local alive = self.ply:Alive();
				local hp = math.Clamp( self.ply:Health(), 0, 100 )
				local rhp = math.Clamp( self.ply:GetRealHealth(), 0, 100 )
				local hunger = math.Clamp( self.ply:GetHunger(), 0, 1000 )
				local thirst = math.Clamp( self.ply:GetThirst(), 0, 1000 )
				local hpText = hp/50 .. "%"
				local hpColor = Color(140,50,50,255) 
				local rhpColor = Color( 50, 140, 50, 200 )
				local color = Color( 250, 250, 250, 200 )
				local hColor = Color( 50, 200, 50, 255 )
				local tColor = Color( 50, 50, 200, 255 )
				if self.ply:GetBleed() or (self.ply:Health() <= 20) then hpColor = Color(Pulsate(1)*140, 50, 50, 255) end
				if self.ply:GetSick() or (self.ply:GetRealHealth() <= 20) then rhpColor = Color(50, Pulsate(1)*140, 50, 200 ) end
				if self.ply:GetHunger() <= 25 then hColor = Color( 50, Pulsate(1)*200, 50, 255 ) end
				if self.ply:GetThirst() <= 25 then tColor = Color( 50, 50, Pulsate(1)*200, 255 ) end
				
				if not alive then
					hp, rhp, hunger, thirst = 0, 0, 0, 0
					color = Color( 100, 100, 100, 200 )
				end
						
				-- Draw the bar backgrounds
				surface.SetDrawColor( Color( 50, 50, 50, 200 ) )
				surface.DrawRect( posX+padW, hpHeight+(padY), hpWidth, 3 )
				surface.DrawRect( posX+padW, hpHeight+10+(padY), hpWidth, 3 )
				surface.DrawRect( posX+padW, hpHeight+20+(padY), hpWidth, 3 )
				surface.DrawRect( posX+padW, hpHeight+30+(padY), hpWidth, 3 )
				
				-- blood
				surface.SetDrawColor( hpColor )
				surface.DrawRect( posX+padW, hpHeight+(padY), hpWidth * hp * 0.01, 3 )
				
				-- health
				surface.SetDrawColor( rhpColor )
				surface.DrawRect( posX+padW, hpHeight+10+(padY), hpWidth * rhp * 0.01, 3 )
				
				-- hunger
				surface.SetDrawColor( hColor )
				surface.DrawRect( posX+padW, hpHeight+20+(padY), hpWidth * hunger * 0.001, 3 )
				
				-- thirst
				surface.SetDrawColor( tColor )
				surface.DrawRect( posX+padW, hpHeight+30+(padY), hpWidth * thirst * 0.001, 3 )
				
				if not alive then
					draw.SimpleTextOutlined( "DEAD", "SafeZone_POPUP", posX+w/2-40, h/2+3+(padY), Color(255,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.5, Color( 0, 0, 0, 200 ) )
				end

				if team.IsLeader( tm, self.ply ) then
					surface.SetMaterial( leaderMat )
					surface.SetDrawColor( Color( 255, 255, 255, 255) )
					surface.DrawTexturedRect( posX+padW - 20, 4, 16, 16 )
				end

				draw.DrawText(self.ply:Nick(), "char_title16", posX+padW, 5, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)	
				draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 150))
			end

		    local modelpanel = vgui.Create("DModelPanel", player_panel)
		    modelpanel.ply = ply
		    modelpanel:SetPos(5, 5)
		    modelpanel:SetSize(55, 55)

		    local PaintModel = modelpanel.Paint

		    function modelpanel:DrawModel()
		        local curparent = self
		        local rightx = self:GetWide()
		        local leftx = 0
		        local topy = 0
		        local bottomy = self:GetTall()
		        local previous = curparent

		        while (curparent:GetParent() ~= nil) do
		            curparent = curparent:GetParent()
		            local x, y = previous:GetPos()
		            topy = math.Max(y, topy + y)
		            leftx = math.Max(x, leftx + x)
		            bottomy = math.Min(y + previous:GetTall(), bottomy + y)
		            rightx = math.Min(x + previous:GetWide(), rightx + x)
		            previous = curparent
		        end

		        if self:GetParent():IsDragging() then
		            self.Entity:DrawModel()
		        else
		            render.SetScissorRect(leftx, topy, rightx, bottomy, true)
		            self.Entity:DrawModel()
		            render.SetScissorRect(0, 0, 0, 0, false)
		        end
		    end

		    modelpanel:SetDrawOnTop(false)

		    modelpanel.LayoutEntity = function() end

		    function modelpanel:Paint(w, h)
		        local x2, y2 = self:GetParent():LocalToScreen(0, 0)
		        local w2, h2 = self:GetParent():GetSize()
		        render.SetScissorRect(x2, y2, x2 + w2, y2 + h2, true)
		        PaintModel(self, w, h)
		        render.SetScissorRect(0, 0, 0, 0, false)
		    end

		    modelpanel:SetModel( ply:GetModel() )
		    modelpanel.Think = function(self)
		    	if ( self.nextThink or 0 ) > CurTime() then return end
		    	self.nextThink = CurTime() + 1
		    	if !IsValid(self.ply) then return end

		    	self:GetEntity():SetModel( self.ply:GetModel() )
		    	self:GetEntity():SetSkin( self.ply:GetSkin() )
		   	end
		    if not IsValid( modelpanel:GetEntity() ) then return end

		    modelpanel:GetEntity():SetMaterial( ply:GetMaterial() )
		    modelpanel:GetEntity():SetSkin( ply:GetSkin() )

			modelpanel:GetEntity():SetBodyGroups( ply:GetBodyGroups() )

			local bone = modelpanel:GetEntity():LookupBone( "ValveBiped.Bip01_Head1" ) 
			if !bone then return end

		    local eyepos = modelpanel:GetEntity():GetBonePosition(bone)
		    eyepos:Add( Vector( 0, 0, 2 ) )	-- Move up slightly
			modelpanel:SetLookAt( eyepos )
			modelpanel:SetCamPos( eyepos-Vector( -15, 0, 0 ) )	-- Move cam in front of eyes
			modelpanel:GetEntity():SetEyeTarget( eyepos-Vector( -15, 0, 0 ) )

		    modelpanel:SetColor( Color(255, 255, 255, 255) )

			table.insert(GroupHUD.players, ply:EntIndex())
			self.curExtraSize = self.curExtraSize + 64
		end

		self:SetTall(self.curExtraSize)

	end

end

function DZ_RemoveGroupHUD()
	if IsValid(GroupHUD) then GroupHUD:Remove() end
end

local gpanelW = 250
local gpanelH = 80
local function DrawGroups()
	if GUI_ShowGroupHUD == 0 then return end
	if LocalPlayer():Team() then return end

	local posX = 14
	local posY = 0

	local padW 				= 	22
	local padY = 14
	local hpHeight			= 	28
	local hpWidth 			= 	gpanelW - 45


	for k, ply in pairs( team.GetPlayers( LocalPlayer():Team() ) ) do

		surface.SetDrawColor( Color( 0, 0, 0, 200 ) )
		surface.DrawRect( posX, (padY), gpanelW, 76 )

			-- Vars	
		-- Draw background
		--surface.SetMaterial( team_bg )
		--drawBlurAt(0, 0 - gpanelH * 0.8, gpanelW, gpanelH * 2.5)
		
		if ( not IsValid( ply ) ) then
			draw.SimpleTextOutlined( "Not available", "Cyb_Inv_Label", padW, padY, Color( 230, 230, 230, 200 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.5, Color( 0, 0, 0, 200 ) )
			return 
		else
			local alive = ply:Alive();
			local hp = math.Clamp( ply:Health(), 0, 100 )
			local rhp = math.Clamp( ply:GetRealHealth(), 0, 100 )
			local hunger = math.Clamp( ply:GetHunger(), 0, 1000 )
			local thirst = math.Clamp( ply:GetThirst(), 0, 1000 )
			local hpText = hp/50 .. "%"
			local hpColor = Color(140,50,50,255) 
			local rhpColor = Color( 50, 140, 50, 200 )
			local color = Color( 250, 250, 250, 200 )
			local hColor = Color( 50, 200, 50, 255 )
			local tColor = Color( 50, 50, 200, 255 )
			if ply:GetBleed() or (ply:Health() <= 20) then hpColor = Color(Pulsate(1)*140, 50, 50, 255) end
			if ply:GetSick() or (ply:GetRealHealth() <= 20) then rhpColor = Color(50, Pulsate(1)*140, 50, 200 ) end
			if ply:GetHunger() <= 25 then hColor = Color( 50, Pulsate(1)*200, 50, 255 ) end
			if ply:GetThirst() <= 25 then tColor = Color( 50, 50, Pulsate(1)*200, 255 ) end
			
			if not alive then
				hp, rhp, hunger, thirst = 0, 0, 0, 0
				color = Color( 100, 100, 100, 200 )
			end
		
			draw.SimpleTextOutlined( ply:Nick(), "Cyb_Inv_Label", posX+padW, 14+padY, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.5, Color( 0, 0, 0, 200 ) )
			
			-- Draw the bar backgrounds
			surface.SetDrawColor( Color( 50, 50, 50, 200 ) )
			surface.DrawRect( posX+padW, hpHeight+(padY), hpWidth, 3 )
			surface.DrawRect( posX+padW, hpHeight+10+(padY), hpWidth, 3 )
			surface.DrawRect( posX+padW, hpHeight+20+(padY), hpWidth, 3 )
			surface.DrawRect( posX+padW, hpHeight+30+(padY), hpWidth, 3 )
			
			-- blood
			surface.SetDrawColor( hpColor )
			surface.DrawRect( posX+padW, hpHeight+(padY), hpWidth * hp * 0.01, 3 )
			
			-- health
			surface.SetDrawColor( rhpColor )
			surface.DrawRect( posX+padW, hpHeight+10+(padY), hpWidth * rhp * 0.01, 3 )
			
			-- hunger
			surface.SetDrawColor( hColor )
			surface.DrawRect( posX+padW, hpHeight+20+(padY), hpWidth * hunger * 0.001, 3 )
			
			-- thirst
			surface.SetDrawColor( tColor )
			surface.DrawRect( posX+padW, hpHeight+30+(padY), hpWidth * thirst * 0.001, 3 )
			
			if not alive then
				draw.SimpleTextOutlined( "DEAD", "SafeZone_POPUP", posX+gpanelW/2-40, gpanelH/2+3+(padY), Color(255,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0.5, Color( 0, 0, 0, 200 ) )
			end
			
			--draw.SimpleTextOutlined( hpText, "Cyb_Inv_Bar" , padW + hpWidth - 10, hpHeight + 2, color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 0.5, Color( 0, 0, 0, 200 ) )
			padY = padY + 76
		end

	end

end
hook.Add("HUDPaint", "DrawGroups", DrawGroups)