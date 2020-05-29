function PMETA:GetWeightMax()
	local maxweight = self:HasPerk("perk_strongback") and PHDayZ.Player_MaxWeight*2 or PHDayZ.Player_MaxWeight
	maxweight = maxweight + self:GetAdditionalWeight()

	return maxweight
end

hook.Add("EntityTakeDamage", "QualityDegrade", function(target, dmginfo)
	local ent = dmginfo:GetAttacker()
	if not IsValid(ent) then return end
	if not ent:IsPlayer() then return end

    local wep = ent:GetActiveWeapon()
    if not IsValid(wep) then return end

    if ( ent.NextDmgCheck or 0 ) < CurTime() then -- Incase multiple bullets are fired (shotgun), we only want this to be called once.

        ent.NextDmgCheck = CurTime() + 0.05

        if wep.Base != "cw_melee_base" then return end -- just melee only for this one.

        local tab = ent.CharTable

        if WepToMats[wep:GetClass()] then return end -- stop duplicating extra loss on process (i.e. axe/pick)

        if !ent:GetInArena() && !ent:IsVIP() && tab[wep.item] && table.Count(tab[wep.item]) > 0 then
            for k, it in pairs(tab[wep.item]) do
            	local amt = math.random(3,6)
                it.quality = it.quality - amt

                if SERVER and it.quality < (PHDayZ.AlertQualityLevel or 300) then
            		if (ent.NextTipDegrade or 0) < CurTime() then
            			local name = GAMEMODE.DayZ_Items[wep.item].Name
            			ent:Tip(3, name.." condition low ["..it.quality.."] - Consider repair!", Color(255,0,0))
            			ent.NextTipDegrade = CurTime() + 10
            		end
           		end

                --MsgAll("Quality change ("..it.quality.." - "..amt..") for "..wep.item.." requires networking!\n")
                ent:UpdateChar(it.id, it.class)
                if it.quality < 100 then
                	ent:BreakItem( it.id, 1 )
                end
            end
        end
    end

end)