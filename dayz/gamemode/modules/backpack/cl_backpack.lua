local vgui = vgui
local draw = draw
local surface = surface
local gradient = Material("gui/gradient")

Local_Backpack = {}
Local_Backpack_Char = {}

--[[function CL_UpdateBackpack( umsg )
	local item = umsg:ReadString()
	local amount = umsg:ReadFloat()
	Local_Backpack[tostring(item)] = tonumber(amount)
end
usermessage.Hook( "UpdateBackpack", CL_UpdateBackpack );]]

net.Receive("UpdateBackpack", function(len)
	Local_Backpack = net.ReadTable()
	local category = net.ReadString() or ""

	if UpdateInv_BP2 then UpdateInv_BP2(category) end
end)

net.Receive("UpdateBackpackChar", function(len)
	Local_Backpack_Char = net.ReadTable()
	if UpdateCharBP then UpdateCharBP() end
end)

net.Receive("net_CloseLootMenu", function(len)
	if (GUI_Loot_Frame and GUI_Loot_Frame:IsValid()) then
		GUI_Loot_Frame:Remove()
		RemoveOpenedMenus()
	end
end)

local backpack
net.Receive("net_LootMenu", function(len)
	backpack = net.ReadFloat()
	GUI_Loot_Menu(backpack)
end)

function DoLootItem(item, amount, backpack, char)
	amount = amount or 1
	if !item then return end -- validation incase the item has been looted already by someone else (rare care scenario)
	
	net.Start( "LootItem" )
		net.WriteString( item )
		net.WriteInt( amount, 32 )
		net.WriteInt( backpack, 32 )
		net.WriteBit( char )
	net.SendToServer()
end

function UpdateCharItemsBP(parent, item, sizex, sizey)	

	--if table.Count(Local_Backpack_Char[item]) < 1 then return end

	local it = GAMEMODE.Util:GetItemIDByClass(Local_Backpack_Char, item)
	if !it then
		it = GAMEMODE.Util:GetItemIDByClass(Local_Backpack, item)
	end
    if it == nil then return false end

	local BP_GUI_Inv_Item_Panel, modelpanel = DZ_MakeIcon( it.id, item, it.amount, parent, nil, "invslot", sizex or 94, sizey or 94, false, true, false )
	BP_GUI_Inv_Item_Panel.rarity = it.rarity or 1

	BP_GUI_Inv_Item_Panel.CharTable = true
	BP_GUI_Inv_Item_Panel.Slot = parent
	BP_GUI_Inv_Item_Panel.ItemClass = item
	BP_GUI_Inv_Item_Panel.ItemID = it.id

	modelpanel.DoClick = function()
		DoLootItem( it.id, 1, backpack, true )
		timer.Simple( 0.3, UpdateCharBP )
	end
		
end

function GUI_Loot_Menu(backpack)	
	
	if GUI_Loot_Frame != nil and GUI_Loot_Frame:IsValid() then
		GUI_Loot_Frame:Remove()
	end

	if GUI_Loot_Frame != nil && GUI_Loot_Frame:IsValid() then GUI_Loot_Frame:Remove() end
	
	GUI_Loot_Frame = vgui.Create("DFrame")
	GUI_Loot_Frame:SetSize(810 ,600)
	GUI_Loot_Frame:MakePopup()
	GUI_Loot_Frame:SetTitle("")
	GUI_Loot_Frame:Center()	
	GUI_Loot_Frame.Paint = function(self, w, h)
		draw.RoundedBoxEx(0,2,2,w-4,h-4,Color( 60, 60, 60, 255 ), true, true, true, true) 
	end

	local Title_Spacer = vgui.Create("DPanel", GUI_Loot_Frame)
	Title_Spacer:Dock(TOP)
	Title_Spacer:DockMargin(5,0,5,0)
	Title_Spacer:SetTall(30)
	Title_Spacer.Paint = function(self, w, h)
		draw.RoundedBox(0,0,0,w,h,Color( 30, 30, 30, 200 ))

		local type = "Stored"
		local bp = Entity(backpack)
		if IsValid(bp) && ( bp:GetClass() == "prop_ragdoll" or bp:GetClass() == "grave" ) then
 			draw.DrawText(bp:GetStoredName().."'s Equipped Items:", "char_title18", 470, 6, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			type = bp:GetStoredName().."'s"
		end

		draw.DrawText(type.." Items:", "char_title18", 5, 6, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
	end

	local loot_all = vgui.Create("DButton", Title_Spacer)
	loot_all:SetPos(398, 5)
	loot_all:SetSize(60,20)
	loot_all:SetText("Loot All")
	loot_all.DoClick = function()
		timer.Create("lootall_"..backpack, 0.5, 0, function()
			if !IsValid(Entity(backpack)) then timer.Destroy("lootall_"..backpack) return end
			if !IsValid(GUI_Loot_Frame) then timer.Destroy("lootall_"..backpack) return end
			
			local it_id
			local amount = 1
			local char

			for _, items in pairs(Local_Backpack_Char) do
				
				for k, it in pairs( items ) do
					it_id = it.id
					amount = 1
					char = 1

					break	
				end				
			end

			if !it_id then
				for _, items in pairs(Local_Backpack) do
					
					for k, it in pairs( items ) do
						it_id = it.id
						amount = it.amount

						break	
					end				
				end
			end

			DoLootItem( it_id, amount, backpack, char )
		end)
	end
	
	if BP_GUI_Inv_Item_Panel != nil and BP_GUI_Inv_Item_Panel:IsValid() then
		BP_GUI_Inv_Item_Panel:Clear()
	end
		
	BPGUI_Inv_Panel_List_BP = vgui.Create("DPanelList", GUI_Loot_Frame)
	BPGUI_Inv_Panel_List_BP:Dock(FILL)
	BPGUI_Inv_Panel_List_BP:DockMargin(5,5,5,5)
	--BPGUI_Inv_Panel_List_BP:SetPos(235,50)
	BPGUI_Inv_Panel_List_BP.Paint = function(self, w, h)
		draw.RoundedBox(0,0,0,w,h,Color( 30, 30, 30, 200 ))
	end
	BPGUI_Inv_Panel_List_BP:SetPadding(7.5)
	BPGUI_Inv_Panel_List_BP:SetSpacing(2)
	BPGUI_Inv_Panel_List_BP:EnableHorizontal(3)
	BPGUI_Inv_Panel_List_BP:EnableVerticalScrollbar(true)
	
	local ragdoll = false
	if Entity(backpack):GetClass() == "prop_ragdoll" or Entity(backpack):GetClass() == "grave" then
		ragdoll = true
		RightPanel = vgui.Create("DPanelList", GUI_Loot_Frame)
		RightPanel:SetSize(327, 490)
		RightPanel:Dock(RIGHT)
		RightPanel:DockMargin(0,5,5,5)
		--RightPanel:SetPos(490, 75)
		RightPanel.Paint = function(self, w, h)
			draw.RoundedBox(0,0,0,w,h,Color( 30, 30, 30, 100 ))
		end
		
		local PlayerModel = vgui.Create("DModelPanel", RightPanel)
		if Entity(backpack).GetStoredModel then
			PlayerModel:SetModel(Entity(backpack):GetStoredModel())
			PlayerModel:SetSize(500,500)
			PlayerModel:SetPos(-75, 0)
		else
			PlayerModel:SetModel(Entity(backpack):GetModel())
			PlayerModel:SetSize(500,500)
			PlayerModel:SetPos(-75, 0)
		end

		if IsValid(PlayerModel.Entity) then
			PlayerModel.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
			PlayerModel.LayoutEntity = function() end
		end

		function UpdateCharBP()
		
			if IsValid(BCharSlot1) then BCharSlot1:Remove() end
			if IsValid(BCharSlot2) then BCharSlot2:Remove() end
			if IsValid(BCharSlot3) then BCharSlot3:Remove() end
			if IsValid(BCharSlot4) then BCharSlot4:Remove() end
			if IsValid(BCharSlot5) then BCharSlot5:Remove() end
			if IsValid(BCharSlot6) then BCharSlot6:Remove() end
			if IsValid(BCharSlot7) then BCharSlot7:Remove() end
			if IsValid(BCharSlot8) then BCharSlot8:Remove() end
			if IsValid(BCharSlot9) then BCharSlot9:Remove() end
			if IsValid(BCharSlot10) then BCharSlot10:Remove() end
			
			local charslotcolor = Color(0,0,0,50)

			BCharSlot1 = vgui.Create("DPanel", RightPanel) -- Hat
			BCharSlot1:SetSize(98,98)
			BCharSlot1:SetPos(125,60)
			BCharSlot1.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end
			
			BCharSlot2 = vgui.Create("DPanel", RightPanel) -- Clothes
			BCharSlot2:SetSize(98,98)
			BCharSlot2:SetPos(125,165)
			BCharSlot2.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot3 = vgui.Create("DPanel", RightPanel) -- Primary Weapon
			BCharSlot3:SetSize(64,64)
			BCharSlot3:SetPos(230,304)
			BCharSlot3.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end	
			
			BCharSlot4 = vgui.Create("DPanel", RightPanel) -- Secondary Weapon
			BCharSlot4:SetSize(64,64)
			BCharSlot4:SetPos(230,375)
			BCharSlot4.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end
			
			BCharSlot5 = vgui.Create("DPanel", RightPanel) -- Melee Weapon
			BCharSlot5:SetSize(64,64)
			BCharSlot5:SetPos(54,304)
			BCharSlot5.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot6 = vgui.Create("DPanel", RightPanel) -- Tertiary Weapon
			BCharSlot6:SetSize(64,64)
			BCharSlot6:SetPos(54,375)
			BCharSlot6.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot7 = vgui.Create("DPanel", RightPanel) -- Backpack
			BCharSlot7:SetSize(64,64)
			BCharSlot7:SetPos(230,165)
			BCharSlot7.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot8 = vgui.Create("DPanel", RightPanel) -- Shoes
			BCharSlot8:SetSize(98,98)
			BCharSlot8:SetPos(125,375)
			BCharSlot8.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot9 = vgui.Create("DPanel", RightPanel) -- Pants
			BCharSlot9:SetSize(98,98)
			BCharSlot9:SetPos(125,270)
			BCharSlot9.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			BCharSlot10 = vgui.Create("DPanel", RightPanel) -- BodyArmor
			BCharSlot10:SetSize(64,64)
			BCharSlot10:SetPos(54,165)
			BCharSlot10.Paint = function(self, w, h)
				draw.RoundedBox(8,0,0,w,h,charslotcolor)
			end

			for k, items in pairs(Local_Backpack_Char) do
				local amount = 0
		        for _, item in pairs(items) do
		            amount = amount + item.amount
		        end

		        if amount < 1 then continue end

				if GAMEMODE.DayZ_Items[k].Hat then
					UpdateCharItemsBP(BCharSlot1, k)		
				elseif GAMEMODE.DayZ_Items[k].Body then
					UpdateCharItemsBP(BCharSlot2, k)
				elseif GAMEMODE.DayZ_Items[k].Primary then
					UpdateCharItemsBP(BCharSlot3, k, 60, 60)
				elseif GAMEMODE.DayZ_Items[k].Secondary then
					UpdateCharItemsBP(BCharSlot4, k, 60, 60)
				elseif GAMEMODE.DayZ_Items[k].Melee then
					UpdateCharItemsBP(BCharSlot5, k, 60, 60)
				elseif GAMEMODE.DayZ_Items[k].Tertiary then
					UpdateCharItemsBP(BCharSlot6, k, 60, 60)
				elseif GAMEMODE.DayZ_Items[k].BackPack then
					UpdateCharItemsBP(BCharSlot7, k, 60, 60)
				elseif GAMEMODE.DayZ_Items[k].Shoes then
					UpdateCharItemsBP(BCharSlot8, k)
				elseif GAMEMODE.DayZ_Items[k].Pants then
					UpdateCharItemsBP(BCharSlot9, k)
				elseif GAMEMODE.DayZ_Items[k].BodyArmor then
					UpdateCharItemsBP(BCharSlot10, k, 60, 60)
				end
			end
		end
		UpdateCharBP()
	end
		
	backpackCategoryPanels = {}
	function UpdateInv_BP2(catUpdate)
		if !IsValid(BPGUI_Inv_Panel_List_BP) then return end

		--BPGUI_Inv_Panel_List_BP:Clear(true)

		local itemCategories = GAMEMODE.Util:GetItemCategories()
	    if !catUpdate and IsValid(backpackCategoryScroll) then backpackCategoryScroll:Remove() end
	    if !IsValid(backpackCategoryScroll) then
	        backpackCategoryScroll = vgui.Create("DScrollPanel", BPGUI_Inv_Panel_List_BP)
	        backpackCategoryScroll:Dock(FILL)
	        backpackCategoryScroll.Paint = function(self, w, h) end
	        backpackCategoryScroll.Think = function(self)
	            if ( self.NextThink or 0 ) > CurTime() then return end

	            local children = self:GetCanvas():GetChildren()
	            for k, child in pairs(children) do
	                if !child:IsVisible() then
	                    child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
	                end
	            end

	            self.NextThink = CurTime() + 0.2
	        end

	        local ScrollBar = backpackCategoryScroll:GetVBar();

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
	            
	            backpackCategoryPanels[category] = vgui.Create("DCollapsibleCategory", backpackCategoryScroll)
	            backpackCategoryPanels[category]:SetLabel("")
	            --backpackCategoryPanels[category]:SetWide( parent:GetWide() )
	            backpackCategoryPanels[category]:Dock(TOP)
	            --backpackCategoryPanels[category]:SetSize(350, 310)
	            backpackCategoryPanels[category]:DockMargin(0, 0, 5, 5)
	            backpackCategoryPanels[category]:DockPadding(0, 0, 0, 5)

	            backpackCategoryPanels[category].Paint = function(self, w, h)
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

	            backpackCategoryPanels[category].List = vgui.Create("DIconLayout", backpackCategoryPanels[category] )
	            backpackCategoryPanels[category].List:SetPos(0, 20)
	            local size = 445
	            if !ragdoll then size = 790 end
	            backpackCategoryPanels[category].List:SetSize( size, 10 )
	            backpackCategoryPanels[category].List:SetSpaceX(5)
	            backpackCategoryPanels[category].List:SetSpaceY(5)
	            backpackCategoryPanels[category].List:SetBorder(5)

	            backpackCategoryPanels[category].List.Paint = function(self, w, h)
	                draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
	            end
	            backpackCategoryPanels[category].Think = function(self, vis)
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
	            if IsValid(backpackCategoryPanels[v].List) then
	                backpackCategoryPanels[v].List:Clear()
	            end
	        end
	        --print("clearing and rebuilding all")
	    else
	        -- we just have the one category to update
	        if !backpackCategoryPanels[catUpdate] then return end
	        if IsValid(backpackCategoryPanels[catUpdate].List) then
	            backpackCategoryPanels[catUpdate].List:Clear()
	        end
	        --print("clearing and rebuilding "..catUpdate)

	    end

		for item, ItemTable in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, "Name") do
			if !Local_Backpack[item] then continue end
			
			for _, it in pairs( Local_Backpack[item] ) do
				local ItemTable = GAMEMODE.DayZ_Items[item]
				local amount = it.amount
				
				if amount > 0  then

                	local itemCat = ItemTable.Category
                	if !itemCat then itemCat = "none" end

					if catUpdate and itemCat != catUpdate then continue end

					local BP_GUI_Inv_Item_Panel_BP, GUI_Inv_Item_Icon = DZ_MakeIcon( it.id, item, amount, backpackCategoryPanels[itemCat].List, nil, "invslot", 60, 60, false, true, false )
					BP_GUI_Inv_Item_Panel_BP.ItemClass = item
					BP_GUI_Inv_Item_Panel_BP.ItemID = it.id
					BP_GUI_Inv_Item_Panel_BP.rarity = it.rarity or 1

					GUI_Inv_Item_Icon.DoClick = function()
						DoLootItem( it.id, amount, backpack )
						timer.Simple( 0.3, function() UpdateInv_BP2(itemCat) end)
					end
					
					GUI_Inv_Item_Icon.DoRightClick = function()
						ItemMENU = DermaMenu()
						
						local amts = {1, 5, 10, 25, 50, 100}
						for k, v in ipairs(amts) do
							if amount < v then continue end
							local panel = ItemMENU:AddOption("Loot "..v, function()
								DoLootItem( it.id, v, backpack )
								timer.Simple( 0.3, function() UpdateInv_BP2(itemCat) end)
							end )
							panel.Paint = PaintItemMenus
						end

						if amount > 1 then
							local panel = ItemMENU:AddOption("Loot "..amount, function()
								DoLootItem( it.id, amount, backpack )
								timer.Simple( 0.3, function() UpdateInv_BP2(itemCat) end)
							end)
							panel.Paint = PaintItemMenus
					    end

						ItemMENU:Open( gui.MousePos() )	
					end		
					
					backpackCategoryPanels[itemCat].List:Add(BP_GUI_Inv_Item_Panel_BP)
					backpackCategoryPanels[itemCat].List:InvalidateLayout()			
					--BPGUI_Inv_Panel_List_BP:AddItem(BP_GUI_Inv_Item_Panel_BP)

				end
			end
		end
	end
	UpdateInv_BP2()

	
end
