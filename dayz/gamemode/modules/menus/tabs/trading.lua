local PlayerObjectModels = {}
local nextUpdate = 0
TFrame = TFrame or {}
local player_panels = {}
function UpdateTrade()
	local parent = GUI_Trade_Panel_List
	if !IsValid(parent) then return end
	
	local size = 365

	if !IsValid( TFrame[1] ) then
		TFrame[1] = vgui.Create("DScrollPanel", parent)
		TFrame[1]:SetWide( size )

		TFrame[1].Think = function(self)
			if ( nextUpdate or 0 ) > CurTime() then return end

			nextUpdate = CurTime() + 1
			UpdateTrade()
		end

		PaintVBar( TFrame[1]:GetVBar() )

		TFrame[1]:Dock(LEFT)
		TFrame[1]:DockMargin(5,0,5,0)
		TFrame[1].Paint = paint_bg
	end

	if !IsValid(TFrame[2]) then
		TFrame[2] = vgui.Create("DScrollPanel", parent)
		TFrame[2]:SetWide( size )

		PaintVBar( TFrame[2]:GetVBar() )

		TFrame[2]:Dock(RIGHT)
		TFrame[2]:DockMargin(5,0,5,0)
		TFrame[2].Paint = paint_bg
	end

	timer.Simple(0, function()

		local i = 2
		for k, v in pairs( player.GetAll() ) do
			if LocalPlayer() == v then continue end -- we don't want to trade with ourselves!
			if LocalPlayer():GetPos():DistToSqr(v:GetPos()) > ( 400 * 400 ) then if IsValid( player_panels[ v:EntIndex() ] ) then player_panels[ v:EntIndex() ]:Remove() end continue end
			
			if IsValid( player_panels[ v:EntIndex() ] ) then continue end 
			
			if i == 1 then i = 2 elseif i == 2 then i = 1 end

			local PlayerPanel = vgui.Create("DPanel", TFrame[i])
			PlayerPanel:Dock(TOP)
			PlayerPanel.ply = v
			PlayerPanel:SetTall(80)
			PlayerPanel.Paint = function(self, w, h)
				paint_bg(self, w, h)

				if !IsValid(self.ply) then self:Remove() return end

				draw.DrawText(self.ply:Nick(), "char_title24", 100, 20, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT)	
			end
			PlayerPanel:DockMargin(0,0,0,5)

			player_panels[ v:EntIndex() ] = PlayerPanel

			local modelpanel = vgui.Create("DModelPanel", PlayerPanel)
		    modelpanel.ply = v
		    modelpanel:SetPos(5, 5)
		    modelpanel:SetSize(75, 75)
		    table.insert(PlayerObjectModels, modelpanel)
		    local PaintModel = modelpanel.Paint

		    function modelpanel:DrawModel()
		        local curparent = self
		        local rightx = self:GetWide()
		        local leftx = 0
		        local topy = 0
		        local bottomy = self:GetTall()
		        local previous = curparent

		        while (curparent:GetParent() ~= nil) do
		            curparent = curparent:GetParent()
		            local x, y = previous:GetPos()
		            topy = math.Max(y, topy + y)
		            leftx = math.Max(x, leftx + x)
		            bottomy = math.Min(y + previous:GetTall(), bottomy + y)
		            rightx = math.Min(x + previous:GetWide(), rightx + x)
		            previous = curparent
		        end

		        if self:GetParent():IsDragging() then
		            self.Entity:DrawModel()
		        else
		            render.SetScissorRect(leftx, topy, rightx, bottomy, true)
		            self.Entity:DrawModel()
		            render.SetScissorRect(0, 0, 0, 0, false)
		        end
		    end

		    modelpanel:SetDrawOnTop(false)

		    modelpanel.LayoutEntity = function() end

		    function modelpanel:Paint(w, h)
		        local x2, y2 = self:GetParent():LocalToScreen(0, 0)
		        local w2, h2 = self:GetParent():GetSize()
		        render.SetScissorRect(x2, y2, x2 + w2, y2 + h2, true)
		        PaintModel(self, w, h)
		        render.SetScissorRect(0, 0, 0, 0, false)
		    end

		    modelpanel:SetModel( ply:GetModel() )
		    modelpanel.Think = function(self)
		    	if ( self.nextThink or 0 ) > CurTime() then return end
		    	self.nextThink = CurTime() + 1
		    	if !IsValid(self.ply) then return end

		    	self:GetEntity():SetModel( self.ply:GetModel() )
		    	self:GetEntity():SetSkin( self.ply:GetSkin() )
		   	end
		    if not IsValid( modelpanel:GetEntity() ) then return end

		    modelpanel:GetEntity():SetMaterial( ply:GetMaterial() )
		    modelpanel:GetEntity():SetSkin( ply:GetSkin() )

			modelpanel:GetEntity():SetBodyGroups( ply:GetBodyGroups() )

		    local eyepos = modelpanel:GetEntity():GetBonePosition( modelpanel:GetEntity():LookupBone( "ValveBiped.Bip01_Head1" ) )
		    eyepos:Add( Vector( 0, 0, 2 ) )	-- Move up slightly
			modelpanel:SetLookAt( eyepos )
			modelpanel:SetCamPos( eyepos-Vector( -15, 0, 0 ) )	-- Move cam in front of eyes
			modelpanel:GetEntity():SetEyeTarget( eyepos-Vector( -15, 0, 0 ) )

		    modelpanel:SetColor( Color(255, 255, 255, 255) )


			PlayerPanel.Trade = vgui.Create("DButton", PlayerPanel)
			PlayerPanel.Trade:Dock(RIGHT)
			PlayerPanel.Trade:DockMargin(2,2,2,2)
			PlayerPanel.Trade:SetWide(76)
			PlayerPanel.Trade:SetText("Trade")
			PlayerPanel.Trade.Paint = PaintButtons

			PlayerPanel.Trade.DoClick = function()
				RunConsoleCommand("starttrade", v:Nick())
			end

		end
	end)
end

function GUI_Rebuild_Trade(parent)
	GUI_Trade_Panel_List = parent
	TFrame = {}
	UpdateTrade(GUI_Trade_Panel_List)
end

DayZ_AddMenuTab( { order = 3, name = "Trading", type = "DPanel", icon = "cyb_mat/cyb_perks.png", desc = "Trade with others nearby, securely.", func = GUI_Rebuild_Trade } )
