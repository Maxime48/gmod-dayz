Local_HotBar = Local_HotBar or {}

local slots = 9

for i=1, slots do 
	Local_HotBar[i] = Local_HotBar[i] or {}
end

net.Receive("dz_addslot", function(len)
	local it = net.ReadTable()

	local founditem = false
	for i=1, 9 do
		if !Local_HotBar[i] then continue end
		if Local_HotBar[i].itemclass == it.class then
			founditem = it.class
			break
		end
	end

	if founditem then return end -- don't equip the same item twice, automatically.

	local ItemTable = GAMEMODE.DayZ_Items[it.class]

	for i=1, 9 do
		if !Local_HotBar[i] or !Local_HotBar[i].item then
			Local_HotBar[i] = Local_HotBar[i] or {}
			Local_HotBar[i].item = it.id
			Local_HotBar[i].itemclass = it.class
			if ItemTable && ItemTable.Weapon then
				Local_HotBar[i].weapon = ItemTable.Weapon
			end
			break
		end
	end
end)

HotBar_CurItemOpts = HotBar_CurItemOpts or {}
function HotBar_Ping(i, secondary)
	if !i then return end
	if !IsValid(HotBarPanel) then return end
	for i=1, slots do 
		if !IsValid(HotBarPanel.Slots[i]) then return end
		HotBarPanel.Slots[i].Active = false
	end

	if IsValid(HotBarPanelSecondary) then

        local item = HotBar_CurItemOpts[i]
        if !item then HotBarPanelSecondary:AlphaTo(0, 0.5, 0, function() HotBarPanelSecondary:Remove() end) return end

        HotBarPanelSecondary.Slots[i].Pinged = true        
        RunConsoleCommand(item.cmd, item.id)
		HotBarPanelSecondary:AlphaTo(0, 0.5, 0, function()
			HotBarPanelSecondary:Remove()
		end)
        
        return false
	end

	if !IsValid(HotBarPanel.Slots[i]) then return end

	HotBarPanel.Slots[i].Pinged = true
	timer.Create("slotping_"..i, 1, 1, function()
		HotBarPanel.Slots = HotBarPanel.Slots or {}
		if !IsValid(HotBarPanel.Slots[i]) then return end

		HotBarPanel.Slots[i].Pinged = false
	end)
			
	local ItemTable = GAMEMODE.DayZ_Items[ Local_HotBar[i].itemclass ]
	if !ItemTable then return true end

	if ItemTable.Weapon && LocalPlayer():HasWeapon(ItemTable.Weapon) then return true end

	HotBar_CurItemOpts = {}

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

    if (ItemTable.ProcessFunction != nil) then
        table.insert( HotBar_CurItemOpts, {name="Use", cmd="UseItem", class = Local_HotBar[i].itemclass, id = Local_HotBar[i].item} )
    end

    if itemtype != '' then
        table.insert( HotBar_CurItemOpts, {name="Equip", cmd="EquipItem", class = Local_HotBar[i].itemclass, id = Local_HotBar[i].item} )
    end

    if ItemTable.EatFor != nil or  ItemTable.DrinkFor != nil then
        table.insert( HotBar_CurItemOpts, {name="Eat", cmd="UseItem", class = Local_HotBar[i].itemclass, id = Local_HotBar[i].item} )
    end

    table.insert( HotBar_CurItemOpts, {name="Throw", cmd="ThrowItem", class = Local_HotBar[i].itemclass, id = Local_HotBar[i].item} )

    if #HotBar_CurItemOpts > 1 then
   		HotBar_MakeSecondary(i)
   		return false
   	end

    --RunConsoleCommand("ThrowItem", it.id, 1)

	return true
end

local secondaryslots = 5
function HotBar_MakeSecondary(index)
	if IsValid(HotBarPanelSecondary) then HotBarPanelSecondary:AlphaTo(0, 0.5, 0, function() HotBarPanelSecondary:Remove() end) return end 

	local sizex, sizey = ( 64 * #HotBar_CurItemOpts ) + ( 10 * #HotBar_CurItemOpts ), 64 + 10

	HotBarPanelSecondary = vgui.Create("DPanel")
	HotBarPanelSecondary:SetSize(sizex, sizey)
	HotBarPanelSecondary:SetPos((ScrW() / 2) - (sizex/2), ScrH() - sizey*2)
	HotBarPanelSecondary.Paint = function(self, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(10, 10, 10, 200), true, true, false, false)
	end

	HotBarPanel.Slots[index].Active = true

	HotBarPanelSecondary.Slots = {}
	for i, v in ipairs(HotBar_CurItemOpts) do 
		HotBarPanelSecondary.Slots[i] = vgui.Create("DPanel", HotBarPanelSecondary)
		HotBarPanelSecondary.Slots[i].slot = i
		HotBarPanelSecondary.Slots[i]:SetSize(64,64)
		HotBarPanelSecondary.Slots[i]:DockMargin(5,5,5,5)
		HotBarPanelSecondary.Slots[i]:Dock(LEFT)

		local ping_color = Color(255, 200, 50, 200)
		local active_color = Color(0, 200, 200, 150)
		HotBarPanelSecondary.Slots[i].Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 20))
            draw.DrawText(i, "char_title16", 4, 2, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)

            draw.DrawText(v.name, "char_title16", w/2, h/2 - 8, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            if self.Pinged then

				draw.RoundedBox(0,0,0,w,2,ping_color) -- Top
				draw.RoundedBox(0,0,62,w,2,ping_color) -- Bottom
				draw.RoundedBox(0,0,0,2,h,ping_color) -- Left
				draw.RoundedBox(0,62,0,2,h,ping_color) -- Right

	            ping_color.a = ping_color.a - 10
			else
				ping_color.a = 255
			end

		end 
	end

end

function HotBar_DoLogic(idx)
	local ping = HotBar_Ping(idx)
    if !ping then return true end

    if Local_HotBar[idx] && Local_HotBar[idx].item then
        local id = Local_HotBar[idx].item
        local class = Local_HotBar[idx].itemclass

        local it = GAMEMODE.Util:GetItemByDBID(Local_Inventory, id)
        if !it or it.amount < 1 then
            it = GAMEMODE.Util:GetItemIDByClass(Local_Character, class)
        end
        if !it or it.amount < 1 then
            it = GAMEMODE.Util:GetItemIDByClass(Local_Inventory, class)
        end
        if !it then return true end

        for i=1, slots do
        	Local_HotBar[i].active = false
        end
        Local_HotBar[idx].active = true

        local ItemTable = GAMEMODE.DayZ_Items[it.class]

        if ItemTable.Weapon then
            if LocalPlayer():HasWeapon(ItemTable.Weapon) then
                --WSWITCH:SelectAndConfirm(idx)
                RunConsoleCommand("wepswitch", ItemTable.Weapon)
                return true
            end 
        end

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

        if (ItemTable.Function != nil) then
            RunConsoleCommand("Useitem", it.id)
            return true
        end

        if itemtype != '' then
            RunConsoleCommand("EquipItem", it.id)
            return true
        end

        if ItemTable.EatFunction != nil or  ItemTable.DrinkFunction != nil then
            RunConsoleCommand("Eatitem", it.id)
            return true
        end

        RunConsoleCommand("ThrowItem", it.id, 1)

    else
        if IsValid(LocalPlayer()) && IsValid( LocalPlayer():GetActiveWeapon() ) && LocalPlayer():GetActiveWeapon():GetClass() == "weapon_emptyhands" then
            LocalPlayer():ConCommand("+reload")
            timer.Simple(0.1, function() LocalPlayer():ConCommand("-reload") end)
        else
            RunConsoleCommand("wepswitch", "weapon_emptyhands")
        end
    end
end

function GetNextHotBarSlot(empty)
	local idx = GetActiveHotBarSlot()

	for i=idx, slots do
		if Local_HotBar[idx] && Local_HotBar[idx].item then
			idx = i
			break
		end
	end

	return idx
end

function GetActiveHotBarSlot()
	local idx
	for i=1, slots do 
		if Local_HotBar[i] && Local_HotBar[i].active then
			idx = i
			break
		end
	end

	return idx or 1
end

function CreateHotBar()
	if IsValid(HotBarPanel) then 
		if !( LocalPlayer():Alive() and AliveChar ) or DZ_MENUBLUR then HotBarPanel:Hide() else HotBarPanel:Show() end
		return 
	end
	--if IsValid(HotBarPanel) then HotBarPanel:Remove() end

	local sizex, sizey = ( 64 * slots )+ ( 10 * slots ), 64 + 10

	HotBarPanel = vgui.Create("DPanel")
	HotBarPanel:SetSize(sizex, sizey + 20)
	HotBarPanel:SetPos((ScrW() / 2) - (sizex/2), ScrH() - sizey - 20)
	HotBarPanel.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 200))
	end

	HotBarPanel.XPBar = vgui.Create("DPanel", HotBarPanel)
	HotBarPanel.XPBar:SetTall(20)
	HotBarPanel.XPBar:Dock(TOP)

	HotBarPanel.Slots = {}
	for i=1, slots do 
		HotBarPanel.Slots[i] = vgui.Create("DPanel", HotBarPanel)
		HotBarPanel.Slots[i].slot = i
		HotBarPanel.Slots[i]:SetSize(64,64)
		HotBarPanel.Slots[i]:DockMargin(5,5,5,5)
		HotBarPanel.Slots[i]:Dock(LEFT)

		HotBarPanel.Slots[i]:Receiver( "invslot", function( pnl, tbl, dropped, menu, x, y )
	    	if ( !dropped ) then return end
			if tbl[1]:GetParent() == HotBarPanel.Slots[i] then return end

			local slot = tbl[1].slot
			if slot then
				if Local_HotBar[slot] && Local_HotBar[slot].item then
					Local_HotBar[slot] = {}
					Local_HotBar[slot].item = Local_HotBar[i].item
					Local_HotBar[slot].itemclass = Local_HotBar[i].itemclass

					if Local_HotBar[i].weapon then
						Local_HotBar[slot].weapon = Local_HotBar[i].weapon
					end

				end
			end

			Local_HotBar[i] = {}
			Local_HotBar[i].item = tbl[1].ItemID
			Local_HotBar[i].itemclass = tbl[1].ItemClass

			local ItemTable = GAMEMODE.DayZ_Items[ tbl[1].ItemClass ]
			if ItemTable && ItemTable.Weapon then
				Local_HotBar[i].weapon = ItemTable.Weapon
			end

			return

	    end )
	
		HotBarPanel.Slots[i].Think = function(self)
			if (self.nextThink or 0) > CurTime() then return end
			Local_HotBar[i] = Local_HotBar[i] or {}

			if !Local_HotBar[i].item then
				for k, v in pairs(self:GetChildren()) do
					v:Remove()
				end
			end

			if Local_HotBar[i].item && !IsValid(self.panel) then
				local ItemTable = GAMEMODE.DayZ_Items[Local_HotBar[i].itemclass]
				if Local_HotBar[i].weapon then
					self.panel, self.modelpanel = DZ_MakeIcon( Local_HotBar[i].item, Local_HotBar[i].itemclass, 0, HotBarPanel.Slots[i], nil, "invslot", 64, 64, false, true, nil, false, true, false, false, true )
				else
					self.panel, self.modelpanel = DZ_MakeIcon( Local_HotBar[i].item, Local_HotBar[i].itemclass, LocalPlayer():GetItemAmount(Local_HotBar[i].item), HotBarPanel.Slots[i], nil, "invslot", 64, 64, false, true, nil, false, true, false, false, true )
				end
				local it = GAMEMODE.Util:SearchForItem( Local_HotBar[i].item )

				if !it then return end
				if !self.panel then return end
				
				self.panel.rarity = it.rarity or 1
				
				self.panel.slot = i
	            self.panel:SetSize(64, 64)
	            self.panel:SetPos(0,0)
	            self.panel.hotbar = true
	            self.panel.oldPaint = self.panel.Paint
	            self.panel.Paint = function(self, w, h)
	            	self.oldPaint(self, w, h)

					if ItemTable.Weapon then

	            		local intAmmoInMag = 0 
						local intAmmoOutMag = 0
						local wep = LocalPlayer():GetWeapon(ItemTable.Weapon)

						if wep:IsValid() then
							intAmmoInMag = wep:Clip1()
							intAmmoOutMag = LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType())
						end

		            	if wep:IsValid() && wep:Clip1() >= 0 then    
		            		surface.SetFont("char_title16")
		            		local sizex, _ = surface.GetTextSize("x "..intAmmoOutMag)   

		            		local colIn, colOut = Color(255, 255, 255, 200), Color(255, 255, 255, 200)
		            		if intAmmoInMag < 1 then
		            			colIn = Color(255,0,0,200)
		            		end
		            		if intAmmoOutMag < 1 then
		            			colOut = Color(255,0,0,200)
		            		end

		            		draw.DrawText(intAmmoInMag, "char_title16", w - sizex, h - 18, colIn, TEXT_ALIGN_RIGHT)
		            		draw.DrawText("/"..intAmmoOutMag, "char_title16", w - 5, h - 18, colOut, TEXT_ALIGN_RIGHT)
		            	end
		            end

	        	end
	            self.panel.item = Local_HotBar[i].item
	            self.modelpanel:SetSize(60,60)

	            self.modelpanel.AlwaysDraw = true -- ignore ent count

	            self.modelpanel.DoRightClick = function()
					ItemMENU = DermaMenu()
					local it = Local_HotBar[i]

					if Local_Character[it.itemclass] && Local_Character[it.itemclass][it.item] then
						local panel = ItemMENU:AddOption("UnEquip", function()
							RunConsoleCommand("DEquipItem", it.item)
							Local_HotBar[i] = {}
						end)
						panel.Paint = PaintItemMenus

						ItemMENU:AddSpacer()
					end

					local panel = ItemMENU:AddOption("Remove", function()
						Local_HotBar[i] = {}
						--HotBarPanel:Remove()
					end)
					panel.Paint = PaintItemMenus

					ItemMENU:Open( gui.MousePos() )	
				end
				self.modelpanel.DoClick = function()
					Local_HotBar[i] = {}
				end

			elseif Local_HotBar[i].item && IsValid(self.panel) then
				local ItemTable = GAMEMODE.DayZ_Items[Local_HotBar[i].itemclass]

				if IsValid(self.modelpanel) then
					if !LocalPlayer():HasItem(Local_HotBar[i].item) and !LocalPlayer():HasEquipped(Local_HotBar[i].item) then
				        --self.modelpanel:SetColor( Color(0,0,0,255) )
				        Local_HotBar[i] = {}
				    else
				        self.modelpanel:SetColor(ItemTable.Color or Color(255, 255, 255, 255))
				    end
				end

				if Local_HotBar[i].item != self.panel.item then
					self.panel:Remove()
				end
			end

			--self.nextThink = CurTime() + 0.1
		end

		local ping_color = Color(255, 200, 50, 200)
		local active_color = Color(0, 200, 200, 150)
		HotBarPanel.Slots[i].Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 20))
            draw.DrawText(i, "char_title16", 4, 2, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)

            local wep = LocalPlayer():GetActiveWeapon()
            if wep and wep:IsValid() then
				if Local_HotBar[i] && Local_HotBar[i].weapon then
					if wep:GetClass() == Local_HotBar[i].weapon then
						draw.RoundedBox(0,0,0,w,2,active_color) -- Top
						draw.RoundedBox(0,0,62,w,2,active_color) -- Bottom
						draw.RoundedBox(0,0,0,2,h,active_color) -- Left
						draw.RoundedBox(0,62,0,2,h,active_color) -- Right
					end
				end
            end

            if self.Active then
				draw.RoundedBox(0,0,0,w,2,active_color) -- Top
				draw.RoundedBox(0,0,62,w,2,active_color) -- Bottom
				draw.RoundedBox(0,0,0,2,h,active_color) -- Left
				draw.RoundedBox(0,62,0,2,h,active_color) -- Right
			end

            if self.Pinged then

				draw.RoundedBox(0,0,0,w,2,ping_color) -- Top
				draw.RoundedBox(0,0,62,w,2,ping_color) -- Bottom
				draw.RoundedBox(0,0,0,2,h,ping_color) -- Left
				draw.RoundedBox(0,62,0,2,h,ping_color) -- Right

	            ping_color.a = ping_color.a - 10
			else
				ping_color.a = 255
			end

		end 
	end

	timer.Simple(1, function()
		local inc = 1
		for class, items in pairs(Local_Character) do
			if inc > 9 then continue end

			for k, item in pairs(items) do
				if item.amount < 1 then continue end

				local ItemTable = GAMEMODE.DayZ_Items[item.class]

				if !ItemTable.Weapon then continue end
				Local_HotBar[inc] = Local_HotBar[inc] or {}
				Local_HotBar[inc].item = item.id
				Local_HotBar[inc].itemclass = item.class
				Local_HotBar[inc].weapon = ItemTable.Weapon

				inc = inc + 1
			end
		end

	end)

end
concommand.Add("hotbar", CreateHotBar)
concommand.Add("hotbar_del", function() Local_HotBar = {} if IsValid(HotBarPanel) then HotBarPanel:Remove() end end)
concommand.Add("hotbar_debug", function() PrintTable(Local_HotBar) end)