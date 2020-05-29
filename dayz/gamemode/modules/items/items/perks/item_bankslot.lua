ITEM = {}
ITEM.Name = "+100 Bank Space"
ITEM.Angle = Angle(0,0,0)
ITEM.Desc = "Unlocks 100 more space in the bank - Max +2000.\nAuto-refunds credits at limit."
ITEM.Model = "models/fallout 3/backpack_1.mdl"
ITEM.Color = Color(255, 210, 0)
ITEM.Material = "models/shiny"
ITEM.Weight = 0
ITEM.Credits = 100
ITEM.SpawnChance = -1
ITEM.NoConsumeFromFloor = true
ITEM.SpawnOffset = Vector(0,0,3.5)
ITEM.ProcessFunction = function(ply, item) if ply:GetNWInt( "extraslots" ) >= 2000 then ply:ChatPrint("You already have the max extra bank slots! Refunded!") ply:GiveItem("item_credits", 100) return end ply:GiveBankSlots(100) ply:EmitSound( "smb3_powerup.wav", 35, 100 ) ply:ChatPrint("You unlocked an extra 100 bank space!") end