util.AddNetworkString( "UpdateBank" )
util.AddNetworkString( "UpdateBankFull" )
util.AddNetworkString( "UpdateBankWeight" )

function PMETA:UpdateBank( item, del )
	del = del or false
	if item != nil then
		item = tonumber(item) or item
		
		net.Start( "UpdateBank" )
			net.WriteTable(item)
			net.WriteBool(del)
		net.Send( self )
	else
		for k, items in pairs( self.BankTable ) do
			--MsgAll(k)
			net.Start("UpdateBankFull")
				net.WriteString(k)
				net.WriteTable(items)
			net.Send( self )
		end
	end
	
	self:CalculateWeight()
end

function PMETA:Deposit( item, amount, noauto )
	if item == nil and amount == nil then return false end
	
	item = tonumber(item) or item
	
	if self.NextDeposit and self.NextDeposit > CurTime() then return false end
	self.NextDeposit = CurTime() + 0.1
	
	if !self:GetSafeZone() then
		self:Tip(3, "youneedszbank", Color(255,255,0))
		return
	end
	
	local illness = ""
	if self:GetSick() then illness = "sick" end
	if self:GetRadiation() > 20 then illness = "irradiated" end
	if self:GetHunger() == 0 then illness = "starving" end
	if self:GetThirst() == 0 then illness = "dehydrated" end

	if illness != "" then self:ChatPrint("You can't deposit while "..illness.."!") return false end

	if !self:CanPerformAction() then return false end

	local it = GAMEMODE.Util:GetItemByDBID(self.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

	if !self.BankWeightCur then return false end

	amount = math.Round( amount )
	if amount < 1 then return false end
	
	local maxbankweight = PHDayZ.BankMaxWeight[ self:GetHelperUserGroup() ] or PHDayZ.DefaultBankWeight

	if self.BankWeightCur + ( ItemTable.Weight * amount ) > ( maxbankweight + self:GetNWInt( "extraslots" ) ) and ItemKey != "item_money" then -- Allow money to be placed in bank regardless of weight limits.
		self:ChatPrint( "Your bank can't carry anymore." )

		return false
	end

	if !self:HasItemAmount(item, amount) then return false end -- Exploit patch 3.191

	if !self:TakeItem( item, amount ) then return false end

    local stacked = false
    local always_stack = {"item_money", "item_credits"} --no quality, ignore and autostack
    if !noauto then
        local its = GAMEMODE.Util:GetItemIDsByClass(self.BankTable, ItemKey)
        for _, it2 in pairs(its) do
            if GetCondition( it2.quality ) == GetCondition( it.quality ) or (table.HasValue(always_stack, it.class) and table.HasValue(always_stack, it2.class)) then
            	if it.rarity != it2.rarity then continue end

                amount = it2.amount + amount

                --self:SetItem(it2.id, amount)

                self.BankTable[ ItemKey ] =  self.BankTable[ ItemKey ] or {}
                if !self.BankTable[ ItemKey ][it2.id] then continue end
                self.BankTable[ ItemKey ][it2.id].amount = amount
                self:UpdateBank( it2 )
                PLib:QuickQuery( "UPDATE `players_bank` SET `amount` = " .. amount .. " WHERE `id` = " .. it2.id .. ";" )

                hook.Call("DZ_OnBankItem", GAMEMODE, self, ItemKey, amount)

                stacked = true
                break
            end
        end
    end
    
	self:EmitSound("npc/combine_soldier/gear"..math.random(1,4)..".wav", 75, 100, 0.5)

	DzLog(7, "Player '"..self:Nick().."' ("..self:SteamID()..") Deposited "..ItemTable.Name.."' x"..math.Round(amount) )

    if stacked then return end
	
	--local BankCurItemAmount = self:GetItemAmount(it.id, true)

	local quality, rarity, foundtype, found_id, foundwhen = it.quality, it.rarity, it.foundtype or 1, it.found_id or self.ID, it.foundwhen or os.time()
	
	local ins = DZ_GetLastInsert("players_bank") 

    local function itupdate(lastInsert)
        local it = {}
        it.id = lastInsert
        it.class = ItemKey
        it.amount = amount
        it.quality = quality
        it.rarity = rarity
        it.found_id = found_id
        it.foundtype = foundtype
        it.foundwhen = foundwhen

        self.BankTable[ ItemKey ] = self.BankTable[ ItemKey ] or {}
		self.BankTable[ ItemKey ][ lastInsert ] = it
        self:UpdateBank( it )

        hook.Call("DZ_OnBankItem", GAMEMODE, self, ItemKey, amount)
    end
    --itupdate( ins )

  	PLib:RunPreparedQuery({ sql = "INSERT INTO `players_bank` ( `user_id`, `item`, `amount`, `quality`, `durability`, `foundtype`, `found_id`, `foundwhen` ) VALUES ( " .. self.ID .. ", '" .. ItemKey .. "', " .. amount .. ", "..quality..", "..rarity..", " .. foundtype .. ", " .. found_id .. ", "..foundwhen.." );", 
    callback = function( data )
        itupdate(data)
    end })
	
	DZ_AddPredictedInsert("players_bank") -- add 1 as we are about to update

end
concommand.Add( "DepositItem", function( ply, cmd, args ) 
	ply:Deposit( args[ 1 ], args[ 2 ] ) 
end )

function PMETA:Withdraw( item, amount )
	if item == nil and amount == nil then return false end
	
	if !self:GetSafeZone() then
		self:Tip(3, "youneedszbank", Color(255,255,0))
		return
	end
	
	if self.NextWithdraw and self.NextWithdraw > CurTime() then return false end
	self.NextWithdraw = CurTime() + 0.5
	
	if !self:CanPerformAction() then return false end
	
	item = tonumber(item) or item
	
	local it = GAMEMODE.Util:GetItemByDBID(self.BankTable, item)
	--PrintTable(self.BankTable)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

	amount = math.Round( amount )
	if amount < 0 then return false end 

	local CurItemAmount = it.amount
	if CurItemAmount < 1 then return false end
	
	if amount > CurItemAmount then amount = CurItemAmount end
				
	local NewItemAmount = CurItemAmount - amount
	local quality = it.quality or math.random(100, 700)
	local rarity = it.rarity

	if NewItemAmount < 1 then
		self.BankTable[ ItemKey ] = self.BankTable[ ItemKey ] or {}
		self.BankTable[ ItemKey ][item] = nil

		PLib:QuickQuery( "DELETE FROM `players_bank` WHERE `id` = " .. item .. ";" )
	else
		self.BankTable[ ItemKey ] = self.BankTable[ ItemKey ] or {}
		self.BankTable[ ItemKey ][item] = it

		PLib:QuickQuery( "UPDATE `players_bank` SET `amount` = " .. NewItemAmount .. " WHERE `id` = " .. item .. ";" )
	end

	it.amount = NewItemAmount

	self:EmitSound("npc/combine_soldier/gear"..math.random(1,4)..".wav", 75, 100, 0.5)

	DzLog(7, "Player '"..self:Nick().."' ("..self:SteamID()..") Withdrew "..ItemTable.Name.."' x"..math.Round(amount) )

	hook.Call("DZ_OnWithdrawItem", GAMEMODE, self, ItemKey, amount)

	self:GiveItem( ItemKey, amount, nil, quality, rarity, nil, nil, nil, nil, true, it )
	self:UpdateBank( it )
end
concommand.Add( "WithdrawItem", function( ply, cmd, args ) 
	ply:Withdraw( args[ 1 ], args[ 2 ] ) 
end )