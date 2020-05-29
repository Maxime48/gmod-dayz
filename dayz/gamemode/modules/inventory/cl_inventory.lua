local vgui = vgui
local draw = draw
local surface = surface
local InventoryModelPanels = {}
TotalWeight = TotalWeight or 0
Local_Character = Local_Character or {}
Local_Inventory = Local_Inventory or {}
Local_PerkTable = Local_PerkTable or {}
local CharModelPanels = {}

--------------------------------

local UpdateDelay = 0
net.Receive("UpdateItem", function(len)
    local it = net.ReadTable()
    local notify = net.ReadBool()

   -- print("Item Update Recieved")
   -- PrintTable(it)
    local old_amount = 0

    Local_Inventory[it.class] = Local_Inventory[it.class] or {}

    if Local_Inventory[it.class][it.id] then
        old_amount = Local_Inventory[it.class][it.id].amount
    end

    Local_Inventory[it.class][it.id] = it

    if notify then
        timer.Simple(UpdateDelay, function()
            DoGiveItemUI( it.class, it.amount - old_amount, it.rarity )
            UpdateDelay = math.Clamp( UpdateDelay - 1, 0, 100 )
        end)
        UpdateDelay = UpdateDelay + 1
    end

    local cat = GAMEMODE.DayZ_Items[it.class].Category
    if !cat then cat = "none" end
    
   -- print(cat)
    
    UpdateAllTabs(cat)
end)

BPFrames = BPFrames or {}
function DoGiveItemUI( item, amount, rar )
    if !GAMEMODE.DayZ_Items[item] then return end

    local name = GAMEMODE.DayZ_Items[item].Name
    local desc = GAMEMODE.DayZ_Items[item].Desc
    local MenuSize = 505

    local yPos = 300

    local BPFrame = vgui.Create("DPanel")

    BPFrame:SetSize( MenuSize, 85 )
    BPFrame.Moving = true

    BPFrame:SetPos(-MenuSize, yPos)

    for k, frame in pairs(BPFrames) do
        if frame.Moving then return end -- probably removing itself.
        local x, y = frame:GetPos()
        frame.yPos = y - 90

        frame:MoveTo( 0, frame.yPos, 0.75, 0, -1, function() BPFrame.Moving = false end )
    end

    BPFrame:MoveTo( 0, BPFrame.yPos or yPos, 0.75, 0, -1, function() BPFrame.Moving = false end )

    timer.Simple(8, function() 
        if IsValid(BPFrame) then 
            BPFrame.Moving = true
            BPFrame:MoveTo( -MenuSize, BPFrame.yPos or yPos, 0.75, 0, -1, function() table.RemoveByValue(BPFrames, BPFrame) BPFrame:Remove() end ) 
        end 
    end)

    rar = rar or 1
    local rarity = GetRarity(rar)

    BPFrame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color( 0, 0, 0, 150 ))

        draw.RoundedBoxEx(4,5,5,75,75,Color( 0, 0, 0, 50 ), true, true, true, true)
        draw.RoundedBoxEx(4,6,6,75-2,75-2,Color( 255, 255, 255, 10 ), true, true, true, true) 
        draw.RoundedBoxEx(4,7,7,75-4,75-4,Color( 60, 60, 60, 255 ), true, true, true, true) 

        draw.DrawText( "GAINED:", "char_options", 90, -5, Color(0, 200, 0 ,255), TEXT_ALIGN_LEFT )

        draw.DrawText( "★ "..name, "char_title24", 90, 40, rarity.color or Color(0, 200, 0 ,255), TEXT_ALIGN_LEFT )
        
        draw.DrawText( desc, "char_title16", 90, 65, Color(200,200,200,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    if !IsValid(BPFrame.Icon) then
        BPFrame.Icon, BPFrame.MIcon = DZ_MakeIcon( nil, item, amount, BPFrame, nil, nil, 75, 75, false, false, false )
    end
    BPFrame.Icon:SetPos(5, 5)
    BPFrame.Icon.rarity = rar


    table.insert(BPFrames, BPFrame)
end

net.Receive("UpdateItemFull", function(len)
    Local_Inventory = net.ReadTable()
    --print("Recieved full inventory update")
    UpdateAllTabs()
end)

net.Receive("UpdateCharFull", function(len)
    Local_Character = net.ReadTable()
    local catUpdate = net.ReadString()
   -- print('updating char')
    UpdateAllTabs(catUpdate)
end)

net.Receive("UpdateWeight", function(len)
    TotalWeight = math.Round(net.ReadFloat(), 1)
end)

net.Receive("UpdateWorth", function(len)
    local worth = math.Round(net.ReadFloat(), 1)
    local inv = net.ReadBool()

    if inv then
        TotalWorth = worth
    else
        TotalBankWorth = worth
    end
end)

net.Receive("PlayerPerks", function(len)
    Local_PerkTable = net.ReadTable()
end)

function Rebuild_Backup(len)
    UpdateAllTabs()
end

net.Receive("net_UpdateInventory", Rebuild_Backup)

function UpdateCharItems(parent, item, sizex, sizey)
    if not IsValid(parent) then return end

    for k, v in pairs(parent:GetChildren()) do
        if IsValid(v) then
            v:Remove()
        end
    end

    local it = GAMEMODE.Util:GetItemIDByClass(Local_Character, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    local panel, modelpanel = DZ_MakeIcon(it.id, item, 0, parent, nil, "invslot", sizex or 94, sizey or 94, false, true)
    --if !panel then print("[PHDayZ] Failed making item icon for "..item) return end
    table.insert(CharModelPanels, modelpanel)
    panel.rarity = it.rarity or 0

    modelpanel.DoClick = function()
        RunConsoleCommand("DEquipItem",it.id)
    end

    modelpanel.DoRightClick = function()
        ItemMENU = DermaMenu()

        local panel = ItemMENU:AddOption("UnEquip", function()
            RunConsoleCommand("DEquipItem", it.id)
        end)

        panel.Paint = PaintItemMenus

        ItemMENU:AddSpacer()

        local HotBarMenu, panel = ItemMENU:AddSubMenu( "Add to Hotbar" )

        HotBarMenu.Paint = PaintItemMenus
        panel.Paint = PaintItemMenus

        for i=1, 9 do
            local panel = HotBarMenu:AddOption("Slot "..i, function()
                Local_HotBar[i].item = it.id
                Local_HotBar[i].itemclass = it.class
                --HotBarPanel:Remove()
            end)

            panel.Paint = PaintItemMenus
        end

        ItemMENU:Open( gui.MousePos() ) 
    end

    timer.Simple(0.1, function()
        if IsValid(InvPlayerModel) then
            InvPlayerModel:SetModel(LocalPlayer():GetModel())
            InvPlayerModel.Entity.GetPlayerColor = function() return Vector(GetConVarString("cl_playercolor")) end
        end
    end)
end

function DZ_IsMenuOpen()
    local val = false
    if IsValid(GUI_Loot_Frame) then
        val = true
    end

    if IsValid(GUI_Donate_Frame) then
        val = true
    end

    if IsValid(GUI_Quest_Frame) then
        val = true
    end

    if IsValid(GUI_Upgrade_Frame) then
        val = true
    end

    if IsValid(GUI_Main_Frame) && GUI_Main_Frame:IsVisible() then
        val = true
    end

    return val
end

function RemoveOpenedMenus()
    if IsValid(GUI_Loot_Frame) then
        GUI_Loot_Frame:Remove()
    end

    if IsValid(GUI_Donate_Frame) then
        GUI_Donate_Frame:Remove()
    end

    if IsValid(GUI_Upgrade_Frame) then
        GUI_Upgrade_Frame:Remove()
    end

    if IsValid(InspectPanel) then
        InspectPanel:Remove()
    end

    if IsValid(SelectFrame) then
        SelectFrame:Remove()
    end

    if IsValid(Admin_GiveMenu) then
        Admin_GiveMenu:Remove()
    end

    if IsValid(GUI_Quest_Frame) then
        GUI_Quest_Frame:Remove()
    end

    if DZ_ItemMENU ~= nil and DZ_ItemMENU:IsValid() then
        DZ_ItemMENU:Remove()
    end

    if IsValid(GUI_Main_Frame) && GUI_Main_Frame:IsVisible() then
        GUI_Main_Frame:Hide()
    end
end

net.Receive("CloseOpenMenus", function(len)
    RemoveOpenedMenus()
end)

function UpdateAllTabs(catUpdate)
    --if not DZ_MENUVISIBLE and not IsValid(GUI_Donate_Frame) then return end

    if isfunction(UpdateInv) then
        UpdateInv(catUpdate)
    end

    if isfunction(UpdateShopInv) then
        UpdateShopInv(true, catUpdate)
    end

    if isfunction(UpdateInvSelect) then
        UpdateInvSelect()
    end

    if IsValid(UpgradeInv_Panel) then
        UpdateUpgrades(UpgradeInv_Panel.List, catUpdate)
    end

    --if isfunction(UpdateBank) then
        --UpdateBank(catUpdate)
    --end

    if IsValid(GUI_Main_Frame) then
        if isfunction(GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc) then
            GUI_Main_Frame.IconSheet:GetActiveTab():GetPanel().updatefunc(catUpdate) -- bank, inventory auto updates
        end
    else
        GUI_MainMenu(true)
    end
end

function DZ_MakeItemMenu(item, ItemTable, it, itemtype, modelpanel, setmenu)
    if IsValid(DZ_ItemMENU) then DZ_ItemMENU:Remove() end

    local ItemMENU
    if !setmenu then
        ItemMENU = DermaMenu()
    else
        ItemMENU = setmenu
    end

    local itemamt = LocalPlayer():GetItemAmount(it.id)

    local cats = {"ammo", "attachments", "primaries", "secondaries", "tertiaries", "tools", "parts", "melee", "bodyarmor", "backpacks", "clothes", "pants", "shoes", "misc"}

    if !ItemTable.CantRepair && table.HasValue(cats, string.lower(ItemTable.Category or "")) then
        local t = ""
        if !LocalPlayer():HasItem(ItemTable.RepairItem or "item_repairkit", true) then
            t = " [Missing Repair Kit]"
        end
        if LocalPlayer():GetLevel() < ( ( ItemTable.LevelReq or 0 ) / 2 )  then 
            t = " [Level Req: "..( ItemTable.LevelReq / 2 ).."]"
        end
        local panel = ItemMENU:AddOption("Repair"..t, function()
            RunConsoleCommand("Repairitem", it.id)
        end)
        panel.Paint = PaintItemMenus

        if !LocalPlayer():HasItem(ItemTable.RepairItem or "item_repairkit", true) then
            panel:SetDisabled(true)
        else
            panel.ConditionsMet = true
        end
        ItemMENU:AddSpacer()
    end
                                    
    if itemtype != '' then
        local panel = ItemMENU:AddOption("Equip ["..itemtype.."]", function()
            RunConsoleCommand("EquipItem",it.id)
        end)
        panel.Paint = PaintItemMenus
        ItemMENU:AddSpacer()
    end

    if ( ItemTable.ReqCook != nil && !ItemTable.CantCook ) && !ItemTable.NoBlueprint && !Local_BPTable[item] then
        local t = ""
        if !Local_BPTable[item] && !ItemTable.NoBlueprint then
            if ItemTable.CantCraft then
                t = " [Uncraftable]"
            else
                t = " [BP Available]"
            end
        end

        if LocalPlayer():GetLevel() < ( ItemTable.LevelReq or 0 ) then 
            t = " [Level Req: "..ItemTable.LevelReq.."]"
        end
        local panel = ItemMENU:AddOption("Study "..t, function()
            RunConsoleCommand("StudyItem",it.id)
        end)
        panel.Paint = PaintItemMenus

        if Local_BPTable[item] or ItemTable.NoBlueprint then
            panel:SetDisabled(true)
        else
            panel.ConditionsMet = true
        end

        if !Local_BPTable[item] && !ItemTable.NoBlueprint then
            panel.ConditionsMet = true
        end

        ItemMENU:AddSpacer()                                                    
    end

    if ItemTable.ReqCraft != nil && !ItemTable.CantDecompile then
        local t = ""
        if !Local_BPTable[item] && !ItemTable.NoBlueprint then
            t = " [BP Available]"
            if !LocalPlayer():HasItem("item_paper", true) and !LocalPlayer():HasSkill("int_bitsnbobs") then
                t = t .. " [Missing Paper]"
            end
        end

        if ItemTable.CantCraft then
            t = " [Uncraftable]"
        end

        local do_disable, cond = false, true
        if !LocalPlayer():HasItem(ItemTable.RepairItem or "item_repairkit", true) then
            t = t .. " [Missing Repair Kit]"
            cond = 2
        end

        if LocalPlayer():GetLevel() < ( ItemTable.LevelReq or 0 ) then 
            t = " [Level Req: "..ItemTable.LevelReq.."]"
        end

        if !LocalPlayer():HasItem("item_paper", true) and !LocalPlayer():HasSkill("int_bitsnbobs") && !Local_BPTable[item] then
            do_disable = true
        elseif !Local_BPTable[item] && !LocalPlayer():HasItem("item_paper", true) && !ItemTable.NoBlueprint then
            cond = false
        end

        local panel
        if itemamt > 1 then
            DropMenu, panel = ItemMENU:AddSubMenu( "Decompile X"..t )
            DropMenu.Paint = PaintItemMenus
            panel.Paint = PaintItemMenus

            DropMenu:AddSpacer()

            local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
            if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end

            for k, v in ipairs(amts) do              
                if itemamt >= v then
                    local panel2 = DropMenu:AddOption("Decompile "..v,    function()
                        RunConsoleCommand("MultiDecompileItem", it.id, v)
                    end )
                    panel2.Paint = PaintItemMenus
                    panel2:SetDisabled(do_disable)
                    panel2.ConditionsMet = cond
                end
            end
        else
            panel = ItemMENU:AddOption("Decompile"..t, function()
                RunConsoleCommand("Decompileitem",it.id)
            end)
            panel.Paint = PaintItemMenus
        end

        panel:SetDisabled(do_disable)
        panel.ConditionsMet = cond

        ItemMENU:AddSpacer()                                                    
    end

    if ItemTable.ProcessFunction != nil or ItemTable.BloodFor or ItemTable.HealsFor or ItemTable.EatFor or ItemTable.DrinkFor then

        local txt = "Use"
        if ItemTable.DrinkFor then
            txt = "Drink"
        elseif ItemTable.EatFor then
            txt = "Eat"
        end

        local panel = ItemMENU:AddOption(ItemTable.OverrideUseMenu or txt, function()
            RunConsoleCommand("Useitem", it.id)
        end)
        panel.Paint = PaintItemMenus
        ItemMENU:AddSpacer()                                                    
    end

    local panel = ItemMENU:AddOption("Throw 1", function()
        RunConsoleCommand("ThrowItem",it.id,1)
    end )       
    panel.Paint = PaintItemMenus    

    local panel = ItemMENU:AddOption("Drop 1",  function()
        RunConsoleCommand("DropItem",it.id,1)
    end )       
    panel.Paint = PaintItemMenus                    
    
    local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
    if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end
    
    if itemamt > 1 then
        local DropMenu, panel = ItemMENU:AddSubMenu( "Drop X" )
        DropMenu.Paint = PaintItemMenus
        panel.Paint = PaintItemMenus
        if !table.HasValue(amts, itemamt) && itemamt > 1 then
            local panel = ItemMENU:AddOption("Drop "..itemamt, function()
                RunConsoleCommand("DropItem",it.id,amount)
            end)
            panel.Paint = PaintItemMenus
        end

        DropMenu:AddSpacer()

        for k, v in ipairs(amts) do
            if itemamt < v then continue end
            local panel = DropMenu:AddOption("Drop "..v,    function()
                RunConsoleCommand("DropItem",it.id,v)
            end )
            panel.Paint = PaintItemMenus
        end

        local panel = ItemMENU:AddOption("Drop ...", function()
            GUI_Amount_Popup(it.id, "DropItem")
        end)
        panel.Paint = PaintItemMenus
        ItemMENU:AddSpacer()

        local panel = ItemMENU:AddOption("Split 1", function()
            RunConsoleCommand("SplitItem",it.id,1)
        end)
        panel.Paint = PaintItemMenus

        if ItemTable.ClipSize then
            local panel = ItemMENU:AddOption("Split Clip[x"..ItemTable.ClipSize.."]", function()
                RunConsoleCommand("SplitItem",it.id,ItemTable.ClipSize)
            end)
            panel.Paint = PaintItemMenus
        end

        local panel = ItemMENU:AddOption("Split ...", function()
            GUI_Amount_Popup(it.id, "SplitItem")
        end)
        panel.Paint = PaintItemMenus

    end

    if table.Count( Local_Inventory[item] ) > 1 then
        
        local amt = 0
        for k, v in pairs(Local_Inventory[item]) do
            if v.amount > 0 && v.rarity == it.rarity then amt = amt + 1 end
        end

        if amt > 1 then

            ItemMENU:AddSpacer()
            
            local StackMenu, panel = ItemMENU:AddSubMenu( "Stack" )
            StackMenu.Paint = PaintItemMenus
            panel.Paint = PaintItemMenus

            local panel = StackMenu:AddOption( "Stack Same Conditions", function()
                RunConsoleCommand("StackCond",item)
            end)
            panel.Paint = PaintItemMenus

            ItemMENU:AddSpacer()

            local tab = {}
            for k, v in pairs(Local_Inventory[item]) do
                if v.amount < 1 then continue end
                if v.id == it.id then continue end

                if ( it.quality < 100 and v.quality > 100 ) or ( it.quality > 100 and v.quality < 100 ) then continue end
                if it.rarity != v.rarity then continue end

                local itemTable = GAMEMODE.DayZ_Items[item]
                local panel = StackMenu:AddOption( "with "..itemTable.Name.."("..GetCondition(v.quality)..") [x"..v.amount.."]", function()
                    RunConsoleCommand("StackItem",it.id,v.id)
                end)
                panel.Paint = PaintItemMenus

            end
        end
    end

    ItemMENU:AddSpacer()

    local HotBarMenu, panel = ItemMENU:AddSubMenu( "Add to Hotbar" )
    HotBarMenu.Paint = PaintItemMenus
    panel.Paint = PaintItemMenus
    for i=1, 9 do
        local panel = HotBarMenu:AddOption("Slot "..i, function()
            Local_HotBar[i].item = it.id
            Local_HotBar[i].itemclass = it.class
            --HotBarPanel:Remove()
        end)
        panel.Paint = PaintItemMenus
    end

    ItemMENU:Open( gui.MousePos() ) 

    DZ_ItemMENU = ItemMENU

    return ItemMENU
end

net.Receive("dz_updateFounders", function(len)
    local founder = net.ReadString()
    local founder_id = net.ReadInt(32)

    DZ_FounderName[ founder_id ] = founder
end)

DZ_FounderName = DZ_FounderName or {}
local InspectModelPanels = {}
function InspectItem(item, pos, popup, itements, top, itemid, setrarity, setamount)
    if itements && !IsValid(itements) then return end

    for k, v in pairs(InspectModelPanels) do
        if IsValid(v) and IsValid(v:GetEntity()) then
            v:GetEntity():Remove()
        end
    end

    if IsValid(InspectPanel) then --globalised by functions it is called from.
        InspectPanel:Remove()
    end

    if !item and !itemid or !GAMEMODE.DayZ_Items[item] then
        if IsValid(InspectPanel) then InspectPanel:Remove() end
        return
    end

    --if not IsValid(GUI_Main_Frame) then return end
    surface.SetFont("Cyb_Inv_ToolTip")
    local sizex, _ = surface.GetTextSize(GAMEMODE.DayZ_Items[item].Desc)
    sizex = sizex + 111
    -- 106 is Margin and Icon size together.
    surface.SetFont("char_title24")
    local titlex, _ = surface.GetTextSize(GAMEMODE.DayZ_Items[item].Name)
    titlex = titlex + 111

    -- Again, see above comment.
    if sizex < titlex then
        sizex = titlex
    end

    -- In case the description is less in size than the title.
    if sizex < 450 then
        sizex = 450
    end

    -- And a minimum size limit.
    local InspectPanel = vgui.Create("DPanel")
    InspectPanel:SetSize(sizex, 136)
    if !top then
        InspectPanel:SetDrawOnTop(true)
    end

    local posx, posy = gui.MousePos()
    if pos then
        pos.x = pos.x - sizex/2
        pos.y = pos.y - 53
    end

    pos = pos or { x = posx + 1, y = posy + 1 }

    InspectPanel:SetPos(pos.x, pos.y)
    if popup then
        InspectPanel:MakePopup()
    end

    local quality, perish, found_id, foundtype
    local foundwhen = 0
    local amount = setamount or 1

    local rarity = setrarity or 1
    if itements && IsValid(itements) && itements:GetClass() == "base_item" then
        quality = itements:GetQuality()
        rarity = itements:GetRarity()
        amount = itements:GetAmount()
        found_id = itements:GetFounder()
        foundtype = itements:GetFoundType()
        foundwhen = itements:GetFoundWhen()
        perish = math.Round( itements:GetPerish() - CurTime() )
    end

    if itemid then
        local it = GAMEMODE.Util:SearchForItem(itemid)

        if it then         
            amount = it.amount
            quality = it.quality
            rarity = it.rarity
            found_id = it.found_id
            foundtype = it.foundtype
            foundwhen = it.foundwhen
        end
    end
    local ItemTable = GAMEMODE.DayZ_Items[item]

    if ItemTable.Category == "lootboxes" && ItemTable.ID != "item_keypad" then
        rarity = GAMEMODE.DayZ_Items[item].Rarity
    end

    if found_id && !DZ_FounderName[found_id] then
        -- request name from server
        net.Start("dz_foundernameReq")
            net.WriteInt(found_id, 32)
        net.SendToServer()
    end

    local rar_tab = GetRarity( rarity )
    InspectPanel.Paint = function(self, w, h)
        h = h - 30
        if not ( IsValid(GUI_Loot_Frame) or IsValid(GUI_Donate_Frame) or IsValid(GUI_Main_Frame) or IsValid(GUI_Quest_Frame) ) then
            InspectPanel:Remove()
        end

        DrawBlurRect( pos.x, pos.y, w, h )

        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 150))

        local buff = 0
        if perish && IsValid(itements) then
            if !isfunction(itements.GetPerish) then return end

            perish = math.Round( itements:GetPerish() - CurTime() )
            local txt = "[ "..perish.."s ]"
            surface.SetFont("Cyb_Inv_Label")
            local x, y = surface.GetTextSize(txt)

            draw.DrawText(txt, "Cyb_Inv_Label", w - 4, 4, Color(200,200,200,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            buff = x + 5
        end

        if rar_tab then
            local txt = rar_tab.t
            if PHDayZ.DebugMode then
                txt = rar_tab.t .. " ["..item.."]"
            end
            draw.DrawText(txt, "Cyb_Inv_Label", w - buff - 4, 4, rar_tab.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        else
            draw.DrawText("UNDEFINED: "..(rarity or 0), "Cyb_Inv_Label", w - buff - 4, 4, Color(200,200,200,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    local found_types = {}
    found_types[0] = "Spawned"
    found_types[1] = "Found"
    found_types[2] = "Crafted"
    found_types[3] = "Cooked"
    found_types[4] = "Grown"
    found_types[5] = "Bought"
    found_types[6] = "Upgraded"

    InspectPanel.FoundBy = vgui.Create("DPanel", InspectPanel)
    InspectPanel.FoundBy:SetTall(30)
    InspectPanel.FoundBy:Dock(BOTTOM)
    InspectPanel.FoundBy.Paint = function(self, w, h) 
        if foundtype and found_id then
            --if !DZ_FounderName[found_id] then return end
            local id = found_id

            local fw = foundwhen

            if DZ_FounderName[id] then
                id = DZ_FounderName[id]
            end
            if id == 0 then id = "Server" end

            if !found_types[foundtype] then return end

            local text = found_types[foundtype].." by: "..id


            if foundwhen and foundwhen != 0 then
                local time = os.time() - foundwhen

                local t_str = SecondsToClock(time, true, true)
                if t_str == "" then
                    t_str = "<1m"
                end
                text = found_types[foundtype].." "..t_str.." ago by: "..id
            end

            surface.SetFont("char_title18")
            local sizex, sizey = surface.GetTextSize(text)

            draw.RoundedBoxEx(4, (w/2) - (sizex/2) - 10, 0, sizex + 20, h, Color(0, 0, 0, 150), false, false, true, true)
            draw.DrawText(text, "char_title18", w/2, h/2 - 8, Color(200,200,200,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        end
    end

    local panel, modelpanel = DZ_MakeIcon(itemid or nil, item, amount or 0, InspectPanel, nil, nil, 96, 96, true, true, false, false, true, true)
    if !panel then InspectPanel:Remove() return end -- error catch
    
    panel:DockMargin(5, 5, 5, 5)
    panel:Dock(LEFT)
    panel.rarity = rarity

    local item_name = GAMEMODE.DayZ_Items[item].Name
    if GAMEMODE.DayZ_Items[item].Weapon && rar_tab then
        item_name = "'"..rar_tab.wep .."' "..item_name
    end

    local ItemName = vgui.Create("DLabel", InspectPanel)
    ItemName:Dock(TOP)
    ItemName:SetText("★ "..item_name)
    if rar_tab then
        ItemName:SetTextColor(rar_tab.color)
    end
    ItemName:SetFont("char_title24")
    ItemName:SizeToContents()
    if GAMEMODE.DayZ_Items[item].Desc && GAMEMODE.DayZ_Items[item].Desc != "" then
        local ItemDesc = vgui.Create("DLabel", InspectPanel)
        ItemDesc:Dock(TOP)
        ItemDesc:SetText(GAMEMODE.DayZ_Items[item].Desc)
        ItemDesc:SetFont("Cyb_Inv_ToolTip")
        ItemDesc:SizeToContents()
    end
    if GAMEMODE.DayZ_Items[item].Weapon then
        local wep = DZ_GetWeaponTable( GAMEMODE.DayZ_Items[item].Weapon )
        if wep && wep.Primary && wep.Primary.AmmoItem then

            local color = Color(200,0,0,200)
            if LocalPlayer():HasItem(wep.Primary.AmmoItem, 1, true) then
                color = Color(0,200,0,200)
            end

            local name = GAMEMODE.DayZ_Items[wep.Primary.AmmoItem].Name
            local AmmoPanel = vgui.Create("DPanel", InspectPanel)
            AmmoPanel.Paint = function(self, w, h) end
            AmmoPanel:DockMargin(0, 0, 0, 2)
            AmmoPanel:Dock(TOP)
            AmmoPanel:SetSize(200, 16)

            local AmmoImage = DZ_MakeIcon(itemid or nil, wep.Primary.AmmoItem, 0, AmmoPanel, nil, nil, 24, 24, false, true, false, false, true, true)
            AmmoImage.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(200,200,200,10)) end
            AmmoImage:SetPos(-3,-5)
            AmmoImage.rarity = 1

            local AmmoTitle = vgui.Create("DLabel", AmmoPanel)
            AmmoTitle:DockMargin(24, 0, 0, 0)
            AmmoTitle:Dock(LEFT)
            AmmoTitle:SetColor(color)
            AmmoTitle:SetText(name)
            AmmoTitle:SetFont("Cyb_Inv_ToolTip")
            AmmoTitle:SizeToContents()

            if wep.Damage then
                local orig_dmg = wep.Damage
                local dmg = wep.Damage + math.ceil( ( wep.Damage / 100 ) * ( rarity * PHDayZ.WeaponRarityDamagePercent ) ) 
                local s = ""
                if wep.Shots && wep.Shots > 1 then
                    s = " x"..wep.Shots
                end
                local WepDamage = vgui.Create("DLabel", AmmoPanel)
                WepDamage:DockMargin(5, 0, 0, 0)
                WepDamage:Dock(LEFT)
                WepDamage:SetColor( Color(200,200,0,200) )
                WepDamage:SetText(orig_dmg.."+"..dmg - orig_dmg..s)
                WepDamage:SetFont("Cyb_Inv_ToolTip")
                WepDamage:SizeToContents()
            end
        end
    end

    rarity = rarity - 1 -- if it's common, we don't want bonuses. QUICKHACK

    local rads = GAMEMODE.DayZ_Items[item].RadsFor or 0
    rads = rads + math.floor( ( rads/ 10 ) * rarity ) 
    if rads != 0 then
        local color = Color(0,255,0)
        if rads>0 then color=Color(255,0,0) rads = "+"..rads end
        local RadsTitle = vgui.Create("DLabel", InspectPanel)
        RadsTitle:DockMargin(0, 0, 0, 2)
        RadsTitle:Dock(TOP)
        RadsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end
        RadsTitle:SetText(rads.." radiation "..txt)
        RadsTitle:SetFont("Cyb_Inv_ToolTip")
        RadsTitle:SetSize(200, 10)       
    end
    local bps = (GAMEMODE.DayZ_Items[item].BloodFor or 0)*50
    bps = bps + math.floor( ( bps/ 10 ) * rarity )
    if bps != 0 then
        local color = Color(255,0,0)
        if bps>0 then color=Color(0,255,0) bps = "+"..bps end
        local BpsTitle = vgui.Create("DLabel", InspectPanel)
        BpsTitle:DockMargin(0, 0, 0, 2)
        BpsTitle:Dock(TOP)
        BpsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end
        BpsTitle:SetText(bps.." blood "..txt)
        BpsTitle:SetFont("Cyb_Inv_ToolTip")
        BpsTitle:SetSize(200, 10)    
    end
    local dps = (GAMEMODE.DayZ_Items[item].DrinkFor or 0)*10
    dps = dps + math.floor( ( dps/ 10 ) * rarity )
    if dps != 0 then
        local color = Color(255,0,0)
        if dps>0 then color=Color(0,255,0) dps = "+"..dps end
        local DpsTitle = vgui.Create("DLabel", InspectPanel)
        DpsTitle:DockMargin(0, 0, 0, 2)
        DpsTitle:Dock(TOP)
        DpsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end

        DpsTitle:SetText(dps.." thirst "..txt)
        DpsTitle:SetFont("Cyb_Inv_ToolTip")
        DpsTitle:SetSize(200, 10)    
    end
    local eps = (GAMEMODE.DayZ_Items[item].EatFor or 0)*10
    eps = eps + math.floor( ( ( eps/ 20 ) * 3 ) * rarity )
    if eps != 0 then
        local color = Color(255,0,0)
        if eps>0 then color=Color(0,255,0) eps = "+"..eps end
        local EpsTitle = vgui.Create("DLabel", InspectPanel)
        EpsTitle:DockMargin(0, 0, 0, 2)
        EpsTitle:Dock(TOP)
        EpsTitle:SetColor(color)
         local txt = ""
        if (15 * (rarity)) > 0 then
            txt = "+"..(15 * (rarity)).."%"
        end

        EpsTitle:SetText(eps.." food "..txt)
        EpsTitle:SetFont("Cyb_Inv_ToolTip")
        EpsTitle:SetSize(200, 10)    
    end
    local hps = (GAMEMODE.DayZ_Items[item].HealsFor or 0)
    hps = hps + math.floor( ( hps/ 10 ) * rarity )
    if hps != 0 then
        local color = Color(255,0,0)
        if hps>0 then color=Color(0,255,0) hps = "+"..hps end
        local HpsTitle = vgui.Create("DLabel", InspectPanel)
        HpsTitle:DockMargin(0, 0, 0, 2)
        HpsTitle:Dock(TOP)
        HpsTitle:SetColor(color)
         local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end

        HpsTitle:SetText(hps.." health "..txt)
        HpsTitle:SetFont("Cyb_Inv_ToolTip")
        HpsTitle:SetSize(200, 10)    
    end
    local sps = (GAMEMODE.DayZ_Items[item].StaminaFor or 0)
    sps = sps + math.floor( ( sps/ 10 ) * rarity )
    if sps != 0 then
        local color = Color(255,0,0)
        if sps>0 then color=Color(0,255,0) sps = "+"..sps end
        local SpsTitle = vgui.Create("DLabel", InspectPanel)
        SpsTitle:DockMargin(0, 0, 0, 2)
        SpsTitle:Dock(TOP)
        SpsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end
        SpsTitle:SetText(sps.." stamina "..txt)
        SpsTitle:SetFont("Cyb_Inv_ToolTip")
        SpsTitle:SetSize(200, 10)    
    end
    local gps = (GAMEMODE.DayZ_Items[item].GasFor or 0)
    gps = gps + math.floor( ( gps/ 10 ) * rarity )
    if gps != 0 then
        local color = Color(255,0,0)
        if gps>0 then color=Color(0,255,0) gps = "+"..gps end
        local GpsTitle = vgui.Create("DLabel", InspectPanel)
        GpsTitle:DockMargin(0, 0, 0, 2)
        GpsTitle:Dock(TOP)
        GpsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end

        GpsTitle:SetText(gps.." fuel "..txt)
        GpsTitle:SetFont("Cyb_Inv_ToolTip")
        GpsTitle:SetSize(200, 10)    
    end
    local bodyarmor = (GAMEMODE.DayZ_Items[item].BodyArmor or 0)
    if bodyarmor != 0 then
        local color = Color(255,0,0)
        if bodyarmor>0 then color=Color(0,255,0) bodyarmor = "+"..bodyarmor end
        local SpsTitle = vgui.Create("DLabel", InspectPanel)
        SpsTitle:DockMargin(0, 0, 0, 2)
        SpsTitle:Dock(TOP)
        SpsTitle:SetColor(color)
        SpsTitle:SetText(bodyarmor.." armor")
        SpsTitle:SetFont("Cyb_Inv_ToolTip")
        SpsTitle:SetSize(200, 10)    
    end
    local wps = (GAMEMODE.DayZ_Items[item].WeightFor or 0)
    wps = wps + math.ceil( ( wps / 10 ) * rarity )
    if wps != 0 then
        local color = Color(255,0,0)
        if wps>0 then color=Color(0,255,0) wps = "+"..wps end
        local SpsTitle = vgui.Create("DLabel", InspectPanel)
        SpsTitle:DockMargin(0, 0, 0, 2)
        SpsTitle:Dock(TOP)
        SpsTitle:SetColor(color)
        local txt = ""
        if (10 * (rarity)) > 0 then
            txt = "+"..(10 * (rarity)).."%"
        end
        SpsTitle:SetText(wps.." weight "..txt)
        SpsTitle:SetFont("Cyb_Inv_ToolTip")
        SpsTitle:SetSize(200, 16)    
    end
    local price = GAMEMODE.Util:GetItemPrice(item, 1, nil, true, nil, quality, nil, rarity)
    local price_amt = price * amount

    local weight = GAMEMODE.DayZ_Items[item].Weight
    local WeightTitle = vgui.Create("DLabel", InspectPanel)
    WeightTitle:DockMargin(0, 0, 0, 5)
    WeightTitle:Dock(BOTTOM)
    WeightTitle:SetText("")
    WeightTitle:SetSize(200, 20)
    WeightTitle.Paint = function(self, w, h)
        local distx = 0
        if quality && ( item != "item_money" && !GAMEMODE.DayZ_Items[item].IsCurrency ) then
            local text = "Condition: "
            draw.DrawText(text, "Cyb_Inv_ToolTip", 0, 5, Color(200,200,200,200), TEXT_ALIGN_LEFT)
            local cx, _ = surface.GetTextSize(text)
            distx = distx + cx

            text = GetCondition(quality, true)
            draw.DrawText(text, "Cyb_Inv_ToolTip", distx, 5, ColorLerp(quality), TEXT_ALIGN_LEFT)
            local qx, _ = surface.GetTextSize(text)
            distx = distx + qx
        end

        local padding = 0
        local text = ( quality && !GAMEMODE.DayZ_Items[item].IsCurrency ) and "• Weight: "..weight or "Weight: "..weight
        if weight >= 0 then
            if distx > 0 then
                padding = 5
            end
            draw.DrawText(text, "Cyb_Inv_ToolTip", distx + padding, 5, Color(200, 200, 200, 200), TEXT_ALIGN_LEFT)
            local titlex, _ = surface.GetTextSize(text)
            distx = distx + titlex
        end

        local text2 = ""
        if price > 0 then
            text = "• Worth: "

            if price != price_amt && price_amt > 0 then
                text2 = " | $"..price_amt
            end

            draw.DrawText(text, "Cyb_Inv_ToolTip", distx + padding + 5, 5, Color(200, 200, 200, 200), TEXT_ALIGN_LEFT)
            local titlex, _ = surface.GetTextSize(text)
            distx = distx + titlex
            draw.DrawText("$"..price..text2, "Cyb_Inv_ToolTip", distx + padding + 5, 5, Color(200, 200, 0, 200), TEXT_ALIGN_LEFT)
        end
    end

    return InspectPanel
end

function UpdateCharPanels()
    if IsValid(CharSlot1) then
        CharSlot1:Remove()
    end

    -- Hats
    if IsValid(CharSlot2) then
        CharSlot2:Remove()
    end

    -- Clothes
    if IsValid(CharSlot3) then
        CharSlot3:Remove()
    end

    -- Primaries
    if IsValid(CharSlot4) then
        CharSlot4:Remove()
    end

    -- Secondaries 
    if IsValid(CharSlot5) then
        CharSlot5:Remove()
    end

    -- Melees
    if IsValid(CharSlot6) then
        CharSlot6:Remove()
    end

    -- Tertiaries
    if IsValid(CharSlot7) then
        CharSlot7:Remove()
    end

    -- Backpacks
    if IsValid(CharSlot8) then
        CharSlot8:Remove()
    end

    -- Shoes
    if IsValid(CharSlot9) then
        CharSlot9:Remove()
    end

     if IsValid(CharSlot10) then
        CharSlot10:Remove()
    end

    -- Pants
    local charslotcolor = Color(0, 0, 0, 50)
    CharSlot1 = vgui.Create("DPanel", CharPanel)
    CharSlot1:SetSize(98, 98)
    CharSlot1:SetPos(145, 20)

    CharSlot1.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categoryhats"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot1:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot1 then return end
        if table.Count(CharSlot1:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Hat ~= nil then
            if GAMEMODE.DayZ_Items[tbl[1].ItemClass].VIP and not LocalPlayer():IsVIP() then
                chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "This Hat is VIP Only! Sorry!")

                return
            end

            tbl[1]:SetSize(94, 94)
            tbl[1]:SetPos(2, 2)
            tbl[1]:GetChild(1):SetSize(90, 90)
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Hat Items go in this slot!")
        end
    end)

    CharSlot2 = vgui.Create("DPanel", CharPanel)
    CharSlot2:SetSize(98, 98)
    CharSlot2:SetPos(145, 125)

    CharSlot2.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categoryclothes"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot2:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot2 then return end
        if table.Count(CharSlot2:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Body ~= nil then
            tbl[1]:SetSize(94, 94)
            tbl[1]:SetPos(2, 2)
            tbl[1]:GetChild(1):SetSize(90, 90)
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Clothing Items go in this slot!")
        end
    end)

    CharSlot9 = vgui.Create("DPanel", CharPanel)
    CharSlot9:SetSize(98, 98)
    CharSlot9:SetPos(145, 230)

    CharSlot9.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorypants"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot9:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot9 then return end
        if table.Count(CharSlot9:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Pants ~= nil then
            tbl[1]:SetSize(94, 94)
            tbl[1]:SetPos(2, 2)
            tbl[1]:GetChild(1):SetSize(90, 90)
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Pants go in this slot!")
        end
    end)

    CharSlot8 = vgui.Create("DPanel", CharPanel)
    CharSlot8:SetSize(98, 98)
    CharSlot8:SetPos(145, 335)

    CharSlot8.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categoryshoes"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot8:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot8 then return end
        if table.Count(CharSlot8:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Shoes ~= nil then
            tbl[1]:SetSize(94, 94)
            tbl[1]:SetPos(2, 2)
            tbl[1]:GetChild(1):SetSize(90, 90)
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Shoes go in this slot!")
        end
    end)

    CharSlot3 = vgui.Create("DPanel", CharPanel)
    -- Primary Weapon
    CharSlot3:SetSize(64, 64)
    CharSlot3:SetPos(250, 264)

    CharSlot3.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categoryprimaries"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot3:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot3 then return end
        if table.Count(CharSlot3:GetChildren()) > 0 then return end
        if LocalPlayer():GetFreshSpawn() > CurTime() then chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "You cannot equip a Primary while on Fresh Spawn cooldown!") return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Primary ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Primary Items go in this slot!")
        end
    end)

    CharSlot4 = vgui.Create("DPanel", CharPanel)
    -- Secondary Weapon
    CharSlot4:SetSize(64, 64)
    CharSlot4:SetPos(250, 335)

    CharSlot4.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorysecondaries"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot4:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot4 then return end
        if table.Count(CharSlot4:GetChildren()) > 0 then return end
        if LocalPlayer():GetFreshSpawn() > CurTime() then chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "You cannot equip a Secondary while on Fresh Spawn cooldown!") return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Secondary ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Secondary Items go in this slot!")
        end
    end)

    CharSlot10 = vgui.Create("DPanel", CharPanel)
    -- BodyArmor!
    CharSlot10:SetSize(64, 64)
    CharSlot10:SetPos(74, 125)

    CharSlot10.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorybodyarmor"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot10:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot10 then return end
        if table.Count(CharSlot10:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].BodyArmor ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Bodyarmor goes in this slot!")
        end
    end)

    CharSlot5 = vgui.Create("DPanel", CharPanel)
    -- Melee Weapon
    CharSlot5:SetSize(64, 64)
    CharSlot5:SetPos(74, 264)

    CharSlot5.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorymelee"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot5:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot5 then return end
        if table.Count(CharSlot5:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Melee ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Melee Items go in this slot!")
        end
    end)

    CharSlot6 = vgui.Create("DPanel", CharPanel)
    -- Melee Weapon
    CharSlot6:SetSize(64, 64)
    CharSlot6:SetPos(74, 335)

    CharSlot6.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorytertiaries"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot6:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot6 then return end
        if table.Count(CharSlot6:GetChildren()) > 0 then return end
        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].Tertiary ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Tertiary Items go in this slot!")
        end
    end)

    CharSlot7 = vgui.Create("DPanel", CharPanel)
    -- Backpacks!
    CharSlot7:SetSize(64, 64)
    CharSlot7:SetPos(250, 125)

    CharSlot7.Paint = function(self, w, h)
        if table.Count(self:GetChildren()) == 0 then
            draw.DrawText(LANG.GetTranslation("categorybackpacks"), "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(0, 0, 0, w, h, charslotcolor)
    end

    CharSlot7:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end
        if tbl[1]:GetParent() == CharSlot7 then return end
        if table.Count(CharSlot7:GetChildren()) > 0 then return end

        if GAMEMODE.DayZ_Items[tbl[1].ItemClass].BackPack ~= nil then
            tbl[1]:SetParent(pnl)
            RunConsoleCommand("Equipitem", tbl[1].ItemID)
        else
            chat.AddText(Color(0, 255, 0, 255), "[Inventory] ", Color(255, 255, 255, 255), "Backpacks go in this slot!")
        end
    end)

    local ran = {}
    for k, items in pairs(Local_Character) do
        if ran[k] then continue end

        local amount = 0
        for _, item in pairs(items) do
            amount = amount + item.amount
        end

        if amount < 1 then continue end
        if GAMEMODE.DayZ_Items[k].Hat then
            UpdateCharItems(CharSlot1, k)
        elseif GAMEMODE.DayZ_Items[k].Body then
            UpdateCharItems(CharSlot2, k)
        elseif GAMEMODE.DayZ_Items[k].Primary then
            UpdateCharItems(CharSlot3, k, 60, 60)
        elseif GAMEMODE.DayZ_Items[k].Secondary then
            UpdateCharItems(CharSlot4, k, 60, 60)
        elseif GAMEMODE.DayZ_Items[k].Melee then
            UpdateCharItems(CharSlot5, k, 60, 60)
        elseif GAMEMODE.DayZ_Items[k].Tertiary then
            UpdateCharItems(CharSlot6, k, 60, 60)
        elseif GAMEMODE.DayZ_Items[k].BackPack then
            UpdateCharItems(CharSlot7, k, 60, 60)
        elseif GAMEMODE.DayZ_Items[k].Shoes then
            UpdateCharItems(CharSlot8, k)
        elseif GAMEMODE.DayZ_Items[k].Pants then
            UpdateCharItems(CharSlot9, k)
        elseif GAMEMODE.DayZ_Items[k].BodyArmor then
            UpdateCharItems(CharSlot10, k, 60, 60)
        end
        ran[k] = true
    end
end

function GUI_Rebuild_Inv(parent)
    if GUI_Loot_Frame ~= nil and GUI_Loot_Frame:IsValid() then
        GUI_Loot_Frame:Remove()
    end

    if not IsValid(parent) then return end

    for k, v in pairs(InventoryModelPanels) do
        if IsValid(v) then
            v:Remove()
        end
    end

    if GUI_Inv_Item_Panel ~= nil and GUI_Inv_Item_Panel:IsValid() then
        GUI_Inv_Item_Panel:Clear()
    end

    RightPanel = vgui.Create("DPanelList", parent)
    RightPanel:SetWide(298)
    RightPanel:DockMargin(0, 0, 5, 0)
    RightPanel:Dock(RIGHT)

    RightPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 20, 0, w, h, Color(30, 30, 30, 120))
    end

    GUI_Inv_Panel_List = vgui.Create("DPanelList", parent)
    --GUI_Inv_Panel_List:SetSize(270,505)
    --GUI_Inv_Panel_List:SetPos(10,1)
    GUI_Inv_Panel_List:SetWide(452)
    GUI_Inv_Panel_List:DockMargin(5, 0, 0, 0)
    GUI_Inv_Panel_List:Dock(LEFT)

    GUI_Inv_Panel_List.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 100))
    end

    GUI_Inv_Panel_List:SetPadding(7.5)
    GUI_Inv_Panel_List:SetSpacing(2)
    GUI_Inv_Panel_List:EnableHorizontal(3)
    GUI_Inv_Panel_List:EnableVerticalScrollbar(true)

    GUI_Inv_Panel_List:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end

        if tbl[1]:GetParent() == pnl then 
            --print(tbl[1].ItemClass.." wants SplitItem "..tbl[1].Amount/2)
            RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount/2)
            return 
        end
        --tbl[1]:SetSize(66, 66)
        --tbl[1]:GetChild(1):SetSize(50, 50)
        --GUI_Inv_Panel_List:AddItem(tbl[1])
        RunConsoleCommand("Dequipitem", tbl[1].ItemID)
    end)

    CharPanel = vgui.Create("DPanelList", RightPanel)
    CharPanel:SetPos(-33, 0)
    CharPanel:SetSize(400, 500)
    CharPanel.Paint = function(self, w, h) 
        --draw.DrawText("Equipped:", "char_title18", 57, 5, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT)
        --draw.RoundedBox(0, 0, 0, 5, h, Color(30, 30, 30, 120)) 
    end
    InvPlayerModel = vgui.Create("DModelPanel", CharPanel)
    InvPlayerModel:SetModel(LocalPlayer():GetModel())
    InvPlayerModel:GetEntity():SetSkin(LocalPlayer():GetSkin())
     
    InvPlayerModel:GetEntity():SetBodyGroups(LocalPlayer():GetBodyGroups())

    InvPlayerModel.Entity.GetPlayerColor = function() return Vector(GetConVarString("cl_playercolor")) end
    InvPlayerModel:SetSize(500, 500)
    InvPlayerModel:SetPos(-50, -40)

    function InvPlayerModel:LayoutEntity(ent)
        ent:SetSequence(LocalPlayer():GetSequence())
        InvPlayerModel:RunAnimation()

        return
    end

    table.insert(InventoryModelPanels, InvPlayerModel)
    
    UpdateCharPanels()

    UpdateInv()

    GUI_Weight_Bar = vgui.Create("DPanelList", RightPanel)
    GUI_Weight_Bar:Dock(BOTTOM)
    GUI_Weight_Bar:DockMargin(25, 5, 5, 5)

    local weight_smooth = 0
    GUI_Weight_Bar.Paint = function(self, w, h)
        local maxweight = LocalPlayer():GetWeightMax()

        if TotalWeight then
            draw.RoundedBoxEx(0, 0, 0, w, h, Color(40, 40, 40, 255), true, true, true, true)

            local per = (TotalWeight / maxweight)
            local wei = (w-2) * per

            weight_smooth = math.Approach( weight_smooth, wei, 80 * FrameTime() )
            weight_smooth = math.floor(weight_smooth)

            local perc = math.floor(weight_smooth / w * 100)

            if wei > 0 then
                local col = Color(0,0,0,0)

                if perc < 50 then
                    col = Color(0,200,0,100)
                elseif perc >= 50 and perc < 80 then
                    col = Color(200,200,0,100)
                elseif perc >= 80 then 
                    col = Color(200,0,0,100)
                end

                draw.RoundedBoxEx(0, 1, 1, weight_smooth, h - 2, col, true, true, false, false)

                draw.RoundedBoxEx(0, 1, 1, weight_smooth, h - 2, Color(60, 60, 60, 200), true, true, false, false)

            end

            draw.DrawText(LANG.GetTranslation("backpackweight"), "char_title16", 5, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT)
            draw.DrawText(TotalWeight .. "/" .. maxweight.." ("..math.floor(per*100).."%)", "char_title16", w - 5, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT)
        end
    end

    GUI_Weight_Bar:SetPadding(7.5)
    GUI_Weight_Bar:SetSpacing(2)
    GUI_Weight_Bar:EnableHorizontal(3)
    GUI_Weight_Bar:EnableVerticalScrollbar(true)

    local Perk_Panel = vgui.Create("DPanel", RightPanel)
    Perk_Panel:Dock(BOTTOM)
   
    local i = 0
    for k, v in pairs(Local_PerkTable) do
        if !GAMEMODE.DayZ_Items[k] then continue end
        i = i + 1
    end

    local size = 34
    local tall = size
    if i > 8 then
        tall = math.ceil(i / 8) * size
    end
    Perk_Panel:SetTall(tall)
    Perk_Panel.amt = i
    Perk_Panel:DockMargin(25, 5, 5, 5)
    Perk_Panel.Paint = function() end

    local Perk_Container = vgui.Create("DIconLayout", Perk_Panel)
    Perk_Container:Dock(FILL)
    Perk_Container:SetLayoutDir(LEFT)
    Perk_Container:DockMargin(0, 0, 0, 0)
    Perk_Container.Paint = function() end
    Perk_Container.Think = function(self)
        if ( self.nextThink or 0 ) > CurTime() then return end
        
        local i = 0
        for k, v in pairs(Local_PerkTable) do
            if !GAMEMODE.DayZ_Items[k] then continue end
            i = i + 1
        end

        if ( self.amt or 0 ) != i then

            self:Clear()

            for k, v in pairs(Local_PerkTable) do
                if !GAMEMODE.DayZ_Items[k] then continue end

                local panel, modelpanel = DZ_MakeIcon( nil, k, 0, self, nil, nil, size - 2, size - 2, false, true )
                panel:SetTooltip(GAMEMODE.DayZ_Items[k].Name.." - "..GAMEMODE.DayZ_Items[k].Desc)

                modelpanel.OnCursorEntered = function()end

                modelpanel.OnCursorExited = function()end

                table.insert(InventoryModelPanels, modelpanel)

                self:Add(panel)
                self:InvalidateLayout()

            end

            self.amt = i
        end
        self.nextThink = CurTime() + 1
    end

end

function ClearSlot(pnl, time)
    timer.Simple(0.5, function()
        timer.Simple(time or ProcessTime - 0.5 or 0, function()
            if not IsValid(pnl) then return end

            if pnl:GetChildren()[1] then
                pnl:GetChildren()[1]:Remove()
            end

            UpdateInv()
        end)
    end)
end

function GUI_Amount_Popup(item)
    if GUI_Amount_Frame ~= nil and GUI_Amount_Frame:IsValid() then
        GUI_Amount_Frame:Remove()
    end

    local GUI_Amount_Frame = vgui.Create("DFrame")
    GUI_Amount_Frame:Center()
    GUI_Amount_Frame:SetSize(200, 100)
    GUI_Amount_Frame:MakePopup()
    GUI_Amount_Frame:SetTitle("Amount")

    GUI_Amount_Frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, Color(46, 36, 26, 255))
    end

    local GUI_Amount_slider = vgui.Create("DNumSlider", GUI_Amount_Frame)
    GUI_Amount_slider:SetWide(270)
    GUI_Amount_slider:SetPos(-80, 25)
    GUI_Amount_slider:SetText("")
    GUI_Amount_slider:SetMin(1)
    GUI_Amount_slider:SetMax(Local_Inventory[item])
    GUI_Amount_slider:SetDecimals(0)
    GUI_Amount_slider:SetValue(1)

    local GUI_Drop_Button = vgui.Create("DButton", GUI_Amount_Frame)
    GUI_Drop_Button:SetPos(10, 70)
    GUI_Drop_Button:SetSize(180, 15)
    GUI_Drop_Button:SetText("")

    GUI_Drop_Button.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 255))
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(139, 133, 97, 55))
        local struc = {}
        struc.pos = {}
        struc.pos[1] = 90
        -- x pos
        struc.pos[2] = 7
        -- y pos
        struc.color = Color(255, 255, 255, 255)
        -- Red
        struc.text = "Confirm"
        -- Text
        struc.xalign = TEXT_ALIGN_CENTER
        -- Horizontal Alignment
        struc.yalign = TEXT_ALIGN_CENTER
        -- Vertical Alignment
        draw.Text(struc)
    end

    GUI_Drop_Button.DoClick = function()
        RunConsoleCommand("Dropitem", item, GUI_Amount_slider:GetValue())
        GUI_Amount_Frame:Remove()
        timer.Simple(0.3, Rebuild_Backup)
    end
end