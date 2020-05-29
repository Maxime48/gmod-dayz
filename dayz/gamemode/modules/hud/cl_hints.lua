local XpAddInc = false
local XPAlpha = 0
local XP_Amount = 0
local LevelDesc = ""
local LevelUpInc = false
local LevelUpAlpha = 0

function HINTPaint()
    if LocalPlayer():IsValid() then
        if XpAddInc == true then
            XPAlpha = XPAlpha + 3
        else
            if XPAlpha > 0 then
                XPAlpha = XPAlpha - 3
            else
                XP_Amount = 0
                XP_Name = ""
            end
        end

        if XPAlpha > 255 then XPAlpha = 255 end

        if IsValid(HotBarPanel) && XPAlpha > 0 then
            
            local x, y = HotBarPanel:GetPos()
            if IsValid(HotBarPanel.XPBar) then
                x = x + ( HotBarPanel.XPBar.XPS or 0 )
            end

            local groupie = ""
            if XP_Name != "" then
                groupie = " ( "..XP_Name.." )"
            end

            draw.DrawText("+" .. XP_Amount .. "XP"..groupie, "char_title16", x + 5, y - 16, Color(255, 255, 0, XPAlpha), TEXT_ALIGN_LEFT)

        end

        -- Levelling up.        
        if LevelUpInc == true then
            -- Level up
            --UpdateLevels()

            if LevelUpAlpha < 255 then
                LevelUpAlpha = LevelUpAlpha + 1
            end

            XpAddInc = false
            XPAlpha = 0

        else
            if LevelUpAlpha > 0 then
                LevelUpAlpha = LevelUpAlpha - 1
            end
        end


        if IsValid(HotBarPanel) then
            local x, y = HotBarPanel:GetPos()            
            draw.DrawText( "++Level Up!", "char_title16", x + 5, y - 20, Color( 255, 255, 0, LevelUpAlpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

            if LevelDesc != "" then
                draw.DrawText( "+ "..LevelDesc, "char_title16", x + 5, y - 40, Color( 255, 255, 0, LevelUpAlpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
            end
        end

    end
end

hook.Add("HUDPaint", "PaintOurHint", HINTPaint)

XP_Name = XP_Name or ""
net.Receive("net_XPAward", function(len)
    
    XP_Amount = XP_Amount + net.ReadFloat()
    XpAddInc = true
    XP_Name = ""

    local teammate = net.ReadString() or ""
    if teammate != "" && teammate != LocalPlayer():Nick() then
        XP_Name = teammate
    end

    timer.Create("xp_destroy", 4, 1, function()
        XpAddInc = false
    end)
end)

net.Receive("net_LevelUp", function(len)
    LevelUpInc = true

    XPBar_XPSmooth = 0

    timer.Simple(6, function()
        LevelUpInc = false
    end)
end)

net.Receive("net_AddUnlock", function(len)
    LevelDesc = net.ReadString() or ""
    LevelUpInc = true

    timer.Simple(6, function()
        LevelUpInc = false
        LevelDesc = ""
    end)
end)

local TipPanels = {}

-- Stacker table.
net.Receive("TipSendParams", function(len)
    local tab = net.ReadTable()
    local icontype = tab[1]
    local str = ""
    local color = Color(255, 255, 255)

    for k, v in pairs(tab) do
        if not isnumber(v) then
            str = str .. " " .. (LANG.TryTranslation(v) or v)
        elseif isnumber(v) then
            icontype = v
        else
            color = v
        end
    end

    surface.SetFont("Cyb_HudTEXT")
    local s1 = surface.GetTextSize(str)
    local tippanel = vgui.Create("DPanel")
    tippanel:SetSize(s1 + 100, 64)
    table.insert(TipPanels, tippanel)
    local pos = table.Count(TipPanels) * 70
    tippanel:SetPos(ScrW() - (s1 + 120), ScrH())
    tippanel:MoveTo(ScrW() - (s1 + 120), ScrH() - 150 - pos, 0.5, 0, -10, nil)

    tippanel:MoveTo(ScrW(), ScrH() - 150 - pos, 0.5, 5, -1, function(data, self)
        if IsValid(self) then
            table.RemoveByValue(TipPanels, self)
            self:Remove()
        end
    end)

    tippanel.Paint = function(self)
        col1 = col1 or Color(255, 255, 255, 255)
        col2 = col2 or Color(255, 255, 255, 255)
        draw.RoundedBox(8, 0, 7, self:GetWide(), 50, Color(48, 49, 54, 155))
        draw.SimpleText(str, "Cyb_HudTEXT", 80, 32, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    MsgC(color, str.."\n")

    local tipicon = vgui.Create("DImage", tippanel)
    tipicon:SetMaterial(Material(PHDayZ.TipIcons[icontype]))
    tipicon:SetSize(32, 32)
    tipicon:SetPos(8, 16)
end)

local UpdateDelay = 0
net.Receive("TipSend", function(len)
    local icontype = net.ReadUInt(3)
    local str1 = net.ReadString()
    local col1 = net.ReadTable()
    local str2 = net.ReadString()
    local col2 = net.ReadTable()
    local convar = net.ReadString() or "" 

    timer.Simple(UpdateDelay, function()
        MakeTip(icontype, str1, col1, str2, col2, convar)
        UpdateDelay = math.Clamp( UpdateDelay - 1, 0, 100 )
    end)
    UpdateDelay = UpdateDelay + 1
    
end)

function MakeTip(icontype, str1, col1, str2, col2, convar)

    local lang1 = LANG.TryTranslation(str1)
    local lang2 = LANG.TryTranslation(str2 or "") or ""
    if string.find( lang1, "[ERROR", 1, true ) then
        lang1 = str1
    end
    if string.find( lang2, "[ERROR", 1, true ) then
        lang2 = str2
    end

    surface.SetFont("Cyb_HudTEXT")
    local s1 = surface.GetTextSize(lang1)
    local s2 = surface.GetTextSize(lang2)

    if lang2 == "" then
        s2 = 0
    end

    local tippanel = vgui.Create("DPanel")
    tippanel:SetSize(s1 + s2 + 100, 64)

    local pos = 70
    tippanel:SetPos(ScrW() - (s1 + s2 + 120), ScrH())
    tippanel:MoveTo(ScrW() - (s1 + s2 + 120), ScrH() - 150 - pos, 0.5, 0, -10, function(data, self) self.Moving = false end)
    tippanel.Moving = true

    for k, frame in pairs(TipPanels) do
        if frame.Moving then continue end -- probably removing itself.
        local x, y = frame:GetPos()
        frame.yPos = y - 70

        frame.Moving = true
        frame:MoveTo( x, frame.yPos, 0.5, 0, -1, function() frame.Moving = false end )
    end

    timer.Simple(5, function()
        if !IsValid(tippanel) then return end
        tippanel.Moving = true

        local x, y = tippanel:GetPos()

        tippanel:MoveTo(ScrW(), y, 0.5, 0, -1, function(data, self)
            if IsValid(self) then
                table.RemoveByValue(TipPanels, self)
                self:Remove()
            end
        end)
    end)
    
    table.insert(TipPanels, tippanel)

    tippanel.Paint = function(self)
        col1 = col1 or Color(255, 255, 255, 255)
        col2 = col2 or Color(255, 255, 255, 255)
        draw.RoundedBox(8, 0, 7, self:GetWide(), 50, Color(48, 49, 54, 155))

        if convar and convar ~= "" then
            if GetConVar(convar):GetInt() ~= nil then
                lang1 = string.Replace(lang1, "CONVAR", string.upper(input.GetKeyName(GetConVar(convar):GetInt())))
            end

            draw.SimpleText(lang1, "Cyb_HudTEXT", 80, 32, col1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if lang2 ~= "" then
                if input.GetKeyName(GetConVar(convar):GetInt()) then
                    lang2 = string.Replace(lang2, "CONVAR", string.upper(input.GetKeyName(GetConVar(convar):GetInt())))
                end

                draw.SimpleText(" " .. lang2, "Cyb_HudTEXT", 80 + s1, 32, col2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            return
        end

        draw.SimpleText(lang1, "Cyb_HudTEXT", 80, 32, col1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if lang2 ~= "" then
            draw.SimpleText(" " .. lang2, "Cyb_HudTEXT", 80 + s1, 32, col2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local tipicon = vgui.Create("DImage", tippanel)
    tipicon:SetMaterial(Material(PHDayZ.TipIcons[icontype]))
    tipicon:SetSize(32, 32)
    tipicon:SetPos(8, 16)

    print(lang1)
    if lang2 != "" then
        print(" "..lang2)
    end

    if IsValid(LocalPlayer()) then
        LocalPlayer():EmitSound("garrysmod/save_load1.wav", 75, 100, 0.05)
    end
    --surface.PlaySound()
end


function DrawModelsOnPlayer(ply)

    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end

    --for k, ply in pairs( player.GetAll() ) do
    if !ply:Alive() then return end
    if ply:GetMoveType() != MOVETYPE_WALK then return end

    if !ply.GetProcessItem then return end
    if ply:GetProcessItem() != "" then
        local itemClass = ply:GetProcessItem()
        local itemTable = GAMEMODE.DayZ_Items[itemClass]
        if !itemTable then return end

        if !IsValid(ply.itemHandModel) then
            ply.itemHandModel = ClientsideModel( itemTable.Model )
            ply.itemHandModel:SetModelScale( itemTable.Modelscale or 1 )
            ply.itemHandModel.class = itemClass

            ply.itemHandModel:SetColor(itemTable.Color or Color(255, 255, 255, 255))
        
            if itemTable.Skin then
                ply.itemHandModel:SetSkin(itemTable.Skin)
            end

            if itemTable.BodyGroups then
                ply.itemHandModel:SetBodyGroups(itemTable.BodyGroups)
            end
            
            if itemTable.Material then
                ply.itemHandModel:SetMaterial( itemTable.Material )
            end
        end

        if ply.itemHandModel.class != itemClass then
            ply.itemHandModel.class = itemClass
            ply.itemHandModel:SetModel( itemTable.Model )
            ply.itemHandModel:SetModelScale( itemTable.Modelscale or 1 )
            ply.itemHandModel:SetColor(itemTable.Color or Color(255, 255, 255, 255))
        
            if itemTable.Skin then
                ply.itemHandModel:SetSkin(itemTable.Skin)
            end

            if itemTable.BodyGroups then
                ply.itemHandModel:SetBodyGroups(itemTable.BodyGroups)
            end
            
            if itemTable.Material then
                ply.itemHandModel:SetMaterial( itemTable.Material )
            end

            ply.itemHandModel:SetPos(ply:GetPos()) --fallback incase it exists elsewhere
        end

        local bone = "ValveBiped.Bip01_L_Hand"
        local handBone = ply:LookupBone(bone);
        if !handBone then return end

        local bonepos, boneang = ply:GetBonePosition( handBone )
        local min, max = ply.itemHandModel:GetRenderBounds()
        --if max < 3 then max = 3 end
        local offset = boneang:Right( ) * 1 + boneang:Forward( ) * 3 + boneang:Up( ) * 0

        if bonepos then
            -- magic begins
            ply.itemHandModel:SetRenderOrigin( bonepos + offset )
            ply.itemHandModel:SetRenderAngles( boneang )

            ply.itemHandModel:SetPos(bonepos + offset)
            ply.itemHandModel:SetAngles(boneang)
            ply.itemHandModel:SetupBones()
        end
    else
        if IsValid(ply.itemHandModel) && !ply.itemHandModel:IsPlayer() then ply.itemHandModel:Remove() return end
        -- causes error.
    end
end
hook.Add( "PostPlayerDraw", "DrawModelsOnPlayer", DrawModelsOnPlayer )
    
DZ_StatusBarEnt = DZ_StatusBarEnt or nil

local SlowItDown = 0
function AddStatusBar( ent )
    if !IsValid(ent) then return end
    if SlowItDown > CurTime() then return end

    local pos = ent:GetPos()

    if !ent:IsPlayer() and !ent:IsNPC() and !ent:IsVehicle() then return end

    if LocalPlayer():GetPos():DistToSqr(pos) > (1500*1500) then return end

    if ent:IsVehicle() && LocalPlayer():InVehicle() then return end

    if ent:GetMaxHealth() == 0 then return end

    if ent:IsVehicle() && !ent.GetFuel then return end -- not a vehicle worth noting
    if ent:IsVehicle() and ent:Health() < 1 then return end -- no point showing burned out cars with health.

    if ent:IsPlayer() and !ent:Alive() then return end
    if ent:IsPlayer() and ent:GetMoveType() != MOVETYPE_WALK then return end

    if ent:IsPlayer() and ent:Crouching() then return end
    if ent:IsPlayer() and prone and ent:IsProne() then return end

    if DZ_StatusBarEnt == ent then return end

    DZ_StatusBarEnt = ent

    local hp, mhp = ent:Health(), ent:GetMaxHealth()
    StatusBar_HPSmooth = hp / mhp

    timer.Create("dz_statusenttimeout_"..ent:EntIndex(), 10, 1, function()
        RemoveStatusBar( ent )
    end)

    SlowItDown = CurTime() + 0.1
end

function RemoveStatusBar( ent )
    if !IsValid(ent) then return end

    DZ_StatusBarEnt = nil
end

StatusBar_HPSmooth = StatusBar_HPSmooth or 1
function DrawStatusBar()
    if !IsValid(HotBarPanel) then return end
    if !IsValid(LocalPlayer()) then return end

    local x, y = HotBarPanel:GetPos()

    y = y - 12

    local w, h = HotBarPanel:GetWide(), 45

    if !IsValid(DZ_StatusBarEnt) then return end

    local ent = DZ_StatusBarEnt

    local hp, mhp = ent:Health(), ent:GetMaxHealth()
    local perc = hp / mhp
    local whp = perc
    if whp>1 then whp=1 end

    StatusBar_HPSmooth = math.Approach( StatusBar_HPSmooth, whp, 1 * FrameTime() )

    local class = ent:GetClass()
    local name = class
    if ent.PrintName then
        name = string.gsub(ent.PrintName, "%d", "")
    end

    if language.GetPhrase(class) != class then
        name = language.GetPhrase(class)
    end

    if ent:IsVehicle() then

        class = ent.GetVehicleClass and ent:GetVehicleClass() != "" and ent:GetVehicleClass() or ent:GetClass()
        name = getNiceName( class )
        name = firstToUpper(name)

    end

    if ent:IsNPC() && isfunction(ent.GetLevel) then
        name = name .. " [Lvl: "..ent:GetLevel().."]"
    end

    local text = hp .. "/" .. mhp
    if hp > 100000 then
        text = "∞"
    end

    local ncol = Color(255,255,255,255)
    local statuseffects = {}

    local pteam = ""
    local tcol = Color(255,255,255,255)
    if ent:IsPlayer() then
        name = (ent:GetAFK() and "[AFK] " or "")..ent:GetName()
        text = ( hp / 20 ).."L"
        if !ent:GetInArena() then
            StatusBar_HPSmooth = 1
            text = "???"
        end

        local new = ent:GetFreshSpawn()
        local tm = ScoreGroup(ent)

        local teamn = team.GetName(tm) 
        tcol = team.GetColor(tm)

        local gtm = ScoreGroup(ent, true)
        if gtm != tm then
            pteam = "["..team.GetName(gtm).."]"
            tcol = team.GetColor(gtm)
        end

        local bleed, sick, rads, rhp, hunger, thirst = ent:GetBleed(), ent:GetSick(), ent:GetRadiation(), ent:GetRealHealth(), ent:GetHunger(), ent:GetThirst()
        if bleed then table.insert(statuseffects, "Bleeding") end
        if sick then table.insert(statuseffects, "Sickness") end
        if rads > 0 then table.insert(statuseffects, "Irradiated") end
        if rhp <= 25 then table.insert(statuseffects, "Low Health") end
        if hunger < 100 then table.insert(statuseffects, "Starving") end
        if thirst < 100 then table.insert(statuseffects, "Dehydrated") end

    end


    if table.Count(statuseffects) > 4 then statuseffects = {"Fucked"} end -- lmao

    local t = " - "
    for k, v in pairs(statuseffects) do
        text = text .. t .. "["..v.."]"
        t = ""
    end
 
    draw.RoundedBox( 0, x, y - h, w, h, Color(10,10,10,200) )
    surface.SetFont("char_title20")

    local sx1, sy1 = surface.GetTextSize(pteam)
    if pteam != "" then
        draw.DrawText( pteam, "char_title20", x + 5, y - h + 2, tcol, TEXT_ALIGN_LEFT )
    end
    
    local sx2, sy2 = surface.GetTextSize(name)
    draw.DrawText( name, "char_title20", x + 5 + sx1, y - h + 2, ncol, TEXT_ALIGN_LEFT )

    if isfunction(ent.GetProcessName) && ent:GetProcessName() != "" then draw.DrawText( " - \""..ent:GetProcessName().."\"", "char_title20", x + sx1 + sx2 + 10, y - h + 2, Color(255,255,0,255), TEXT_ALIGN_LEFT ) end

    local hptxt = "BL"
    if ent:IsVehicle() then
        hptxt = "HP"
    end
    -- hp boxes
    draw.RoundedBox( 0, x + 5, y - h + 25, w - 10, 16, Color(0,0,0,255) )
    draw.RoundedBox( 0, x + 5, y - h + 25, (w - 10) * StatusBar_HPSmooth, 16, Color(200,0,0,255) )

    draw.DrawText( hptxt..": "..text, "char_title16", ScrW() / 2, y - h + 25, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
end
hook.Remove("HUDPaint", "DrawStatusBar")

local last_hit_player = nil
local szmat = Material("cyb_mat/cyb_equipment.png")
function DrawTargetID( ply )
    local lply = LocalPlayer()

    local tr = lply:GetEyeTraceNoCursor()
    ply = ply or tr.Entity 

    if !IsValid(ply) then return end
    
    AddStatusBar(ply)

    if ply:IsPlayer() then

        if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
        if ply:Crouching() then return end
        if prone and ply:IsProne() then return end
        if !ply:Alive() then return end
        
        local offset = Vector( 0, 0, 100 )
        local ang = LocalPlayer():EyeAngles()
        local pos = ply:GetPos() + offset + ang:Up()
     
        ang:RotateAroundAxis( ang:Forward(), 90 )
        ang:RotateAroundAxis( ang:Right(), 90 )

        local tm = ScoreGroup(ply)

        local name, teamn, tcol, ncol = ply:GetName(), team.GetName(tm), team.GetColor(tm), Color(255,255,255,255)
        if ply:GetAFK() then
            name = "[AFK] "..name
        end
        local gtm = ScoreGroup(ply, true)
        if gtm != tm then
            name = "["..team.GetName(gtm).."] "..name
            ncol = team.GetColor(gtm)
        end

        cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.2 )
            cam.IgnoreZ(true)

            draw.DrawText( name, "char_title", 2, 22, ncol, TEXT_ALIGN_CENTER )
            draw.DrawText( teamn, "char_title1", 2, 62, tcol, TEXT_ALIGN_CENTER )
            surface.SetFont("char_title")
            local sizex,_ = surface.GetTextSize( name )
            if ply:GetSafeZoneEdge() or ply:GetSafeZone() then
                if ply:GetPVPTime() > CurTime() then
                    surface.SetDrawColor( 200, 0, 0, 255 )
                else
                    surface.SetDrawColor( 0, 200, 0, 255 )
                end
                surface.SetMaterial( szmat ) -- If you use Material, cache it!
                surface.DrawTexturedRect( -((sizex/2)+32), 30, 32, 32 )
            end
            cam.IgnoreZ(false)
        cam.End3D2D()
    end
end
hook.Add( "PostDrawTranslucentRenderables", "DrawTargetID", DrawTargetID )