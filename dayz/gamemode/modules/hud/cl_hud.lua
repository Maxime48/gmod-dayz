PHDayZ = PHDayZ or {}
CyBConf = CyBConf or {}

CyBConf.ItemGlow = CreateClientConVar("dz_itemglow", 1, true, false)

GUI_ItemGlow = GUI_ItemGlow or 1
hook.Add("Initialize", "InitKeys", function()
	GUI_ItemGlow = CyBConf.ItemGlow:GetInt() or 1
end)

local function UpdateItemGlow(str, old, new)
	GUI_ItemGlow = math.floor(new)
end
cvars.AddChangeCallback(CyBConf.ItemGlow:GetName(), UpdateItemGlow)

CurDeathTime = CurDeathTime or (CurTime()+PHDayZ.Player_DeathTime)
DeathMessage = DeathMessage or ""
LastDeathMessage = LastDeathMessage or DeathMessage

net.Receive( "net_DeathMessage", function( len )
	
	DeathMessage = net.ReadString()
	LastDeathMessage = DeathMessage
	--surface.PlaySound( "music/death.wav" )
	
	if LocalPlayer().IsVIP and LocalPlayer():IsVIP() then
		CurDeathTime = (CurTime()+PHDayZ.Player_VIPDeathTime)
	else
		CurDeathTime = (CurTime()+PHDayZ.Player_DeathTime)
	end

	if LocalPlayer():GetInArena() then
		CurDeathTime = CurTime() + 5
	end

	-- you asked for it.
	if !LocalPlayer():GetInArena() then
		Local_HotBar = {} 
		if IsValid(HotBarPanel) then 
			HotBarPanel:Remove() 
		end
	end
end)

net.Receive( "LastDeath", function( len )
	LastDeathMessage = net.ReadString()
end)

local blur = Material("pp/blurscreen")
function drawBlurAt(x, y, w, h, amount, passes, reverse)
	-- Intensity of the blur.
	amount = amount or 5

	surface.SetMaterial(blur)
	surface.SetDrawColor(255, 255, 255)

	local scrW, scrH = ScrW(), ScrH()
	local x2, y2 = x / scrW, y / scrH
	local w2, h2 = (x + w) / scrW, (y + h) / scrH

	for i = -(passes or 0.2), 1, 0.2 do
		if reverse then
			blur:SetFloat("$blur", i*-1 * amount)
		else
			blur:SetFloat("$blur", i * amount)
		end
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRectUV(x, y, w, h, x2, y2, w2, h2)
	end
end

function Pulsate(c) --used for flashing colors
	return (math.abs(math.sin(CurTime()*c)))
end

function Fluctuate(c) --used for flashing colors
	return (math.cos(CurTime()*c)+1)/2
end

net.Receive("PHDayZ_ServerErrors", function( len )
	PHDayZ_CriticalErrors = net.ReadTable()
end)

local soundplaying = false
local shownRadWarning = false
function ShowSZPopup()
	local SW, SH = ScrW(),ScrH()
	local TagTime = LocalPlayer():GetPVPTime()


	if IsValid(SZPanel) then	
		if SZPanel.Moving then return end

		local DoMove = false
		if LocalPlayer():GetPVPTime() < CurTime() and SZPanel.WasTagged then
			DoMove = true
		elseif LocalPlayer():GetSafeZone() and SZPanel.Edge then
			DoMove = true
		elseif LocalPlayer():GetSafeZoneEdge() and !SZPanel.Edge then
			DoMove = true
		elseif ( !LocalPlayer():GetSafeZone() and !LocalPlayer():GetSafeZoneEdge() and !LocalPlayer():GetInArena() ) or ( LocalPlayer():GetPVPTime() > CurTime() and !SZPanel.WasTagged ) then
			DoMove = true
		elseif LocalPlayer():GetInArena() and !SZPanel.Arena then
			DoMove = true
		end

		if DoMove then
			SZPanel:MoveTo(ScrW(), 200, 1, 0.1, -1, function(anim, pnl)
				SZPanel:Remove()
			end)
			SZPanel.Moving = true
		end

	end

	if ( !LocalPlayer():GetSafeZone() and !LocalPlayer():GetSafeZoneEdge() and !LocalPlayer():GetInArena() ) or IsValid(SZPanel) then return end

	SZPanel = vgui.Create("DPanel")
	SZPanel:SetSize(200, 75)
	SZPanel:SetPos(ScrW(), 200)
	SZPanel.Edge = LocalPlayer():GetSafeZoneEdge()
	SZPanel.Arena = LocalPlayer():GetInArena()
	SZPanel.WasTagged = ( LocalPlayer():GetPVPTime() > CurTime() ) 

	local text = (LocalPlayer():GetSafeZone() and LANG.GetTranslation("safezone")) or (LocalPlayer():GetSafeZoneEdge() and LANG.GetTranslation("safezoneedge")) or ""
	local infotext = ( LocalPlayer():GetPVPTime() > CurTime() ) and "Vulnerable to Damage" or (LocalPlayer():GetSafeZone() and LANG.GetTranslation("safezonehint")) or (LocalPlayer():GetSafeZoneEdge() and LANG.GetTranslation("safezonehint")) or LANG.GetTranslation("safezonevuln")

	if LocalPlayer():GetInArena() then
		text = "PRACTICE ARENA"
		infotext = "Shoot your friends. No gear loss! Instant Respawn!"
	end

	local color = "0, 255, 0"
	if ( LocalPlayer():GetPVPTime() > CurTime() ) then
		color = "255, 0, 0"
	end

	local teleporttext = LANG.GetTranslation("safezoneteleport") or "Type !sz to Teleport"

	local parse = "<font=char_title16><color= ".. color ..">"..infotext
	SZPanel.text = markup.Parse(parse)
	SZPanel.textX = nil

	SZPanel.Paint = function(self, w, h)

		local szcountdown = ""
		if self.WasTagged then
			szcountdown = " ("..math.Round(LocalPlayer():GetPVPTime() - CurTime()).."s)"
			if math.Round(LocalPlayer():GetPVPTime() - CurTime()) <= 0 then
				szcountdown = ""
			end
		end

		if (self.text) then
			self.textX = self.textX or w + 8
			self.text:Draw(self.textX, 30)

			if (self.NextUpdate or 0) < CurTime() then
				self.NextUpdate = CurTime() + 1
				parse = "<font=char_title16><color= ".. color ..", 255>"..infotext..szcountdown
				self.text = markup.Parse(parse)
			end

			self.textX = self.textX - (FrameTime() * 90)

			if (self.textX + self.text:GetWidth() < 0) then

				self.textX = w + 8

			end
		
		end

		draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 200))
		draw.DrawText(text, "char_title24", w/2, 8, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		if PHDayZ.SafeZoneTeleportEnabled then
			local text = "Find teleporters to come back!"
			if PHDayZ.SafeZoneTeleportChat then
				text = "Type !sz to Teleport"
			end
			draw.DrawText(text, "char_title16", w/2, 52, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		end
		//draw.DrawText(infotext..szcountdown, "char_title16", w/2, 28, color, TEXT_ALIGN_CENTER)

	end

	SZPanel:MoveTo(ScrW()-200, 200, 1, 0.1, -1, function() if IsValid(SZPanel) then SZPanel.Moving = false end end)

	--timer.Simple(10, function() if IsValid(SZPanel) then SZPanel:Remove() end end)

end

PHDayZ_CriticalErrors = PHDayZ_CriticalErrors or {}

local function ShowSetupErrors()
	if #PHDayZ_CriticalErrors < 1 then return end
	local w = ScrW()
	local h = 200
	local padding = ScrW()/2-w/2


	local y = ScrH()/2
	local color = Color(Pulsate(1)*255, 0, 0, 255)

	draw.RoundedBoxEx(4, padding-1, y-h/2, w, h, Color(10, 10, 10, 200), false, false, false, false)
	draw.SimpleText( "THIS SERVER HAS CRITICAL GAMEMODE SETUP ERRORS (SEE ERROR FAQ)", "SafeZone_NAME", padding + w/2 - 4, y-60, color, 1, 1, 0.5, Color( 0, 0, 0, 255 ))

	local i = 0
	for k, v in pairs(PHDayZ_CriticalErrors) do
		draw.SimpleText( v, "tab_title", padding + w/2 - 4, y+i, Color(255,0,0,255), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
		i = i + 30
	end
	
end

DayZContent = DayZContent or false
local function CheckMissingContent()

	if !DayZContent then
		if file.Exists("models/zed/malezed_04.mdl", "GAME") then DayZContent = true end
	end

	if DayZContent then timer.Destroy("ContentChecker") end

end
timer.Create("ContentChecker", 5, 0, CheckMissingContent)

local function ShowMissingContent()
	--if #PHDayZ_MissingContent < 1 then return end
	--if IsMounted('ep2') then return end
	if GUI_ShowMissingContent == 0 then return end

	if DayZContent then return end

	local w = 538
	local h = 170
	local padding = 0
	local tpad = 20
	local y = 175
	local color = Color( 140, 50, 50, 255 )
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, Color(10, 10, 10, 150), false, true, false, true)
	 
	draw.SimpleText( "YOUR CLIENT IS MISSING CONTENT!", "SafeZone_NAME", padding + w/2, y-70, Color( 255, 0, 0, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))

	if !DayZContent then
		draw.SimpleText( "Content: 'GMod DayZ' not found!", "Cyb_HudTEXT", tpad, y, Color( 255, 255, 255, 255 ), 0, 1, 0.5, Color( 0, 0, 0, 255 ))
	end

	draw.SimpleText( "ENJOY ERRORS/MISSING TEXTURES!", "SafeZone_NAME", padding + w/2, y+40, Color( 255, 0, 0, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	draw.SimpleText( "Get the content from !workshop", "Cyb_HudTEXT", tpad, y+70, Color( 255, 255, 255, 255 ), 0, 1, 0.5, Color( 0, 0, 0, 255 ))
end

local function GetHungerValue()
	return math.Clamp(LocalPlayer():GetHunger(), 0, 1000)
end

local function GetRadiationValue()
	return LocalPlayer():GetRadiation() or 0
end

local function GetThirstValue()
    return math.Clamp(LocalPlayer():GetThirst(), 0, 1000)
end

function GM:DrawDeathNotice(x, y)
	return
end

function HideThings( name )
    if (name == "CHudDamageIndicator" ) then
		return false
    end
end
hook.Add( "HUDShouldDraw", "HideThings", HideThings )

function GM:HUDShouldDraw(Name)
	if IsValid(LocalPlayer()) and LocalPlayer():GetSafeZone() && Name == "CHudWeaponSelection" then
		return false
	end
	return true
end

local grad = Material("gui/gradient")
local tagmat = Material("gui/icon_cyb_64_red.png")
local edgemat = Material("gui/icon_cyb_64_orange.png")
local safemat = Material("gui/icon_cyb_64_blue.png")

ProcessName = ProcessName or "N/A"
ProcessTime = ProcessTime or 0
ProcessItem = ProcessItem or ""
ProcessRunning = ProcessRunning or false
local ProcessStartTime = RealTime()
function DoProcessBar()
	ProcessName = net.ReadString()
	ProcessAmount = net.ReadInt(16)
	ProcessTime = net.ReadFloat()
	ProcessItem = net.ReadString()

	ProcessItem = ProcessItem or "item_wood"

	ProcessRunning = true
	ProcessStartTime = RealTime()
	MakeProcessBar()
end
net.Receive("DoProcessBar", DoProcessBar)

function MakeProcessBar()
	if !ProcessRunning then return end

	local name, amount, item, time = ProcessName, ProcessAmount, ProcessItem, ProcessTime

	local NewPanel = false
	if !IsValid(ProcessFrame) then
		NewPanel = true
		ProcessFrame = vgui.Create("DPanel")
	end

	ProcessFrame.colorOverride = nil

	timer.Create("removeprocessbar", time + 3, 1, function() 
		if IsValid(ProcessFrame) then 
			ProcessFrame:MoveTo( ScrW()/2 - 250, -85, 0.5, 0, -1, function() if !ProcessFrame.Moving then ProcessFrame:Remove() end end ) 
		end 
	end)

	local makecustomicon = false
	if !GAMEMODE.DayZ_Items[item] then
		ProcessFrame.Status = name
		makecustomicon = true
	else
		ProcessFrame.Status = name.." "..GAMEMODE.DayZ_Items[item].Name.." x"..amount
	end

	ProcessFrame:SetSize( 500, 85 )

	if NewPanel then
		ProcessFrame:SetPos( ScrW()/2 - 250, -85 )
		ProcessFrame.WantsMove = true
	end

	ProcessFrame:MoveTo( ScrW()/2 - 250, 60, 0.5, 0, -1, function() ProcessFrame.Moving = false end )
	ProcessFrame.Moving = true

	ProcessFrame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, self.colorOverride or Color( 0, 0, 0, 150 ))

		draw.RoundedBoxEx(4,5,5,75,75,Color( 0, 0, 0, 50 ), true, true, true, true)
		draw.RoundedBoxEx(4,6,6,75-2,75-2,Color( 255, 255, 255, 10 ), true, true, true, true) 
		draw.RoundedBoxEx(4,7,7,75-4,75-4,Color( 60, 60, 60, 255 ), true, true, true, true) 

		if LocalPlayer():GetItemAmount(item) > 0 then
			draw.DrawText( "x"..LocalPlayer():GetItemAmount(item), "Cyb_Inv_Label", 75, 65, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT )
		end

		draw.DrawText( "[R] Cancel", "Cyb_Inv_Label", w - 5, h - 20, Color(200, 200, 200, 255), TEXT_ALIGN_RIGHT )

	end

	if IsValid(ProcessFrame.ProcessIconPanel) then -- Remove and re-create.
		ProcessFrame.ProcessIconPanel:Remove()
	end

	if makecustomicon then
		ProcessFrame.ProcessIconPanel = vgui.Create("DPanel", ProcessFrame)
		ProcessFrame.ProcessIconPanel.Paint = function(self, w, h)

			draw.RoundedBoxEx(4,0,0,w,h,Color( 0, 0, 0, 50 ), true, true, true, true)
			draw.RoundedBoxEx(4,1,1,w-2,h-2,Color( 255, 255, 255, 10 ), true, true, true, true) 
			draw.RoundedBoxEx(4,2,2,w-4,h-4,Color( 60, 60, 60, 255 ), true, true, true, true) 

		end
		ProcessFrame.ProcessIconPanel:SetSize(75, 75)

		ProcessFrame.ProcessIcon = vgui.Create("DModelPanel", ProcessFrame.ProcessIconPanel)
		ProcessFrame.ProcessIcon:SetPos(0, 0)
		ProcessFrame.ProcessIcon:SetSize(80, 80)
		ProcessFrame.ProcessIcon:SetModel( item )
		
		local PaintModel = ProcessFrame.ProcessIcon.Paint
		ProcessFrame.ProcessIcon.LayoutEntity = function() end
		ProcessFrame.ProcessIcon:SetDrawOnTop(false)

		local mn, mx = ProcessFrame.ProcessIcon:GetEntity():GetRenderBounds();
		local size = 0;
		size = math.max(size, math.abs(mn.x) + math.abs(mx.x));
		size = math.max(size, math.abs(mn.y) + math.abs(mx.y));
		size = math.max(size, math.abs(mn.z) + math.abs(mx.z));

		ProcessFrame.ProcessIcon:SetFOV(45);
		ProcessFrame.ProcessIcon:SetCamPos(Vector(size, size, size));
		ProcessFrame.ProcessIcon:SetLookAt((mn + mx) * 0.5);
		--ProcessFrame.ProcessIcon:GetEntity():SetAngles( Angle(0,0,0) )

		function ProcessFrame.ProcessIcon:Paint(w, h)
		
			local x2, y2 = self:GetParent():LocalToScreen( 0, 0 )
			local w2, h2 = self:GetParent():GetSize()
			render.SetScissorRect( x2, y2, x2 + w2, y2 + h2, true )

			PaintModel( self, w, h )
			
			render.SetScissorRect( 0, 0, 0, 0, false )
		end

	else

		ProcessFrame.ProcessIconPanel, ProcessFrame.ProcessIcon = DZ_MakeIcon( nil, item, 0, ProcessFrame, nil, nil, 75, 75, false, true, false )

	end

	ProcessFrame.ProcessIconPanel:SetPos(5, 5)

	if !IsValid(ProcessFrame.ProcessBar) then
		ProcessFrame.ProcessBar = vgui.Create("DPanel", ProcessFrame)
	end
	ProcessFrame.ProcessBar:SetSize( 400, 25 )
	ProcessFrame.ProcessBar:SetPos( 90, 30 )

	local width = 0
	local curtime = RealTime() + time

	ProcessFrame.ProcessBar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color( 50, 50, 50, 255 ))

		if ProcessRunning and width < 401 then
			if time < 1 then
				width = ( ( RealTime() - ProcessStartTime ) * (time*4) ) * 400
			else
				width = ( ( RealTime() - ProcessStartTime ) / time ) * 400
			end

			local timeleft = math.Round( curtime - RealTime() )
			if !GAMEMODE.DayZ_Items[item] then
				ProcessFrame.Status = name.." ( ".. timeleft .."s )"
			else
				ProcessFrame.Status = name.." "..GAMEMODE.DayZ_Items[item].Name.." x"..amount.." ( ".. timeleft .."s )"
			end

		end

		surface.SetDrawColor( 30, 30, 30, 150 )
		surface.DrawRect( 0, 0, width, h )

		if width >= 400 then
			ProcessFrame.Status = "Finished!"
			ProcessFrame.colorOverride = Color(0,100,0,150)
		end

		draw.DrawText( ProcessFrame.Status, "Cyb_Inv_Label", w/2, h-18, Color(200,200,200,255), TEXT_ALIGN_CENTER )
	end
end

local red, green = 255, 0
--Stop progress bar
function StopProcessBar()
	if IsValid(ProcessFrame) then 
		ProcessFrame.Status = "Cancelled!" 
		ProcessFrame.colorOverride = Color(100,0,0,150)
		timer.Simple(3, function()
			if !IsValid(ProcessFrame) then return end
			if ProcessRunning then return end

			ProcessFrame:MoveTo( ScrW()/2 - 250, -85, 0.5, 0, -1, function() ProcessFrame.colorOverride = nil if !ProcessFrame.Moving then ProcessFrame:Remove() end end ) 

		end)
	end

	red, green = 255, 0 

	ProcessRunning = false
end
net.Receive("StopProcessBar", StopProcessBar)

local function DrawProcessBar()
	if ProcessRunning then
		local wid = ScrW() / 3
		local hei = ScrH() / 30
		surface.SetDrawColor( 30, 30, 30, 150 )
		surface.DrawRect( ScrW() * 0.5 - wid * 0.5, ScrH() / 30, wid, hei )

		local width = ( ( RealTime() - ProcessStartTime ) / ProcessTime ) * wid
		if width >= wid then UpdateAllTabs() StopProcessBar() return end -- end
		surface.SetDrawColor( red, green, 0, 255)
		red = 255/(width/150)
		green = (width/3)
		surface.DrawRect( ScrW() * 0.5 - wid * 0.5, ScrH() / 30, width, hei )

		surface.SetDrawColor( 27, 167, 219,255 )
		surface.DrawOutlinedRect( ScrW() * 0.5 - wid * 0.5, ScrH() / 30, wid, hei )

		draw.SimpleText( ProcessName, "Cyb_HudTEXT", ScrW() * 0.5, hei * 1.5, Color( 255, 255, 255, 255 ), 1, 1 )
	end
end

function hidehud(name)
	for k, v in pairs({"CHudHealth", "CHudBattery", "CHudAmmo"})do
		if name == v then return false end
	end
end
hook.Add("HUDShouldDraw", "HideOurHud:D", hidehud)

local ButtonMaterial = Material("cyb_mat/cyb_keybut.png")
function GM:HUDDrawTargetID()
	local tr = LocalPlayer():GetEyeTrace()

	hook.Call("DZ_HudTargetID", GAMEMODE, tr)
		
	if !DZ_MENUVISIBLE && IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_physics" or tr.Entity:GetClass() == "dz_interactable") and (tr.Entity:Health() > 0) and !tr.Entity:GetPersistent() then
		if PHDayZ.AllowPropDamage then
			local ent = tr.Entity
			local maxhp, hp, pos = ent:GetMaxHealth(), ent:Health(), ent:GetPos()
			local percentCalc = 255 * (hp / maxhp)
			draw.SimpleText(tostring(hp) .." / " ..tostring(maxhp), "char_title24", ScrW()/2, ScrH()/2-50, Color(255-percentCalc,percentCalc,0,255), 1, 1, 1, Color(0,0,0,255))
		end
	end

	if !DZ_MENUVISIBLE && IsValid(tr.Entity) and ( tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "grave" ) and LocalPlayer():GetPos():Distance(tr.Entity:GetPos()) < 100 then
		if tr.Entity:GetStoredName() == "" then return end

		local tab = { tr.Entity }
		halo.Add( tab, Color( 127, 127, 127 ), 2, 2, 1 )


		draw.DrawText(tr.Entity:GetStoredName(), "char_title24", ScrW()/2, ScrH()/2 - 30, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		draw.DrawText(tr.Entity:GetStoredReason(), "char_title16", ScrW()/2, ScrH()/2 - 7, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		draw.DrawText("[E] Search Body ("..math.Round( tr.Entity:GetPerish() - CurTime() ).."s)", "char_title16", ScrW()/2, ScrH()/2 + 10, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if !DZ_MENUVISIBLE && IsValid(tr.Entity) and ( tr.Entity:GetClass() == "base_lootable" ) and LocalPlayer():GetPos():Distance(tr.Entity:GetPos()) < 300 then
		local tab = { tr.Entity }
		halo.Add( tab, Color( 127, 127, 127 ), 2, 2, 1 )

		local name = getNiceName(tr.Entity:GetModel())

		draw.DrawText("[E] Search "..firstToUpper( name ), "char_title24", ScrW()/2, ScrH()/2 + 10, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if !DZ_MENUVISIBLE && IsValid(tr.Entity) and ( tr.Entity:GetClass() == "base_item" or tr.Entity:GetClass() == "dz_shopitem" or tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "grave" ) and LocalPlayer():GetPos():Distance(tr.Entity:GetPos()) < 100 then


		local tab = { tr.Entity }
		local rarity = {}
		rarity.color = Color(255, 255, 255)
		if tr.Entity.GetRarity then
			rarity = GetRarity( tr.Entity:GetRarity() )
		end

		local class = tr.Entity:GetClass()
		if class != "prop_ragdoll" and class != "grave" then
			class = tr.Entity:GetItem()
		end

		if LocalPlayer():KeyDown(IN_USE) && tr.Entity:GetClass() != "dz_shopitem" then
			if IsValid(ButtonPanel) then return end

			ButtonPanel = vgui.Create("DPanel")
			ButtonPanel:SetDrawOnTop(true)
			ButtonPanel.Paint = function(self, w, h) 
				draw.RoundedBox( 4, 0, 0, w, h, Color(0,0,0,220) ) 
			end
			local i = 0

			if tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "grave" then

				if string.find(string.lower(tr.Entity:GetStoredName()), "bleeding out") then

					ButtonPanel.DoKill = vgui.Create("DButton", ButtonPanel)
					ButtonPanel.DoKill:Dock(TOP)
					ButtonPanel.DoKill:SetTall(30)
					ButtonPanel.DoKill:SetText("")
					ButtonPanel.DoKill.Paint = function(self, w, h)
						local boxcolor = Color(0,0,0,255)
						local textcolor = Color(255,255,255,255)
						if self:IsHovered() then
							boxcolor = Color(255,255,255,255)
							textcolor = Color(0,0,0,255)
						end

						draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

						draw.DrawText( "Kill", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						draw.DrawText( "(Break Neck)", "char_title12", w/2, h/2 + 4, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end
					ButtonPanel.DoKill.DoClick = function(self)
						sound.Play( "select", LocalPlayer( ):GetPos( ) )

						net.Start("ragdoll_DoKill")
							net.WriteUInt(tr.Entity:EntIndex(), 32)
						net.SendToServer()
					end
					i = i + 30
					
					ButtonPanel.Revive = vgui.Create("DButton", ButtonPanel)
					ButtonPanel.Revive:Dock(TOP)
					ButtonPanel.Revive:SetTall(30)
					ButtonPanel.Revive:SetText("")
					ButtonPanel.Revive.Paint = function(self, w, h)
						local boxcolor = Color(0,0,0,255)
						local textcolor = Color(255,255,255,255)
						if self:IsHovered() then
							boxcolor = Color(255,255,255,255)
							textcolor = Color(0,0,0,255)
						end

						local t 
						if !LocalPlayer():HasItem("item_medic2", true) then
							boxcolor = Color(80,0,0,255)
							textcolor = Color(255,255,255,255)
							t = "[Requires Bandage]"
						end

						draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

						draw.DrawText( "Save", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						if t != nil then
							draw.DrawText( t, "char_title12", w/2, h/2 + 4, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						end
					end
					ButtonPanel.Revive.DoClick = function(self)
						sound.Play( "select", LocalPlayer( ):GetPos( ) )

						net.Start("ragdoll_DoRevive")
							net.WriteUInt(tr.Entity:EntIndex(), 32)
						net.SendToServer()
					end
					i = i + 30

				end
				
				ButtonPanel.Bury = vgui.Create("DButton", ButtonPanel)
				ButtonPanel.Bury:Dock(TOP)
				ButtonPanel.Bury:SetTall(30)
				ButtonPanel.Bury:SetText("")
				ButtonPanel.Bury.Paint = function(self, w, h)
					local boxcolor = Color(0,0,0,255)
					local textcolor = Color(255,255,255,255)
					if self:IsHovered() then
						boxcolor = Color(255,255,255,255)
						textcolor = Color(0,0,0,255)
					end

					local t 
					if !LocalPlayer():HasItem("seed_hoe", true) and !LocalPlayer():HasCharItem("seed_hoe", true) then
						boxcolor = Color(80,0,0,255)
						textcolor = Color(255,255,255,255)
						t = "[Requires Wooden Shovel]"
					end

					draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

					draw.DrawText( "Bury Body", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					if t != nil then
						draw.DrawText( t, "char_title12", w/2, h/2 + 4, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end
				end
				ButtonPanel.Bury.DoClick = function(self)
					sound.Play( "select", LocalPlayer( ):GetPos( ) )

					net.Start("ragdoll_DoBury")
						net.WriteUInt(tr.Entity:EntIndex(), 32)
					net.SendToServer()
				end
				i = i + 30

				ButtonPanel.Loot = vgui.Create("DButton", ButtonPanel)
				ButtonPanel.Loot:Dock(TOP)
				ButtonPanel.Loot:SetTall(30)
				ButtonPanel.Loot:SetText("")
				ButtonPanel.Loot.Paint = function(self, w, h)
					local boxcolor = Color(0,0,0,255)
					local textcolor = Color(255,255,255,255)
					if self:IsHovered() then
						boxcolor = Color(255,255,255,255)
						textcolor = Color(0,0,0,255)
					end

					draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

					draw.DrawText( "Loot Body", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				ButtonPanel.Loot.DoClick = function(self)
					sound.Play( "select", LocalPlayer( ):GetPos( ) )

					net.Start("ragdoll_DoLoot")
						net.WriteUInt(tr.Entity:EntIndex(), 32)
					net.SendToServer()
				end

				i = i + 30

				gui.EnableScreenClicker(true)

				ButtonPanel:SetPos((ScrW()/2)-75, (ScrH()/2)-(i/2) )
				ButtonPanel:SetSize(150, i)

				return
			end
			halo.Add( tab, rarity.color, 5, 5, 1 )

			if GAMEMODE.DayZ_Items[class].CanIgnite and !tr.Entity:IsOnFire() then
				ButtonPanel.Ignite = vgui.Create("DButton", ButtonPanel)
				ButtonPanel.Ignite:Dock(TOP)
				ButtonPanel.Ignite:SetTall(30)
				ButtonPanel.Ignite:SetText("")
				ButtonPanel.Ignite.Paint = function(self, w, h)
					local boxcolor = Color(0,0,0,255)
					local textcolor = Color(255,255,255,255)
					if self:IsHovered() then
						boxcolor = Color(255,255,255,255)
						textcolor = Color(0,0,0,255)
					end

					draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

					draw.DrawText( "Set on Fire", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				ButtonPanel.Ignite.DoClick = function(self)
					sound.Play( "select", LocalPlayer( ):GetPos( ) )

					net.Start("base_ItemAction")
						net.WriteUInt(4, 4)
						net.WriteUInt(tr.Entity:EntIndex() , 32)
					net.SendToServer()
				end
				i = i + 30
			end

			if GAMEMODE.DayZ_Items[class].Weapon or GAMEMODE.DayZ_Items[class].Body or GAMEMODE.DayZ_Items[class].Pants or GAMEMODE.DayZ_Items[class].Shoes or GAMEMODE.DayZ_Items[class].BackPack or GAMEMODE.DayZ_Items[class].Hat or GAMEMODE.DayZ_Items[class].BodyArmor then
				ButtonPanel.Equip = vgui.Create("DButton", ButtonPanel)
				ButtonPanel.Equip:Dock(TOP)
				ButtonPanel.Equip:SetTall(30)
				ButtonPanel.Equip:SetText("")
				ButtonPanel.Equip.Paint = function(self, w, h)
					local boxcolor = Color(0,0,0,255)
					local textcolor = Color(255,255,255,255)
					if self:IsHovered() then
						boxcolor = Color(255,255,255,255)
						textcolor = Color(0,0,0,255)
					end

					draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

					draw.DrawText( "Equip", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				ButtonPanel.Equip.DoClick = function(self)
					sound.Play( "select", LocalPlayer( ):GetPos( ) )

					net.Start("base_ItemAction")
						net.WriteUInt(5, 4)
						net.WriteUInt(tr.Entity:EntIndex(), 32)
					net.SendToServer()
				end
				i = i + 30
			end

			if GAMEMODE.DayZ_Items[class].CustomFunc and GAMEMODE.DayZ_Items[class].CustomFuncName then
				ButtonPanel.CustomFunc = vgui.Create("DButton", ButtonPanel)
				ButtonPanel.CustomFunc:Dock(TOP)
				ButtonPanel.CustomFunc:SetTall(30)
				ButtonPanel.CustomFunc:SetText("")
				ButtonPanel.CustomFunc.Paint = function(self, w, h)
					local boxcolor = Color(0,0,0,255)
					local textcolor = Color(255,255,255,255)
					if self:IsHovered() then
						boxcolor = Color(255,255,255,255)
						textcolor = Color(0,0,0,255)
					end

					draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

					draw.DrawText( GAMEMODE.DayZ_Items[class].CustomFuncName, "Cyb_Inv_Label", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				ButtonPanel.CustomFunc.DoClick = function(self)
					sound.Play( "select", LocalPlayer( ):GetPos( ) )

					net.Start("base_ItemAction")
						net.WriteUInt(3, 4)
						net.WriteUInt(tr.Entity:EntIndex() , 32)
					net.SendToServer()
				end
				i = i + 30
			end

			ButtonPanel.Collect = vgui.Create("DButton", ButtonPanel)
			ButtonPanel.Collect:Dock(TOP)
			ButtonPanel.Collect:SetTall(30)
			ButtonPanel.Collect:SetText("")
			ButtonPanel.Collect.Paint = function(self, w, h)
				local boxcolor = Color(0,0,0,255)
				local textcolor = Color(255,255,255,255)
				if self:IsHovered() then
					boxcolor = Color(255,255,255,255)
					textcolor = Color(0,0,0,255)
				end

				draw.RoundedBox( 0, 0, 0, w, h, boxcolor ) 

				draw.DrawText( "Collect", "char_title24", w/2, h/2 - 12, textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
			ButtonPanel.Collect.DoClick = function(self)
				sound.Play( "select", LocalPlayer( ):GetPos( ) )

				net.Start("base_ItemAction")
					net.WriteUInt(2, 4)
					net.WriteUInt(tr.Entity:EntIndex() , 32)
				net.SendToServer()
			end
			i = i + 30

			gui.EnableScreenClicker(true)

			ButtonPanel:SetPos((ScrW()/2)-75, (ScrH()/2)-(i/2) )
			ButtonPanel:SetSize(150, i)

			return
		end
		if IsValid(ButtonPanel) then ButtonPanel:Remove() gui.EnableScreenClicker(false) end

		local pos = {}
		pos.x = ScrW()/2
		pos.y = ScrH()/2

		if tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "grave" then return end 

		if InspectGUI and IsValid(InspectGUI) then 
			if InspectGUI.class != class then 
				if !DZ_MENUVISIBLE && !IsValid(GUI_Loot_Frame) then 
					InspectGUI:Remove() 
				end 
			end 
			return 
		end
		InspectGUI = InspectItem(class, pos, false, tr.Entity, true)
		if InspectGUI and IsValid(InspectGUI) then InspectGUI.class = class end
	else
		if IsValid(ButtonPanel) then ButtonPanel:Remove() gui.EnableScreenClicker(false) end
		if ( !DZ_MENUVISIBLE && !IsValid(GUI_Loot_Frame) ) && IsValid(InspectGUI) then InspectGUI:Remove() end
	end
end

local DMGIndicatorAlpha = 0

local HitMarkers = {}

local function scale( n )
	return n * ( ScrH() / 720 )
end

local function DrawMarker( m )
	local fade = m.fade
	local damage_percent = 0.1

	if fade <= 0 then return end

	local normal_col = Color(200,200,200,255)

	local col = Color( 255, 255, 255, 255 * ( math.min( fade * 2, 1 ) ) )

	col.r = damage_percent < 1 and normal_col.r
	col.g = damage_percent < 1 and normal_col.g
	col.b = damage_percent < 1 and normal_col.b

	surface.SetDrawColor( col )

	local len = scale( 2 + ( 2 + damage_percent * 5 ) * fade )
	local dist = scale( 5 + ( 1 - fade ) * ( 20 + damage_percent * 5 ) )

	local screen_pos = m.pos:ToScreen()
	local x, y = screen_pos.x, screen_pos.y

	surface.DrawLine( x + dist, y + dist, x + dist + len, y + dist + len )
	surface.DrawLine( x - dist, y + dist, x - dist - len, y + dist + len )
	surface.DrawLine( x + dist, y - dist, x + dist + len, y - dist - len )
	surface.DrawLine( x - dist, y - dist, x - dist - len, y - dist - len )

	m.fade = Lerp( FrameTime() * 2, fade, 0 )
end

net.Receive("HurtInfo", function(len)
	local dmgpos = net.ReadVector()

	table.insert( HitMarkers, { pos = dmgpos, fade = 2 } )

	LocalPlayer():EmitSound( "buttons/lightswitch2.wav", 75, 100, 0.2 )
end)

hook.Add("HUDPaint", "DrawDamageMarkers", function()
	local i = 1

	while i <= #HitMarkers do
		local m = HitMarkers[ i ]

		DrawMarker( m )

		if m.fade < 0.001 then
			table.remove( HitMarkers, i )
		else
			i = i + 1
		end
	end
end)

local vigmat = Material("cyb_mat/vignette.png", "smooth")
local function DrawVignette()
	local w, h = ScrW(), ScrH()

	surface.SetMaterial( vigmat )
	surface.SetDrawColor( Color(150,10,10,255) )
	surface.DrawTexturedRect( 0, 0, ScrW(),ScrH() )

end

local healthmat = Material("cyb_mat/cyb_health.png", "smooth")
local healthsmooth = 0
local function DrawHealth()

	local w = 48
	local h = 48
	local padding = 133

	healthsmooth = math.Approach( healthsmooth, LocalPlayer():GetRealHealth(), 50 * FrameTime() )
	local percent = healthsmooth / 100

	local y = ScrH() - 175
	local color = Color( 140, 50, 50, 255 )
	if LocalPlayer():GetSick() or (LocalPlayer():GetRealHealth() < 25) then
		color = Color(Pulsate(1)*140, 50, 50, 255)
	end
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, Color(10, 10, 10, 150), false, true, false, true)
	
	render.SetMaterial( healthmat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        Color( 10, 10, 40, 240 ),
        -90
    )

	render.SetScissorRect( 0, y+h/2 - (h * percent), padding + w, ScrH(), true )
	render.SetMaterial( healthmat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        color,
        -90
    )
	render.SetScissorRect( 0, y+h/2, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( math.Round(percent*100), "char_title14", padding + w/2, y, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end

end

local function GetVehicleFuelValue()
	local vehicle = LocalPlayer():GetVehicle()
	if !IsValid(vehicle) then return false end
	
	if IsValid(vehicle:GetParent()) then vehicle = vehicle:GetParent() end
	if !vehicle.GetFuel then return false end

	return math.Round(vehicle:GetFuel())
end

local vehfuelmat = Material("gui/icon_cyb_64_fuel.png", "smooth")
local function DrawVehicleFuel()
	if !GetVehicleFuelValue() then return end
	local w = 48
	local h = 48
	local padding = 15
	local percent = GetVehicleFuelValue() / 100
	local y = ScrH() - 285
	local color = Color( 255, 100, 0, 255 )
	if GetVehicleFuelValue() < 25 then
		color = Color(255, Pulsate(1)*100, 0, 255)
	end
	
	local boxcolor = Color(10, 10, 10, 150)
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)
	
	render.SetMaterial( vehfuelmat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        Color( 10, 10, 40, 240 ),
        -90
    )

	render.SetScissorRect( 0, y+h/2 - (h * percent), padding + w, ScrH(), true )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        color,
        -90
    )
	render.SetScissorRect( 0, y+h/2, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( GetVehicleFuelValue(), "char_title14", padding + w/2, y, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end
	
end

local function GetVehicleHealthValue()
	local vehicle = LocalPlayer():GetVehicle()
	if !IsValid(vehicle) then return false end
	
	if IsValid(vehicle:GetParent()) then vehicle = vehicle:GetParent() end
	if vehicle:Health() == 0 then return false end
	local maxhealth = vehicle:GetMaxHealth()
	if maxhealth == 0 then maxhealth = 100 end
	
	return (vehicle:Health() / maxhealth)
end

local vehhealthmat = Material("gui/icon_cyb_64_spanner.png", "smooth")
local function DrawVehicleHealth()
	if !GetVehicleHealthValue() then return end
	local w = 48
	local h = 48
	local padding = 75
	local percent = math.Round(GetVehicleHealthValue() * 100)
	local y = ScrH() - 285
	local color = Color( 0, 175, 63, 255 )
	if percent < 25 then
		color = Color(Pulsate(1)*255, 175, 63, 255)
	end
	
	local boxcolor = Color(10, 10, 10, 150)
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)
	
	render.SetMaterial( vehhealthmat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        Color( 10, 10, 40, 240 ),
        -90
    )

	render.SetScissorRect( 0, y+h/2 - (h * percent/100), padding + w, ScrH(), true )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        color,
        -90
    )
	render.SetScissorRect( 0, y+h/2, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( percent.."%", "char_title14", padding + w/2, y, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end
	
end

local thirstmat = Material("cyb_mat/cyb_thirst.png", "smooth")
local thirstsmooth = 0
local function DrawThirst()
	if !GetThirstValue() then return end

	local w = 48
	local h = 48
	local padding = 133

	thirstsmooth = math.Approach( thirstsmooth, GetThirstValue(), 50 * FrameTime() )
	local percent = thirstsmooth / 1000

	local y = ScrH() - 105
	local color = Color( 50, 50, 200, 255 )
	if GetThirstValue() < 25 then
		color = Color(50, 50, Pulsate(1)*200, 255)
	end
	
	local boxcolor = Color(10, 10, 10, 150)
	if ( LocalPlayer():GetSafeZone() or LocalPlayer():GetSafeZoneEdge() or LocalPlayer():GetInArena() ) and PHDayZ.Safezone_NoDrain then 
		boxcolor = Color(150, 150, 150, 50)
	end
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, false, true, false, true)
	
	render.SetMaterial( thirstmat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        Color( 10, 10, 40, 240 ),
        -90
    )

	render.SetScissorRect( 0, y+h/2 - (h * percent), padding + w, ScrH(), true )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        color,
        -90
    )
	render.SetScissorRect( 0, y+h/2, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( math.Round(percent*1000), "char_title14", padding + w/2, y, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end
end

local hungermat = Material("cyb_mat/cyb_hunger.png", "smooth")
local hungersmooth = 0
local function DrawHunger()
	if !GetHungerValue() then return end

	local w = 48
	local h = 48
	local padding = 133

	hungersmooth = math.Approach( hungersmooth, GetHungerValue(), 50 * FrameTime() )
	local percent = hungersmooth / 1000

	local y = ScrH() - 35
	local color = Color( 50, 200, 50, 255 )
	if GetHungerValue() < 25 then
		color = Color(50, Pulsate(1)*200, 50, 255)
	end
	
	local boxcolor = Color(10, 10, 10, 150)
	if ( LocalPlayer():GetSafeZone() or LocalPlayer():GetSafeZoneEdge() or LocalPlayer():GetInArena() ) and PHDayZ.Safezone_NoDrain then 
		boxcolor = Color(150, 150, 150, 50)
	end
	
	draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, false, true, false, true)
		
	render.SetMaterial( hungermat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        Color( 10, 10, 40, 240 ),
        -90
    )

	render.SetScissorRect( 0, y+h/2 - (h * percent), padding + w, ScrH(), true )
	render.SetMaterial( hungermat )
	render.DrawQuadEasy( Vector( padding + w/2, y),
        Vector(0,0,-1),
        w, h,
        color,
        -90
    )
	render.SetScissorRect( 0, y+h/2, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( math.Round(percent*1000), "char_title14", padding + w/2, y, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end
end

local hp_bg = Material( "cyb_mat/cyb_hpbg.png", "smooth" )
local bloodsmooth = 0
local armorsmooth = 0
local function DrawBlood()
	if !LocalPlayer():Health() then return end

	local w = 94
	local h = 242
	local padding = 23
	bloodsmooth = math.Approach( bloodsmooth, LocalPlayer():Health(), 50 * FrameTime() )
	armorsmooth = math.Approach( armorsmooth, LocalPlayer():GetPArmor(), 50 * FrameTime() )

	local percent = bloodsmooth / LocalPlayer():GetMaxHealth()
	local armor_percent = armorsmooth / 100 -- max armor is always 100

	local y = ScrH() - (10 * 3) - (20 * 3)
	local color = Color( 140, 50, 50, 255 )
	if LocalPlayer():GetBleed() or (LocalPlayer():Health() <= 20) then
		color = Color(Pulsate(1)*140, 50, 50, 255)
	end
	draw.RoundedBoxEx(4, padding-1, y-h/2, w, h, Color(10, 10, 10, 150), false, false, false, false)

	render.SetScissorRect( 0, ScrH() - (h * armor_percent), padding + w, ScrH(), true )
	render.SetMaterial( hp_bg )
	render.DrawQuadEasy( Vector( padding + w/2, ScrH() - h/2,0),
        Vector(0,0,-1),
        w, h,
        Color(0,255,255,100),
        -90
    )
	render.SetScissorRect( 0, ScrH() - h + 20, padding + w, ScrH(), false )

	render.SetMaterial( hp_bg )
	render.DrawQuadEasy( Vector( padding + w/2, ScrH() - h/2,0),
        Vector(0,0,-1),
        w-4, h-4,
        Color( 40, 10, 10, 240 ),
        -90
    )

	render.SetScissorRect( 0, ScrH() - (h * percent), padding + w, ScrH(), true )
	render.SetMaterial( hp_bg )
	render.DrawQuadEasy( Vector( padding + w/2, ScrH() - h/2,0),
        Vector(0,0,-1),
        w-4, h-4,
        color,
        -90
    )
	render.SetScissorRect( 0, ScrH() - h + 20, padding + w, ScrH(), false )

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( ""..math.Round(percent*100)/20 .. " L", "char_title14", padding + w/2 - 4, ScrH() - h/2 - 26, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))
	end
	
end

XPBar_XPSmooth = 0
local function DrawXP()
	local padding = 0
	local offset = 10
	local w = 12
	local h = 211
	local bgc = Color( 10, 10, 10, 150 )
	local inc = Color( 30, 30, 30, 200 )

	draw.RoundedBoxEx(4, offset + padding, ScrH() - padding - h, w, h, Color(10, 10, 10, 150), true, false, true, false)


	if nevertrue then -- is now disabled lel

		local plyxp = LocalPlayer():GetXP() or 0
		LocalPlayer().CL_Level = LocalPlayer():GetLevel() or 1
		XPBarLength = plyxp / ( PHDayZ.Player_XPLevelMultiplier * LocalPlayer().CL_Level )
		
		local percent = plyxp / ( PHDayZ.Player_XPLevelMultiplier * LocalPlayer().CL_Level )
		local y = math.Round( h * percent )

		draw.RoundedBoxEx(4, offset + padding, ScrH() - padding - h, w, h, Color(10, 10, 10, 150), true, false, true, false)

		draw.RoundedBoxEx(4, offset + padding, ScrH() - padding - y, w, h, Color(50, 120, 50, 255), true, true, true, true)
		
		if GUI_ShowHUDLabels > 0 then
			draw.SimpleText( LocalPlayer().CL_Level, "char_title14", offset + padding + w/2, ScrH() - 10, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))	
		end

	end
	if IsValid(HotBarPanel)  then
		local x, yr = HotBarPanel:GetPos()
		local w, h = HotBarPanel:GetWide()

		if !HotBarPanel.ResizedForXP then
			HotBarPanel.XPBar.Paint = function(self, w, h)
				local w, h = self:GetSize()

				local plyxp = LocalPlayer():GetXP() or 0
				local plylvl = LocalPlayer():GetLevel() or 1 
				local perc = plyxp / ( PHDayZ.Player_XPLevelMultiplier * plylvl )

				local pad = 2 
				local wt = w - (pad*2)
				local wp = math.Round( wt * perc )
				XPBar_XPSmooth = math.Approach( XPBar_XPSmooth, wp, 50 * FrameTime() )
				self.XPS = XPBar_XPSmooth
				local col = Color(0,200,0,80)

		        if wp != XPBar_XPSmooth then
		        	col = Color(0, 220, 0, 120)
		        end

		        draw.RoundedBoxEx(0, 5, pad + 3, w - (pad*2) - 5, h, Color(10,10,10,255), true, true, true, true)

				draw.RoundedBoxEx(0, 5, pad + 3, XPBar_XPSmooth - pad - 5, h - pad, col, true, true, true, true)

				draw.SimpleText( "Level: "..plylvl.." ["..plyxp.."/"..PHDayZ.Player_XPLevelMultiplier * plylvl.."]", "char_title18", w / 2, h/2 + 2, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ) )

			end

			HotBarPanel.ResizedForXP = true
		end

	end
end

local staminasmooth = 0
local function DrawStamina()

	local padding = 13
	local w = 12
	local h = 211
	local bgc = Color( 10, 10, 10, 150 )
	local inc = Color( 30, 30, 30, 200 )
	local plystamina = LocalPlayer():GetStamina() or 100
	
	staminasmooth = math.Approach( staminasmooth, plystamina*10, 100 * FrameTime() )

	local offset = 103
	local percent = staminasmooth / 1000
	local y = h * percent

	draw.RoundedBoxEx(4, offset + padding, ScrH() - h, w, h, Color(10, 10, 10, 150), false, true, false, true)

	draw.RoundedBoxEx(4, offset + padding, ScrH() - y, w, h, Color(120, 120, 50, 255), true, true, false, true)

	if GUI_ShowHUDLabels > 0 then
		draw.SimpleText( plystamina, "char_title14", offset + padding + w/2, ScrH() - 10, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))	
	end
end

local weightmat = Material("cyb_mat/cyb_backpack.png", "smooth")
local radsmooth = 0
local radTimer = false
local function DrawStatusEffects()
	local w = 48
	local h = 48
	local padding = 203
	local y = ScrH() - 35
	local color = Color( 255, 100, 0, 255 )
	local boxcolor = Color(10, 10, 10, 150)

	if !shownRadWarning then
		if GetRadiationValue() > 0 && LocalPlayer():GetInRadZone() then
			draw.RoundedBox( 6, ScrW()/2 - 200, ScrH()/2 - 400, 400, 80, Color(0, 0, 0, 150 ) )
			draw.DrawText("RADIATION WARNING", "char_title", ScrW()/2, ScrH()/2-400, Color(255, 0, 0, 255),TEXT_ALIGN_CENTER)										
			draw.DrawText("Leave the area as soon as possible!", "char_options1", ScrW()/2, ScrH()/2-350, Color(150, 150, 150, 255),TEXT_ALIGN_CENTER)	

			if !radTimer then
				timer.Simple(5, function() shownRadWarning = true radTimer = false end)
			end
		end
	end
	if !LocalPlayer():GetInRadZone() then
		shownRadWarning = false
	end

	radsmooth = math.Approach( radsmooth, LocalPlayer():GetRadiation(), 50 * FrameTime() )

	if radsmooth > 25 then
		util.ScreenShake( Vector( 0, 0, 0 ), 0.3, 5, 1, 0 )
		draw.RoundedBox( 0, 0, 0, ScrW(), ScrH(), Color(0, 40, 0, math.Clamp( radsmooth*2, 0, 150 ) ) )
	end

	if LocalPlayer():GetFreshSpawn() > CurTime() then 
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)

		render.SetMaterial( hp_bg )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w-28, h,
	        Color( Pulsate(0.5)*40, Pulsate(0.5)*40, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    local countdown = " ("..math.Round(LocalPlayer():GetFreshSpawn() - CurTime()).."s)"
		if math.Round(LocalPlayer():GetFreshSpawn() - CurTime()) <= 0 then
			countdown = ""
		end

	    draw.SimpleText( "FS", "char_title14", padding+24, y-h/2+22, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	    draw.SimpleText( countdown, "char_title14", padding+24, y-h/2+36, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	    AnyStatus = true

		padding = padding + 70
	end


	if LocalPlayer():GetPVPTime() > CurTime() then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( hp_bg )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w-28, h,
	        Color( Pulsate(0.5)*40, Pulsate(0.5)*10, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    local szcountdown = " ("..math.Round(LocalPlayer():GetPVPTime() - CurTime()).."s)"
		if math.Round(LocalPlayer():GetPVPTime() - CurTime()) <= 0 then
			szcountdown = ""
		end

	    draw.SimpleText( "PVP", "char_title14", padding+24, y-h/2+22, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	    draw.SimpleText( szcountdown, "char_title14", padding+24, y-h/2+36, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	    AnyStatus = true
	    
		padding = padding + 70
	end

	if GetRadiationValue() > 0 then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( thirstmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*10, Pulsate(0.5)*80, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    draw.SimpleText( GetRadiationValue().. " rads", "char_title14", padding + w/2, y - h/2 + 26, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))

	    AnyStatus = true
	    
		padding = padding + 70
	end

	if ( GetHungerValue() >= 700 && GetThirstValue() >= 700 ) then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)

		render.SetMaterial( thirstmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( 50, 50, 200, 255 ),
	        -90
	    )

		render.SetMaterial( hungermat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( 50, 200, 50, 255 ),
	        -90
	    )

	    render.SetMaterial( healthmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w/2, h/2,
	        Color( 140, 50, 50, 255 ),
	        -90
	    )

	    AnyStatus = true
	    
		padding = padding + 70
	elseif ( GetHungerValue() >= 500 && GetThirstValue() >= 500 ) then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		
		render.SetMaterial( thirstmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( 25, 25, 100, 255 ),
	        -90
	    )

		render.SetMaterial( hungermat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( 25, 100, 25, 255 ),
	        -90
	    )

	    render.SetMaterial( healthmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w/2, h/2,
	        Color( 140, 50, 50, 255 ),
	        -90
	    )
	    
	    AnyStatus = true
	    
		padding = padding + 70
	end

	if GetHungerValue() <= 250 then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( hungermat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*10, Pulsate(0.5)*80, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    AnyStatus = true
	    
		padding = padding + 70
	end

	if GetThirstValue() <= 250 then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( thirstmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*10, Pulsate(0.5)*10, Pulsate(0.5)*80, 240 ),
	        -90
	    )

	    AnyStatus = true
	    
		padding = padding + 70
	end

	if LocalPlayer():GetBleed() then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( thirstmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*40, Pulsate(0.5)*10, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    AnyStatus = true
	    
		padding = padding + 70
	end

	if LocalPlayer():GetSick() then
		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)
		render.SetMaterial( healthmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*10, Pulsate(0.5)*40, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    AnyStatus = true

		padding = padding + 70
	end

	if ( TotalWeight or 0 ) >= LocalPlayer():GetWeightMax() then

        local perc = ( TotalWeight / LocalPlayer():GetWeightMax() ) * 100

		draw.RoundedBoxEx(4, padding-5, y-h/2-5, w+10, h+10, boxcolor, true, true, true, true)		
		render.SetMaterial( weightmat )
		render.DrawQuadEasy( Vector( padding + w/2, y,0),
	        Vector(0,0,-1),
	        w, h,
	        Color( Pulsate(0.5)*200, Pulsate(0.5)*10, Pulsate(0.5)*10, 240 ),
	        -90
	    )

	    draw.SimpleText( math.Round( perc, 0 ).. " %", "char_title14", padding + w/2, y - h/2 + 36, Color( 200, 200, 200, 255 ), 1, 1, 0.5, Color( 0, 0, 0, 255 ))

	    AnyStatus = true
	    
		padding = padding + 70
	end

end

function ShowTicker()

end

local scr_dmg = Material("cyb_mat/screendamage.png")
function DrawScreenDamage(frac)

	local scrW, scrH = ScrW(), ScrH();
	local rfrac = 1-frac
	--print(rfrac)

	surface.SetDrawColor(255, 255, 255, math.Clamp(255 * frac, 0, Pulsate(0.5)*200));
	surface.SetMaterial(scr_dmg);
	surface.DrawTexturedRect(0, 0, scrW, scrH);

	if frac > 0.75 && ( LocalPlayer():Alive() or LocalPlayer():GetBleedingOut() ) then

		if ( nextfade or 0 ) < CurTime() then
			nextfade = CurTime() + math.random(4, 7)

			LocalPlayer():EmitSound("ambient/voices/cough"..math.random(1,3)..".wav")
			LocalPlayer():ScreenFade( SCREENFADE.IN, Color( 200, 0, 0, 128 ), 0.3, 0 )
		end

	end

	drawBlurAt(0, 0, scrW, scrH, (Pulsate(0.5)*rfrac)*20)


end;


function GM:HUDPaint( )
	local SW,SH = ScrW(),ScrH()

	DrawVignette()

	local vj = hook.GetTable()["HUDPaint"]["VJ_Controller"]
	if vj != nil then 
		local w, h = 350, 70

		draw.RoundedBox(0,SW/2 - w/2,SH - 190,w,h,Color( 0,0, 0, 200 ))

		local text = "YOU ARE DEAD"


		draw.DrawText(text, "char_options", SW/2, SH-170, Color(255, 0, 0, 255),TEXT_ALIGN_CENTER)
		
		if DeathMessage == "" then return end
		local deathcountdown = math.Round(CurDeathTime - CurTime())
		local text = "Can respawn in "..deathcountdown.."!"
		if LocalPlayer():GetBleedingOut() then 
			text = "Can give up in "..deathcountdown.."!"
		end
		if deathcountdown <= 0 then
			deathcountdown = 0
			text = "Respawn [E]"
			if LocalPlayer():GetBleedingOut() then 
				text = "Give Up [E]"
			end
		end


		draw.DrawText(text, "char_title20", SW/2, SH-185, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)

		--return
	end
	
	ShowSetupErrors()
	DZ_LoadingScreen()

	if (GUI_ShowHUD == 0) then if IsValid(HotBarPanel) then HotBarPanel:Remove() end return end
	
	if LocalPlayer():Alive() then
		local hp, mhp = LocalPlayer():Health(), LocalPlayer():GetMaxHealth()
		if (hp < mhp/2) or GetHungerValue() <= 1 or GetThirstValue() <= 1 then
			DrawScreenDamage( 1 - ((1 / mhp) * (hp/2)) )
		end

		DrawStatusEffects()
	end

	CreateHotBar()

	if DZ_MENUBLUR then return end

	DrawHealth()
	DrawBlood()

	if LocalPlayer():Alive() and AliveChar then

		DrawThirst()
		DrawHunger()		
		DrawStamina()
		DrawXP()
		DrawStatusBar()
		
		--DrawProcessBar()
		
		WSWITCH:Draw(LocalPlayer())

		DrawVehicleFuel()
		DrawVehicleHealth()

		ShowSZPopup()
		ShowMissingContent()

		ShowTicker()

		GAMEMODE:HUDDrawTargetID()
	else
		if DeathMessage == "" then return end
			
		local deathcountdown = math.Round(CurDeathTime - CurTime())
		if deathcountdown <= 0 then
			deathcountdown = 0
		end
		
		local DeadBoxW = ScrW()
		local DeadBoxH = 180
		
		draw.RoundedBox(0,SW/2-(DeadBoxW/2),SH/2-(DeadBoxH/2),DeadBoxW,DeadBoxH,Color( 0,0, 0, 200 ))
		
		local text = "YOU HAVE DIED"
		if LocalPlayer():GetBleedingOut() then 
			text = "YOU ARE UNCONCIOUS!"
		end

		if LocalPlayer():GetInArena() then
			text = "DON'T WORRY! THIS IS JUST PRACTICE!"
		end

		draw.DrawText(text, "char_options", SW/2, SH/2-60, Color(255, 0, 0, 255),TEXT_ALIGN_CENTER)										
		draw.DrawText(DeathMessage, "char_options1", SW/2, SH/2, Color(150, 150, 150, 255),TEXT_ALIGN_CENTER)	
		

		local text = "[LMB] Respawn"
		if LocalPlayer():GetBleedingOut() then 
			text = "[LMB] Give Up"
		end
		if LocalPlayer():GetInArena() then
			text = "Respawning"
		end
		
		if deathcountdown > 0 then 
			text = text .. " in "..deathcountdown.."s"
		end

		if LocalPlayer():GetBleedingOut() && !LocalPlayer():GetInArena() then 
			text = text .. " | Certain death in "..LocalPlayer():GetRealHealth().."s"
		end

		draw.DrawText(text, "char_title20", SW/2, SH/2+40, Color(150, 150, 150, 255),TEXT_ALIGN_CENTER)	

		if LocalPlayer():GetInArena() then return end

		--if LocalPlayer():GetBleedingOut() then return end

		draw.DrawText("[RMB] Give Up & Control an NPC...", "char_title20", SW/2, SH/2+65, Color(150, 150, 150, 255),TEXT_ALIGN_CENTER)
	end
				
	local intAmmoInMag = 0 
	local intAmmoOutMag = 0
	if LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon():IsWeapon() then
		intAmmoInMag = LocalPlayer():GetActiveWeapon():Clip1()
		intAmmoOutMag = LocalPlayer():GetAmmoCount(LocalPlayer():GetActiveWeapon():GetPrimaryAmmoType())
	end
				
	if !IsValid(HotBarPanel) && !WSWITCH.Show and LocalPlayer():GetActiveWeapon():IsValid() && LocalPlayer():GetActiveWeapon():Clip1() >= 0 && LocalPlayer():GetActiveWeapon():GetClass() != "weapon_physcannon" then
		--draw.RoundedBox(10,SW - 201,SH -81,151,72,Color( 50, 50, 50, 255 ))
		
		draw.RoundedBox(6,SW - 200,SH -70,250,100,Color( 0, 0, 0, 200 )) -- Small Ammo Box
		
		surface.SetDrawColor(200, 200, 200,255)
		
		surface.SetTextColor(Color(255,255,255))
		surface.SetFont("AmmoType1")
		local x,y = surface.GetTextSize( intAmmoInMag )
		surface.SetTextPos(SW-140-x/2,SH-35-y/2)
		surface.DrawText( intAmmoInMag )
		
		surface.SetTextColor(Color(150,0,0))
		surface.SetFont("AmmoType2")
		local x,y = surface.GetTextSize( intAmmoOutMag )
		surface.SetTextPos(SW-90-x/2,SH-25-y/2)
		surface.DrawText( "x "..intAmmoOutMag )
	end		

end

local blur = Material("pp/blurscreen")
local amount = 10

local function drawBlur(panel)
	surface.SetMaterial(blur)
	surface.SetDrawColor(255, 255, 255)

	local x, y = panel:LocalToScreen(0, 0)
	
	for i = 0, 0.7, 0.1 do
		-- Do things to the blur material to make it blurry.
		blur:SetFloat("$blur", i * amount)
		blur:Recompute()

		-- Draw the blur material over the screen.
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
	end
end
local PANEL = {}
function PANEL:Init()

	dzTicker = self

	self:SetWide(ScrW() * (PHDayZ.ServerTickerWidthPerc or 0.7))
	self:SetPos(8, PHDayZ.ServerTickerPixelDepth or 8)
	self:SetTall(30)
	self:CenterHorizontal()

	self.i = 0
	self:SetAlpha(0)

	if (#PHDayZ.ServerTicker > 0) then
		self.changing = true
		self:AlphaTo(255, 1, 0, function()
			self.changing = false
		end)
	end
end

function PANEL:setText(text)

	text = "<font=char_title24><color= ".. PHDayZ.ServerTickerTextColor ..">"..text
	self.text = markup.Parse(text)
	self.textX = nil
end

function PANEL:Paint(w, h)
	if !PHDayZ.ServerTickerEnabled then return end

	local color = PHDayZ.ServerTickerColor or color_black
	drawBlur(self)

	surface.SetDrawColor(color)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(0, 0, 0, 75)
	surface.DrawOutlinedRect(0, 0, w, h)

	if (self.changing) then
		return
	end

	if (self.text) then
		self.textX = self.textX or w + 8
		self.text:Draw(self.textX, 4)

		self.textX = self.textX - (FrameTime() * 90)

		if (self.textX + self.text:GetWidth() < 0) then
			//self.i = self.i + 1
			self.i = math.random(1, #PHDayZ.ServerTicker)
			self.changing = true
			self:AlphaTo(0, 1, 0, function()
				self:AlphaTo(255, 1, PHDayZ.ServerTickerDelay or 5, function()
					self.changing = false
				end)
			end)

			if (PHDayZ.ServerTicker[self.i]) then
				self:setText(PHDayZ.ServerTicker[self.i])
			elseif (#PHDayZ.ServerTicker > 0) then
				//self.i = 1
				self:setText(PHDayZ.ServerTicker[1])
			end
		end
	elseif (#PHDayZ.ServerTicker > 0) then
		//self.i = 1
		self:setText(PHDayZ.ServerTicker[math.random(1, #PHDayZ.ServerTicker)])
		self.changing = true

		self:AlphaTo(255, 1, 0, function()
			self.changing = false
		end)			
	end
end
vgui.Register("dzTicker", PANEL, "DPanel")

if (IsValid(dzTicker)) then
	dzTicker:Remove()
	vgui.Create("dzTicker")
else
	if IsValid(LocalPlayer()) then
		vgui.Create("dzTicker")
	end
end

hook.Add("InitPostEntity", "dzTicker", function()
	vgui.Create("dzTicker")
end)

hook.Add("PlayerBindPress", "cancelProcessBind", function(ply, bind, pressed)
	--if pressed then return end

	if ( bind == "+attack" or bind == "+attack2" ) and DZ_IsMenuOpen() then
		return false
	end

	if bind == "+reload" && ProcessRunning == true then
		net.Start("process_DoStop")
			net.WriteString(bind)
		net.SendToServer()

		--return false
	end
end)