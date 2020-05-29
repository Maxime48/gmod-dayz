Local_TradeTable = Local_TradeTable or {}
Other_TradeTable = Other_TradeTable or {}
OtherConfirmed = false

local InvitePanel
local Col = {
	Border = Color(20,20,20, 150), Main = Color(100,100,100, 100),
	
	Text = Color(255,255,255), TextShadow = Color(0,0,0),
	
	Accept = Color(150,255,150), Decline = Color(255,150,150),
}
net.Receive( "net_tradeInvite", function()
	local othernick = net.ReadString()	
	local inviteTime = net.ReadFloat()
	local ply = LocalPlayer()

	if !inviteTime or !othernick then return end

	surface.PlaySound("friends/message.wav")

	timer.Create("invite_soundspam", 1, 0, function()
		if !IsValid(InvitePanel) then timer.Destroy("invite_soundspam") return end
		surface.PlaySound("friends/message.wav")
	end)
	
	if IsValid(InvitePanel) then return end
	InvitePanel = vgui.Create( "DPanel" )
	InvitePanel:SetSize( 300, 100 )
	InvitePanel.nick = othernick
	InvitePanel:SetPos( (ScrW()/2)-150, ScrH()-225 )
	InvitePanel.Paint = function( s, w,h )
		local glow = math.abs(math.sin(CurTime() * 2) * 255); 

		surface.SetDrawColor( Color(glow, 10, 10, 255) )

		surface.DrawRect( 0,0, 2,h )
		surface.DrawRect( w-2,0, 2,h )
		surface.DrawRect( 2,0, w-4,2 )
		surface.DrawRect( 2,h-2, w-4,2 )
		
		surface.SetDrawColor( Col.Main )
		surface.DrawRect( 2,2, w-4,h-4 )
		
		draw.SimpleText( "You have been invited to trade with", "DayZGroupsFontSmall", (w/2)+1, 16, Col.TextShadow, TEXT_ALIGN_CENTER )
		draw.SimpleText( "You have been invited to trade with", "DayZGroupsFontSmall", w/2, 15, Col.Text, TEXT_ALIGN_CENTER )
		
		draw.SimpleText( s.nick, "DayZGroupsFont", (w/2)+1, 41, Col.TextShadow, TEXT_ALIGN_CENTER )
		draw.SimpleText( s.nick, "DayZGroupsFont", w/2, 40, team.GetColor(tm), TEXT_ALIGN_CENTER )
		
		local str = string.format( "%s to accept", (input.LookupBinding("gm_showhelp") or "[ShowHelp") )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)-4, 71, Col.TextShadow, TEXT_ALIGN_RIGHT )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)-5, 70, Col.Accept, TEXT_ALIGN_RIGHT )
		
		local str = string.format( "%s to decline", (input.LookupBinding("gm_showteam") or "[ShowTeam") )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)+6, 71, Col.TextShadow, TEXT_ALIGN_LEFT )
		draw.SimpleText( str, "DayZGroupsFontSmall", (w/2)+5, 70, Col.Decline, TEXT_ALIGN_LEFT )
	end
	
	hook.Add( "PlayerBindPress", InvitePanel, function(self,ply,bind,pressed)
		if not IsValid(self) then return end
		
		if bind=="gm_showhelp" and pressed then
			net.Start("net_tradeInvite")
				net.WriteBool(true)
			net.SendToServer()
			
			self:Remove()
			return true
		elseif bind=="gm_showteam" and pressed then
			net.Start("net_tradeInvite")
				net.WriteBool(false)
			net.SendToServer()

			self:Remove()
			return true
		end
	end)
	
	local pnl = InvitePanel
	timer.Simple( math.min(math.abs(inviteTime-CurTime()), 30), function()
		if IsValid(pnl) then pnl:Remove() end
	end)
end)

net.Receive("UpdateTrade", function(len)
	local item = net.ReadTable()
    local loc = net.ReadBool()
    if !loc then
    	Local_TradeTable[item.class][item.id] = item
    	UpdateTradeUI("loc")
    else
    	Other_TradeTable[item.class][item.id] = item
    	UpdateTradeUI("ext")
    end
  	OtherConfirmed = false
end)

net.Receive("UpdateTradeFull", function(len)
    local tab = net.ReadTable()
    local loc = net.ReadBool()
    if !loc then
    	Local_TradeTable = tab
    	UpdateTradeUI("loc")
    else
    	Other_TradeTable = tab
    	UpdateTradeUI("ext")
    end
    OtherConfirmed = false
end)

OtherPlayer = OtherPlayer or nil
net.Receive("net_tradeMenu", function(len)
	local bool = net.ReadBool()
	OtherPlayer = net.ReadEntity() or nil
	if !bool then
    	GUI_Trade_Menu()
    else
		if IsValid(GUI_Trade_Frame) then
			GUI_Trade_Frame:Remove()
		end
    end
end)

net.Receive("net_tradeConfirm", function(len)
	local bool = net.ReadBool()
	OtherConfirmed = true
end)

function GUI_Trade_Menu()
	if IsValid(GUI_Trade_Frame) then
		GUI_Trade_Frame:Remove()
	end

	GUI_Trade_Frame = vgui.Create("DPanel")
	GUI_Trade_Frame:SetSize(800,600)
	GUI_Trade_Frame:MakePopup()
	GUI_Trade_Frame:Center()	
	GUI_Trade_Frame.Paint = function(self, w, h)
		local othernick = ""
		if IsValid(OtherPlayer) then othernick = OtherPlayer:Nick() end
		draw.RoundedBox(0,0,0,w,h,Color( 60, 60, 60, 255 )) 
		draw.DrawText( "Trading with "..othernick, "char_title36", 45, 0, Color(200,200,200), TEXT_ALIGN_LEFT )
	end

	if !IsValid(GUI_Trade_Frame.icon) then
		GUI_Trade_Frame.icon = vgui.Create( "DImage", GUI_Trade_Frame )
		GUI_Trade_Frame.icon:SetImage( "cyb_mat/cyb_profit.png" )
		GUI_Trade_Frame.icon:SetPos(5, 5)
		GUI_Trade_Frame.icon:SetSize( 32, 32 )
		GUI_Trade_Frame.icon:SetImageColor(Color(255,255,255,200))
	end

	OtherConfirmed = false

	local CBut = vgui.Create("DButton", GUI_Trade_Frame)
	CBut:SetColor(Color(200,200,200,255))
	CBut:SetFont("Cyb_Inv_Bar")
	CBut:SetText("X")
	CBut.Paint = function() end
	CBut:SetSize(32,32)
	CBut:SetPos(CBut:GetParent():GetWide()-CBut:GetWide()-5, 5)
	CBut.DoClick = function() if GUI_Trade_Frame:IsValid() then RunConsoleCommand("Canceltrade") GUI_Trade_Frame:Remove() RemoveOpenedMenus() end end

	tradeConfirm = vgui.Create("DPanel", GUI_Trade_Frame)
	tradeConfirm:Dock(TOP)
	tradeConfirm:DockMargin(5,40,5,0)
	tradeConfirm:SetTall(60)
	tradeConfirm.Paint = function(self, w, h)
		draw.RoundedBox(0,0,0,w,h,Color( 100, 100, 100, 200 )) 
	end

	tradeConfirm.confirm = vgui.Create("DButton", tradeConfirm)
	tradeConfirm.confirm.Paint = function(self, w, h) 
		if !self:GetDisabled() then 
			draw.RoundedBox(4,2,2,w-4,h-4,Color(172, 41, 37, 200))
			draw.DrawText( "Accept", "SafeZone_INFO", w/2, 10, Color(200,200,200,200), TEXT_ALIGN_CENTER )
		else
			draw.RoundedBox(4,2,2,w-4,h-4,Color(41, 172, 37, 200))
			draw.DrawText( "Accepted", "SafeZone_INFO", w/2, 10, Color(200,200,200,200), TEXT_ALIGN_CENTER )
		end
	end
	tradeConfirm.confirm:SetFont("SafeZone_INFO")
	tradeConfirm.confirm:SetText("")
	tradeConfirm.confirm:Dock(LEFT)
	tradeConfirm.confirm:SetWide(200)
	tradeConfirm.confirm.DoClick = function(self)
		self:SetEnabled( false )

		RunConsoleCommand("confirmtrade")
	end

	tradeConfirm.other = vgui.Create("DPanel", tradeConfirm)
	tradeConfirm.other.Paint = function(self, w, h) 
		if OtherConfirmed then 
			draw.RoundedBox(4,2,2,w-4,h-4,Color(41, 172, 37, 200))
			draw.DrawText( "Accepted", "SafeZone_INFO", w/2, 10, Color(200,200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			draw.RoundedBox(4,2,2,w-4,h-4,Color(172, 41, 37, 200))
			draw.DrawText( "Accept waiting", "SafeZone_INFO", w/2, 10, Color(200,200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end
	tradeConfirm.other:Dock(RIGHT)
	tradeConfirm.other:SetWide(200)

	LocalInvPanel = vgui.Create("DPanelList", GUI_Trade_Frame)
	LocalInvPanel:SetTall(200)
	LocalInvPanel:Dock(BOTTOM)
	LocalInvPanel:DockMargin(5,5,5,5)
	LocalInvPanel.Paint = function(self, w, h)
		draw.RoundedBox(2,0,0,w,h,Color( 30, 30, 30, 200 ))
	end
	LocalInvPanel:SetPadding(7.5)
	LocalInvPanel:SetSpacing(2)
	LocalInvPanel:EnableHorizontal(3)
	LocalInvPanel:EnableVerticalScrollbar(true)

	MyOfferPanel = vgui.Create("DPanelList", GUI_Trade_Frame)
	MyOfferPanel:Dock(LEFT)
	MyOfferPanel:DockMargin(5,5,5,0)
	MyOfferPanel:SetWide(GUI_Trade_Frame:GetWide()/2 - 8)
	MyOfferPanel:SetPadding(7.5)
    MyOfferPanel:SetSpacing(2)
    MyOfferPanel:EnableHorizontal(3)
    MyOfferPanel:EnableVerticalScrollbar(true)
	MyOfferPanel.Paint = function(self, w, h)
		draw.RoundedBox(2,0,0,w,h,Color( 50, 50, 50, 200 ))
	end

	TheirOfferPanel = vgui.Create("DPanelList", GUI_Trade_Frame)
	TheirOfferPanel:Dock(RIGHT)
	TheirOfferPanel:DockMargin(5,5,5,0)
	TheirOfferPanel:SetWide(GUI_Trade_Frame:GetWide()/2 - 8)
	TheirOfferPanel:SetPadding(7.5)
    TheirOfferPanel:SetSpacing(2)
    TheirOfferPanel:EnableHorizontal(3)
    TheirOfferPanel:EnableVerticalScrollbar(true)
	TheirOfferPanel.Paint = function(self, w, h)
		draw.RoundedBox(2,0,0,w,h,Color( 50, 50, 50, 200 ))
	end

	UpdateTradeUI()
end

LocalInvPanelModels = LocalInvPanelModels or {}
MyOfferPanelModels = MyOfferPanelModels or {}
TheirOfferPanelModels = TheirOfferPanelModels or {}

function UpdateTradeUI(value)

	if !value then
		Local_TradeTable = {}
		Other_TradeTable = {}
	end

	if IsValid(tradeConfirm.confirm) then
		tradeConfirm.confirm:SetEnabled(true)
	end

	if !value or value == "loc" then
		if IsValid(MyOfferPanel) then
			MyOfferPanel:Clear()
			for k, v in pairs(MyOfferPanelModels) do
				if IsValid(v) and IsValid(v:GetEntity()) then
					v:GetEntity():Remove() -- Because GC no worky on modelpanels!
				end
			end
		end

		for _, ItemTable in ipairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
			local item = ItemTable.ID
			if !Local_TradeTable[item] then continue end

			for _, it in pairs(Local_TradeTable[item]) do
				if it.amount > 0 then

					local panel, modelpanel = DZ_MakeIcon( it.id, item, it.amount, MyOfferPanel, nil, "myofferslot", 63, 63, false, true )
					panel.rarity = it.rarity or 1

					modelpanel.DoClick = function()
						RunConsoleCommand("Cancelofferitem",it.id)
						return
					end

					MyOfferPanel:AddItem(panel)
					table.insert(MyOfferPanelModels, modelpanel)
					
				end
			end
			
		end

	end

	if !value or value == "ext" then
		if IsValid(TheirOfferPanel) then 
			TheirOfferPanel:Clear() 
			for k, v in pairs(TheirOfferPanelModels) do
				if IsValid(v) and IsValid(v:GetEntity()) then
					v:GetEntity():Remove() -- Because GC no worky on modelpanels!
				end
			end
		end

		for _, ItemTable in ipairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
			local item = ItemTable.ID
			if !Other_TradeTable[item] then continue end
			for _, it in pairs(Other_TradeTable[item]) do

				if it.amount > 0 then

					local panel, modelpanel = DZ_MakeIcon( it.id, item, it.amount, TheirOfferPanel, nil, "myofferslot", 63, 63, false, true )
					panel.rarity = it.rarity or 1
					
					TheirOfferPanel:AddItem(panel)
					table.insert(TheirOfferPanelModels, modelpanel)
					
				end

			end
		end

	end

	if !value or value == "inv" then
		
		if IsValid(LocalInvPanel) then 
			LocalInvPanel:Clear() 
			for k, v in pairs(LocalInvPanelModels) do
				if IsValid(v) and IsValid(v:GetEntity()) then
					v:GetEntity():Remove() -- Because GC no worky on modelpanels!
				end
			end
		end

		for _, ItemTable in ipairs( GAMEMODE.Util:ItemsSortByVal("Name") ) do
			local item = ItemTable.ID
			if !Local_Inventory[item] then continue end

			for _, it in pairs(Local_Inventory[item]) do
			
				if it.amount > 0 then

					local panel, modelpanel = DZ_MakeIcon( it.id, item, it.amount, LocalInvPanel, nil, "invslot", 63, 63, false, true )
					panel.rarity = it.rarity or 1
					modelpanel.DoClick = function()
						RunConsoleCommand("Tradeofferitem",it.id)
						return
					end

					modelpanel.DoRightClick = function()
						ItemMENU = DermaMenu()
							
						local amts = {1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000, 1000000}
            			if !table.HasValue(amts, it.amount) then table.insert(amts, it.amount) end
						for k, v in ipairs(amts) do
							if it.amount < v then continue end
							local panel = ItemMENU:AddOption("Offer "..v, 	function()
								RunConsoleCommand("Tradeofferitem", it.id, v)
							end )
							panel.Paint = PaintItemMenus
						end

						if it.amount > 1 then
							local panel = ItemMENU:AddOption("Offer X", function()
								GUI_Amount_Popup(it.id, "Tradeofferitem")
							end)
							panel.Paint = PaintItemMenus
						end
						
						ItemMENU:Open( gui.MousePos() )	
					end

					LocalInvPanel:AddItem(panel)
					table.insert(LocalInvPanelModels, modelpanel)
					
				end

			end
		end

	end

end
