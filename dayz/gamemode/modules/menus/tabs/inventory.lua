local InventoryModelPanels = {}
invcategoryPanels = invcategoryPanels or {}

DZ_CategorySortType = DZ_CategorySortType or "Name"

function UpdateInv( catUpdate )
	
	local InventoryTable = Local_Inventory

	if !IsValid(GUI_Inv_Panel_List) then return end
	
	if IsValid(InvPlayerModel) then
		InvPlayerModel:SetModel(LocalPlayer():GetModel())
		InvPlayerModel.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
	end
	
	if !catUpdate then
		for k, v in pairs(InventoryModelPanels) do
			if IsValid(v) and IsValid(v:GetEntity()) then
				v:Remove() -- Because GC no worky on modelpanels!
			end
		end
	end
	--GUI_Inv_Panel_List:Clear(true)

	if !IsValid(DZ_CategorySort) then
		DZ_CategorySort = vgui.Create("DComboBox", GUI_Inv_Panel_List)
		DZ_CategorySort:Dock(TOP)
		DZ_CategorySort:SetTall(20)
		DZ_CategorySort:AddChoice("Name", "Name", true)
		DZ_CategorySort:AddChoice("Price", "GeneratedPrice")
		DZ_CategorySort:AddChoice("Condition", "quality")
		DZ_CategorySort:AddChoice("Rarity", "rarity")
	  	DZ_CategorySort.OnSelect = function(self, idx, val, data)
	    	DZ_CategorySortType = tostring(data)
	    	UpdateInv()
	    end
	end
	DZ_CategorySort:Remove() -- unfinished

	local itemCategories = GAMEMODE.Util:GetItemCategories()
	if !catUpdate and IsValid(invcategoryScroll) then invcategoryScroll:Remove() end
	if !IsValid(invcategoryScroll) then
		invcategoryScroll = vgui.Create("DScrollPanel", GUI_Inv_Panel_List)
	    invcategoryScroll:Dock(FILL)
	    invcategoryScroll.Paint = function(self, w, h) end
	    invcategoryScroll.Think = function(self)
	    	if ( self.NextThink or 0 ) > CurTime() then return end

	    	local children = self:GetCanvas():GetChildren()
	    	for k, child in pairs(children) do
	    		if !child:IsVisible() then
	    			child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
	    		end
	    	end

	    	self.NextThink = CurTime() + 0.2
	   	end

	   	local ScrollBar = invcategoryScroll:GetVBar();

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
			
			invcategoryPanels[category] = vgui.Create("DCollapsibleCategory", invcategoryScroll)
	        invcategoryPanels[category]:SetLabel("")
	        --invcategoryPanels[category]:SetWide( GUI_Inv_Panel_List:GetWide() )
	        invcategoryPanels[category]:Dock(TOP)
	        --invcategoryPanels[category]:SetSize(350, 310)
	        invcategoryPanels[category]:DockMargin(0, 0, 5, 5)
	        invcategoryPanels[category]:DockPadding(0, 0, 0, 5)

	        invcategoryPanels[category].Paint = function(self, w, h)
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

	        invcategoryPanels[category].List = vgui.Create("DIconLayout", invcategoryPanels[category] )
	        invcategoryPanels[category].List:SetPos(0, 20)
	    	invcategoryPanels[category].List:SetSize( 445, 10 )
	    	invcategoryPanels[category].List:SetSpaceX(5)
	    	invcategoryPanels[category].List:SetSpaceY(5)
	    	invcategoryPanels[category].List:SetBorder(5)
	    	invcategoryPanels[category].List:Receiver("cat_slot", function(pnl, tbl, dropped, menu, x, y)
		        if (not dropped) then return end
		        --print(tbl[1]:GetParent())
		        if tbl[1]:GetParent() == pnl then 
		            --print(tbl[1].ItemClass.." wants SplitItem "..tbl[1].Amount/2)
		            RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount/2)
		            return 
		        end
		        --tbl[1]:SetSize(66, 66)
		        --tbl[1]:GetChild(1):SetSize(50, 50)
		        --GUI_Inv_Panel_List:AddItem(tbl[1])
		        --RunConsoleCommand("Dequipitem", tbl[1].ItemID)
		    end)

	    	invcategoryPanels[category].List.Paint = function(self, w, h)
	    		draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
	    	end
	        invcategoryPanels[category].Think = function(self, vis)
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
			if IsValid(invcategoryPanels[v].List) then
				invcategoryPanels[v].List:Clear()
			end
		end
		--print("clearing and rebuilding all")
	else
		-- we just have the one category to update
		if !invcategoryPanels[catUpdate] then return end
		if IsValid(invcategoryPanels[catUpdate].List) then
			invcategoryPanels[catUpdate].List:Clear()
		end
		--print("clearing and rebuilding "..catUpdate)

	end

	--print("UpdateInv RAN")
	local tab = {}
	local i = 0
	if DZ_CategorySortType != "Name" && DZ_CategorySortType != "GeneratedPrice" then
		for _, items in pairs( Local_Inventory ) do

			for _, it in SortedPairsByMemberValue( items, string.lower(DZ_CategorySortType) ) do
				tab[i] = it
				i = i + 1
			end
		end
	else
		for k, v in SortedPairsByMemberValue( GAMEMODE.DayZ_Items, DZ_CategorySortType or "Name" ) do
			if !Local_Inventory[v.ID] then continue end

			for _, it in pairs( Local_Inventory[v.ID] ) do
				tab[i] = it
				i = i + 1
			end
		end
	end

	for _, it in pairs( tab ) do 
		local item = it.class
		local ItemTable = GAMEMODE.DayZ_Items[item]
		local amount = it.amount
		
		local itemCat = ItemTable.Category
		if !itemCat then itemCat = "none" end

		if catUpdate and itemCat != catUpdate then continue end

		if amount > 0 then

			local panel, modelpanel = DZ_MakeIcon( it.id, item, amount, invcategoryPanels[itemCat].List, nil, "invslot", 66, 66, false, true )
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

			modelpanel.DoClick = function()
				if itemtype != '' then
					RunConsoleCommand("EquipItem", it.id)
					return
				end
				if ItemTable.ProcessFunction != nil or ItemTable.BloodFor or ItemTable.HealsFor or ItemTable.EatFor != nil or ItemTable.DrinkFor != nil then
					RunConsoleCommand("Useitem", it.id)
				end
			end

			modelpanel.DoRightClick = function()
				DZ_MakeItemMenu(item, ItemTable, it, itemtype, modelpanel)
			end

			invcategoryPanels[itemCat].List:Add(panel)
			invcategoryPanels[itemCat].List:InvalidateLayout()
			--GUI_Inv_Panel_List:AddItem(panel)
			table.insert(InventoryModelPanels, modelpanel)
			
		end

	end

	if isfunction(UpdateCharPanels) then UpdateCharPanels() end
end


function GUI_Rebuild_Inventory(parent)
	
	GUI_Rebuild_Inv(parent)	

end

DayZ_AddMenuTab( { order = 1, name = "Inventory", type = "DPanel", icon = "cyb_mat/cyb_backpack.png", desc = "Your Items and Equipment", func = GUI_Rebuild_Inventory } )
