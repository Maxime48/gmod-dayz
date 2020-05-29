function GM:HUDDrawPickupHistory( )
end

function dragndrop.Drop() -- an edit, because meta tables suck.

	if ( dragndrop.HandleDroppedInGame() ) then
		dragndrop.StopDragging()
		return
	end

	local draggedPanel = dragndrop.m_DraggingMain

	-- Show the menu
	if ( dragndrop.m_MouseCode == MOUSE_RIGHT && dragndrop.m_ReceiverSlot && dragndrop.m_ReceiverSlot.Menu ) then

		local x, y = dragndrop.m_Receiver:LocalCursorPos()

		local menu = DermaMenu()
		menu.OnRemove = function( m ) -- If user clicks outside of the menu - drop the dragging
			dragndrop.StopDragging()
		end

		for k, v in pairs( dragndrop.m_ReceiverSlot.Menu ) do

			menu:AddOption( v, function()

				dragndrop.CallReceiverFunction( true, k, x, y )
				dragndrop.StopDragging()

			end )

		end

		menu:Open()

		dragndrop.m_DropMenu = menu

		return

	end

	dragndrop.CallReceiverFunction( true, nil, nil, nil )
	dragndrop.StopDragging()

	local panel = vgui.GetHoveredPanel()
	if IsValid(panel) then
		if panel:GetClassName() == "CGModBase" then -- if you dropped it on nothing;
			if draggedPanel.hotbar then
				local slot = draggedPanel.slot
				Local_HotBar[slot] = {} -- wiped
			else
				RunConsoleCommand("DropItem", draggedPanel.ItemID)
			end

		end
	end
end