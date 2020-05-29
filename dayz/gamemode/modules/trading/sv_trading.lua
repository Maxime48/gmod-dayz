local PMETA = FindMetaTable("Player")
util.AddNetworkString("UpdateTrade")
util.AddNetworkString("UpdateTradeFull")
util.AddNetworkString("net_tradeMenu")
util.AddNetworkString("net_tradeConfirm")
util.AddNetworkString("net_tradeInvite")

local function InsertConfig()

end
hook.Add("DZ_InitialLoad", "InsertTradeConfig", InsertConfig)

local function tradeComplete(ply, other)
    if !IsValid(ply) or !IsValid(other) then return end

    ply.tradingWith = nil
    ply.tradeConfirmed = false

    other.tradingWith = nil
    other.tradeConfirmed = false

    ply:EmitSound("items/ammo_pickup.wav", 75, 100, 0.5)
    other:EmitSound("items/ammo_pickup.wav", 75, 100, 0.5)

    if ply.SetProcessName then ply:SetProcessName("") end
    if other.SetProcessName then other:SetProcessName("") end

    local str = ""

    for class, items in pairs(ply.tradeTable) do   
        for _, item in pairs(items) do
            local amount = tonumber(item.amount)
            if amount < 1 then continue end
            str = str .. ", ".. GAMEMODE.DayZ_Items[item.class].Name .. " (x"..amount..")"

            other:GiveItem(item.class, amount, nil, item.quality, item.rarity)

            ply:TakeItem(item.id, amount)

        end

    end

    net.Start("net_tradeMenu")
        net.WriteBool(true)
    net.Send(ply)    

    local ostr = ""
    for class, items in pairs(other.tradeTable) do

        for _, item in pairs(items) do
            local amount = tonumber(item.amount)

            if amount < 1 then continue end
            ostr = ostr .. ", ".. GAMEMODE.DayZ_Items[item.class].Name .. " (x"..amount..")"
            
            ply:GiveItem(item.class, amount, nil, item.quality, item.rarity)
            other:TakeItem(item.id, amount)

        end

    end

    net.Start("net_tradeMenu")
        net.WriteBool(true)
    net.Send(other)

    if str == "" then str = " Nothing!" end
    if ostr == "" then ostr = " Nothing!" end
    ply:PrintMessage(HUD_PRINTTALK, "Trade with "..other:Nick().." complete! Gained"..ostr)
    other:PrintMessage(HUD_PRINTTALK, "Trade with "..ply:Nick().." complete! Gained"..str)

    ply.tradeTable = {}
    other.tradeTable = {}

end

local function startTrade(ply, cmd, args)
    if !args[1] then return end

    if IsValid(ply.tradingWith) then ply:PrintMessage(HUD_PRINTTALK, "You are currently trading with "..ply.tradingWith:Nick().."!") return "" end

    name = string.lower(args[1]);
    local foundply = GAMEMODE.Util:GetPlayerByName(name)

    if !IsValid(foundply) then return end
    if ply == foundply then return end

    if ply:GetPos():DistToSqr(foundply:GetPos()) > ( 400 * 400 ) then ply:PrintMessage(HUD_PRINTTALK, foundply:Nick().. " is too far away, unable to trade.") return "" end

    --if !( ply:GetSafeZone() or ply:GetSafeZoneEdge() ) then ply:PrintMessage(HUD_PRINTTALK, "You are not in the safezone, unable to trade.") return "" end
    --if !(foundply:GetSafeZone() or foundply:GetSafeZoneEdge() ) then ply:PrintMessage(HUD_PRINTTALK, foundply:Nick().." is not in the safezone, unable to trade.") return "" end

    ply.tradeInvites = ply.tradeInvites or {}

    if ( ply.tradeInvites[ foundply:EntIndex() ] or 0 ) > CurTime() then 
        local time = math.Round( ply.tradeInvites[ foundply:EntIndex() ] - CurTime() )
        ply:PrintMessage(HUD_PRINTTALK, "Wait "..time.."s before trade inviting "..foundply:Nick().." again!")
        --return ""
    end

    ply.tradeInvites[ foundply:EntIndex() ] = CurTime() + 5

    foundply.invitedBy = ply
    foundply.tradeInviteAccepted = false

    net.Start("net_tradeInvite")
        net.WriteString(ply:Nick())
        net.WriteFloat( CurTime()+30 )
    net.Send(foundply)

    ply:PrintMessage(HUD_PRINTTALK, "Trade invite sent to "..foundply:Nick().."!")

    return ""
end
concommand.Add("starttrade", startTrade)

net.Receive( "net_tradeInvite", function( len, ply )
    if not IsValid(ply) then return end
    if !IsValid(ply.invitedBy) then return end
    local bool = net.ReadBool()

    if bool then 
        ply.tradeInviteAccepted = true
    else
        ply.invitedBy.tradeInvites[ ply:EntIndex() ] = CurTime() + 60

        ply.invitedBy = nil
        ply.tradeInviteAccepted = nil
    end
end)

local function confirmTrade(ply, cmd, args)
    if !IsValid(ply.tradingWith) then return end
    local other = ply.tradingWith

    ply.tradeConfirmed = true

    --if table.Count(ply.tradeTable) > 0 then
        net.Start("net_tradeConfirm")
        net.Send( other )
    --end

end
concommand.Add("confirmtrade", confirmTrade)

local function addToTrade(ply, cmd, args)

    if !args[1] then return end

    local item = tonumber(args[1])
    local amount = tonumber(args[2]) or 1

    if amount < 1 then amount = 1 end

    local it = GAMEMODE.Util:GetItemByDBID(ply.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    ply.tradeTable[it.class] = ply.tradeTable[it.class] or {}
    ply.tradeTable[it.class][item] = table.Copy(it)    
    ply.tradeTable[it.class][item].amount = amount -- override./

    ply.tradeConfirmed = false

    if IsValid(ply.tradingWith) then
        
        net.Start("UpdateTradeFull")
            net.WriteTable(ply.tradeTable)
            net.WriteBool(true)
        net.Send(ply.tradingWith)

        ply.tradingWith.tradeConfirmed = false

    end

    net.Start("UpdateTradeFull")
        net.WriteTable(ply.tradeTable)
        net.WriteBool(false)
    net.Send(ply)

end
concommand.Add("Tradeofferitem", addToTrade)

local function removeFromTrade(ply, cmd, args)

    if !args[1] then return end

    local item = tonumber(args[1])

    local it = GAMEMODE.Util:GetItemByDBID(ply.InvTable, item)
    if it == nil then return false end
    local ItemTable, ItemKey = GAMEMODE.DayZ_Items[ it.class ], it.class
    if ItemTable == nil then return false end

    ply.tradeTable[it.class][it.id] = nil
    ply.tradeConfirmed = false

    if IsValid(ply.tradingWith) then
        
        net.Start("UpdateTradeFull")
            net.WriteTable(ply.tradeTable)
            net.WriteBool(true)
        net.Send( ply.tradingWith )
        ply.tradingWith.tradeConfirmed = false

    end

    net.Start("UpdateTradeFull")
        net.WriteTable(ply.tradeTable)
        net.WriteBool(false)
    net.Send(ply)
end
concommand.Add("Cancelofferitem", removeFromTrade)

local function cancelTrade(ply)

    ply.tradeTable = {}
    local other = ply.tradingWith
    ply.tradingWith = nil
    if IsValid(other) then
        other.tradeTable = {}
        other.tradingWith = nil
    end
    if IsValid(other) then
        
        net.Start("net_tradeMenu")
            net.WriteBool(true)
        net.Send(other)

        net.Start("UpdateTradeFull")
            net.WriteTable(ply.tradeTable)
            net.WriteBool(true)
        net.Send(other)
        if other.SetProcessName then other:SetProcessName("") end

    end

    if ply.SetProcessName then ply:SetProcessName("") end
    net.Start("UpdateTradeFull")
        net.WriteTable(ply.tradeTable)
        net.WriteBool(false)
    net.Send(ply)

end
concommand.Add("Canceltrade", cancelTrade)

local function doTradeLogic(ply)
    if ( ply.nextTradeThink or 0 ) > CurTime() then return end

    if ply.tradeInviteAccepted && ply.invitedBy then
        local other = ply.invitedBy

        ply.tradeTable = {}
        net.Start("net_tradeMenu")
            net.WriteBool(false)
            net.WriteEntity(other)
        net.Send(ply)

        other.tradeTable = {}
        net.Start("net_tradeMenu")
            net.WriteBool(false)
            net.WriteEntity(ply)
        net.Send(other)

        ply.tradingWith = other
        ply.tradeConfirmed = false
        other.tradingWith = ply
        other.tradeConfirmed = false

        ply.tradeInviteAccepted = nil
        ply.invitedBy = nil
        other.tradeInviteAccepted = nil
        other.invitedBy = nil
    end

    if IsValid(ply.tradingWith) then
        local other = ply.tradingWith

        if ply.tradeConfirmed and other.tradeConfirmed then
            tradeComplete(ply, other)
        end 
    else
        ply.tradingWith = nil
    end

    ply.nextTradeThink = CurTime() + 1
end
hook.Add("PlayerTick", "TradeThink", doTradeLogic)
hook.Add("VehicleMove", "TradeThink", doTradeLogic)

local function tradeText(ply, text, team)
    if ( string.sub( text, 2, 6 ) == "trade" ) then
        local args = string.Explode(" ", text);
        local plyname = args[2]
        return startTrade(ply, "starttrade", {args[2]})
    end
end
hook.Add("PlayerSay", "tradeText", tradeText)