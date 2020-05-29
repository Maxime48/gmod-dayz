local root = GM.FolderName.."/gamemode/modules/menus/tabs"
if !PHDayZ.DisableStartupInfo then
	Msg("======================================================================\n")
end
for _, File in SortedPairs(file.Find(root .."/*.lua", "LUA"), true) do
	if !PHDayZ.DisableStartupInfo then
		MsgC( Color(255,0,0), "[PHDayZ] Pooling CLIENT tab: " .. File .. "\n" )
	end
	AddCSLuaFile(root .. "/" ..File)
end
if !PHDayZ.DisableStartupInfo then
	Msg("======================================================================\n")
end