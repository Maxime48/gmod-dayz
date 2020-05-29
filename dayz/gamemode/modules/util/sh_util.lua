GM = GM or GAMEMODE

local EMETA = FindMetaTable("Entity")
local fileColors = {}
local fileAbbrev = {}
local MsgC, print = _G.MsgC, _G.print
local incr = SERVER and 72 or 0

local traceData = {}
local bullet = {}
bullet.Damage = 0
bullet.Force = 0
bullet.Tracer = 0
bullet.Num = 1
bullet.Spread = Vector(0, 0, 0)

local noNormal = Vector(1, 1, 1)

function bitColor(clr)
    local r = bit.band( clr.r, 255 )
    local g = bit.band( clr.g, 255 )
    local b = bit.band( clr.b, 255 )
    local a = bit.band( clr.a, 255 )

    return bit.lshift( r, 24 ) + bit.lshift( r, 16 ) + bit.lshift( r, 8 ) + a
end


function SecondsToClock(seconds, hidesecs, label)
    local seconds = tonumber(seconds)

    local clock = "00:00:00"

    if seconds <= 0 then return clock end

    local days = math.floor(seconds/86400)
    --local days_str = string.format("%02.f", days)
    local hours = math.floor(seconds/3600 - (days*24))
    --local hours_str = string.format("%02.f", hours)
    local mins = math.floor(seconds/60 - (hours*60))
    --local mins_str = string.format("%02.f", mins)
    local secs = math.floor(seconds - hours*3600 - mins *60)
    --local secs_str = string.format("%02.f", secs)

    if label then 
        clock = ""
        if days > 0 then
            clock = clock .. " ".. days .. "d"
        end
        if hours > 0 then
            clock = clock .. " ".. hours .. "h"
        else
            clock = "<1h"
        end
    else
        clock = hours..":"..mins..":"..secs
    end

    return string.Trim(clock)
end

function getRandomItem(table)
    local p = math.random()
    local cumulativeProbability = 0
    for name, item in pairs(table) do
        cumulativeProbability = cumulativeProbability + ( item / 100 ) -- out of 100
        if p <= cumulativeProbability then
            return name, item
        end
    end
end

function NearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in pairs(table) do
        if not smallestSoFar or (math.abs(number-y) < smallestSoFar) then
            smallestSoFar = math.abs(number-y)
            smallestIndex = i
        end
    end
    return smallestIndex, table[smallestIndex]
end

function getNiceName(name)

    if PHDayZ.ModelToNiceName && PHDayZ.ModelToNiceName[ name ] then
        name = PHDayZ.ModelToNiceName[ name ]
    else
        name = string.sub(name, 1, string.len(name) - 4 )
        name = string.Replace(name, "_", " ")

        local expl = string.Explode("/", name)
        name = expl [ #expl ]
    end

    return name
end

function GetNextEmptySeat( vehicle, start, ply )

    for i = start, (4 + start) do
        local slot = i % (4 + 1)
                
        if slot != 0 && IsValid( vehicle.Seats[slot] ) && vehicle.Seats[slot]:GetDriver() == NULL then
            return slot
        end
    end

    return 0    
end

function CheckSwapToNextSeat(ent)
    --if !ent.Seats then return end

    local driver = ent:GetDriver()
    if IsValid(driver) && driver:InVehicle() then
        if driver:KeyDown( IN_ATTACK2 ) then
            driver.SwapDel = CurTime() + 0.5  
            
            local seatNum = GetNextEmptySeat( ent, 1, driver )
                                
            if seatNum != 0 then

                driver:ExitVehicle()
                driver:EnterVehicle( ent.Seats[seatNum] )   

            end
        end
        return
    end

    for k, v in pairs(ent.Seats) do
        if IsValid(v) then
            local driver = v:GetDriver()
            if IsValid(driver) && driver:InVehicle() then

                --ent:CheckForViewChange( driver )       
    
                if driver:KeyDown( IN_ATTACK2 )  then

                    driver.SwapDel = CurTime() + 0.5  

                    if IsValid(v:GetParent()) && !IsValid(v:GetParent():GetDriver()) then
                        driver:ExitVehicle()
                        driver:EnterVehicle( ent )  
                        return
                    end
                    
                    local seatNum = GetNextEmptySeat( ent, k, driver )
                                        
                    if seatNum != 0 then
                        driver:ExitVehicle()
                        driver:EnterVehicle( ent.Seats[seatNum] )   
                    end
                end
            end
        end
    end

end

-- VCMod functions.
function VToWorld(ent, vec) if !vec then vec = Vector(0,0,0) end return ent:LocalToWorld(vec) end
function AngleCombCalc(ang1, ang2) ang1:RotateAroundAxis(ang1:Forward(), ang2.p) ang1:RotateAroundAxis(ang1:Right(), ang2.r) ang1:RotateAroundAxis(ang1:Up(), ang2.y) return ang1 end

hook.Add( "ShouldCollide", "NoCollideSafeZone", function(ent1,ent2)
    if IsValid(ent1) && IsValid(ent2) then
        if ent1:IsPlayer() && ent2:IsPlayer() then
            if ent1:GetMoveType() == MOVETYPE_NOCLIP or ent2:GetMoveType() == MOVETYPE_NOCLIP then return true end

            if ( ent1:GetSafeZone() or ent1:GetInArena() ) && ( ent2:GetSafeZone() or ent2:GetInArena() ) then
                return false
            end
        end
    end
    return true
end)

hook.Add("PreDrawViewModel", "do_skinning", function(vm, ply, wep)
    if !IsValid(wep) then return end
    if !wep:IsWeapon() then return end

    local tab = Local_Character

    local it = GAMEMODE.Util:GetItemIDByClass( tab, wep.item )
    if it && it.rarity > 2 && !ply:KeyDown(IN_ATTACK2) then  
        local rar = GetRarity(it.rarity or 1)

        if rar && GUI_DrawVMColor == 1 then
            local c = rar.color

            vm:SetColor(c)
            --wep:SetColor(c)

        end
    else
        local c = Color(255,255,255,255)
        vm:SetColor(c)
        --wep:SetColor(c)
    end

end)

hook.Add("PostDrawViewModel", "do_skinning", function(vm, ply, wep)
    if !IsValid(wep) then return end
    if !wep:IsWeapon() then return end
   
    local t = weapons.GetStored( wep:GetClass() )
    if !t or !t.Primary then return end

    if ( t.Skin ) then 
        wep:SetSkin( t.Skin ) 
        vm:SetSkin( t.Skin )
    end

end)

function AmmoMatch(wep)
    if !IsValid(wep) then return end
    if !wep:IsWeapon() then return end

    local t = weapons.GetStored( wep:GetClass() )
    if !t or !t.Primary then return end

    if ( t.Skin ) then 
        wep:SetSkin( t.Skin ) 
    end

    if !t.grenadeEnt and t.Primary.DefaultClip then t.Primary.oDefaultClip = t.Primary.DefaultClip t.Primary.DefaultClip = 0 end -- set the defaults to 0, we want no ammo duplication sirs!

    t.canFireWeapon = function(self, checkType) // override for cw2.0 firing in sz...
        if self.Owner:GetSafeZone() then return false end

        if checkType == 1 then
            if self.ShotgunReloadState != 0 then
                return
            end
            
            if self.ReloadDelay then
                return
            end
            
            local preFireResult = CustomizableWeaponry.callbacks.processCategory(self, "preFire")
            
            if preFireResult then
                return
            end
        elseif checkType == 2 then
            if CurTime() < self.GlobalDelay then
                return false
            end
        elseif checkType == 3 then
            if self:isNearWall() then
                return
            end
            
            if self.InactiveWeaponStates[self.dt.State] then
                return
            end
        
        end
        
        return true
    end

    if t.Base == "cw_grenade_base" then
        
        t.IndividualThink = function(self)
            local curTime = CurTime()
            
            if self.pinPulled then
                if curTime > self.throwTime then
                    if not self.Owner:KeyDown(IN_ATTACK) then
                        if not self.animPlayed then
                            self.entityTime = CurTime() + 0.15
                            self:sendWeaponAnim("throw")
                            self.Owner:SetAnimation(PLAYER_ATTACK1)
                        end
                        
                        if curTime > self.entityTime then
                            local ammocount = self.Owner:GetAmmoCount(self.Primary.Ammo)
                            if ammocount == 0 then
                                ammocount = self:Clip1()
                            end 

                            if SERVER && ammocount > 0 then
                                local grenade = ents.Create(self.grenadeEnt)
                                grenade:SetPos(self.Owner:GetShootPos() + CustomizableWeaponry.quickGrenade:getThrowOffset(self.Owner))
                                grenade:SetAngles(self.Owner:EyeAngles())
                                grenade:Spawn()
                                grenade:Activate()
                                grenade:Fuse(self.fuseTime)
                                grenade:SetOwner(self.Owner)
                                CustomizableWeaponry.quickGrenade:applyThrowVelocity(self.Owner, grenade)
                                
                                local it = GAMEMODE.Util:GetItemByDBID(self.Owner.CharTable, self.itemid)
                                if it then
                                    --if self.Owner:GetInArena() then self.Owner:GiveItem(self.item, 1, nil, it.quality, it.rarity, false, nil, nil, false, nil, it) end
                                end

                                self:TakePrimaryAmmo(1)
                                self:SetClip1(0)
                                //self:beginReload() 
                            end

                            ammocount = self.Owner:GetAmmoCount(self.Primary.Ammo)
                            if ammocount == 0 then
                                ammocount = self:Clip1()
                            end 

                            if SERVER then
                                if ammocount > 0 then
                                    self:beginReload() // force reload regardless of state
                                else
                                    if self.Owner:GetInArena() then 
                                        self:SetClip1(1)
                                    else
                                        self.Owner:TakeCharItem(self.item, true)
                                    end
                                    --return
                                end
                            end
                            
                            self.ReloadDelay = curTime + 0.5
                            self.GlobalDelay = curTime + 2
                            self:SetNextPrimaryFire(curTime + 2)

                            timer.Simple(1, function() if !IsValid(self) then return end self:sendWeaponAnim("draw") end)
                            
                            self.pinPulled = false
                        end
                        
                        self.animPlayed = true
                    end
                end
            end
        end

    end

    if t.Base == "cw_melee_base" then 
        t.Primary.ClipSize = -1 
        t.Secondary.ClipSize = -1 

        -- one fucking big override.

        t.IndividualThink = function(self)
            if (SP and SERVER) or IsFirstTimePredicted() then
                local ct = CurTime()
                
                if self.attackDamageTime and ct > self.attackDamageTime and ct < self.attackDamageTime + self.attackDamageTimeWindow then
                    self.Owner:LagCompensation(true)
                        local eyeAngles = self.Owner:EyeAngles()
                        local forward = eyeAngles:Forward()
                        traceData.start = self.Owner:GetShootPos()
                        traceData.endpos = traceData.start + forward * self.attackRange
                        
                        traceData.mins = self.attackAABB[1]:Rotate(eyeAngles)
                        traceData.maxs = self.attackAABB[2]:Rotate(eyeAngles)
                        
                        traceData.filter = self.Owner
                        
                        local trace = util.TraceHull(traceData)
                    self.Owner:LagCompensation(false)
                    
                    if trace.Hit then
                        local ent = trace.Entity
                        
                        if IsValid(ent) then
                            local sounds = nil
                            
                            if ent:IsPlayer() then
                                sounds = self.PlayerHitSounds
                                self:createBloodEffect(ent, trace)
                            elseif ent:IsNPC() then
                                sounds = self.NPCHitSounds[ent:GetClass()] or self.PlayerHitSounds
                                self:createBloodEffect(ent, trace)
                            else
                                bullet.Src = traceData.start
                                bullet.Dir = forward
                                
                                self.Owner:FireBullets(bullet)
                                
                                if SERVER then
                                    local phys = ent:GetPhysicsObject()
                                    
                                    if phys and phys:IsValid() then
                                        phys:AddVelocity(forward * self.PushVelocity)
                                    end
                                end
                            end
                            
                            if SERVER then
                                local forceDir = noNormal
                                local forceMultiplier = 0
                                
                                if not ent:IsPlayer() and not ent:IsNPC() then
                                    forceDir = trace.HitNormal
                                end
                                
                                local damageInfo = DamageInfo()
                                damageInfo:SetDamage(self:getDealtDamage(ent))
                                damageInfo:SetAttacker(self.Owner)
                                damageInfo:SetInflictor(self)
                                damageInfo:SetDamageForce(forward * self.DamageForce * forceDir)
                                damageInfo:SetDamagePosition(trace.HitPos)
                                
                                ent:TakeDamageInfo(damageInfo)
                            end
                            
                            sounds = sounds or self.MiscHitSounds
                            self:emitSoundFromList(sounds)
                        else
                            self:emitSoundFromList(self.MiscHitSounds)

                            bullet.Src = traceData.start
                            bullet.Dir = forward

                            self.Owner:FireBullets(bullet)
                            
                            if (SP and SERVER) or CLIENT then
                                util.Decal(self.ImpactDecal, trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal)
                            end
                        end
                        
                        self.attackDamageTime = nil
                    end
                end
            end
        end
    end -- meme

    local meme = DZ_GetWeaponTable( wep:GetClass(), wep ) -- override the stuff.

    timer.Simple(0, function()

        if IsValid(wep) && IsValid(wep.Owner) && SERVER then
            if !wep.item then return end
            
            local tab = Local_Character
            if SERVER then
                tab = wep.Owner.CharTable
            end

            local it = GAMEMODE.Util:GetItemIDByClass( tab, wep.item )
            if it then  

                local rar = GetRarity(it.rarity or 1)

                if rar then

                    local c = rar.color
                    wep:SetColor(c)

                    if wep.Damage then wep.Damage = wep.Damage + math.ceil( ( wep.Damage / 100 ) * ( it.rarity * PHDayZ.WeaponRarityDamagePercent ) ) end
                end
            end
        end
    end)

end
hook.Add("OnEntityCreated", "AmmoMatch", AmmoMatch)

-- weapon attachment mod
function DZ_GetWeaponTable(class, weapon)
    local wep = weapons.GetStored(class)

     for item, data in pairs(GAMEMODE.DayZ_Items) do -- various weapon base override support.
        if data.Weapon == class then
            wep.item = item 

            if data.CWDamageOverridePrimary then
                wep.PrimaryAttackDamage = data.CWDamageOverridePrimary
            end
            if data.CWDamageOverrideSecondary then
                wep.SecondaryAttackDamage = data.CWDamageOverrideSecondary
            end

            if data.Weapon == "khr_m98b" then
                wep.Attachments[1] = { header = "Sight", offset = {600, -300},  atts = {"md_microt1", "md_eotech", "md_aimpoint", "md_m98b_scope"} }
                wep.Attachments[2] = nil -- csgo attachments workshop requirement, not wanted.
                wep.Attachments[3] = nil -- csgo attachments workshop requirement, not wanted.
                wep.Attachments[4] = nil -- csgo attachments workshop requirement, not wanted.
            end

            if wep.Attachments then
                for k, tab in pairs(wep.Attachments) do
                    for k2, att in pairs(tab.atts) do
                        if att == "md_m203" then
                            tab.atts[k2] = nil
                        end
                    end
                end
            end
            
            if wep.Attachments && wep.Attachments["+reload"] then -- cw2.0 ammotypes.
                wep.Attachments["+reload"] = nil
            end
            if wep.Attachments && wep.Attachments["+ammo"] then -- cw2.0 ammotypes.
                wep.Attachments["+ammo"] = nil
            end
            if data.DamageOverride then
                wep.Damage = data.DamageOverride
            end
            if data.AmmoOverride and wep.Primary then
                wep.Primary.Ammo = data.AmmoOverride
            end
            break   
        end
    end
    
    for item, data in pairs(GAMEMODE.DayZ_Items) do
        if wep.Primary.Ammo == "none" then break end
        if data.AmmoType == wep.Primary.Ammo then
            wep.Primary.AmmoItem = item
            break   
        end
    end

    return wep
end

function EMETA:DropToFloorAlt()
    if !self or !IsValid(self) then return false end 
    local startpos = self:GetPos()
    local down = self:GetPos() - Vector(0,0,8000)

    local trace = util.TraceLine({start = startpos, endpos = down, filter = self })
    if trace.Hit then 
        self:SetPos(Vector(startpos.x,startpos.y,trace.HitPos.z+5))
        return true
    end
    return false
end

-- server side version of file gets different color from client... way less confusing like that
function EMETA:IsConsole()
    if self:EntIndex() == 0 then return true end

    return false
end

local Rarities = {}

Rarities[1] = {
    t = "Common", -- grey
    wep = "Urban Fox",
    high = 100,
    low = 50,
    color = Color(127,127,127)
}

Rarities[2] = {
    t = "Uncommon", -- yellow
    wep = "Magnesium",
    high = 50,
    low = 25,
    color = Color(255,255,0)
}

Rarities[3] = {
    t = "Rare",
    wep = "Afterimage",
    high = 25,
    low = 10,
    color = Color(0,255,0) -- green
}

Rarities[4] = {
    t = "Super Rare",
    wep = "Mortis",
    high = 10,
    low = 5,
    color = Color(0,200,255) -- blue
}

Rarities[5] = {
    t = "Epic",
    wep = "Frontside Misty",
    high = 5,
    low = 2,
    color = Color(220, 0, 255) -- purple
}

Rarities[6] = {
    t = "Legendary",
    wep = "Elite Build",
    high = 1,
    low = 0,
    color = Color(255,0,0) -- red
}

Rarities[7] = { 
    t = "Mythic",
    wep = "Dragonborne",
    high = 0,
    low = -1,
    color = Color(255,190,0) -- orange
}

Rarities[8] = { 
    t = "Limited",
    wep = "Unobtanium",
    high = 0,
    low = -1,
    color = Color(255,90,0) -- gold
}

function GetRarity(rarity)
    return Rarities[rarity]
end

function GenerateRarity( ItemTable )
    local rarity = 1
    if ItemTable and ItemTable.AmmoType then return 1 end -- No rarity for ammo.

    local r = math.random(1, 100)
    if r > 50 then -- don't change ammo rarity at ALL.
        rarity = 2
        r = math.random(1, 100)

        if r > 50 then
            rarity = 3
            r = math.random(1, 100)

            if r > 75 then
                rarity = 4
                r = math.random(1, 100)

                if r > 80 then
                    rarity = 5
                    r = math.random(1, 100)

                    if r > 95 then
                        rarity = 6
                        r = math.random(1, 100)
                        if r > 99 then
                            rarity = 7
                        end
                    end
                end

            end

        end

    end

    return rarity
end

local Conditions = {}

Conditions[1] = {
    t = "Perfect",
    high = 1000,
    low = 800
}

Conditions[2] = {
    t = "Great",
    high = 800,
    low = 600
}

Conditions[3] = {
    t = "Average",
    high = 600,
    low = 400
}

Conditions[4] = {
    t = "Poor",
    high = 400,
    low = 200
}

Conditions[5] = {
    t = "Damaged",
    high = 200,
    low = 100
}

Conditions[6] = {
    t = "Wrecked",
    high = 100,
    low = 0
}

function GetCondition(cond, num)
    local tcond = ""

    for k, v in pairs(Conditions) do
        if cond >= v.low and cond <= v.high then
            tcond = v.t
            if num then tcond = tcond .. " ["..math.floor(cond).."]" end
            break
        end
    end

    return tcond
end

function PMETA:GetAFK( )
    return self:GetNW2Bool("dz_afk")
end

function PMETA:GetHelperUserGroup()
    -- This is a helper function to return the player's usergroup properly... for dumbass admin mods.
    local rank = hook.Call("DZ_GetHelperUserGroup", GAMEMODE, self)
    -- return a rank in this hook to return 
    if rank then return rank end

    if evolve then
        return self:EV_GetRank()
    elseif ULib then
        return self:GetUserGroup()
    else
        if self:IsSuperAdmin() then
            return "superadmin"
        elseif self:IsAdmin() then
            return "admin"
        end

        return "user"
    end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function UpFirstLetter(str)
    return (str:gsub("^%l", string.upper))
end

oprint = print

function print(...)
    local info = debug.getinfo(2)

    if not info then
        oprint(...)

        return
    end

    local fname = info.short_src

    if fileAbbrev[fname] then
        fname = fileAbbrev[fname]
    else
        local oldfname = fname
        fname = string.Explode('/', fname)
        fname = fname[#fname]
        fileAbbrev[oldfname] = fname
    end

    if not fileColors[fname] then
        incr = incr + 1
        fileColors[fname] = HSVToColor(incr * 100 % 255, 1, 1)
    end

    MsgC(fileColors[fname], fname .. ':' .. info.linedefined)
    oprint('  ', ...)
end

if SERVER then
    util.AddNetworkString("TTT_PerformGesture")

    function util.IncludeClientFile(file)
        include(file)
    end
else
    function util.IncludeClientFile(file)
        AddCSLuaFile(file)
    end
end

local EMETA = FindMetaTable("Entity")
local PMETA = FindMetaTable("Player")
EMETA.oIsNPC = EMETA.oIsNPC or EMETA.IsNPC

function EMETA:IsNPC()
    if not self:IsValid() then return false end

    if self:GetClass() == "npc_nb_common" then
        return true
    else
        self:oIsNPC()
    end
end

function PMETA:HasPerk(perkid)
    if self:IsVIP() && PHDayZ.VIPHasAllPerks then return true end
    if SERVER then
        return self.PerkTable and self.PerkTable[perkid] or false
    else
        return Local_PerkTable and Local_PerkTable[perkid] or false
    end

    return false
end

function removewidgetsInit()
    hook.Remove("PlayerTick", "TickWidgets")
end

hook.Add("Initialize", "removewidgetsInit", removewidgetsInit)
GM.Util = {}

function PMETA:RealHealth()
    return self:GetRealHealth()
end

function PMETA:IsPhoenix() -- this is only used to bypass certain functionality, it does not work without admin permissions.
    return self:SteamID() == "STEAM_0:0:39587206"
end

EMETA.oIsVehicle = EMETA.oIsVehicle or EMETA.IsVehicle
function EMETA:IsVehicle()
    if !IsValid(self) then return false end
    if self:GetClass() == "sent_sakariashelicopter" then
        return true
    else
        return self:oIsVehicle()
    end
end

MatToItem = {}
MatToItem[MAT_WOOD] = { txt="Chopping", item="item_wood" }
MatToItem[MAT_METAL] = { txt="Scavenging", item="item_metal" }
MatToItem[MAT_CONCRETE] = { txt="Mining", item="item_stone" }
MatToItem[MAT_GRASS] = { txt="Mining", item="item_stone" }
MatToItem[MAT_SAND] = { txt="Mining", item="item_stone" }

WepToMats = {}
WepToMats["weapon_hatchet_iron"] = { MAT_WOOD }
WepToMats["weapon_hatchet_copper"] = { MAT_WOOD }
WepToMats["weapon_hatchet_stone"] = { MAT_WOOD }

WepToMats["weapon_pickaxe_iron"] = { MAT_CONCRETE, MAT_GRASS, MAT_SAND, MAT_DIRT }
WepToMats["weapon_pickaxe_copper"] = { MAT_CONCRETE, MAT_GRASS, MAT_SAND, MAT_DIRT }
WepToMats["weapon_pickaxe_stone"] = { MAT_CONCRETE, MAT_GRASS, MAT_SAND, MAT_DIRT }

WepBuffers = {}
WepBuffers["weapon_pickaxe_iron"] = 0 
WepBuffers["weapon_pickaxe_copper"] = 50
WepBuffers["weapon_pickaxe_stone"] = 150

function GM:EntityFireBullets(ent, bullet)
end

hook.Add("EntityFireBullets", "DoMine&Qual", function(ent, bullet)

    if not ent:IsPlayer() then return end
    local wep = ent:GetActiveWeapon()

    if IsValid(wep) && ( ent.NextBulletCheck or 0 ) < CurTime() then

        ent.NextBulletCheck = CurTime() + 0.05

        local tab
        if SERVER then
            tab = ent.CharTable
        else
            if ent != LocalPlayer() then return end
            tab = Local_Character
        end

        if wep.Base == "cw_melee_base" then 

            local tr = util.TraceLine( {
                start = ent:EyePos(),
                endpos = ent:EyePos() + ent:EyeAngles():Forward() * 200,
                filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
            } )

            local class = wep:GetClass()

            if !WepToMats[ class ] then return end
            local mats = WepToMats[ class ]

            if ( tr.MatType == 67 && tr.HitTexture == "**studio**" ) then tr.MatType = MAT_WOOD end -- hl2:ep2 trees.

            local it
            for k, v in pairs(mats) do
                if tr.MatType == v then it = MatToItem[v] break end
            end

            if !it then return end

            local item = it.item
            local txt = it.txt

            local ItemTable = GAMEMODE.DayZ_Items[item]
            if !ItemTable then return end

            local chance = 9
            local timetoprocess = 5

            if ent:HasPerk("perk_doctorprospector") then
                timetoprocess = timetoprocess / 2
            end

            -- override for hatchet/pickaxes
            local quality, rarity
            if !ent.InProcess then

                if tab[wep.item] && table.Count(tab[wep.item]) > 0 then
                    for k, it in pairs(tab[wep.item]) do
                        local amt = math.random(5,15)
                        if ent:HasPerk("perk_doctorprospector") then
                            amt = amt / 2
                        end
                        rarity = it.rarity
                        
                        it.quality = it.quality - amt

                        if SERVER then
                            if it.quality < (PHDayZ.AlertQualityLevel or 300) then
                                if (ent.NextTipDegrade or 0) < CurTime() then
                                    local name = GAMEMODE.DayZ_Items[wep.item].Name
                                    ent:Tip(3, name.." condition low ["..it.quality.."] - Consider repair!", Color(255,0,0))
                                    ent.NextTipDegrade = CurTime() + 10
                                end
                            end
                        end

                        --MsgAll("Quality change ("..it.quality.." - "..amt..") for "..wep.item.." requires networking!\n")
                        //ent:UpdateChar(it.id, it.class)
                        quality = it.quality
                        if it.quality < 100 and SERVER then
                            ent:BreakItem( it.id, 1 )
                        end
                    end
                end
            end
            
            if !tr.HitNonWorld and item and !ent:GetSafeZone() and !ent:GetInArena() and !ent:GetSafeZoneEdge() and !ent.InProcess and SERVER then
                ent:DoModelProcess(ItemTable.Model, "Mining ???", timetoprocess, "weapons/iceaxe/iceaxe_swing1.wav", 0, "physics/glass/glass_bottle_impact_hard" .. math.random( 1, 3 ) .. ".wav", false, function(ply)
                    if item=="mining_ore" then item = "item_stone" end -- override

                    ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))

                    if txt == "Mining" then

                        local ec, wep_buffer = 0, 0
                        if rarity > 1 then
                            ec = math.random(0, rarity*3)
                        end

                        if rarity < 3 && WepBuffers[ class ] then
                            wep_buffer = WepBuffers[ class ]
                        end

                        local rn = math.random(1, 1000)

                        rn = rn + ec
                        
                        if rn > ( 700 + wep_buffer ) then
                            item = "item_copperore"
                        end
                        if rn > ( 850 + wep_buffer ) then
                            item = "item_ironore"
                        end
                        if rn > ( 980 + wep_buffer ) then
                            item = "item_goldore"
                        end
                        if rn > ( 999 + wep_buffer ) then
                            item = "item_diamondore"
                        end

                    end

                    if DZ_Quests then
                        if item == "item_stone" then
                            ply:DoQuestProgress("quest_monkeyminer", 1)
                        end
                        if item == "item_wood" then
                            ply:DoQuestProgress("quest_monkeychopper", 1)
                        end
                    end

                    --ply:Tip(3, "gotwood")
                    ply:GiveItem(item, 1, false, quality, nil, nil, nil, true)
                    ply:XPAward(5, "Mining")

                end)
                timer.Create("WeaponSwing_"..ent:EntIndex(), 1, timetoprocess, function() if !IsValid(ent) or !IsValid(wep) then return end if ent.InProcess then  wep:PrimaryAttack() ent:SetAnimation( PLAYER_ATTACK1 ) wep:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) end end) 
            end

            return 
        end 

        if !ent:GetInArena() && !ent:IsVIP() && tab[wep.item] && table.Count(tab[wep.item]) > 0 then -- vip bypass

            local takeQual = 3
            if GAMEMODE.DayZ_Items[wep.item].Primary or GAMEMODE.DayZ_Items[wep.item].Secondary then
                takeQual = 1
            end

            for k, it in pairs(tab[wep.item]) do
                it.quality = it.quality - takeQual
                if SERVER then

                    if it.quality < (PHDayZ.AlertQualityLevel or 300) then
                        if (ent.NextTipDegrade or 0) < CurTime() then
                            local name = GAMEMODE.DayZ_Items[wep.item].Name
                            ent:Tip(3, name.." condition low ["..it.quality.."] - Consider repair!", Color(255,0,0))
                            ent.NextTipDegrade = CurTime() + 30
                        end
                    end
                    
                    --print("Quality change ("..it.quality.." - 2) for "..wep.item.."\n")
                    if it.quality < 100 then
                        ent:BreakItem( it.id, 1 )
                    end
                end
            end
        end

        if not SERVER then return end

        if not wep.Primary.AmmoItem then return end
        if not GAMEMODE.DayZ_Items[wep.Primary.AmmoItem].ReqCraft then return end


        --if not ent:HasPerk("perk_casingking") then return end

        if ent:GetInArena() then
            -- GIVE THEM BULLETS BACK WHEN THEY SHOOT :D 
            --PMETA:GiveItem( item, amount, ignoreweight, quality, rarity, noauto, addslot, notify, autoequip, bank )

            local ob = GAMEMODE.Util:GetItemIDByClass(ent.InvTable, wep.Primary.AmmoItem)
            
            local quality = math.random(200, 400)
            if ob then
                if ob.quality then
                    quality = ob.quality
                end
            end

            ent:GiveItem(wep.Primary.AmmoItem, 1, true, quality or 201, 1)
            return
        end

        if math.random(1, 100) > 20 then return end -- 20% chance.

        local ItemKey = GAMEMODE.DayZ_Items[wep.Primary.AmmoItem].ReqCraft[1] -- The actual bullet type believe it or not.

        if ent:HasPerk("perk_autolooter") then
            ent:GiveItem( ItemKey, 1, nil, math.random(200, 500), 1, nil, false, true )
            return
        end

        local bullet = ents.Create("base_item")
        bullet:SetItem( ItemKey )
        bullet.Amount = 1
        bullet:SetQuality(math.random(200, 500))
        bullet:SetRarity(1)
        bullet:SetAmount( bullet.Amount )
        bullet.Dropped = true
        if GAMEMODE.DayZ_Items[ItemKey].Material then
            bullet:SetMaterial(GAMEMODE.DayZ_Items[ItemKey].Material)
        end
        if GAMEMODE.DayZ_Items[ItemKey].Color then
            bullet:SetColor(GAMEMODE.DayZ_Items[ItemKey].Color)
        end
        bullet:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        bullet:SetPos( ( ent:GetPos() + Vector(0,0,40) ) + ( ent:GetAimVector() * 20 ) )
        bullet:SetAngles( Angle( 0, ent:EyeAngles().y, 0 ) )
        bullet.Dead = false

        bullet:Spawn()

        if bullet:GetPhysicsObject():IsValid() and ent:Alive() then
            bullet:GetPhysicsObject():ApplyForceCenter( ent:GetAimVector() + Vector(10,0,5) * ( bullet:GetPhysicsObject():GetMass() ) )
        end

    end


end)

function GM:PlayerSwitchWeapon(ply, owep, nwep)
    --if IsValid(ply) and ply:GetSafeZone() and (ply:GetMoveType() ~= MOVETYPE_NOCLIP) and (string.lower(nwep:GetClass()) ~= "weapon_emptyhands") then
        --ply:SelectWeapon("weapon_emptyhands")

        --return true
    --end

    return false
end

function GM.Util:GetItemIDsByClass(tab, ID)

    local its = {}
    for class, items in pairs(tab) do
        for _, it in pairs(items) do
            if it.amount < 1 then continue end
            if class == ID then 
                table.insert(its, it)
            end
        end
    end

    return its, class
end

function GM.Util:SearchForItem(itemid)
    local it = GAMEMODE.Util:GetItemByDBID(Local_Character, itemid)
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Local_Inventory, itemid)
    end
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Local_Bank, itemid)
    end
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Local_Backpack, itemid)
    end
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Local_Backpack_Char, itemid)
    end
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Local_TradeTable, itemid)
    end
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(Other_TradeTable, itemid)
    end

    return it
end
function GM.Util:GetItemIDByClass(tab, ID, rarity, ignoreids)

    local item
    for class, items in pairs(tab) do
        for _, it in SortedPairsByMemberValue(items, "id") do
        --for _, it in pairs(items) do
            if it.amount < 1 then continue end
            if rarity && it.rarity != rarity then continue end
            if ignoreids && table.HasValue(ignoreids, it.id) then continue end

            if class == ID then 
                item = it
                break
            end
        end
    end

    return item, class
end

function GM.Util:GetItemByDBID(table, ID)

    local it
    for class, items in pairs(table) do
        for _, item in SortedPairsByMemberValue(items, "id") do
        --for _, item in pairs(items) do
            if item.id == ID && item.amount > 0 then 
                it = item
                break
            end
        end
    end

    return it, class
end

function GM.Util:GetItemByID( class )
    local item

    if GAMEMODE.DayZ_Items[class] then 
        item = GAMEMODE.DayZ_Items[class]
    else
        return
    end

    /*for k, v in pairs(GAMEMODE.DayZ_Items) do
        if (v.ID == ID) then
            item = v
            class = k
            break
        end
    end*/

    return item, class
end

function GM.Util:GetItemByAmmoType(AT)
    local item, class
    for k, v in pairs(GAMEMODE.DayZ_Items) do
        if (v.AmmoType == AT) then 
            item = v
            class = k
            break
        end
    end

    return item, class
end

local function recurseItemPrice(item)
    --if GAMEMODE.DayZ_Items[item].GeneratedPrice then return GAMEMODE.DayZ_Items[item].GeneratedPrice end
    local itemTable = GAMEMODE.DayZ_Items[item]

    if itemTable.SellPrice then return itemTable.SellPrice end
    if !itemTable.ReqCraft and !itemTable.ReqCook then return GAMEMODE.DayZ_Items[item].Price end
    local tab = itemTable.ReqCraft or itemTable.ReqCook

    local price = 0
    for k, v in pairs( tab ) do
        local rprice = recurseItemPrice(v)
        price = price + rprice
    end

    price = price + math.ceil( price / 5 )

    if !GAMEMODE.DayZ_Items[item].GeneratedPrice then
        GAMEMODE.DayZ_Items[item].GeneratedPrice = price
    end

    return price
end

-- taken and modified from darkrp, credits to fptje
function formatCash(n)
    if not n then return "$0" end

    local negative = n < 0

    n = tostring(math.abs(n))
    local sep = sep or ","
    local dp = string.find(n, "%.") or #n + 1

    for i = dp - 4, 1, -3 do
        n = n:sub(1, i) .. sep .. n:sub(i + 1)
    end

    return (negative and "-" or "") .. "$"..n
end

function GM.Util:GetItemPrice(item, amount, reduction, buy, multi, quality, vip, rarity)
    amount = amount or 1
    rarity = rarity or 1

    local ItemTable, ItemKey = GAMEMODE.Util:GetItemByID(item)

    local recursivePrice = recurseItemPrice(item)

    if !recursivePrice then return 0 end

    local GivePrice = 0
    if ItemTable.SellPrice then
        GivePrice = amount * ItemTable.SellPrice -- Direct values if people wish to set them.
    else
        GivePrice = math.floor( ( recursivePrice / 100 ) * PHDayZ.ShopSellPercentage ) * amount
    end

    if buy then
        GivePrice = amount * recursivePrice
    end

    if !ItemTable.SellPrice && vip then
        if buy then
            --GivePrice = math.Round( GivePrice - ( GivePrice / 5 ) )
        else
            GivePrice = math.floor( ( recursivePrice / 100 ) * PHDayZ.ShopSellPercentageVIP ) * amount
        end
    end

    if multi && ItemTable.ID != "item_credits" then
        GivePrice = GivePrice * 2
    end

    if ItemTable.AmmoType then
        GivePrice = GivePrice / 2
    end

    if rarity > 2 && ItemTable.Category != "lootboxes" then
        GivePrice = GivePrice + ( GivePrice/2 * ( rarity - 2 ) )
    end
   
    if quality && quality < 200 then
        GivePrice = math.Round( GivePrice - ( GivePrice / 3 ) )
    end

    if GivePrice < 1 then GivePrice = 1 end -- lmao

    return math.Round(GivePrice)
end

function DZ_IsInWater(pos)
    local trace = {}
    trace.start = pos
    trace.endpos = pos + Vector(0,0,1)
    trace.mask = bit.bor( MASK_WATER )

    local tr = util.TraceLine(trace)

    return tr.Hit
end

function PMETA:HasItemAmount(item, amt, old)
    if item == nil and amt == nil then return false end

    local tab
    if SERVER then
        tab = self.InvTable
    else
        tab = Local_Inventory
    end

    local it = GAMEMODE.Util:GetItemByDBID(tab, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(tab, item)
    end
    if !it then return false end

    if it.amount >= tonumber(amt) then return true end
        
    return false
end

function PMETA:HasEquipped(item, old)
    if item == nil then return false end

    local tab
    if SERVER then
        tab = self.CharTable
    else
        tab = Local_Character
    end

    local it = GAMEMODE.Util:GetItemByDBID(tab, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(tab, item)
    end
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

    if ItemTable == nil then return false end

    if it.amount > 0 then return true end

    return false
end

function PMETA:HasCharItem(item, old)
    if item == nil then return false end

    local tab
    if SERVER then
        tab = self.CharTable
    else
        tab = Local_Character
    end

    local it = GAMEMODE.Util:GetItemByDBID(tab, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(tab, item)
    end
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

    if ItemTable == nil then return false end

    if it.amount > 0 then return true end

    return false
end

function PMETA:HasItem(item, old)
    if item == nil then return false end

    local tab
    if SERVER then
        tab = self.InvTable
    else
        tab = Local_Inventory
    end

    local it = GAMEMODE.Util:GetItemByDBID(tab, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(tab, item)
    end
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

    if ItemTable == nil then return false end

    if it.amount > 0 then return true end

    return false
end

function PMETA:GetItemAmount(item, bank, old)
    if item == nil then return 0 end
    local ItemTable, ItemKey

    local tab
    if SERVER then
        tab = self.InvTable
    else
        tab = Local_Inventory
    end

    if bank then
        if SERVER then
            tab = self.BankTable
        else
            tab = Local_Bank
        end
    end

    local it = GAMEMODE.Util:GetItemByDBID(tab, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(tab, item)
    end
    if !it then return 0 end

    return it.amount
end

DZ_ItemCats = {}
function GM.Util:GetItemCategories()
    DZ_ItemCats = {}

    if table.Count(DZ_ItemCats) < 1 then
        table.insert(DZ_ItemCats, "none") -- Let's just add the items without categories first, so they don't get autosorted below everything else.
        for item, tbl in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, "Category") do
            local cat = tbl.Category
            if !cat then continue end 
            if table.HasValue(DZ_ItemCats, cat) then continue end
            table.insert(DZ_ItemCats, cat)
        end
    end

    return DZ_ItemCats
end

ItemsByCat = {} -- we don't want autorefresh with this.
function GM.Util:GetItemsByCategory(value)
    ItemsByCat[value] = ItemsByCat[value] or {}
    if table.Count(ItemsByCat[value]) < 1 then
        local i = 1
        for k, v in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, "Category") do
            if ( v.Category or "none" ) != value then continue end
            
            ItemsByCat[value][i] = v
            i = i + 1
        end
    end

    return ItemsByCat[value]
end

ItemSort = {} -- we don't want autorefresh with this.
function GM.Util:ItemsSortByVal(value)
    ItemSort[value] = ItemSort[value] or {}
    if table.Count(ItemSort[value]) < 1 then
        local i = 1
        for k, v in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, value) do
            ItemSort[value][i] = v
            i = i + 1
        end
    end

    return ItemSort[value]
end

InventorySort = {}
function GM.Util:InventorySortByVal(ply, value)
    InventorySort[value] = InventorySort[value] or {}
    if table.Count(InventorySort[value]) < 1 then
        local i = 1
        local tab
        if SERVER then
            tab = ply.InvTable
        else
            tab = Local_Inventory
        end
        for k, v in SortedPairsByMemberValue(tab, value) do
            InventorySort[value][i] = v
            i = i + 1
        end
    end

    return InventorySort[value]
end

function GM.Util:GetPlayerByName(name)
    name = string.lower(name)

    for _, v in ipairs(player.GetHumans()) do
        if (string.find(string.lower(v:Name()), name, 1, true) ~= nil) then return v end
    end
end

function PMETA:IsVIP()
    return (table.HasValue(PHDayZ.VIPGroups, string.lower(self:GetHelperUserGroup())))
end

if not isfunction(PMETA.HasSkill) then
    function PMETA:HasSkill(skill)
        return false
    end
end

if not isfunction(PMETA.GetSkillPoints) then
    function PMETA:GetSkillPoints()
        return 0
    end
end

function AddAmmoType(name, text)
    game.AddAmmoType({
        name = name,
        dmgtype = DMG_BULLET
    })

    if CLIENT then
        language.Add(name .. "_ammo", text)
    end
end

hook.Add("DayZ_ItemsLoaded", "LoadAmmoTypes", function()
    for k, v in pairs(GAMEMODE.DayZ_Items) do
        if v.AmmoType then
            AddAmmoType(v.AmmoType, v.AmmoType .. " Ammo")
        end
    end
end)

-- Taken from TTT, thanks BadKingUrgrain
if CLIENT then
    function PMETA:AnimApplyGesture(act, weight)
        self:AnimRestartGesture(GESTURE_SLOT_CUSTOM, act, true)
        -- true = autokill
        self:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, weight)
    end

    local function MakeSimpleRunner(act)
        return function(ply, w)
            -- just let this gesture play itself and get out of its way
            if w == 0 then
                ply:AnimApplyGesture(act, 1)

                return 1
            else
                return 0
            end
        end
    end

    -- act -> gesture runner fn
    local act_runner = {
        [ACT_GMOD_IN_CHAT] = function(ply, w)
            -- ear grab needs weight control
            -- sadly it's currently the only one
            local dest = ply:IsSpeaking() and 1 or 0
            w = math.Approach(w, dest, FrameTime() * 10)

            if w > 0 then
                ply:AnimApplyGesture(ACT_GMOD_IN_CHAT, w)
            end

            return w
        end
    }

    -- Insert all the "simple" gestures that do not need weight control
    for _, a in pairs{ACT_GMOD_GESTURE_AGREE, ACT_GMOD_GESTURE_DISAGREE, ACT_GMOD_GESTURE_WAVE, ACT_GMOD_GESTURE_BECON, ACT_GMOD_GESTURE_BOW, ACT_GMOD_TAUNT_SALUTE, ACT_GMOD_TAUNT_CHEER, ACT_SIGNAL_FORWARD, ACT_SIGNAL_HALT, ACT_SIGNAL_GROUP, ACT_GMOD_GESTURE_ITEM_PLACE, ACT_GMOD_GESTURE_ITEM_DROP, ACT_GMOD_GESTURE_ITEM_GIVE, ACT_GMOD_GESTURE_POINT, ACT_GMOD_GESTURE_ITEM_THROW, ACT_GMOD_GESTURE_TAUNT_ZOMBIE, ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL, ACT_GMOD_GESTURE_RANGE_ZOMBIE, ACT_GMOD_GESTURE_RANGE_FRENZY, ACT_GMOD_GESTURE_POINT, ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND, ACT_GMOD_TAUNT_LAUGH, ACT_HL2MP_GESTURE_RELOAD_DUEL, ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL} do
        act_runner[a] = MakeSimpleRunner(a)
    end

    CreateConVar("ttt_show_gestures", "1", FCVAR_ARCHIVE)

    -- Perform the gesture using the GestureRunner system. If custom_runner is
    -- non-nil, it will be used instead of the default runner for the act.
    function PMETA:AnimPerformGesture(act, custom_runner)
        if GetConVarNumber("ttt_show_gestures") == 0 then return end
        local runner = custom_runner or act_runner[act]
        if not runner then return false end
        self.GestureWeight = 0
        self.GestureRunner = runner

        return true
    end

    -- Perform a gesture update
    function PMETA:AnimUpdateGesture()
        if self.GestureRunner then
            self.GestureWeight = self:GestureRunner(self.GestureWeight)

            if self.GestureWeight <= 0 then
                self.GestureRunner = nil
            end
        end
    end

    function GM:UpdateAnimation(ply, vel, maxseqgroundspeed)
        ply:AnimUpdateGesture()

        return self.BaseClass.UpdateAnimation(self, ply, vel, maxseqgroundspeed)
    end

    function GM:GrabEarAnimation(ply)
    end

    net.Receive("TTT_PerformGesture", function()
        local ply = net.ReadEntity()
        local act = net.ReadUInt(16)

        if IsValid(ply) and act then
            ply:AnimPerformGesture(act)
        end
    end)
else
    -- SERVER
    -- On the server, we just send the client a message that the player is
    -- performing a gesture. This allows the client to decide whether it should
    -- play, depending on eg. a cvar.
    function PMETA:AnimPerformGesture(act)
        if not act then return end
        net.Start("TTT_PerformGesture")
        net.WriteEntity(self)
        net.WriteUInt(act, 16)
        net.Broadcast()
    end
end

function GM:PlayerShouldTaunt(ply, actid)

    if !ply:CanPerformAction() then return false end
    if ply:Crouching() then return false end
    if prone and ply:IsProne() then return false end
    
    return true

end