local vgui = vgui
local draw = draw
local surface = surface
local gradient = Material("gui/gradient")

CanCrafts = CanCrafts or {}

local CraftModelPanels = {}

Local_BPTable = Local_BPTable or {}
net.Receive("UpdateBluePrint", function(len)
	
	local item = net.ReadString()
	local cook = net.ReadBit()

	if !GAMEMODE.DayZ_Items[item] then return end

	Local_BPTable[item] = true

	DoBluePrintUI(item, cook)

	local cat = GAMEMODE.DayZ_Items[item].Category
	if !cat then cat = "none" end

	if isfunction(UpdateCraftInv) then UpdateCraftInv(cat, true) end

end)

net.Receive("UpdateBluePrintsFull", function(len)

	Local_BPTable = net.ReadTable()

	UpdateCraftInv()

end)

BPFrames = BPFrames or {}
function DoBluePrintUI( item, cook )
	if !GAMEMODE.DayZ_Items[item] then return end

	local name = GAMEMODE.DayZ_Items[item].Name
	local MenuSize = 505

	local yPos = 300

	if table.Count(BPFrames) > 0 then
		yPos = yPos + ( table.Count(BPFrames) * 90 )
	end

	local BPFrame = vgui.Create("DPanel")

	BPFrame:SetPos(-MenuSize, yPos)
	BPFrame:SetSize( MenuSize, 85 )

	timer.Simple(5, function() 
		if IsValid(BPFrame) then 
			BPFrame:MoveTo( -MenuSize, yPos, 0.75, 0, -1, function() table.RemoveByValue(BPFrames, BPFrame) BPFrame:Remove() end ) 
		end 
	end)

	BPFrame:MoveTo( 0, yPos, 0.75, 0, -1, function() end )

	BPFrame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color( 0, 0, 0, 150 ))

		draw.RoundedBoxEx(4,5,5,75,75,Color( 0, 0, 0, 50 ), true, true, true, true)
		draw.RoundedBoxEx(4,6,6,75-2,75-2,Color( 255, 255, 255, 10 ), true, true, true, true) 
		draw.RoundedBoxEx(4,7,7,75-4,75-4,Color( 60, 60, 60, 255 ), true, true, true, true) 

		local text = (cook == 1) and "RECIPE" or "BLUEPRINT"
		local text2 = (cook == 1) and "make" or "craft"
		draw.DrawText( text.." UNLOCKED!", "char_options", 90, 5, Color(0, 200, 0 ,255), TEXT_ALIGN_LEFT )
		
		draw.DrawText( "You now know how to "..text2..":", "char_title16", 90, h/2+3, Color(200,200,200,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		draw.DrawText( name, "char_title20", 90, h/2+15, Color(200,200,200,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	if !IsValid(BPFrame.Icon) then
		BPFrame.Icon, BPFrame.MIcon = DZ_MakeIcon( nil, item, 0, BPFrame, nil, nil, 75, 75, false, true, false )
		BPFrame.Icon.rarity = 1
	end
	BPFrame.Icon:SetPos(5, 5)

	table.insert(BPFrames, BPFrame)
end

function GUI_Rebuild_Crafting(parent)
	GUI_Rebuild_Craft_Items(parent)	
end

local CraftingValue = ""
function GUI_Rebuild_Craft_Items(parent)
		
	if GUI_Inv_Item_Panel != nil and GUI_Inv_Item_Panel:IsValid() then
		GUI_Inv_Item_Panel:Clear()
	end

	if IsValid(CraftPanel) then CraftPanel:Remove() end			
	CraftPanel = vgui.Create("DIconLayout", parent)
	CraftPanel:Dock(FILL)
	CraftPanel:DockMargin(5,0,5,-8)

	CraftPanel.Paint = function() end
	CraftPanel.SelectedItemPanel = nil
	
	CraftItemPanel = vgui.Create("DPanel", parent)
	CraftItemPanel:Dock(BOTTOM)
	CraftItemPanel:SetTall(95)
	CraftItemPanel:DockMargin(5,8,5,0)
	CraftItemPanel.Displayed = false
	CraftItemPanel.Paint = function(self, w, h)
		draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))

		if CraftItemPanel.Displayed then return end

		draw.SimpleText( LANG.GetTranslation("craftingtip"), "Cyb_HudTEXT", w/2, h/2 - 20, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( LANG.GetTranslation("craftingtip2"), "Cyb_HudTEXT", w/2, h/2, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( LANG.GetTranslation("craftingtip3"), "Cyb_HudTEXT", w/2, h/2 + 20, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	CanCrafts = {}
	for k, v in SortedPairsByMemberValue(GAMEMODE.DayZ_Items, "Category") do
		if !v.ReqCraft and !v.ReqCook then continue end
		if v.CantCraft or v.CantCook then continue end
		if v.genRarity then continue end
		--print(k)
		CanCrafts[k] = v.Name
		--table.insert(CanCrafts, {k, "Name" = Name})
	end
	
	UpdateCraftInv()

end

local SelectModelPanels = {}
local function DoSelectItemsUI(item, cmd, w_amount)

	local ItemTable = GAMEMODE.DayZ_Items[item]

	if !ItemTable then return false end

	local craft = ItemTable.ReqCraft and table.Copy( ItemTable.ReqCraft ) or table.Copy( ItemTable.ReqCook ) 

	if IsValid(SelectFrame) then SelectFrame:Remove() end

	SelectFrame = vgui.Create("DPanel")
	SelectFrame:SetSize(400, 300)
	SelectFrame:Center()
	SelectFrame:MakePopup()
	SelectFrame.Paint = function(self, w, h) draw.RoundedBox(2,0,0,w,h,CyB.panelBg) end
	SelectFrame.Think = function(self)
		if ( self.nextThink or 0 ) > CurTime() then return end

		if !self:HasFocus() then
			self:MoveToFront()
		end
		self.nextThink = CurTime() + 0.1
	end

	local title_select = vgui.Create("DPanel", SelectFrame)
    title_select:Dock(TOP)
    title_select:SetTall(20)
    title_select:DockMargin(5, 5, 5, 0)
    title_select.Paint = function(self, w, h)
        paint_bg(self, w, h)

        if SelectFrame.endItem then
        	draw.SimpleText("Crafted Item:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        	return
        end
        draw.SimpleText("Required Item:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

    local close = vgui.Create("DButton", SelectFrame)
    close:SetColor(Color(255,255,255,255))
    close:SetFont("Cyb_Inv_Bar")
    close:SetText("X")
    close.Paint = function() end
    close:SetSize(32,32)
    close:SetPos(close:GetParent():GetWide()-close:GetWide(), 0)
    close.DoClick = function() if SelectFrame:IsValid() then SelectFrame:Remove() end end

	SelectFrame.SelectedItems = {}

	local i = 1


	SelectFrame.Required = vgui.Create("DPanel", SelectFrame)
	SelectFrame.Required:Dock(TOP)
	SelectFrame.Required:DockMargin(5,5,5,0)
	SelectFrame.Required:SetTall(100)
	SelectFrame.Required.Step = i
	SelectFrame.Required.CalcAmount = 0
	SelectFrame.Required.Paint = function(self, w, h) paint_bg(self,w,h) end
	SelectFrame.Required.Think = function(self)

		if IsValid(self.But) then
			if !craft[self.Step] then
				self.But:SetVisible(true)

				if !SelectFrame.endItem then
					
					local rarity = 0 -- lets do this the old way
					local max = 0
					local used_ids = {}
					for k, id in pairs(SelectFrame.SelectedItems) do
						local it = GAMEMODE.Util:GetItemByDBID(Local_Inventory, id)

						if !it then continue end -- why

						rarity = rarity + it.rarity

						if table.HasValue(used_ids, id) then continue end
						table.insert(used_ids, id)
						
						max = max + it.amount
					end

					max = math.floor( max / table.Count( SelectFrame.SelectedItems ) )

					SelectFrame.Required.CalcAmount = max

					rarity = rarity / table.Count( SelectFrame.SelectedItems )
					-- quick math median

					if IsValid(SelectFrame.Required.panel) then SelectFrame.Required.panel:Remove() end

					local panel, modelpanel = DZ_MakeIcon( nil, item, 1, SelectFrame.Required, nil, "upgradeslot", 48, 48, false, true )
	    			if !panel then return end

	    			panel.rarity = math.floor( rarity )

	    			panel:SetPos(SelectFrame:GetWide()/2 - panel:GetWide() / 2, 25)

					SelectFrame.endItem = item

					local CraftAmount = vgui.Create("DNumSlider", SelectFrame.Panel)
					CraftAmount:SetWide(270)
					CraftAmount:SetMin(1)
					CraftAmount:SetValue(1)
					CraftAmount:SetMax( max )
					CraftAmount:SetPos(0, 50)
					CraftAmount:SetDecimals(0)
					CraftAmount.Paint = function(self, w, h)
						draw.RoundedBox(2,110,-10,w,h+20,Color( 50, 50, 50, 255 ))
						local aw = w - 160
						draw.SimpleText(1, "char_title16", aw + 8, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
						draw.SimpleText(max, "char_title16", w - 8, 0, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
					end
					CraftAmount.OnValueChanged = function(s)
						if IsValid(CraftItemPanel.CraftAmount) then
							local amt = math.Round( s:GetValue() )
							CraftItemPanel.CraftAmount:SetValue( amt )
							panel.Amount = amt
						end
					end

					CraftAmount.TextArea:Hide()

					CraftAmount.Scratch:SetColor(Color(200,200,200,255))
				end
			end
		end

		if IsValid(CraftItemPanel.CraftAmount) then

			w_amount = CraftItemPanel.CraftAmount:GetValue()
			self.But:SetText("CRAFT x"..math.floor(w_amount))
			self.But.amt = w_amount
		end
	end

	local title_select = vgui.Create("DPanel", SelectFrame)
    title_select:Dock(TOP)
    title_select:SetTall(20)
    title_select:DockMargin(5, 5, 5, 0)
    title_select.Paint = function(self, w, h)
        paint_bg(self, w, h)
        if SelectFrame.endItem then
        	draw.SimpleText("Drag the slider to craft multiple:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        	return
        end
        draw.SimpleText("Click to select available items:", "char_title20", 5, 0, Color(200, 200, 200), TEXT_ALIGN_LEFT)
    end

	SelectFrame.Panel = vgui.Create("DPanel", SelectFrame)
	SelectFrame.Panel:Dock(FILL)
    SelectFrame.Panel:SetWide(SelectFrame:GetWide() - 10)
    SelectFrame.Panel.Paint = function(self, w, h) paint_bg(self,w,h) end
    SelectFrame.Panel:DockMargin(5,5,5,5)

	SelectFrame.ItemList = vgui.Create("DIconLayout", SelectFrame.Panel)
	SelectFrame.ItemList:Dock(FILL)
    SelectFrame.ItemList:SetWide(SelectFrame:GetWide() - 10)
    SelectFrame.ItemList:DockMargin(5,5,5,5)
    SelectFrame.ItemList.Paint = function(self, w, h) end
    SelectFrame.ItemList:Receiver("invslot", function(pnl, tbl, dropped, menu, x, y)
        if (not dropped) then return end

        if tbl[1]:GetParent() == pnl then 
            --print(tbl[1].ItemClass.." wants SplitItem "..tbl[1].Amount/2)

            RunConsoleCommand("SplitItem", tbl[1].ItemID, tbl[1].Amount/2)

            return 
        end
	end)

   	local tbl_c = {}
	function UpdateInvSelect()
		if !IsValid(SelectFrame.ItemList) then return false end

		SelectFrame.ItemList:Clear()

		local noitems = true
		local step = SelectFrame.Required.Step

		tbl_c = {} -- needs to wipe

		for k, v in pairs(SelectFrame.SelectedItems) do
			tbl_c[v] = ( tbl_c[v] or 0 ) + 1 
		end

		for _, ItemTable in pairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
	        local item2 = ItemTable.ID
	        if !Local_Inventory[item2] then continue end
	        
	        if !step then continue end
	        if craft[ step ] != item2 then continue end -- only show the items it needs.


	        for _, it in pairs( Local_Inventory[item2] ) do
	            local ItemTable = GAMEMODE.DayZ_Items[item2]
	            local amount = it.amount

	            if amount < ( tbl_c[it.id] or 0 ) then continue end -- do not show items you have selected, in case it requires multiple.

	            if amount > 0 then

	            	noitems = false

	                local panel, modelpanel = DZ_MakeIcon( it.id, item2, amount, SelectFrame.ItemList, nil, "invslot", 48, 48, false, true )
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
	                    --DZ_MakeItemMenu(item2, ItemTable, it, itemtype, modelpanel)
	                end

	                modelpanel.DoClick = function()
	                	i = i + 1
	                	SelectFrame.Required.ItemID = it.id
	                	NextItem(i)

	                	UpdateInvSelect()

	                	if it.amount > 1 && craft[ i ] then
			                --RunConsoleCommand("SplitItem", it.id, it.amount / 2)
			            end

	                	if IsValid(InspectPanel) then
					        InspectPanel:Remove()
					    end
	                end

	                SelectFrame.ItemList:Add(panel)
	                SelectFrame.ItemList:InvalidateLayout()
	                --GUI_Inv_Panel_List:AddItem(panel)
	                table.insert(SelectModelPanels, modelpanel)
	                
	            end

	        end
	    end

	    if noitems && craft[ step ] then
	    	SelectFrame.Panel.Paint = function(self, w, h) 
		    	paint_bg(self,w,h) 
		    	local it = craft[SelectFrame.Required.Step]
		    	if !GAMEMODE.DayZ_Items[it] then return end

		    	draw.DrawText( "Cancelling... Item not found\n"..GAMEMODE.DayZ_Items[it].Name, "SafeZone_INFO", w/2, h/2 - 40, Color(200,200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		    end
	    	
	    	timer.Create("removeselect", 3, 0, function() if IsValid(SelectFrame) then SelectFrame:Remove() end end)
	    else
	    	SelectFrame.Panel.Paint = function(self, w, h) 
		    	paint_bg(self,w,h)
		    end

	    	timer.Destroy("removeselect")
	    end

	    return noitems
	end

	function NextItem(step)

		local it = craft[step]

		SelectFrame.Required.Step = step

		local olditem = SelectFrame.Required.ItemID
		
		SelectFrame.Required.ItemID = nil
		table.insert(SelectFrame.SelectedItems, olditem)

		if !it then 
			-- no more steps... reset to original item
			return false 
		end

		SelectFrame.Required:Clear()

		SelectFrame.Required.But = vgui.Create("DButton", SelectFrame.Required)
		SelectFrame.Required.But:Dock(BOTTOM)
		SelectFrame.Required.But:SetTall(20)
		SelectFrame.Required.But:SetText("CRAFT x"..w_amount)
		SelectFrame.Required.But.amt = 1 
		SelectFrame.Required.But.Paint = PaintButtons
		SelectFrame.Required.But.DoClick = function(self)

			if self.amt > 1 && !string.find(cmd, "Multi") then
				cmd = "Multi"..cmd
			end

			RunConsoleCommand( cmd, item, self.amt, unpack(SelectFrame.SelectedItems) )

			SelectFrame:Remove()

			if IsValid(CraftItemPanel.CraftAmount) then
				CraftItemPanel.CraftAmount:SetValue( 1 ) -- default back
			end

		end
		SelectFrame.Required.But:SetVisible(false)

		SelectFrame.Required.panel, modelpanel = DZ_MakeIcon( nil, it, 1, SelectFrame.Required, nil, "upgradeslot", 48, 48, false, true )
	    SelectFrame.Required.panel.rarity = 1

	    SelectFrame.Required.panel:SetPos(SelectFrame:GetWide()/2 - SelectFrame.Required.panel:GetWide() / 2, 25)

	    local noitems = UpdateInvSelect()
	    
		return noitems
	end
	NextItem(i)

end

local CraftItemModelPanels = {}
local CraftingModelPanels = {}
local function CraftPanelSetItem( item )

	for k, v in pairs(CraftItemModelPanels) do
		if IsValid(v) then
			v:Remove()
		end
	end

	CraftItemPanel:Clear()

	CraftItemPanel.SelectedItems = {}

	if !Local_BPTable[ item ] and !GAMEMODE.DayZ_Items[item].NoBlueprint then
		CraftItemPanel.Displayed = false
		return
	end

	local tbl2 = {}

	CraftItemPanel.Displayed = true

	local panel, craftableItemModelPanel = DZ_MakeIcon( nil, item, 0, CraftItemPanel, nil, nil, 86, 86, true, false, false )
	panel:SetPos(5,5)
	panel.rarity = 1
	table.insert(CraftItemModelPanels, craftableItemModelPanel)
	
	local ItemName = vgui.Create("DLabel", CraftItemPanel)
	ItemName:SetColor(Color(255,255,255,255))
	ItemName:SetFont("Cyb_Inv_Bar")
	ItemName:SetText(GAMEMODE.DayZ_Items[item].Name)
	ItemName:SizeToContents()
	ItemName:SetPos(100,10)
	
	local Description = vgui.Create("DLabel", CraftItemPanel)
	Description:SetColor(Color(255,255,255,255))
	Description:SetFont("Cyb_Inv_Label")
	Description:SetText(GAMEMODE.DayZ_Items[item].Desc)
	Description:SizeToContents()
	Description:SetPos(100,30)

	if !GAMEMODE.DayZ_Items[item].ReqCraft and !GAMEMODE.DayZ_Items[item].ReqCook then return end
	
	local CraftAmount = vgui.Create("DNumSlider", CraftItemPanel)
	CraftItemPanel.CraftAmount = CraftAmount
	local DoCook = vgui.Create("DButton", CraftItemPanel)
	--DoCook.Paint = function() end
	local DoCook2 = vgui.Create("DButton", CraftItemPanel)

	DoCook.Paint = PaintButtons
	DoCook2.Paint = PaintButtons

	local buttontext = "CRAFT"
	local buttontext2 = "DECOMPILE"
	if GAMEMODE.DayZ_Items[item].ReqCook then
		buttontext = "COOK"

		if !Local_BPTable[item] and !GAMEMODE.DayZ_Items[item].NoBlueprint then
			buttontext2 = "LEARN BLUEPRINT"
		else
			buttontext2 = ""
			DoCook2:SetVisible(false)
		end
	end

	local buttonamount = " x1"

	CraftAmount:SetWide(270)
	CraftAmount:SetMin(1)
	CraftAmount:SetMax(1000)
	CraftAmount:SetPos(175, 54)
	CraftAmount:SetDecimals(0)
	CraftAmount:SetValue(1)
	CraftAmount.Paint = function(self, w, h)
		draw.RoundedBox(2,110,-10,w,h+20,Color( 50, 50, 50, 255 ))
	end
	CraftAmount.OnValueChanged = function(s)
		buttonamount = " x"..math.Round(s:GetValue())
		DoCook:SetText(buttontext..buttonamount)
		DoCook2:SetText(buttontext2..buttonamount)
	end

	CraftAmount.TextArea:Hide()

	CraftAmount.Scratch:SetColor(Color(200,200,200,255))

	local HasAmount = vgui.Create("DLabel", CraftItemPanel)
	HasAmount:SetText( "" )
	HasAmount.Paint = function(self, w, h)
		--draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)
		if LocalPlayer():GetItemAmount(item, nil, true) > 0 then
			draw.DrawText( "x"..LocalPlayer():GetItemAmount(item, nil, true), "SafeZone_INFO", w/2-5, h/2-20, Color(200,200,200,200), TEXT_ALIGN_RIGHT )
		end
	end
	HasAmount:SetSize(300,50)
	HasAmount:SetPos(CraftItemPanel:GetWide() - HasAmount:GetWide()/2, 5)

	DoCook2:SetFont("char_title20")
	DoCook2:SetText(buttontext2..buttonamount)
	DoCook2:SetSize(180,20)
	DoCook2:SetPos(100,70)
	DoCook2.DoClick = function()
		local cmd = "DecompileItem"
		if GAMEMODE.DayZ_Items[item].ReqCook then
			cmd = "StudyItem"
		end
		if CraftAmount:GetValue() > 1 then
			cmd = "Multi"..cmd
		end

		RunConsoleCommand(cmd, item, CraftAmount:GetValue() or 1)
	end


	DoCook:SetFont("char_title20")
	DoCook:SetText(buttontext..buttonamount)
	DoCook:SetSize(180,20)
	DoCook:SetPos(100,50)
	DoCook.DoClick = function()
		if !Local_BPTable[item] and !GAMEMODE.DayZ_Items[item].NoBlueprint then return end

		local cmd = "CraftItem"
		if GAMEMODE.DayZ_Items[item].ReqCook then
			cmd = "CookItem"
		end
		if CraftAmount:GetValue() > 1 then
			cmd = "Multi"..cmd
		end

		if IsValid(CraftItemPanel) and table.Count(CraftItemPanel.SelectedItems) == 0 then
			
			DoSelectItemsUI(item, cmd, CraftAmount:GetValue() or 1)
			return
		end

		RunConsoleCommand(cmd, item, CraftAmount:GetValue() or 1)
	end

	craftableItemModelPanel.Think = function()
		DoCook:SetEnabled( ( Local_BPTable[item] or GAMEMODE.DayZ_Items[item].NoBlueprint ) and !( GAMEMODE.DayZ_Items[item].CantCraft or GAMEMODE.DayZ_Items[item].CantCook ) )
		DoCook2:SetVisible( LocalPlayer():HasItem(item, true) )
		if GAMEMODE.DayZ_Items[item].ReqCook then
			DoCook2:SetVisible( LocalPlayer():HasItem(item, true) && !Local_BPTable[item] && !GAMEMODE.DayZ_Items[item].NoBlueprint )
		end
	end

	if !Local_BPTable[item] and !GAMEMODE.DayZ_Items[item].NoBlueprint and !( GAMEMODE.DayZ_Items[item].CantCraft or GAMEMODE.DayZ_Items[item].CantCook ) then DoCook:SetText("NEED BLUEPRINT!") return end

	if GAMEMODE.DayZ_Items[item].CantCraft or GAMEMODE.DayZ_Items[item].CantCook then DoCook:SetText("UNCRAFTABLE!") return end

	local reqItems = GAMEMODE.DayZ_Items[item].ReqCraft or GAMEMODE.DayZ_Items[item].ReqCook

	local margin = 5
	for k, v in SortedPairs(reqItems, true) do

		tbl2[item] = tbl2[item] or {}
		tbl2[item][v] = tbl2[item][v] or 0
		tbl2[item][v] = tbl2[item][v] + 1
					
		if !GAMEMODE.DayZ_Items[ v ] then continue end

		local panel, ItemModelPanel = DZ_MakeIcon( nil, v, 0, CraftItemPanel, nil, nil, 40, 40, false, true, false )
		panel:Dock(RIGHT)
		panel:DockMargin(0,52,margin,5)
		panel.rarity = 1
		margin = 0
		ItemModelPanel.ItemNum = tbl2[ item ][ v ]
		ItemModelPanel.NextThink = 0
		ItemModelPanel.Think = function(self)
			if ( self.NextThink or 0 ) > CurTime() then return end
			self.NextThink = CurTime() + 1

			if LocalPlayer():GetItemAmount(v, nil, true) < self.ItemNum then
				self:SetColor( Color(0,0,0,255) )
			else
				self:SetColor( GAMEMODE.DayZ_Items[ v ].Color or Color(255,255,255,255) )
			end

		end
		table.insert(CraftItemModelPanels, ItemModelPanel)

		ItemModelPanel.DoClick = function()
			CraftPanel.SelectedItemPanel = nil
			for k, v in pairs(CraftingModelPanels) do
				if v.itemclass == ItemModelPanel.itemclass then
					CraftPanel.SelectedItemPanel = v
				end
			end

			CraftPanelSetItem( v )
		end
		
	end	
end

local book_mat = Material("materials/icon16/page_find.png")
categoryCraftPanels = categoryCraftPanels or {}
function UpdateCraftInv( catUpdate )

	local CraftTable = CanCrafts
	local inventoryonly = false

	if !catUpdate then
		for k, v in pairs(CraftingModelPanels) do
			if IsValid(v) and IsValid(v:GetEntity()) then
				v:GetEntity():Remove() -- Because GC no worky on modelpanels!
			end
		end
	end

	if !IsValid(CraftPanel) then return end -- ran too early?

	local itemCategories = GAMEMODE.Util:GetItemCategories()
	if !catUpdate and IsValid(categoryCraftScroll) then categoryCraftScroll:Remove() end
	if !IsValid(categoryCraftScroll) then
		categoryCraftScroll = vgui.Create("DScrollPanel", CraftPanel)
		categoryCraftScroll:SetWide(CraftPanel:GetWide())
	    categoryCraftScroll:Dock(FILL)
	    categoryCraftScroll.Paint = function(self, w, h) end
	    categoryCraftScroll.Think = function(self)
	    	if ( self.NextThink or 0 ) > CurTime() then return end

	    	local children = self:GetCanvas():GetChildren()
	    	for k, child in pairs(children) do
	    		if !child:IsVisible() then
	    			child.Think(child, true) -- hacky way to bypass IsVisible disabling Think.
	    		end
	    	end

	    	self.NextThink = CurTime() + 0.2
	   	end

	   	local ScrollBar = categoryCraftScroll:GetVBar();

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
			
			categoryCraftPanels[category] = vgui.Create("DCollapsibleCategory", categoryCraftScroll)
	        categoryCraftPanels[category]:SetLabel("")
	        categoryCraftPanels[category]:SetWide( CraftPanel:GetWide() )
	        categoryCraftPanels[category]:Dock(TOP)
	        categoryCraftPanels[category]:DockMargin(0, 0, 0, 5)
	        categoryCraftPanels[category]:DockPadding(0, 0, 0, 5)

	        categoryCraftPanels[category].Paint = function(self, w, h)
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

	        categoryCraftPanels[category].List = vgui.Create("DIconLayout", categoryCraftPanels[category] )
	        categoryCraftPanels[category].List:SetPos(0, 25)
	    	categoryCraftPanels[category].List:SetSize( 725, 300)
	    	categoryCraftPanels[category].List:SetSpaceX(5)
	    	categoryCraftPanels[category].List:SetSpaceY(5)
	    	categoryCraftPanels[category].List:SetBorder(5)
			categoryCraftPanels[category].List.Paint = function(self, w, h)
	    		draw.RoundedBoxEx(0, 0, 0, w, h, Color(0, 0, 0, 70), true, true, true, true)
	    	end

	        categoryCraftPanels[category].Think = function(self, vis)
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

	if !catUpdate then

		for k, v in pairs(itemCategories) do
			if categoryCraftPanels[v] then
				categoryCraftPanels[v].List:Clear()
			end
		end
		--print("clearing and rebuilding all")
	else
		-- we just have the one category to update
		categoryCraftPanels[catUpdate].List:Clear()
		--print("clearing and rebuilding "..catUpdate)

	end

	local tbl2 = {}

	if table.Count(CraftTable) > 0 then

		--if table.Count(CraftPanel:GetChildren()) > 1 then return end

		for craftable, _ in SortedPairsByValue(CraftTable) do
		--for k, craftable in pairs(CraftTable) do 		
			local amount	
			local ItemTable = GAMEMODE.DayZ_Items[craftable]
			local itemCat = ItemTable.Category
			if !itemCat then itemCat = "none" end
			if catUpdate and itemCat != catUpdate then continue end

			local draw_tooltip = true
			if !Local_BPTable[ craftable ] and !GAMEMODE.DayZ_Items[craftable].NoBlueprint then
				draw_tooltip = false 
			end
			
			local craftableItemPanel, craftableItemModelPanel = DZ_MakeIcon( nil, craftable, 0, categoryCraftPanels[itemCat].List, nil, nil, 74, 74, false, true, false, nil, !draw_tooltip )
			if !craftableItemPanel then return end
			craftableItemPanel.rarity = 1
			
			if !Local_BPTable[ craftable ] and !GAMEMODE.DayZ_Items[craftable].NoBlueprint then
				--craftableItemModelPanel:SetModel("models/dayz/drinks/dayz_phoenixphuze.mdl")
			end

			craftableItemPanel:SetSize(74, 74)
			craftableItemPanel.Paint = function() end
			
			craftableItemModelPanel:SetSize(70,70)
			craftableItemModelPanel:SetPos(2,2)

			craftableItemModelPanel.Think = function(self)
				if ( self.NextThink or 0 ) > CurTime() then return end
				self.NextThink = CurTime() + 1

				if !Local_BPTable[ craftable ] and !GAMEMODE.DayZ_Items[craftable].NoBlueprint then
					//craftableItemModelPanel.SetModel("")
					self:RecomputeAngles(true)
					self:SetColor( Color(0,0,0,255) )
				else
					self:SetColor( GAMEMODE.DayZ_Items[ craftable ].Color or Color(255,255,255,255) )
				end

			end

			local PaintModel = craftableItemModelPanel.Paint
			
			local itemtype = string.upper( GAMEMODE.DayZ_Items[craftable].Name or "" )

			function craftableItemModelPanel:Paint(w, h)

				local bg_color
				if !Local_BPTable[ craftable ] and !GAMEMODE.DayZ_Items[craftable].NoBlueprint then
	            	bg_color = Color(200, 0, 0, 50)
	            	itemtype = "???"
	        	else
	        		bg_color = Color(0, 0, 0, 50)
	        	end

	        	if ( GAMEMODE.DayZ_Items[craftable].LevelReq or 0 ) > LocalPlayer():GetLevel() then
	        		bg_color = Color(200, 0, 0, 50)
	            	itemtype = "LEVEL "..GAMEMODE.DayZ_Items[craftable].LevelReq
	        	end

				draw.RoundedBoxEx(4,0,0,w,h,bg_color, true, true, true, true)

				--draw.RoundedBoxEx(4,1,1,w-2,h-2,Color( 255, 255, 255, 10 ), true, true, true, true) 
				
				local x2, y2 = CraftPanel:LocalToScreen( 0, 0 )
				local w2, h2 = CraftPanel:GetSize()
				render.SetScissorRect( x2, y2, x2 + w2, y2 + h2, true )

				PaintModel( self, w, h )
				
				render.SetScissorRect( 0, 0, 0, 0, false )

				if GAMEMODE.DayZ_Items[ craftable ].GivePer then
					draw.DrawText( "x"..GAMEMODE.DayZ_Items[ craftable ].GivePer, "Cyb_Inv_Label", w-5, h-17, Color(255,255,255,255), TEXT_ALIGN_RIGHT )
				end 

				local sizex, _ = surface.GetTextSize( itemtype )
				if sizex > 70 then
					itemtype = string.sub(itemtype, 1, 8)
					itemtype = string.TrimRight( itemtype, " " )
					itemtype = itemtype.."..."
				end

	        	draw.RoundedBox(2, 0, h - 18, w, (h / 4 )+ 2, Color(0, 0, 0, 150))

            	draw.DrawText(itemtype, "Cyb_Inv_Label", w / 2, h - 15, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER)

				if CraftPanel.SelectedItemPanel == self then
					local color = Color(255, 200, 50, 255)

					draw.RoundedBox(0,0,0,w,2,color) -- Top
					draw.RoundedBox(0,0,68,w,2,color) -- Bottom
					draw.RoundedBox(0,0,0,2,h,color) -- Left
					draw.RoundedBox(0,68,0,2,h,color) -- Right
				end

	        	if GAMEMODE.DayZ_Items[craftable].NoBlueprint then
	        		surface.SetMaterial(book_mat)
	        		surface.SetDrawColor( Color(255, 255, 255, 50) )
	        		surface.DrawTexturedRect( w - 21, 5, 16, 16 )

	        	end


			end
			
			craftableItemModelPanel.DoClick = function()
				CraftPanel.SelectedItemPanel = craftableItemModelPanel

				CraftPanelSetItem( craftable )
			end
			table.insert(CraftingModelPanels, craftableItemModelPanel)
						
			categoryCraftPanels[itemCat].List:Add(craftableItemPanel)
			categoryCraftPanels[itemCat].List:InvalidateLayout()
		
		end
	end
end	


DayZ_AddMenuTab( { order = 4, name = "Crafting", type = "DPanel", icon = "cyb_mat/cyb_crafting.png", desc = "Craft new weapons, ammo and more", func = GUI_Rebuild_Crafting } )
