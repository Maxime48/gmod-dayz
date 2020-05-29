local table = table
local surface = surface
local draw = draw
local math = math
local team = team

GM = GM or GAMEMODE

RankColors = {}
RankColors["founder"] = { txt = "Founder", col = Color(255,0,0,255)}
RankColors["owner"] = { txt = "Owner", col = Color(255,0,0,255)}
RankColors["superadmin"] = { txt = "Super Admin", col = Color(0,255,0,255)}
RankColors["admin"] = { txt = "Admin", col = Color(0,200,255,255)}
RankColors["vip"] = { txt = "VIP", col = Color(0,0,255,255)}
RankColors["member"] = { txt = "Member", col = Color(255,255,255,255)}

include("main_score.lua") 

local namecolor = {
   admin = Color(220, 180, 0, 255)
};

sboard_panel = sboard_panel or nil
local function ScoreboardRemove()
   if sboard_panel then
      sboard_panel:Remove()
      sboard_panel = nil 
   end
end
hook.Add("DZLanguageChanged", "RebuildScoreboard", ScoreboardRemove)
concommand.Add("dz_reloadscoreboard", ScoreboardRemove)
function GM:ScoreboardCreate()
   ScoreboardRemove() 

   sboard_panel = vgui.Create("DZScoreboard")
end

function GM:ScoreboardShow()
   self.ShowScoreboard = true

   if not IsValid(sboard_panel) then
      self:ScoreboardCreate()
   end

   gui.EnableScreenClicker(true)

   sboard_panel:SetVisible(true)
   sboard_panel:UpdateScoreboard(true)

   sboard_panel:StartUpdateTimer()
end

function GM:ScoreboardHide()
   self.ShowScoreboard = false

   gui.EnableScreenClicker(false)

   if IsValid(sboard_panel) then
      sboard_panel:SetVisible(false)
   end
end

function GM:GetScoreboardPanel()
   return sboard_panel
end

function GM:HUDDrawScoreBoard()
   -- replaced by panel version
end

function GM:DZScoreboardColorForPlayer(ply)
   if not IsValid(ply) then return namecolor.default end

   if ply:IsAdmin() and GetGlobalBool("dz_highlight_admins", true) && !PHDayZ.AdminsHide then
      return namecolor.admin
   end
   return namecolor.default
end