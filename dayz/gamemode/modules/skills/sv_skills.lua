util.AddNetworkString("net_SkillGain")
util.AddNetworkString("net_SkillXP")
local PMETA = FindMetaTable("Player")

hook.Remove("DZ_OnXPAward", "GiveSkillXP")

function PMETA:UpdateSkills(ignoresql)
   end

function PMETA:SaveSkills()
end

function PMETA:TakeSkillPoints(amt)
end

function PMETA:TakeSkill(typ, amt)
end

function PMETA:ResetSkillsAndPoints()
end

function PMETA:ResetSkillPoints()
end

function PMETA:ResetSkills()
end

function PMETA:AssignSkillPoint(typ)
end

function PMETA:GiveSkillPoints(amt)
end

function PMETA:HasSkillPoint()
end

function PMETA:GainSkill(id)
end

-- 1 = Intelligence
-- 2 = Endurance
-- 3 = Dexterity
-- 4 = Strength
function PMETA:CheckSkills(rest)
end