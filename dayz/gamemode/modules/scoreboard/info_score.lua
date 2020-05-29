---- Player info panel,

local vgui = vgui

--- Base stuff
local PANEL = {}

function PANEL:Init()
   self.Player = nil

   --self:SetMouseInputEnabled(false)
end

function PANEL:SetPlayer(ply)
   self.Player = ply
   self:UpdatePlayerData()
end

function PANEL:UpdatePlayerData()
   -- override me
end

function PANEL:Paint()
   return true
end

vgui.Register("DZScorePlayerInfoBase", PANEL, "Panel")

--- Dead player search results 112579743

local PANEL = {}

function PANEL:Init()
   self.List = vgui.Create("DPanelSelect", self)
   self.List:EnableHorizontal(true)

   if self.List.VBar then
      self.List.VBar:Remove()
      self.List.VBar = nil
   end

   self.Scroll = vgui.Create("DHorizontalScroller", self.List)

   self.Help = vgui.Create("DLabel", self)
   self.Help:SetText("Help")
   self.Help:SetFont("Cyb_Inv_Label")
   self.Help:SetVisible(false)
end

function PANEL:PerformLayout()
   self:SetSize(self:GetWide(), 75)

   self.List:SetPos(0, 0)
   self.List:SetSize(self:GetWide(), 70)
   self.List:SetSpacing(1)
   self.List:SetPadding(2)
   self.List:SetDrawBackground(false)

   self.Scroll:StretchToParent(3,3,3,3)

   self.Help:SizeToContents()
   self.Help:SetPos(5, 5)
end

function PANEL:UpdatePlayerData()
   if not IsValid(self.Player) then return end

   self.Help:SetVisible(false)

   if self.Search == self.Player.search_result then return end

   self.List:Clear(true)
   self.Scroll.Panels = {}

   local search_raw = self.Player.search_result

   -- standard search result preproc
   local search = PreprocSearch(search_raw)

   -- wipe some stuff we don't need, like id
   search.nick = nil

   -- Create table of SimpleIcons, each standing for a piece of search
   -- information.
   for t, info in SortedPairsByMemberValue(search, "p") do
      local ic = nil

      -- Certain items need a special icon conveying additional information
      if t == "lastid" then
         ic = vgui.Create("SimpleIconAvatar", self.List)
         ic:SetPlayer(info.ply)
         ic:SetAvatarSize(24)
      elseif t == "dtime" then
         ic = vgui.Create("SimpleIconLabelled", self.List)
         ic:SetIconText(info.text_icon)
      else
         ic = vgui.Create("SimpleIcon", self.List)
      end

      ic:SetIconSize(64)
      ic:SetIcon(info.img)

      ic:SetTooltip(info.text)

      ic.info_type = t

      self.List:AddPanel(ic)
      self.Scroll:AddPanel(ic)
   end

   self.Search = search_raw

   self.List:InvalidateLayout()
   self.Scroll:InvalidateLayout()

   self:PerformLayout()
end



vgui.Register("DZScorePlayerInfoSearch", PANEL, "DZScorePlayerInfoBase")

--- Living player, tags etc
local PANEL = {}

function PANEL:Init()
   --self:SetMouseInputEnabled(false)

end

function PANEL:SetPlayer(ply)
   self.Player = ply
   self:UpdateData()

   self:InvalidateLayout()
end

function PANEL:ApplySchemeSettings()

end

function PANEL:UpdateData()
   if not IsValid(self.Player) then return end
   local ply = self.Player

   self:Clear()

   self.playermodel = vgui.Create("DModelPanel", self)
   self.playermodel:SetModel(ply:GetModel())
   self.playermodel:SetSize(64,64)
   self.playermodel.LayoutEntity = function(ent) end
   self.playermodel:SetPos(0,0)
   if self.playermodel:GetEntity():LookupBone("ValveBiped.Bip01_Head1") then
	   local eyepos = self.playermodel:GetEntity():GetBonePosition(self.playermodel:GetEntity():LookupBone("ValveBiped.Bip01_Head1"))
	   eyepos:Add(Vector(2, 0, 2))	-- Move up slightly
	   self.playermodel:SetLookAt(eyepos)
	   self.playermodel:SetCamPos(eyepos-Vector(-12, 0, 0))
	   self.playermodel.Entity:SetEyeTarget(eyepos-Vector(-12, 0, 0))
   end

   if ply:Frags() >= PHDayZ.Player_BountyKillsReq then
	   self.weapons = self.weapons or {}

	   self.weppanel = vgui.Create("DPanel", self)
	   self.weppanel.Paint = function(self, w, h)

		   draw.RoundedBoxEx(0,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)

	   end
	   self.weppanel.label = vgui.Create("DLabel", self.weppanel)
	   self.weppanel.label:SetText("Bounties weapons: ")
	   self.weppanel.label:Dock(TOP)
	   self.weppanel.label:SetContentAlignment(5)

   	local i = 0
	   local DefaultWeapons = { "weapon_physgun", "gmod_tool", "weapon_emptyhands", "weapon_physcannon" }
	   for k, v in pairs( ply:GetWeapons() ) do
	   	  if table.HasValue( DefaultWeapons, v:GetClass() ) then continue end

	   	  i = i + 64
	   	  self.weapons[v] = vgui.Create("DPanel", self.weppanel)
	   	  self.weapons[v].Paint = function(ent) end
	   	  self.weapons[v].modelpanel = vgui.Create("DModelPanel", self.weapons[v])
	   	  self.weapons[v].modelpanel:SetModel(v:GetModel())
	   	  self.weapons[v]:SetSize(64,64)
	   	  self.weapons[v]:Dock(RIGHT)
	   	  self.weapons[v].modelpanel.LayoutEntity = function(ent) end
	   	  self.weapons[v].modelpanel:Dock(FILL)

           if IsValid(self.weapons[v].modelpanel:GetEntity()) then -- Fuck knows why this becomes invalid...
   	        local mn, mx = self.weapons[v].modelpanel:GetEntity():GetRenderBounds();
   		     local size = 0;
   		     size = math.max(size, math.abs(mn.x) + math.abs(mx.x));
   		     size = math.max(size, math.abs(mn.y) + math.abs(mx.y));
   		     size = math.max(size, math.abs(mn.z) + math.abs(mx.z));

   	        self.weapons[v].modelpanel:SetFOV(45);
   		     self.weapons[v].modelpanel:SetCamPos(Vector(size, size, size));
   		     self.weapons[v].modelpanel:SetLookAt((mn + mx) * 0.5);
           end
	   end

  	   self.weppanel:SetSize(i, 64)
   	self.weppanel:SetPos(self:GetWide()-self.weppanel:GetWide(), self:GetTall()-self.weppanel:GetTall())

   end

end

function PANEL:Paint(w, h)

	surface.SetDrawColor(Color(0,0,0,150))
    surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

end

function PANEL:PerformLayout()
   self:SetSize(self:GetWide(), 64)

   local margin = 10
   local x = 250 --29
   local y = 0

end

vgui.Register("DZScorePlayerInfoTags", PANEL, "DZScorePlayerInfoBase")