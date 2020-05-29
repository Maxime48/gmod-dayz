AddCSLuaFile()
GM = GM or GAMEMODE

function DayZ_LoadSkill(filepath, filename, category)
end

function DayZ_IncludeSkillFolder(folder)
end

hook.Add("PostGamemodeLoaded", "DayZ_LoadSkills", function()
    GAMEMODE.DayZ_Skills = {}
end)


hook.Add("OnReloaded", "DayZ_LoadSkills", function()
    GAMEMODE.DayZ_Skills = {}
end)