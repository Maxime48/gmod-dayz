-- Add your map to this table if you wish it to be easily supported. This is deliberately hard coded to prevent maps conflicting (player spawns etc) with each other.`
MapIndex = MapIndex or {}
MapIndex[1] = "rp_apocalypse"
MapIndex[2] = "gm_atomic"
MapIndex[3] = "rp_stalker"
MapIndex[4] = "rp_evocity2_v2p_fixed"
MapIndex[5] = "rp_pripyat"
MapIndex[6] = "gm_fork"
MapIndex[7] = "rp_headattackcity_v1_linux"
MapIndex[8] = "rp_stalker_new"
MapIndex[9] = "rp_pripyat_fixed"
MapIndex[10] = "gm_flatgrass"
MapIndex[11] = "rp_stalker_thatgmodzserver"
MapIndex[12] = "zs_headattackcity_v1_linux"
MapIndex[13] = "gm_boreas"
MapIndex[14] = "rp_chaos_city_v33x_03"
MapIndex[15] = "rp_ineu_valley2_v1a"
MapIndex[16] = "dayz_ghosttown"

local cur_map = string.lower( game.GetMap() )
if !table.HasValue( MapIndex, cur_map ) then
	if SERVER then
		MsgC(Color(0,255,0), "MapIndex: "..cur_map.." not in table, inserted!\n")
	end
	table.insert( MapIndex, cur_map )
end

MaleModels = {}
MaleModels[1] = {
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/male_08.mdl",
	"models/player/group01/male_09.mdl"
}

MaleModels[2] = {
	"models/player/group02/male_02.mdl",
	"models/player/group02/male_04.mdl",
	"models/player/group02/male_06.mdl",
	"models/player/group02/male_08.mdl",
}

MaleModels[3] = {
	"models/player/group03/male_01.mdl",
	"models/player/group03/male_02.mdl",
	"models/player/group03/male_03.mdl",
	"models/player/group03/male_04.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_06.mdl",
	"models/player/group03/male_07.mdl",
	"models/player/group03/male_08.mdl",
	"models/player/group03/male_09.mdl"
}

MaleModels[4] = {
	"models/player/group03m/male_01.mdl",
	"models/player/group03m/male_02.mdl",
	"models/player/group03m/male_03.mdl",
	"models/player/group03m/male_04.mdl",
	"models/player/group03m/male_05.mdl",
	"models/player/group03m/male_06.mdl",
	"models/player/group03m/male_07.mdl",
	"models/player/group03m/male_08.mdl",
	"models/player/group03m/male_09.mdl"
}

MaleModels[5] = {
	"models/player/urban.mdl",
	"models/player/gasmask.mdl",
	"models/player/riot.mdl",
	"models/player/swat.mdl"
}

MaleModels[6] = {
	"models/player/leet.mdl",
	"models/player/guerilla.mdl",
	"models/player/arctic.mdl",
	"models/player/phoenix.mdl"
}

FemaleModels = {}
FemaleModels[1] = {
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl"
}

FemaleModels[2] = {
	"models/player/group03/female_01.mdl",
	"models/player/group03/female_02.mdl",
	"models/player/group03/female_03.mdl",
	"models/player/group03/female_04.mdl",
	"models/player/group03/female_05.mdl",
	"models/player/group03/female_06.mdl"
}

FemaleModels[3] = {
	"models/player/group03m/female_01.mdl",
	"models/player/group03m/female_02.mdl",
	"models/player/group03m/female_03.mdl",
	"models/player/group03m/female_04.mdl",
	"models/player/group03m/female_06.mdl",
	"models/player/group03m/female_05.mdl"
}

FemaleModels[4] = {
	"models/player/alyx.mdl",
}