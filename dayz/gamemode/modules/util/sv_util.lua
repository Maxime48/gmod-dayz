local EMETA = FindMetaTable( "Entity" )
local PMETA = FindMetaTable( "Player" )

---- Weapon switching
local function ForceWeaponSwitch(ply, cmd, args)
   -- Turns out even SelectWeapon refuses to switch to empty guns, gah.
   -- Worked around it by giving every weapon a single Clip2 round.
   -- Works because no weapon uses those.
   local wepname = args[1]
   local wep = ply:GetWeapon(wepname)
   if IsValid(wep) then
      -- Weapons apparently not guaranteed to have this
      if wep.SetClip2 then
         wep:SetClip2(1)
      end
	  -- Hacky i know, but it fixes the long known source bug that doesn't allow you to equip empty weapons (nor have hooks run for them).
	  if ply:GetAmmoCount(wep:GetPrimaryAmmoType()) < 1 then
	    if wep.Primary and wep.Primary.AmmoItem then
			--ply:GiveItem(wep.Primary.AmmoItem, 1, true)
			--timer.Simple(0, function() ply:TakeItem(wep.Primary.AmmoItem, 1, true) end)
		end
	  end
      ply:SelectWeapon(wepname)
   end
end
concommand.Add("wepswitch", ForceWeaponSwitch)

DZ_LastInsert = DZ_LastInsert or {}
function DZ_GetLastInsert(t_n, force)

	local id = 1

	if DZ_LastInsert[t_n] then
		id = DZ_LastInsert[t_n]
		return id
	end

	PLib:RunPreparedQuery({ sql = "SELECT MAX(id) FROM "..t_n..";", 
    callback = function( data )
    	if data then
	    	data = data[1]
	        DZ_LastInsert[t_n] = data["MAX(id)"] + 1
	    end
    end })

	return id
end

local function DZ_UpdateInsertCache( inc, t_n )
	if !t_n or !inc then return end
	inc = inc + 1 -- next

	DZ_LastInsert[t_n] = inc -- this is just to make it look nicer
end
hook.Add("PLib_LastInsert", "keep_em_updated", DZ_UpdateInsertCache)

function DZ_LoadInserts()
	DZ_GetLastInsert("players")
	DZ_GetLastInsert("players_inventory")
	DZ_GetLastInsert("players_character")
	DZ_GetLastInsert("players_bank")
end
hook.Add("DZ_FullyLoaded", "LoadLastInserts", DZ_LoadInserts)

function DZ_AddPredictedInsert(t_n)
	DZ_LastInsert[t_n] = DZ_LastInsert[t_n] or 0

	DZ_LastInsert[t_n] = DZ_LastInsert[t_n] + 1
end

function SpawnPlant(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end

	ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))

	local planttype = args[1] or "item_food2"
	local tr = ply:GetEyeTrace()

	local ent = ents.Create("dz_plant")
	ent:SetPos( tr.HitPos )
	ent.Creator = ply
	ent.FruitType = planttype
	ent:SetRarity( args[2] or 1 )
	ent:Spawn()
	ply.plantHitPos = nil
end
concommand.Add("dz_makeplant", SpawnPlant)

function DZ_MakePlant(ply, item, planttype, it)
	if not DZ_CanPlant(ply) then return true end

	local rarity = 1

	if it then
		rarity = it.rarity or 1
	end

	ply:EmitSound(Sound("npc/vort/claw_swing"..math.random(1,2)..".wav"))

	local time = 5

	if ply:HasPerk("perk_fancyfarmer") then
		time = time / 2
	end

	if not planttype then 
		ply:DoProcess(item, "Planting", time, "npc/vort/claw_swing"..math.random(1,2)..".wav")
		return 
	end

	local ent = ents.Create("dz_plant")
	ent:SetPos( ply.plantHitPos )
	ent.Creator = ply
	ent.FruitType = planttype
	ent:SetRarity( rarity )
	ent:Spawn()
	ply.plantHitPos = nil

	--ply:TakeItem(item, 1)
end

function DZ_CanPlant(ply)
	if ply:GetSafeZone() or ply:GetSafeZoneEdge() or ply:GetInArena() then 
		ply:Tip(3, "You cannot do this in the safezone/arena!") 
		return false 
	end

	local trace = {}
	trace.start = ply:GetShootPos()
	trace.endpos = trace.start + (ply:GetAimVector() * 200)
	--trace.mask = bit.bor( MASK_WATER, MASK_CURRENT )
	trace.filter = ply

	local tr = util.TraceLine(trace)

	if (not tr.HitWorld) or ( tr.MatType != MAT_DIRT and tr.MatType != MAT_GRASS and tr.MatType != MAT_SAND and tr.MatType != MAT_SNOW ) then
		ply:Tip(3, "You need to be aiming at grass/dirt!") 
		return false
	end

	ply.plantHitPos = ply.plantHitPos or tr.HitPos

	return true
end

function StopTransmit( ent, ply, bool )
	if !ent or !ply then return end
	if !IsValid( ent ) or !IsValid( ply ) then return end
	
	if bool == nil then bool = false end
	
	for k,v in pairs( ent:GetChildren() ) do 
		v:SetTransmitWithParent( true ) 
	end
	
	ent:SetPreventTransmit( ply, bool )
end

function PMETA:GiveBankSlots( amount )
	self:SetNWInt( "extraslots", self:GetNWInt("extraslots") + amount )
end

DZ_IgnitedEntities = DZ_IgnitedEntities or {}
EMETA.oIgnite = EMETA.oIgnite or EMETA.Ignite
function EMETA:Ignite(time)
	if !IsValid(self) then return false end

	for k, v in pairs(DZ_IgnitedEntities) do
		if !IsValid(v) or !v:IsOnFire() then DZ_IgnitedEntities[k] = nil end
	end

	table.insert(DZ_IgnitedEntities, self)

	self:oIgnite(time)
end

hook.Add( "SetupPlayerVisibility", "AddRTCamera", function( pPlayer, pViewEntity )
	-- Adds any view entity
	if ( pViewEntity:IsValid() ) then
		AddOriginToPVS( pViewEntity:GetPos() )
	end
end )

outilEffect = outilEffect or util.Effect 
function util.Effect(effectName, effectData, allowOverride, ignorePrediction) // i had to override this, broken networking as of 2/11/18
	outilEffect(effectName, effectData, true, true)
end 

hook.Add("PersistenceSave", "save_later", function(nosave)
	if timer.Exists("persistence_save") then
		if !nosave then
			MsgAll("[PHDayZ] Cancelling autosave, saved by admin..\n")
		end
		timer.Destroy("persistence_save")
	end
end)

EMETA.oSetPersistent = EMETA.oSetPersistent or EMETA.SetPersistent
function EMETA:SetPersistent(bool, nosave)
	if !IsValid(self) then return end

	self:oSetPersistent(bool)

	if nosave then return end
	MsgAll("[PHDayZ] Admin changed Persistence... Auto-saving in 5 minutes unless saved beforehand..\n")

	timer.Create("persistence_save", 300, 1, function()
		PrintMessage(HUD_PRINTTALK, "[PHDayZ] Persistence Auto-Save override... forcing save... don't worry, this isn't a crash!")
		timer.Simple(1, function() hook.Run( "PersistenceSave", nosave ) end)
	end)
	--print("[PHDayZ] Persistence override... forcing save!")
	--hook.Run( "PersistenceSave" )
end

PMETA.oRemoveAmmo = PMETA.oRemoveAmmo or PMETA.RemoveAmmo
function PMETA:RemoveAmmo(amt, ammotype)

    local aItemTable, aItemKey = GAMEMODE.Util:GetItemByAmmoType( ammotype )

    local it = self.ammoUsed[aItemKey]
    if !it then return false end

    self:TakeItem( it.id, amt )
end

PMETA.oSetAmmo = PMETA.oSetAmmo or PMETA.SetAmmo
function PMETA:SetAmmo(amt, ammotype)

    local aItemTable, aItemKey = GAMEMODE.Util:GetItemByAmmoType( ammotype )

    local it = self.ammoUsed[aItemKey]
    if !it then return false end

    self:SetItem( it.id, amt )
end

hook.Add( "PersistenceLoad", "PersistenceLoad", function( name ) // hacky override. 

	local file = file.Read( "persist/" .. game.GetMap() .. "_" .. name .. ".txt" )
	if ( !file ) then return end

	local tab = util.JSONToTable( file )
	if ( !tab ) then return end
	if ( !tab.Entities ) then return end
	if ( !tab.Constraints ) then return end

	local Ents, Constraints = duplicator.Paste( nil, tab.Entities, tab.Constraints )

	for k, v in pairs( Ents ) do
		v:SetPersistent( true, true )
	end

end )

local datatypes = {}
datatypes[1] = "shop.txt"
datatypes[2] = "admin.txt"
datatypes[3] = "loot.txt"
datatypes[4] = "death.txt"
datatypes[5] = "possibleexploits.txt"
datatypes[6] = "crafting.txt"
datatypes[7] = "bank.txt"
datatypes[8] = "inven.txt"

function DzLog(log, text)
	file.CreateDir("dayz/log")
	
	local xfile = datatypes[log] or "unknown.txt"
	
	if not file.Exists("dayz/log/"..xfile, "DATA") then
		file.Write("dayz/log/"..xfile)
	end
	file.Append("dayz/log/"..xfile, "["..os.date( "%X - %d/%m/%Y").."] "..text.."\n")

	if log == 5 then
		print(text)
	end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ItemDestroyed(pos)
	local effectdata = EffectData()
	effectdata:SetOrigin( pos )

	util.Effect( "cball_explode", effectdata )
end

function DZ_CanLootbox(ply, item, rarity)
	local keypads = GAMEMODE.Util:GetItemIDsByClass(ply.InvTable, "item_keypad")

	local keypadfound = false
	for _, item in pairs(keypads) do
		if item.rarity == rarity then
			keypadfound = item.id
		end
	end

	if !keypadfound then 
		ply:Tip(3, "You need a "..GetRarity(rarity).t.." Keypad to unlock this!", Color(255,255,0,255))
		return false
	end

	return keypadfound
end

function MakeConfetti(ply)

	local effectdata = EffectData()
	effectdata:SetOrigin( ply:GetPos() + Vector(0,0,80) )
	local r, g, b = math.random(1,255), math.random(1,255), math.random(1,255)

	effectdata:SetStart( Vector( r, g, b ) )
	util.Effect( "balloon_pop", effectdata )

end

function DZ_DoLootbox(ply, item, rarity)

	local keypadfound = DZ_CanLootbox(ply, item, rarity)
	if !keypadfound then 

		return true 
	end

	local item_gain = "garrysmod/balloon_pop_cute.wav"

	local weps_tab = {}
	local noweps_tab = {}
	for k, v in pairs( GAMEMODE.DayZ_Items ) do
		if v.SpawnChance < 1 or v.Attachment or v.Tertiary then continue end

		if v.Weapon && !v.Tertiary then
			weps_tab[k] = v
			continue
		end
		if v.Category != "perks" && v.Category != "lootboxes" then
			noweps_tab[k] = v
		end
	end

	local gen_rarity = GenerateRarity()
	if gen_rarity < rarity then gen_rarity = rarity end
	local orig_text = GetRarity(rarity).t
	local text = GetRarity(gen_rarity).wep

	local ItemTable, ItemKey = table.Random( weps_tab )

	ply:EmitSound(item_gain)
	MakeConfetti(ply)
	
	ply:GiveItem(ItemKey, 1, true, 800, gen_rarity, nil, nil, true )

	MsgAll(ply:Nick().." opened a "..orig_text.." Lootbox and received: "..text.." ".. ItemTable.Name .."!\n")

	for i=1, 3 do
		timer.Create(ply:EntIndex().."_Lootbox_Slow_"..i, i, 1, function()
			if !IsValid(ply) then return end -- tough shit if they left here.

			local ItemTable, ItemKey = table.Random( noweps_tab )

			ply:EmitSound(item_gain)

			local amount = 1
			if ItemTable.AmmoType then
				amount = 100 * rarity
				rarity = 1
				MsgAll(ply:Nick().." received: x"..amount.." ".. ItemTable.Name .."!\n")
			elseif ItemTable.Category == "food" or ItemTable.Category == "drinks" or ItemTable.Category == "resources" or ItemTable.Category == "medical" then
				amount = math.random( 1, 3+(rarity*2) )
				MsgAll(ply:Nick().." received: x"..amount.." ".. ItemTable.Name .."!\n")
			elseif ItemTable.Category == "parts" then
				amount = math.random( 1, 3+rarity )
				MsgAll(ply:Nick().." received: x"..amount.." ".. ItemTable.Name .."!\n")
			else
				MsgAll(ply:Nick().." received: "..orig_text.." ".. ItemTable.Name .."!\n")
			end

			ply:GiveItem(ItemKey, amount, true, 800, rarity, nil, nil, true )

			MakeConfetti(ply)

		end)
	end

	timer.Create(ply:EntIndex().."_Lootbox_Slow_5", 5, 1, function()
		if !IsValid(ply) then return end -- tough shit if they left here.

		ply:EmitSound("vo/npc/Barney/ba_ohyeah.wav")
	end)

	--ply:TakeItem(item, 1)
	ply:TakeItem(keypadfound, 1)

	--ply:PrintMessage(HUD_PRINTTALK, "Phoenixf129: Hey, I was in a rush today so I haven't finished unboxing yet. It should be finished tonight. Keep hold of your boxes for now! You will recieve 1 guaranteed same weapon rarity, and 3 other items of the same rarity upon system completion. These items will also have a chance of being a higher rarity!")
	return false
end