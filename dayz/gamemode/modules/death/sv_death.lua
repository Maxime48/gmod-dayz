util.AddNetworkString("SendHitInfo")
util.AddNetworkString("HurtInfo")
util.AddNetworkString("CloseOpenMenus")
util.AddNetworkString("ZombiePModel")
util.AddNetworkString("RZombiePModel")
util.AddNetworkString("net_DeathMessage")
util.AddNetworkString("net_DeathMessage2")
util.AddNetworkString("ragdoll_DoLoot")
util.AddNetworkString("ragdoll_DoBury")
util.AddNetworkString("ragdoll_DoRevive")
util.AddNetworkString("ragdoll_DoKill")
util.AddNetworkString("StartBleedOut")

hook.Add("ShutDown", "Savetheammos", function()
    for k, v in pairs(player.GetAll()) do
        v:EmptyClip(nil, nil, true)
    end
end)

net.Receive("ragdoll_DoBury", function(len, ply)
    local ent_id = net.ReadUInt(32)
    local self = Entity( ent_id )

    if !IsValid(self) then return end

    if !ply:CanPerformAction() then return end

    if !ply:HasItem("seed_hoe", true) && !ply:HasCharItem("seed_hoe", true) then return end

    if self:GetClass() != "prop_ragdoll" and self:GetClass() != "grave" then return end

    if !self.dzsearchable then return end

    if ply:GetInArena() && self.ply then ply:Tip(3, "You cannot bury a respawning player, dickhead!", Color(255,0,0)) return end

    if self:GetPos():Distance(ply:GetPos()) > 200 then  return end

    if self:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end
    
    ply:DoModelProcess(self:GetModel(), "Burying "..self:GetStoredName(), 5, "player/footsteps/sand"..math.random(1,2)..".wav", 0, "", true, function()
        if !IsValid(ply) or !ply:Alive() then return end
        if !IsValid(self) then return end

        local bones = self:GetPhysicsObjectCount()
        if ( bones < 2 ) then return end

        print(ply:Nick().." buried "..self:GetStoredName())

        for bone = 1, bones-1 do
            local b = self:GetPhysicsObjectNum( bone )
            b:EnableCollisions( false )
            b:EnableMotion( false )
        end

        local phys = self:GetPhysicsObject()
        
        if IsValid(phys) then
            phys:EnableCollisions( false )
        end

        local t = 0
        timer.Create(self:EntIndex().."_burying", 0.1, 20, function()
            if !IsValid(self) then return end
            t = t + 1
            local bones = self:GetPhysicsObjectCount()
            if ( bones < 2 ) then return end

            for bone = 1, bones-1 do
                local b = self:GetPhysicsObjectNum( bone )
                local pos = b:GetPos()

                pos.z = pos.z - 2

                b:EnableCollisions( false )
                b:SetPos(pos)
            end

            if ( self.lastSound or 0 ) < CurTime() then
                self:EmitSound("player/footsteps/sand"..math.random(1,2)..".wav")    
                self.lastSound = CurTime() + 0.2        
            end

            if t == 20 then
                self:Remove()
            end
            
        end)

        self:DrawShadow(false)


    end)
end)

net.Receive("ragdoll_DoKill", function(len, ply)
    local ent_id = net.ReadUInt(32)
    local self = Entity( ent_id )

    if !IsValid(self) then return end
    if !IsValid(self.ply) then return end

    if !ply:CanPerformAction() then return end

    if self:GetClass() != "prop_ragdoll" and self:GetClass() != "grave" then return end

    if !self.dzsearchable then return end
    
    if ply:GetInArena() && self.ply then ply:Tip(3, "You cannot kill a respawning player either!", Color(255,0,0)) return end

    if self:GetPos():Distance(ply:GetPos()) > 200 then return end

    if self:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end
    
    ply:DoModelProcess(self:GetModel(), "Breaking "..self.ply:Nick().."'s Neck", 3, "", 0, "physics/flesh/flesh_bloody_break.wav", true, function()
        if !IsValid(ply) then return end
        if !IsValid(self) then return end
        if !IsValid(self.ply) then return end
        if self.ply:Alive() then return end 

        if self.ply:GetRealHealth() < 1 then return end 

        self.ply:SetRealHealth( 0 )

        ply:XPAward(20, "Neck Breaker")
    end)
end)

net.Receive("sb_DoPickup", function(len, ply)
    local ent_id = net.ReadUInt(32)
    local self = Entity( ent_id )

    if !IsValid(self) then return end

    if !ply:CanPerformAction() then return end

    if self:GetClass() != "modulus_skateboard" then return end
    
    if self:GetPos():Distance(ply:GetPos()) > 200 then return end

    if self:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end
    
    ply:DoModelProcess(self:GetModel(), "Collecting Skateboard", 5, "items/ammocrate_open.wav", 0, "items/medshot4.wav", true, function()
        if !IsValid(ply) then return end
        if !IsValid(self) then return end

        ply:GiveItem("item_skateboard", 1)

        self:Remove()

    end)
end)

net.Receive("ragdoll_DoRevive", function(len, ply)
    local ent_id = net.ReadUInt(32)
    local self = Entity( ent_id )

    if !IsValid(self) then return end
    if !IsValid(self.ply) then return end

    if !ply:CanPerformAction() then return end

    if !ply:HasItem("item_medic2", true) then return end

    if self:GetClass() != "prop_ragdoll" and self:GetClass() != "grave" then return end

    if !self.dzsearchable then return end
    
    if ply:GetInArena() && self.ply then ply:Tip(3, "You cannot revive a respawning player either!", Color(255,0,0)) return end

    if self:GetPos():Distance(ply:GetPos()) > 200 then return end

    if self:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end
    
    ply:DoModelProcess(self:GetModel(), "Reviving "..self.ply:Nick(), 5, "items/ammocrate_open.wav", 0, "items/medshot4.wav", true, function()
        if !IsValid(ply) then return end
        if !IsValid(self) then return end
        if !IsValid(self.ply) then return end
        if self.ply:Alive() then return end 

        if self.ply:GetRealHealth() < 1 then return end

        print("[PHDayZ] "..ply:Nick().." saved "..self.ply:Nick().."!")

        self.ply.BleedOutWin = true

        --self.ply:SetHealth(20) -- 1ltr

        self.ply:SetRealHealth( self.ply:GetRealHealth() + 20 )

        self.ply:Tip(3, ply:Nick().." saved you!", Color(0,255,0,255))

        ply:TakeItem("item_medic2", 1, true)

        ply:XPAward(20, "Life Saver")

    end)
end)

net.Receive("ragdoll_DoLoot", function(len, ply)
    local ent_id = net.ReadUInt(32)
    local self = Entity( ent_id )

    if !IsValid(self) then return end

    if !ply:CanPerformAction() then return end

    if ply:GetInArena() && self.ply then ply:Tip(3, "You cannot loot a respawning player!", Color(255,0,0)) return end

    if !self.dzsearchable then return end

    if self:GetPos():Distance(ply:GetPos()) > 200 then return end

    print(ply:Nick().." searched "..self:GetStoredName())

    if self:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end

    local anyItems = 0
    self.ItemTable = self.ItemTable or {}
    self.CharTable = self.CharTable or {}

    for k, items in pairs(self.ItemTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
        end
    end

    for k, items in pairs(self.CharTable) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            anyItems = anyItems + 1
        end
    end

    if anyItems < 1 then
        ply:ChatPrint("There be nothing to take here.")
        ply.LootingBackpack = nil
        if self:GetClass() == "prop_ragdoll" then
            --self:SetModel("models/player/skeleton.mdl")
        end
        return false
    end
    
    ply:DoModelProcess(self:GetModel(), "Searching "..self:GetStoredName(), 2, "npc/combine_soldier/gear"..math.random(1,6)..".wav", 0, "", true, function(ply)
        if !IsValid(ply) or !ply:Alive() then return end
        if !IsValid(self) then return end

        SendBackpack( self, ply )
    end)
end)

function DoControlZombie(ply, c, a)
print("dz_becomezombie | executed")
    if !PHDayZ.VJBaseSupport then return end
    if ( ply.zBecome or 0 ) > CurTime() then return end

    if !ply.Dead then return end
    ply.zBecome = CurTime() + 1
    
    local class = nil
    if a && a[1] && ply:IsSuperAdmin() then class = a[1] end

    local ent = SpawnAZombie(nil, true, nil, class, true)
  
    if !IsValid(ent) then return end

    if !ent:IsNPC() then
        return
    elseif ent:IsNPC() && ent:Health() <= 0 then
        return
    elseif ent.VJ_IsBeingControlled == true then
        return
    end

    if (!ent.IsVJBaseSNPC) then
        return
    end

    ply:EmitSound("vj_illuminati/illuminati confirmed.mp3")

    ply.StartedControlling = CurTime() + 2

    if !ply:Alive() then ply:Spawn() end
    ply.forceMenu = true

    print("[PHDayZ] "..ply:Nick().." became an npc: "..( ply.DeathMsg or "unknown" ))

    timer.Simple(0.1, function()
        if !IsValid(ply) then return end

        ply:SetSafeZone(false)
        ply:SetSafeZoneEdge(false)
        ply:SetInRadZone(false)

--[[         ply.SpawnControllerObject = ents.Create("ob_vj_npccontroller")
        ply.SpawnControllerObject.TheController = ply
        ply.SpawnControllerObject:SetControlledNPC(ent) ]]
		
		local SpawnControllerObject = ents.Create("obj_vj_npccontroller")
		SpawnControllerObject.TheController = ply
		SpawnControllerObject:SetControlledNPC(ent)
		SpawnControllerObject:Spawn()
		//SpawnControllerObject:Activate()
		SpawnControllerObject:StartControlling()

        SpawnControllerObject.StopControlling = function(self)
            if IsValid(ply) and ( ply.AllowRespawn or 0 ) > CurTime() then return end -- stop them if they can't respawn yet.

            //if !IsValid(SpawnControllerObject.TheController) then return self:Remove() end
            self:CustomOnStopControlling()

            if IsValid(SpawnControllerObject.TheController) then
                if SpawnControllerObject.TheController.forceMenu then
                    SpawnControllerObject.TheController.forceMenu = nil
                    SpawnControllerObject.TheController:ConCommand("dz_menu")
                end

                SpawnControllerObject.TheController.IsControlingNPC = false

            end
            SpawnControllerObject.TheController = NULL

            if IsValid(self.ControlledNPC) then
                //self.ControlledNPC:StopMoving()
                self.ControlledNPC.VJ_IsBeingControlled = false
                self.ControlledNPC.VJ_TheController = NULL
                self.ControlledNPC.VJ_TheControllerEntity = NULL
                //self.ControlledNPC:ClearSchedule()
                if self.ControlledNPC.IsVJBaseSNPC == true then
                    self.ControlledNPC.DisableWandering = self.VJNPC_DisableWandering
                    self.ControlledNPC.DisableChasingEnemy = self.VJNPC_DisableChasingEnemy
                    //self.ControlledNPC.DisableFindEnemy = self.VJNPC_DisableFindEnemy
                    self.ControlledNPC.DisableTakeDamageFindEnemy = self.VJNPC_DisableTakeDamageFindEnemy
                    self.ControlledNPC.DisableTouchFindEnemy = self.VJNPC_DisableTouchFindEnemy
                    self.ControlledNPC.DisableSelectSchedule = self.VJNPC_DisableSelectSchedule
                    self.ControlledNPC.HasMeleeAttack = self.VJNPC_HasMeleeAttack
                    self.ControlledNPC.HasRangeAttack = self.VJNPC_HasRangeAttack
                    self.ControlledNPC.HasLeapAttack = self.VJNPC_HasLeapAttack
                    self.ControlledNPC.CallForHelp = self.VJNPC_CallForHelp
                    self.ControlledNPC.CallForBackUpOnDamage = self.VJNPC_CallForBackUpOnDamage
                    self.ControlledNPC.FollowPlayer = self.VJNPC_FollowPlayer
                    self.ControlledNPC.BringFriendsOnDeath = self.VJNPC_BringFriendsOnDeath
                    self.ControlledNPC.CanDetectGrenades = self.VJNPC_RunsAwayFromGrenades
                    self.ControlledNPC.RunOnTouch = self.VJNPC_RunOnTouch
                    self.ControlledNPC.RunOnHit = self.VJNPC_RunOnHit
                    if self.ControlledNPC.IsVJBaseSNPC_Human == true then
                        if self.ControlledNPC.DisableWeapons == false then
                            self.ControlledNPC:CapabilitiesAdd(bit.bor(CAP_MOVE_SHOOT))
                            self.ControlledNPC:CapabilitiesAdd(bit.bor(CAP_AIM_GUN))
                        end
                    end
                end
            end
            //self.PropCamera:Remove()
            self.VJControllerEntityIsRemoved = true
            self:Remove()
        end
        
        SpawnControllerObject:Spawn()

        SpawnControllerObject:StartControlling()


    end)
end
concommand.Add("dz_becomezombie", DoControlZombie)


function CreateBackpack(ply, dmginfo)
    if ply:IsBot() then return end 

    local grave_ent = "grave"
    if PHDayZ.RagdollDeaths then
        grave_ent = "prop_ragdoll"
    end

    local grave = ents.Create( grave_ent )
    grave.dzsearchable = true
    grave.ply = ply
    grave:SetModel( ply:GetModel() )
    grave:SetStoredModel( ply.oPModel or ply:GetModel() )
    grave:SetStoredName(ply:Nick().."'s Body")
    grave:SetStoredReason(ply.DeathMsg)
    if PHDayZ.RagdollDeaths then
        grave:SetPos( ply:GetPos() )
    else
       grave:SetPos( ply:GetPos() + Vector(0,0,20) )
    end
    grave:SetAngles( ply:GetAngles() )
    grave.canDamage = CurTime() + 1.5
    grave:Spawn()

    if grave:GetClass() == "prop_ragdoll" then

        -- position the bones
        local num = grave:GetPhysicsObjectCount()-1
        local v = ply:GetVelocity()

        -- bullets have a lot of force, which feels better when shooting props,
        -- but makes bodies fly, so dampen that here
        if dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_SLASH) then
            v = v / 2
        end

        if dmginfo:IsExplosionDamage() then
            v = v * 2
        end


        for i=0, num do
            local bone = grave:GetPhysicsObjectNum(i)
            if IsValid(bone) then
                local bp, ba = ply:GetBonePosition(grave:TranslatePhysBoneToBone(i))
                if bp and ba then
                    bone:SetPos(bp)
                    bone:SetAngles(ba)
                end

                -- not sure if this will work:
                bone:SetVelocity(v)
            end
        end
    end

    grave:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
    grave:Fire("FadeAndRemove", "", (PHDayZ.GravePerishTime or 600))
    grave:SetPerish( CurTime() + (PHDayZ.GravePerishTime or 600) )

    AddPlayerInvItems(ply, grave)

    if IsValid(ply.backpack) then
        UpdateBackPack(grave, ply.backpack.class)
        ply.backpack:Remove()
    end
    if IsValid(ply.hat) then
        UpdateHat(grave, ply.hat.class)
        ply.hat:Remove()
    end
    
    if grave:GetClass() == "prop_ragdoll" then
        UpdateBackweps(grave)
    end

    save_player(ply)

    if isfunction(Adv_Compass_AddMarker) then -- mCompass support

        local tab = { ply }

        if mCompass_Settings && table.Count(grave.ItemTable) > 0 then
            grave.MarkerID = Adv_Compass_AddMarker(true, grave, CurTime() + 20, Color(255,0,0,255), tab )
        end

        timer.Create(grave:EntIndex().."_ping_owner", 15, 0, function()
            if !IsValid(grave) or !IsValid(ply) then timer.Destroy(grave:EntIndex().."_ping_owner") return end

            if mCompass_Settings then
                if table.Count(grave.ItemTable) < 1 then return end -- there is no point continuing broadcasting an empty body.
                    
                if grave.MarkerID then
                    Adv_Compass_RemoveMarker(grave.MarkerID)
                end

                grave.MarkerID = Adv_Compass_AddMarker(true, grave, CurTime() + 20, Color(255,0,0,255), tab, "cyb_mat/cyb_backpack.png", "Died" )
            end
        end)

    end
    
    return grave
end

function RestorePlayerInvItems(backpack, ply)
    if ply:GetInArena() then ply:UpdateChar(nil, nil, nil, true) return end -- does not restore, because does not save!

    --table.Merge( ply.InvTable, backpack.ItemTable )
    --table.Merge( ply.CharTable, backpack.CharTable )


    if table.Count(backpack.ItemTable) > 0 then
        local Delete = {}

        for k, items in pairs(backpack.ItemTable) do

            for _, it in pairs(items) do
                if it.amount < 1 then continue end

                if GAMEMODE.DayZ_Items[k].DontDeleteOnDeath then continue end

                --function PMETA:GiveItem( item, amount, ignoreweight, quality, rarity, noauto, addslot, notify, autoequip, bank )

                ply:GiveItem( k, it.amount, true, it.quality, it.rarity, true, nil, nil, false, nil, it )
            end
    
        end
    
    end
    --ply:UpdateItem()

    if table.Count(backpack.CharTable) > 0 then
        for k, items in pairs(backpack.CharTable) do

            for _, it in pairs(items) do
                if it.amount < 1 then continue end

                if GAMEMODE.DayZ_Items[k].DontDeleteOnDeath then continue end

                ply:GiveItem( k, it.amount, true, it.quality, it.rarity, true, false, nil, true, nil, it )
            end
            
        end
    end
    --ply:UpdateChar()


end

function AddPlayerInvItems(ply, backpack)

    backpack.ItemTable = {}
    backpack.CharTable = {}

    if ply:GetInArena() then return end -- does not save, because does not restore!

    if !ply.CharTable then return end -- this will be basically bots only.
    if !ply.InvTable then return end -- this will be basically bots only.

    if table.Count(ply.CharTable) > 0 then
        local Delete = {}

        for k, items in pairs(ply.CharTable) do

            for _, v in pairs(items) do
                if v.amount < 1 then continue end

                if GAMEMODE.DayZ_Items[k].DontDeleteOnDeath then continue end

                if GAMEMODE.DayZ_Items[k].DontDropOnDeath then
                    if GAMEMODE.DayZ_Items[k].DEquipFunc then
                        GAMEMODE.DayZ_Items[k].DEquipFunc(ply, v.id, k)
                    end

                    Delete[v.id] = true
                    ply.CharTable[k][v.id] = nil
                    continue
                end

                -- Don't drop the item on death, but still Delete it.
                if GAMEMODE.DayZ_Items[k].DEquipFunc then
                    GAMEMODE.DayZ_Items[k].DEquipFunc(ply, v.id, k)
                end

                backpack.CharTable[k] = backpack.CharTable[k] or {}
                backpack.CharTable[k][v.id] = v
                ply.CharTable[k][v.id] = nil
                Delete[v.id] = true
            end

        end

        if table.Count(Delete) > 0 then
            PLib:QuickQuery("DELETE FROM `players_character` WHERE `id` IN ( \"" .. table.concat(table.GetKeys(Delete), "\", \"") .. "\" );")
        else
            PLib:QuickQuery("DELETE FROM `players_character` WHERE `user_id` = " .. ply.ID .. ";")
            ply.CharTable = {}
        end

        Delete = nil
        ply:UpdateChar()
    end

    if table.Count(ply.InvTable) > 0 then
        local Delete = {}

        for k, items in pairs(ply.InvTable) do

            for _, v in pairs(items) do
                if v.amount < 1 then continue end

                if GAMEMODE.DayZ_Items[k].DontDeleteOnDeath then continue end

                -- Don't delete the item on death.
                if GAMEMODE.DayZ_Items[k].DontDropOnDeath then
                    Delete[v.id] = true
                    ply.InvTable[k][v.id] = nil
                    continue
                end

                -- Don't drop the item on death, but still Delete it.
                if k == "item_credits" then continue end

                -- Credits do not drop on death.
                if ply:HasPerk("perk_deadmansluck") then
                    -- has the player got the dead man's luck perk
                    if math.random(0, 100) <= 90 then
                        -- 10% chance
                        if v.amount > 0 then
                            backpack.ItemTable[k] = backpack.ItemTable[k] or {}
                            backpack.ItemTable[k][v.id] = v
                        end
                        ply.InvTable[k][v.id] = nil
                        Delete[v.id] = true
                    end
                else
                    break
                end
            end
        end

        if table.Count(Delete) > 0 then
            PLib:QuickQuery("DELETE FROM `players_inventory` WHERE `id` IN ( \"" .. table.concat(table.GetKeys(Delete), "\", \"") .. "\" );")
        else
            PLib:QuickQuery("DELETE FROM `players_inventory` WHERE `user_id` = " .. ply.ID .. " AND `item` != \"item_credits\";")
            backpack.ItemTable = ply.InvTable
            ply.InvTable = {}
            ply.InvTable["item_credits"] = (backpack.ItemTable["item_credits"] and backpack.ItemTable["item_credits"]) or nil
            backpack.ItemTable["item_credits"] = nil
        end

        Delete = nil
        ply:UpdateItem()
    end
end


hook.Add("OnNPCKilled", "XPItemsAward", function(npc, attacker, inflictor)

    if IsValid(attacker) and attacker:IsNPC() then -- npcs killing npcs.
        attacker.Frags = ( attacker.Frags or 0 ) + 1

        if !isfunction(attacker.GetLevel) then return end

        if isfunction(attacker.CheckLevel) then attacker:CheckLevel() end

        local hp = math.Clamp( attacker:Health() + ( attacker:GetMaxHealth() / 10 ), 0, attacker:GetMaxHealth() )
        attacker:SetHealth( hp )
        attacker:EmitSound( "items/medshot4.wav", 55, 100 )

    end

    if IsValid(attacker) and ( attacker:IsPlayer() or attacker:IsVehicle() ) then
        
        local zclass = string.gsub(npc:GetClass(), "%d+" ,"*")

        --if npc.IsZombie or ( PHDayZ.ZombieTypes[zclass] ) then
    
            local chance = 1
            --if npc.rarity < 10 then
            local rarity = npc.rarity or PHDayZ.ZombieTypes[zclass] or 5
            if rarity <= 20 then
                chance = 2
            end
            if rarity <= 5 then
                chance = 3
            end
            if rarity < 3 then
                chance = 4
            end
            if rarity < 2 then
                chance = 5
            end

            if chance < 0 then chance = 1 end

            --end
            local xp = PHDayZ.Player_XPAwardOnZombieKill or 5
            local noitem = false
            if attacker:IsVehicle() then
                xp = xp / 2
                noitem = true
                if attacker.Seats then
                    
                    for k, seat in pairs(attacker.Seats) do
                        if !IsValid(seat) then continue end

                        local driver = seat:GetDriver()
                        if !IsValid(driver) then continue end
                        if driver == attacker:GetDriver() then continue end -- in case of mischief.

                        if driver:IsPlayer() then
                            local amt = xp * chance * npc:GetLevel()
                            if amt > 250 then amt = 250 end -- HARDCODE.

                            driver:XPAward( amt, "NPC Kill" )
                        end

                    end
                end

                if math.random(1, 5) > 3 then
                    attacker:TakeDamage(1, npc, attacker)
                end
                attacker = attacker:GetDriver()

            end

            if attacker:IsPlayer() and attacker:GetInArena() then 
                noitem = true
            end

            if !IsValid(attacker) then return end

            if attacker:IsPlayer() and !attacker:GetInArena() then 

                local amt = xp * chance * npc:GetLevel()
                if amt > 250 then amt = 250 end -- HARDCODE.

                attacker:XPAward(amt, "NPC Kill")
            end

            if !noitem then
                --DropMoney(npc, 20 * chance, 50 * chance * ( npc:GetLevel() / 2 ), ( PHDayZ.ZombieMoneyChance or 20 ) * chance * npc:GetLevel(), attacker )
                if VJAnimals[ npc:GetClass() ] then
                    DropMeat(npc, 1, 2 * npc:GetLevel(), ( PHDayZ.ZombieMeatChance or 15 ) * chance * npc:GetLevel(), attacker )
                end

                DropItem(npc, 1, 1 * chance, ( PHDayZ.ZombieItemChance or 5 ) + chance * npc:GetLevel(), attacker )

                if VJInsurgents[ npc:GetClass() ] then 
                    DropMoney(npc, 20 * chance, 50 * chance * ( npc:GetLevel() / 2 ), ( PHDayZ.ZombieMoneyChance or 20 ) * chance * npc:GetLevel(), attacker )

                    local amt = math.floor( npc:GetLevel() / 2 )
                    for i = 1, ( 1 + amt ) do
                        DropItem(npc, 1, 1, 100, attacker, true )
                    end
                end
            end

            ZombieTbl[npc] = nil

            for k, v in pairs(ZombieTbl) do
                if not IsValid(k) then
                    ZombieTbl[k] = nil
                end
            end
        --end
    end

end)

function CreateCorpse(ent, dmginfo)
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetModel(ent.deathmodel or ent:GetModel())
    ragdoll:SetPos(ent:GetPos())
    ragdoll:SetAngles(ent:GetAngles())
    ragdoll:Spawn()

    ragdoll:SetModelScale( ent:GetModelScale(), 1)

    ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)
    ragdoll:SetSkin(ent:GetSkin())

    ragdoll:SetBodyGroups( ent:GetBodyGroups() )

    local col = ent:GetColor()

    if col.a < 1 then
        col.a = 255
    end

    ragdoll:SetRenderMode(1)
    ragdoll:SetColor(Color(col.r, col.g, col.b, col.a))
    ragdoll:SetMaterial(ent:GetMaterial())

    if ent:IsNPC() or ent.IsZombie then
        ent.nick = "Zombie"

        if ent.modelscale then
            ragdoll:SetModelScale(ent.modelscale, 0)
        end

        ragdoll:Fire("FadeAndRemove", "", 5)

        for bone = 0, ragdoll:GetPhysicsObjectCount() do
            local phys = ragdoll:GetPhysicsObjectNum(bone)
            local plybone = ragdoll:TranslatePhysBoneToBone(bone)
            local bonepos, boneang = ent:GetBonePosition(plybone)

            if IsValid(phys) and IsValid(ent) then
                phys:SetPos(bonepos)
                phys:SetAngles(boneang)
            end

            if IsValid(phys) then
                phys:AddVelocity(ent:GetVelocity())
            end
        end

        if ent:IsOnFire() then
            ragdoll:Ignite(math.random(8, 10), 15)
        end

        ent:Remove()

        local xp = PHDayZ.Player_XPAwardOnZombieKill or 5

        if dmginfo then

            local attacker = dmginfo:GetAttacker()
            if attacker:IsPlayer() then
                if ent.IsZombie then
                    if ent.OPZombie then
                        xp = xp * 3
                    elseif ent.MiniZombie then
                        xp = xp / 2
                    end

                    attacker:XPAward(xp, "howthefuckdidyougetthis")
                    --MsgAll("CreateCorpse")
                    --DropMoney(ent, 20, 50, PHDayZ.ZombieMoneyChance or 20, attacker)
                    DropMeat(ent, 1, 2, PHDayZ.ZombieMeatChance or 15, attacker)
                    DropItem(ent, 1, 1, PHDayZ.ZombieItemChance or 5, attacker)
                end
            end

        end

        ZombieTbl[ent] = nil

        for k, v in pairs(ZombieTbl) do
            if not IsValid(k) then
                ZombieTbl[k] = nil
            end
        end

        return ragdoll
    end

    return nil
end

-- Dickheads.
function GM:CanPlayerSuicide( ply )
    if ply.Dead or !ply.Ready or ply.Loading then return false end -- Yeah, no suiciding while dead.
    if ply:GetSafeZone() or ply:GetSafeZoneEdge() or ply:GetInArena() then return false end -- No suiciding in safezone plebs.
    return true
end

-- Because for some reason this hook doesn't always fucking call.
function GM:DoPlayerDeath(ply, attacker, dmginfo)
    ply.Dead = true

    --ply:CreateRagdoll()
    ply:AddDeaths(1)
    ply:SetPVPTime(0)
    ply:SetRadiation(0)

    ply:EmptyClip(nil, nil, true)

    local dtime = PHDayZ.Player_DeathTime

    if ply:IsVIP() then
        dtime = PHDayZ.Player_VIPDeathTime
    end

    if PHDayZ.Player_DeathBlackScreen then
        ply:ScreenFade(SCREENFADE.OUT, color_black, dtime / 3, 600)
    end
    ply.AllowRespawn = CurTime() + dtime

    -- Either i'm being autistic, or this function pissed me off so i was lazy.
    if !ply.DeathMsg then
        ply.DeathMsg = "Killed by a Magical force"
        if ply:IsOnFire() then
            ply.DeathMsg = "Burned to death"
        elseif attacker:IsPlayer() then
            if attacker == ply then
                if ( ply:Health() < 1 and ply:GetBleed() ) or ply.BloodDeath then
                    ply.DeathMsg = "Died from blood loss"
                    ply.BloodDeath = nil
                elseif ply:GetRealHealth() < 1 && ply:GetRadiation() >= 25 then
                    ply.DeathMsg = "Died from radiation"
                elseif ply:GetRealHealth() < 1 or ply.SicknessDeath then
                    ply.DeathMsg = "Died from sickness"
                    ply.SicknessDeath = nil
                elseif ply:GetHunger() < 1 then
                    ply.DeathMsg = "Died from starvation"
                elseif ply:GetThirst() < 1 then
                    ply.DeathMsg = "Died from dehydration"
                elseif ply.Drowning and ply.Drowning > 20 then
                    ply.DeathMsg = "Drowned"
                else
                    ply.DeathMsg = "Suicide"
                end
            else
                local w = dmginfo:GetInflictor()

                local name = "magic"
                if IsValid(w) then
                    --local wep = weapons.GetStored( w:GetClass() )
                    name = w:GetClass()
                    local item = dmginfo:GetInflictor().item

                    if item == "item_basebat" && DZ_Quests then
                        attacker:DoQuestProgress("quest_mobhit", 1)
                    end
                    
                    if item then name = GAMEMODE.DayZ_Items[item].Name end
                end
                ply.DeathMsg = "Killed by "..name

                print("[PHDayZ] "..attacker:Nick().." killed "..ply:Nick().." with "..name)
                --ply.DeathMsg = "Killed by " .. attacker:Nick()
            end
        elseif attacker:IsNPC() then

            local class = attacker:GetClass()
            local name = class
            if attacker.PrintName then
                name = string.gsub(attacker.PrintName, "%d", "")
            end

            ply.DeathMsg = "Killed by a/n "..name
        elseif attacker.ZombPunched then
            ply.DeathMsg = "Zombies can throw things too"
        elseif attacker:GetClass() == "prop_physics" then
            ply.DeathMsg = "Squashed by an Object"
        elseif attacker:GetClass() == "base_item" then
            ply.DeathMsg = "Killed by a/n "..GAMEMODE.DayZ_Items[attacker:GetItem()].Name
        elseif attacker:IsWorld() then
            ply.DeathMsg = "Died from Falling"
            ply.nextCanBleedOut = CurTime() + 30 -- fucking die you map exploiting turds. no bleedout for you.
        elseif attacker:IsVehicle() && dmginfo:IsExplosionDamage() then
            ply.DeathMsg = "Blown up by a Vehicle"
        elseif dmginfo:IsExplosionDamage() then
            ply.DeathMsg = "Killed by an Explosion"
        elseif attacker:IsVehicle() then
            ply.DeathMsg = "Squashed by a Vehicle"
        end
    end

    if ply._disd then 
        ply.DeathMsg = "Disconnected: "..ply.DeathMsg
    end

    ply.LastDeathMsg = ply.DeathMsg -- for your history :)

    net.Start("AliveChar")
        net.WriteBool(!ply.Dead)
        net.WriteString(ply.LastDeathMsg)
    net.Send(ply)

    ply.dddmg = dmginfo

    net.Start("net_DeathMessage")
        if ply.DeathMsg ~= "" then
            net.WriteString(ply.DeathMsg)
        end
    net.Send(ply)

    DzLog(4, "Player '" .. ply:Nick() .. "' (" .. ply:SteamID() .. "): " .. ply.DeathMsg)

    if ( ply.nextCanBleedOut or 0 ) < CurTime() then
        print("[PHDayZ] "..ply:Nick().." started bleeding out ("..math.ceil( ply:GetRealHealth()/2 ).."s): "..ply.DeathMsg)
    end

    local grave = CreateBackpack(ply, dmginfo)
    ply.grave = grave
    ply.g_attacker = attacker

    ply:Spectate( OBS_MODE_CHASE )
    ply:SpectateEntity( grave )
end

local function BountyBroadcast(ply)
    --local tm = ply:Team()

    if !isfunction(Adv_Compass_AddMarker) then 
        hook.Remove("PlayerTick", "BroadcastBounties")
        hook.Remove("VehicleMove", "BroadcastBounties")

        return 
    end
    
    if ( ply.nextBountyUpdate or 0 ) > CurTime() then return end

    if ply.Loading or !ply.Ready or ply.Dead then return end

    if ply:Frags() < PHDayZ.Player_BountyKillsReq or ( ply:GetSafeZone() or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetInArena() ) then return end
    ply.nextBountyUpdate = CurTime() + 60

    local color = Color(255, 0, 0, 255)

    local pos = ply:GetPos()
    if ply:InVehicle() then -- quick hack
        pos = ply:GetVehicle():GetPos()
    end
    local m_id = Adv_Compass_AddMarker(false, pos, CurTime() + 60, color, nil, "cyb_mat/skill_4.png", ply:Nick() )

    local amt = (ply:Frags() * 2)
    TipAll(3, "Bounty Position updated for " .. ply:Nick() .. "! Kill worth ¢"..amt.."! Check your compass!", Color(255, 0, 0))

    --MsgAll( "Broadcasted bounty "..ply:Nick() )
end
hook.Add("PlayerTick", "BroadcastBounties", BountyBroadcast)
hook.Add( "VehicleMove", "BroadcastBounties", BountyBroadcast)

hook.Add("PlayerDisconnected", "tagfuck", function(ply)
    if not IsValid(ply) then return end
    local grave = ply.grave

    if ply:Alive() then 
        ply:EmptyClip(nil, nil, true)

        if ( ply:GetPVPTime() > CurTime() or ply:IsOnFire() ) && !ply:GetInArena() then
            ply._disd = true
            ply.DeathMsg = "Combat logged"
            ply:Kill()
        else
            checkDeath(ply, nil, true)
        end
    end

    if IsValid(grave) then
        checkDeath(ply, nil, true)
    end

end)

function checkDeath(ply, attacker, discon)

    --if discon then
    --MsgAll(ply:Nick().. " was graverobbed")

    local grave = ply.grave

    if !discon && IsValid(ply.g_attacker) then
        attacker = ply.g_attacker
    end

    if !discon && PHDayZ.Player_LooseXPDeath then  
        local xptolose = ( ply:GetXP() / 100 ) * PHDayZ.Player_XPLossPercentage
        if PHDayZ.Player_XPLossCap > 0 && xptolose > PHDayZ.Player_XPLossCap then
            xptolose = PHDayZ.Player_XPLossCap
        end
        if !ply:IsVIP() then
            ply:SetXP( ply:GetXP() - xptolose )
        end
    end

    if !discon && isfunction(LoseSkills) then LoseSkills(ply) end

    if IsValid(grave) then
        
        local e_id = grave:EntIndex()
        timer.Destroy(e_id.."_bleed")

        if IsValid(grave.bleed) then
            grave.bleed:Remove()
        end

        grave:SetStoredName(ply:Nick().."'s Body")
        grave.ply = nil
    end

    if IsValid(attacker) && attacker:IsPlayer() && attacker != ply then

        if ply:Frags() >= PHDayZ.Player_BountyKillsReq then
            -- bounty!
            attacker:GiveCredits( ply:Frags() * 2 )
            TipAll(3, "The bounty on " .. ply:Nick() .. " was claimed!", Color(0, 255, 0))

            if attacker:Frags() < PHDayZ.Player_BanditKillsReq then
                attacker:SetNWBool("isHero", true)
            end
        else
            if attacker:Frags() == PHDayZ.Player_BountyKillsReq then
                TipAll(3, "A bounty has been placed on " .. attacker:Nick() .. "!", Color(255, 0, 0))
            end
        end

        if attacker:GetMoveType() != MOVETYPE_NOCLIP then 

            attacker:AddFrags(1)
            attacker:AddPFrags(1) -- permafrag

        end

        ply:SetFrags(0) -- Player reset kill count only.

    end

end

graves = graves or {}
function GM:PlayerDeath(ply, infl, attacker)
    if attacker:IsVehicle() and attacker:GetDriver() then
        attacker = attacker:GetDriver()
    end

    --ply:SetModel(ply.oPModel or "models/player/group01/male_01.mdl")
    -- Removing Ghillisuit.
    --ply:SetFrags(0)
    ply:SetProcessItem("") -- incase they were doing something when they died.

    ply:SetNWBool("isHero", false)

    local grave = ply.grave

    local hp = ply:GetRealHealth()
    if ply:GetInArena() or ( hp > 25 && ( ply.nextCanBleedOut or 0 ) < CurTime() ) then   

        if IsValid(grave) then
            local e_id = grave:EntIndex()
            timer.Create(e_id.."_bleed", 1, 0, function()
                if !IsValid(grave) then timer.Destroy(e_id.."_bleed") return end
                if !IsValid(grave.ply) then timer.Destroy(e_id.."_bleed") return end


                if IsValid(grave.bleed) then grave.bleed:Remove() end

                grave.bleed = ents.Create("info_particle_system")
                grave.bleed:SetKeyValue("effect_name", "blood_impact_red_01")
                grave.bleed:SetPos( grave:GetPos() ) 
                grave.bleed:Spawn()
                grave.bleed:Activate() 
                grave.bleed:Fire("Start", "", 0)
                grave.bleed:Fire("Kill", "", 0.2)

            end)
        end

        if !ply:GetInArena() then
            ply:SetRealHealth( hp / 2 )
        end

        ply.bleedOut = 0
    else
        ply.nextCanBleedOut = 0

        checkDeath(ply, attacker)

        if !IsValid(ply.grave) then return end
        -- just die
        ply.grave.ply = nil 
        ply.grave = nil
    end
    --net.Start("StartBleedOut")
    --net.Send(ply)

    ply.dddmg = nil

    local sounds = {"vo/npc/male01/no01.wav", "vo/npc/Barney/ba_no01.wav", "vo/npc/Barney/ba_no02.wav", "vo/npc/male01/no02.wav", "vo/coast/bugbait/sandy_help.wav", "vo/Streetwar/sniper/male01/c17_09_help02.wav", "vo/npc/male01/help01.wav"}

    ply:EmitSound( table.Random(sounds), 500, 100, 1 )

end

function GM:PlayerDeathThink(ply)
    if IsValid(ply) then

        if IsValid(ply.grave) then
            ply:SetPos( ply.grave:GetPos() )    
        end

        local hp = ply:GetRealHealth()
        if hp > 0 && ( ply.nextBleedOut or 0 ) < CurTime() && IsValid(ply.grave) then
            if ply:GetBleedingOut() == false then
                ply:SetBleedingOut(true)
            end

            ply.bleedOut = ( ply.bleedOut or 0 ) + 1

            if !ply:GetInArena() then
                ply:SetRealHealth( hp - 1 )
                ply:SetHealth(ply.bleedOut/2)
            end

            ply:SetHealth(0)

            ply.rN = math.random(0, 100)
            ply.nextBleedOut = CurTime() + 1

            if IsValid(ply.grave) then
                ply.grave:SetStoredName(ply:Nick().." - Bleeding out in "..hp.."s!")
            end
        end

        if ( ply:GetRealHealth() < 1 or !IsValid(ply.grave) ) && ply:GetBleedingOut() then
            ply:SetBleedingOut(false) -- YOU DIED.

            ply:EmitSound("stranded/need_thirst1.wav")
            ply:SetHealth(0)
            
            checkDeath(ply)

            if IsValid(ply.grave) then
                ply.grave.ply = nil
                ply.grave = nil
            end
            print("[PHDayZ] "..ply:Nick().." bled out: "..( ply.DeathMsg or "unknown" ) ) 

        end

        if ( ( ply.bleedOut or 0 ) > 5 and ply:GetInArena() ) or ( ( ply.bleedOut or 0 ) > 24 && ( ply.rN or 0 ) > 90 ) then
            ply.BleedOutWin = true
        end

        if ply.BleedOutWin then 

            local grave = ply.grave
            if IsValid(grave) then

                local pos = grave:GetPos()

                ply:Spawn()

                ply:UnSpectate()

                ply:SetPos(pos)

                RestorePlayerInvItems(grave, ply)

                grave:Remove()

                ply:SetDeaths( ply:Deaths() - 1 ) -- they survived

                ply:SetBleedingOut(false)

                if ply:GetRealHealth() < 5 then
                    ply:SetRealHealth(5)
                end

                if ply:GetInArena() && ply.arenaEnterHP then
                    ply:SetHealth( ply.arenaEnterHP )
                else
                    ply:SetHealth(20) -- 1ltr
                end

                grave.ply = nil
            
                ply.bleedOut = 0
                ply.rN = nil

                ply:EmitSound("ambient/voices/citizen_beaten"..math.random(1,5)..".wav", 75, 100, 0.5)

                ply.Dead = false -- for system checks

                if !ply:GetInArena() then
                    ply.nextCanBleedOut = CurTime() + 300 -- 5 minutes til they can bleed out again, unless they die.
                end

                net.Start("AliveChar")
                    net.WriteBool(!ply.Dead)
                    net.WriteString(ply.LastDeathMsg)
                net.Send(ply)
                
                print("[PHDayZ] "..ply:Nick().." recovered from bleed out!")
                return
            end
            
        end

        if !ply:GetBleedingOut() && ply:KeyDown(IN_ATTACK2) && !ply.IsControlingNPC then
            checkDeath(ply)

            if IsValid(ply.grave) then
                ply.grave.ply = nil
                ply.grave = nil
            end
            DoControlZombie(ply)
            return
        end

        if ( ply.AllowRespawn or 0 ) < CurTime() then
            if ply:KeyDown(IN_ATTACK) then

                checkDeath(ply)   

                print("[PHDayZ] "..ply:Nick().." died: "..( ply.DeathMsg or "unknown" ))

                if IsValid(ply.grave) then
                    ply.grave.ply = nil
                    ply.grave = nil
                end
                ply:Spawn()
            end
        end
    end
end

local DoIgnite = {}
--DoIgnite["player"] = true
DoIgnite["base_item"] = true
DoIgnite["backpack"] = true
DoIgnite["prop_physics"] = true
DoIgnite["prop_ragdoll"] = true
DoIgnite["npc_nb_common"] = true
DoIgnite["prop_physics_multiplayer"] = true
local vec = Vector(50, 50, 100)

function FireSpread(ent)
    if not ent:IsOnFire() then return end

    if (ent.firecount or 0) >= 3 and not ent:IsOnFire() then
        ent.firecount = ent.firecount - 1

        return
    end

    if PHDayZ.DebugMode then
        MsgAll("Running FireSpread on " .. ent:GetClass())
    end

    local en = ents.FindInBox(ent:GetPos() + vec, ent:GetPos() - vec)

    for k, v in pairs(en) do
        local dontcontinue = false
        if v:IsOnFire() then continue end
        if not DoIgnite[v:GetClass()] then continue end

        if not v:IsPlayer() then
            if math.random(0, 100) < 95 then
                dontcontinue = true
            end
        end

        if dontcontinue or v.InProcess or v.Noclip then
            if PHDayZ.DebugMode then
                MsgAll("Not Running Ignite on " .. v:GetClass())
            end

            continue
        end

        if PHDayZ.DebugMode then
            MsgAll("Running Ignite on " .. v:GetClass())
        end

        if v:IsPlayer() then
            v.playerwarnings = (v.playerwarnings or 0) + 1
            local color = 85 * v.playerwarnings + 1
            v:Tip(3, "closetofire", Color(color, 0, 0))
        end

        if v:IsPlayer() and (v.playerwarnings or 0) < 3 then continue end

        if IsValid(v) then
            local ignitefor = math.random(5, v:IsPlayer() and 10 or 30)
            v:Ignite(ignitefor, 0)

            if v:IsPlayer() then
                v.playerwarnings = nil
            end
        end

        ent.firecount = (ent.firecount or 0) + 1
    end
end

local NextFireSpread = 0

local function DoFireSpread()
    if NextFireSpread > CurTime() then return end
    if not PHDayZ.FireSpread then return end

    for k, v in pairs(DZ_IgnitedEntities) do
        if not IsValid(v) or not v:IsOnFire() or v:IsPlayer() or v:GetPersistent() then
            DZ_IgnitedEntities[k] = nil
            continue
        end

        FireSpread(v)
    end

    NextFireSpread = CurTime() + 5
end

hook.Add("Think", "FireSpread", DoFireSpread)

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)

    if hitgroup == HITGROUP_HEAD then
        if !ply.CharTable then return end -- fucking bots man

        if IsValid(ply.hat) && !ply:GetInArena() then
            ply:EmitSound("physics/cardboard/cardboard_box_impact_bullet1.wav", 75, 100, 0.5)

            local it = GAMEMODE.Util:GetItemIDByClass(ply.CharTable, ply.hat.class)

            if it then
                local dmg = dmginfo:GetDamage()
                dmginfo:SetDamage( dmg - it.rarity )
                dmg = dmg - it.rarity

                it.quality = it.quality - ( dmg * 4 )

                if it.quality < 150 then
                    ply:BreakItem(it.id, true)
                else
                    --ply:UpdateChar(it)
                end

                dmginfo:ScaleDamage(0.2)
            end
        else
            dmginfo:ScaleDamage(1.2)
        end

    else
        dmginfo:ScaleDamage(0.6) -- fights last longer

        if ply:GetInArena() then return end
        if !ply.CharTable then return end

        for class, items in pairs( ply.CharTable ) do
            local CharItem = GAMEMODE.DayZ_Items[ class ]

            if CharItem.BodyArmor then

                local hasitem = false
                local quality = 0
                for k, item in pairs(items) do
                    if item.amount < 1 then continue end

                    local dmg = dmginfo:GetDamage()
                    dmginfo:SetDamage( dmg - item.rarity )
                    dmg = dmg - item.rarity

                    local amt = math.Round( ( dmg * 200 ) / CharItem.BodyArmor )

                    item.quality = item.quality - amt
                    quality = item.quality
                    
                    ply:UpdateChar(item.id, item.class)
                    hasitem = item      
                    break
                end

                if quality >= 100 then
                    dmginfo:ScaleDamage(0.6)                   
                end

                if !hasitem then continue end
            
                if quality < 100 then
                    ply:BreakItem(hasitem.id, true)
                    ItemDestroyed( ply:GetPos() + Vector(0, 0, 40) )
                    break
                end
            end
        end

    end
end

local meleetypes = {DMG_CRUSH, DMG_SLASH, DMG_CLUB}
function GM:EntityTakeDamage(ent, dmginfo)
    if ent:GetPersistent() then return true end

    local attacker = dmginfo:GetAttacker()

    if IsValid(ent) && ( ent:IsPlayer() or ent:IsNPC() ) && IsValid( attacker ) && attacker:IsPlayer() && ent != attacker then
        net.Start( "HurtInfo" )
            net.WriteVector( dmginfo:GetDamagePosition() )
        net.Send( attacker )
    end

    if IsValid(attacker) and ( attacker:IsPlayer() or attacker:IsNPC() ) && !attacker.Noclip then
        
        if ent:IsPlayer() then
            net.Start("CloseOpenMenus")
            net.Send( ent )
        end

        if ent:IsNPC() && ( ent.VJ_NPC_Class or ent.IsZombie ) then
            if ent:GetTarget() != attacker then
                if ent:Disposition(attacker) > 2 then return end
                if ( ent.nAChange or 0 ) > CurTime() then return end

                ent.nAChange = CurTime() + 10

                ent.RunningAfter_FollowPlayer = false
                ent.vACT_StopAttacks = false
                ent.Flinching = false

                ent:SelectSchedule()
                ent:StopMoving()

                ent:SetTarget( attacker )
                ent:SetEnemy( attacker )
                ent:VJ_TASK_CHASE_ENEMY()

            end
        end
    end

    if IsValid(attacker) and attacker:IsPlayer() then
        if (attacker:GetSafeZone() or attacker:GetSafeZoneEdge()) and not ent:IsPlayer() then
            dmginfo:SetDamage(0)
        end

        local item = dmginfo:GetInflictor().item
        if !item then return end

        local ItemTable = GAMEMODE.DayZ_Items[item]
        if ent:IsPlayer() && ( ItemTable.Melee or ItemTable.Tertiary ) then
            dmginfo:ScaleDamage(0.7) -- melee is nerfed
        end

    end

    if ent:IsPlayer() and ent:InVehicle() then
        dmginfo:ScaleDamage(0.2) -- half damage in vehicles.
    end

    if IsValid(ent.ply) && ent.dzsearchable && IsValid(ent.ply.grave) && !ent.ply:GetInArena() then -- grave! 
        if ( ent.canDamage or 0 ) > CurTime() then return end
        local hp = ent.ply:GetRealHealth()

        ent.ply:SetRealHealth( math.Clamp( hp - dmginfo:GetDamage()/2, 0, 100 ) )
    end
    
    if ent:IsPlayer() and not ent:IsBot() then

        local it = GAMEMODE.Util:GetItemIDByClass(ent.CharTable, "item_hazmat_1")

        if it && dmginfo:IsDamageType( DMG_RADIATION ) then 
            it.quality = it.quality - dmginfo:GetDamage() 
            dmginfo:ScaleDamage(0) 
            --ent:UpdateChar(it.id) 
            return 
        end

        if !dmginfo:IsDamageType( DMG_RADIATION ) && ent.InProcess then ent:StopProcess() end
        ent:UnLock()

        if ent:GetInArena() or ent:GetSafeZoneEdge() or ent:GetSafeZone() && ent:GetPVPTime() < CurTime() then return end

        if dmginfo:IsDamageType(DMG_BURN) then
            ent:SetBleed(false)
        end
        if dmginfo:IsDamageType(DMG_BULLET) then
            if math.random(1, 10) > 8 then
                ent:SetBleed(true)
            end
        end
    end

    if ( attacker:IsNPC() or attacker.IsZombie ) and ent:IsPlayer() then
        dmginfo:ScaleDamage( PHDayZ.NPC_PlayerDamageScale or 0.60 ) -- 0.35
    end

    if ( ent:IsNPC() or ent.IsZombie ) and attacker:IsPlayer() then
        if dmginfo:GetAttacker():HasPerk("perk_zombieslayer") then
            dmginfo:ScaleDamage(1.1)
        end

        if dmginfo:IsDamageType(DMG_BLAST) then
            dmginfo:ScaleDamage(2)
        end

        local wep = dmginfo:GetInflictor()
        if (IsValid(wep) and wep:GetClass() == "weapon_emptyhands") or dmginfo:IsDamageType(DMG_BULLET) then
            dmginfo:ScaleDamage(2)
            if dmginfo:GetAmmoType() == 33 then -- type is shotgun buckshot
                dmginfo:ScaleDamage(4)
            end
        end
    end

    if attacker:IsVehicle() and IsValid(attacker:GetDriver()) and ent:IsPlayer() then
        attacker:GetDriver():AddFrags(1)
        attacker:GetDriver():AddPFrags(1)
    end

    if (ent:GetClass() == "sent_sakariashelicopter") then
        if dmginfo:IsExplosionDamage() then
            ent:SetHealth(ent:Health() - 10)
        else
            ent:SetHealth(ent:Health() - 5)
        end

        if IsValid(ent:GetDriver()) then
            ent:GetDriver():TakeBlood(2, dmginfo:GetAttacker(), dmginfo:GetInflictor())
        end

        if ent.Seats then
            for k, v in pairs(ent.Seats) do
                if not IsValid(v) then continue end

                if IsValid(v:GetDriver()) then
                    v:GetDriver():TakeBlood(2, dmginfo:GetAttacker(), dmginfo:GetInflictor())
                end
            end
        end

        ent:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav")
    end

    if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "dz_interactable" ) and !ent:GetPersistent() and ent.SID and PHDayZ.AllowPropDamage then

        if dmginfo:IsDamageType( DMG_BURN ) && ent:GetModel() == "models/dayz/misc/dayz_campfire.mdl" then return end -- campfire will burn itself.

        ent:SetHealth(ent:Health() - dmginfo:GetDamage())

        if ent:Health() < 1 then
            ItemDestroyed(ent:GetPos())
            ent:Remove()
        end
    end
end

function PlayerDamages(victim, attacker)
end

hook.Add("PlayerShouldTakeDamage", "PlayerDamages", PlayerDamages)

function OverrideDeathSound()
    return true
end

hook.Add("PlayerDeathSound", "OverrideDeathSound", OverrideDeathSound)

function DropMoney(ent, amountlow, amounthigh, chance, ply)
    if math.random(0, 100) <= chance then   

        local amount = math.random(amountlow, amounthigh)

        if amount > 500 then amount = 500 end -- HARDCODED CAP

        if ply:HasPerk("perk_autolooter") then
            ply:GiveItem( "item_money", amount, nil, 500, 1, nil, false, true )
            if VJInsurgents[ ent:GetClass() ] && DZ_Quests then
                ply:DoQuestProgress("quest_inshell", amount)
            end

            return
        end

        local moneyitem = ents.Create("base_item")
        moneyitem:SetItem("item_money")
        moneyitem:SetQuality(500)
        moneyitem:SetRarity(1)
        moneyitem.Amount = amount
        moneyitem:SetAmount(amount)
        moneyitem.Dropped = true

        if VJInsurgents[ ent:GetClass() ] then
            moneyitem.NPCDropped = true
        end

        moneyitem:SetPos(ent:GetPos() + Vector(0, 0, 50))
        moneyitem:Spawn()
        local phys = moneyitem:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:AddVelocity(Vector(math.random(50, 150), math.random(50, 150), math.random(50, 150)))
        end
    end
end

function DropMeat(ent, amountlow, amounthigh, chance, ply)
    if math.random(0, 100) <= chance then
        local item = ent:IsOnFire() and "item_cookedmeat" or "item_meat"
        
        if !GAMEMODE.DayZ_Items[item] then return end
        local rarity, quality, amount = GenerateRarity(), math.random(100, 500), math.random(amountlow, amounthigh)

        if ply:HasPerk("perk_autolooter") then
            ply:GiveItem( item, amount, nil, quality, rarity, nil, false, true )
            return
        end

        if amount > 20 then amount = 20 end -- ANOTHER HARDCODE.

        local meat = ents.Create("base_item")
        meat:SetItem(item)
        meat:SetRarity(rarity)
        meat:SetQuality(quality)
        meat.Amount = amount
        meat:SetAmount(meat.Amount)
        meat.Dropped = true
        meat:SetPos(ent:GetPos() + Vector(0, 0, 50))
        meat:Spawn()
        local phys = meat:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:AddVelocity(Vector(math.random(50, 150), math.random(50, 150), math.random(50, 150)))
        end
    end
end

DZ_DropPool = DZ_DropPool or {}
function DropItem(ent, amountlow, amounthigh, chance, ply, anyitem)
    if math.random(0, 100) <= chance then
        local item = table.Random(PHDayZ.ZombieItems) or "item_medic1"
        local ItemTable
        local categories = {"Food", "Drinks", "Medical", "Primaries", "Secondaries", "Ammo"}

        if table.Count(DZ_DropPool) < 1 then 
            for _, cat in pairs(categories) do
                local tab = GAMEMODE.Util:GetItemsByCategory( string.lower(cat) )

                for _, t in pairs(tab) do

                    local Item = GAMEMODE.DayZ_Items[t.ID]
                    if !Item then continue end
                    if ( Item.SpawnChance or -1 ) < 0 then continue end
    
                    DZ_DropPool[t.ID] = t

                    --table.insert(DZ_DropPool, t)
                end
            end
        end

        if anyitem then ItemTable, item = table.Random( DZ_DropPool ) end

        ItemTable = GAMEMODE.DayZ_Items[item]

        if !ItemTable then return end

        local rarity = GenerateRarity()
        if ItemTable.AmmoType then rarity = 1 end
        local amount = math.random(amountlow, amounthigh)
        if amount < 1 then amount = 1 end
        if ItemTable.ClipSize then
            amount = math.random(1, ItemTable.ClipSize)
        end

        local quality = math.random(200, 500)

        if ( ItemTable.Weapon and math.random(1, 10) <= 9 ) or !ent:GetActiveWeapon() then
            return
        end

        if ply && ply:HasPerk("perk_autolooter") then 
            ply:GiveItem( item, amount, nil, quality, rarity, nil, false, true )
            return
        end

        local meat = ents.Create("base_item")
        meat:SetItem(item)
        meat:SetQuality(quality)
        
        meat:SetRarity(rarity)

        meat.Amount = amount
        meat:SetAmount(amount)
        meat.Dropped = true
        meat:SetPos(ent:GetPos() + Vector(0, 0, 50))
        meat:Spawn()
        local phys = meat:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:AddVelocity(Vector(math.random(50, 150), math.random(50, 150), math.random(50, 150)))
        end
    end
end