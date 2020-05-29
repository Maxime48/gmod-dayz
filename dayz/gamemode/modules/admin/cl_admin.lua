LootVectors = LootVectors or {}
VehicleSpawns = VehicleSpawns or {}
ZombieSpawns = ZombieSpawns or {}
PlayerSpawns = PlayerSpawns or {}
ESP_DrawPlayersCvar = GetConVar( "dz_espdrawplayers" ) or CreateClientConVar("dz_espdrawplayers", 0, false, false)
ESP_DrawPlayerAimsCvar = GetConVar( "dz_espdrawaims" ) or CreateClientConVar("dz_espdrawaims", 0, false, false)
ESP_DrawItemsCvar = GetConVar( "dz_espdrawitems" ) or CreateClientConVar("dz_espdrawitems", 0, false, false)
ESP_DrawLootablesCvar = GetConVar( "dz_espdrawlootables" ) or CreateClientConVar("dz_espdrawlootables", 0, false, false)
ESP_DrawNPCsCvar = GetConVar( "dz_espdrawnpcs" ) or CreateClientConVar("dz_espdrawnpcs", 0, false, false)
ShowSpawnsCvar = GetConVar( "dz_showspawns" ) or CreateClientConVar("dz_showspawns", 0, false, false)
ShowLegendCvar = GetConVar( "dz_showlegend" ) or CreateClientConVar("dz_showlegend", 0, false, false)
MaxDistCvar = GetConVar( "dz_drawmaxdist" ) or CreateClientConVar("dz_drawmaxdist", 100000, false, false)
ShowSpawns = ShowSpawns or 0
ShowLegend = ShowLegend or 0
ESP_DrawPlayers = ESP_DrawPlayers or 0
ESP_DrawPlayerAims = ESP_DrawPlayerAims or 0
ESP_DrawItems = ESP_DrawItems or 0
ESP_DrawNPCs = ESP_DrawNPCs or 0

function UpdateShowSpawns(str, old, new)
    ShowSpawns = math.floor(new)
end
cvars.AddChangeCallback(ShowSpawnsCvar:GetName(), UpdateShowSpawns)

function UpdateShowLegend(str, old, new)
    ShowLegend = math.floor(new)
end
cvars.AddChangeCallback(ShowLegendCvar:GetName(), UpdateShowLegend)

function UpdateESP_DrawPlayers(str, old, new)
    ESP_DrawPlayers = math.floor(new)
end
cvars.AddChangeCallback(ESP_DrawPlayersCvar:GetName(), UpdateESP_DrawPlayers)

function UpdateESP_DrawNPCs(str, old, new)
    ESP_DrawNPCs = math.floor(new)
end
cvars.AddChangeCallback(ESP_DrawNPCsCvar:GetName(), UpdateESP_DrawNPCs)

function UpdateESP_DrawItems(str, old, new)
    ESP_DrawItems = math.floor(new)
end
cvars.AddChangeCallback(ESP_DrawItemsCvar:GetName(), UpdateESP_DrawItems)

function UpdateESP_DrawLootables(str, old, new)
    ESP_DrawLootables = math.floor(new)
end
cvars.AddChangeCallback(ESP_DrawLootablesCvar:GetName(), UpdateESP_DrawLootables)

function UpdateESP_DrawPlayerAims(str, old, new)
    ESP_DrawPlayerAims = math.floor(new)
end
cvars.AddChangeCallback(ESP_DrawPlayerAimsCvar:GetName(), UpdateESP_DrawPlayerAims)

hook.Add("PostGamemodeLoaded", "InitShowSpawns", function()
    ShowSpawns = ShowSpawnsCvar:GetInt() or 0
    ShowLegend = ShowLegendCvar:GetInt() or 0
    ESP_DrawPlayers = ESP_DrawPlayersCvar:GetInt() or 0
    ESP_DrawItems = ESP_DrawItemsCvar:GetInt() or 0
    ESP_DrawNPCs = ESP_DrawNPCsCvar:GetInt() or 0
    ESP_DrawPlayerAims = ESP_DrawPlayerAimsCvar:GetInt() or 0
end)

net.Receive("SendSpawnVectors", function()
    LootVectors = net.ReadTable()
end)

net.Receive("SendVehicleVectors", function()
    VehicleSpawns = net.ReadTable()
end)

net.Receive("SendZombieVectors", function()
    ZombieSpawns = net.ReadTable()
end)

net.Receive("SendPlayerVectors", function()
    PlayerSpawns = net.ReadTable()
end)

MaxDist = MaxDist or 10000

function UpdateMaxDist(str, old, new)
    MaxDist = math.floor(new)
end

cvars.AddChangeCallback(MaxDistCvar:GetName(), UpdateMaxDist)

hook.Add("PostGamemodeLoaded", "InitShowSpawns2", function()
    MaxDist = MaxDistCvar:GetInt() or 0
end)

local colors = {}
colors[1] = { col = Color(127, 255, 255), name = "Basic" }
-- basic
colors[2] = { col = Color(255, 255, 0), name = "Food" }
-- food
colors[3] = { col = Color(255, 70, 0), name = "Industrial" }
-- industrial
colors[4] = { col = Color(0, 255, 0), name = "Medical" }
-- medical
colors[5] = { col = Color(255, 0, 0), name = "Weapon" }
-- weapon
colors[6] = { col = Color(220, 0, 255), name = "Hat" }
-- hat
colors[7] = { col = Color(0, 127, 31), name = "Player" }
-- zombies
colors[8] = { col = Color(0, 161, 255), name = "Zombie" }

-- jeeps
function DrawTheText(text, x, y, color, font)
    draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    --draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 127), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

categoryAdminPanels = categoryAdminPanels or {}
AdminModelPanels = AdminModelPanels or {}
function MakeGiveMenu()
    if not LocalPlayer():IsSuperAdmin() then return end
    
    if IsValid(Admin_GiveMenu) then
        Admin_GiveMenu:Remove()

        return
    end

    for k, v in pairs(AdminModelPanels) do
        if !IsValid(v) then continue end
        
        --print(v, "removed")
        v:Remove()
    end

    Admin_GiveMenu = vgui.Create("DFrame")
    Admin_GiveMenu:SetSize(600, 600)
    Admin_GiveMenu:MakePopup()
    Admin_GiveMenu:Center()
    Admin_GiveMenu:SetTitle("Give Item")
    Admin_GiveMenu:ShowCloseButton(true)
    Admin_GiveMenu.btnMaxim:Hide()
    Admin_GiveMenu.btnMinim:Hide()

    Admin_GiveMenu.Paint = function(self, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, Color(10, 10, 10, 150), false, true, false, true)
    end

    local itemCategories = GAMEMODE.Util:GetItemCategories()

    if !IsValid(categoryAdminScroll) then
        categoryAdminScroll = vgui.Create("DScrollPanel", Admin_GiveMenu)
        categoryAdminScroll:SetWide( 550 )
        categoryAdminScroll:Dock(FILL)
        categoryAdminScroll.Paint = function(self, w, h) end
        categoryAdminScroll.Think = function(self)
            if ( self.NextThink or 0 ) > CurTime() then return end

            local children = self:GetCanvas():GetChildren()
            for k, child in pairs(children) do
                if !child:IsVisible() then
                    child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
                end
            end

            self.NextThink = CurTime() + 0.5
        end

        local ScrollBar = categoryAdminScroll:GetVBar();

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

        for _, category in ipairs(itemCategories) do
            
            categoryAdminPanels[category] = vgui.Create("DCollapsibleCategory", categoryAdminScroll)
            categoryAdminPanels[category]:SetLabel("")
            categoryAdminPanels[category]:SetWide( 550 )
            categoryAdminPanels[category]:Dock(TOP)
            categoryAdminPanels[category]:DockMargin(0, 0, 0, 5)
            categoryAdminPanels[category]:DockPadding(0, 0, 0, 5)

            categoryAdminPanels[category].Paint = function(self, w, h)
                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)

                if self:GetExpanded() then
                    draw.RoundedBoxEx(0, 0, h-5, w, 5, Color(0, 0, 0, 70), true, true, true, true)
                end

                local txt = "+"
                local clr = Color(100, 100, 100, 200)

                if self:GetExpanded() then
                    txt = "-"
                    clr = Color(200, 200, 200, 200)
                end

                if category == "none" then 
                    draw.DrawText("Currency", "char_title20", 5, 0, clr, TEXT_ALIGN_LEFT)
                else
                    draw.DrawText(firstToUpper(LANG.GetTranslation("category"..category)), "char_title20", 5, 0, clr, TEXT_ALIGN_LEFT)
                end
                draw.DrawText(txt, "char_title20", w-10, 0, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            categoryAdminPanels[category].List = vgui.Create("DIconLayout", categoryAdminPanels[category] )
            categoryAdminPanels[category].List:SetPos(0, 25)
            categoryAdminPanels[category].List:SetSize( 570, 300)
            categoryAdminPanels[category].List:SetSpaceX(5)
            categoryAdminPanels[category].List:SetSpaceY(5)
            categoryAdminPanels[category].List:SetBorder(5)
            categoryAdminPanels[category].List:Receiver("cat_slot", function(pnl, tbl, dropped, menu, x, y)
                if (not dropped) then return end
                --print(tbl[1]:GetParent())
                if tbl[1]:GetParent() == pnl then 
                    --print(tbl[1].ItemClass.." wants SplitItem "..tbl[1].Amount/2)
                    --RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount/2)
                    return 
                end
                --tbl[1]:SetSize(66, 66)
                --tbl[1]:GetChild(1):SetSize(50, 50)
                --GUI_Inv_Panel_List:AddItem(tbl[1])
                --RunConsoleCommand("Dequipitem", tbl[1].ItemID)
            end)
            categoryAdminPanels[category].List.Paint = function(self, w, h)
                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
            end

            categoryAdminPanels[category].Think = function(self, vis)
                if !vis and ( self.NextThink or 0 ) > CurTime() then return end
                local children = self.List:GetChildren()

                if table.Count(children) > 0 then
                    self:SetVisible(true)
                else
                    self:SetVisible(false)
                end
                self:GetParent():InvalidateLayout()

                if vis then return end
                self.NextThink = CurTime() + 1
            end


        end
    end

    for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
        local item, itemCat = ItemTable.ID, ItemTable.Category
        if !itemCat then itemCat = "none" end

        categoryAdminPanels[itemCat] = categoryAdminPanels[itemCat] or {} -- Extra validation, in case.
        if !categoryAdminPanels[itemCat].List then continue end

        local panel, modelpanel = DZ_MakeIcon( nil, item, 0, categoryAdminPanels[itemCat].List, nil, nil, 55, 55, false, true, false, nil, nil )
        panel.rarity = 1
        AdminModelPanels[itemCat] = AdminModelPanels[itemCat] or {}
        table.insert(AdminModelPanels[itemCat], modelpanel)

        modelpanel.DoClick = function()
            RunConsoleCommand( "dz_giveitem", item, 1 )
        end

        modelpanel.DoRightClick = function()
            ItemMENU = DermaMenu()
            
            local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}

            local panel = ItemMENU:AddOption(ItemTable.Name)  
            panel.Paint = PaintItemMenus   
            ItemMENU:AddSpacer()
            for k, v in ipairs(amts) do
                local panel = ItemMENU:AddOption("Give "..v,    function()
                    RunConsoleCommand("dz_giveitem",item,v)
                end )
                panel.Paint = PaintItemMenus
            end

            ItemMENU:Open( gui.MousePos() ) 

            DZ_ItemMENU = ItemMENU
        end
    end

end

concommand.Add("dz_givemenu", MakeGiveMenu)

function MakeConfigMenu()
    if not LocalPlayer():IsAdmin() then return end

    if IsValid(AddConfigFrame) then
        AddConfigFrame:Remove()

        return
    end

    AddConfigFrame = vgui.Create("DFrame")
    AddConfigFrame:SetSize(600, 600)
    AddConfigFrame:MakePopup()
    AddConfigFrame:Center()
    AddConfigFrame:SetTitle("DayZ Config Options")
    AddConfigFrame:ShowCloseButton(true)
    AddConfigFrame.btnMaxim:Hide()
    AddConfigFrame.btnMinim:Hide()

    AddConfigFrame.Paint = function(self, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, Color(10, 10, 10, 150), false, true, false, true)
    end

    AddConfigFrame:SetDraggable(true)
    local SaveButton = vgui.Create("DButton", AddConfigFrame)
    SaveButton:SetText("Save and Reload Config")
    if !LocalPlayer():IsSuperAdmin() then
        SaveButton:SetText("Superadmin Access Required!")
    end
    SaveButton:SetFont("char_title20")
    SaveButton:Dock(BOTTOM)
    SaveButton:DockMargin(0, 5, 0, 0)
    SaveButton.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(92, 184, 92, 255))
    end

    SaveButton.DoClick = function(self)
        if !LocalPlayer():IsSuperAdmin() then return end
        
        self:SetDisabled(true)

        net.Start("dz_adminConfigUpdate")
            net.WriteTable(PHDayZ)
        net.SendToServer()
        timer.Simple(3, function() if !IsValid(self) then return end self:SetDisabled(false) end)
    end
    local Scroll = vgui.Create("DScrollPanel", AddConfigFrame)
    --Create the Scroll panel
    Scroll:Dock(FILL)
    PaintVBar( Scroll:GetVBar() )
    local IconPanel = vgui.Create("DIconLayout", Scroll)
    IconPanel:Dock(FILL)
    --IconPanel:SetSpaceY(5)

    for k, v in SortedPairs(PHDayZ) do
        --if type(v) == "table" then
            --continue
        --end
        //print(k .. " - " .. tostring(v))
        local ConfigOption = IconPanel:Add("DPanel")
        ConfigOption:SetTall(16)
        ConfigOption:Dock(TOP)
        ConfigOption.Paint = function() end
        local OptionType = vgui.Create("DLabel", ConfigOption)
        OptionType:Dock(LEFT)
        OptionType:SetFont("char_title16")
        OptionType:SetColor(Color(200,255,200,100))
        OptionType:SetText("["..UpFirstLetter( type(v) or "Unknown" ).."]")
        OptionType:SizeToContents()

        local OptionName = vgui.Create("DLabel", ConfigOption)
        OptionName:SetPos(60, 1)
        OptionName:SetFont("char_title16")
        OptionName:SetColor(Color(255,255,255,200))
        OptionName:SetText(k)
        OptionName:SizeToContents()

        local Option
        if type(v) == "boolean" then
            Option = vgui.Create("DCheckBox", ConfigOption)
            Option:Dock(RIGHT)
            Option:SetChecked(v)
        elseif type(v) == "string" or type(v) == "Vector" or type(v) == "Angle" then
            Option = vgui.Create("DTextEntry", ConfigOption)
            Option.vartype = type(v)
            Option:Dock(RIGHT)
            Option:SetSize(200, 32)

            if type(v) == "Vector" or type(v) == "Angle" then
                Option:SetText(v[1] .. ", " .. v[2] .. ", " .. v[3])
            else
                Option:SetText(tostring(v))
            end
        elseif type(v) == "number" then
            Option = vgui.Create("DNumberWang", ConfigOption)
            Option:Dock(RIGHT)
            Option:SetMin(0)
            Option:SetMax(1000000)
            Option:SetValue(v)
        elseif type(v) == "table" then
            Option = vgui.Create("DLabel", ConfigOption)
            Option:Dock(RIGHT)
            Option:SetText("Requires file edit")
            Option:SizeToContents()
        end

        Option.OnChange = function(self)
            local val
            if type(v) == "boolean" then
                val = self:GetChecked()
            elseif type(v) == "string" or type(v) == "Vector" or type(v) == "Angle" then
                val = self:GetText()
                if self.vartype == "Vector" then
                    local t = string.Explode(", ", val)
                    val = Vector(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
                elseif self.vartype == "Angle" then
                    local t = string.Explode(", ", val)
                    val = Angle(tonumber(t[1]), tonumber(t[2]), tonumber(t[3]))
                end
            elseif type(v) == "number" then
                val = tonumber(self:GetValue())
            end

            PHDayZ[k] = val
            print(type(val), k, val)
        end
    end

end

-- do nothing right now.
--local Option = vgui.Create("DProperties", ConfigOption)
--ConfigOption:SetSize(100, 100)
--Option:Dock(RIGHT)
--Option:SetSize(100,100)
--local Row = Option:CreateRow("Category", "Row")
--Row:Setup("Generic")
--Row:SetValue("Tits!")
--for _k, _v in pairs(v) do 
--print(_k .. " - " .._v)
--end
concommand.Add("dz_configmenu", MakeConfigMenu)

local IGNOREZ = true;
local color = Color( 255, 0, 0, 50 );
local item_color = Color( 255, 255, 0, 50 );
local that_other_color = Color( color.r, color.g, color.b, 255 );
local that_other_color2 = Color( item_color.r, item_color.g, item_color.b, 255 );
hook.Add("HUDPaint", "DrawSpawns", function()

    if !LocalPlayer():IsAdmin() then return end
    if LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP && !LocalPlayer():IsSuperAdmin() then return end

    if ESP_DrawItems == 1 then
        
        local baseItems = ents.FindByClass("base_item")

        -- base_item
        for k, v in pairs(baseItems) do
            --if v:GetClass() != "base_item" then continue end
            local pos = v:GetPos()
            if pos == Vector(0,0,0) then continue end -- do not draw if at origin vector.
            
            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

            local pos_ad = pos + Vector(0,0,20)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()    
            local item = v:GetItem()
            if !item then continue end

            local rarity = v:GetRarity() or 1
            local rar = GetRarity(rarity)

            local ItemTable = GAMEMODE.DayZ_Items[ item ]

            DrawTheText(ItemTable.Name.." ["..rar.t.."]", screen.x, screen.y, rar.color, "char_title16")
        end

        cam.Start3D( EyePos(), EyeAngles() )
            for i, ent in pairs( baseItems ) do

                if( !IsValid( ent ) ) then continue end

                if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                local rarity = ent:GetRarity() or 1
                local rar = GetRarity(rarity)
                if !rar then
                    rar = {}
                    rar.color = Color(255,255,255,50)
                end

                local col = Color(rar.color.r, rar.color.g, rar.color.b, 50)
                local other_col = Color(rar.color.r, rar.color.g, rar.color.b, 255)

                local pos, ang = ent:GetPos(), ent:GetAngles()
                local min, max = ent:OBBMins(), ent:OBBMaxs()
                if( min == nil || max == nil ) then
                        continue
                end
                if( !IGNOREZ ) then
                    render.SetColorMaterial()
                else
                    render.SetColorMaterialIgnoreZ()
                end
                render.SetBlend( other_col.a / 255 )
                render.DrawBox( pos, ang, min, max, col, !IGNOREZ )
                render.DrawWireframeBox( pos, ang, min, max, other_col, !IGNOREZ )
            end
        cam.End3D()

    end

    if ESP_DrawLootables == 1 then
        local baseLootables = ents.FindByClass("base_lootable")

        for k, v in pairs(baseLootables) do
            --if v:GetClass() != "base_item" then continue end
            local pos = v:GetPos()
            if pos == Vector(0,0,0) then continue end -- do not draw if at origin vector.
            
            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

            local pos_ad = pos + Vector(0,0,20)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()    

            local name = v:GetModel()

            if PHDayZ.ModelToNiceName && PHDayZ.ModelToNiceName[ name ] then
                name = PHDayZ.ModelToNiceName[ name ]
            else
                name = string.sub(name, 1, string.len(name) - 4 )
                name = string.Replace(name, "_", " ")

                local expl = string.Explode("/", name)
                name = expl [ #expl ]
            end

            DrawTheText("[ID: "..v:EntIndex().."] "..name, screen.x, screen.y, Color(0,150,200,255), "char_title16")
        end

        cam.Start3D( EyePos(), EyeAngles() )

            for i, ent in pairs( baseLootables ) do

                if( !IsValid( ent ) ) then continue end

                if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                local col = Color(0, 50, 200, 50)
                local other_col = Color(0, 50, 200, 255)

                local pos, ang = ent:GetPos(), ent:GetAngles()
                local min, max = ent:OBBMins(), ent:OBBMaxs()
                if( min == nil || max == nil ) then
                        continue
                end
                render.SetBlend( 0.7 )

                if( !IGNOREZ ) then
                    render.SetColorMaterial()
                else
                    render.SetColorMaterialIgnoreZ()
                end
                render.SetBlend( other_col.a / 255 )
                render.DrawBox( pos, ang, min, max, col, !IGNOREZ )
                render.DrawWireframeBox( pos, ang, min, max, other_col, !IGNOREZ )

            end
        cam.End3D();
    end

    if ESP_DrawPlayerAims == 1 then

        local allPlayers = player.GetHumans()

        cam.Start3D( EyePos(), EyeAngles() )

            for i, ent in pairs( allPlayers ) do

                if( !IsValid( ent ) ) then continue end
                if ent == LocalPlayer() then continue end

                if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                local td = { }
                td.start = ent:GetShootPos( )
                td.endpos = ent:GetShootPos( ) + ent:GetAimVector( ) * 4096
                td.filter = ent
                local tr = util.TraceLine( td )

                local start, finish = td.start, tr.HitPos

                if( !IGNOREZ ) then
                    render.SetColorMaterial()
                else
                    render.SetColorMaterialIgnoreZ()
                end

                --render.SetBlend( color.a / 255 )
                render.DrawLine( start, finish, Color(0,255,0,255), !IGNOREZ )

            end

        cam.End3D();

    end

    if ESP_DrawPlayers == 1 then

        local allPlayers = player.GetHumans()
        local baseRagdolls = ents.FindByClass("prop_ragdoll")
        local baseGraves = ents.FindByClass("grave")

        for k, v in pairs( allPlayers ) do
            local pos = v:GetPos()
            local pos_ad = pos + Vector(0,0,72)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()

            local wep = IsValid(v:GetActiveWeapon()) and v:GetActiveWeapon():GetClass() or "None"

            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
            DrawTheText(v:Nick(), screen.x, screen.y-30, Color(255,0,0,255), "char_title16")
            DrawTheText(wep, screen.x, screen.y-20, Color(255,0,0,255), "char_title16")

            local hpM = v:Health() / 2.5

            surface.SetDrawColor( Color(255,0,0) )
            surface.DrawOutlinedRect(screen.x - 20, screen.y - 50, 40, 4)
            surface.DrawRect(screen.x - 20, screen.y - 50 , hpM, 4)

        end

       for k, v in pairs( baseRagdolls ) do
            local pos = v:GetPos()
            local pos_ad = pos + Vector(0,0,30)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()

            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
            if !isfunction(v.GetStoredName) then continue end
            if v:GetStoredName() == "" then continue end

            DrawTheText(v:GetStoredName(), screen.x, screen.y, Color(255,0,0,255), "char_title16")
        end

        for k, v in pairs( baseGraves ) do
            local pos = v:GetPos()
            local pos_ad = pos + Vector(0,0,30)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()

            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
            if !isfunction(v.GetStoredName) then continue end
            if v:GetStoredName() == "" then continue end

            DrawTheText(v:GetStoredName(), screen.x, screen.y, Color(255,0,0,255), "char_title16")
        end

        cam.Start3D( EyePos(), EyeAngles() )

            for i, ent in pairs( baseGraves ) do

                if( !IsValid( ent ) ) then continue end

                if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                local pos, ang = ent:GetPos(), ent:GetAngles()
                local min, max = ent:OBBMins(), ent:OBBMaxs()
                if( min == nil || max == nil ) then
                        continue
                end
                render.SetBlend( 0.7 )

                if( !IGNOREZ ) then
                    render.SetColorMaterial()
                else
                    render.SetColorMaterialIgnoreZ()
                end
                render.SetBlend( color.a / 255 )
                render.DrawBox( pos, ang, min, max, color, !IGNOREZ )
                render.DrawWireframeBox( pos, ang, min, max, that_other_color, !IGNOREZ )

            end
        cam.End3D();

        cam.Start3D( EyePos(), EyeAngles() );
            for i, ent in pairs( baseRagdolls ) do
                if( !ent ) then continue; end
                if( !IsValid( ent ) ) then continue; end

                if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                if !ent.GetStoredName then continue end
                if ent:GetStoredName() == "" then continue end

                for hitbox = 0, ent:GetHitBoxCount(0) do
                    local bone = ent:GetHitBoxBone( hitbox, 0 );
                    if !bone then continue; end
                    local bpos, bang = ent:GetBonePosition( bone );
                    local min, max = ent:GetHitBoxBounds( hitbox, 0 );
                    if( min == nil || max == nil ) then
                        continue;
                    end
                    if( !IGNOREZ ) then
                        render.SetColorMaterial();
                    else
                        render.SetColorMaterialIgnoreZ();
                    end
                    render.SetBlend( color.a / 255 );
                    render.DrawBox( bpos, bang, min, max, color, !IGNOREZ );
                    render.DrawWireframeBox( bpos, bang, min, max, that_other_color, !IGNOREZ );
                end
            end
        cam.End3D();


        cam.Start3D( EyePos(), EyeAngles() );
            for i, ent in pairs( allPlayers ) do
                    if( !ent ) then continue; end
                    if( !IsValid( ent ) ) then continue; end
                    if( ent == LocalPlayer() ) && !LocalPlayer():GetThirdPerson() then continue; end
                    if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

                    for hitbox = 0, ent:GetHitBoxCount(0) do
                            local bone = ent:GetHitBoxBone( hitbox, 0 );
                            if !bone then continue; end
                            local bpos, bang = ent:GetBonePosition( bone );
                            local min, max = ent:GetHitBoxBounds( hitbox, 0 );
                            if( min == nil || max == nil ) then
                                    continue;
                            end
                            if( !IGNOREZ ) then
                                    render.SetColorMaterial();
                            else
                                    render.SetColorMaterialIgnoreZ();
                            end
                            render.SetBlend( color.a / 255 );
                            render.DrawBox( bpos, bang, min, max, color, !IGNOREZ );
                            render.DrawWireframeBox( bpos, bang, min, max, that_other_color, !IGNOREZ );
                    end
            end
    cam.End3D();

    end

    if ESP_DrawNPCs == 1 then

        local allNpcs = ents.GetAll()

        for k, v in pairs( allNpcs ) do
            if !v:IsNPC() then continue end -- :( ugly

            local pos = v:GetPos()
            local pos_ad = pos + Vector(0,0,72)
            local ang = v:GetAngles()
            local screen = pos_ad:ToScreen()

            local wep = IsValid(v:GetActiveWeapon()) and v:GetActiveWeapon():GetClass() or nil

            if pos:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

            local class = v:GetClass()
            local name = class
            if v.PrintName then
                name = string.gsub(v.PrintName, "%d", "")
            end


            if v.GetLevel then
                name = name.." [Lvl: "..v:GetLevel().."]"
            end

            DrawTheText(name, screen.x, screen.y-30, Color(0,255,0,255), "char_title16")
            if wep != nil then
                DrawTheText(wep, screen.x, screen.y-20, Color(0,255,0,255), "char_title16")
            end

            local hp, mhp = v:Health(), v:GetMaxHealth()
            local perc = hp / mhp
            local w = math.Round(perc*40)

            surface.SetDrawColor( Color(0,255,0) )
            surface.DrawOutlinedRect(screen.x - 20, screen.y - 50, 40, 4)
            surface.DrawRect(screen.x - 20, screen.y - 50 , w, 4)

        end

    end

    if ShowSpawns < 1 then return end
    local w = 180
    local h = 380
    local padding = 0
    local color = Color(140, 50, 50, 255)
    

    if #LootVectors < 1 then
        DrawTheText("Run dz_requestspawns in your console!", ScrW() / 2, ScrH() / 2, Color(255, 0, 0), "Cyb_LOGO")

        return
    end

    local font, font2 = "char_title16", "char_title12"

    for i = 1, #LootVectors do
        for k, v in pairs(LootVectors[i]) do
            local pos = v:ToScreen()
            if v:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
            DrawTheText("x", pos.x, pos.y, colors[i].col, font)
            if ShowLegend == 1 then
                DrawTheText(colors[i].name or "Unknown", pos.x, pos.y - 16, colors[i].col, font2)
            end
        end
    end

    for k, v in pairs(PlayerSpawns) do
        local pos = v:ToScreen()
        if v:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
        DrawTheText("p", pos.x, pos.y, colors[4].col, font)
        if ShowLegend == 1 then
            DrawTheText("Player", pos.x, pos.y - 16, colors[4].col, font2)
        end
    end

    for i = 1, #VehicleSpawns do
        for k, v in pairs(VehicleSpawns[i]) do
            local pos = v:ToScreen()
            if v:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

            DrawTheText("v", pos.x, pos.y, colors[i].col, font)
            if ShowLegend == 1 then
                DrawTheText("Vehicle", pos.x, pos.y - 16, colors[i].col, font2)
            end
        end
    end

    for k, v in pairs(ZombieSpawns) do
        local pos = v:ToScreen()
        if v:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end
        DrawTheText("z", pos.x, pos.y, Color(0, 255, 0), font)
        if ShowLegend == 1 then
            DrawTheText("Zombie", pos.x, pos.y - 16, Color(0, 255, 0), font2)
        end
    end

    hook.Run("DZ_DrawMapSetup", font, font2)
end)

AdminMenu_SpawnButtons_d = {
    {
        name = "Basic",
        command = "basic",
        item = "item_stone",
        color = Color(127, 255, 255),
        letter = "x"
    },
    {
        name = "Food",
        command = "food",
        item = "item_food2",
        color = Color(255, 255, 0),
        letter = "x"
    },
    {
        name = "Industrial",
        command = "industrial",
        item = "item_gasoline",
        color = Color(255, 70, 0),
        letter = "x"
    },
    {
        name = "Medical",
        command = "medical",
        item = "item_medic2",
        color = Color(0, 255, 0),
        letter = "x"
    },
    {
        name = "Weapon",
        command = "weapon",
        item = "item_knife",
        color = Color(255, 0, 0),
        letter = "x"
    },
    {
        name = "Hat",
        command = "hat",
        item = "item_hat_5",
        color = Color(220, 0, 255),
        letter = "x"
    },
    {
        name = "Zombie",
        command = "zombie",
        item = "item_meat",
        color = Color(0, 255, 0),
        letter = "z"
    },
    {
        name = "Jeep",
        command = "hl2jeep",
        item = "shoes_battered",
        color = Color(255, 255, 0),
        letter = "v"
    },
    {
        name = "Helicopter",
        command = "helicopter",
        item = "shoes_battered",
        color = Color(255, 255, 0),
        letter = "v"
    },
    {
        name = "Player",
        command = "player",
        item = "item_hula",
        color = Color(0, 255, 0),
        letter = "p"
    }
}

hook.Add("Initialize", "InitCyBMapEnabled", function()
    CyBMapEnabled = CyBConf.MinimapEnabled:GetInt() or 1
    CyBMapShowZomb = CyBConf.MapShowZombies:GetInt() or 0
end)

AdminMenu_SpawnButtons_Extra = {}
AdminToggleNet = AdminToggleNet or false
local function DrawAdminTools(enabled)
    if not LocalPlayer():IsAdmin() then return end

    if !enabled then
        if ValidPanel(AdminTools) then AdminTools:Remove() end

        return
    end

    if #LootVectors < 1 then
        RunConsoleCommand("dz_requestspawns")
    end

    if ValidPanel(AdminTools) then
        AdminTools:Show()
    else
        AdminTools = vgui.Create("DPanel")
        AdminTools:Dock(BOTTOM)
        AdminTools:DockMargin(200,0,0,0)
        AdminTools:SetTall(96)
        AdminTools.Paint = function(self, w, h)
            //draw.RoundedBox( 4, 0, 0, w, h, Color(0,0,0,180) )
        end
        AdminMenu_SpawnButtons_Extra = {}
        hook.Call("DZ_AddSetupMenuItem")
    end

    //panel:DockMargin(0,52,0,5)

    AdminTools_Setup = vgui.Create("DPanel", AdminTools)
    AdminTools_Setup:SetTall(64)
    AdminTools_Setup:Dock(RIGHT)
    AdminTools_Setup.Paint = function(self, w, h)
         draw.RoundedBoxEx(4, 0, 0, w, h, Color(92, 184, 92, 255), false, true, false, true)
    end

    AdminTools_Top = vgui.Create("DPanel", AdminTools_Setup)
    AdminTools_Top:SetTall(32)
    AdminTools_Top:Dock(TOP)
    AdminTools_Top.Paint = function(self, w, h)
        //draw.RoundedBox(4, 0, 0, w, h, Color(91,192,222, 0))

        draw.RoundedBoxEx(2, 0, 0, w, 40, Color(0, 0, 0, 100), false, true, false, true)
        draw.DrawText( "ADMIN SPAWN CONTROL", "tab_title", w/2, 0, Color(200,200,200,200), TEXT_ALIGN_CENTER )
    end

    local SavePersistent = vgui.Create("DButton", AdminTools_Top)
    SavePersistent:SetTooltip("Force saves the persistent props created by the C menu in case the server crashes.")
    SavePersistent:SetText("Force Save")
    SavePersistent.Paint = PaintButtons
    SavePersistent:SetFont("char_title20")
    SavePersistent.DoClick = function()
        RunConsoleCommand("dz_savepersist")
    end
    SavePersistent:Dock(LEFT)
    SavePersistent:DockMargin(5, 4, 5, 4)

    local AdminNetwork = vgui.Create("DButton", AdminTools_Top)
    AdminNetwork:SetTooltip("Stops you from being networked to other players. Cheaters can't see you! (Ignores Admins)")
    AdminNetwork:SetText("Toggle Networking")
    AdminNetwork.Paint = function(self, w, h)
    
        local color = Color(60, 10, 10, 255)
        local text_color = Color(200,200,200,255)

        if AdminToggleNet then
            color = Color(10, 60, 10, 255)
        end

        local text = self:GetText()
        if text != "" then
            self:SetText("")
            self.text = text
        end

        draw.RoundedBox( 2, 0, 0, w, h, color ) 
        draw.DrawText( self.text, "char_title16", w/2, h/2-8, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    AdminNetwork:SetFont("char_title20")
    AdminNetwork:SetWide( 120 )
    AdminNetwork.DoClick = function()
        RunConsoleCommand("dz_admintogglenet")
        AdminToggleNet = !AdminToggleNet
    end
    AdminNetwork:Dock(LEFT)
    AdminNetwork:DockMargin(5, 4, 5, 4)

    local DrawPoints = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    DrawPoints:SetText("")
    DrawPoints:SetFont("char_title20")
    DrawPoints:SetTooltip("[ESP] Draw Players?")
    DrawPoints:SetConVar("dz_espdrawplayers")
    DrawPoints:Dock(RIGHT)
    DrawPoints:DockMargin(0, 4, 5, 0)

    local DrawPoints = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    DrawPoints:SetText("")
    DrawPoints:SetFont("char_title20")
    DrawPoints:SetTooltip("[ESP] Draw NPCs?")
    DrawPoints:SetConVar("dz_espdrawnpcs")
    DrawPoints:Dock(RIGHT)
    DrawPoints:DockMargin(0, 4, 5, 0)

    local DrawPoints = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    DrawPoints:SetText("")
    DrawPoints:SetTooltip("[ESP] Draw Items?")
    DrawPoints:SetFont("char_title20")
    DrawPoints:SetConVar("dz_espdrawitems")
    DrawPoints:Dock(RIGHT)
    DrawPoints:DockMargin(0, 4, 5, 0)

    local DrawLootables = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    DrawLootables:SetText("")
    DrawLootables:SetTooltip("[ESP] Draw Lootables?")
    DrawLootables:SetFont("char_title20")
    DrawLootables:SetConVar("dz_espdrawlootables")
    DrawLootables:Dock(RIGHT)
    DrawLootables:DockMargin(0, 4, 5, 0)

    local DrawSpawns = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    DrawSpawns:SetTooltip("Draw Spawns?")
    DrawSpawns:SetText("")
    DrawSpawns:SetFont("char_title20")
    DrawSpawns:SetConVar("dz_showspawns")
    DrawSpawns:Dock(RIGHT)
    DrawSpawns:DockMargin(0, 4, 5, 0)

    local ShowLegendBox = vgui.Create("DCheckBoxLabel", AdminTools_Top)
    ShowLegendBox:SetTooltip("Draw Legend?")
    ShowLegendBox:SetText("")
    ShowLegendBox:SetFont("char_title20")
    ShowLegendBox:SetConVar("dz_showlegend")
    ShowLegendBox:Dock(RIGHT)
    ShowLegendBox:DockMargin(0, 4, 5, 0)

    local function buttonpaint(button, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(92, 184, 92, 255))
    end

    local MakeLootable = vgui.Create("DButton", AdminTools_Setup)
    MakeLootable:Dock(RIGHT)
    MakeLootable:DockMargin(5,0,0,0)
    MakeLootable:SetSize(64, 64)
    MakeLootable:SetText("")
    MakeLootable:SetTooltip("Turns the prop you are looking at into a lootable entity.")
    MakeLootable.Paint = function(self, w, h)
        draw.RoundedBox(4,2,2,w-4,h-4,Color(37, 41, 172, 255))
        draw.RoundedBox(4,2,2,w-4,h/4,Color( 0, 0, 0, 150 ))
        draw.DrawText( "TURN LOOTABLE:", "Cyb_Inv_Label", w/2, 2, Color(200,200,200,200), TEXT_ALIGN_CENTER )
    end

    MakeLootable.DoClick = function(self)
        RunConsoleCommand("dz_turnlootable")
    end

    local RemoveSpawn = vgui.Create("DButton", AdminTools_Setup)
    RemoveSpawn:Dock(RIGHT)
    RemoveSpawn:DockMargin(5,0,0,0)
    RemoveSpawn:SetSize(62, 62)
    RemoveSpawn:SetTooltip("Removes a spawn near where you are looking")
    RemoveSpawn:SetText("")
    RemoveSpawn.Paint = function(self, w, h)
        draw.RoundedBox(4,2,2,w-4,h-4,Color(172, 41, 37, 255))
        draw.RoundedBox(4,2,2,w-4,h/4,Color( 0, 0, 0, 150 ))
        draw.DrawText( "REMOVE:", "Cyb_Inv_Label", w/2, 2, Color(200,200,200,200), TEXT_ALIGN_CENTER )
    end

    RemoveSpawn.DoClick = function(self)
        RunConsoleCommand("dz_removespawn")
    end

    local i = 69

    for k, v in pairs(AdminMenu_SpawnButtons_d) do
        if v.item then
            local panel, modelpanel = DZ_MakeIcon( nil, v.item, 0, AdminTools_Setup, nil, nil, 64, 64, false, true, nil, false, true )
            panel:SetSize(64, 64)
            panel.Paint = function() end
            panel:SetTooltip("Adds a "..v.name.." spawn where you are looking")
            modelpanel:SetSize(60,60)
            modelpanel:SetPos(2,2)
            modelpanel.AlwaysDraw = true

            panel:Dock(RIGHT)
            panel:DockMargin(5,0,0,0)

            panel.Paint = function(self, w, h) paint_bg(self, w, h) end

            panel.DoClick = function(self)
                RunConsoleCommand("dz_addspawn", v.command)
            end
            modelpanel.DoClick = function(self)
                RunConsoleCommand("dz_addspawn", v.command)
            end

            i = i + 69
        end
    end

    for k, v in pairs(AdminMenu_SpawnButtons_Extra) do
        if v.item then
            local panel, modelpanel = DZ_MakeIcon( nil, v.item, 0, AdminTools_Setup, nil, nil, 94, 94, false, true, nil, false, true )
            panel:SetSize(64, 64)
            panel.Paint = function() end
            modelpanel:SetSize(60,60)
            modelpanel:SetPos(2,2)
            modelpanel.AlwaysDraw = true

            panel:Dock(RIGHT)
            panel:DockMargin(5,0,0,0)
            panel:SetTooltip("Adds a "..v.name.." spawn where you are looking")
            panel.Paint = function(self, w, h) paint_bg(self, w, h) end

            panel.DoClick = function(self)
                RunConsoleCommand("dz_addspawn", v.command)
            end
            modelpanel.DoClick = function(self)
                RunConsoleCommand("dz_addspawn", v.command)
            end

            i = i + 103
        end
    end


    AdminTools_Setup:SetWide(i)

    AddSpawnFrame = AdminTools_Setup


end
hook.Add("OnContextMenuOpen", "", function() DrawAdminTools(true) end)
hook.Add("OnContextMenuClose", "", function() DrawAdminTools(false) end)

function GM:PlayerNoClip(ply, state)
    return false
end