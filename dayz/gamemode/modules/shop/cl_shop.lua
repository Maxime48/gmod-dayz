net.Receive("RefreshShopInv", function(len)
    if IsValid(ShopInv) then
        UpdateShopInv("shop_inv")
    end
end)

net.Receive("ShopTable", function(len)
    local tab = net.ReadTable()
    local cat = net.ReadString()
    if cat == "" then cat = nil end

    GAMEMODE.DayZ_Shops["shop_buy"] = tab

    if IsValid(ShopPanel) then
        UpdateShopInv(true, cat)
    end
end)

ShopItemModelPanels = ShopItemModelPanels or {}
ShopModelPanels = ShopModelPanels or {}
ShopInvModelPanels = ShopInvModelPanels or {}
categoryShopPanels = categoryShopPanels or {}
categoryInvShopPanels = categoryInvShopPanels or {}
SP = SP or {}
function paint_bg(self, w, h)
   draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
end


function GUI_Rebuild_Shop_Items(parent)
    if parent ~= nil and parent:IsValid() then
        parent:Clear()
    end
    timer.Destroy("sellall_") -- fallback incase it still ran for whatever reason

    local function paint_bg(self, w, h)
        draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
    end

    ShopItemPanel = vgui.Create("DPanel", parent)
    ShopItemPanel:Dock(BOTTOM)
    ShopItemPanel:SetTall(95)
    ShopItemPanel:DockMargin(5, 5, 5, 5)
    ShopItemPanel.Displayed = false

    local title_shop = vgui.Create("DPanel", parent)
    title_shop:Dock(TOP)
    title_shop:SetTall(20)
    title_shop:DockMargin(5, 5, 5, 0)
    title_shop.Paint = function(self, w, h)
        paint_bg(self, w, h)

        draw.SimpleText("Your Items:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText("Shop Items:", "char_title20", 360, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

    ShopInv = vgui.Create("DPanel", parent)
    ShopInv:Dock(LEFT)
    ShopInv:SetWide( 363 )
    ShopInv:DockMargin(5, 5, 0, 0)
    ShopInv.Paint = paint_bg

    ShopPanel = vgui.Create("DPanel", parent)
    ShopPanel:Dock(FILL)
    ShopPanel:DockMargin(5, 5, 5, 0)
    ShopPanel.Paint = paint_bg
    
    ShopItemPanel.Paint = function(self, w, h)
        paint_bg(self, w, h)
        --draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
        if self.Displayed then return end
        draw.SimpleText("Click on an item to see Sale options", "SafeZone_INFO", w / 2, h / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local function sell_alltimer(cat)
        local item_tab = {}

        local t_name = "sellall_"..(cat or "")

        timer.Create(t_name, 0.1, 0, function()
            if !IsValid(parent) then timer.Destroy(t_name) return end
            
            local it_id, amount, lastCat

            if table.Count(item_tab) < 1 then
                for _, items in pairs(Local_Inventory) do
                
                    for k, it in pairs( items ) do
                        if it.amount < 1 then continue end
                        local ItemTable = GAMEMODE.DayZ_Items[it.class]
                        local itemCat = ( ItemTable.Category or "" )

                        if cat and itemCat != cat then continue end
                        if itemCat == "none" or itemCat == "lootboxes" then continue end

                        if ItemTable.IsCurrency then continue end
                        if ItemTable.CantSell then continue end
                        if !GAMEMODE.Util:GetItemPrice(it.class) then continue end

                        table.insert(item_tab, { id = it.id, amount = it.amount, cat = itemCat })
                    end

                end
            end

            if item_tab[1] then
                it_id = item_tab[1].id
                amount = item_tab[1].amount

                local cc = item_tab[1].cat

                if !cat && lastCat != cc then
                    timer.Simple(0.1, function() UpdateShopInv(true, cc) end)
                end

                lastCat = cc
                table.remove(item_tab, 1)
            end

            if !it_id then timer.Destroy(t_name) if cat then timer.Simple(0.1, function() UpdateShopInv(true, cat) end) end return end

            RunConsoleCommand("SellItemMoney", it_id, amount, LocalPlayer():IsVIP() and 1 or 0 )
        end)
    end
    
    local itemCategories = GAMEMODE.Util:GetItemCategories()
    local sell_all = vgui.Create("DButton", title_shop)
    sell_all:SetPos(90, 1)
    sell_all:SetSize(60,18)
    sell_all:SetText("Sell ...")
    sell_all.Paint = PaintButtons
    sell_all.DoClick = function()
        ItemMENU = DermaMenu()

        local panel = ItemMENU:AddOption("Sell All",   function()
            sell_alltimer()
        end)
        panel.Paint = PaintItemMenus

        ItemMENU:AddSpacer()

        for k, cat in pairs(itemCategories) do
            if !IsValid( categoryInvShopPanels[cat].List ) then continue end

            local children = categoryInvShopPanels[cat].List:GetChildren()
    
            if cat == "" or cat == "none" or cat == "lootboxes" or ( table.Count(children) < 1 ) then continue end

            local panel = ItemMENU:AddOption("Sell "..firstToUpper(cat),   function()
                sell_alltimer(cat)
            end)
            panel.Paint = PaintItemMenus
        end
        
        ItemMENU:Open( gui.MousePos() )

        DZ_ItemMENU = ItemMENU
    end

    timer.Simple(0, function() UpdateShopInv(true) end)
end

local function ShopPanelSetItem(item, it)
    if item == "item_money" then ShopPanel.SelectedItemPanel = nil return end -- NOPE

    local itemid, quality 
    local rarity = 1
    if it then
        itemid = it.id
        quality = it.quality
        rarity = it.rarity
    end

    local vip = false
    if IsValid( GUI_Donate_Frame ) then 
        vip = GUI_Donate_Frame.vip or false
    end

    ShopItemPanel.Displayed = true
    for k, v in pairs(ShopItemModelPanels) do
        if !IsValid(v) then continue end
        
        --print(v, "removed")
        v:Remove()
    end

    ShopItemPanel:Clear()

    local panel, craftableItemModelPanel = DZ_MakeIcon( itemid, item, 0, ShopItemPanel, nil, nil, 90, 90, false, true, false, nil, nil )
    panel:SetPos(2, 2)
    panel.rarity = rarity
    
    table.insert(ShopItemModelPanels, craftableItemModelPanel)

    local ItemName = vgui.Create("DLabel", ShopItemPanel)
    ItemName:SetColor(Color(255, 255, 255, 255))
    ItemName:SetFont("Cyb_Inv_Bar")
    ItemName:SetText(GAMEMODE.DayZ_Items[item].Name)
    ItemName:SizeToContents()
    ItemName:SetPos(100, 10)
    local Description = vgui.Create("DLabel", ShopItemPanel)
    Description:SetColor(Color(255, 255, 255, 255))
    Description:SetFont("Cyb_Inv_Label")
    Description:SetText(GAMEMODE.DayZ_Items[item].Desc)
    Description:SizeToContents()
    Description:SetPos(100, 30)
    local buttontext = LANG.GetTranslation("buy")
    local buttontext2 = LANG.GetTranslation("sell")
    local buttonamount = " x1"
    local CraftAmount = vgui.Create("DNumSlider", ShopItemPanel)
    local DoCook = vgui.Create("DButton", ShopItemPanel)
    --DoCook.Paint = function() end
    local DoCook2 = vgui.Create("DButton", ShopItemPanel)
    DoCook.Paint = PaintButtons
    DoCook2.Paint = PaintButtons

    local price = GAMEMODE.Util:GetItemPrice(item, 1, true, true, nil, quality, nil, rarity)
    local cur = "$"

    local reduction = GAMEMODE.Util:GetItemPrice(item, 1, true, nil, nil, quality, vip, rarity)
    CraftAmount:SetText("")
    local max = 100
    if itemid then
        max = LocalPlayer():GetItemAmount(itemid)
    else
        max = GAMEMODE.DayZ_Shops["shop_buy"][item] or 1
    end
    max = math.Clamp(max, 1, 1000)

    CraftAmount:SetMinMax(1, max)
    CraftAmount:SetDecimals(0)
    CraftAmount:SetPos(175, 54)
    CraftAmount:SetSize(270, 30)
    CraftAmount:SetValue(1)

    CraftAmount.Paint = function(self, w, h)
        draw.RoundedBox(2,110,-10,w,h+20,Color( 50, 50, 50, 255 ))
    end
    CraftAmount.TextArea:Hide()

    CraftAmount.Scratch:SetColor(Color(200,200,200,255))

    CraftAmount.Think = function(s)
        s:SetValue(math.Round(s:GetValue()))

        local amount = s:GetValue() or 1
        price = GAMEMODE.Util:GetItemPrice(item, amount, true, true, nil, quality, nil, rarity)
        reduction = GAMEMODE.Util:GetItemPrice(item, amount, true, nil, nil, quality, vip, rarity)

        -- Because SetDecimals is cancer.
        
        buttonamount = " x" .. math.Round(s:GetValue())
        DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")
        DoCook2:SetText(buttontext2 .. buttonamount .. " (" .. "+$" .. reduction .. ")")

        if rarity > 1 or price < 1 then
            DoCook:SetVisible(false)
        end

        if !GAMEMODE.DayZ_Shops["shop_buy"][item] or GAMEMODE.DayZ_Shops["shop_buy"][item] < 1 then 
            DoCook:SetVisible(false) -- shop doesn't have it for sale, cannot buy it.
        end

        if not DoCook:IsVisible() and not DoCook2:IsVisible() then
            CraftAmount:SetVisible(false)
        end
    end

    local HasAmount = vgui.Create("DLabel", ShopItemPanel)
    HasAmount:SetText("")

    HasAmount.Paint = function(self, w, h)
        --draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)
        if LocalPlayer():GetItemAmount(item, true) > 0 then
            draw.DrawText("x" .. LocalPlayer():GetItemAmount(item, true), "SafeZone_INFO", w / 2 - 5, 0, Color(200, 200, 200, 200), TEXT_ALIGN_RIGHT)
        end

        if Local_PerkTable[item] then
            draw.DrawText("Already Used", "Cyb_Inv_Bar", w / 2 - 5, h - 20, Color(Pulsate(1) * 255, 0, 0, 200), TEXT_ALIGN_RIGHT)
        end
    end

    HasAmount:SetSize(400, 95)
    HasAmount:SetPos(ShopItemPanel:GetWide() - HasAmount:GetWide() / 2, 0)
    DoCook2:SetFont("char_title20")
    DoCook2:SetText(buttontext2 .. buttonamount .. " (" .. "+$" .. reduction .. ")")
    DoCook2:SetSize(180, 20)
    DoCook2:SetPos(100, 70)

    DoCook2.DoClick = function()
        RunConsoleCommand("SellItemMoney", itemid or item, CraftAmount:GetValue(), vip and 1 or 0)
    end

    DoCook:SetFont("char_title20")
    DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")
    DoCook:SetSize(180, 20)
    DoCook:SetPos(100, 50)

    DoCook.DoClick = function()
        --if GAMEMODE.DayZ_Items[item].Price then
            --print("buying")
            RunConsoleCommand("BuyItemMoney", item, CraftAmount:GetValue(), vip and 1 or 0)
        --end
    end

    craftableItemModelPanel.Think = function()
        if GAMEMODE.DayZ_Shops["shop_buy"][item] then
            DoCook:SetVisible( GAMEMODE.DayZ_Shops["shop_buy"][item] > 0 && price > 0 )
        end
        DoCook2:SetVisible(LocalPlayer():HasItem(item, true) and ( price > 0 ) )
    end
end


local ammotable = {}
function UpdateShopInv(updateInv, catUpdate)

    local t_name = "sellall_"..(catUpdate or "")

    if timer.Exists(t_name) then return end -- don't update while we spam, we don't want 1fps.
    
    if !IsValid(ShopPanel) then return end -- ran too early?
    if !IsValid(ShopInv) then return end -- ran too early?

    if IsValid(ShopPanel) && !catUpdate then
        ShopPanel:Clear(true)
    end

    if IsValid(ShopInv) && !catUpdate && updateInv then
        ShopInv:Clear(true)
    end

    local itemCategories = GAMEMODE.Util:GetItemCategories()
    if !catUpdate and IsValid(categoryShopScroll) then categoryShopScroll:Remove() end
    if !catUpdate and IsValid(categoryShopInvScroll) then categoryShopInvScroll:Remove() end
    
    if !IsValid(categoryShopInvScroll) then
        categoryShopInvScroll = vgui.Create("DScrollPanel", ShopInv)
        categoryShopInvScroll:SetWide( 360 )
        categoryShopInvScroll:Dock(FILL)
        categoryShopInvScroll.Paint = function(self, w, h) end
        categoryShopInvScroll.Think = function(self)
            if ( self.NextThink or 0 ) > CurTime() then return end

            local children = self:GetCanvas():GetChildren()
            for k, child in pairs(children) do
                if !child:IsVisible() then
                    child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
                end
            end

            self.NextThink = CurTime() + 0.5
        end

        local ScrollBar = categoryShopInvScroll:GetVBar();

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
        
            categoryInvShopPanels[category] = vgui.Create("DCollapsibleCategory", categoryShopInvScroll)
            categoryInvShopPanels[category]:SetLabel("")
            categoryInvShopPanels[category]:SetWide( 350 )
            categoryInvShopPanels[category]:Dock(TOP)
            categoryInvShopPanels[category]:DockMargin(0, 0, 0, 5)
            categoryInvShopPanels[category]:DockPadding(0, 0, 0, 5)

            categoryInvShopPanels[category].Paint = function(self, w, h)
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

            categoryInvShopPanels[category].List = vgui.Create("DIconLayout", categoryInvShopPanels[category] )
            categoryInvShopPanels[category].List:SetPos(0, 25)
            categoryInvShopPanels[category].List:SetSize( 370, 300)
            categoryInvShopPanels[category].List:SetSpaceX(5)
            categoryInvShopPanels[category].List:SetSpaceY(5)
            categoryInvShopPanels[category].List:SetBorder(5)
            categoryInvShopPanels[category].List:Receiver("cat_slot", function(pnl, tbl, dropped, menu, x, y)
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
            categoryInvShopPanels[category].List.Paint = function(self, w, h)
                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
            end

            categoryInvShopPanels[category].Think = function(self, vis)
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

    if !IsValid(categoryShopScroll) then
        categoryShopScroll = vgui.Create("DScrollPanel", ShopPanel)
        categoryShopScroll:SetWide( 350 )
        categoryShopScroll:Dock(FILL)
        categoryShopScroll.Paint = function(self, w, h) end
        categoryShopScroll.Think = function(self)
            if ( self.NextThink or 0 ) > CurTime() then return end

            local children = self:GetCanvas():GetChildren()
            for k, child in pairs(children) do
                if !child:IsVisible() then
                    child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
                end
            end

            self.NextThink = CurTime() + 0.5
        end

        local ScrollBar = categoryShopScroll:GetVBar();

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
            
            categoryShopPanels[category] = vgui.Create("DCollapsibleCategory", categoryShopScroll)
            categoryShopPanels[category]:SetLabel("")
            categoryShopPanels[category]:SetWide( 350 )
            categoryShopPanels[category]:Dock(TOP)
            categoryShopPanels[category]:DockMargin(0, 0, 0, 5)
            categoryShopPanels[category]:DockPadding(0, 0, 0, 5)

            categoryShopPanels[category].Paint = function(self, w, h)
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

            categoryShopPanels[category].List = vgui.Create("DIconLayout", categoryShopPanels[category] )
            categoryShopPanels[category].List:SetPos(0, 25)
            categoryShopPanels[category].List:SetSize( 370, 300)
            categoryShopPanels[category].List:SetSpaceX(5)
            categoryShopPanels[category].List:SetSpaceY(5)
            categoryShopPanels[category].List:SetBorder(5)
            categoryShopPanels[category].List:Receiver("cat_slot", function(pnl, tbl, dropped, menu, x, y)
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
            categoryShopPanels[category].List.Paint = function(self, w, h)
                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
            end

            categoryShopPanels[category].Think = function(self, vis)
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

    if !catUpdate then

        for k, v in pairs(itemCategories) do
            if categoryShopPanels[v] then

                if ShopModelPanels[v] then
                    for k, v in pairs(ShopModelPanels[v]) do
                        if !IsValid(v) then continue end
                        
                        --print(v, "removed")
                        v:Remove()
                    end
                end

                if IsValid(categoryShopPanels[v].List) then
                    categoryShopPanels[v].List:Clear()
                end
            end
            if updateInv && categoryInvShopPanels[v] then

                if ShopModelPanels[v] then
                    for k, v in pairs(ShopModelPanels[v]) do
                        if !IsValid(v) then continue end
                        
                        --print(v, "removed")
                        v:Remove()
                    end
                end

                if IsValid(categoryInvShopPanels[v].List) then
                    categoryInvShopPanels[v].List:Clear()
                end
            end
        end
        --print("clearing and rebuilding all")
    else
        -- we just have the one category to update
        if categoryShopPanels[catUpdate] then 

            if ShopModelPanels[catUpdate] then
                for k, v in pairs(ShopModelPanels[catUpdate]) do
                    if !IsValid(v) then continue end
                    
                    --print(v, "removed")
                    v:Remove()
                end
            end

            if IsValid(categoryShopPanels[catUpdate].List) then
                categoryShopPanels[catUpdate].List:Clear() 
            end
        end
        if updateInv && categoryInvShopPanels[catUpdate] then 

            if ShopModelPanels[catUpdate] then
                for k, v in pairs(ShopModelPanels[catUpdate]) do
                    if !IsValid(v) then continue end
                    
                    --print(v, "removed")
                    v:Remove()
                end
            end

            if IsValid(categoryInvShopPanels[catUpdate].List) then
                categoryInvShopPanels[catUpdate].List:Clear() 
            end
        end
        --print("clearing and rebuilding "..catUpdate)

    end

    if updateInv then

        for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
            if !GAMEMODE.Util:GetItemPrice(ItemTable.ID) then continue end
            local item = ItemTable.ID
            if !Local_Inventory[item] then continue end
            if ItemTable.CantSell && ( item != "item_money" && item != "item_credits" ) then continue end

            local itemCat = ItemTable.Category
            if !itemCat then itemCat = "none" end
            if catUpdate and itemCat != catUpdate then continue end

            categoryInvShopPanels[itemCat] = categoryInvShopPanels[itemCat] or {} -- Extra validation, in case.
            if !IsValid(categoryInvShopPanels[itemCat].List) then continue end

            for _, it in pairs( Local_Inventory[item] ) do
                if it.amount > 0 then
                    local panel, modelpanel = DZ_MakeIcon( it.id, item, it.amount, categoryInvShopPanels[itemCat].List, nil, "invslot", 52, 52, false, true )
                    panel:Receiver( "panel_item", function(self, tbl, bDoDrop, Command, x, y) end ) -- we dont want this in the shop
                    panel.rarity = it.rarity or 0
                    table.insert(ShopInvModelPanels, modelpanel)

                    local itemtype = ''
                    if ItemTable.Hat then itemtype = 'Hat' end
                    if ItemTable.Body then itemtype = 'Body' end
                    if ItemTable.Shoes then itemtype = 'Shoes' end
                    if ItemTable.Pants then itemtype = 'Pants' end
                    if ItemTable.Primary then itemtype = 'Primary' end
                    if ItemTable.Secondary then itemtype = 'Secondary' end
                    if ItemTable.Melee then itemtype = 'Melee' end
                    if ItemTable.Tertiary then itemtype = 'Tertiary' end
                    if ItemTable.BackPack then itemtype = 'Backpack' end
                    if ItemTable.BodyArmor then itemtype = 'Body Armor' end

                    modelpanel.DoClick = function()
                        ShopPanel.SelectedItemPanel = panel
                        ShopPanelSetItem(item, it)
                    end

                    modelpanel.DoRightClick = function()
                        ItemMENU = DermaMenu()

                        local itemamt = it.amount

                        local panel = ItemMENU:AddOption("Sell "..itemamt,   function()
                            RunConsoleCommand("SellItemMoney", it.id, itemamt)
                        end)
                        panel.Paint = PaintItemMenus

                        local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
                        if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end

                        if itemamt > 1 then

                            local DropMenu, panel = ItemMENU:AddSubMenu( "Sell X" )
                            DropMenu.Paint = PaintItemMenus
                            panel.Paint = PaintItemMenus

                            for k, v in ipairs(amts) do
                                if itemamt < v then continue end
                                local panel = DropMenu:AddOption("Sell "..v,    function()
                                    RunConsoleCommand("SellItemMoney",it.id,v)
                                end )
                                panel.Paint = PaintItemMenus
                            end
                        end

                        ItemMENU:AddSpacer()
                        ItemMENU:AddSpacer()

                        DZ_MakeItemMenu(item, ItemTable, it, itemtype, modelpanel, ItemMENU)
                    end
                end
            end
        end
    end

    for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
        if !GAMEMODE.Util:GetItemPrice(ItemTable.ID) then continue end
        if ItemTable.DontStock && ItemTable.ID != "item_credits" then continue end

        local item = ItemTable.ID
        if !GAMEMODE.DayZ_Shops["shop_buy"][item] then continue end -- ignore

        local amount = GAMEMODE.DayZ_Shops["shop_buy"][item]

        if amount < 1 then continue end

        local itemCat = ItemTable.Category
        if !itemCat then itemCat = "none" end
        if catUpdate and itemCat != catUpdate then continue end

        categoryShopPanels[itemCat] = categoryShopPanels[itemCat] or {} -- Extra validation, in case.
        if !categoryShopPanels[itemCat].List then continue end

        local rarity = 1
        if ( GUI_Donate_Frame.vip and LocalPlayer():IsVIP() ) and !( ItemTable.AmmoType or ItemTable.IsCurrency) then
            rarity = 2
        end

        local panel, modelpanel = DZ_MakeIcon( nil, item, amount, categoryShopPanels[itemCat].List, nil, nil, 55, 55, false, true, false, nil, nil )
        panel.rarity = rarity
        ShopModelPanels[itemCat] = ShopModelPanels[itemCat] or {}
        table.insert(ShopModelPanels[itemCat], modelpanel)

        modelpanel.DoClick = function()
            ShopPanel.SelectedItemPanel = panel
            ShopPanelSetItem(item)
        end

        modelpanel.DoRightClick = function()
            ItemMENU = DermaMenu()

            local itemamt = amount

            local panel = ItemMENU:AddOption("Buy 1",   function()
                RunConsoleCommand("BuyItemMoney", item, 1)
            end)
            panel.Paint = PaintItemMenus

            if amount > 1 then

                local panel = ItemMENU:AddOption("Buy "..amount,   function()
                    RunConsoleCommand("BuyItemMoney", item, amount)
                end)
                panel.Paint = PaintItemMenus

            end
            
            local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
            if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end

            if itemamt > 1 then

                local DropMenu, panel = ItemMENU:AddSubMenu( "Buy X" )
                DropMenu.Paint = PaintItemMenus
                panel.Paint = PaintItemMenus

                for k, v in ipairs(amts) do
                    if itemamt < v then continue end
                    local panel = DropMenu:AddOption("Buy "..v,    function()
                        RunConsoleCommand("BuyItemMoney",item,v)
                    end )
                    panel.Paint = PaintItemMenus
                end
            end


            ItemMENU:Open( gui.MousePos() ) 

            DZ_ItemMENU = ItemMENU
        end

    end

end