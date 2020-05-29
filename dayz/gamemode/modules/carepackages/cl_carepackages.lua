net.Receive( "SendCarePackageVectors", function()
	CarePackageSpawns = net.ReadTable()
end)

local function DrawTheText(text, x, y, color, font)
	draw.SimpleText(text, font, x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- preparing for 5.0.1 1040296
hook.Add("DZ_DrawMapSetup", "DrawCarePackages", function(font, font2)

	for k, v in pairs(CarePackageSpawns) do
		local pos = v:ToScreen()

		if v:DistToSqr(LocalPlayer():GetPos()) > MaxDist * MaxDist then continue end

		DrawTheText( "c", pos.x, pos.y, Color(255,0,0), font )

		if ShowLegend == 1 then
			DrawTheText( "Care Package", pos.x, pos.y - 16, Color(255,0,0), font2 )
		end
	end

end)

hook.Add("DZ_AddSetupMenuItem", "AddCarePackageButton", function()
	local but = {
        name = "Care Package",
        command = "carepackage",
        item = "att_acog",
        color = Color(255, 0, 0),
        letter = "c"
    }

    table.insert(AdminMenu_SpawnButtons_Extra, but)
end)