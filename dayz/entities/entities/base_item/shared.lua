ENT.Type 		= "anim"
ENT.PrintName	= ""
ENT.Author		= "Phoenixf129"
ENT.Contact		= ""


function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "Item" )
	self:NetworkVar( "Int", 0, "Amount" )
	self:NetworkVar( "Int", 1, "Perish" )
	self:NetworkVar( "Int", 2, "Rarity" )
	self:NetworkVar( "Int", 3, "Quality" )
	self:NetworkVar( "Int", 4, "Founder" )
	self:NetworkVar( "Int", 5, "FoundType" )
	self:NetworkVar( "Int", 6, "FoundWhen" )
	self:NetworkVar( "Bool", 0, "SafeZone")
	self:NetworkVar( "Entity", 0, "Activator" )

end

function ENT:Initialize()
	local Class = self:GetItem()

	if Class == nil then
		self:Remove()
	end
	
	self.RanTouch = false
	
	Class = tonumber(Class) or Class
	
	local ItemTable, ItemKey
	if isnumber( Class ) then
		ItemTable, ItemKey = GAMEMODE.DayZ_Items_OLD[ Class ], Class
	elseif ( isstring( Class ) ) then
		ItemTable, ItemKey = GAMEMODE.Util:GetItemByID( Class )
	end
	
	if !ItemTable then print("No ItemTable for Class "..Class) self:Remove() return end

	self.ItemTable = ItemTable

	if SERVER then

		self:SetModel( ItemTable.Model )

		if ItemTable.Material then
			self:SetMaterial( ItemTable.Material )
		end

		if ItemTable.Color then
			self:SetColor( ItemTable.Color )
		end

		local rarity = GetRarity( self:GetRarity() or 1 )
		if rarity && ItemTable.Weapon then
			self:SetColor(rarity.color)
		end
		
		if ItemTable.Skin then
			self:SetSkin( ItemTable.Skin )
		end

		if ItemTable.BodyGroups then
			self:SetBodyGroups( ItemTable.BodyGroups )
		end

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		--self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		self:SetUseType( SIMPLE_USE )
		self:SetHealth( 300 )

		self:SetRenderMode(1)
		self:SetSaveValue("fademindist", 2048)
		self:SetSaveValue("fademaxdist", 4096)

		local phys = self:GetPhysicsObject()
		local vol = 1
		if IsValid(phys) then
			local mins, maxs = phys:GetAABB()
			vol = math.abs(maxs.x-mins.x) * math.abs(maxs.y-mins.y) * math.abs(maxs.z-mins.z)
			vol = vol/(24^3)
		end

		if !IsValid(phys) or ( vol > 1 ) or ( vol < 0.0001 ) then -- too small
			//local mins, maxs = self:WorldSpaceAABB()
			local mins, maxs = self:OBBMins(), self:OBBMaxs()
			self:PhysicsInitBox( mins, maxs ) -- Hacky i know.
			self:SetCollisionBounds( mins, maxs )

			if PHDayZ.DebugMode then
				MsgC(Color(255,150,0), "[PHDayZ] Item "..ItemTable.Name.." doesn't have a Valid Physics Model - Generating one!\n")
			end
		else
			phys:SetMass(20)
		end

		if !self.NoCalcPos then
			if self.Dropped == true then
				
				self:SetMoveType( MOVETYPE_VPHYSICS )
				
			else

				local height = self:OBBMins()
				self:SetPos( (self:GetPos() - Vector( 0, 0, height[3] )) + Vector(0, 0, 5) )

				local tr = util.TraceLine( {
					start = self:GetPos(), 
					endpos = self:GetPos() - Vector(0,0,100), 
					filter = self
				} )

				if tr.Fraction > 0.01 then 
					self:SetPos( tr.HitPos + Vector( 0, 0, math.abs(height[3]) ))
				end

			end
		end

		local perishtime = PHDayZ.ItemPerishTime or 300
		if !self.Dropped then
			perishtime = perishtime * 2
		end

		self:SetPerish( CurTime() + perishtime )
		--self:SetCondition(math.Rand(1, 1000))

		if !self.NoCalcPos then
			if IsValid(phys) then phys:Wake() end
		end
	end
end