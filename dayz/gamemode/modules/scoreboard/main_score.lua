local surface = surface
local draw = draw
local math = math
local string = string
local vgui = vgui

surface.CreateFont("cool_small", {font = "coolvetica",
                                  size = 20,
                                  weight = 400})
surface.CreateFont("cool_large", {font = "coolvetica",
                                  size = 24,
                                  weight = 400})
surface.CreateFont("treb_small", {font = "Trebuchet18",
                                  size = 14,
                                  weight = 700})

RankIcons = {}
RankIcons["owner"] = "icon16/key.png"
RankIcons["founder"] = "icon16/key.png"
RankIcons["superadmin"] = "icon16/shield_add.png"
RankIcons["admin"] = "icon16/shield.png"
RankIcons["vipadmin"] = "icon16/star.png"
RankIcons["vip"] = "icon16/heart.png"
RankIcons["user"] = "icon16/user.png"
RankIcons["guest"] = "icon16/user.png"

GROUP_COUNT = 3

GROUP_BOUNTY = -1
GROUP_BANDIT = -2
GROUP_HERO = -3

DZTMColors = {}
DZTMColors[GROUP_BOUNTY] = { clr = Color(200, 0, 0), nm = "Bounties" }
DZTMColors[GROUP_BANDIT] = { clr = Color(255, 178, 0), nm = "Bandits" }
DZTMColors[GROUP_HERO] = { clr = Color(0, 200, 0), nm = "Heroes" }

local PANEL = {}

include("team_score.lua")

local logo = Material("cyb_mat/dayz_logo.png")

function ScoreGroup(p, override)
   if not IsValid(p) then return -999 end -- will not match any group panel

   local teamn = p:Team()

   if override then
      
      if p:Frags() >= PHDayZ.Player_BountyKillsReq then
         teamn = GROUP_BOUNTY
      elseif p:Frags() >= PHDayZ.Player_BanditKillsReq then
         teamn = GROUP_BANDIT
      end

      if p:GetNWBool("isHero") then
         teamn = GROUP_HERO
      end

   end

   return teamn
end

function PANEL:Init()

   self.hostdesc = vgui.Create("DLabel", self)
   self.hostdesc:SetText("")
   self.hostdesc:SetContentAlignment(5)

   self.hostname = vgui.Create( "DLabel", self )
   self.hostname:SetText( PHDayZ.scoreboardtitle )
   self.hostname:SetContentAlignment(5)

   self.version = vgui.Create( "DLabel", self)
   self.version:SetText( "v"..PHDayZ.version )
   self.version:SetContentAlignment(9)

   self.author = vgui.Create( "DLabel", self)
   self.author:SetText("Created by Phoenixf129")
   self.author:SetContentAlignment(9)

   self.ply_frame = vgui.Create( "DZPlayerFrame", self )

   self.ply_groups = {}

   for i=1, 3 do
      
      local GroupPos = -i

      local GroupColor = DZTMColors[GroupPos].clr
      local name = DZTMColors[GroupPos].nm
      GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50)

      local t = vgui.Create("DZScoreGroup", self.ply_frame:GetCanvas())
      t:SetGroupInfo( name, GroupColor, GroupPos )
      self.ply_groups[GroupPos] = t

   end

   for k, v in ipairs( team.GetAllTeams() ) do
   
      local GroupColor = v.Color
      GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50)

      local GroupPos = k
      local t = vgui.Create("DZScoreGroup", self.ply_frame:GetCanvas())
      t:SetGroupInfo( v.Name, GroupColor, GroupPos, v.Leader )
      self.ply_groups[GroupPos] = t

   end

   -- the various score column headers
   self.cols = {}
   self:AddColumn( "Ping" )
   self:AddColumn( "Level" )
   self:AddColumn( "K | D | TK" )

   -- Let hooks add their column headers (via AddColumn())
   hook.Call( "DZScoreboardColumns", nil, self )

   self:UpdateScoreboard()
   self:StartUpdateTimer()
end

-- For headings only the label parameter is relevant, func is included for
-- parity with sb_row
function PANEL:AddColumn( label, func, width )
   self.cols = self.cols or {}
   local lbl = vgui.Create( "DLabel", self )
   lbl:SetText( label )
   lbl.IsHeading = true
   lbl.Width = width or 50 -- Retain compatibility with existing code

   table.insert( self.cols, lbl )
   return lbl
end

function PANEL:StartUpdateTimer()
   if not timer.Exists("DZScoreboardUpdater") then
      timer.Create( "DZScoreboardUpdater", 0.1, 0,
       function()
          local pnl = GAMEMODE:GetScoreboardPanel()
          if IsValid(pnl) then
             pnl:UpdateScoreboard()
          end
       end)
   end
end

local colors = {
   bg = Color(30,30,30, 235),
   bar = Color(220,0,0,50)
};

local y_logo_off = 72

function PANEL:Paint()
   -- Logo sticks out, so always offset bg
   draw.RoundedBox( 8, 0, y_logo_off, self:GetWide(), self:GetTall() - y_logo_off, colors.bg)

   -- Server name is outlined by orange/gold area
   draw.RoundedBox( 0, 0, y_logo_off + 25, self:GetWide(), 46, colors.bar)

   --surface.SetTexture( logo )
   surface.SetMaterial( logo )
   surface.SetDrawColor( 255, 255, 255, 255 )
   surface.DrawTexturedRect( 5, 0, 256, 256 )

end

function PANEL:PerformLayout()
   -- position groups and find their total size

   local gy = 0
   -- can't just use pairs (undefined ordering) or ipairs (group 2 and 3 might not exist) 

   for i=1, 3 do
      local group = self.ply_groups[-i]
      if ValidPanel(group) then
         if group:HasRows() then
            group:SetVisible(true)
            group:SetPos(0, gy)
            group:SetSize(self.ply_frame:GetWide(), group:GetTall())
            group:InvalidateLayout()
            gy = gy + group:GetTall() + 5
         else
            group:SetVisible(false)
         end
      end
   end

   for i, v in pairs(team.GetAllTeams()) do

      local group = self.ply_groups[i]
      if ValidPanel(group) then
         if group:HasRows() then
            group:SetVisible(true)
            group:SetPos(0, gy)
            group:SetSize(self.ply_frame:GetWide(), group:GetTall())
            group:InvalidateLayout()
            gy = gy + group:GetTall() + 5
         else
            group:SetVisible(false)
         end
      else
         if team.GetAllTeams()[i] then

            local GroupPos = i
            local GroupColor = team.GetAllTeams()[i].Color
            GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50)

            local t = vgui.Create("DZScoreGroup", self.ply_frame:GetCanvas())
            t:SetGroupInfo(team.GetAllTeams()[i].Name, GroupColor, GroupPos, team.GetAllTeams()[i].Leader )
            self.ply_groups[GroupPos] = t

            if ValidPanel(t) then
               if t:HasRows() then
                  t:SetVisible(true)
                  t:SetPos(0, gy)
                  t:SetSize(self.ply_frame:GetWide(), t:GetTall())
                  t:InvalidateLayout()
                  gy = gy + t:GetTall() + 5
               else
                  t:SetVisible(false)
               end
            end
         end
      end
   end

   self.ply_frame:GetCanvas():SetSize(self.ply_frame:GetCanvas():GetWide(), gy)

   local h = y_logo_off + 110 + self.ply_frame:GetCanvas():GetTall()

   -- if we will have to clamp our height, enable the mouse so player can scroll
   local scrolling = h > ScrH() * 0.95
--   gui.EnableScreenClicker(scrolling)
   self.ply_frame:SetScroll(scrolling)

   h = math.Clamp(h, 110 + y_logo_off, ScrH() * 0.95)

   local w = math.max(ScrW() * 0.6, 640)

   self:SetSize(w, h)
   self:SetPos( (ScrW() - w) / 2, math.min(72, (ScrH() - h) / 4))

   self.ply_frame:SetPos(8, y_logo_off + 109)
   self.ply_frame:SetSize(self:GetWide() - 16, self:GetTall() - 109 - y_logo_off - 5)

   -- server stuff
   self.hostdesc:SizeToContents()
   self.hostdesc:SetPos(w/2 - self.hostdesc:GetWide()/2, y_logo_off + 5)

   local hw = w - 180 - 8
   self.hostname:SetSize(hw, 40)
   self.hostname:SetPos(w/2 - self.hostname:GetWide()/2, y_logo_off + 27)
   self.version:SetPos(w-self.version:GetWide()-5, y_logo_off+17)
   self.version:SizeToContents()
   self.author:SetPos(w-self.author:GetWide()-5, y_logo_off+2)
   self.author:SizeToContents()

   surface.SetFont("SafeZone_NAME")
   local hname = PHDayZ.scoreboardtitle
   local tw, _ = surface.GetTextSize(hname)
   while tw > hw do
      hname = string.sub(hname, 1, -6) .. "..."
      tw, th = surface.GetTextSize(hname)
   end

   self.hostname:SetText(hname)

   -- score columns
   local cy = y_logo_off + 90
   local cx = w - 8 -(scrolling and 16 or 0)
   self.cols = self.cols or {}
   for k,v in ipairs(self.cols) do
      v:SizeToContents()
      cx = cx - v.Width
      v:SetPos(cx - v:GetWide()/2, cy)
   end
end

function PANEL:ApplySchemeSettings()
   self.hostdesc:SetFont("SafeZone_NAME")
   self.hostname:SetFont("SafeZone_NAME")
   self.version:SetFont("Cyb_Inv_Label")

   self.hostdesc:SetTextColor(COLOR_WHITE)
   self.hostname:SetTextColor(COLOR_BLACK)
   self.version:SetTextColor(COLOR_GREY)
   self.author:SetTextColor(COLOR_GREY)

   for k,v in pairs(self.cols) do
      v:SetFont("Cyb_Inv_Label")
      v:SetTextColor(COLOR_WHITE)
   end
end

function PANEL:UpdateScoreboard( force )
   if not force and not self:IsVisible() then return end

   -- Put players where they belong. Groups will dump them as soon as they don't
   -- anymore.

   for i=1, 3 do
      local GroupPos = -i
      local GroupColor = DZTMColors[GroupPos].clr
      local name = DZTMColors[GroupPos].nm

      GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50)

      if !self.ply_groups[GroupPos] then
         local t = vgui.Create("DZScoreGroup", self.ply_frame:GetCanvas())
         t:SetGroupInfo(name, GroupColor, GroupPos)
         self.ply_groups[GroupPos] = t
      else
         self.ply_groups[GroupPos]:SetGroupInfo(name, GroupColor, GroupPos)
      end
   end

   for k, v in ipairs(team.GetAllTeams()) do
      local GroupPos = k

      local GroupColor = v.Color
      GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50)

      if !self.ply_groups[GroupPos] then
         local t = vgui.Create("DZScoreGroup", self.ply_frame:GetCanvas())
         t:SetGroupInfo(v.Name, GroupColor, GroupPos)
         self.ply_groups[GroupPos] = t
      else
         self.ply_groups[GroupPos]:SetGroupInfo(v.Name, GroupColor, GroupPos, v.Leader)
      end
   end

   for k, p in pairs(player.GetAll()) do
      if IsValid(p) then
         local group = ScoreGroup(p)
         local teamn = ScoreGroup(p, true)

         if teamn != group then
            if self.ply_groups[teamn] and not self.ply_groups[teamn]:HasPlayerRow(p) then
               self.ply_groups[teamn]:AddPlayerRow(p)
            end
         end

         if self.ply_groups[group] and not self.ply_groups[group]:HasPlayerRow(p) then
            self.ply_groups[group]:AddPlayerRow(p)
         end
      end
   end

   for k, group in pairs(self.ply_groups) do
      if ValidPanel(group) then
         group:SetVisible( group:HasRows() )
         group:UpdatePlayerData()
      end
   end

   self:PerformLayout()
end

vgui.Register( "DZScoreboard", PANEL, "Panel" )

---- PlayerFrame is defined in sandbox and is basically a little scrolling
---- hack. Just putting it here (slightly modified) because it's tiny.

local PANEL = {}
function PANEL:Init()
   self.pnlCanvas  = vgui.Create( "Panel", self )
   self.YOffset = 0

   self.scroll = vgui.Create("DVScrollBar", self)

   PaintVBar( self.scroll )
end

function PANEL:GetCanvas() return self.pnlCanvas end

function PANEL:OnMouseWheeled( dlta )
   self.scroll:AddScroll(dlta * -2)

   self:InvalidateLayout()
end

function PANEL:SetScroll(st)
   self.scroll:SetEnabled(st)
end

function PANEL:PerformLayout()
   self.pnlCanvas:SetVisible(self:IsVisible())

   -- scrollbar
   self.scroll:SetPos(self:GetWide() - 16, 0)
   self.scroll:SetSize(16, self:GetTall())

   local was_on = self.scroll.Enabled
   self.scroll:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
   self.scroll:SetEnabled(was_on) -- setup mangles enabled state

   self.YOffset = self.scroll:GetOffset()

   self.pnlCanvas:SetPos( 0, self.YOffset )
   self.pnlCanvas:SetSize( self:GetWide() - (self.scroll.Enabled and 16 or 0), self.pnlCanvas:GetTall() )
end
vgui.Register( "DZPlayerFrame", PANEL, "Panel" )