AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString( "net_DonatorMenu" )

function ENT:Initialize()
   self:SetModel("models/Humans/Group03/male_07.mdl")
   
   self:SetHullType( HULL_HUMAN )
   self:SetHullSizeNormal();
   self:SetSolid( SOLID_BBOX )
   self:CapabilitiesAdd( CAP_ANIMATEDFACE, CAP_TURN_HEAD, CAP_DUCK)
   
   //Sets the entity values
   self:SetHealth(10000000)
   self:SetUseType(SIMPLE_USE)  
end

local TalkSounds = {"vo/npc/male01/vquestion03.wav","vo/npc/male01/littlecorner01.wav","vo/trainyard/male01/cit_window_use03.wav","vo/npc/male01/question19.wav","vo/trainyard/male01/cit_pedestrian01.wav","vo/trainyard/cit_raid_use02.wav","vo/npc/male01/question20.wav","vo/npc/male01/vquestion01.wav","vo/npc/male01/question02.wav","vo/npc/male01/vanswer14.wav","vo/npc/male01/question29.wav","vo/trainyard/male01/cit_pedestrian02.wav","vo/npc/male01/answer17.wav","vo/npc/male01/gordead_ques13.wav","vo/npc/male01/vquestion02.wav","vo/npc/male01/vanswer10.wav","vo/npc/male01/vquestion04.wav","vo/npc/male01/vanswer07.wav","vo/npc/male01/gethellout.wav"}

local nextTalk = 0
local nextTalkE = 0
function ENT:AcceptInput( input, activator, caller )
   if input == "Use" && activator:IsPlayer() then
      
      activator._VIPSHOP = false

      net.Start( "net_DonatorMenu" )  
         net.WriteBool(false)
         net.WriteBool(false)
         net.WriteTable( GAMEMODE.CurrentShopInv or {} ) -- fallback
      net.Send( activator )
      
      if nextTalkE < CurTime() then
         self:EmitSound(table.Random(TalkSounds), 75, 100, 1)

         nextTalkE = CurTime() + 2
      end

      if isfunction(self.SetLevel) then self:SetLevel(999) end


   end
end

function ENT:Think()
   if nextTalk == 0 then nextTalk = CurTime() + math.random(1, 15) return end

   if (nextTalk or 0) < CurTime() then
      self:EmitSound(table.Random(TalkSounds), 75, 100, 1)

      nextTalk = CurTime() + math.random(30, 120)
   end
end

function ENT:OnTakeDamage(dmg)
   self:SetHealth(1000000)
end