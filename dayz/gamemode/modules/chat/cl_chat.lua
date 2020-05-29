net.Receive("GlobalChat", function(len)
	local ChatPlayer = player.GetByID( net.ReadUInt(32) )
	
	if !ChatPlayer:IsValid() then return end
	
	chat.PlaySound()
	
	local color = Color(150, 0, 0)
	if ChatPlayer:IsAdmin() then
		color = Color(0, 255, 0)
		if PHDayZ.AdminsHide then color = Color(0, 200, 250) end
	elseif ChatPlayer:IsVIP() and PHDayZ.ShowVIPColors then
		color = Color(0, 200, 250) 
	end

	if ChatPlayer:Team() != TEAM_NEUTRAL then
		color = team.GetColor( ChatPlayer:Team() ) or Color(255, 150, 50)
	end
	
	chat.AddText( color, ChatPlayer, Color( 125, 125, 125 ), " [Global]", Color( 200,200,200 ), ": " .. net.ReadString())
end)

net.Receive("GroupChat", function(len)
	local ChatPlayer = player.GetByID( net.ReadUInt(32) )
	
	if !ChatPlayer:IsValid() then return end
	
	chat.PlaySound()
	
	local color = Color(150, 0, 0)
	if ChatPlayer:IsAdmin() then
		color = Color(0, 255, 0)
		if PHDayZ.AdminsHide then color = Color(0, 200, 250) end
	elseif ChatPlayer:IsVIP() and PHDayZ.ShowVIPColors then
		color = Color(0, 200, 250) 
	end
	
	local groupname = team.GetName( ChatPlayer:Team() ) or "Unknown"
	local groupcolor = team.GetColor( ChatPlayer:Team() ) or Color(255, 150, 50)

	chat.AddText( groupcolor, ChatPlayer, groupcolor, " [Group]", Color( 200,200,200 ), ": " .. net.ReadString())
end)

net.Receive("MeChat", function(len)
	local ChatPlayer = player.GetByID( net.ReadUInt(32) )
	local dist = net.ReadUInt(32)
	if !ChatPlayer:IsValid() then return end
		
	chat.PlaySound()
		
	local color = Color(150, 0, 0)
	if ChatPlayer:IsAdmin() then
		color = Color(0, 255, 0)
		if PHDayZ.AdminsHide then color = Color(0, 200, 250) end
	elseif ChatPlayer:IsVIP() and PHDayZ.ShowVIPColors then
		color = Color(0, 200, 250) 
	end

	if ChatPlayer:Team() != TEAM_NEUTRAL then
		color = team.GetColor( ChatPlayer:Team() ) or Color(255, 150, 50)
	end

	chat.AddText( color, ChatPlayer, color, " "..net.ReadString() )
end)

net.Receive("LocalChat", function(len)
	local ChatPlayer = player.GetByID( net.ReadUInt(32) )
	local dist = net.ReadUInt(32)
	
	if !ChatPlayer:IsValid() then return end
		
	chat.PlaySound()
		
	local color = Color(150, 0, 0)
	if ChatPlayer:IsAdmin() then
		color = Color(0, 255, 0)
		if PHDayZ.AdminsHide then color = Color(0, 200, 250) end
	elseif ChatPlayer:IsVIP() and PHDayZ.ShowVIPColors then
		color = Color(0, 200, 250) 
	end
	local amt, distance = math.Round(dist * 1.905 / 100), ""
	if ChatPlayer != LocalPlayer() then
		distance = " - "..amt.."m"
	end

	if ChatPlayer:Team() != TEAM_NEUTRAL then
		color = team.GetColor( ChatPlayer:Team() ) or Color(255, 150, 50)
	end

	chat.AddText( color, ChatPlayer, Color( 255, 255, 255 ), " [Local"..distance.."]", Color( 200,200,200 ), ": " .. net.ReadString())
end)

net.Receive("TradeChat", function(len)
	local ChatPlayer = player.GetByID( net.ReadUInt(32) )
	
	if !ChatPlayer:IsValid() then return end
		
	chat.PlaySound()
		
	local color = Color(150, 0, 0)
	if ChatPlayer:IsAdmin() then
		color = Color(0, 255, 0)
		if PHDayZ.AdminsHide then color = Color(0, 200, 250) end
	elseif ChatPlayer:IsVIP() and PHDayZ.ShowVIPColors then
		color = Color(0, 200, 250) 
	end

	chat.AddText( color, ChatPlayer, Color( 255, 150, 50 ), " [Trade]", Color( 200,200,200 ), ": " .. net.ReadString())
end)

local receivers
local function GetChatReceipients()
	--local dist = math.Round(PHDayZ.MaxChatDistance / 1.905 * 100) -- back to units from meters

	receivers = {}
	for k, v in pairs(player.GetAll()) do
		if !IsValid(v) or v == LocalPlayer() or !v:Alive() or v:Crouching() or (prone and v:IsProne()) or v:GetMoveType() == MOVETYPE_NOCLIP then continue end

		local dir = ( v:GetPos() - LocalPlayer():GetPos() ):GetNormal();
		
		local canSee = dir:Dot( LocalPlayer():GetForward() ) > 0.6 -- -1 is directly opposite, 1 is self:GetForward(), 0 is orthogonal

        if !v:IsLineOfSightClear( LocalPlayer() ) && !v:InVehicle() then continue end -- you cant see me :D

        if !canSee then continue end
		local dist = v:GetPos():Distance( LocalPlayer():GetPos() )
		local dist_m = math.Round(dist * 1.905 / 100) -- back to units from meters
		if dist_m > PHDayZ.MaxChatDistance then continue end

		table.insert(receivers, v)
	end
end
hook.Add("Think", "GetChatReceipients", GetChatReceipients)

local function DrawOthers()
	if not receivers then return end

	local x, y = chat.GetChatBoxPos()
	y = y - 40

	local receiversCount = #receivers
    -- No one hears you

    local istyping = false
    if LocalPlayer().IsUsingVoice or LocalPlayer():IsTyping() or (IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName( ) == "TextEntry") or gui.IsGameUIVisible() or gui.IsConsoleVisible()  then istyping = true end

    if !istyping then return end
    draw.WordBox(2, x, y - (receiversCount * 21), "Who can hear you:", "char_title18", Color(0,0,0,160), Color(0,255,0,255))

    if receiversCount == 0 then
        draw.WordBox(2, x, y+21, "No idea...", "char_title18", Color(0,0,0,160), Color(255,0,0,255))
        return
    -- Everyone hears you
    elseif receiversCount == player.GetCount() - 1 then
        draw.WordBox(2, x, y - (receiversCount * 21) + 21, "EVERYONE :D", "char_title18", Color(0,0,0,160), Color(0,255,0,255))
        return
    end

    local rp = 0
    for i = 1, receiversCount, 1 do
        if not IsValid(receivers[i]) then
            receivers[i] = receivers[#receivers]
            receivers[#receivers] = nil
            continue
        end

        rp = rp + 1

        local name = receivers[i]:Nick()

        --local dist = math.Round(receivers[i][2] * 1.905 / 100)
        draw.WordBox(2, x, y - (i - 1) * 21, name, "char_title18", Color(0, 0, 0, 160), Color(255, 255, 255, 255))
    end

    if rp == 0 then
        draw.WordBox(2, x, y+21, "No idea...", "char_title18", Color(0,0,0,160), Color(255,0,0,255))
   	end

end
hook.Add("HUDPaint", "drawPlayerChats", DrawOthers)

// Code based on Garry's Base Gamemode
local config = {}
local PANEL = {}
PlayerVoicePanels = PlayerVoicePanels or {}

function GM:PlayerStartVoice( ply )
	if ply == LocalPlayer() then
        ply.IsUsingVoice = true
    end

	if ( !IsValid( g_VoicePanelList ) ) then return end
	
	-- There'd be an exta one if voice_loopback is on, so remove it.
	--GAMEMODE:PlayerEndVoice( ply )

	if IsValid(ply) then
		if ply:Alive() then
	    	ply:AnimPerformGesture(ACT_GMOD_IN_CHAT)
	   	end
	end

	if ( IsValid( PlayerVoicePanels[ ply ] ) ) then

		if ( PlayerVoicePanels[ ply ].fadeAnim ) then
			PlayerVoicePanels[ ply ].fadeAnim:Stop()
			PlayerVoicePanels[ ply ].fadeAnim = nil
		end

		PlayerVoicePanels[ ply ]:SetAlpha( 255 )

		return

	end

	if ( !IsValid( ply ) ) then return end

	local pnl = g_VoicePanelList:Add( "VoiceNotify" )
	pnl:Setup( ply )
	
	PlayerVoicePanels[ ply ] = pnl

end

local function VoiceClean()

	for k, v in pairs( PlayerVoicePanels ) do
	
		if ( !IsValid( k ) ) then
			GAMEMODE:PlayerEndVoice( k )
		end
	
	end

end
timer.Create( "VoiceClean", 10, 0, VoiceClean )

function GM:PlayerEndVoice( ply, no_reset )

	if ply == LocalPlayer() then
        ply.IsUsingVoice = false
    end

	if ( IsValid( PlayerVoicePanels[ ply ] ) ) then

		if ( PlayerVoicePanels[ ply ].fadeAnim ) then return end

		PlayerVoicePanels[ ply ].fadeAnim = Derma_Anim( "FadeOut", PlayerVoicePanels[ ply ], PlayerVoicePanels[ ply ].FadeOut )
		PlayerVoicePanels[ ply ].fadeAnim:Start( 2 )

	end

end

/*
 * CONFIG
 *       You can change stuff here
 */

config.BarColor = {
    [0] = Color(255, 0, 0), -- Over 0% -> Red
    [25] = Color(255, 255, 0), -- Over 25 % -> Yellow
    [50] = Color(0, 255, 0) -- Over 50% -> Green
}

-- Default: 40
config.BarHeightMultiplier = 40
-- If you want it faster, increase the rate
-- If you want it slower, decrease the rate
-- Default: 0.1
config.UpdateRate = 0.1
-- If you want more bars, decrease the value
-- and increase the Bar Count
-- Default: 5
config.SingleBarWidth = 5
-- How many bars do you want to be displayed?
-- Default: 30 (Perfect setting with bar width 5)
config.BarCount = 30
-- Distance between 2 Bars
-- Default: 2
config.BarDistance = 2
-- Background Color of the bar itself
-- This HAS to be a function
-- Default: Black
config.BackgroundColor = function(panel, ply)
    -- Tip if you have a TTT server
    -- This will normalize the background color of the panel (Green for Inno, Blue for Detective and Red in private Traitor Voice Channel)
    -- Change the line under me to: return panel.Color
    return Color(0,0,0)
end
-- Color of the name
-- This HAS to be a function
-- Default: White
config.NameColor = function(panel, ply)
    return Color(255,255,255)
end
-- Font of the name
-- This HAS to be a function
-- Default: GModNotify
config.NameFont = function(panel, ply)
    return "GModNotify"
end
-- I highly recommend this stays turned off
-- for example: If your gamemode draws a box, it will draw over the bar and stuff
-- That would not be good
-- Default: false (you should keep it that way)
config.CallGamemodePaintFunc = false
-- You have to test this function out on your gamemode
-- This sets wether the gamemode paint function should be called before (true) or after (false) my paint function
-- Again, test it out yourself
-- NOTE: If you have set config.CallGamemodePaintFunc to false, this will be ignored!
-- Default: false
config.CallGamemodePaintFuncFirst = false
/* 
 * DO NOT EDIT ANYTHING FROM HERE !
 */
function PANEL:Init()
	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:Dock(LEFT)
	self.Avatar:SetSize(32, 32)
	self.Color = Color(0,0,0)
	self:SetSize(250, 32 + 8)
	self:DockPadding(4, 4, 4, 4)
	self:DockMargin(2, 2, 2, 2)
	self:Dock(BOTTOM)
    
    self.Past = {}
end
function PANEL:Setup(ply)  
	self.ply = ply
	--self.LabelName:SetText(ply:Nick())
	self.Avatar:SetPlayer(ply)
	
	self.Color = team.GetColor(ply:Team())
    timer.Create("PanelThink" .. ply:UniqueID(), config.UpdateRate, 0, function()
        if self:Valid() then
            if self.UpdatePast ~= nil then
                self:UpdatePast()
            end
        end
    end)
	
	self:InvalidateLayout()
    
    -- wow.. This is for the shitty gamemodes that overwrite my paint function -.-       
    timer.Simple(0, function()
        if self ~= nil then
            if self:Valid() then
                local PaintFunc = self.Paint
                
                self.Paint = function(s, w, h)
                    if s ~= nil then
                        if s:Valid() then
                            -- Idiots
                            if PaintFunc ~= nil and config.CallGamemodePaintFunc and config.CallGamemodePaintFuncFirst == true then
                                PaintFunc(s,w,h)
                            end
                            
                            s:VVPaint(w, h)
                            
                            -- Idiots
                            if PaintFunc ~= nil and config.CallGamemodePaintFunc and config.CallGamemodePaintFuncFirst == false then
                                PaintFunc(s,w,h)
                            end
                        end
                    end
                end
            end
        end
    end)
end
function PANEL:UpdatePast()
    if self ~= nil and self:Valid() && IsValid(self.ply) then
        table.insert(self.Past, self.ply:VoiceVolume())
        
        local len = #self.Past
        if len > (config.BarCount-1) then
            table.remove(self.Past, 1)
        end
    end
end 
function PANEL:GetBarColor(p)
    local barcolor = Color(0,0,0)
   
    for i,v in pairs(config.BarColor) do
        if p > i then
            barcolor = v
        end
    end
   
    return barcolor
end
function PANEL:VVPaint(w, h)
	if not IsValid(self.ply) or not self:Valid() then return end
	draw.RoundedBox(4, 0, 0, w, h, config.BackgroundColor(self, self.ply))
    
    for i,v in pairs(self.Past) do
        local barh = v * config.BarHeightMultiplier
        local barcolor = self:GetBarColor(v * 100)
        surface.SetDrawColor(barcolor)
        surface.DrawRect(35 + i * (config.BarDistance + config.SingleBarWidth), 36 - barh, config.SingleBarWidth, barh)
    end
    
    -- Draw Name
    surface.SetFont(config.NameFont(self, self.ply))
    local w,h = surface.GetTextSize(self.ply:Nick())
    
    surface.SetTextColor(config.NameColor(self, self.ply))
    surface.SetTextPos(40, 40/2 - h/2)
    surface.DrawText(self.ply:Nick())
end
function PANEL:Think()
    if self:Valid() then
        if self.fadeAnim then
            self.fadeAnim:Run()
        end
    end
end
function PANEL:FadeOut(anim, delta, data)	
	if anim.Finished then	
		if IsValid(PlayerVoicePanels[self.ply]) then
			PlayerVoicePanels[self.ply]:Remove()
			PlayerVoicePanels[self.ply] = nil
			return
		end		
        
        return 
    end
			
	self:SetAlpha(255 - (255 * (delta*2)))
end
derma.DefineControl("VoiceNotify", "", PANEL, "DPanel") 
-- Support for the shitty gamemodes that like creating there own voice panel -.-
local function HookVoiceVGUI()
    timer.Simple(0, function()
        g_VoicePanelList.OriginalAdd = g_VoicePanelList.Add
        g_VoicePanelList.Add = function(s, what)
            return g_VoicePanelList.OriginalAdd(s, "VoiceNotify")
        end
    end)
end
hook.Add("InitPostEntity", "VVHookVoiceVGUI", HookVoiceVGUI)