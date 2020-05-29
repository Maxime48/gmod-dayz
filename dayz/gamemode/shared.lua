GM.Name		= "Gmod Day-Z"
GM.Author	= "Phoenixf129"
GM.Email	= "phoenixf129@gmail.com"
GM.Website	= "https://gmoddayz.net"

DeriveGamemode( "sandbox" )

GM = GM or GAMEMODE

TEAM_NEUTRAL = 1
TEAM_SAFEZONE = -1

GROUP_BOUNTY = -1
GROUP_BANDIT = -2
GROUP_HERO = -3

TEAM_JOINING = 256

team.SetUp( TEAM_JOINING, "Loading/Creating Character", Color( 150, 150, 0, 255 ) ) 
team.SetUp( TEAM_NEUTRAL, "Neutral", Color( 150, 150, 150, 255 ) ) 
team.SetUp( GROUP_HERO, "Hero", Color( 0, 200, 0 ) ) 
team.SetUp( GROUP_BANDIT, "Bandit", Color( 255, 178, 0 ) ) 
team.SetUp( GROUP_BOUNTY, "Bounty", Color( 255, 0, 0 ) ) 

PMETA = FindMetaTable( "Player" )

concommand.Remove("gmod_undo")

if mCompass_Settings then
	if SERVER then
		resource.AddWorkshop(1452363997)
	end
	mCompass_Settings.Allow_Player_Spotting = true
	mCompass_Settings.Force_Server_Style = false
	mCompass_Settings.Style_Selected = "fortnite"

	if CLIENT then
		RunConsoleCommand("mcompass_ratio", "1.8")
		RunConsoleCommand("mcompass_yposition", "0.05")
	end
	local compassTBL = mCompass_Settings.Style[mCompass_Settings.Style_Selected]
	compassTBL.compassY = 0.05

	--mCompass_Settings.Max_Spot_Distance = mCompass_Settings.Max_Spot_Distance * 20
end

-- Events auto-dictation:

EVENT_CHRISTMAS = false
EVENT_HALLOWEEN = false

local month = os.date("%m")
local year_day = os.date("%j")

if tonumber(year_day) > 342 && tonumber(year_day) < 362 then
	EVENT_CHRISTMAS = true
	MsgAll("[PHDayZ] Detected Christmas, enabling event mode!\n")
end

if SERVER then
	resource.AddWorkshop(346465496)
end

if tonumber(year_day) > 298 && tonumber(year_day) < 311 then
	EVENT_HALLOWEEN = true
	MsgAll("[PHDayZ] Detected Halloween, enabling event mode!\n")
	if SERVER then
		--resource.AddWorkshop(346465496)
	end
end