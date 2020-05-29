local vgui = vgui
local draw = draw
local surface = surface
local gradient = Material("gui/gradient")
local UpgradeInvModelPanels = {}
updateInvCategoryPanels = updateInvCategoryPanels or {}

function UpdateUpgrades(parent, catUpdate)
        
    local itemCategories = GAMEMODE.Util:GetItemCategories()
    if !catUpdate and IsValid(updateinvcategoryScroll) then updateinvcategoryScroll:Remove() end
    if !IsValid(updateinvcategoryScroll) then
        updateinvcategoryScroll = vgui.Create("DScrollPanel", parent)
        updateinvcategoryScroll:Dock(FILL)
        updateinvcategoryScroll.Paint = function(self, w, h) end
        updateinvcategoryScroll.Think = function(self)
            if ( self.NextThink or 0 ) > CurTime() then return end

            local children = self:GetCanvas():GetChildren()
            for k, child in pairs(children) do
                if !child:IsVisible() then
                    child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
                end
            end

            self.NextThink = CurTime() + 0.2
        end

        local ScrollBar = updateinvcategoryScroll:GetVBar();

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
            
            updateInvCategoryPanels[category] = vgui.Create("DCollapsibleCategory", updateinvcategoryScroll)
            updateInvCategoryPanels[category]:SetLabel("")
            --updateInvCategoryPanels[category]:SetWide( parent:GetWide() )
            updateInvCategoryPanels[category]:Dock(TOP)
            --updateInvCategoryPanels[category]:SetSize(350, 310)
            updateInvCategoryPanels[category]:DockMargin(0, 0, 5, 5)
            updateInvCategoryPanels[category]:DockPadding(0, 0, 0, 5)

            updateInvCategoryPanels[category].Paint = function(self, w, h)
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

            updateInvCategoryPanels[category].List = vgui.Create("DIconLayout", updateInvCategoryPanels[category] )
            updateInvCategoryPanels[category].List:SetPos(0, 20)
            updateInvCategoryPanels[category].List:SetSize( 445, 10 )
            updateInvCategoryPanels[category].List:SetSpaceX(5)
            updateInvCategoryPanels[category].List:SetSpaceY(5)
            updateInvCategoryPanels[category].List:SetBorder(5)
            updateInvCategoryPanels[category].List:Receiver("cat_slot", function(pnl, tbl, dropped, menu, x, y)
                if (not dropped) then return end
                --print(tbl[1]:GetParent())
                if tbl[1]:GetParent() == pnl then 
                    --print(tbl[1].ItemClass.." wants SplitItem "..tbl[1].Amount/2)
                    RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount/2)
                    return 
                end
                --tbl[1]:SetSize(66, 66)
                --tbl[1]:GetChild(1):SetSize(50, 50)
                --parent:AddItem(tbl[1])
                --RunConsoleCommand("Dequipitem", tbl[1].ItemID)
            end)

            updateInvCategoryPanels[category].List.Paint = function(self, w, h)
                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
            end
            updateInvCategoryPanels[category].Think = function(self, vis)
                if !vis and ( self.NextThink or 0 ) > CurTime() then return end
                local children = self.List:GetChildren()

                if table.Count(children) > 0 then
                    self:SetVisible(true)
                else
                    self:SetVisible(false)
                end
                self:GetParent():InvalidateLayout()
                self:SizeToContents()

                if vis then return end
                self.NextThink = CurTime() + 0.2
            end


        end
    end

    if !catUpdate then

        for k, v in pairs(itemCategories) do
            if IsValid(updateInvCategoryPanels[v].List) then
                updateInvCategoryPanels[v].List:Clear()
            end
        end
        --print("clearing and rebuilding all")
    else
        -- we just have the one category to update
        if !updateInvCategoryPanels[catUpdate] then return end
        if IsValid(updateInvCategoryPanels[catUpdate].List) then
            updateInvCategoryPanels[catUpdate].List:Clear()
        end
        --print("clearing and rebuilding "..catUpdate)

    end

    --parent:Clear()

    for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
        local item = ItemTable.ID
        if !Local_Inventory[item] then continue end

        for _, it in pairs( Local_Inventory[item] ) do
            local ItemTable = GAMEMODE.DayZ_Items[item]
            local amount = it.amount

            local itemids = {}
            for i = 1, 3 do 
                local panel = Upgrade_Panel.Slots[i]
                if IsValid(panel) then
                    if table.Count( panel:GetChildren() ) > 0 then
                        if IsValid(panel:GetChildren()[1]) then
                            itemids[i] = panel:GetChildren()[1].ItemID
                        end
                    end
                end
            end

            if table.HasValue(itemids, it.id) then continue end -- we refresh because split so don't show existing item.
            
            if amount > 0 then
                
                if it.rarity > 6 then continue end

                local cats = { "ammo", "lootboxes", "none" }
                local itemCat = ItemTable.Category
                if !itemCat then itemCat = "none" end

                if table.HasValue( cats, string.lower(itemCat) ) && item != "item_keypad" then continue end


                if catUpdate and itemCat != catUpdate then continue end

                local panel, modelpanel = DZ_MakeIcon( it.id, item, amount, updateInvCategoryPanels[itemCat].List, nil, "upgradeslot", 66, 66, false, true )
                panel.rarity = it.rarity or 0

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


                modelpanel.DoRightClick = function()
                    local ItemMENU = DermaMenu()

                    local panel = ItemMENU:AddOption("Upgrade [Req x3]", function()
                        RunConsoleCommand("UpgradeItem", it.id)
                    end)
                    panel.Paint = PaintItemMenus

                    ItemMENU:AddSpacer()

                    DZ_MakeItemMenu(item, ItemTable, it, itemtype, modelpanel, ItemMENU)
                end

                updateInvCategoryPanels[itemCat].List:Add(panel)
                updateInvCategoryPanels[itemCat].List:InvalidateLayout()

                --parent:Add(panel)
                --parent:InvalidateLayout()
                --parent:AddItem(panel)
                table.insert(UpgradeInvModelPanels, modelpanel)
                
            end

        end
    end
end

function GUI_Rebuild_Upgrades(parent)

    for k, v in pairs(UpgradeInvModelPanels) do
        if IsValid(v) then v:Remove() end
    end

    local title_upgrades = vgui.Create("DPanel", parent)
    title_upgrades:Dock(TOP)
    title_upgrades:SetTall(40)
    title_upgrades:DockMargin(5, 5, 5, 0)
    title_upgrades.Paint = function(self, w, h)
        paint_bg(self, w, h)

        draw.SimpleText("Drag 3 of the same item into the slots above to Upgrade:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText("Higher Rarity means better gear, stat bonuses, weapon damage and more!", "char_title20", 5, 20, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

    UpgradeInv_Panel = vgui.Create("DPanel", parent)
    UpgradeInv_Panel:Dock(LEFT)
    UpgradeInv_Panel:SetWide(480)
    UpgradeInv_Panel:DockMargin(5,5,0,5)
    UpgradeInv_Panel.Paint = function(self, w, h) paint_bg(self, w, h) end
    
    UpgradeInv_Panel.List = vgui.Create("DIconLayout", UpgradeInv_Panel)
    UpgradeInv_Panel.List:Dock(FILL)
    --UpgradeInv_Panel.List:SetTall(320)
    UpgradeInv_Panel.List:SetWide(parent:GetWide() - 10)
    UpgradeInv_Panel.List:DockMargin(5,5,5,5)
    UpgradeInv_Panel.List.Paint = function(self, w, h) end

    Upgrade_Panel = vgui.Create("DPanel", parent)

    Upgrade_Panel.Slots = {}
    Upgrade_Panel.Items = {}
    Upgrade_Panel:Dock(FILL)
    Upgrade_Panel:DockMargin(5,5,5,5)
    Upgrade_Panel.Paint = function(self, w, h) paint_bg(self, w, h) end
    Upgrade_Panel.ItemIDs = {}
    Upgrade_Panel.Think = function()
        if ( Upgrade_Panel.nextThink or 0 ) > CurTime() then return end
        local bool = false
        local rarities = {}
        for i = 1, 3 do 
            local panel = Upgrade_Panel.Slots[i]
            if IsValid(panel) then
                if table.Count( panel:GetChildren() ) < 1 then
                    bool = false
                else
                    if IsValid(panel:GetChildren()[1]) then
                        Upgrade_Panel.ItemIDs[i] = panel:GetChildren()[1].ItemID
                        Upgrade_Panel.Items[i] = panel:GetChildren()[1].ItemClass -- expected
                        rarities[i] = panel:GetChildren()[1].rarity
                    end
                end
            end
        end

        if Upgrade_Panel.Items[1] == Upgrade_Panel.Items[2] and Upgrade_Panel.Items[2] == Upgrade_Panel.Items[3] then
            -- that was easy...
            bool = true
        end

        if rarities[1] != rarities[2] or rarities[2] != rarities[3] then
            bool = false
        end

        if !Upgrade_Panel.Items[1] or !Upgrade_Panel.Items[2] or !Upgrade_Panel.Items[3] then bool = false end

        Upgrade_Panel.But:SetVisible(bool)

        Upgrade_Panel.nextThink = CurTime() + 0.5
    end

    UpdateUpgrades(UpgradeInv_Panel.List)

    Upgrade_Panel.But = vgui.Create("DButton", Upgrade_Panel)
    Upgrade_Panel.But:Dock(BOTTOM)
    Upgrade_Panel.But:SetTall(60)
    Upgrade_Panel.But:SetText("UPGRADE!")
    Upgrade_Panel.But.Paint = function(self, w, h)
        local color = Color(50, 10, 10, 255)
        local text_color = Color(200,200,200,255)
        if self:IsHovered() then
            color = Color(30, 10, 10, 255)
        end

        local text = self:GetText()
        if text != "" then
            self:SetText("")
            self.text = text
        end

        draw.RoundedBox( 2, 0, 0, w, h, color ) 
        draw.DrawText( self.text, "char_title24", w/2, h/2-12, text_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end
    Upgrade_Panel.But.DoClick = function(self)
        RunConsoleCommand("UpgradeItem", Upgrade_Panel.ItemIDs[1], Upgrade_Panel.ItemIDs[2], Upgrade_Panel.ItemIDs[3])
        
        --RunConsoleCommand("menu_tab", "inventory")
    end


    local pos = 30
    local pos_toadd = 130
    for i = 1, 3 do
        local charslotcolor = Color(0, 0, 0, 50)
        Upgrade_Panel.Slots[i] = vgui.Create("DPanel", Upgrade_Panel)
        Upgrade_Panel.Slots[i]:SetSize(98, 98)
        Upgrade_Panel.Slots[i]:SetPos(80, pos)
        pos = pos + pos_toadd

        Upgrade_Panel.Slots[i].Paint = function(self, w, h)
            if table.Count(self:GetChildren()) == 0 then
                draw.DrawText("Item "..i, "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)
            end

            paint_bg(self, w, h)
        end

        local cats = { "ammo", "lootboxes", "none" }

        Upgrade_Panel.Slots[i]:Receiver("upgradeslot", function(pnl, tbl, dropped, menu, x, y)
            if (not dropped) then return end
            if tbl[1]:GetParent() == Upgrade_Panel.Slots[i] then return end
            if table.Count(Upgrade_Panel.Slots[i]:GetChildren()) > 0 then return end

            local itemCat = GAMEMODE.DayZ_Items[ tbl[1].ItemClass ].Category
            if !itemCat then itemCat = "none" end

            if table.HasValue( cats, itemCat ) && tbl[1].ItemClass != "item_keypad" then return end

            if tbl[1].Amount > 1 then
                RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount - 1)
            end

            tbl[1].Amount = 1

            tbl[1]:SetSize(94, 94)
            tbl[1]:SetPos(2, 2)
            tbl[1]:GetChild(1):SetSize(90, 90)

            if IsValid(tbl[1].ModelPanel) then
                tbl[1].ModelPanel:SetSize( 90,90 )

                tbl[1].ModelPanel.DoClick = function(self)
                    tbl[1]:Remove()
                    surface.PlaySound("items/ammo_pickup.wav")
                    UpdateUpgrades( UpgradeInv_Panel.List, itemCat )                    
                end
            end

            surface.PlaySound("items/battery_pickup.wav")

            tbl[1]:SetParent(pnl)
        end)

    end


end

function UpgradeMenu(vip)
    if GUI_Upgrade_Frame != nil && GUI_Upgrade_Frame:IsValid() then GUI_Upgrade_Frame:Remove() end
    GUI_Upgrade_Frame = vgui.Create("DPanel")
    GUI_Upgrade_Frame:SetSize(800, 600)
    GUI_Upgrade_Frame:Center()
    --GUI_Upgrade_Frame:ShowCloseButton(false)
    --GUI_Upgrade_Frame:SetTitle("")
    GUI_Upgrade_Frame.Paint = function(self, w, h)
        draw.RoundedBox( 0, 0, 0, w, h, Color(50,10,10,255) )
    end     
    GUI_Upgrade_Frame.weapon = true
    
    GUI_Upgrade_Frame:MakePopup()

    local PropertySheet = vgui.Create("DVerticalPropertySheet", GUI_Upgrade_Frame);
    PropertySheet.weapon = true
    PropertySheet:SetPos(10, 40);
    PropertySheet:Dock(FILL)
    PropertySheet.Paint = function(self, w, h) 
        draw.RoundedBox( 0, 0, 0, w, h, Color(50,10,10,255) )
    end 

    if !IsValid(GUI_Upgrade_Frame.title) then
        GUI_Upgrade_Frame.title = vgui.Create("DPanel", GUI_Upgrade_Frame) -- So docking works properly on each page, without duplicated code.
        GUI_Upgrade_Frame.title:Dock(TOP)
        GUI_Upgrade_Frame.title:SetTall(40)
        GUI_Upgrade_Frame.title.Paint = function(self, w, h)
            draw.RoundedBox( 0, 0, 0, w, h, Color(50,10,10,255) )

            draw.DrawText( LANG.GetTranslation(string.lower(PropertySheet:GetActiveTab():GetPanel().name)) or "Inventory", "tab_title", 45, 5, Color(255,255,255), TEXT_ALIGN_LEFT )
        end
    end

    if !IsValid(GUI_Upgrade_Frame.icon) then
        GUI_Upgrade_Frame.icon = vgui.Create( "DImage", GUI_Upgrade_Frame )
        GUI_Upgrade_Frame.icon:SetImage( "cyb_mat/cyb_backpack.png" )
        GUI_Upgrade_Frame.icon:SetPos(5, 5)
        GUI_Upgrade_Frame.icon:SetSize( 32, 32 )
        GUI_Upgrade_Frame.icon.Think = function(self) 
            self:SetImage( PropertySheet:GetActiveTab():GetPanel().icon or "cyb_mat/cyb_backpack.png" )
        end
    end
    
    local PanelSizeX = 746
    local PanelSizeY = 515
    local PanelPosX = 22
    local PanelPosY = 22

    GUI_Upgrade_tab_Panel = vgui.Create("DPanel", PropertySheet)
    GUI_Upgrade_tab_Panel:SetSize(PanelSizeX,PanelSizeY)
    GUI_Upgrade_tab_Panel:SetPos(PanelPosX,PanelPosY)
    GUI_Upgrade_tab_Panel.Paint = function(self, w, h)
    end

                        
    PropertySheet:AddSheet("Item Upgrades", GUI_Upgrade_tab_Panel, "cyb_mat/cyb_weapon.png", true, true, "Upgrade your stuff.");   

    local GUI_MainMenu_CloseButton = vgui.Create("DButton", GUI_Upgrade_Frame)
    GUI_MainMenu_CloseButton:SetColor(Color(255,255,255,255))
    GUI_MainMenu_CloseButton:SetFont("Cyb_Inv_Bar")
    GUI_MainMenu_CloseButton:SetText("X")
    GUI_MainMenu_CloseButton.Paint = function() end
    GUI_MainMenu_CloseButton:SetSize(32,32)
    GUI_MainMenu_CloseButton:SetPos(GUI_MainMenu_CloseButton:GetParent():GetWide()-GUI_MainMenu_CloseButton:GetWide()-5, 5)
    GUI_MainMenu_CloseButton.DoClick = function() if GUI_Upgrade_Frame:IsValid() then GUI_Upgrade_Frame:Remove() end end

    GUI_Rebuild_Upgrades(GUI_Upgrade_tab_Panel) 
end
net.Receive( "net_UpgradeMenu", function()
    local bool = net.ReadBool() or false
    UpgradeMenu(bool) 
end);

function DonatorMenu(vip, guideonly)
	if IsValid(GUI_Donate_Frame) then 
        if !vip && GUI_Donate_Frame.vip == true then
            GUI_Donate_Frame:Remove()
        end
    end
	GUI_Donate_Frame = vgui.Create("DPanel")
	GUI_Donate_Frame:SetSize(800, 600)
	GUI_Donate_Frame:Center()
	--GUI_Donate_Frame:ShowCloseButton(false)
	--GUI_Donate_Frame:SetTitle("")
	GUI_Donate_Frame.Paint = function(self, w, h)
		if vip then
			draw.RoundedBox( 0, 0, 0, w, h, CyB.barBgvip )
		else
			draw.RoundedBox( 0, 0, 0, w, h, CyB.barBg )
		end
	end		
	GUI_Donate_Frame.vip = vip or false
	
	GUI_Donate_Frame:MakePopup()

    if !IsValid(GUI_Donate_Frame.title) then
        GUI_Donate_Frame.title = vgui.Create("DPanel", GUI_Donate_Frame) -- So docking works properly on each page, without duplicated code.
        GUI_Donate_Frame.title:Dock(TOP)
        GUI_Donate_Frame.title:SetTall(40)
        GUI_Donate_Frame.title.Paint = function(self, w, h)
            local perc = 100 - (PHDayZ.ShopSellPercentage or 20)
            if GUI_Donate_Frame.vip then
                draw.RoundedBox( 0, 0, 0, w, h, CyB.barBgvip )
                perc = 100 - (PHDayZ.ShopSellPercentageVIP or 20)
            else
                draw.RoundedBox( 0, 0, 0, w, h, CyB.barBg )
            end
            if guideonly && !LocalPlayer():IsVIP() then
                draw.DrawText((GUI_Donate_Frame.vip and "VIP " or "").."Shop [-"..perc.."%] - See Server Packages below!", "tab_title", 45, 5, Color(255,255,255), TEXT_ALIGN_LEFT )
                return
            end
            draw.DrawText((GUI_Donate_Frame.vip and "VIP " or "").."Shop [-"..perc.."%]", "tab_title", 45, 5, Color(255,255,255), TEXT_ALIGN_LEFT )
        end
    end

    local GUI_MainMenu_CloseButton = vgui.Create("DButton", GUI_Donate_Frame.title)
    GUI_MainMenu_CloseButton:SetColor(Color(255,255,255,255))
    GUI_MainMenu_CloseButton:SetFont("Cyb_Inv_Bar")
    GUI_MainMenu_CloseButton:SetText("X")
    GUI_MainMenu_CloseButton.Paint = function() end
    GUI_MainMenu_CloseButton:Dock(RIGHT)
    GUI_MainMenu_CloseButton:SetWide(32)
    GUI_MainMenu_CloseButton.DoClick = function() if IsValid(GUI_Donate_Frame) then GUI_Donate_Frame:Remove() end end

    if !IsValid(GUI_Donate_Frame.icon) then
        GUI_Donate_Frame.icon = vgui.Create( "DImage", GUI_Donate_Frame )
        GUI_Donate_Frame.icon:SetImage( "cyb_mat/cyb_backpack.png" )
        GUI_Donate_Frame.icon:SetPos(5, 5)
        GUI_Donate_Frame.icon:SetSize( 32, 32 )
        GUI_Donate_Frame.icon.Think = function(self) 
            self:SetImage( IsValid(GUI_Donate_Frame.PropertySheet) and GUI_Donate_Frame.PropertySheet:GetActiveTab():GetPanel().icon or "cyb_mat/cyb_backpack.png" )
        end
    end

    if guideonly && !LocalPlayer():IsVIP() then 
        GUI_Donate_Frame:Remove()
        gui.OpenURL( PHDayZ.VIPURL != "" and PHDayZ.VIPURL or "https://gmoddayz.net/donate/"..LocalPlayer():SteamID64().."/" )
        /*
        local VIPHelp = vgui.Create("DHTML", GUI_Donate_Frame)
        VIPHelp:Dock(FILL)
        VIPHelp:DockMargin(5, 0, 5, 0)
        VIPHelp:OpenURL(PHDayZ.VIPURL or "https://gmoddayz.net/donate/"..LocalPlayer():SteamID64().."/")
        VIPHelp:SetScrollbars(true)
        VIPHelp:SetMouseInputEnabled(true)
        VIPHelp:SetKeyBoardInputEnabled(true)
        VIPHelp:RequestFocus()
        
        local ctrls = vgui.Create( "DHTMLControls", GUI_Donate_Frame ) -- Navigation controls
        ctrls:Dock(BOTTOM)
        ctrls:DockMargin(5, 0, 5, 5)
        ctrls:SetHTML( VIPHelp ) -- Links the controls to the DHTML window
        ctrls.AddressBar:SetText( PHDayZ.VIPURL or "https://gmoddayz.net/donate/"..LocalPlayer():SteamID64().."/" ) -- Address bar isn't updated automatically
        */
        return 
    end

	GUI_Donate_Frame.PropertySheet = vgui.Create("DVerticalPropertySheet", GUI_Donate_Frame);
	GUI_Donate_Frame.PropertySheet.vip = GUI_Donate_Frame.vip
	GUI_Donate_Frame.PropertySheet:SetPos(10, 40);
	GUI_Donate_Frame.PropertySheet:Dock(FILL)
	GUI_Donate_Frame.PropertySheet.Paint = function() 
								end	
	
	local PanelSizeX = 746
	local PanelSizeY = 515
	local PanelPosX = 22
	local PanelPosY = 22

	GUI_Shop_tab_Panel = vgui.Create("DPanel", GUI_Donate_Frame.PropertySheet)
	GUI_Shop_tab_Panel:SetSize(PanelSizeX,PanelSizeY)
	GUI_Shop_tab_Panel:SetPos(PanelPosX,PanelPosY)
	GUI_Shop_tab_Panel.Paint = function(self, w, h)

		if !PHDayZ.ShopBuyEnabled then
			draw.RoundedBox( 4, w/4 - 100, h/4 - 50, w/2 + 200, h/2 - 75, Color(10,10,10,100) )
			draw.DrawText("The shop is closed", "char_title24", w/2, h/2 - 100, Color(200, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.DrawText("Trade with others via /trade playername", "char_title16", w/2, h/2 - 10, Color(200, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

						
	GUI_Donate_Frame.PropertySheet:AddSheet((GUI_Donate_Frame.vip and "VIP " or "").."Shop", GUI_Shop_tab_Panel, "cyb_mat/cyb_weapon.png", true, true, "Sell your stuff.");	

	local Perk_tab = vgui.Create("DPanel", GUI_Donate_Frame.PropertySheet)
	Perk_tab:SetSize(PanelSizeX,PanelSizeY)
	Perk_tab:SetPos(PanelPosX,PanelPosY)
	Perk_tab.Paint = function(self, w, h)
	end

						
	GUI_Donate_Frame.PropertySheet:AddSheet("Character Perks", Perk_tab, "cyb_mat/cyb_perks.png", true, true, "Upgrades for your account!");	

	local LootBox_tab = vgui.Create("DPanel", GUI_Donate_Frame.PropertySheet)
	LootBox_tab:SetSize(PanelSizeX,PanelSizeY)
	LootBox_tab:SetPos(PanelPosX,PanelPosY)
	LootBox_tab.Paint = function(self, w, h)
	end

						
	GUI_Donate_Frame.PropertySheet:AddSheet("Lootboxes", LootBox_tab, "cyb_mat/cyb_bank.png", true, true, "Open boxes with keypads!");	

	if PHDayZ.ShopBuyEnabled then
		GUI_Rebuild_Shop(GUI_Shop_tab_Panel)
	end

	GUI_Rebuild_Perks(Perk_tab)
	GUI_Rebuild_LootBoxs(LootBox_tab)

    local Donate_tab = vgui.Create("DPanel", GUI_Donate_Frame.PropertySheet)
    Donate_tab:SetSize(PanelSizeX,PanelSizeY)
    Donate_tab:SetPos(PanelPosX,PanelPosY)
    Donate_tab.Paint = function(self, w, h)
    end
                        
    GUI_Donate_Frame.PropertySheet:AddSheet("Donate/VIP Upgrades", Donate_tab, "cyb_mat/cyb_profit.png", true, true, "Buy Credits, Make it rain and more!");   

    local title_donate = vgui.Create("DPanel", Donate_tab)
    title_donate:Dock(TOP)
    title_donate:SetTall(20)
    title_donate:DockMargin(5, 5, 5, 0)
    title_donate.Paint = function(self, w, h)
        paint_bg(self, w, h)

        draw.SimpleText("Buy Credits, VIP and more!", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

    local url = PHDayZ.VIPURL != "" and PHDayZ.VIPURL or "https://gmoddayz.net/donate/"..LocalPlayer():SteamID64().."/"

    local VIPButton = vgui.Create("DButton", Donate_tab)
    VIPButton:Dock(FILL)
    VIPButton:DockMargin(5, 5, 5, 5)
    VIPButton:SetText("CLICK HERE!\nOPENS IN STEAM OVERLAY")
    VIPButton.Paint = PaintButtons
    VIPButton.DoClick = function()
        gui.OpenURL(url)
    end
end
net.Receive( "net_DonatorMenu", function()
	local bool = net.ReadBool() or false
    local bool2 = net.ReadBool() or false

    local shop_items = net.ReadTable() 
    
    GAMEMODE.DayZ_Shops["shop_buy"] = shop_items

	DonatorMenu(bool, bool2) 
end);

function GUI_Rebuild_Shop(parent)
	if GUI_Wep_Panel_List != nil && GUI_Wep_Panel_List:IsValid() then
		GUI_Wep_Panel_List:Clear()
	else
	
		local GUI_Wep_Panel_List = vgui.Create("DPanelList", parent)
		GUI_Wep_Panel_List:Dock(FILL)
		GUI_Wep_Panel_List.Paint = function() end
		GUI_Wep_Panel_List:SetPadding(7.5)
		GUI_Wep_Panel_List:SetSpacing(2)
		GUI_Wep_Panel_List:EnableHorizontal(3)
		GUI_Wep_Panel_List:EnableVerticalScrollbar(true)
		
		GUI_Rebuild_Shop_Items(GUI_Wep_Panel_List)

	end
end

local PerkItemModelPanels = {}
local function PerkPanelSetItem(parent, item, it)
    if item == "item_money" then parent.SelectedItemPanel = nil return end -- NOPE

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

    PerkItemPanel.Displayed = true
    for k, v in pairs(PerkItemModelPanels) do
        if !IsValid(v) then continue end
        
        --print(v, "removed")
        v:Remove()
    end

    PerkItemPanel:Clear()
    local ItemTable = GAMEMODE.DayZ_Items[item]
    local panel, craftableItemModelPanel = DZ_MakeIcon( itemid, item, 0, PerkItemPanel, nil, nil, 90, 90, false, true, false, nil, nil )
    panel:SetPos(2, 2)
    panel.rarity = rarity
    
    table.insert(PerkItemModelPanels, craftableItemModelPanel)

    local ItemName = vgui.Create("DLabel", PerkItemPanel)
    ItemName:SetColor(Color(255, 255, 255, 255))
    ItemName:SetFont("Cyb_Inv_Bar")
    ItemName:SetText(ItemTable.Name)
    ItemName:SizeToContents()
    ItemName:SetPos(100, 10)
    local Description = vgui.Create("DLabel", PerkItemPanel)
    Description:SetColor(Color(255, 255, 255, 255))
    Description:SetFont("Cyb_Inv_Label")
    Description:SetText(ItemTable.Desc)
    Description:SizeToContents()
    Description:SetPos(100, 30)
    local buttontext = LANG.GetTranslation("buy")
    local buttontext2 = LANG.GetTranslation("sell")
    local buttonamount = " x1"
    local DoCook = vgui.Create("DButton", PerkItemPanel)
    DoCook.Paint = PaintButtons

    local price = ItemTable.Credits
    local cur = "¢"

    local reduction = 0
    local max = 100
    if itemid then
        max = 1
    end
    max = 1


    local CraftAmount = vgui.Create("DNumSlider", PerkItemPanel)

    CraftAmount:SetText("")

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
        price = ItemTable.Credits
        reduction = 0

        -- Because SetDecimals is cancer.
        
        buttonamount = " x" .. math.Round(s:GetValue())
        DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")

        if not DoCook:IsVisible() or max < 2 then
            CraftAmount:SetVisible(false)
        end
    end

    local HasAmount = vgui.Create("DLabel", PerkItemPanel)
    HasAmount:SetText("")

    HasAmount.Paint = function(self, w, h)
        --draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)
        if LocalPlayer():GetItemAmount(item, nil, true) > 0 then
            draw.DrawText("x" .. LocalPlayer():GetItemAmount(item, nil, true), "SafeZone_INFO", w / 2 - 95, 0, Color(200, 200, 200, 200), TEXT_ALIGN_RIGHT)
        end

        if Local_PerkTable[item] then
            draw.DrawText("Already Used", "Cyb_Inv_Bar", w / 2 - 95, h - 20, Color(Pulsate(1) * 255, 0, 0, 200), TEXT_ALIGN_RIGHT)
        end
    end

    HasAmount:SetSize(400, 95)
    HasAmount:SetPos(PerkItemPanel:GetWide() - HasAmount:GetWide() / 2, 0)

    DoCook:SetFont("char_title20")
    DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")
    DoCook:SetSize(180, 20)
    DoCook:SetPos(100, 50)

    DoCook.DoClick = function()
	    RunConsoleCommand("BuyItemMoney", item, CraftAmount:GetValue(), vip and 1 or 0)

    	timer.Simple(0.5, function() if IsValid(parent) then PerkPanelSetItem(parent, item, it) end end)
    end

    local c_amount = LocalPlayer():GetItemAmount("item_credits", nil, true)
    local panel, modelpanel = DZ_MakeIcon( nil, "item_credits", c_amount, PerkItemPanel, nil, nil, 90, 90, false, true, false, nil, nil )
    panel:Dock(RIGHT)
    panel.rarity = 1
end

local PerkModelPanels = {}
function GUI_Rebuild_Perks(parent)
	if GUI_Wep_Panel_List != nil && GUI_Wep_Panel_List:IsValid() then
		GUI_Wep_Panel_List:Clear()
	else
		
		local title_perks = vgui.Create("DPanel", parent)
	    title_perks:Dock(TOP)
	    title_perks:SetTall(20)
	    title_perks:DockMargin(5, 5, 5, 0)
	    title_perks.Paint = function(self, w, h)
	        paint_bg(self, w, h)

	        draw.SimpleText("Purchase perks with Credits to permanently unlock abilities for your character!", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
	    end

	    PerkItemPanel = vgui.Create("DPanel", parent)
	    PerkItemPanel:Dock(BOTTOM)
	    PerkItemPanel:SetTall(95)
	    PerkItemPanel:DockMargin(5, 5, 5, 5)
	    PerkItemPanel.Displayed = false
	    PerkItemPanel.Paint = function(self, w, h)
	        paint_bg(self, w, h)
	        --draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
	        if self.Displayed then return end
	        draw.SimpleText("Click on a perk to see Sale options", "SafeZone_INFO", w / 2, h / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	    end

	    local Perk_Panel = vgui.Create("DPanel", parent)
	    Perk_Panel:Dock(FILL)
	    Perk_Panel:DockMargin(5,5,5,0)
	    Perk_Panel.Paint = function(self, w, h) paint_bg(self, w, h) end

		local Perk_List = vgui.Create("DIconLayout", Perk_Panel)
		Perk_List:SetWide( parent:GetWide() - 10 )
		Perk_List:SetWide( parent:GetTall() - 10 )
		

		Perk_List:Dock(FILL)
        Perk_List:DockMargin(5,5,5,0)
        Perk_List:SetSpaceX(3)
        Perk_List:SetSpaceY(3)
		
		for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
   	        local item = ItemTable.ID
	        if !GAMEMODE.Util:GetItemPrice(item) then continue end
	        if ItemTable.DontStock && item != "item_credits" then continue end
	        local cat = ItemTable.Category
	        if cat != "perks" then continue end

	       	local panel, modelpanel = DZ_MakeIcon( nil, item, 0, Perk_List, nil, nil, 103, 103, false, true, false, nil, nil )
	        panel.rarity = 1
	        table.insert(PerkModelPanels, modelpanel)

	        modelpanel.DoClick = function()
	            Perk_List.SelectedItemPanel = panel
	            PerkPanelSetItem(Perk_List, item)
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

	        Perk_List:Add(panel)
            Perk_List:InvalidateLayout()

	    end

	end
end

local LootBoxItemModelPanels = {}
local function LootBoxPanelSetItem(parent, item, it)
    if item == "item_money" then parent.SelectedItemPanel = nil return end -- NOPE

    local itemid, quality 
    local rarity = GAMEMODE.DayZ_Items[item].Rarity
    if it then
        itemid = it.id
        quality = it.quality
        rarity = it.rarity
    end

    local vip = false
    if IsValid( GUI_Donate_Frame ) then 
        vip = GUI_Donate_Frame.vip or false
    end

    LootBoxItemPanel.Displayed = true
    for k, v in pairs(LootBoxItemModelPanels) do
        if !IsValid(v) then continue end
        
        --print(v, "removed")
        v:Remove()
    end

    LootBoxItemPanel:Clear()
    local ItemTable = GAMEMODE.DayZ_Items[item]
    local panel, craftableItemModelPanel = DZ_MakeIcon( itemid, item, 0, LootBoxItemPanel, nil, nil, 90, 90, false, true, false, nil, nil )
    panel:SetPos(2, 2)
    panel.rarity = ItemTable.Rarity
    
    table.insert(LootBoxItemModelPanels, craftableItemModelPanel)

    local ItemName = vgui.Create("DLabel", LootBoxItemPanel)
    ItemName:SetColor(Color(255, 255, 255, 255))
    ItemName:SetFont("Cyb_Inv_Bar")
    ItemName:SetText(ItemTable.Name)
    ItemName:SizeToContents()
    ItemName:SetPos(100, 10)
    local Description = vgui.Create("DLabel", LootBoxItemPanel)
    Description:SetColor(Color(255, 255, 255, 255))
    Description:SetFont("Cyb_Inv_Label")
    Description:SetText(ItemTable.Desc)
    Description:SizeToContents()
    Description:SetPos(100, 30)
    local buttontext = LANG.GetTranslation("buy")
    local buttontext2 = LANG.GetTranslation("sell")
    local buttonamount = " x1"
    local DoCook = vgui.Create("DButton", LootBoxItemPanel)
    DoCook.Paint = PaintButtons

    local price = ItemTable.Price
    local cur = "$"

    local reduction = 0
    local max = 100
    if itemid then
        max = 1
    end
    max = 1


    local CraftAmount = vgui.Create("DNumSlider", LootBoxItemPanel)

    CraftAmount:SetText("")

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
        price = ItemTable.Price
        reduction = 0

        -- Because SetDecimals is cancer.
        
        buttonamount = " x" .. math.Round(s:GetValue())
        DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")

        if not DoCook:IsVisible() or max < 2 then
            CraftAmount:SetVisible(false)
        end
    end

    local HasAmount = vgui.Create("DLabel", LootBoxItemPanel)
    HasAmount:SetText("")

    HasAmount.Paint = function(self, w, h)
        --draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)
        if LocalPlayer():GetItemAmount(item, nil, true) > 0 then
            draw.DrawText("x" .. LocalPlayer():GetItemAmount(item, nil, true), "SafeZone_INFO", w / 2 - 95, 0, Color(200, 200, 200, 200), TEXT_ALIGN_RIGHT)
        end
    end

    HasAmount:SetSize(400, 95)
    HasAmount:SetPos(LootBoxItemPanel:GetWide() - HasAmount:GetWide() / 2, 0)

    DoCook:SetFont("char_title20")
    DoCook:SetText(buttontext .. buttonamount .. " (" .. "-" .. cur .. price .. ")")
    DoCook:SetSize(180, 20)
    DoCook:SetPos(100, 50)

    DoCook.DoClick = function()
	    RunConsoleCommand("BuyItemMoney", item, CraftAmount:GetValue(), vip and 1 or 0)

    	timer.Simple(0.5, function() if IsValid(parent) then LootBoxPanelSetItem(parent, item, it) end end)
    end

    local c_amount = LocalPlayer():GetItemAmount("item_money", nil, true)
    local panel, modelpanel = DZ_MakeIcon( nil, "item_money", c_amount, LootBoxItemPanel, nil, nil, 90, 90, false, true, false, nil, nil )
    panel:Dock(RIGHT)
    panel.rarity = 1
end

local LootBoxModelPanels = {}
function GUI_Rebuild_LootBoxs(parent)
	if GUI_Wep_Panel_List != nil && GUI_Wep_Panel_List:IsValid() then
		GUI_Wep_Panel_List:Clear()
	else
		
		local title_LootBoxs = vgui.Create("DPanel", parent)
	    title_LootBoxs:Dock(TOP)
	    title_LootBoxs:SetTall(40)
	    title_LootBoxs:DockMargin(5, 5, 5, 0)
	    title_LootBoxs.Paint = function(self, w, h)
	        paint_bg(self, w, h)

	        draw.SimpleText("Purchase a box you have a key for and enjoy the contents!", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
            draw.SimpleText("3 Perfect Items inside each box & 1 Guaranteed Perfect Weapon! Guaranteed box minimum rarity!", "char_title20", 5, 20, Color(200, 200, 200), TEXT_ALIGN_LEFT)
	    end

	    LootBoxItemPanel = vgui.Create("DPanel", parent)
	    LootBoxItemPanel:Dock(BOTTOM)
	    LootBoxItemPanel:SetTall(95)
	    LootBoxItemPanel:DockMargin(5, 5, 5, 5)
	    LootBoxItemPanel.Displayed = false
	    LootBoxItemPanel.Paint = function(self, w, h)
	        paint_bg(self, w, h)
	        --draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
	        if self.Displayed then return end
	        draw.SimpleText("Click on a LootBox to see Sale options", "SafeZone_INFO", w / 2, h / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	    end

	    local LootBox_Panel = vgui.Create("DPanel", parent)
	    LootBox_Panel:Dock(FILL)
	    LootBox_Panel:DockMargin(5,5,5,0)
	    LootBox_Panel.Paint = function(self, w, h) paint_bg(self, w, h) end

		local LootBox_List = vgui.Create("DIconLayout", LootBox_Panel)
		LootBox_List:SetWide( parent:GetWide() - 10 )
		LootBox_List:SetTall( parent:GetTall() - 10 )
		
		LootBox_List:Dock(FILL)
        LootBox_List:DockMargin(5,5,5,0)
        LootBox_List:SetSpaceX(3)
        LootBox_List:SetSpaceY(3)
		
		for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Rarity") ) do
   	        local item = ItemTable.ID
	        if !GAMEMODE.Util:GetItemPrice(item) then continue end
	        --if ItemTable.DontStock && item != "item_credits" then continue end
	        local cat = ItemTable.Category
	        if cat != "lootboxes" then continue end

	        if ItemTable.ID == "item_keypad" then continue end

	       	local panel, modelpanel = DZ_MakeIcon( nil, item, 0, LootBox_List, nil, nil, 103, 103, false, true, false, nil, nil )
	        panel.rarity = ItemTable.Rarity
	        table.insert(LootBoxModelPanels, modelpanel)

	        modelpanel.DoClick = function()
	            LootBox_List.SelectedItemPanel = panel
	            LootBoxPanelSetItem(LootBox_List, item)
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

	        LootBox_List:Add(panel)
            LootBox_List:InvalidateLayout()

	    end

	end
end