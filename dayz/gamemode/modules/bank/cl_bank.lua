local vgui = vgui
local draw = draw
local surface = surface
local gradient = Material("gui/gradient")

Local_Bank = Local_Bank or {}

net.Receive("UpdateBankFull", function(len)
	local i = net.ReadString()
	local items = net.ReadTable()

	Local_Bank = Local_Bank or {}
	local class -- since this function only runs on each class, it's safe to assume it will be the same.

	for k, v in pairs(items) do
		class = v.class
		Local_Bank[v.class] = Local_Bank[v.class] or {}

		Local_Bank[v.class][v.id] = v
	end
	
	local cat = "none"
	if GAMEMODE.DayZ_Items[class] && GAMEMODE.DayZ_Items[class].Category then
		cat = GAMEMODE.DayZ_Items[class].Category
	end

	if isfunction(UpdateBank) then UpdateBank(cat, true) end
end)

net.Receive("UpdateBank", function(len)
	local item = net.ReadTable()
	local del = net.ReadBool()


	--print("Calling UpdateBank ", del)
	Local_Bank[item.class] = Local_Bank[item.class] or {}
	if !del then
		Local_Bank[item.class][item.id] = item
	else
		--print("removed item ", item.class)
		Local_Bank[item.class][item.id] = nil
	end

	local cat = "none"
	if GAMEMODE.DayZ_Items[item.class] && GAMEMODE.DayZ_Items[item.class].Category then
		cat = GAMEMODE.DayZ_Items[item.class].Category
	end

	if isfunction(UpdateBank) then UpdateBank(cat, true) end	
end)

net.Receive("UpdateBankWeight", function(len)
	TotalBankWeight = math.Round(net.ReadFloat(), 1)
end)

function GUI_Bank_Menu(parent)
	if !IsValid(parent) then 
		return
	end

	GUI_Bank_Inv_Weight_Panel = vgui.Create("DPanel", parent)
	GUI_Bank_Inv_Weight_Panel:Dock(BOTTOM)
	GUI_Bank_Inv_Weight_Panel:SetTall(25)
	GUI_Bank_Inv_Weight_Panel:DockMargin(5, 5, 5, 0)
	GUI_Bank_Inv_Weight_Panel.Paint = function() end
		
	GUI_BankInv_Panel_List = vgui.Create("DPanelList", parent)
	GUI_BankInv_Panel_List:SetWide(342)
	GUI_BankInv_Panel_List:Dock(LEFT)
	GUI_BankInv_Panel_List:DockMargin(5,0,0,5)
	--GUI_BankInv_Panel_List:DockMargin(20,0,5,50)
	
	--GUI_BankInv_Panel_List:SetSize(350, parent:GetTall()-40)
	GUI_BankInv_Panel_List.Paint = function(self, w, h)
		--draw.RoundedBox(0,0,0,w,h,Color( 30, 30, 30, 100 ))
	end
	GUI_BankInv_Panel_List:Receiver( "bankslot", function( pnl, tbl, dropped, menu, x, y )
    	if ( !dropped ) then return end
		if tbl[1]:GetParent() == GUI_BankInv_Panel_List then return end

		--tbl[1]:SetSize(60,60)
		--tbl[1]:GetChild(1):SetSize(50,50)

		--GUI_BankInv_Panel_List:AddItem(tbl[1])
		RunConsoleCommand("WithdrawItem", tbl[1].ItemID, (tbl[1].Amount or 1))
    end )
	
	GUI_BankInv_Panel_List:SetPadding(7.5)
	GUI_BankInv_Panel_List:SetSpacing(2)
	GUI_BankInv_Panel_List:EnableHorizontal(3)
	GUI_BankInv_Panel_List:EnableVerticalScrollbar(true)
	
	GUI_Bank_Inv_Weight_Bar = vgui.Create("DPanel", GUI_Bank_Inv_Weight_Panel)
	GUI_Bank_Inv_Weight_Bar:SetSize(342,25)
	GUI_Bank_Inv_Weight_Bar:SetPos( 0, 0 )

	
	local weight_smooth = 0
	GUI_Bank_Inv_Weight_Bar.Paint = function(self, w, h)
		local maxweight = LocalPlayer():GetWeightMax()

		if TotalWeight then
            draw.RoundedBoxEx(0, 0, 0, w, h, Color(40, 40, 40, 255), true, true, true, true)

            local per = (TotalWeight / maxweight)
            local wei = w * per

            weight_smooth = math.Approach( weight_smooth, wei, 80 * FrameTime() )
            local perc = weight_smooth / w * 100          

            if w * (TotalWeight / maxweight) > 0 then

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
            draw.DrawText(TotalWeight .. "/" .. maxweight, "char_title16", w - 5, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT)
		end
	end

	GUI_Bank_Panel_List = vgui.Create("DPanelList", parent)
	GUI_Bank_Panel_List:Dock(FILL)
	GUI_Bank_Panel_List:DockMargin(5,0,5,5)

	GUI_Bank_Panel_List.Paint = function(self, w, h)
		--draw.RoundedBox(0,0,0,w,h,Color( 30, 30, 30, 100 ))
	end
	GUI_Bank_Panel_List:SetPadding(7.5)
	GUI_Bank_Panel_List:SetSpacing(2)
	GUI_Bank_Panel_List:EnableHorizontal(3)
	GUI_Bank_Panel_List:EnableVerticalScrollbar(true)	
	GUI_Bank_Panel_List:Receiver( "bankslot", function( pnl, tbl, dropped, menu, x, y )
    	if ( !dropped ) then return end
		if tbl[1]:GetParent() == GUI_Bank_Panel_List then return end

		--tbl[1]:SetSize(60,60)
		--tbl[1]:GetChild(1):SetSize(50,50)

		--GUI_Bank_Panel_List:AddItem(tbl[1])
		RunConsoleCommand("DepositItem", tbl[1].ItemID, (tbl[1].Amount or 1))
    end )

	local ScrollBar = GUI_Bank_Panel_List.VBar
   	PaintVBar( ScrollBar )

	GUI_Bank_Weight_Bar = vgui.Create("DPanel", GUI_Bank_Inv_Weight_Panel)
	GUI_Bank_Weight_Bar:SetSize(395,25)
	GUI_Bank_Weight_Bar:SetPos(347, 0)
	--GUI_Bank_Weight_Bar:Dock(RIGHT)
	--GUI_Bank_Weight_Bar:DockMargin(0,0,0,20)
	local weight_smooth2 = 0
	GUI_Bank_Weight_Bar.Paint = function(self, w, h)
		if TotalBankWeight then
			local MaxBankWeight = PHDayZ.BankMaxWeight[LocalPlayer():GetHelperUserGroup()] or PHDayZ.DefaultBankWeight
			local total = TotalBankWeight/(MaxBankWeight+LocalPlayer():GetNWInt("extraslots"))

            local wei = w * total

            weight_smooth2 = math.Approach( weight_smooth2, wei, 80 * FrameTime() )
            local perc = weight_smooth2 / w * 100

			draw.RoundedBoxEx(0, 0, 0, w, h, Color(40, 40, 40, 255), true, true, true, true)

            if wei > 0 then
            	local col = Color(0,0,0,0)

                if perc < 50 then
                    col = Color(0,200,0,100)
                elseif perc >= 50 and perc < 80 then
                    col = Color(200,200,0,100)
                elseif perc >= 80 then 
                    col = Color(200,0,0,100)
                end
                draw.RoundedBoxEx(0, 1, 1, weight_smooth2, h - 2, col, true, true, false, false)

                draw.RoundedBoxEx(0, 1, 1, weight_smooth2, h - 2, Color(60, 60, 60, 200), true, true, false, false)
            end

            draw.DrawText(LANG.GetTranslation("bankweight"), "char_title16", 5, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT)
            local text = TotalBankWeight.."/"..(MaxBankWeight+LocalPlayer():GetNWInt("extraslots"))
            surface.SetFont("char_title16")
            local x, y = surface.GetTextSize(text)
            draw.DrawText(text, "char_title16", w - 8, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT)
            draw.DrawText(formatCash(TotalBankWorth), "char_title16", w - ( 13 + x ), h - 20, Color(200, 200, 0, 255), TEXT_ALIGN_RIGHT)
		end
	end

	----------------------------------

	if isfunction(UpdateBank) then UpdateBank(nil, true) end
end
--net.Receive( "net_BankMenu", GUI_Bank_Menu );

function GUI_Amount_Popup(item, command)
	if GUI_Amount_Frame != nil && GUI_Amount_Frame:IsValid() then GUI_Amount_Frame:Remove() end
	GUI_Amount_Frame = vgui.Create("DFrame")
	GUI_Amount_Frame:SetSize(200,100)
	GUI_Amount_Frame:Center()
	GUI_Amount_Frame:MakePopup()
	GUI_Amount_Frame:SetTitle("How Many?")
	GUI_Amount_Frame:ShowCloseButton(true)
	GUI_Amount_Frame.btnMaxim:Hide()
	GUI_Amount_Frame.btnMinim:Hide()
	GUI_Amount_Frame:SetDrawOnTop(true)
	GUI_Amount_Frame.Paint = function(self, w, h)
		draw.RoundedBoxEx( 6, 0, 0, w, h, Color(100, 100, 100, 255), true, true, true, true )
	end
	local GUI_Amount_slider = vgui.Create("DNumSlider", GUI_Amount_Frame)

	local max = LocalPlayer():GetItemAmount(item)
	if command == "WithdrawItem" then
		max = LocalPlayer():GetItemAmount(item, true)
	end

	GUI_Amount_slider:SetWide(270)
	GUI_Amount_slider:SetPos(-80,25)
	GUI_Amount_slider:SetText("")
	GUI_Amount_slider:SetDecimals(0)
	GUI_Amount_slider:SetMin(1)
	GUI_Amount_slider:SetMax( max )
	
	GUI_Amount_slider:SetValue(1)	
	
	local GUI_Drop_Button = vgui.Create("DButton", GUI_Amount_Frame)
	GUI_Drop_Button:SetPos(10,70)
	GUI_Drop_Button:SetSize(180,15)
	GUI_Drop_Button:SetText("")
	GUI_Drop_Button.Paint = function(self, w, h)
		draw.RoundedBox(4,0,0,w,h,Color( 0, 0, 0, 255 ))
		draw.RoundedBox(4,1,1,w-2,h-2,Color( 139, 133, 97, 55))
						
		local struc = {}
		struc.pos = {}
		struc.pos[1] = 90 -- x pos
		struc.pos[2] = 7 -- y pos
		struc.color = Color(255,255,255,255) -- Red
		struc.text = "Confirm" -- Text
		struc.xalign = TEXT_ALIGN_CENTER-- Horizontal Alignment
		struc.yalign = TEXT_ALIGN_CENTER -- Vertical Alignment
		draw.Text( struc )
	end
										
	GUI_Drop_Button.DoClick = function()
		RunConsoleCommand( command, item, math.Round( GUI_Amount_slider:GetValue() ) )
		GUI_Amount_Frame:Remove()
	end
end