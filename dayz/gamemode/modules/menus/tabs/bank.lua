local BankModelPanels = {}
local BankInvModelPanels = {}
categoryPanels = categoryPanels or {}
categoryInvPanels = categoryInvPanels or {}
function UpdateBank(catUpdate, bank)
	if !IsValid(GUI_BankInv_Panel_List) then return end

	--GUI_BankInv_Panel_List:Clear()
	local itemCategories = GAMEMODE.Util:GetItemCategories()

	if !catUpdate then

		for k, v in pairs(itemCategories) do
			if bank && categoryPanels[v] && IsValid(categoryPanels[v].List) then categoryPanels[v].List:Clear() end
			if categoryInvPanels[v] && IsValid(categoryInvPanels[v].List) then categoryInvPanels[v].List:Clear() end
		end
		--print("clearing and rebuilding all")
	else
		-- we just have the one category to update
		if bank && categoryPanels[catUpdate] and IsValid(categoryPanels[catUpdate].List) then categoryPanels[catUpdate].List:Clear() end
		if categoryInvPanels[catUpdate] && IsValid(categoryInvPanels[catUpdate].List) then categoryInvPanels[catUpdate].List:Clear() end
		--print("clearing and rebuilding "..catUpdate)
	end

	--if !catUpdate and IsValid(categoryIScroll) then categoryIScroll:Remove() end

	if !IsValid(categoryIScroll) then
		categoryIScroll = vgui.Create("DScrollPanel", GUI_BankInv_Panel_List)
		categoryIScroll:SetWide(GUI_BankInv_Panel_List:GetWide())
	    categoryIScroll:Dock(FILL)
	    categoryIScroll.Paint = function(self, w, h) end
	    categoryIScroll.Think = function(self)
	    	if ( self.NextThink or 0 ) > CurTime() then return end

	    	local children = self:GetCanvas():GetChildren()
	    	for k, child in pairs(children) do
	    		if !child:IsVisible() then
	    			child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
	    		end
	    	end

	    	self.NextThink = CurTime() + 0.2
	   	end

	   	local ScrollBar = categoryIScroll:GetVBar();

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
			
			categoryInvPanels[category] = vgui.Create("DCollapsibleCategory", categoryIScroll)
	        categoryInvPanels[category]:SetLabel("")
	        categoryInvPanels[category]:SetWide( GUI_BankInv_Panel_List:GetWide() )
	        categoryInvPanels[category]:Dock(TOP)
	        categoryInvPanels[category]:DockMargin(0, 0, 0, 5)
	        categoryInvPanels[category]:DockPadding(0,0,0,5)

	        categoryInvPanels[category].Paint = function(self, w, h)
				draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)

	            if self:GetExpanded() then
	            	--draw.RoundedBoxEx(0, 0, h-5, w, 5, Color(0, 0, 0, 70), true, true, true, true)
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

	        categoryInvPanels[category].List = vgui.Create("DIconLayout", categoryInvPanels[category] )
	        categoryInvPanels[category].List:SetPos(5, 25)
	    	categoryInvPanels[category].List:SetSize( 340, 300)
	    	categoryInvPanels[category].List:SetSpaceX(2)
	    	categoryInvPanels[category].List:SetSpaceY(2)
	    	categoryInvPanels[category].List.Paint = function(self, w, h)
	    		draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
	    	end
	        categoryInvPanels[category].Think = function(self, vis)
	        	if !vis and ( self.NextThink or 0 ) > CurTime() then return end
	        	local children = self.List:GetChildren()

	        	if table.Count(children) > 0 then
	        		self:SetVisible(true)
	        	else
	        		self:SetVisible(false)
	        	end
	        	self:GetParent():InvalidateLayout()

	        	if vis then return end
	        	self.NextThink = CurTime() + 0.2
	   		end


		end
	end

	--if !catUpdate and IsValid(categoryScroll) then categoryScroll:Remove() end
	if !IsValid(categoryScroll) then
		categoryScroll = vgui.Create("DScrollPanel", GUI_Bank_Panel_List)
		categoryScroll:SetWide(GUI_Bank_Panel_List:GetWide())
	    categoryScroll:Dock(FILL)
	    categoryScroll.Paint = function(self, w, h) end
	    categoryScroll.Think = function(self)
	    	if ( self.NextThink or 0 ) > CurTime() then return end

	    	local children = self:GetCanvas():GetChildren()
	    	for k, child in pairs(children) do
	    		if !child:IsVisible() then
	    			child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
	    		end
	    	end

	    	self.NextThink = CurTime() + 0.2
	   	end

	   	local ScrollBar = categoryScroll:GetVBar();

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
			
			categoryPanels[category] = vgui.Create("DCollapsibleCategory", categoryScroll)
	        categoryPanels[category]:SetLabel("")
	        categoryPanels[category]:SetWide( GUI_Bank_Panel_List:GetWide() )
	        categoryPanels[category]:Dock(TOP)
	        categoryPanels[category]:DockMargin(0, 0, 0, 5)
	        categoryPanels[category]:DockPadding(0,0,0,5)

	        categoryPanels[category].Paint = function(self, w, h)
				draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)

	            if self:GetExpanded() then
	            	--draw.RoundedBoxEx(0, 0, h-5, w, 5, Color(0, 0, 0, 70), true, true, true, true)
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

	        categoryPanels[category].List = vgui.Create("DIconLayout", categoryPanels[category] )
	        categoryPanels[category].List:SetPos(5, 25)
	    	categoryPanels[category].List:SetSize( 400, 300)
	    	categoryPanels[category].List:SetSpaceX(2)
	    	categoryPanels[category].List:SetSpaceY(2)
	    	categoryPanels[category].List.Paint = function(self, w, h)
	    		draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
	    	end
	        categoryPanels[category].Think = function(self, vis)
	        	if !vis and ( self.NextThink or 0 ) > CurTime() then return end
	        	local children = self.List:GetChildren()

	        	if table.Count(children) > 0 then
	        		self:SetVisible(true)
	        	else
	        		self:SetVisible(false)
	        	end
	        	self:GetParent():InvalidateLayout()

	        	if vis then return end
	        	self.NextThink = CurTime() + 0.2
	   		end


		end
	end
	for _, ItemTable in ipairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
		local item = ItemTable.ID
		if !Local_Inventory[item] then continue end

		for _, it in pairs( Local_Inventory[item] ) do
			local ItemTable = GAMEMODE.DayZ_Items[item]
			local amount = it.amount

			if amount > 0 then

				local itemCat = ItemTable.Category
				if !itemCat then itemCat = "none" end
				if amount < 1 then continue end
				if catUpdate and itemCat != catUpdate then continue end

				local panel, modelpanel = DZ_MakeIcon( it.id, item, amount, categoryInvPanels[itemCat].List, nil, "bankslot", 60, 60, false, true )
				table.insert(BankInvModelPanels, modelpanel)
				if !panel then continue end

				panel.Amount = amount
				panel.rarity = it.rarity

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

				modelpanel.NextThink = 0
				modelpanel.Think = function(self, w, h)
					if self.NextThink > CurTime() then return end
					self.NextThink = CurTime() + 1

					if !LocalPlayer():GetSafeZone() then
						panel.SetRed = true
					else
						panel.SetRed = false
					end

				end

				modelpanel.DoClick = function()
					RunConsoleCommand("DepositItem",it.id,amount)
				end

				modelpanel.DoRightClick = function()
					ItemMENU = DermaMenu()

					local itemamt = amount


					local panel = ItemMENU:AddOption("Deposit "..itemamt, 	function()
						RunConsoleCommand("DepositItem", it.id, amount)
					end)
					panel.Paint = PaintItemMenus

        			local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
        			if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end

					if itemamt > 1 then

						local DropMenu, panel = ItemMENU:AddSubMenu( "Deposit X" )
				        DropMenu.Paint = PaintItemMenus
				        panel.Paint = PaintItemMenus

						for k, v in ipairs(amts) do
				            if itemamt < v then continue end
				            local panel = DropMenu:AddOption("Deposit "..v,    function()
				                RunConsoleCommand("DepositItem",it.id,v)
				            end )
				            panel.Paint = PaintItemMenus
				        end
					end

					if itemamt > 1 then
						local panel = ItemMENU:AddOption("Deposit ...", function()
							GUI_Amount_Popup(it.id, "DepositItem")
						end)
						panel.Paint = PaintItemMenus
					end
					
					--ItemMENU:Open(gui.MousePos())

					ItemMENU:AddSpacer()
					ItemMENU:AddSpacer()

					DZ_MakeItemMenu(item, ItemTable, it, itemtype, modelpanel, ItemMENU)
				end	

				--GUI_BankInv_Panel_List:AddItem(panel)

				categoryInvPanels[itemCat].List:Add(panel)
				categoryInvPanels[itemCat].List:InvalidateLayout()
			end
		end
	end

	if !bank or !IsValid(GUI_Bank_Panel_List) then return end
	--GUI_Bank_Panel_List:Clear()

	for _, ItemTable in ipairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
	--for item, items in pairs(Local_Bank) do
		local item = ItemTable.ID
		if !Local_Bank[item] then continue end
		local items = Local_Bank[item]

		for _, it in pairs( items ) do
			local ItemTable = GAMEMODE.DayZ_Items[item]
			local amount = it.amount

			local itemCat = ItemTable.Category
			if !itemCat then itemCat = "none" end
			if amount < 1 then continue end
			if catUpdate and itemCat != catUpdate then continue end

			local panel, modelpanel = DZ_MakeIcon( it.id, item, amount, categoryPanels[itemCat].List, nil, "bankslot", 60, 60, false, true )
			if !panel then continue end
			
			panel.Amount = amount
			panel.rarity = it.rarity
			
			modelpanel.NextThink = 0
			modelpanel.Think = function(self, w, h)
				if self.NextThink > CurTime() then return end
				self.NextThink = CurTime() + 1

				if !LocalPlayer():GetSafeZone() then
					panel.SetRed = true
				else
					panel.SetRed = false
				end

			end

			modelpanel.DoClick = function()
				RunConsoleCommand("WithdrawItem", it.id, amount)
				--PrintTable(it)
			end

			modelpanel.DoRightClick = function()
				ItemMENU = DermaMenu()
				local itemamt = amount

				local panel = ItemMENU:AddOption("Withdraw "..itemamt, 	function()
					RunConsoleCommand("WithdrawItem",it.id,amount)
				end)
				panel.Paint = PaintItemMenus

				local amts = {1, 2, 5, 10, 25, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
				if !table.HasValue(amts, itemamt) then table.insert(amts, itemamt) end
				
			    if itemamt > 1 then
			        local DropMenu, panel = ItemMENU:AddSubMenu( "Withdraw X" )
			        DropMenu.Paint = PaintItemMenus
			        panel.Paint = PaintItemMenus

			        for k, v in ipairs(amts) do
			            if itemamt < v then continue end
			            local panel = DropMenu:AddOption("Withdraw "..v,    function()
			                RunConsoleCommand("WithdrawItem",it.id,v)
			            end )
			            panel.Paint = PaintItemMenus
			        end
        		end

				if itemamt > 1 then
					local panel = ItemMENU:AddOption("Withdraw ...", function()
						GUI_Amount_Popup(it.id, "WithdrawItem")
					end)
					panel.Paint = PaintItemMenus
				end

				ItemMENU:Open(gui.MousePos())
			end

			categoryPanels[itemCat].List:Add(panel)
			categoryPanels[itemCat].List:InvalidateLayout()
			BankModelPanels[itemCat] = BankModelPanels[itemCat] or {}
			table.insert(BankModelPanels[itemCat], modelpanel)
		end
	end
end

function GUI_Rebuild_Bank(parent)

	GUI_Bank_Menu(parent)	

end

DayZ_AddMenuTab( { order = 2, name = "Bank", type = "DPanel", icon = "cyb_mat/cyb_bank.png", desc = "Safe housing for those items you can't afford to lose", func = GUI_Rebuild_Bank, updatefunc = UpdateBank } )
