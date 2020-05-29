AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString( "net_DonatorMenu" )

function ENT:Initialize()
   self:SetModel("models/humans/group01/male_01.mdl")
   
   self:SetHullType( HULL_HUMAN )
   self:SetHullSizeNormal();
   self:SetSolid( SOLID_BBOX )
  
   //Sets the entity values
   self:SetHealth(10000000)
   self:SetUseType(SIMPLE_USE)  
end

local TalkSounds = {"vo/npc/male01/vquestion03.wav","vo/npc/male01/littlecorner01.wav","vo/trainyard/male01/cit_window_use03.wav","vo/npc/male01/question19.wav","vo/trainyard/male01/cit_pedestrian01.wav","vo/trainyard/cit_raid_use02.wav","vo/npc/male01/question20.wav","vo/npc/male01/vquestion01.wav","vo/npc/male01/question02.wav","vo/npc/male01/vanswer14.wav","vo/npc/male01/question29.wav","vo/trainyard/male01/cit_pedestrian02.wav","vo/npc/male01/answer17.wav","vo/npc/male01/gordead_ques13.wav","vo/npc/male01/vquestion02.wav","vo/npc/male01/vanswer10.wav","vo/npc/male01/vquestion04.wav","vo/npc/male01/vanswer07.wav","vo/npc/male01/gethellout.wav"}

local nextTalk = 0
local nextTalkE = 0
function ENT:AcceptInput( input, activator, caller )
   if input == "Use" && activator:IsPlayer() then

      net.Start( "net_DonatorMenu" )  
         net.WriteBool(true)
         net.WriteBool(true)
         net.WriteTable( GAMEMODE.DayZ_Shops[ "shop_buy" ] or {} ) -- all items or fallback
      net.Send( activator )

      if activator:IsVIP() then
         activator._VIPSHOP = true
      end
      
      if (nextTalkE or 0) < CurTime() then
         self:EmitSound(table.Random(TalkSounds), 75, 100, 1)

         nextTalkE = CurTime() + 2
      end

      if isfunction(self.SetLevel) then self:SetLevel(999) end

   end
end
   
function ENT:Think()
   if (nextTalk or 0) < CurTime() then
      self:EmitSound(table.Random(TalkSounds), 75, 100, 1)

      nextTalk = CurTime() + math.random(60, 300)
   end
end

function ENT:OnTakeDamage(dmg)
   self:SetHealth(1000000)
end