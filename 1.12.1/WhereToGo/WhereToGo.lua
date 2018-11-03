SLASH_WHERE1, SLASH_WHERE2 = '/where', '/wtg';
function SlashCmdList.WHERE(msg, editBox)
	zones = {{1, 10, "[A] Dun Morogh"}, {1, 10, "[H] Durotar"}, {1, 10, "[A] Elwynn Forest"}, {1, 10, "[H] Mulgore"}, {1, 10, "[A] Teldrassil"}, {1, 10, "[H] Tirisfal Glades"}, {10, 20, "[A] Darkshore"}, {10, 20, "[A] Loch Modan"}, {10, 20, "[H] Silverpine Forest"}, {10, 20, "[A] Westfall"}, {10, 25, "[H] Barrens"}, {15, 25, "[A] Redridge Mountains"}, {15, 27, "Stonetalon Mountains"}, {18, 30, "Ashenvale"}, {18, 30, "[A] Duskwood"}, {20, 30, "Hillsbrad Foothills"}, {20, 30, "[A] Wetlands"}, {25, 35, "[H] Thousand Needles"}, {30, 40, "Alterac Mountains"}, {30, 40, "Arathi Highlands"}, {30, 40, "Desolace"}, {30, 45, "Stranglethorn Vale"}, {35, 45, "Dustwallow Marsh"}, {35, 45, "[H] Badlands"}, {35, 45, "[H] Swamp of Sorrows"}, {40, 50, "Feralas"}, {40, 50, "Hinterlands"}, {40, 50, "Tanaris"}, {45, 50, "Searing Gorge"}, {45, 55, "Azshara"}, {45, 55, "Blasted Lands"}, {48, 55, "Un'goro Crater"}, {48, 55, "Felwood"}, {50, 58, "Burning Steppes"}, {51, 58, "Western Plaguelands"}, {55, 60, "Deadwind Pass"}, {53, 60, "Eastern Plaguelands"}, {53, 60, "Winterspring"}, {55, 60, "Moonglade"}, {55, 60, "Silithus"}}
	if msg == "" then
		msg = UnitLevel("player")
	end
	msg = tonumber(msg)
	for i=1,39,1 do
		if msg <= zones[i][2] and msg >= zones[i][1] then
			print("WhereToGo: [" .. zones[i][1] .. "-" .. zones[i][2] .. "] " .. zones[i][3])
		end
	end
end