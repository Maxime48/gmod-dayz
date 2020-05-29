hook.Add("InitPostEntity", "FilterAnnoyingConsole", function()
    RunConsoleCommand("con_filter_enable", "1")
    RunConsoleCommand("con_filter_text_out", "Attempting to create unknown particle system 'steam_jet_80'")
    RunConsoleCommand("con_filter_text_out", "Attempting to create unknown particle system 'steam_large_01'")
    RunConsoleCommand("con_filter_text_out", "Attempting to create unknown particle system 'dust_bridge_crack'")
    RunConsoleCommand("con_filter_text_out", "Attempting to create unknown particle system 'Dust_Ceiling_Rumble_512Square'")
end)

local blur = Material("pp/blurscreen")

function LerpColor(t, cFrom, cTo)
    local r, g, b, a = cFrom.r, cFrom.g, cFrom.b, cFrom.a
    
    -- from + (to - from) * percentage
    return Color(r + (cTo.r - r) * t, g + (cTo.g - g) * t, b + (cTo.b - b) * t, a + (cTo.a - a) * t)
end

function PaintVBar(vbar)

    local ScrollBar = vbar

    local bg_color = Color(40, 40, 40, 255)
    local fg_color = Color(30, 30, 30, 255)
    local t_color = Color(150, 150, 150, 255)
    
    ScrollBar.Paint = function(self, w, h)
        draw.RoundedBox(0,0,0,w,h,fg_color)
    end

    ScrollBar.btnUp.Paint = function(self, w, h)
        draw.RoundedBox(0,0,0,w,h,bg_color)
        draw.DrawText("▴", "char_title20", w/2 - 1, h/2 - 10, t_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ScrollBar.btnDown.Paint = function(self, w, h)
        draw.RoundedBox(0,0,0,w,h,bg_color)
        draw.DrawText("▾", "char_title20", w/2 - 2, h/2 - 12, t_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ScrollBar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(0,0,0,w,h,bg_color)
    end
end

local function draweffect(len)
    local ent = net.ReadEntity()
    local ef = net.ReadString()
    local pos = net.ReadVector()

    local ang = net.ReadAngle()
    local att = net.ReadInt(32)
    local col = net.ReadInt(32)
    local dmgt = net.ReadInt(32)
    local ei = net.ReadVector()
    local mag = net.ReadInt(32)
    local rad = net.ReadInt(32)
    local scale = net.ReadInt(32)
    local start = net.ReadVector()

    local ed = EffectData()
    if IsValid(ent) then
        ed:SetEntity(ent)
    end
    ed:SetOrigin(pos)

    /*ed:SetAngles(ang)
    ed:SetAttachment(att)

    ed:SetColor( col )
    ed:SetDamageType(dmgt)
    ed:SetNormal(ei)
    --ed:SetEntIndex(ei)
    ed:SetMagnitude(mag)
    ed:SetRadius(rad)
    ed:SetScale(scale)
    ed:SetStart(start)*/

    util.Effect(ef, ed, true, true)
end
net.Receive("DZ_DrawEffect", draweffect)

function ColorLerp(flDist)
    local flMinDist = 10
    local flMaxDist = 1000
    local cMin = Color(255, 0, 0)
    local cMax = Color(0, 255, 0)

    local t -- Lerp percentage

    -- Could also use math.Clamp on the fractional calculation
    -- But this is more efficient
    if (flDist <= flMinDist) then
        t = 0
    elseif (flDist >= flMaxDist) then
        t = 1
    else
        -- t is calculated by subtracting the minimum distance from the top and bottom of a fraction of flDist/flMaxDist
        -- This will give a number 0-1 
        t = (flDist - flMinDist) / (flMaxDist - flMinDist)
    end

    -- This is your gradient
    return LerpColor(t, cMin, cMax)
end

function DrawBlurPanel(panel, amount, heavyness)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)

    for i = 1, (heavyness or 3) do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

-- Use this on a panel in it's paint hook. or just use the one below, really doesnt matter
function DrawBlurRect(x, y, w, h, amount, heavyness)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)

    for i = 1, (heavyness or 3) do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        render.SetScissorRect(x, y, x + w, y + h, true)
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

function PaintButtons(self, w, h)
    
    local color = Color(60, 60, 60, 255)
    local text_color = Color(200,200,200,255)
    if self:IsHovered() then
        color = Color(50, 50, 50, 255)
    end

    local text = self:GetText()
    if text != "" then
        self:SetText("")
        self.text = text
    end

    draw.RoundedBox( 2, 0, 0, w, h, color ) 
    draw.DrawText( self.text, "char_title16", w/2, h/2-8, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

function PaintItemMenus(self, w, h)
    local boxcolor = Color(0,0,0,255)
    local textcolor = Color(220,220,220,255)
    if self:IsHovered() then
        boxcolor = Color(0,80,0,255)
        --textcolor = Color(0,0,0,255)
        if self:GetDisabled() then
            boxcolor = Color(80,0,0,255)
        end
        if self.ConditionsMet == true then
            boxcolor = Color(0,80,0,255)
        end
        if self.ConditionsMet == 2 then
            boxcolor = Color(80,80,0,255)
        end
    end

    local text = self:GetText()
    if text != "" then
        self:SetText("")
        self.text = text
    end

    draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 
    --DrawBlurPanel(self)
    if !self.text then return end

    surface.SetFont("char_title16")
    local sizex, _ = surface.GetTextSize(self.text)
    if sizex > self:GetParent():GetWide() - 10 then
        self:GetParent():SetWide(sizex + 20)
    end

    draw.DrawText( self.text, "char_title16", w/2, h/2-8, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    return false
end

DZ_IconPanels = DZ_IconPanels or {}

function DZ_RemoveIcon(itemid)
    local panel = DZ_IconPanels[itemid]

    if IsValid(panel) then
        panel:Remove()
    end
end

local IconPanels = {}

local function PanelThink() -- my panels always think for themselves

    for k, v in pairs(IconPanels) do
        if !IsValid(v) then IconPanels[v] = nil continue end

        --if !v:IsVisible() then
            v:Think()
            --print("Thinking")
        --end
    end
end
hook.Add("Think", "IconPanelThink", PanelThink)

local border = 4
local border_w = 5
local matHover = Material( "gui/sm_hover.png", "nocull" )
local boxHover = GWEN.CreateTextureBorder( border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover )

function DZ_MakeIcon(itemid, item, amount, parent, itemmenus, receiver, sizex, sizey, drawitemtype, norotate, drawper, concept, notooltip, set_playermodel, viponly)

    sizex = sizex or 60
    sizey = sizey or 60

    local ItemTable = GAMEMODE.DayZ_Items[item]

    local itemtype = ""

    if drawitemtype and ItemTable.Category then
        itemtype = LANG.GetTranslation("category" .. ItemTable.Category) or ""
    end

    local panel = vgui.Create("DPanelList", parent)
    panel:SetSize(sizex, sizey)
    panel:SetSpacing(5)
    panel:SetPos(2, 2)

    if receiver then
        panel:Droppable(receiver)
    end
    panel:Droppable("panel_item")
    panel:Droppable("cat_slot")

    panel.ItemClass = item
    panel.ItemID = itemid
    panel.Amount = amount
    panel.rarity = GAMEMODE.DayZ_Items[item].Rarity or 1

    table.insert(IconPanels, panel)

    panel.minDrawY = ScrH()/2 - 300
    panel.maxDrawY = ScrH()/2 + 300

    if itemid then
        DZ_IconPanels[itemid] = panel
    end

    panel:Receiver( "panel_item", function(self, tbl, bDoDrop, Command, x, y)
        if !bDoDrop then return end
        local panel = tbl[1]

        --print(panel.ItemClass.."("..panel.ItemID..") wants stack with "..self.ItemClass.."("..self.ItemID..")")
        RunConsoleCommand("StackItem", panel.ItemID, self.ItemID)
    end )

    local function makeicon()
        local x, y = panel:LocalToScreen(0, 0)

        --draw.RoundedBoxEx(4,2,2,w-4,h-4,Color( 60, 60, 60, 255 ), true, true, true, true) 
        local modelpanel = vgui.Create("DModelPanel", panel)
        modelpanel:SetPos(5, 5)
        modelpanel:SetSize(sizex - 9, sizey - 9)
        panel.ModelPanel = modelpanel

        panel.OnRemove = function(self)
            if IsValid(modelpanel) then
                if IsValid(modelpanel:GetEntity()) then 
                    modelpanel:GetEntity():Remove() -- gc no worky?
                end
                --collectgarbage() -- rip
                
                modelpanel:Remove()
            end
        end

        modelpanel.OnRemove = function(self)
            if IsValid(modelpanel:GetEntity()) then 
                modelpanel:GetEntity():Remove() -- gc no worky?
            end
            --collectgarbage() -- rip
        end
        
        modelpanel:SetDragParent(panel)
        if receiver then
            modelpanel:Droppable(receiver)
        end
        modelpanel:Droppable("panel_item")

        modelpanel.ItemClass = item
        local PaintModel = modelpanel.Paint

        if norotate then
            modelpanel.LayoutEntity = function() end
        end

        function modelpanel:DrawModel()
            local curparent = self
            local rightx = self:GetWide()
            local leftx = 0
            local topy = 0
            local bottomy = self:GetTall()
            local previous = curparent

            while (curparent:GetParent() ~= nil) do
                curparent = curparent:GetParent()
                local x, y = previous:GetPos()
                topy = math.Max(y, topy + y)
                leftx = math.Max(x, leftx + x)
                bottomy = math.Min(y + previous:GetTall(), bottomy + y)
                rightx = math.Min(x + previous:GetWide(), rightx + x)
                previous = curparent
            end

            if self:GetParent():IsDragging() then
                self.Entity:DrawModel()
            else
                render.SetScissorRect(leftx, topy, rightx, bottomy, true)
                self.Entity:DrawModel()
                render.SetScissorRect(0, 0, 0, 0, false)
            end
        end

        modelpanel:SetDrawOnTop(false)

        function modelpanel:Paint(w, h)
            local x2, y2 = self:GetParent():LocalToScreen(0, 0)
            local w2, h2 = self:GetParent():GetSize()

            render.SetScissorRect(x2, y2, x2 + w2, y2 + h2, true)
            PaintModel(self, w, h)
            render.SetScissorRect(0, 0, 0, 0, false)

            if drawper and ItemTable.GivePer then
                draw.DrawText("x" .. GAMEMODE.DayZ_Items[item].GivePer, "char_title8", w - 5, h - 17, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT)
            end

            if itemtype ~= "" then

                if (ItemTable.VIP or viponly) then
                    draw.RoundedBox(2, 0, 0, w, 16, Color(0, 0, 0, 150))
                    draw.DrawText("VIP ONLY", "Cyb_Inv_Label", w / 2, 2, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                draw.RoundedBox(2, 0, h - 18, w, h / 4, Color(0, 0, 0, 150))
                draw.DrawText(string.upper(itemtype), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
            end


            self.OverlayFade = math.Clamp( ( self.OverlayFade or 0 ) - RealFrameTime() * 640 * 2, 0, 255 )

            if ( dragndrop.IsDragging() || !self:IsHovered() ) then return end

            self.OverlayFade = math.Clamp( self.OverlayFade + RealFrameTime() * 640 * 8, 0, 255 )

            if ( self.OverlayFade > 0 ) then
                boxHover( 0, 0, w, h, Color( 255, 255, 255, self.OverlayFade ) )
            end

        end

        modelpanel.NextThink = 0

        if ItemTable.BodyModel and set_playermodel then
            modelpanel:SetModel(ItemTable.BodyModel)
        else
            modelpanel:SetModel(ItemTable.Model)
        end
        if not IsValid(modelpanel:GetEntity()) then return end

        -- Wtf?
        if ItemTable.Material then
            modelpanel:GetEntity():SetMaterial(ItemTable.Material)
        end

        if ItemTable.Skin then
            modelpanel:GetEntity():SetSkin(ItemTable.Skin)
        end

        if ItemTable.BodyGroups then
            modelpanel:GetEntity():SetBodyGroups(ItemTable.BodyGroups)
        end

        modelpanel:SetColor(ItemTable.Color or Color(255, 255, 255, 255))
        modelpanel:GetEntity():SetAngles(Angle(0, 0, 0))

        if ItemTable.ViewAngle ~= nil then
            modelpanel:GetEntity():SetAngles(ItemTable.ViewAngle)
        end

        function modelpanel:RecomputeAngles(noangle)
            if !IsValid(self:GetEntity()) then return end

            local mn, mx = self.Entity:GetRenderBounds()
            local ItemTable = GAMEMODE.DayZ_Items[ self.ItemClass ]

            local size = 0
            size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
            size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
            size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
            modelpanel:SetFOV(45)
            modelpanel:SetCamPos(Vector(size, size, size))
            modelpanel:SetLookAt((mn + mx) * 0.5)
            -- if ItemTable.ViewDist != nil then modelpanel:SetCamPos(Vector(size, size, size)+ItemTable.ViewDist) end
            
            if !noangle then
                if ItemTable.ViewAngle ~= nil then
                    self:GetEntity():SetAngles(ItemTable.ViewAngle)
                end

                if ItemTable.OverrideCamPos then
                    self:SetCamPos(ItemTable.OverrideCamPos)
                end
            else
                self:SetCamPos( Vector(0,5000,0) )
            end
        end
        modelpanel:RecomputeAngles()

        if IsValid(modelpanel:GetEntity():GetPhysicsObject()) then
            modelpanel:GetEntity():GetPhysicsObject():EnableMotion(false)
        end
        
        modelpanel.OnCursorEntered = function()
            if notooltip then return end
            InspectPanel = InspectItem(item, nil, nil, nil, nil, itemid, panel.rarity or 1, amount or 1)
        end

        modelpanel.OnCursorExited = function()
            if IsValid(InspectPanel) then
                InspectPanel:Remove()
            end
        end

        if amount > 0 then
            local label = vgui.Create("DLabel", panel)
            label:SetColor(Color(200, 200, 200, 255))
            label:SetText("")
            label:SetSize(64, 32)
            label:SetPos(8, 4) 
            label.Paint = function(self, w, h)
                local x, y, align = 2, 2, TEXT_ALIGN_LEFT
                if panel.hotbar then
                    x, y, align = 50, 0, TEXT_ALIGN_RIGHT
                end

                amount = panel.Amount

                if itemid && panel.hotbar then
                    amount = LocalPlayer():GetItemAmount(itemid)
                end

                draw.DrawText("x" .. amount, "char_title14", x, y, Color(255, 255, 255, 200), align)
            end
        end

        return modelpanel
    end

    panel.Think = function(self) -- my hacky entity saver
        local x, y = self:LocalToScreen(0, 0)

        if y < self.minDrawY or y > self.maxDrawY then -- hardcoded menu positions

            if IsValid(self.ModelPanel) && !self.ModelPanel.AlwaysDraw then
                self.oldModelPaint = self.ModelPanel.Paint
                self.oldModelClick = self.ModelPanel.DoClick
                self.oldModelRightClick = self.ModelPanel.DoRightClick
                self.oldModelThink = self.ModelPanel.Think

                self.oldModelItemNum = self.ModelPanel.ItemNum

                self.ModelPanel:Remove()
                --print("removed "..ItemTable.Name.." modelpanel at space "..y)
            end
        else
            if !IsValid(self.ModelPanel) then
                local modelpanel = makeicon()
                if !IsValid(modelpanel) then return end -- max ents.

                if self.oldModelPaint then 
                    modelpanel.Paint = self.oldModelPaint
                    modelpanel.Think = self.oldModelThink
                    modelpanel.DoClick = self.oldModelClick
                    modelpanel.DoRightClick = self.oldModelRightClick
                    modelpanel.ItemNum = self.oldModelItemNum
                end
            end
        end

    end
    
    panel.Paint = function(self, w, h)
        --draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 100 ), true, true, true, true)
        local rar_tab = GetRarity(self.rarity)

        --print(modelpanel:IsVisible())

        if rar_tab then 
            local col = rar_tab.color
            if self.hotbar then
                col.a = 50
            else
                col.a = 30
            end
            draw.RoundedBoxEx(0, 1, 1, w - 2, h - 2, col, true, true, true, true)
            col.a = 255
        end
        if (ItemTable.VIP or viponly) && !LocalPlayer():IsVIP() then
            draw.RoundedBoxEx(0, 1, 1, w - 2, h - 2, Color(255, 0, 0, 20), true, true, true, true)

            return
        elseif self.SetRed then
            draw.RoundedBoxEx(0, 1, 1, w - 2, h - 2, Color(255, 0, 0, 20), true, true, true, true)

            return
        elseif self.SetGreen then
            draw.RoundedBoxEx(0, 1, 1, w - 2, h - 2, Color(0, 255, 0, 20), true, true, true, true)

            return
        end

        draw.RoundedBoxEx(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 50), true, true, true, true)
    end
    
    local modelpanel = makeicon()

    /*
    if !IsValid(modelpanel) then
        modelpanel = vgui.Create("SpawnIcon", panel)
        modelpanel:SetPos(5, 5)
        modelpanel:SetModel( ItemTable.Model )
        modelpanel:SetSize(sizex - 9, sizey - 9)
        panel.ModelPanel = modelpanel

        modelpanel.OnCursorEntered = function()
            if notooltip then return end
            InspectPanel = InspectItem(item, nil, nil, nil, nil, itemid, panel.rarity or 1)
        end

        modelpanel.OnCursorExited = function()
            if IsValid(InspectPanel) then
                InspectPanel:Remove()
            end
        end

        modelpanel.AlwaysDraw = true
    end
    */
    
    return panel, IsValid(modelpanel) and modelpanel or panel -- fallback incase max entites, will use panel instead since modelpanel will be nil.
end

--parent:AddItem( panel )
hook.Add("PostDrawViewModel", "DrawHands", function(vm, ply, wep)
    if (wep.UseHands and not wep:IsScripted()) then
        local hands = LocalPlayer():GetHands()

        if (IsValid(hands)) then
            hands:DrawModel()
        end
    end
end)

function GM:Tick()
    --local client = LocalPlayer()

    --if IsValid(client) then
        --if client:Alive() then
            --WSWITCH:Think()
        --end
    --end
end

local function SendWeaponDrop()
    RunConsoleCommand("cyb_dropweapon")
    -- Turn off weapon switch display if you had it open while dropping, to avoid
    -- inconsistencies.
    WSWITCH:Disable()
end

function GM:PlayerBindPress(ply, bind, pressed)
    if not IsValid(ply) then return end

    if bind == "invnext" and pressed then
        local idx = GetActiveHotBarSlot()
        idx = idx + 1
        if idx > 9 then idx = 1 end

        --HotBar_DoLogic(idx)
        return true
    elseif bind == "invprev" and pressed then
        local idx = GetActiveHotBarSlot()
        idx = idx - 1
        if idx < 1 then idx = 1 end

        --HotBar_DoLogic(idx)

        return true
    elseif bind == "+attack" then
        if WSWITCH.Show then
            if not pressed then
                WSWITCH:ConfirmSelection()
            end

            return true
        end
    elseif string.sub(bind, 1, 4) == "slot" and pressed then
        local idx = tonumber(string.sub(bind, 5, -1)) or 1
        --WSWITCH:SelectSlot(idx)

        HotBar_DoLogic(idx)

        return true
    end
end

function TraceMat2(ply, cmd, args)

    local tr = util.TraceLine( {
        start = LocalPlayer():EyePos(),
        endpos = LocalPlayer():EyePos() + EyeAngles():Forward() * 10000,
        filter = function( ent ) if ( ent:GetClass() == "prop_physics" ) then return true end end
    } )
    if tr.HitTexture then
        local texture = tr.HitTexture
        PrintTable(tr.Entity:GetMaterials())

        ply:PrintMessage(HUD_PRINTCONSOLE, texture)
    end
end
concommand.Add("dz_trace", TraceMat2)

if prone then
    concommand.Remove("gmod_undo")
    concommand.Add("gmod_undo", function()
        prone.Request()
    end)
end