util.AddNetworkString( "UpdateItem" )
util.AddNetworkString( "UpdateItemFull" )
util.AddNetworkString( "UpdateWeight" )
util.AddNetworkString( "UpdateWorth" )
util.AddNetworkString( "dz_addslot" )
util.AddNetworkString( "dz_foundernameReq" )
util.AddNetworkString( "dz_updateFounders" )

_Acecool = false
local PMETA = FindMetaTable("Player")

function PMETA:CanPerformAction()
    if self.InProcess then
        --self:Tip(3, "cantperform", Color(255,255,0))
        return false
    end

    if self:GetAFK() then 
        self:Tip(3, "You cannot do this while AFK!", Color(255,255,0))
        return false 
    end

    if self:GetMoveType() == MOVETYPE_NOCLIP && !self:IsPhoenix() && !self:InVehicle() then
        self:Tip(3, "You cannot do this while in noclip!", Color(255,255,0))
        return false
    end

    if IsValid(self.tradingWith) then
        --self:Tip(3, "cantperform", Color(255,255,0))
        return false
    end

    if self:IsOnFire() then
        self:Tip(3, "ouchfire", Color(255,0,0))
        return false
    end

    if !self:Alive() then 
        return false 
    end

    return true
end

function PMETA:AddAdditionalWeight( rarity, amount )

    if !amount then 
        amount = rarity 
        rarity = nil 
    end -- fallback for old shit

    if rarity then
        rarity = rarity - 1

        amount = amount + math.ceil( ( amount / 10 ) * rarity )
    end

    self:SetAdditionalWeight( math.Clamp( self:GetAdditionalWeight() + amount, 0, 10000 ) ) 
end

function PMETA:GetWeight()
    return self.WeightCur or 0
end

function PMETA:SetWeight( amount )
    self.WeightCur = amount
end

function PMETA:CanInvCarry(item, amount)

    if self.Loading then return true end
    
    item = tonumber(item) or item
    amount = tonumber(amount) or 1
    
    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    elseif ( istable( item ) ) then
        ItemTable, ItemKey = item, GAMEMODE.DayZ_Items[item.ID]
    end
    
    if !self.Noclip && self:GetWeight() + ( ItemTable.Weight * amount ) > self:GetWeightMax() then
        self:Tip( 3, "overburdened", Color(255,0,0) )
    
        return false
    end
    
    return true
end

function PMETA:CalculateWeight()

    local weight = 0
    for class, items in pairs( self.InvTable ) do

        local ItemTable = GAMEMODE.DayZ_Items[ class ]

        --PrintTable(items)
        for _, item in pairs(items) do
                        
            if ItemTable && ItemTable.Weight then
                weight = weight + ItemTable.Weight * item.amount
            end

        end

    end

    self:SetWeight( weight )

    local max_weight = self:GetWeightMax()
    if weight > ( max_weight + (max_weight/10) ) then
        self:Tip( 3, "You are carrying too much weight!", Color(255,0,0) )
    end

    net.Start( "UpdateWeight" )
        net.WriteFloat( self:GetWeight() )
    net.Send( self )

    local bweight, bworth = 0, 0
    for class, items in pairs( self.BankTable ) do

        local ItemTable = GAMEMODE.DayZ_Items[ class ]

        for _, item in pairs(items) do
            if ItemTable && ItemTable.Weight then
                bweight = bweight + ItemTable.Weight * item.amount
            end

            local price = GAMEMODE.Util:GetItemPrice(item.class, item.amount, true, true, nil, item.quality, nil, item.rarity)

            if item.class == "item_money" then
                price = item.amount
            end

            bworth = bworth + price 
        end
        
    end

    self.BankWeightCur = bweight
    self.BankWorthCur = bworth

    net.Start( "UpdateBankWeight" )
        net.WriteFloat( bweight )
    net.Send( self )

    net.Start( "UpdateWorth" )
        net.WriteFloat( bworth )
        net.WriteBool( false )
    net.Send( self )

end

PMETA.AddWeight = PMETA.CalculateWeight

function PMETA:UpdateItem( item, take )
    if item != nil then
        
        net.Start( "UpdateItem" )
            net.WriteTable( item )
            net.WriteBool( take or false )
        net.Send( self )
        
        hook.Call( "DZ_OnUpdateItem", GAMEMODE, self, item.class, amount )
    else

        net.Start( "UpdateItemFull" )
            net.WriteTable( self.InvTable )
        net.Send( self )
        
        for class, items in pairs( self.InvTable ) do
            for _, it in pairs(items) do
                hook.Call( "DZ_OnUpdateItem", GAMEMODE, self, it.class, it.amount )   
            end
        end  
    end

    self:CalculateWeight()
    self:UpdateAmmoCount()
end
concommand.Add( "Update", function( ply, cmd, args ) 
    ply:UpdateItem()
end )

function UpdateBackweps(self)
    --if !self:IsAdmin() then return end

    self.backWeapons = self.backWeapons or {}

    for k, v in pairs(self.backWeapons) do
        if !IsValid(v) then continue end
        v:Remove()
    end
    self.backWeapons = {}

    self.CharTable = self.CharTable or {} 

    for item, _ in pairs( self.CharTable ) do
        local ItemTable = GAMEMODE.DayZ_Items[item]

        if ItemTable.Primary or ItemTable.Secondary or ItemTable.Melee or ItemTable.BodyArmor then
            local ent = ents.Create("backwep")
            ent:SetItem(item)
            ent:SetModel(ItemTable.Model)
            if ItemTable.Material then
                ent:SetMaterial(ItemTable.Material)
            end
            if ItemTable.Skin then
                ent:SetSkin(ItemTable.Skin)
            end
            if ItemTable.BodyGroups then
                ent:SetBodyGroups(ItemTable.BodyGroups)
            end
            ent:SetPos(self:GetPos())
            ent:SetParent(self)
            ent:Spawn()
            table.insert(self.backWeapons, ent)
        end

    end

end

function UpdateBackPack( self, item, justbone )

    if justbone then
        if !IsValid(self.backpack) then return end
        local item = self.backpack.class
        UpdateBackPack( self, item )
        return
    end

    if item == nil then return false end

    item = tonumber(item) or item

    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], GAMEMODE.DayZ_Items[ item ].ID
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    end
    
    if ItemTable == nil then return false end

    if ItemTable.VIP != nil and not self:IsVIP() then return false end
        
    if IsValid(self.backpack) then
        self.backpack:Remove()
    end

    self.backpack = ents.Create( "bp" )
    self.backpack.class = ItemKey
    self.backpack.vip = ItemTable.VIP or false

    self.backpack:SetModel( ItemTable.Model )
    if ItemTable.Skin then
        self.backpack:SetSkin( ItemTable.Skin )
    end

    self.backpack:SetParent(self)
    self.backpack:Spawn()
end

function UpdateHat( self, item )
    if item == nil then return false end

    item = tonumber(item) or item

    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], GAMEMODE.DayZ_Items[ item ].ID
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    end
    
    if ItemTable == nil then return false end

    if !IsValid(self) then return false end

    --if ItemTable.VIP != nil and not (self.IsVIP && self:IsVIP()) then return false end
        
    if IsValid(self.hat) then self.hat:Remove() end

    self.hat = ents.Create( "hat" )
    self.hat.class = ItemKey
    self.hat.vip = ItemTable.VIP or false
    self.hat:SetPos( Vector( self:GetPos() ) + Vector( 0, 0, 40 ) )
    self.hat:SetModel( ItemTable.Model )
    self.hat:SetParent(self)
    if ItemTable.Skin then
        self.hat:SetSkin( ItemTable.Skin )
    end
    if ItemTable.BodyGroups then
        self.hat:SetBodyGroups( ItemTable.BodyGroups )
    end
    self.hat:Spawn()
end

function PMETA:UpdateWeapons( item, key, reload_weps )

    if IsValid( self.hat ) then
        self.hat:Remove()
    end

    if IsValid( self.backpack ) then
        self.backpack:Remove()
    end
        
    if item then
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ key ], key
        if ItemTable == nil then return false end

        if not self.CharTable[ItemKey] or table.Count( self.CharTable[ItemKey] ) < 1 then
            if GAMEMODE.DayZ_Items[ItemKey].Weapon then
                self:StripWeapon(GAMEMODE.DayZ_Items[ItemKey].Weapon)
            end
            if GAMEMODE.DayZ_Items[ItemKey].BodyArmor then
                self:SetPArmor(0)
            end
        else

            if self.CharTable[ItemKey][item] && self.CharTable[ItemKey][item].quality < 100 then
                if GAMEMODE.DayZ_Items[ItemKey].Weapon then
                    self:StripWeapon(GAMEMODE.DayZ_Items[ItemKey].Weapon)
                end
                if GAMEMODE.DayZ_Items[ItemKey].BodyArmor then
                    self:SetPArmor(0)
                end
            end

        end
        
        if GAMEMODE.DayZ_Items[ItemKey].BodyModel then
            self:EmitSound("npc/combine_soldier/gear3.wav")
        end

        if GAMEMODE.DayZ_Items[ItemKey].BackPack then
            self:EmitSound("npc/combine_soldier/gear5.wav")
        end
    end
        
    local clothesfound = false
    for class, items in pairs( self.CharTable ) do
        local ItemTable = GAMEMODE.DayZ_Items[ class ]
        
        local hasitem = {}
        local item
        for _, it in pairs(items) do
            if it.quality < 100 then continue end -- ignore wrecked.
            if it.amount >= 0 then table.insert(hasitem, it.class) end
            item = it.id
        end

        if not table.HasValue( hasitem, class ) then 
            if ItemTable.Weapon then
                self:StripWeapon( ItemTable.Weapon )
            end
        end 

        if not table.HasValue( hasitem, class ) then continue end
            
        if ItemTable.VIP != nil and not self:IsVIP() then continue end

        if ItemTable.Weapon != nil then
            if self:IsWepBanned() then continue end

            self:Give( ItemTable.Weapon )
            local wep = self:GetWeapon( ItemTable.Weapon )
            
            wep.itemid = item
            if reload_weps then
                --self.nextWepUpdate = CurTime() + 0.2

                --MsgAll("FILLING CLIPS FOR "..ItemTable.Weapon..""..self:Nick())

                self:FillClips( wep )
            end
        end

        if ItemTable.BackPack then
            self:SetNWInt("Backpackweight", ItemTable.BackPack or 0)
            UpdateBackPack( self, class )
        end

        --self:SetPArmor(0)
        if ItemTable.BodyArmor then

            local quality = self.CharTable[class][item].quality

            local qual = math.Round( ( quality * ( ItemTable.BodyArmor / 100 ) ) / 4 )
            qual = math.Clamp( qual, 0, ItemTable.BodyArmor)

            --print( qual )
            self:SetPArmor(qual)
        end

        if ItemTable.Body != nil then
            clothesfound = true
            
            self.oPModel = self.oPModel or self:GetModel()
            self:SetModel( ItemTable.BodyModel )
            if ItemTable.Skin then
                self:SetSkin( ItemTable.Skin )
            end

            if ItemTable.BodyGroups then
                self:SetBodyGroups(ItemTable.BodyGroups)
            end

            --timer.Simple(1, function() 
                --if !IsValid(self) then return end 
                UpdateBackPack(self, nil, true) 
            --end)
        end
        
        if ItemTable.Hat != nil then
            UpdateHat( self, class )
        end
    end

    self:UpdateAmmoCount()

    UpdateBackweps(self)

    if not clothesfound then
        --self:EmitSound("npc/combine_soldier/gear1.wav")
        self:SetModel( self.oPModel or "models/player/group01/male_01.mdl" )
        self:SetSkin(1)
    end 
end

function PMETA:UpdateAmmoCount()
    self:StripAmmo()

    self.ammoUsed = {}

    for class, items in pairs( self.InvTable ) do

        local ItemTable
        if isnumber(class) then
            ItemTable = GAMEMODE.DayZ_Items[ class ]
        else
            ItemTable = GAMEMODE.DayZ_Items[ class ]
        end

        for _, item in SortedPairsByMemberValue(items, "quality", true) do
            if ItemTable.AmmoType != nil then
                self.ammoUsed[class] = item 
            end
            if item.amount < 1 then continue end
            if item.quality < 100 then continue end

            if ItemTable.AmmoType != nil then
                if self.oSetAmmo then self:oSetAmmo( item.amount, ItemTable.AmmoType ) else self:SetAmmo( item.amount, ItemTable.AmmoType ) end
                break
            end
        end
    end
end

function PMETA:QuickGiveItem( item, amount, quality, rarity )
    return self:GiveItem( item, amount, true, quality, rarity, nil, nil, true, nil, nil, nil )
end

function PMETA:GiveItem( item, amount, ignoreweight, quality, rarity, noauto, addslot, notify, autoequip, bank, itdata )
    if item == nil and amount == nil then return false end
    if !rarity then rarity = 1 end

    quality = quality and math.Clamp(quality, 1, 1000) or math.random(300,800)

    local ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    
    if ItemTable == nil then return false end

    if ItemTable.IsCurrency then quality = 800 end -- Force quality depending on money for stacking.

    amount = math.Round( amount )
    if amount < 1 then return false end

    local newitem = false
    local found_id = 0
    local found_type = 0
    local foundwhen = 0

    if itdata then
        if itdata.found_id then
            found_id = itdata.found_id
            newitem = false
        end
        if itdata.foundtype then
            found_type = itdata.foundtype
            newitem = false
        end        

        if itdata.new then
            newitem = true
        end

        if itdata.foundwhen then
            foundwhen = itdata.foundwhen
        end

    end

    if found_id == 0 then
        found_id = self.ID -- 0 because like below
        newitem = true
    end

    if found_type == 0 then
        found_type = 1 -- 0 because item was just found, did not have data.
        newitem = true
    end

    if foundwhen == 0 then
        foundwhen = os.time()
    end

    if !found_id then MsgAll("CANT GIVE ITEM "..item.." TO "..self:Nick().." AS THEY ARE NOT READY!\n") return false end

    if ItemTable.ID == "item_flashlight" then
        self:AllowFlashlight( true )
    end

    self.InvTable = self.InvTable or {}

    hook.Call("DZ_OnGiveItem", GAMEMODE, self, ItemKey, amount, rarity, newitem)

    local stacked = false
    if !noauto then
        local its = GAMEMODE.Util:GetItemIDsByClass(self.InvTable, ItemKey)

        if ItemKey == "item_money" or ItemTable.IsCurrency then
            for _, item in pairs(its) do
                if item.rarity != rarity then continue end

                local qa, qb = ( item.quality * item.amount ), ( quality * amount )
                amount = item.amount + amount

                local quality = math.Round( (qa + qb) / amount )

                self:SetItem(item.id, amount, quality, rarity, notify)
                stacked = true                
                break
            end
        end
        if stacked then return end

        for _, item in pairs(its) do
            if GetCondition( item.quality ) == GetCondition( quality ) then
                if item.rarity != rarity then continue end
                if item.found_id != found_id then continue end

                local qa, qb = ( item.quality * item.amount ), ( quality * amount )
                amount = item.amount + amount

                local quality = math.Round( (qa + qb) / amount )

                self:SetItem(item.id, amount, quality, nil, notify)
                stacked = true
                break
            end
        end
    end
    
    if stacked then return end

    local ins = DZ_GetLastInsert("players_inventory")

    local function itupdate( lastInsert )
        if !IsValid(self) then return end
        
        local it = {}
        if lastInsert then
            it.id = lastInsert 
        else
            it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, ItemKey)
        end
        it.class = ItemKey
        it.amount = amount
        it.quality = quality
        if rarity > 8 then
            rarity = 1
        end
        it.rarity = rarity

        it.foundtype = found_type
        it.found_id = found_id
        it.foundwhen = foundwhen

        self.InvTable[ ItemKey ] = self.InvTable[ ItemKey ] or {}
        self.InvTable[ ItemKey ][ it.id ] = it
        self:UpdateItem( it, notify )

        if bank != nil then
            self:UpdateBank( it, bank )
        end

        if addslot then
            net.Start("dz_addslot")
                net.WriteTable(it)
            net.Send(self)
        end

        if autoequip then
            self:EquipItem( it.id, nil, nil, true, true )
        end
    end
    --itupdate( ins )

    PLib:RunPreparedQuery({ sql = "INSERT INTO `players_inventory` ( `user_id`, `item`, `amount`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` ) VALUES ( " .. self.ID .. ", '" .. ItemKey .. "', " .. amount .. ", "..quality..", "..rarity..", " .. found_type .. ", "..found_id..", "..foundwhen.." );", 
    callback = function( data )
        --lastInsert = data
        itupdate(data)
    end })
    
    DZ_AddPredictedInsert("players_inventory") -- add 1 as we are about to update

end

function PMETA:SetItem( item, amount, quality, rarity, notify )
    if item == nil and amount == nil then return false end

    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end
    
    amount = tonumber( amount )
    if amount < 0 then return false end

    local qual = math.Clamp(quality or it.quality, 1, 1000)
    local dura = math.Clamp(rarity or it.rarity, 0, 7)

    it.class = ItemKey
    it.amount = amount
    it.quality = qual
    it.rarity = dura

    self.InvTable[ ItemKey ] = self.InvTable[ ItemKey ] or {}
    self.InvTable[ ItemKey ][it.id] = it

    PLib:QuickQuery( "UPDATE `players_inventory` SET `amount` = " .. it.amount .. ", `quality` = "..qual..", `durability` = "..dura.." WHERE `id` = " .. it.id .. ";" )
    self:UpdateItem( it, notify )
end

function PMETA:TakeCharItem( item, old )
    if item == nil then return false end
        
    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.CharTable, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(self.CharTable, item)
    end
        
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end
    
    self.CharTable[ ItemKey ] = self.CharTable[ ItemKey ] or {}    
    self.CharTable[ ItemKey ][ it.id ] = nil
        
    PLib:QuickQuery( "DELETE FROM `players_character` WHERE `user_id` = " .. self.ID .. " AND `item` = '" .. ItemKey .. "';" )

    self:UpdateChar( it.id, ItemKey )
    
    hook.Call("DZ_OnTakeCharItem", GAMEMODE, self, ItemKey)
        
    return true
end

function PMETA:BreakItem( item, char, percentage )
   if item == nil and amount == nil then return false end
   percentage = percentage or 40

    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if !it then
        it = GAMEMODE.Util:GetItemByDBID(self.CharTable, item)
    end
    if it == nil then return false end
    
    local ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( it.class )

    if char then
        self:TakeCharItem(item)
    else
        self:TakeItem(item, 1)
    end

    if !ItemTable.ReqCraft then return false end

    /*for _, v in pairs( ItemTable.ReqCraft ) do
        if GAMEMODE.DayZ_Items[v].NoGiveOnBreak then continue end

        if v == "item_ironbar" and math.random(1,50) > 45 then v = "item_metal" end -- randomly get scrap instead of the iron bar.
        
        local pc = math.random(0, 100)
        if pc > percentage then continue end

        self:GiveItem( v, 1, nil, it.quality or math.random(100,500), it.rarity or math.random(100,500) )
    end*/

    self:Tip( 3, ItemTable.Name .. " has broken.", Color(255,0,0) )
    self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(1,3)..".wav", 75, 100, 0.5)
end

function PMETA:TakeItem( item, amount, old )
    if item == nil and amount == nil then return false end

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if old then
        it = GAMEMODE.Util:GetItemIDByClass(self.InvTable, item)
    end
    if it == nil then return false end
    local ItemKey = it.class    

    amount = tonumber( amount )
    if amount < 1 then return false end

    local CurItemAmount = it.amount

    if amount > it.amount then return false end
    
    local NewItemAmount = CurItemAmount - amount

    if NewItemAmount < 1 then
        self.InvTable[ ItemKey ][ it.id ] = nil

        PLib:QuickQuery( "DELETE FROM `players_inventory` WHERE `id` = '" .. it.id .. "';" )
    else
        self.InvTable[ ItemKey ][ it.id ].amount = NewItemAmount

        PLib:QuickQuery( "UPDATE `players_inventory` SET `amount` = " .. NewItemAmount .. " WHERE `id` = '" .. it.id .. "';" )
    end

    it.amount = NewItemAmount

    self:UpdateItem( it )

    hook.Call("DZ_OnTakeItem", GAMEMODE, self, ItemKey, amount)
    
    return true
end

function PMETA:StackCond(item, val)
    if item == nil then return false end
    if not self:CanPerformAction() then return false end

    item = tonumber(item) or item

    local its = GAMEMODE.Util:GetItemIDsByClass(self.InvTable, item)
    if its == nil then return false end

    local last = {}
    local combine = {}
    for class, it in SortedPairsByMemberValue(its, "quality") do
        if last.id == it.id then continue end
        --if last.rarity != it.rarity then MsgAll(last.rarity.." "..it.rarity) continue end

        if val && string.lower(GetCondition( it.quality )) != string.lower(val) then continue end

        if last.str == GetCondition( it.quality ) then
            table.insert(combine, {a = last.id, b = it.id})
        end
        last.str = GetCondition( it.quality )
        last.id = it.id
    end

    for k, v in ipairs(combine) do
        self:StackItem( v.b, v.a )
    end

end
concommand.Add("StackCond", function(ply, cmd, args) ply:StackCond( args[1] ) end)

function PMETA:UpgradeItem( item1, item2, item3 )
    if item1 == nil then return false end

    if not self:CanPerformAction() then return false end

    item1 = tonumber(item1) or item1
    item2 = tonumber(item2) or item2
    item3 = tonumber(item3) or item3

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item1)
    local it2 = GAMEMODE.Util:GetItemByDBID(self.InvTable, item2)
    local it3 = GAMEMODE.Util:GetItemByDBID(self.InvTable, item2)

    if it == nil then return false end
    local reqamt = 1
    if it2 == nil then
        it2 = it
        reqamt = reqamt + 1
    end
    if it3 == nil then
        it3 = it
        reqamt = reqamt + 1
    end

    if it.amount < reqamt then return false end

    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    local ItemTable2, ItemKey2 = GAMEMODE.DayZ_Items[ it2.class ], it2.class
    local ItemTable3, ItemKey3 = GAMEMODE.DayZ_Items[ it3.class ], it3.class

    local cats = { "ammo", "lootboxes", "", "none" }

    if ( table.HasValue(cats, ItemTable.Category) or table.HasValue(cats, ItemTable2.Category) or table.HasValue(cats, ItemTable3.Category) ) && ItemKey != "item_keypad" then return false end

    if ItemTable == nil or ItemTable2 == nil or ItemTable3 == nil then return false end
    
    if it.rarity != it2.rarity or it2.rarity != it3.rarity then return false end -- not if they are the different rarities!

    local rarity = it.rarity + 1
    local item = it.class
    local quality = ( it.quality + it2.quality + it3.quality ) / 3

    if not self:Alive() then return false end

    local tbl
    for k, v in pairs( ents.FindInBox( self:GetPos()+Vector(100,100,50), self:GetPos()-Vector(100,100,50) ) ) do
        if v:GetClass() == "dz_interactable" and ( v:GetModel() == "models/props_c17/furnituretable002a.mdl" or v:GetModel() == "models/raviool/bartable.mdl" ) then
            tbl = v
            break
        end
    end
        
    if !IsValid(tbl) then 
        return false 
    end

    self:DoCustomProcess(item, "Upgrading", 3, "stranded/start_crafting.wav", 0, "ambient/levels/citadel/weapon_disintegrate"..math.random(1,4)..".wav", true, function(ply)
        if not IsValid(self) or not self:Alive() then return end

        self:TakeItem(item1, reqamt) -- eliminate the first item, and more if it is stacked.

        if item2 then
            self:TakeItem(item2, 1) -- eliminate the secondary item
        end

        if item3 then
            self:TakeItem(item3, 1) -- eliminate the third item
        end
        it.foundtype = 6
        self:GiveItem(item, 1, true, quality, rarity, true, nil, true, nil, nil, it)

        local text = GetRarity(rarity).t
        if ItemTable.Weapon then
            text = GetRarity(rarity).wep
        end

        if ItemTable.ID == "item_dz_axe" && DZ_Quests then -- Axe Tutorial quest
            self:DoQuestProgress("quest_learnthebasics3", 1)
        end

        self:SendLua[[if IsValid(Upgrade_Panel) then for i =1, 3 do Upgrade_Panel.Slots[i]:Clear() end end]]
        MsgAll(self:Nick().. " upgraded to '"..text.."' "..ItemTable.Name.."!\n")

        if IsValid(tbl) && !tbl:GetPersistent() then
            tbl:SetHealth( tbl:Health() - 20 )
        end

    end)

end
concommand.Add( "UpgradeItem", function( ply, command, args )
    ply:UpgradeItem( args[ 1 ], args[ 2 ], args[ 3 ] )
end )

function PMETA:StackItem( item, item2 )
    if item == nil or item2 == nil then return false end

    if not self:CanPerformAction() then return false end

    item = tonumber(item) or item
    item2 = tonumber(item2) or item2

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    local it2 = GAMEMODE.Util:GetItemByDBID(self.InvTable, item2)
    if it == nil or it2 == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    local ItemTable2, ItemKey2 = GAMEMODE.DayZ_Items[ it2.class ], it2.class
    if ItemTable == nil or ItemTable2 == nil then return false end
    
    --self.NextStackItem = self.NextStackItem or 0

    if not self:Alive() then return false end
    --if not self:HasItem( ItemKey ) then return false end
    --if self.NextStackItem > CurTime() then return false end

    if it.class != it2.class then return false end -- yeah, no.

    if it.id == it2.id then return false end -- yeah, no.

    if it.rarity != it2.rarity then return false end

    if ( it.quality < 100 and it2.quality > 100 ) or ( it.quality > 100 and it2.quality < 100 ) then return false end
    
    local amount = it.amount + it2.amount

    local qa, qb = ( it.quality * it.amount ), ( it2.quality * it2.amount )
    --local da, db = ( it.rarity * it.amount ), ( it2.durability * it2.amount )

    local quality = math.Round( (qa + qb) / amount )

    it.found_id = self.ID -- force owner to self when stacked

    self:SetItem(it.id, amount, quality)
    self:TakeItem(item2, it2.amount) -- eliminate the secondary item

    self:EmitSound("npc/combine_soldier/gear"..math.random(1,4)..".wav", 75, 100, 0.5)

    if not self:IsSuperAdmin() then
        --self.NextStackItem = CurTime() + 5 
    else
        --self.NextStackItem = CurTime() + 1
    end
    
end
concommand.Add( "StackItem", function( ply, command, args )
    ply:StackItem( args[ 1 ], args[ 2 ] )
end )

function PMETA:SplitItem( item, amount )
    if item == nil or amount == nil then return false end

    if not self:CanPerformAction() then return false end

    item = tonumber(item) or item
    amount = tonumber(amount) or amount

    amount = math.Round(amount)

    if amount < 1 then return false end

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end
    
    if not self:Alive() then return false end
    --if not self:HasItem( ItemKey ) then return false end   
    --if !self:HasItemAmount(item, amount) then return false end

    local amt = it.amount - amount
    if amt < 1 then return false end

    local quality, rarity = it.quality, it.rarity
    self:SetItem(item, amt)
    self:GiveItem(it.class, amount, nil, quality, rarity, true, nil, nil, nil, nil, it)    

    self:EmitSound("npc/combine_soldier/gear"..math.random(1,4)..".wav", 75, 100, 0.5)
end
concommand.Add( "SplitItem", function( ply, command, args )
    ply:SplitItem( args[ 1 ], args[ 2 ] )
end )

function PMETA:RepairItem( item )
    if item == nil then return false end

    if not self:CanPerformAction() then return false end

    item = tonumber(item) or item
    
    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    if it.quality < 100 then
        self:Tip( 3, "This item is too damaged to repair!", Color(255,0,0) )
        return false
    end

    if self:GetLevel() < ( ( ItemTable.LevelReq or 0 ) / 2 ) then 
        self:Tip( 3, "You need to be Level "..( ItemTable.LevelReq / 2 ).." to Repair this item!", Color(255,255,0) )

        return false 
    end

    if ItemTable.CantRepair then return false end

    local cats = {"ammo", "primaries", "secondaries", "tertiaries", "tools", "parts", "melee", "bodyarmor", "backpacks", "clothes", "pants", "shoes", "misc"}

    if !table.HasValue(cats, string.lower(ItemTable.Category or "")) then return false end

    local RepairItem = GAMEMODE.DayZ_Items[ItemTable.RepairItem or "item_repairkit"]

    if not self:Alive() then return false end

    local it2 = GAMEMODE.Util:GetItemIDByClass(self.InvTable, RepairItem.ID, nil, { it.id })
    if !it2 then 
        self:Tip( 3, "You need a "..RepairItem.Name.." to do this!", Color(255,0,0) )
        return false 
    end

    if it.id == it2.id then return false end

    if it.quality == 1000 then 
        return false 
    end

    if it2.quality < 100 then
        self:Tip( 3, "Repair kit condition too low to repair!", Color(255,0,0) )
        return false
    end

    local repair_max = 600
    if self:GetLevel() > 5 then
        repair_max = math.Clamp(self:GetLevel() * 100, 1, 950)
    end

    if it.quality >= 950 then
        self:Tip( 3, "You cannot repair this item any further!", Color(255,0,0) )
        return
    end

    if it.quality >= repair_max then
        self:Tip( 3, "You need to be a higher level to repair this item further!", Color(255,0,0) )
        return
    end

    self:DoCustomProcess(item, "Repairing", 3, "npc/combine_soldier/gear3.wav", 0, "", true, function(ply, item)
        if not IsValid(self) or not self:Alive() then return end

        local to_take = math.random(80, 100)
        local to_add = to_take

        to_add = to_add - ( ( it.rarity or 1 ) * 10 ) -- take the item rarity
        to_add = to_add + ( ( it2.rarity or 1 ) * 10 ) -- add the repairkits rarity

        local qual = math.Round(it.quality + ( to_add / it.amount ))
        qual = math.Clamp(qual, 1, repair_max)

        self:SetItem( it.id, it.amount, qual )

        local qual2 = math.Round(it2.quality - ( to_take / it2.amount ))
        qual2 = math.Clamp(qual2, 1, repair_max)

        self:SetItem( it2.id, it2.amount, qual2 )

        if DZ_Quests then
            self:DoQuestProgress("quest_learnthebasics5", 1)
        end

    end)

end
concommand.Add( "Repairitem", function( ply, command, args )
    ply:RepairItem( args[ 1 ] )
end )

function PMETA:DeployItem( item, key ) -- called via UseItem
    if item == nil then return true end

    if not self:CanPerformAction() then return true end

    if self:GetSafeZone() or self:GetSafeZoneEdge() then 
        self:Tip( 3, "You cannot do this in the Safezone!", Color(255,0,0) )
        return true 
    end 

    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return true end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return true end

    local ent_class = ItemTable.DeployEnt or "prop_physics"
    local ent = ents.Create(ent_class)
    if ItemTable.WorldModel then
        ent:SetModel(ItemTable.WorldModel)
    else
        ent:SetModel(ItemTable.Model)
    end
    ent.Dropped = true
    
    ent.SID = self:SteamID64()

    ent.CanPickupOverride = true

    if ItemTable.Material then
        ent:SetMaterial(ItemTable.Material)
    end
    if ItemTable.Color then
        ent:SetColor(ItemTable.Color)
    end

    -- Do volume in cubic "feet"
    local min, max = ent:OBBMins(), ent:OBBMaxs()
    local vol = math.abs(max.x-min.x) * math.abs(max.y-min.y) * math.abs(max.z-min.z)
    vol = vol/(24^3)

    ent:SetPos( ( self:GetPos() + Vector(0,0,70) ) + ( self:GetAimVector() * 30 ) + self:GetForward() * 2)
    ent:SetAngles( Angle( 0, self:EyeAngles().y, 0 ) )

    ent:Activate()
    ent:Spawn()
    
    ent:SetHealth((vol*10) * PHDayZ.PropHealthMultiplier)
    ent:SetMaxHealth((vol*10) * PHDayZ.PropHealthMultiplier)

    local phys = ent:GetPhysicsObject()
    if IsValid( phys ) then 
        --phys:SetMass(1)
    end

    if !ent:IsPlayerHolding() then
        self:PickupObject( ent )
    end

    self:TakeItem( item, 1 )
end

function PMETA:UseItem( item )
    if item == nil then return false end

    if not self:CanPerformAction() then return false end

    item = tonumber(item) or item
    
    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    if it.quality < 100 then
        local text = ItemTable.OverrideUseMenu or "use"
        self:Tip( 3, "This item is too damaged to "..string.lower(text).."!", Color(255,0,0) )
        return false
    end

    self.NextUseItem = self.NextUseItem or 0

    if not self:Alive() then return false end
    --if not self:HasItem( ItemKey ) then return false end
    if self.NextUseItem > CurTime() then return false end

    local rarity = it.rarity or 1
    rarity = rarity - 1 -- for purposes below.
    
    if ItemTable.BloodFor or ItemTable.HealsFor or ItemTable.ProcessFunction != nil or ItemTable.EatFor or ItemTable.DrinkFor then
        
        local pr = true
        if ItemTable.PreProcessFunction then pr = ItemTable.PreProcessFunction(self, item, ItemTable.ID, it) end
        if pr == false then return end

        local txt, snd, esnd, time = "Using ", "eat.wav", "npc/barnacle/barnacle_gulp2.wav", ItemTable.TimeToProcess or 2
        if ItemTable.BloodFor or ItemTable.HealsFor then
            txt = "Using"
            snd = "items/medshot4.wav"
            esnd = "heal.wav"
        end
        if ItemTable.EatFor then
            txt = "Eating"
        elseif ItemTable.DrinkFor then
            txt = "Drinking"
            snd = "npc/barnacle/barnacle_gulp1.wav"
        end

        if ItemTable.UseName then
            txt = ItemTable.UseName
        end
        if ItemTable.UseSound then
            snd = ItemTable.UseSound
        end
        if ItemTable.UseEndSound then
            esnd = ItemTable.UseEndSound
        end

        self:DoModelProcess(ItemTable.Model, txt.." "..ItemTable.Name, time, snd, 0, esnd, nil, function(ply)

            local takesitem = false
            if ItemTable.BloodFor then
                local diff = ItemTable.BloodFor + ( (ItemTable.BloodFor / 10) * rarity )
                self:SetHealth( math.Clamp(self:Health() + diff, 0, 100) )
            end

            if ItemTable.DrinkFor then
                local diff = ItemTable.DrinkFor + ( (ItemTable.DrinkFor / 10) * rarity )
                local amt = self:GetThirst() + ( diff * 10 )

                self:SetThirst( math.Clamp( amt, 0, 1000 ) )
            end

            if ItemTable.EatFor then
                local diff = ItemTable.EatFor + ( ((ItemTable.EatFor / 20)*3) * rarity )

                local amt = self:GetHunger() + ( diff * 10 )
                self:SetHunger( math.Clamp( amt, 0, 1000 ) )

                self:SetHealth( math.Clamp( self:Health() + 2, 0, self:GetMaxHealth() ) )
            end

            if ItemTable.StaminaFor then
                local diff = ItemTable.StaminaFor + ( (ItemTable.StaminaFor / 10) * rarity )
                self:SetStamina( math.Clamp( self:GetStamina() + diff, 0, 100 ) )
            end
            if ItemTable.HealsFor then
                local diff = ItemTable.HealsFor + ( (ItemTable.HealsFor / 10) * rarity )
                self:SetRealHealth( math.Clamp( self:GetRealHealth() + diff, 0, 100 ) )
            end
            if ItemTable.RadsFor then
                local rads = ItemTable.RadsFor + math.floor( ( ItemTable.RadsFor/ 10 ) * rarity ) 
                if rads < 0 then rads = rads * -1 end

                self:SetRadiation( math.Clamp( self:GetRadiation() - rads, 0, 1000 ) )
            end
            
            if ItemTable.ProcessFunction then takesitem = ItemTable.ProcessFunction(self, item, ItemTable.ID, it) end

            if !takesitem then
                self:TakeItem( item, 1 )
            end

            if ItemTable.GiveItemOnProcess then
                self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
            end

            hook.Call("DZ_OnUseItem", GAMEMODE, self, ItemTable.ID, it.quality, it.rarity )

        end)

    end
    
    if not self:IsSuperAdmin() then
        self.NextUseItem = CurTime() + 5 
    else
        self.NextUseItem = CurTime() + 1
    end
    
end
concommand.Add( "Useitem", function( ply, command, args )
    ply:UseItem( args[ 1 ] )
end )

function PMETA:GivePerk( perk )
    if perk == nil then return false end

    local ItemTable, ItemKey
    if isnumber( perk ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ perk ], perk
    elseif ( isstring( perk ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( perk )
    end
    
    if ItemTable == nil then return false end

    if self:HasPerk(perk) then
        self:ChatPrint("You already have this perk!")
        self:GiveItem(perk, 1)
        return false
    end

    self:EmitSound( "smb3_powerup.wav", 35, 100 )

    PLib:RunPreparedQuery({ sql = "SELECT `id` FROM `players_perks` WHERE `user_id` = " .. self.ID .. " AND `perk` = '" .. ItemKey .. "';", 
    callback = function( data )
        if not data[ 1 ] then
            PLib:QuickQuery( "INSERT INTO `players_perks` ( `user_id`, `perk` ) VALUES ( " .. self.ID .. ", '" .. ItemKey .. "' );" )
            self:ChatPrint( "You have unlocked the " .. ItemTable.Name .. " perk" )
            self:UpdatePerks()
        end
    end })
end

function PMETA:ThrowItem( item, amount )
    if item == nil and amount == nil then return false end
    amount = amount or 1

    if self.NextDrop and self.NextDrop > CurTime() then return false end
    self.NextDrop = CurTime() + 0.1
    
    if not self:CanPerformAction() then return false end
    
    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if !it then return false end
        
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
        
    if ItemTable == nil then return false end
    
    amount = tonumber( amount )
    if amount < 1 then return false end

    amount = math.Round( amount ) -- Whole numbers only thanks.
    
    self:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_THROW)

    if ItemTable.Weapon && !ItemTable.Tertiary then
        self:EmptyClip(ItemTable.Weapon, true)
    end

    self.NoCancelProcess = true
    self:DoCustomProcess(item, "Throwing", 0.9, "", 0, "", true, function(ply, item)
        if not IsValid(self) or not self:Alive() then return end

        if not self:HasItemAmount( item, amount ) then return false end
        if not self:TakeItem( item, amount ) then return false end

        if ItemTable.ID == "item_flashlight" then
            if not self:HasItem("item_flashlight", true) then
                if self:FlashlightIsOn() then
                    self:Flashlight( false )
                end
                self:AllowFlashlight( false )
            end
        end

        self.NoCancelProcess = nil
    
        local DropedEnt = ents.Create( "base_item" )
        DropedEnt:SetItem( ItemKey )
        DropedEnt.Amount = amount
        DropedEnt.gThrower = self
        DropedEnt:SetAmount( DropedEnt.Amount )
        DropedEnt:SetModelScale(ItemTable.Modelscale or 1)
        DropedEnt:SetRarity(it.rarity)
        DropedEnt:SetQuality(it.quality)
        DropedEnt:SetFoundType(it.foundtype or 1)
        DropedEnt:SetFounder(it.found_id or self.ID)
        DropedEnt:SetFoundWhen( it.foundwhen or 0 )
        DropedEnt.Dropped = true
        if ItemTable.Material then
            DropedEnt:SetMaterial(ItemTable.Material)
        end
        if ItemTable.Color then
            DropedEnt:SetColor(ItemTable.Color)
        end

        DropedEnt:SetPos( ( self:GetPos() + Vector(0,0,70) ) + ( self:GetAimVector() * 30 ) + self:GetForward() * 2)
        DropedEnt:SetAngles( Angle( 0, self:EyeAngles().y, 0 ) )
        DropedEnt.Dead = false

        DropedEnt:Activate()
        DropedEnt:Spawn()

        if DropedEnt:GetPhysicsObject():IsValid() and self:Alive() then
            if DropedEnt:GetPhysicsObject():GetMass() > 1 then
                DropedEnt:GetPhysicsObject():ApplyForceCenter( self:GetAimVector() * 12000 )
            else
                DropedEnt:GetPhysicsObject():ApplyForceCenter( self:GetAimVector() * ( 12000 * DropedEnt:GetPhysicsObject():GetMass() ) )
            end
        end
        
        hook.Call("DZ_OnDropItem", GAMEMODE, self, item, amount)
        --hook.Call("DZ_OnThrowItem", GAMEMODE, self, item, amount)

    end)
end
concommand.Add( "ThrowItem", function( ply, cmd, args ) 
    ply:ThrowItem( args[ 1 ], args[ 2 ] ) 
end )

function PMETA:DropItem( item, amount )
    if item == nil and amount == nil then return false end
    amount = amount or 1

    if self.NextDrop and self.NextDrop > CurTime() then return false end
    self.NextDrop = CurTime() + 0.1
    
    if not self:CanPerformAction() then return false end
    
    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if !it then return false end
        
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
        
    if ItemTable == nil then return false end
    
    amount = tonumber( amount )
    if amount < 1 then return false end

    amount = math.Round( amount ) -- Whole numbers only thanks.
    
    self:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_DROP)

    self.ProcessAmt = amount
    if ItemTable.Weapon && !ItemTable.Tertiary then
        self:EmptyClip(ItemTable.Weapon, true)
    end

    self:DoCustomProcess(item, "Dropping", 1, "", 0, "", true, function(ply, item)
        if not IsValid(self) or not self:Alive() then return end

        if not self:HasItemAmount( item, amount ) then return false end
        
        if not self:TakeItem( item, amount ) then return false end

        if ItemTable.ID == "item_flashlight" then
            if not self:HasItem("item_flashlight", true) then
                if self:FlashlightIsOn() then
                    self:Flashlight( false )
                end
                self:AllowFlashlight( false )
            end
        end

        local DropedEnt = ents.Create( "base_item" )
        DropedEnt:SetItem( ItemKey )
        DropedEnt.Amount = amount
        DropedEnt:SetAmount( DropedEnt.Amount )
        DropedEnt:SetModelScale(ItemTable.Modelscale or 1)
        DropedEnt:SetRarity(it.rarity)
        DropedEnt:SetQuality(it.quality)
        DropedEnt:SetFoundType(it.foundtype or 1)
        DropedEnt:SetFounder(it.found_id or self.ID)
        DropedEnt:SetFoundWhen(it.foundwhen)
        DropedEnt.Dropped = true
        if ItemTable.Material then
            DropedEnt:SetMaterial(ItemTable.Material)
        end
        if ItemTable.Color then
            DropedEnt:SetColor(ItemTable.Color)
        end

        DropedEnt:SetPos( ( self:GetPos() + Vector(0,0,40) ) + ( self:GetAimVector() * 30 ) )
        DropedEnt:SetAngles( Angle( 0, self:EyeAngles().y, 0 ) )
        DropedEnt.Dead = false

        DropedEnt:Activate()
        DropedEnt:Spawn()

        if DropedEnt:GetPhysicsObject():IsValid() and self:Alive() then
            if DropedEnt:GetPhysicsObject():GetMass() > 1 then
                DropedEnt:GetPhysicsObject():ApplyForceCenter( self:GetAimVector() * 500 )
            else
                DropedEnt:GetPhysicsObject():ApplyForceCenter( self:GetAimVector() * ( 500 * DropedEnt:GetPhysicsObject():GetMass() ) )
            end
        end
        
        hook.Call("DZ_OnDropItem", GAMEMODE, self, item, amount)

    end)
end
concommand.Add( "DropItem", function( ply, cmd, args ) 
    ply:DropItem( args[ 1 ], args[ 2 ] ) 
end )

function PMETA:Drink( item, amount )
    if amount == nil then return false end
    if amount < 0 then return false end
    if istable(item) and item.ent and not IsValid(item.ent) then return end
    
    if not self:CanPerformAction() then return false end
        
    if not istable(item) then

        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
            
        if ItemTable == nil then return false end

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then 
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent ) 
            else
                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end

    if self:GetThirst() + ( amount * 10 ) > 1000 then
        self:SetThirst( 1000 )
    else
        self:SetThirst( self:GetThirst() + ( amount * 10 ) )
    end
end

function PMETA:Eat( item, amount )
    if amount == nil then return false end
    if amount < 0 then return false end
    if istable(item) and item.ent and not IsValid(item.ent) then return end
    
    if not self:CanPerformAction() then return false end
    
    if not istable(item) then
        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent )
            else

                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end

    if self:GetHunger() + ( amount * 10 ) > 1000 then
        self:SetHunger( 1000 )
    else
        self:SetHunger( self:GetHunger() + ( amount * 10 ) )
    end

    local amount = 1
    if self:Health() + amount > self:GetMaxHealth() then
        self:SetHealth( self:GetMaxHealth() )
    else
        self:SetHealth( self:Health() + amount )
    end

end

function PMETA:EatDrink( item, amount, amount2 )
    if amount == nil then return false end
    if amount < 0 then return false end
    amount2 = amount2 or amount
    
    if istable(item) and item.ent and not IsValid(item.ent) then return end
    
    if not self:CanPerformAction() then return false end    

    if not istable(item) then
        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then 
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent )
            else

                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end

    if self:GetHunger() + (amount * 10) > 1000 then
        self:SetHunger(1000)
    else
        self:SetHunger( self:GetHunger() + ( amount * 10 ) )
    end

    if self:GetThirst() + (amount2 * 10) > 1000 then
        self:SetThirst( 1000 )
    else
        self:SetThirst( self:GetThirst() + ( amount2 * 10 ) )
    end
    
    local amount = 1
    if self:Health() + amount > self:GetMaxHealth() then
        self:SetHealth( self:GetMaxHealth() )
    else
        self:SetHealth( self:Health() + amount )
    end
    self:EmitSound("npc/barnacle/barnacle_gulp2.wav", 75, 100, 0.5)
end

function PMETA:EatHurt( item, heal, hurt )
    if heal == nil then return false end
    if istable(item) and item.ent and not IsValid(item.ent) then return end

    --hurt = hurt or 10
    if !hurt then
        hurt = math.random(heal/2, heal)
    end
        
    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    end
    
    local amt = self:GetHunger() + ( heal * 10 )
    if amt < 0 then amt = 0 end

    if amt > 1000 then
        self:SetHunger( 1000 )
    else
        self:SetHunger( amt )
    end
    
    if math.random(1,10) > 2 then
        self:SetSick(true)
    end
    self:SetRealHealth(self:GetRealHealth() - hurt)
    
    if not istable(item) then
        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then 
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent ) 
            else

                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end
    
    if self:GetRealHealth() <= 0 then 
        self:Kill()
    end 
    self:EmitSound("npc/barnacle/barnacle_gulp2.wav", 75, 100, 0.5)
end

function PMETA:DrinkHurt( item, heal, hurt, nosick )
    if heal == nil then return false end
    if istable(item) and item.ent and not IsValid(item.ent) then return end
    
    if !hurt then
        hurt = math.random(heal/2, heal)
    end
        
    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    end

    local amt = self:GetThirst() + ( heal * 10 )
    if amt < 0 then amt = 0 end

    if amt > 1000 then
        self:SetThirst( 1000 )
    else
        self:SetThirst( amt )
    end
    
    if !nosick and math.random(1,10) > 2 then
        self:SetSick(true)
    end
    self:SetRealHealth(self:GetRealHealth() - hurt)
    
    if not istable(item) then
        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then 
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent )
            else
                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end
    
    if self:GetRealHealth() <= 0 then 
        self:Kill()
    end
    self:EmitSound("npc/barnacle/barnacle_gulp2.wav", 75, 100, 0.5)
end

function PMETA:Heal( item, amount, real, radiation )
    if amount == nil then return false end
    if amount < 0 then return false end
    if istable(item) and item.ent and not IsValid(item.ent) then return end

    local ItemTable, ItemKey
    if isnumber( item ) then
        ItemTable, ItemKey = GAMEMODE.DayZ_Items[ item ], item
    elseif ( isstring( item ) ) then
        ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( item )
    end
    
    if real then
        if self:GetRealHealth() + amount > self:GetMaxRealHealth() then
            self:SetRealHealth( self:GetMaxRealHealth() )
        else
            self:SetRealHealth( self:GetRealHealth() + amount )
        end
    else
        if self:Health() + amount > self:GetMaxHealth() then
            self:SetHealth( self:GetMaxHealth() )
        else
            self:SetHealth( self:Health() + amount )
        end
    end

    if radiation then
        self:SetRadiation( self:GetRadiation() - radiation )
    end
    
    if not istable(item) then
        local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
        if it == nil then return false end
        local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class

        if ItemTable.GiveItemOnProcess then
            self:GiveItem(ItemTable.GiveItemOnProcess, 1, nil, it.quality, it.rarity, nil, nil, nil, nil, nil, it)
        end

        self:TakeItem(item, 1)
    else
        if item.ent and IsValid(item.ent) then
            if GAMEMODE.DayZ_Items[item.id].FloorFunc then 
                GAMEMODE.DayZ_Items[item.id].FloorFunc( self, item.id, item.ent )
            else
            
                if item.ent:GetAmount() > 1 then
                    item.ent:SetAmount( item.ent:GetAmount() - 1 )              
                else
                    item.ent:Remove()
                end
            end
        end
    end
end

function PMETA:FillClips( wep )
    local all_weps = self:GetWeapons()

    for k, weapon in pairs(all_weps) do
        if wep and weapon != wep then continue end -- lel 

        if !weapon.Primary then continue end
        if !weapon.Primary.ClipSize then continue end
        if !weapon.Primary.AmmoItem then continue end
        local ammo = weapon.Primary.AmmoItem
        local clipsize = weapon.Primary.ClipSize

        if weapon:Clip1() > 0 then continue end

        for class, items in pairs(self.InvTable) do
            
            local refill = 0
            local id
            for _, item in pairs(items) do
                if item.amount < 1 then continue end -- ignore empty.

                if item.quality < 100 then continue end
                if item.class != ammo then continue end

                if item.amount >= clipsize then
                    refill = clipsize
                else
                    refill = item.amount
                end
                id = item.id
            end

            if id then
                --self:EmptyClip(weapon, nil, true) -- incase its ran multiple times

                self:TakeItem( id, refill )
                weapon:SetClip1( refill )
                --MsgAll("REFILLED "..weapon:GetClass())

            end

        end

    end

end

function PMETA:EmptyClip(wep, auto, dc)
    if !self:Alive() then return end
    
    local cur_wep = self:GetActiveWeapon()
    local all_weps = self:GetWeapons()
    if wep then
        cur_wep = self:GetWeapon(wep)
    end

    if dc then

        for k, weapon in pairs(all_weps) do

            if !weapon.Primary then continue end
            if !weapon.Primary.ClipSize then continue end
            if !weapon.Primary.AmmoItem then continue end

            //weapon = self:GetWeapon(weapon)
            if weapon:Clip1() > 0 && weapon.Base != "cw_grenade_base" then
                self:GiveItem( weapon.Primary.AmmoItem, weapon:Clip1(), nil, self.ammoUsed[cur_wep.Primary.AmmoItem] and self.ammoUsed[cur_wep.Primary.AmmoItem].quality or math.random(200, 400) )
            end
        end

        return
    end

    // manual empty clip below
    if not self:CanPerformAction() then return false end
    if not IsValid( cur_wep ) then return false end
    
    if cur_wep.Primary.ClipSize > 0 and cur_wep:Clip1() > 0 && cur_wep.Primary.AmmoItem then
        //ply:GetActiveWeapon():EmptyClip()

        --if self.ammoUsed && self.ammoUsed[cur_wep.Primary.AmmoItem] then
            self:GiveItem( cur_wep.Primary.AmmoItem, cur_wep:Clip1(), nil, self.ammoUsed[cur_wep.Primary.AmmoItem] and self.ammoUsed[cur_wep.Primary.AmmoItem].quality or math.random(200, 400) )
        --end
        if auto then
            self:Tip(3, "Detected ammo in gun, auto-emptied to prevent loss!", Color(255,255,0,255))
        end
        cur_wep:SetClip1(0)

    end
end 
concommand.Add( "EmptyClip", function( ply, cmd, args )
    ply:EmptyClip( args[1] )
end )


function PMETA:DequipItem( item, nogive )
    if item == nil then return false end

    if not self:CanPerformAction() then return false end
    
    item = tonumber(item) or item

    local it = GAMEMODE.Util:GetItemByDBID(self.CharTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    if it.amount < 1 then return false end 

    local quality = it.quality or math.random(100,800)
    local rarity = it.rarity or 1

    if ItemTable.UnequipDelete then
        nogive = true
    end
    
    local fuck = false
    if (not nogive) and ItemTable.BackPack and ( self:GetWeight() > self:GetWeightMax() ) then
        self:Tip(3, "overburdened", Color(255,0,0,255))
        return false
    end

    if ItemTable.Weapon && !ItemTable.Tertiary then
        self:EmptyClip(ItemTable.Weapon, true)
    end
    
    if not nogive then
        self:GiveItem( ItemKey, 1, nil, quality, rarity, nil, nil, nil, nil, nil, it )
    end

    if ItemTable.DEquipFunc then ItemTable.DEquipFunc(self, item, ItemKey, rarity) end

    self:TakeCharItem( item )

    self:EmitSound("npc/combine_soldier/gear5.wav")
    
    hook.Call("DZ_OnUnEquip", GAMEMODE, self, item)

    return true
end
concommand.Add( "DequipItem", function( ply, cmd, args )
    ply:DequipItem( args[ 1 ] )
end )

function PMETA:EquipItem( item, ent, old, bypass, autoreload )
    if item == nil then return false end

    if not self:CanPerformAction() then return false end
    if !bypass and self.EquippingItem then return false end

    item = tonumber(item) or item
    
    local it    
    if !ent then
        it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    else
        it = {amount = ent:GetAmount(), class = ent:GetItem(), quality = ent:GetQuality(), rarity = ent:GetRarity(), foundtype = ent:GetFoundType(), found_id = ent:GetFounder()}
    end

    if old then
        it = GAMEMODE.Util.GetItemIDByClass(self.InvTable, item)
    end

    if it == nil then return false end

    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    local quality, rarity, foundtype, found_id, foundwhen = it.quality, it.rarity, it.foundtype or 1, it.found_id or self.ID, it.foundwhen or 0

    if not ent then
        if self:GetItemAmount( item ) < 1 then return false end
    end

    if quality < 100 then
        self:Tip( 3, "This item is too damaged to use!", Color(255,0,0) )
        return false
    end

    if ItemTable.VIP != nil and not self:IsVIP() then
        self:ChatPrint( "[Inventory] VIP Only Equippable!" )

        return false 
    end
    
    local notallowed = false
    local itemc
    for class, items in pairs( self.CharTable ) do
        local CharItem = GAMEMODE.DayZ_Items[ class ]

        for _, item in pairs(items) do
            if item.amount < 1 then continue end            
            
            if CharItem.Hat and ItemTable.Hat then notallowed = item.id itemc = item.class break end
            if CharItem.Body and ItemTable.Body then notallowed = item.id itemc = item.class break end
            if CharItem.Shoes and ItemTable.Shoes then notallowed = item.id itemc = item.class break end
            if CharItem.Pants and ItemTable.Pants then notallowed = item.id itemc = item.class break end
            if CharItem.Primary and ItemTable.Primary then notallowed = item.id itemc = item.class break end
            if CharItem.Secondary and ItemTable.Secondary then notallowed = item.id itemc = item.class break end
            if CharItem.Melee and ItemTable.Melee then notallowed = item.id itemc = item.class break end
            if CharItem.Tertiary and ItemTable.Tertiary then notallowed = item.id itemc = item.class break end
            if CharItem.BackPack and ItemTable.BackPack then notallowed = item.id itemc = item.class break end
            if CharItem.BodyArmor and ItemTable.BodyArmor then notallowed = item.id itemc = item.class break end

        end

        -- Goddamn this is ugly.
    end

    if ( ItemTable.Weapon ) and !ItemTable.Melee and self:GetFreshSpawn() > CurTime() and PHDayZ.WeaponCooldownFreshSpawns then 
        self:Tip( 3, "freshspawncooldown", Color(255,255,0) )

        --self:UpdateChar( ItemKey )
        return false 
    end

    if (itemc == ItemKey) and not ent then return false end -- no point equipping the same item

    if it.found_id == 0 then
        it.found_id = self.ID -- 0 because like below
    end
    
    if it.found_type == 0 then
        it.found_type = 1 -- 0 because item was just found, did not have data.
    end

    local Dequipped = nil
    local d_rarity, d_quality, d_foundtype, d_found_id, d_foundwhen
    if notallowed then
       local de_q = GAMEMODE.Util:GetItemByDBID(self.CharTable, notallowed)

       d_rarity = de_q.rarity
       d_quality = de_q.quality
       d_foundtype = de_q.foundtype
       d_found_id = de_q.found_id
       d_foundwhen = de_q.foundwhen

       Dequipped = self:DequipItem( notallowed, IsValid(ent) )
        //return false
    end

    if Dequipped == false then return false end

    if ent then

        if notallowed then

            local item = ents.Create( "base_item" )
            item:SetItem( itemc )
            item:SetAmount( 1 )
            item:SetQuality( d_quality or quality )
            item:SetRarity( d_rarity or rarity )
            item:SetFounder( d_found_id or found_id )
            item:SetFoundType( d_foundtype or foundtype )
            item:SetFoundWhen( d_foundwhen or foundwhen )
            item.Dropped = true
            item:SetModelScale(ItemTable.Modelscale or 1)
            item:SetPos( ent:GetPos() + Vector(0,1,10) )
            item:SetAngles( ent:GetAngles() )
            item:Activate()
            item:Spawn()

            if IsValid(item:GetPhysicsObject()) then
                item:PhysWake()
            end

        end

        if !ent.Dropped && ItemTable.Weapon then
            local wep = weapons.GetStored( ItemTable.Weapon )
            local ammotype = wep.Primary.Ammo
            if ammotype then
                local aItemTable, aItemKey = GAMEMODE.Util:GetItemByAmmoType( ammotype )
                if aItemTable && aItemTable.ClipSize then
                    local amount = math.Rand(0, aItemTable.ClipSize) 
                    if amount > 0 then
                        self:GiveItem(aItemKey, amount, nil, it.quality, 1, nil, nil, nil, nil, nil, it)
                    end
                end
            end
        end

        if ent:GetAmount() > 1 then
            ent:SetAmount( ent:GetAmount() - 1 )
        else
            ent:Remove()
        end

    else
        self:TakeItem( item, 1 )
    end
    
    local ins = DZ_GetLastInsert("players_character")

    local function itupdate( lastInsert )
        local it = {}
        if lastInsert then
            it.id = lastInsert 
        else
            it = GAMEMODE.Util:GetItemIDByClass(self.CharTable, ItemKey)
        end

        it.class = ItemKey
        it.amount = 1
        it.quality = quality
        it.rarity = rarity
        it.foundtype = foundtype
        it.found_id = found_id
        it.foundwhen = foundwhen

        if !bypass then
            self:EmitSound("npc/combine_soldier/gear5.wav")
        end
        if ItemTable.EquipFunc then ItemTable.EquipFunc(self, item, ItemKey, rarity) end

        hook.Call("DZ_OnEquip", GAMEMODE, self, item)

        self.CharTable[ ItemKey ] = self.CharTable[ ItemKey ] or {}
        self.CharTable[ ItemKey ][ it.id ] = it
        self:UpdateChar( it.id, ItemKey, nil, ItemTable.Weapon && autoreload )

        if ItemTable.Weapon then
            net.Start("dz_addslot")
                net.WriteTable(it)
            net.Send(self)
        end

        self.EquippingItem = false
    end

    self.EquippingItem = item

    --itupdate( ins )

    PLib:RunPreparedQuery({ sql = "INSERT INTO `players_character` ( `user_id`, `item`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` ) VALUES ( " .. self.ID .. ", '" .. ItemKey .. "', "..quality..", "..rarity..", "..foundtype..", "..found_id..", "..foundwhen.." );", 
    callback = function( data )
        --lastInsert = data
        itupdate(data)
    end })

    DZ_AddPredictedInsert("players_character") -- add 1 as we are about to update

    return true
end
concommand.Add( "EquipItem", function( ply, cmd, args )
    ply:EquipItem( args[ 1 ] )
end )


DZ_FounderNames = DZ_FounderNames or {}
net.Receive("dz_foundernameReq", function(len, ply)
    local id_req = net.ReadInt(32)

    if !id_req then return end

    if DZ_FounderNames[ id_req ] then 
        net.Start("dz_updateFounders")
            net.WriteString( DZ_FounderNames[ id_req ] )
            net.WriteInt( id_req, 32 )
        net.Send(ply)
        return 
    end

    PLib:RunPreparedQuery({ sql = "SELECT `lastnick` FROM `players` WHERE `id` = " .. id_req .. ";", 
    callback = function( data )
        data = data[1]
        if data && data[ "lastnick" ] then
            DZ_FounderNames[ id_req ] = data[ "lastnick" ]

            net.Start("dz_updateFounders")
                net.WriteString( data[ "lastnick" ] )
                net.WriteInt( id_req, 32 )
            net.Send(ply)
        end
    end })

end)

net.Receive("base_ItemAction", function(len, ply)
    local usetype = net.ReadUInt(4) 
    local entindex = net.ReadUInt(32)
    local ty = net.ReadUInt(4)

    local ent = Entity(entindex)
    if not IsValid(ent) then return end

    if ent:GetClass() != "base_item" then return end -- Incase some fucker starts exploiting.
    
    if ent:GetPos():DistToSqr(ply:GetPos()) > (500*500) then return end -- yeah. Fuck you velkon.

    if ent:IsOnFire() then
        ply:Tip(3, "ouchfire", Color(255,0,0) ) 
        ply:TakeBlood(5)
        ply:Ignite( math.random(2, 5) )
        ply:EmitSound("vo/npc/male01/pain0"..math.random(8,9)..".wav", 75, 100, 1)
        ply:ViewPunch(Angle(-10, 0, 0))
        return false 
    end

    if usetype == 1 then
        ent:Consume( ply, ty )
    elseif usetype == 2 then
        ent:Pickup( ply )
    elseif usetype == 3 then
        ent:CustomFunc( ply )
    elseif usetype == 4 then
        ent:IgniteFunc( ply )
    elseif usetype == 5 then
        
        ply:EquipItem( ent.ItemTable.ID, ent )

    end

end)

local Doors = {
    ["func_door"] = function( self )
        return ( self:GetSaveTable().m_toggle_state == 0 )
    end,
    ["func_door_rotating"] = function( self )
        return ( self:GetSaveTable().m_toggle_state == 0 )
    end,
    ["prop_door_rotating"] = function( self )
        return ( self:GetSaveTable().m_eDoorState ~= 0 )
    end,
}

function IsDoor( door )
    if Doors[door:GetClass()] != nil then return true end
    return false
end

function DoorIsOpen( door )
    local func = Doors[door:GetClass()]
    if func then
        return func( door )
    end
end

hook.Add("KeyPress", "FireTraceEvent", function(ply, key)
    if key != IN_USE then return end
    
    local tr = ply:GetEyeTraceNoCursor()

    if tr.HitPos:Distance( ply:GetPos() ) > 200 then return end -- nope!

    if !ply:CanPerformAction() then return end

    local doored = false
    if ply:GetSafeZone() or ply:GetSafeZoneEdge() then
        local ent = tr.Entity
        if IsValid(ent) && IsDoor(ent) && !DoorIsOpen( ent ) then
            ent:Fire("open") -- open sesame.
            doored = true
        end
    end

    if doored then return end -- no furter

    if ply:GetVelocity():Length() > 5 then return end

    local vec = Vector(100,100,100)
    local found_ent = false

    local ie = {}
    ie["base_item"] = true
    ie["prop_ragdoll"] = true
    ie["base_lootable"] = true
    ie["dz_carepackage"] = true

    for _, ent in pairs( ents.FindInBox( ply:GetPos() + vec, ply:GetPos() - vec ) ) do
        if ie[ent:GetClass()] or ent:IsVehicle() then
            found_ent = true
            break
        end
    end

    if found_ent then return end

    --MsgAll(tr.HitTexture)

    local t, do_drink = "", false

    if string.find(tr.HitTexture, "snow") or tr.MatType == MAT_SNOW then
        do_drink = true
        t = "snow"
    end

    if DZ_IsInWater(tr.HitPos) then
        do_drink = true
        t = "water"
    end

    if tr.MatType == 78 && game.GetMap() == "gm_boreas" then
        do_drink = true
        t = "snow"
    end

    if do_drink then

        local function func(ply)
            ply:DrinkHurt(nil, 5, 20, true)
        end

        ply:DoModelProcess(ply:GetModel(), "Drinking "..t, 5, "npc/barnacle/barnacle_gulp1.wav", 0, "", false, func)

        return
    end
end)