CyBConcept = {}

CyBConcept.barBg = Color( 0, 0, 0, 150 ) -- The background color of the tab bar.

CyBConcept.panelBg = Color( 0, 0, 0, 200 ) -- The background color of the panel.

CyBConcept.descPanelBg = Color( 16, 95, 125, 0 ) -- Unused.

CyBConcept.iconHighlight = Color( 255, 255, 255, 200 ) -- The icon for the selected tab.

CyBConcept.iconNormal = Color( 150, 150, 150, 200 ) -- The normal color of each icon.

CyBConcept.iconpanelBg = Color( 0, 0, 0, 100 ) -- The background color of the selected tab.

CyBConcept.iconBg = Color( 0, 0, 0, 100 ) -- The rounded background color of the icon.

CyBConcept.iconButtonBg = Color( 0, 0, 0, 0 ) -- The button's background.

local PANEL = {}
AccessorFunc( PANEL, "m_iconSize", "IconSize" )

function PANEL:Init( )
	self:SetIconSize( 32 )
	self.seperatorWidth = 0
	self.tabBarWidth = 40
	
	self.tabsContainer = vgui.Create( "DPanel", self )
	self.tabsContainer:Dock( RIGHT )
	self.tabsContainer:DockMargin(0,0,0,0)
	self.tabsContainer:SetZPos( 2 )
	function self.tabsContainer.PerformLayout( )
		self.tabsContainer:SetWide( self.tabBarWidth )
	end
	function self.tabsContainer:Paint( w, h )
	end
		
	self.tabs = vgui.Create( "DIconLayout", self.tabsContainer )
	self.tabs:Dock( FILL )
	function self.tabs:Paint( w, h )
	end
	
	self.selectedPanelMarker = vgui.Create( "DPanel", self )
	self.selectedPanelMarker:SetZPos( 0 )
	function self.selectedPanelMarker:Paint( w, h )
		draw.RoundedBoxEx( 8, 0, 0, w, h, CyBConcept.iconpanelBg, false, false, false, false )
	end
	
	self:SetIconSpacing( 10 )
	self:SetTabsInnerMargin( 5 )
end

function PANEL:SetTabsInnerMargin( space )
	self.innerMargin = space
end

function PANEL:SetIconSpacing( space )
	self.ySpacing = space
	self.tabs:SetSpaceY( space )
end

function PANEL:PerformLayout( )
	self.tabs:SetWide( self:GetIconSize( ) )
	local spaceX = ( self.tabsContainer:GetWide( ) - self:GetIconSize( ) ) / 2
	self.tabs:DockMargin( spaceX, self.ySpacing, spaceX, self.ySpacing )
	
	self:SetWide( self.tabsContainer:GetWide( ) + self.seperatorWidth )
	for k, v in pairs( self:GetTabs( ) ) do
		if self:GetPropertySheet( ):GetActiveTab( ) == v then
			local x, y = v:GetPos( )
			local x2, y2 = self.tabs:GetPos( )
			
			x = x + x2
			y = y + y2
			
			x = x - self.ySpacing / 2
			y = y - self.ySpacing / 2
			
			self.selectedPanelMarker:SetPos( x, y )
			self.selectedPanelMarker:SetSize( self:GetWide( ) - x, v:GetTall( ) + self.ySpacing )
		end
	end
end

function PANEL:Paint( w, h )
	local x, y = self.tabsContainer:GetPos( )
	local w, h = self.tabsContainer:GetSize( )
	draw.RoundedBox( 0, x, y, w, h, CyBConcept.barBg )
end

function PANEL:GetTabs( )
	return self.tabs:GetChildren( )
end	


function PANEL:addTab( label, panel, material )
	local icon = vgui.Create( "DImageButton", self.tabs )
	icon.image = material
	icon:SetSize( self:GetIconSize( ), self:GetIconSize( ) )
	icon:SetStretchToFit( false )
	icon.OwnLine = true

	function icon.PerformLayout( icon )
		icon.m_Image:SetSize( self:GetIconSize( )-10, self:GetIconSize( )-10 )
		icon.m_Image:Center()
	end

	function icon:Think( )

		self.Hovered = self:IsHovered()
		
		if self.Hovered and not self.lastHovered then

			sound.Play( "hover", LocalPlayer( ):GetPos( ) )

		end

		self.lastHovered = self.Hovered
		
		if self:GetPropertySheet( ):GetActiveTab( ) == icon or self.Hovered then
			icon.m_Image:SetImageColor( CyBConcept.iconHighlight  )
		else
			icon.m_Image:SetImageColor( CyBConcept.iconNormal )
		end
	end

	function icon:DoClick( )
		self:GetPropertySheet( ):SetActiveTab( self )

		LocalPlayer():EmitSound("buttons/lightswitch2.wav", 75, 100, 0.2)

		panel.name = label
		if isfunction(panel.updatefunc) then panel.updatefunc() end
		
		sound.Play( "select", LocalPlayer( ):GetPos( ) )
	end

	icon.panel = panel

	function icon:GetPanel( )
		return self.panel
	end

	function icon.GetPropertySheet( )
		return self:GetPropertySheet( )
	end

	function icon:Paint( w, h )
		draw.RoundedBox( 2, 0, 0, w, h, CyBConcept.iconBg )

		surface.SetDrawColor( icon.m_Image:GetImageColor() )

		surface.SetMaterial( Material(self.image) )

		surface.DrawTexturedRect( 4, 4, 24, 24 )
	end
	
	return icon
end
vgui.Register( "DConceptVerticalPropertySheetBar", PANEL, "DPanel" ) 

local PANEL = {}
AccessorFunc( PANEL, "m_pActiveTab", "ActiveTab" )
function PANEL:Init( )
	self.spacing = 25
	
	self.tabBar = vgui.Create( "DConceptVerticalPropertySheetBar", self )
	self.tabBar:Dock( LEFT )
	self.tabBar:SetWide( 146 + self.spacing )
	function self.tabBar.GetPropertySheet( )
		return self
	end
	
	self.panelContainer = vgui.Create( "DPanel", self )
	self.panelContainer:DockMargin( 0, 0, 0, 0 )
	self.panelContainer:Dock( FILL )
	function self.panelContainer:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CyBConcept.panelBg )
	end

end

function PANEL:AddSheet( label, panel, material )
	panel:SetParent( self.panelContainer )
	local tab = self.tabBar:addTab( label, panel, material )
	panel:SetVisible( false )
	panel:Dock( FILL )
	if not self:GetActiveTab( ) then
		self:SetActiveTab( tab )
		panel:SetVisible( true )
	end
end

function PANEL:SetActiveTab( tab )
	if self.m_pActiveTab then
		self.m_pActiveTab:GetPanel( ):SetVisible( false )
	end
	self.m_pActiveTab = tab
	self.m_pActiveTab:GetPanel( ):SetVisible( true )
	self:InvalidateLayout( )
	self.tabBar:InvalidateLayout( )
end

function PANEL:Paint( w, h )
end

function PANEL:PerformLayout( )
	local activeTab = self:GetActiveTab( )
	if not activeTab then return end
	activeTab:InvalidateLayout( true )
	
	for k, tab in pairs( self.tabBar:GetTabs( ) ) do
		if tab == activeTab then
			tab:GetPanel( ):SetVisible( true )
			tab:GetPanel( ):SetZPos( 2 )
		else
			tab:GetPanel( ):SetVisible( false )
			tab:GetPanel( ):SetZPos( 1 )
		end
	end
end

vgui.Register( "DConceptVerticalPropertySheet", PANEL, "DPanel" )