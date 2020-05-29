--- Scoreboard player score row, based on sandbox version

include("info_score.lua")

SB_ROW_HEIGHT = 24 --16

local PANEL = {}

function PANEL:Init()
   -- cannot create info card until player state is known
   self.info = nil

   self.open = false

   self.cols = {}
   self:AddColumn( "Ping", function(ply) return "" end )
   self:AddColumn( "Level", function(ply) return ply:GetLevel() end)
   self:AddColumn( "K | D | TK", function(ply) return ply:Frags() .. " | " .. ply:Deaths() .. " | " ..ply:PFrags() end )

   -- Let hooks add their custom columns
   hook.Call("DZScoreboardColumns", nil, self)

   for _, c in ipairs(self.cols) do
      c:SetMouseInputEnabled(false)
   end

   self.tag = vgui.Create("DLabel", self)
   self.tag:SetText("")
   self.tag:SetMouseInputEnabled(false)

   self.rank = vgui.Create("DImage", self)
   self.rank:SetSize(16, 16)
   self.rank:SetImage("icon16/wrench.png")

   self.avatar = vgui.Create( "AvatarImage", self )
   self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
   self.avatar:SetMouseInputEnabled(false)

   self.title = vgui.Create("DLabel", self)
   self.title:SetMouseInputEnabled(false)

   self.nick = vgui.Create("DLabel", self)
   self.nick:SetMouseInputEnabled(false)

   self.voice = vgui.Create("DImageButton", self)
   self.voice:SetSize(16,16)

   self:SetCursor( "hand" )
end

function PANEL:AddColumn( label, func, width )
   self.cols = self.cols or {}
   local lbl = vgui.Create( "DLabel", self )
   lbl.GetPlayerText = func
   lbl.IsHeading = false
   lbl.Width = width or 50 -- Retain compatibility with existing code

   table.insert( self.cols, lbl )
   return lbl
end


local namecolor = {
   default = COLOR_WHITE,
   admin = Color(220, 180, 0, 255),
   dev = Color(100, 240, 105, 255)
};

local preset_colors = {}
preset_colors["STEAM_0:0:39587206"] = Color(255,69,0,255)
preset_colors["STEAM_0:0:49256684"] = Color(255,105,180,255)
preset_colors["STEAM_0:1:30715453"] = Color(255,255,0,255)
preset_colors["STEAM_0:1:49954517"] = Color(255,255,0,255)
preset_colors["STEAM_0:1:22054147"] = Color(255,255,0,255)
preset_colors["STEAM_0:1:32676339"] = Color(255,255,0,255)
preset_colors["STEAM_0:0:80747471"] = Color(255,255,0,255)
preset_colors["STEAM_0:1:58945532"] = Color(255,255,0,255)
preset_colors["STEAM_0:0:63974957"] = Color(255,255,0,255)

local titles = {}
titles["STEAM_0:0:39587206"] = "Creator"
titles["STEAM_0:0:49256684"] = "Test Dummy"
titles["STEAM_0:1:30715453"] = "Beta Tester"
titles["STEAM_0:1:49954517"] = "Beta Tester"
titles["STEAM_0:1:22054147"] = "Aesthetic Master"
titles["STEAM_0:1:32676339"] = "Beta Tester"
titles["STEAM_0:0:80747471"] = "Beta Tester"
titles["STEAM_0:0:63974957"] = "Beta Tester"
titles["STEAM_0:1:58945532"] = "Soprano"

local function ColorForPlayer(ply)
   if IsValid(ply) then
      local c = hook.Call("DZScoreboardColorForPlayer", GM, ply)

      -- verify that we got a proper color
      if c and type(c) == "table" and c.r and c.b and c.g and c.a then
         return c
      else
         --ErrorNoHalt("DZScoreboardColorForPlayer hook returned something that isn't a color!\n")
      end
   end
   return namecolor.default
end

local function ColorForPlayerTitle(ply)
   if IsValid(ply) then
      local c 

      if preset_colors[ ply:SteamID() ] then
         c = preset_colors[ ply:SteamID() ]

         if titles[ ply:SteamID() ] == "Creator" then
            c = HSVToColor( CurTime() * 60 % 360, 1, 1 )
         end

      end

      -- verify that we got a proper color
      if c and type(c) == "table" and c.r and c.b and c.g and c.a then
         return c
      else
         --ErrorNoHalt("DZScoreboardColorForPlayer hook returned something that isn't a color!\n")
      end
   end
   return namecolor.default
end


function PANEL:Paint()
   if not IsValid(self.Player) then return end

   local ply = self.Player

   surface.SetDrawColor( Color(0, 0, 0, 150) )
   surface.DrawRect(0, 0, self:GetWide(), SB_ROW_HEIGHT)

   local pingx, pingy = self:GetWide()-60, 5
   if ply:IsValid() then
		if ply:Ping() < 100 then
		draw.RoundedBox(0,pingx,pingy+8,4,4,Color(0, 255, 0, 255))
		draw.RoundedBox(0,pingx+5,pingy+4,4,8,Color(0, 255, 0, 255))
		draw.RoundedBox(0,pingx+10,pingy,4,12,Color(0, 255, 0, 255))
	elseif ply:Ping() < 225 then
      draw.RoundedBox(0,pingx,pingy+8,4,4,Color(255, 255, 0, 255))
		draw.RoundedBox(0,pingx+5,pingy+4,4,8,Color(255, 255, 0, 255))
		draw.RoundedBox(0,pingx+10,pingy,4,12,Color(155, 155, 155, 255))
	else 
      draw.RoundedBox(0,pingx,pingy+8,4,4,Color(255, 0, 0, 255))
		draw.RoundedBox(0,pingx+5,pingy+4,4,8,Color(155, 155, 155, 255))
		draw.RoundedBox(0,pingx+10,pingy,4,12,Color(155, 155, 155, 255))
	end

	draw.DrawText(ply:Ping(), "Cyb_HudTEXTSmall", pingx+17, pingy, Color(255, 255, 255, 150),TEXT_ALIGN_LEFT)	
end

   if ply == LocalPlayer() then
      surface.SetDrawColor( 200, 200, 200, math.Clamp(math.sin(RealTime() * 2) * 50, 0, 100))
      surface.DrawRect(0, 0, self:GetWide(), SB_ROW_HEIGHT )
   end

   return true
end

function PANEL:SetPlayer(ply)
   self.Player = ply
   self.avatar:SetPlayer(ply)

   if not self.info then
      local g = ScoreGroup(ply)
      self.info = vgui.Create("DZScorePlayerInfoTags", self)
      self.info:SetPlayer(ply)
      self:InvalidateLayout()
   else
      self.info:SetPlayer(ply)

      self:InvalidateLayout()
   end

   self.voice.DoClick = function()
       if IsValid(ply) and ply != LocalPlayer() then
          ply:SetMuted(not ply:IsMuted())
       end
    end

   self:UpdatePlayerData()
end

function PANEL:GetPlayer() return self.Player end

function PANEL:UpdatePlayerData()
   if not IsValid(self.Player) then return end

   local ply = self.Player
   for i=1,#self.cols do
       -- Set text from function, passing the label along so stuff like text
       -- color can be changed
      self.cols[i]:SetText( self.cols[i].GetPlayerText(ply, self.cols[i]) )
   end

   if ply:IsVIP() and !ply:IsAdmin() then
      self.rank:SetImage(RankIcons["vip"])
      self.rank:SetTooltip( "VIP" )
   end

   if ply.GetHelperUserGroup then
      self.rank:SetImage(RankIcons[ply:GetHelperUserGroup()] or "icon16/user.png")
      self.rank:SetTooltip( ply:GetHelperUserGroup() )
   end

   if ply:IsSuperAdmin() or ply:IsAdmin() and PHDayZ.AdminsHide then
      self.rank:SetImage(RankIcons["vip"])
      self.rank:SetTooltip( "VIP" )
   end

   self.title:SetText("") -- blank for magic

   if table.HasValue( DZ_Supporters, ply:SteamID() ) then
      self.title:SetText( "Supporter" )
      self.title:SizeToContents()
      self.title:SetTextColor( Color(255, 165, 0, 255) )
   end

   if titles[ply:SteamID()] then
      self.title:SetText( titles[ply:SteamID()] )
      self.title:SizeToContents()
      self.title:SetTextColor(ColorForPlayerTitle(ply))
   end

   self.nick:SetText( (ply:GetAFK() and "[AFK] " or "")..ply:Nick() )
   self.nick:SizeToContents()
   self.nick:SetTextColor(ColorForPlayer(ply))

   local ptag = ply.sb_tag
   if ScoreGroup(ply) != GROUP_TERROR then
      ptag = nil
   end

   self.tag:SetText(ptag and ptag.txt or "")
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)

   -- cols are likely to need re-centering
   self:LayoutColumns()

   if self.info then
      self.info:UpdatePlayerData()
   end

   if self.Player != LocalPlayer() then
      local muted = self.Player:IsMuted()
      self.voice:SetImage(muted and "icon16/sound_mute.png" or "icon16/sound.png")
   else
      self.voice:Hide()
   end
end

function PANEL:ApplySchemeSettings()
   for k,v in pairs(self.cols) do
      v:SetFont("Cyb_Inv_Label")
      v:SetTextColor(COLOR_WHITE)
   end

   self.nick:SetFont("Cyb_Inv_Bar")
   self.nick:SetTextColor(ColorForPlayer(self.Player))

   self.title:SetFont("Cyb_Inv_Bar")
   self.title:SetTextColor(ColorForPlayerTitle(self.Player))

   local ptag = self.Player and self.Player.sb_tag
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
   self.tag:SetFont("Cyb_Inv_Label")

end

function PANEL:LayoutColumns()
   local cx = self:GetWide()
   for k,v in ipairs(self.cols) do
      v:SizeToContents()
      cx = cx - v.Width
      v:SetPos(cx - v:GetWide()/2, (SB_ROW_HEIGHT - v:GetTall()) / 2)
   end

   self.tag:SizeToContents()
   cx = cx - 90
   self.tag:SetPos(cx - self.tag:GetWide()/2, (SB_ROW_HEIGHT - self.tag:GetTall()) / 2)

end

function PANEL:PerformLayout()
   self.avatar:SetPos(24,0)
   self.avatar:SetSize(SB_ROW_HEIGHT,SB_ROW_HEIGHT)

   self.rank:SetPos(4,4)

   local fw = sboard_panel.ply_frame:GetWide()
   self:SetWide( sboard_panel.ply_frame.scroll.Enabled and fw-16 or fw )

   if not self.open then
      self:SetSize(self:GetWide(), SB_ROW_HEIGHT)

      if self.info then self.info:SetVisible(false) end
   elseif self.info then
      self:SetSize(self:GetWide(), 100 + SB_ROW_HEIGHT)

      self.info:SetVisible(true)
      self.info:SetPos(5, SB_ROW_HEIGHT + 5)
      self.info:SetSize(self:GetWide(), 100)
      self.info:PerformLayout()

      self:SetSize(self:GetWide(), SB_ROW_HEIGHT + self.info:GetTall())
   end

   self.nick:SizeToContents()
   self.title:SizeToContents()

   self.nick:SetPos(SB_ROW_HEIGHT + 30, (SB_ROW_HEIGHT - self.nick:GetTall()) / 2)

   if self.title:GetText() != "" then
      self.title:SetPos(SB_ROW_HEIGHT + 30, (SB_ROW_HEIGHT - self.title:GetTall()) / 2)

      self.nick:SetPos(SB_ROW_HEIGHT + 35 + self.title:GetWide(), (SB_ROW_HEIGHT - self.nick:GetTall()) / 2)
   end

   self:LayoutColumns()

   self.voice:SetVisible(not self.open)
   self.voice:SetSize(16, 16)
   self.voice:DockMargin(4, 4, 4, 4)
   self.voice:Dock(RIGHT)
end

function PANEL:DoClick(x, y)
   self:SetOpen(not self.open)
end

function PANEL:SetOpen(o)
   if self.open then
      surface.PlaySound("ui/buttonclickrelease.wav")
   else
      surface.PlaySound("ui/buttonclick.wav")
   end

   self.open = o

   if self.info then self.info:UpdateData() end

   self:PerformLayout()
   self:GetParent():PerformLayout()
   sboard_panel:PerformLayout()
end

function PANEL:DoRightClick()
   local menu = DermaMenu()
   menu.Player = self:GetPlayer()

   local close = hook.Call( "DZScoreboardMenu", nil, menu )
   if close then menu:Remove() return end
   
   local CopyMenu = menu:AddSubMenu("Copy")

   CopyMenu:AddOption(menu.Player:Nick(true), function()
      SetClipboardText(menu.Player:Nick(true))
   end):SetIcon("icon16/page_copy.png")
   
   CopyMenu:AddOption("SteamID", function()
   	SetClipboardText(menu.Player:SteamID())
   end):SetIcon("icon16/page_copy.png")

   CopyMenu:AddOption("SteamID64", function()
   	SetClipboardText(menu.Player:SteamID64())
   end):SetIcon("icon16/page_copy.png")

   menu:AddOption("Open Steam Community URL", function()
   	gui.OpenURL("http://steamcommunity.com/profiles/"..menu.Player:SteamID64())
   end):SetIcon("icon16/world_link.png")

   menu:AddSpacer()

   menu:Open()
end

vgui.Register( "DZScorePlayerRow", PANEL, "Button" )