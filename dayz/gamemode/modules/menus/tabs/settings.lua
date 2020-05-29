CyBConf = CyBConf or {}
CyBConf.InvKey = GetConVar( "cyb_invkey" ) or CreateClientConVar("cyb_invkey", KEY_T, true, false)
CyBConf.MinimapEnabled = GetConVar( "cyb_minimap" ) or CreateClientConVar("cyb_minimap", 1, true, false)
CyBConf.MapShowZombies = GetConVar( "cyb_mapshowzomb" ) or CreateClientConVar("cyb_mapshowzomb", 0, true, false)
CyBConf.ShowHUD = GetConVar( "cyb_showhud" ) or CreateClientConVar("cyb_showhud", 1, true, false)
CyBConf.ShowSZHint = GetConVar( "cyb_showszhint" ) or CreateClientConVar("cyb_showszhint", 1, true, false)
CyBConf.ShowHUDLabels = GetConVar( "cyb_showhudlabels" ) or CreateClientConVar("cyb_showhudlabels", 1, true, false)
CyBConf.ShowMissingContent = GetConVar( "cyb_showmissingcontent" ) or CreateClientConVar("cyb_showmissingcontent", 1, true, false)
CyBConf.ShowGroupHUD = GetConVar( "cyb_showgrouphud" ) or CreateClientConVar("cyb_showgrouphud", 1, true, false)
CyBConf.DrawVMColor = GetConVar( "cyb_drawvmcolor" ) or CreateClientConVar("cyb_drawvmcolor", 1, true, false)

GUI_InputInvKey = GUI_InputInvKey or KEY_Q
GUI_ShowHUD = GUI_ShowHUD or 1
GUI_ShowHUDLabels = GUI_ShowHUDLabels or 1
GUI_ShowMissingContent = GUI_ShowMissingContent or 1
GUI_ShowGroupHUD = GUI_ShowGroupHUD or 1
GUI_DrawVMColor = GUI_DrawVMColor or 1
hook.Add("PostGamemodeLoaded", "InitCyBConfKeys", function()
	GUI_InputInvKey = CyBConf.InvKey:GetInt() or KEY_Q
	GUI_ShowHUD = CyBConf.ShowHUD:GetInt() or 1
	GUI_ShowSZHint = CyBConf.ShowSZHint:GetInt() or 1
	GUI_ShowHUDLabels = CyBConf.ShowHUDLabels:GetInt() or 1
	GUI_ShowMissingContent = CyBConf.ShowMissingContent:GetInt() or 1
	GUI_ShowGroupHUD = CyBConf.ShowGroupHUD:GetInt() or 1
	GUI_DrawVMColor = CyBConf.DrawVMColor:GetInt() or 1
end)

local function UpdateDrawVMColor(str, old, new)
	GUI_DrawVMColor = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.DrawVMColor:GetName(), UpdateDrawVMColor)

local function UpdateShowGroupHUD(str, old, new)
	GUI_ShowGroupHUD = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ShowGroupHUD:GetName(), UpdateShowGroupHUD)

local function UpdateShowHUDLabels(str, old, new)
	GUI_ShowHUDLabels = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ShowHUDLabels:GetName(), UpdateShowHUDLabels)

local function UpdateShowSZHint(str, old, new)
	GUI_ShowSZHint = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ShowSZHint:GetName(), UpdateShowSZHint)

local function UpdateShowHUD(str, old, new)
	GUI_ShowHUD = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ShowHUD:GetName(), UpdateShowHUD)

local function UpdateInvKey(str, old, new)
	GUI_InputInvKey = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.InvKey:GetName(), UpdateInvKey)

local function UpdateShowMissingContentKey(str, old, new)
	GUI_ShowMissingContent = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ShowMissingContent:GetName(), UpdateShowMissingContentKey)

function GUI_Rebuild_Settings(parent)
			
	local GUI_InvBinder_Label = vgui.Create("DLabel", parent)
	GUI_InvBinder_Label:SetText(LANG.GetTranslation("inventorykey"))
	GUI_InvBinder_Label:Dock(TOP)
	GUI_InvBinder_Label:DockMargin(10, 0, 0, 0)
	GUI_InvBinder_Label.Think = function(self)
		self:SetText(LANG.GetTranslation("inventorykey"))
	end

	local GUI_InvBinder = vgui.Create("DBinder", parent)
	GUI_InvBinder:SetText(LANG.GetTranslation("inventorykey"))
	GUI_InvBinder:Dock(TOP)
	GUI_InvBinder.Paint = PaintButtons
	GUI_InvBinder:SetConVar("cyb_invkey")
	GUI_InvBinder:DockMargin(10, 0, 10, 0)

	local GUI_LangBinder_Label = vgui.Create("DLabel", parent)
	GUI_LangBinder_Label:SetText(LANG.GetTranslation("language"))
	GUI_LangBinder_Label:Dock(TOP)
	GUI_LangBinder_Label:DockMargin(10, 10, 0, 0)
	GUI_LangBinder_Label.Think = function(self)
		self:SetText(LANG.GetTranslation("language"))
	end

	local GUI_LanguageSelector = vgui.Create("DComboBox", parent)
	GUI_LanguageSelector:Dock(TOP)
	GUI_LanguageSelector:DockMargin(10, 0, 10, 0)
  	GUI_LanguageSelector:SetConVar("dz_language")
  	GUI_LanguageSelector:AddChoice("Server Default", "auto")
  	for _, lang in pairs(LANG.GetLanguages()) do
     	GUI_LanguageSelector:AddChoice(lang, lang)
  	end
  	GUI_LanguageSelector.OnSelect = function(idx, val, data)
    	RunConsoleCommand("dz_language", data)
    end
   	GUI_LanguageSelector.Think = GUI_LanguageSelector.ConVarStringThink
	
   	local ThirdPersonCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ThirdPersonCheckBox:SetText("Thirdperson Enabled?")
	ThirdPersonCheckBox:SetConVar("simple_thirdperson_enabled")
	ThirdPersonCheckBox:Dock(TOP)
	ThirdPersonCheckBox:DockMargin(10, 10, 0, 0)

	local ThirdPersonCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ThirdPersonCheckBox:SetText("Thirdperson Shoulderview?")
	ThirdPersonCheckBox:SetConVar("simple_thirdperson_shoulderview")
	ThirdPersonCheckBox:Dock(TOP)
	ThirdPersonCheckBox:DockMargin(10, 10, 0, 0)

	if BountyTable then -- Simple check for radar system.
		local MiniMapCheckBox = vgui.Create("DCheckBoxLabel", parent)
		MiniMapCheckBox:SetText("Minimap Enabled?")
		MiniMapCheckBox:SetConVar("cyb_minimap")
		MiniMapCheckBox:Dock(TOP)
		MiniMapCheckBox:DockMargin(10, 10, 0, 0)
		
		local ZombieCheckBox = vgui.Create("DCheckBoxLabel", parent)
		ZombieCheckBox:SetText(LANG.GetTranslation("showzombies"))
		ZombieCheckBox:SetConVar("cyb_mapshowzomb")
		ZombieCheckBox:Dock(TOP)
		ZombieCheckBox:DockMargin(10, 10, 0, 0)
	end

	local GroupHUDCheckBox = vgui.Create("DCheckBoxLabel", parent)
	GroupHUDCheckBox:SetText(LANG.GetTranslation("grouphudenabled"))
	GroupHUDCheckBox:SetConVar("cyb_showgrouphud")
	GroupHUDCheckBox:Dock(TOP)
	GroupHUDCheckBox:DockMargin(10, 10, 0, 0)
	GroupHUDCheckBox.Think = function(self)
		self:SetText(LANG.GetTranslation("grouphudenabled"))
	end

	local DrawVMCheckBox = vgui.Create("DCheckBoxLabel", parent)
	DrawVMCheckBox:SetText("Enable weapon viewmodel rarity coloring?")
	DrawVMCheckBox:SetConVar("cyb_drawvmcolor")
	DrawVMCheckBox:Dock(TOP)
	DrawVMCheckBox:DockMargin(10, 10, 0, 0)
	DrawVMCheckBox.Think = function(self)
		--self:SetText("Enable weapon viewmodel rarity coloring?")
	end
	
	local ShowHUDCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ShowHUDCheckBox:SetText(LANG.GetTranslation("enableingamehud"))
	ShowHUDCheckBox:SetConVar("cyb_showhud")
	ShowHUDCheckBox:Dock(TOP)
	ShowHUDCheckBox:DockMargin(10, 10, 0, 0)
	ShowHUDCheckBox.Think = function(self)
		self:SetText(LANG.GetTranslation("enableingamehud"))
	end	

	local ShowItemGlowCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ShowItemGlowCheckBox:SetText("Enable Item Glow?")
	ShowItemGlowCheckBox:SetConVar("dz_itemglow")
	ShowItemGlowCheckBox:Dock(TOP)
	ShowItemGlowCheckBox:DockMargin(10, 10, 0, 0)
	ShowItemGlowCheckBox.Think = function(self)
		self:SetText("Enable Item Names?")
	end	

	local ShowSZHintCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ShowSZHintCheckBox:SetText(LANG.GetTranslation("enablesafezonehints"))
	ShowSZHintCheckBox:SetConVar("cyb_showszhint")
	ShowSZHintCheckBox:Dock(TOP)
	ShowSZHintCheckBox:DockMargin(10, 10, 0, 0)
	ShowSZHintCheckBox.Think = function(self)
		self:SetText(LANG.GetTranslation("enablesafezonehints"))
	end	

	local ShowHUDLabelsCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ShowHUDLabelsCheckBox:SetText(LANG.GetTranslation("enablehudlabels"))
	ShowHUDLabelsCheckBox:SetConVar("cyb_showhudlabels")
	ShowHUDLabelsCheckBox:Dock(TOP)
	ShowHUDLabelsCheckBox:DockMargin(10, 10, 0, 0)
	ShowHUDLabelsCheckBox.Think = function(self)
		self:SetText(LANG.GetTranslation("enablehudlabels"))
	end	

	local ShowMissingContentCheckBox = vgui.Create("DCheckBoxLabel", parent)
	ShowMissingContentCheckBox:SetText(LANG.GetTranslation("enablemissingcontentwarnings"))
	ShowMissingContentCheckBox:SetConVar("cyb_showmissingcontent")
	ShowMissingContentCheckBox:Dock(TOP)
	ShowMissingContentCheckBox:DockMargin(10, 10, 0, 0)
	ShowMissingContentCheckBox.Think = function(self)
		self:SetText(LANG.GetTranslation("enablemissingcontentwarnings"))
	end	
end

DayZ_AddMenuTab( { order = 8, name = "Settings", type = "DPanel", icon = "cyb_mat/cyb_settings.png", desc = "Configurable game settings", func = GUI_Rebuild_Settings } )