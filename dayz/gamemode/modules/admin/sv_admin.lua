util.AddNetworkString("SendSpawnVectors")
util.AddNetworkString("SendVehicleVectors")
util.AddNetworkString("SendZombieVectors")
util.AddNetworkString("SendPlayerVectors")
util.AddNetworkString("dz_adminConfigUpdate")
util.AddNetworkString("net_adminPos")
util.AddNetworkString("net_adminPop")

net.Receive("dz_adminConfigUpdate", function(len, ply)
    if !ply:IsSuperAdmin() then return end
    local config = net.ReadTable()    

    PHDayZ = config

    MsgAll("[PHDayZ]", " Config file v"..config.version.." modified and reloaded by "..ply:Nick().."!\n")

    DZ_SaveConfig()
end)

function DZ_SaveConfig()
    file.Write("dayz/config.txt", util.TableToJSON(PHDayZ, true))

    net.Start( "PHDayZ_ConfigUpdate" )
        net.WriteTable( PHDayZ )
    net.Broadcast()

    if PHDayZ.scoreboardtitle != GetConVarString("hostname") then
        if PHDayZ.scoreboardhostname then
            MsgAll("Changing server hostname...\n")
            RunConsoleCommand("hostname", PHDayZ.scoreboardtitle)
        end
    end
end

local function RecursiveSetPreventTransmit(ent, ply, stopTransmitting)
    if ent ~= ply and IsValid(ent) and IsValid(ply) then
        ent:SetPreventTransmit(ply, stopTransmitting)
        local tab = ent:GetChildren()
        for i = 1, #tab do
            RecursiveSetPreventTransmit(tab[ i ], ply, stopTransmitting)
        end
    end
end

function StopNetworkingEntity(ply, bool, admin, target)

    if target and IsValid(target) then
        if ( admin and target:IsAdmin() ) and bool == true then return end
        

        RecursiveSetPreventTransmit(ply, target, bool)
        return
    end

    for k, v in pairs(player.GetAll()) do
        if ( admin and v:IsAdmin() ) and bool == true then continue end

        RecursiveSetPreventTransmit(ply, v, bool)
    end
end

local function colorSwep(ply, owep, nwep)
    if ply:GetMoveType() == MOVETYPE_NOCLIP && ( ply.nD or 0 ) < CurTime() then --admin mode

        ply.nD = CurTime() + 0.2
        timer.Simple(0, function()
            if !IsValid(ply) then return end
            if ply:GetMoveType() != MOVETYPE_NOCLIP then return end

            --for k, v in pairs( ply:GetWeapons() ) do
                nwep:SetNoDraw(true)
            --end
        end)
        
    end
end
hook.Add("PlayerSwitchWeapon", "CheckAdminMode", colorSwep)
hook.Remove("PlayerGiveSWEP", "CheckAdminMode")

local function makeFakeAdmin(ply)
    local ply_pos, ply_ang = ply:GetPos(), ply:GetAngles()

    local admins = {}
    for k, v in pairs(player.GetAll()) do
        if !v:IsAdmin() and !v:IsSuperAdmin() then continue end

        table.insert(admins, v) 
    end

    net.Start("net_adminPos")
        net.WriteEntity( ply )
        net.WriteVector( ply_pos )
        net.WriteAngle( ply_ang )
    net.Send( admins )
end

local function popFakeAdmin(ply)
    net.Start("net_adminPop")
        net.WriteEntity( ply )
    net.Broadcast( )
end

function doMsg(msg, ply)
    local isconsole = ply:EntIndex() == 0 and true or false

    if isconsole then
        print(msg)
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    end
end

local function dz_who(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    --if not isconsole and not ply:IsSuperAdmin() then return end
    
    local msg = "ID\tUserID\tSteamID\t\t\tSteamName\tRPName"

    if args[1] then
        if !( isconsole or ply:IsAdmin() ) then ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Only Admins can query the database for user info!") return end 
        msg = "ID\tSteamID\t\t\tRPName"

        PLib:RunPreparedQuery({
        sql = "SELECT * FROM `players` WHERE `lastnick` LIKE '%"..args[1].."%';",
        callback = function(data)
                    
            doMsg("---------------------------------------------------------------------", ply)
            doMsg(msg, ply)
            doMsg("---------------------------------------------------------------------", ply)

            msg = "No Players found with rpname '" .. args[1] .. "'!\n"

            if data[1] == nil then
                doMsg(msg, ply)
            else
                if #data > 50 then
                    msg = "More than 50 Players found with rpname '" .. args[1] .. "', narrow your search criteria!\n"
                    doMsg(msg, ply)
                    return
                end
                for i = 1, #data do
                    local id = data[ i ][ "id" ]
                    local steamid = data[ i ][ "steamid" ]
                    local rpname = data[ i ][ "lastnick" ]
                    
                    msg = id.."\t"..steamid.."\t"..rpname
                    doMsg(msg, ply)                                      
                end
            end
        end })
        return
    end

    doMsg("---------------------------------------------------------------------", ply)
    doMsg(msg, ply)
    doMsg("---------------------------------------------------------------------", ply)

    for k, v in pairs(player.GetAll()) do
        msg = (v.ID or "NEW").."\t"..v:UserID().."\t"..v:SteamID().."\t" .. v:Nick(true) .. "\t" .. v:Nick()

        doMsg(msg, ply)
    end
end
concommand.Add("dz_who", dz_who)

local function ToggleNet(ply, cmd, args)
    if !ply:IsAdmin() then return end

    ply.Admin_Nonetwork = ply.Admin_Nonetwork or false

    ply.Admin_Nonetwork = !ply.Admin_Nonetwork

    if ply:GetMoveType() != MOVETYPE_NOCLIP then return end -- ignore if not in noclip because networking already ran

    if ply.Admin_Nonetwork == true then

        makeFakeAdmin(ply)

        StopNetworkingEntity(ply, true, true)
    else
        popFakeAdmin(ply)
 
        StopNetworkingEntity(ply, false)
    end
end
concommand.Add("dz_admintogglenet", ToggleNet)

local function DoClipFunc(ply, state)
    if state then

        if ply.Admin_Nonetwork then
            makeFakeAdmin(ply)

            StopNetworkingEntity(ply, true, true)
        end

        ply:SetMoveType(MOVETYPE_NOCLIP)

        ply:GodEnable()

        ply:DrawShadow(false)
        ply:SetColor(Color(255, 255, 255, 0))
        ply:SetKeyValue("rendermode", RENDERMODE_NONE)
        ply:SetKeyValue("renderamt", "0")

        -- patch for admin mode showing weapons
        for k, v in pairs(ply:GetWeapons()) do
            v:SetNoDraw(true)
        end

        ply.CantLoot = true
        ply.Noclip = true
        timer.Remove(ply:UniqueID() .. "NoLooting")
        ply:SetPVPTime(0)

        if !ply:IsPhoenix() then
            MsgAll("["..os.date( "%H:%M:%S" , os.time() ).."] "..ply:Nick().." entered admin mode!\n")
        end

        ply:AddFlags(FL_NOTARGET) -- NPC Ignore

    else
        ply:GodDisable()

        ply:SetKeyValue("rendermode", RENDERMODE_NORMAL)
        ply:SetKeyValue("renderamt", "255")

        -- show weapons that were hidden
        for k, v in pairs(ply:GetWeapons()) do
            v:SetNoDraw(false)
        end

        popFakeAdmin(ply)

        ply:DrawShadow(true)
        verse = "exited"
        StopNetworkingEntity(ply, false)
        timer.Remove( ply:EntIndex().."_noclip" )
        ply:SetColor(Color(255, 255, 255, 255))
        ply.Noclip = false

        timer.Create(ply:UniqueID() .. "NoLooting", 10, 0, function()
            if not ply:IsValid() then return end
            ply.CantLoot = false
        end)

        if !ply:IsPhoenix() then
            MsgAll("["..os.date( "%H:%M:%S" , os.time() ).."] "..ply:Nick().." exited admin mode!\n")
        end

        ply:RemoveFlags(FL_NOTARGET) -- NPC Stop Ignore
    end
end

function GM:PlayerNoClip(ply, state)
    if ply:IsAdmin() then
        local verse = "entered"
        if state then
            if !ply:CanPerformAction() then return false end

            if ply:IsPhoenix() or ( PHDayZ.AdminModeTimer or 0 ) == 0 then
                DoClipFunc(ply, state)
                return
            end

            ply:DoModelProcess(ply:GetModel(), "Entering Admin Mode", PHDayZ.AdminModeTimer or 5, "", 0, "", true, function(ply)
                DoClipFunc(ply, state)
            end)

        else
            DoClipFunc(ply, state)
            return true -- to allow exiting noclip
        end
    end

    return false
end

local function SendUpdates(ply)
    net.Start("SendSpawnVectors")
    net.WriteTable(LootVectors[string.lower(game.GetMap())])
    net.Send(ply)
    net.Start("SendVehicleVectors")
    net.WriteTable(VehicleSpawns[string.lower(game.GetMap())])
    net.Send(ply)
    net.Start("SendPlayerVectors")
    net.WriteTable(Spawns[string.lower(game.GetMap())])
    net.Send(ply)
    net.Start("SendZombieVectors")
    net.WriteTable(ZombieSpawns[string.lower(game.GetMap())])
    net.Send(ply)
    hook.Run("DZ_SendMapSpawnUpdate", ply)
end

local function RequestSpawns(ply)
    if ply:EntIndex() == 0 then return end
    if not ply:IsAdmin() then return end
    -- If it's ran from command.
    SendUpdates(ply)
end

concommand.Add("dz_requestspawns", RequestSpawns)
DZ_AddSpawntypes = DZ_AddSpawntypes or {"basic", "food", "weapon", "medical", "industrial", "hat", "player", "zombie", "hl2jeep", "helicopter"}
local lootnames = {}
lootnames["basic"] = 1
lootnames["food"] = 2
lootnames["industrial"] = 3
lootnames["medical"] = 4
lootnames["weapon"] = 5
lootnames["hat"] = 6
local lootfnames = {}
lootfnames[1] = "basic"
lootfnames[2] = "food"
lootfnames[3] = "industrial"
lootfnames[4] = "medical"
lootfnames[5] = "weapon"
lootfnames[6] = "hat"
local vehiclenames = {}
vehiclenames["hl2jeep"] = 1
vehiclenames["helicopter"] = 2
local vehfnames = {}
vehfnames[1] = "hl2jeep"
vehfnames[2] = "helicopter"

local function AddSpawn(ply, cmd, args)
    if ply:EntIndex() == 0 then return end
    if not ply:IsAdmin() then return end
    -- If it's ran from command.
    local spawntype = args[1] or "none"

    if not table.HasValue(DZ_AddSpawntypes, string.lower(spawntype)) then
        ply:PrintMessage(HUD_PRINTTALK, "Spawntype " .. spawntype .. " is invalid!")
        ply:PrintMessage(HUD_PRINTTALK, "Valid spawntypes are: " .. table.concat(DZ_AddSpawntypes, ", "))

        return
    end

    local tr = ply:GetEyeTraceNoCursor()

    if lootnames[spawntype] then
        table.insert(LootVectors[string.lower(game.GetMap())][lootnames[spawntype]], tr.HitPos)
        file.Write("dayz/spawns_loot/" .. spawntype .. "/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(LootVectors[string.lower(game.GetMap())][lootnames[spawntype]], true))
    elseif vehiclenames[spawntype] then
        table.insert(VehicleSpawns[string.lower(game.GetMap())][vehiclenames[spawntype]], tr.HitPos)
        file.Write("dayz/spawns_vehicle/" .. spawntype .. "/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(VehicleSpawns[string.lower(game.GetMap())][vehiclenames[spawntype]], true))
    elseif spawntype == "player" then
        table.insert(Spawns[string.lower(game.GetMap())], tr.HitPos)
        file.Write("dayz/spawns_player/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(Spawns[string.lower(game.GetMap())], true))
    elseif spawntype == "zombie" then
        table.insert(ZombieSpawns[string.lower(game.GetMap())], tr.HitPos)
        file.Write("dayz/spawns_zombie/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(ZombieSpawns[string.lower(game.GetMap())], true))
    end

    //ply:PrintMessage(HUD_PRINTTALK, "Added " .. spawntype .. " spawn.")
    hook.Run("DZ_AddSpawn", ply, tr.HitPos, spawntype)

    for k, v in pairs(player.GetAll()) do
        if v:IsAdmin() then
            SendUpdates(v)
        end
    end
end

concommand.Add("dz_addspawn", AddSpawn)

local function AddInteractable(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTraceNoCursor()
    local pos = tr.HitPos

    local int = ents.Create("dz_interactable")
    local models = {}
    models[1] = "models/raviool/bartable.mdl"
    models[2] = "models/dayz/misc/dayz_campfire.mdl"
    models[3] = "models/Combine_Helicopter/helicopter_bomb01.mdl"
    models[4] = "models/props_junk/trafficcone001a.mdl"
    local m = models[1]
    int.itType = 1
    if args[1] then
        m = models[ tonumber(args[1]) ]
        int.itType = tonumber(args[1])
    end

    int:SetModel(m)
    int:SetPos( pos + Vector(0,0,20))
    int:Spawn()

    int:Activate()
end
concommand.Add("dz_makeinteractable", AddInteractable)

local function SavePersist(ply, cmd, args)
    if not ply:IsAdmin() then return end

    PrintMessage(HUD_PRINTTALK, "[PHDayZ] "..ply:Nick().." forced Persistence Save... saving! Don't worry. This isn't a crash...")
    timer.Simple(1, function() hook.Run("PersistenceSave") PrintMessage(HUD_PRINTTALK, "[PHDayZ] Saved Everything!") end)

end
concommand.Add("dz_savepersist", SavePersist)

local function GoBoom(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTraceNoCursor()
    local pos = tr.HitPos

    util.BlastDamage( Entity(0), Entity(0), pos, 300, 500 )

end
concommand.Add("dz_boom", GoBoom)

local function ShiftZones(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end

    for k, v in pairs(ents.GetAll()) do
        if v:GetClass() == "safezone" or ( v:GetClass() == "radzone" && args[4] ) then

            v:SetPos( v:GetPos() + Vector( args[1], args[2], args[3] ) )
        
        end
    end

    ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Moved zones!")
end
concommand.Add("dz_shiftz", ShiftZones)


local function ShiftPersistency(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end

    for k, v in pairs(ents.GetAll()) do
        if !v:GetPersistent() then continue end

        v:SetPos( v:GetPos() + Vector( args[1], args[2], args[3] ) )

    end

    ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] Moved persistent props!")
end
concommand.Add("dz_shiftp", ShiftPersistency)

local function RemoveSpawn(ply, cmd, args)
    if ply:EntIndex() == 0 then return end
    if not ply:IsAdmin() then return end
    -- If it's ran from command.
    local tr = ply:GetEyeTraceNoCursor()
    local foundvector = false
    local foundtype = 0
    local foldername = "none"

local debug_vector = true
local debug_store = 1000000000000000000
local less_vector = 3 * 5000.0

    for i = 1, #LootVectors[string.lower(game.GetMap())] do
        for k, v in pairs(LootVectors[string.lower(game.GetMap())][i]) do
            if debug_vector then
                if tr.HitPos:DistToSqr(v) < debug_store then
                    debug_store = tr.HitPos:DistToSqr(v)
                end
            end
            if tr.HitPos:DistToSqr(v) < less_vector then
                print(tr.HitPos:DistToSqr(v))
                foundvector = v
                foundtype = 1
                foldername = lootfnames[i]
                --MsgAll(foldername .. " " .. foundtype)
                break
            end
        end
    end

    if not foundvector then
        for i = 1, #VehicleSpawns[string.lower(game.GetMap())] do
            for k, v in pairs(VehicleSpawns[string.lower(game.GetMap())][i]) do
            if debug_vector then
                if tr.HitPos:DistToSqr(v) < debug_store then
                    debug_store = tr.HitPos:DistToSqr(v)
                end
            end
            if debug_vector then
                if tr.HitPos:DistToSqr(v) < debug_store then
                    debug_store = tr.HitPos:DistToSqr(v)
                end
            end
                if tr.HitPos:DistToSqr(v) < less_vector then
                    foundvector = v
                    foundtype = 2
                    foldername = vehfnames[i]
                    break
                end
            end
        end
    end

    if not foundvector then
        for k, v in pairs(Spawns[string.lower(game.GetMap())]) do
        if debug_vector then
                if tr.HitPos:DistToSqr(v) < debug_store then
                    debug_store = tr.HitPos:DistToSqr(v)
                end
            end
            if tr.HitPos:DistToSqr(v) < less_vector then
                foundvector = v
                foundtype = 3
                break
            end
        end
    end

    if not foundvector then
        for k, v in pairs(ZombieSpawns[string.lower(game.GetMap())]) do
            if tr.HitPos:DistToSqr(v) < less_vector then
                foundvector = v
                foundtype = 4
                break
            end
        end
    end

if debug_vector then
    print(debug_store)
end

ply:ChatPrint("Type: "..foundtype.." | Position: "..tostring(tr.HitPos).." \n Nearest spawn point: "..debug_store.." | You need less than: "..less_vector)

    if foundtype == 1 then
        table.RemoveByValue(LootVectors[string.lower(game.GetMap())][lootnames[foldername]], foundvector)
        file.Write("dayz/spawns_loot/" .. foldername .. "/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(LootVectors[string.lower(game.GetMap())][lootnames[foldername]], true))
        ply:PrintMessage(HUD_PRINTTALK, "Removed LootSpawn successfully!")
    elseif foundtype == 2 then
        table.RemoveByValue(VehicleSpawns[string.lower(game.GetMap())][vehiclenames[foldername]], foundvector)
        file.Write("dayz/spawns_vehicle/" .. foldername .. "/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(VehicleSpawns[string.lower(game.GetMap())][vehiclenames[foldername]], true))
        ply:PrintMessage(HUD_PRINTTALK, "Removed VehicleSpawn successfully!")
    elseif foundtype == 3 then
        table.RemoveByValue(Spawns[string.lower(game.GetMap())], foundvector)
        file.Write("dayz/spawns_player/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(Spawns[string.lower(game.GetMap())], true))
        ply:PrintMessage(HUD_PRINTTALK, "Removed PlayerSpawn successfully!")
    elseif foundtype == 4 then
        table.RemoveByValue(ZombieSpawns[string.lower(game.GetMap())], foundvector)
        file.Write("dayz/spawns_zombie/" .. string.lower(game.GetMap()) .. ".txt", util.TableToJSON(ZombieSpawns[string.lower(game.GetMap())], true))
        ply:PrintMessage(HUD_PRINTTALK, "Removed ZombieSpawn successfully!")
    end

    hook.Run("DZ_RemoveSpawn", ply, tr.HitPos)

    for k, v in pairs(player.GetAll()) do
        if v:IsAdmin() then
            SendUpdates(v)
        end
    end
end

concommand.Add("dz_removespawn", RemoveSpawn)

local function BecomeProp(ply, cmd, args)
    if !ply:IsAdmin() then return end

    local tr = ply:GetEyeTraceNoCursor()
    local ent = tr.Entity

    if !IsValid(ent) then ply:PrintMessage(HUD_PRINTCONSOLE, "dz_turnprop: Invalid entity!") return end

    if ent:GetPersistent() then ply:PrintMessage(HUD_PRINTCONSOLE, "dz_turnprop: Entity is persistent! Cancelling...") return end

    local ent2 = ents.Create("prop_physics")
    ent2:SetModel( ent:GetModel() )
    ent2:SetPos( ent:GetPos() )
    ent2:SetAngles( ent:GetAngles() )
    ent:Remove()
    
    ent2:Spawn()

    local phys = ent2:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    ent2:SetPersistent(true)

    ply:PrintMessage(HUD_PRINTCONSOLE, "dz_turnprop: Converted to prop_physics entity and set persistent!")

end
concommand.Add("dz_turnprop", BecomeProp)

local function BecomeLootable(ply, cmd, args)
    if !ply:IsAdmin() then return end

    local tr = ply:GetEyeTraceNoCursor()
    local ent = tr.Entity

    if !IsValid(ent) then ply:Tip(3, "dz_turnlootable: Invalid entity!", Color(255,0,0,255)) return end
    if ent:GetClass() != "prop_physics" then ply:Tip(3, "dz_turnlootable: Invalid entity (prop_physics only)!", Color(255,0,0,255)) return end

    if ent:GetPersistent() then ply:Tip(3, "dz_turnlootable: Entity is persistent! Cancelling...", Color(255,0,0,255)) return end

    local categories = PHDayZ.LootableItemSetup[ ent:GetModel() ]

    if !categories or table.Count(categories) < 1 then ply:Tip(3, "dz_turnlootable: Warning, "..ent:GetModel().." has no setup PHDayZ.LootableItemSetup entry, defaults to all SpawnChance>0 items!", Color(255,255,0,255)) end

    local ent2 = ents.Create("base_lootable")
    ent2:SetModel( ent:GetModel() )
    ent2:SetPos( ent:GetPos() )
    ent2:SetAngles( ent:GetAngles() )
    ent:Remove()
    
    ent2:Spawn()

    local phys = ent2:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    ent2:SetPersistent(true)

    ply:Tip(3, "dz_turnlootable: Converted to lootable entity and set persistent!", Color(0,255,0,255))

end
concommand.Add("dz_turnlootable", BecomeLootable)

local function SetInitialSpawn(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    PHDayZ.InitialSpawnPoints[ string.lower( game.GetMap() ) ] = ply:GetPos()

    DZ_SaveConfig()

    ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] InitialSpawnPoint config value updated and saved for "..game.GetMap().."!")
end
concommand.Add("dz_setinitialspawn", SetInitialSpawn)

local function SetArenaPos(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    PHDayZ.SafeZoneArenaPos[ string.lower( game.GetMap() ) ] = ply:GetPos()
    
    DZ_SaveConfig()

    ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] SafeZoneArenaPos config value updated and saved for "..game.GetMap().."!")
end
concommand.Add("dz_setarenapos", SetArenaPos)


local function SetSZTeleportPos(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end

    PHDayZ.SafeZoneTeleportPoses[ string.lower( game.GetMap() ) ] = ply:GetPos()
    
    DZ_SaveConfig()

    ply:PrintMessage(HUD_PRINTCONSOLE, "[PHDayZ] SafeZoneTeleportPos config value updated and saved for "..game.GetMap().."!")
end
concommand.Add("dz_setszteleportpos", SetSZTeleportPos)

local function MakeItem(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
    local tr = ply:GetEyeTraceNoCursor()
    
    local ItemKey = args[1]
    local ItemTable = GAMEMODE.DayZ_Items[ItemKey]

    if not ItemTable then
        ply:PrintMessage(HUD_PRINTCONSOLE, "This item doesn't exist!\n")

        return
    end

    local itement = ents.Create("base_item")
    itement:SetItem(ItemKey)
    itement:SetPos( tr.HitPos + Vector(0, 0, 100) )
    itement.Amount = ItemTable.ClipSize or 1
    itement:SetAmount(itement.Amount)

    if ItemTable.SpawnAngle then
        itement:SetAngles(ItemTable.SpawnAngle)
    end

    itement:SetSaveValue("fademindist", 256)
    itement:SetQuality(args[2] or 500)
    itement:SetRarity(args[3] or 1)
    itement:SetSaveValue("fademaxdist", 2048)
    itement:Spawn()
    itement.SpawnLoot = true
    //local height = itement:OBBMins()
    //itement:SetPos(itement:GetPos() - Vector(0, 0, height[3]))
end

concommand.Add("dz_makeitem", MakeItem)

local function MakeZombie(ply, cmd, args)
    if not ply:IsSuperAdmin() or not ( PHDayZ.MakeNPCEnabled and ply:IsAdmin() ) then return end
    local tr = ply:GetEyeTraceNoCursor()
    if !tr.HitPos then return end
    local z = args[1] or nil
    local wep = args[2] or nil
    local lvl = args[3] or nil
    SpawnAZombie(tr.HitPos + Vector(0,0,10), true, ply, z, nil, wep, lvl)
end

concommand.Add("dz_makezombie", MakeZombie)
concommand.Add("dz_makenpc", MakeZombie)

local function RemoveAllBluePrints(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    local target = args[1]

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    PLib:QuickQuery("DELETE FROM `players_blueprints` where `user_id` = " .. target.ID .. ";")
    target.BPTable = {}
    target:SendBluePrints()
end

concommand.Add("dz_removeallblueprints", RemoveAllBluePrints)

function GiveAllBP(ply)
    for k, v in pairs(GAMEMODE.DayZ_Items) do
        if v.NoBlueprint then continue end
        ply:GiveBluePrint(k, true)
    end

    ply:SendBluePrints()
end

local function GiveAllBluePrints(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    local target = args[1]

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    GiveAllBP(target)
end

concommand.Add("dz_giveallblueprints", GiveAllBluePrints)

function DZ_GiveAmmo(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    local target = args[1]

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    local wep = target:GetActiveWeapon()
    if !IsValid(wep) then return end
    if !wep.item then return end
    if !wep.Primary.AmmoItem then return end

    target:GiveItem(wep.Primary.AmmoItem, args[2], 500, 500)
end
concommand.Add("dz_giveammo", DZ_GiveAmmo)

local function printprop(ply, cmd, args)
    local tbl = {}

    local tr = ply:GetEyeTraceNoCursor()
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local mdl = ent:GetModel()
    local pos = ent:GetPos()
    local ang = ent:GetAngles()

    MsgAll("mdl = \"" .. mdl .. "\"\n")
    MsgAll("pos = " .. tostring(pos[1]) .. " " .. tostring(pos[2]) .. ", " .. tostring(pos[3]) .. "\n")
    MsgAll("ang = " .. tostring(ang[1]) .. " " .. tostring(ang[2]) .. " " .. tostring(ang[3]) .. "\n")
    
end
concommand.Add("dz_printprop", printprop)

local function DZ_PrintItems(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end

    if isconsole then
        print("========START ITEM LIST=========")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "========START ITEM LIST=========")
    end

    local NewCategory = ""

    for k, v in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, "Category") do
        local category = v.Category or "None"

        if NewCategory ~= category then
            if isconsole then
                print("===========================")
                print(string.upper(category) .. ":\n")
                print("===========================")
            else
                ply:PrintMessage(HUD_PRINTCONSOLE, "===========================")
                ply:PrintMessage(HUD_PRINTCONSOLE, string.upper(category) .. ":\n")
                ply:PrintMessage(HUD_PRINTCONSOLE, "===========================")
            end
        end

        NewCategory = category

        if isconsole then
            print(k.." - "..GAMEMODE.DayZ_Items[k].Name)
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, k.." - "..GAMEMODE.DayZ_Items[k].Name)
        end
    end

    if isconsole then
        print("========END ITEM LIST=========")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "========END ITEM LIST=========")
    end

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_printitems")
    end
end

concommand.Add("dz_printitems", DZ_PrintItems)

local function DZ_SetHealth(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end
    local target = args[1]
    local amount = math.Clamp(tonumber(args[2]), 0, 100)

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    if not amount or not isnumber(amount) then
        if isconsole then
            print("No amount specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No amount specified.")
        end

        return
    end

    if isconsole then
        MsgN(ply:Nick() .. " set " .. target:Nick() .. "'s health to " .. amount)
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You set " .. target:Nick() .. "'s health to " .. amount)
    end

    target:SetRealHealth(amount)

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_sethealth with args: " .. table.concat(args, " "))
    end
end

concommand.Add("dz_sethealth", DZ_SetHealth)

local function DZ_MaxNeeds(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end
    local target = args[1]

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    if isconsole then
        MsgN(ply:Nick() .. " maxed " .. target:Nick() .. "'s needs")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You maxed " .. target:Nick() .. "'s needs")
    end

    target:SetHunger(1000)
    target:SetThirst(1000)
    target:SetRealHealth(100)
    target:SetBleed(false)
    target:SetSick(false)
    target:SetHealth(target:GetMaxHealth())

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_maxneeds with args: " .. table.concat(args, " "))
    end  
end
concommand.Add("dz_maxneeds", DZ_MaxNeeds)

local function DZ_SetHunger(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end
    local target = args[1]
    local amount = math.Clamp(tonumber(args[2]), 0, 1000)

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    if not amount or not isnumber(amount) then
        if isconsole then
            print("No amount specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No amount specified.")
        end

        return
    end

    if isconsole then
        MsgN(ply:Nick() .. " set " .. target:Nick() .. "'s thirst to " .. amount)
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You set " .. target:Nick() .. "'s hunger to " .. amount)
    end

    target:SetHunger(amount)

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_sethunger with args: " .. table.concat(args, " "))
    end
end

concommand.Add("dz_sethunger", DZ_SetHunger)

local function DZ_SetThirst(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsAdmin() then return end
    local target = args[1]
    local amount = math.Clamp(tonumber(args[2]), 0, 1000)

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    if not amount or not isnumber(amount) then
        if isconsole then
            print("No amount specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No amount specified.")
        end

        return
    end

    if isconsole then
        MsgN(ply:Nick() .. " set " .. target:Nick() .. "'s thirst to " .. amount)
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You set " .. target:Nick() .. "'s thirst to " .. amount)
    end

    target:SetThirst(amount)

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_setthirst with args: " .. table.concat(args, " "))
    end
end

concommand.Add("dz_setthirst", DZ_SetThirst)

local function DZ_ResetPlayer(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    local target = args[1]

    if target then
        target = GAMEMODE.Util:GetPlayerByName(target)
    end

    if not target then
        if isconsole then
            print("No Target specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No target specified.")
        end

        return
    end

    reset_ent(target)

    if isconsole then
        print(target:Nick() .. "'s account has been wiped!")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, target:Nick() .. "'s account has been wiped!")
    end
end

concommand.Add("dz_resetplayer", DZ_ResetPlayer)

local function DZ_ResetSteamID(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    local steamid = args[1]

    --if target then target = GAMEMODE.Util:GetPlayerByName(target) end
    if not steamid then
        if isconsole then
            print("No SteamID specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No SteamID specified.")
        end

        return
    end

    local plyfound

    for k, v in pairs(player.GetAll()) do
        if v:SteamID() == steamid then
            plyfound = v
            break
        end
    end

    if plyfound then
        reset_ent(plyfound)

        if isconsole then
            print(plyfound:Nick() .. "'s account has been wiped!")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, plyfound:Nick() .. "'s account has been wiped!")
        end

        return
    end

    reset_steamid(steamid)

    if isconsole then
        print("Account '" .. steamid .. "' has been wiped!")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "Account '" .. steamid .. "' has been wiped!")
    end
end

concommand.Add("dz_resetid", DZ_ResetSteamID)

-- Example: dz_giveitem item_credits 1000 phoenixf129
-- Not specifying a player gives them to you.
local function DZ_GiveItem(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end
    -- Allows from console, if player is not admin etc.
    local item, amount, targetply, target, cond, rarity = args[1], tonumber(args[2]), ply, args[3], 700, 1
    if args[4] then
        cond = tonumber(args[4])
    end
    if args[5] then
        rarity = tonumber(args[5])
    end

    if ply:EntIndex() == 0 and not target then
        print("No Target specified. You cannot give items to console!")

        return
    end

    if target then
        targetply = GAMEMODE.Util:GetPlayerByName(target) or ply
    end

    if not item then
        if isconsole then
            MsgN("No item specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No item specified.")
        end

        return
    end

    if not amount or not isnumber(amount) then
        if isconsole then
            MsgN("No amount specified.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No amount specified.")
        end

        return
    end

    local ItemTable, ItemKey

    if isnumber(item) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[item], item
    elseif (isstring(item)) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID(item)
    end

    if ItemTable == nil then
        if isconsole then
            MsgN("No Item found with that name/number.")
        else
            ply:PrintMessage(HUD_PRINTCONSOLE, "No Item found with that name/number.")
        end

        return
    end
    
    targetply:GiveItem(ItemKey, amount, true, cond, rarity, nil, nil, true)

    if isconsole then
        MsgN(ItemTable.Name .. " with count " .. amount .. " has been added to the account.")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, ItemTable.Name .. " with count " .. amount .. " has been added to the account.")
    end

    if not isconsole then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_giveitem with args: " .. table.concat(args, " "))
    end
end

concommand.Add("dz_giveitem", DZ_GiveItem)

-- Example: q
-- Description: Gives a non-connected player credits. 
function DZ_GiveItemID(ply, cmd, args)
    local isconsole = ply:EntIndex() == 0 and true or false
    if not isconsole and not ply:IsSuperAdmin() then return end

    local item, amount, steamid, id, cond, rarity = args[1], tonumber(args[2]), args[3], 0, 700, 1
    if args[4] then
        cond = tonumber(args[4])
    end
    if args[5] then
        rarity = tonumber(args[5])
    end

    -- Allows from console, if player is not admin etc.
    if not steamid or not item or (not amount or not isnumber(amount)) then
        print("[PHDayZ] 'dz_giveitemid' Invalid arguments supplied!")
        return
    end

    local foundply

    for k, v in pairs(player.GetAll()) do
        if v:SteamID() == steamid then
            foundply = v
            break
        end
    end

    PLib:RunPreparedQuery({
        sql = "SELECT * FROM `players` WHERE `steamid` = '" .. steamid .. "';",
        callback = function(dat)
            if dat[1] == nil then
                print("Player " .. steamid .. " doesn't exist in the database! They've never joined the server!")
            else
                dat = dat[1]
                local id = dat["id"]
                -- The player's unique ID.
                local ItemTable, ItemKey

                if isnumber(item) then
                    ItemTable, ItemKey = GAMEMODE.DayZ_Items[item], item
                elseif (isstring(item)) then
                    ItemTable, ItemKey = GAMEMODE.Util:GetItemByID(item)
                end

                local CurItemAmount = 0

                local rarity = rarity

                local ins = DZ_GetLastInsert("players_inventory")

                local function itupdate(lastInsert)
                    local it = {}
                    it.id = lastInsert
                    it.class = ItemKey
                    it.amount = amount
                    it.quality = cond
                    it.rarity = rarity

                    if foundply then
                        foundply:Tip(3, "Inventory updated! " .. ItemTable.Name .. " x" .. amount .. " applied!")

                        foundply.InvTable[ItemKey] = foundply.InvTable[ItemKey] or {}
                        foundply.InvTable[ItemKey][it.id] = it
                        foundply:UpdateItem( it )
                    end
                end
                --itupdate( ins )

                PLib:RunPreparedQuery({ sql = "INSERT INTO `players_inventory` ( `user_id`, `item`, `amount`, `quality`, `durability` ) VALUES ( " .. id .. ", '" .. ItemKey .. "', " .. amount .. ", 800, ".. rarity .." );", 
                callback = function( data )
                    itupdate(data)
                end })
                
                DZ_AddPredictedInsert("players_inventory") -- add 1 as we are about to update

                print("[PHDayZ] '" .. ItemTable.Name .. "' x" .. amount .. " applied to account '" .. steamid .. "' (" .. id .. ")!\n")
            end
        end
    })

    if ply:EntIndex() ~= 0 then
        DzLog(2, "Player '" .. ply:Nick() .. "'(" .. ply:SteamID() .. ") ran dz_giveitemid with args: " .. table.concat(args, " "))
    end
end

concommand.Add("dz_giveitemid", DZ_GiveItemID)

local function DZ_Toolgun(ply)
    if ply:IsAdmin() then
        if ply:HasWeapon("gmod_tool") then
            ply:StripWeapon("gmod_tool")
        else
            ply:Give("gmod_tool")
        end
    end
end

concommand.Add("dz_toolgun", DZ_Toolgun)

function PlayerPickup(ply, ent)
    --If the player is a super admin, and the entity is a player
    if ply:IsAdmin() and ent:IsPlayer() then
        ent:GodEnable()

        return true
    end
end

-- Allow pickup
hook.Add("PhysgunPickup", "AllowPlayerPickup", PlayerPickup)

function PhysgunDrop(ply, ent)
    --If the player is a super admin, and the entity is a player
    if ply:IsAdmin() and ent:IsPlayer() then
        ent:GodDisable()
    end
end

hook.Add("PhysgunDrop", "AllowPlayerPickup", PhysgunDrop)

local function up( ply, ent )
    return true
end
hook.Add( "AllowPlayerPickup", "some_unique_name", up )