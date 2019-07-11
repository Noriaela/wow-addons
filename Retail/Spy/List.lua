local HBDP = LibStub("HereBeDragons-Pins-2.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("Spy")
local _

function Spy:RefreshCurrentList(player, source)
	local MainWindow = Spy.MainWindow
	if not MainWindow:IsShown() then
		return
	end

	local mode = Spy.db.profile.CurrentList
	local manageFunction = Spy.ListTypes[mode][2]
	if manageFunction then manageFunction() end

	local button = 1
	for index, data in pairs(Spy.CurrentList) do
		if button <= Spy.ButtonLimit then
			local level = "??"
			local class = "UNKNOWN"
			local opacity = 1

			local playerData = SpyPerCharDB.PlayerData[data.player]
			if playerData then
				if playerData.level then
					level = playerData.level
					if playerData.isGuess == true and tonumber(playerData.level) < Spy.MaximumPlayerLevel then level = level.."+" end
				end
				if playerData.class then class = playerData.class end
			end

			local description = level.." "
			if L[class] and type(L[class]) == "string" then description = description..L[class] end

			if mode == 1 and Spy.InactiveList[data.player] then
				opacity = 0.5
			end
			if player == data.player then
				if not source or source ~= Spy.CharacterName then
					Spy:AlertPlayer(player, source)
					if not source then Spy:AnnouncePlayer(player) end
				end
			end

			Spy:SetBar(button, data.player, description, 100, "Class", class, nil, opacity)
			Spy.ButtonName[button] = data.player
			button = button + 1
		end
	end
	Spy.ListAmountDisplayed = button - 1

	if Spy.db.profile.ResizeSpy then
		Spy:AutomaticallyResize()
	else if not InCombatLockdown() and Spy.MainWindow:GetHeight()< 34 then 
		Spy:RestoreMainWindowPosition(Spy.MainWindow:GetLeft(), Spy.MainWindow:GetTop(), Spy.MainWindow:GetWidth(), 34) end	 			
	end
	Spy:ManageBarsDisplayed()
end

function Spy:ManageNearbyList()
	local prioritiseKoS = Spy.db.profile.PrioritiseKoS

	local activeKoS = {}
	local active = {}
	for player in pairs(Spy.ActiveList) do
		local position = Spy.NearbyList[player]
		if position ~= nil then
			if prioritiseKoS and SpyPerCharDB.KOSData[player] then
				table.insert(activeKoS, { player = player, time = position })
			else
				table.insert(active, { player = player, time = position })
			end
		end
	end

	local inactiveKoS = {}
	local inactive = {}
	for player in pairs(Spy.InactiveList) do
		local position = Spy.NearbyList[player]
		if position ~= nil then
			if prioritiseKoS and SpyPerCharDB.KOSData[player] then
				table.insert(inactiveKoS, { player = player, time = position })
			else
				table.insert(inactive, { player = player, time = position })
			end
		end
	end

	table.sort(activeKoS, function(a, b) return a.time < b.time end)
	table.sort(inactiveKoS, function(a, b) return a.time < b.time end)
	table.sort(active, function(a, b) return a.time < b.time end)
	table.sort(inactive, function(a, b) return a.time < b.time end)

	local list = {}
	for player in pairs(activeKoS) do table.insert(list, activeKoS[player]) end
	for player in pairs(inactiveKoS) do table.insert(list, inactiveKoS[player]) end
	for player in pairs(active) do table.insert(list, active[player]) end
	for player in pairs(inactive) do table.insert(list, inactive[player]) end
	Spy.CurrentList = list
end

function Spy:ManageLastHourList()
	local list = {}
	for player in pairs(Spy.LastHourList) do
		table.insert(list, { player = player, time = Spy.LastHourList[player] })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:ManageIgnoreList()
	local list = {}
	for player in pairs(SpyPerCharDB.IgnoreData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		local position = time()
		if playerData then position = playerData.time end
		table.insert(list, { player = player, time = position })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:ManageKillOnSightList()
	local list = {}
	for player in pairs(SpyPerCharDB.KOSData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		local position = time()
		if playerData then position = playerData.time end
		table.insert(list, { player = player, time = position })
	end
	table.sort(list, function(a, b) return a.time > b.time end)
	Spy.CurrentList = list
end

function Spy:GetNearbyListSize()
	local entries = 0
	for v in pairs(Spy.NearbyList) do
		entries = entries + 1
	end
	return entries
end

function Spy:UpdateActiveCount()
    local activeCount = 0
    for k in pairs(Spy.ActiveList) do
        activeCount = activeCount + 1
    end
	local theFrame = Spy.MainWindow
    if activeCount > 0 then 
		theFrame.CountFrame.Text:SetText("|cFF0070DE" .. activeCount .. "|r") 
    else 
        theFrame.CountFrame.Text:SetText("|cFF0070DE0|r")
    end
end

function Spy:ManageExpirations()
	local mode = Spy.db.profile.CurrentList
	local expirationFunction = Spy.ListTypes[mode][3]
	if expirationFunction then expirationFunction() end
end

function Spy:ManageNearbyListExpirations()
	local expired = false
	local currentTime = time()
	for player in pairs(Spy.ActiveList) do
		if (currentTime - Spy.ActiveList[player]) > Spy.ActiveTimeout then
			Spy.InactiveList[player] = Spy.ActiveList[player]
			Spy.ActiveList[player] = nil
			expired = true
		end
	end
	if Spy.db.profile.RemoveUndetected ~= "Never" then
		for player in pairs(Spy.InactiveList) do
			if (currentTime - Spy.InactiveList[player]) > Spy.InactiveTimeout then
				if Spy.PlayerCommList[player] ~= nil then
					Spy.MapNoteList[Spy.PlayerCommList[player]].displayed = false
					Spy.MapNoteList[Spy.PlayerCommList[player]].worldIcon:Hide()
					HBDP:RemoveMinimapIcon(self, Spy.MapNoteList[Spy.PlayerCommList[player]].miniIcon)
					Spy.PlayerCommList[player] = nil
				end
				Spy.InactiveList[player] = nil
				Spy.NearbyList[player] = nil
				expired = true
			end
		end
	end
	if expired then
		Spy:RefreshCurrentList()
		Spy:UpdateActiveCount()
		if Spy.db.profile.HideSpy and Spy:GetNearbyListSize() == 0 then 
			if not InCombatLockdown() then
				Spy.MainWindow:Hide()
			else	
				Spy:HideSpyCombatCheck()
			end
		end
	end
end

function Spy:ManageLastHourListExpirations()
	local expired = false
	local currentTime = time()
	for player in pairs(Spy.LastHourList) do
		if (currentTime - Spy.LastHourList[player]) > 3600 then
			Spy.LastHourList[player] = nil
			expired = true
		end
	end
	if expired then
		Spy:RefreshCurrentList()
	end
end

function Spy:RemovePlayerFromList(player)
	Spy.NearbyList[player] = nil
	Spy.ActiveList[player] = nil
	Spy.InactiveList[player] = nil
	if Spy.PlayerCommList[player] ~= nil then
		Spy.MapNoteList[Spy.PlayerCommList[player]].displayed = false
		Spy.MapNoteList[Spy.PlayerCommList[player]].worldIcon:Hide()
		HBDP:RemoveMinimapIcon(self, Spy.MapNoteList[Spy.PlayerCommList[player]].miniIcon)
		Spy.PlayerCommList[player] = nil
	end
	Spy:RefreshCurrentList()
	Spy:UpdateActiveCount()	
end

function Spy:ClearList()
	Spy.NearbyList = {}
	Spy.ActiveList = {}
	Spy.InactiveList = {}
	Spy.PlayerCommList = {}
	Spy.ListAmountDisplayed = 0
	for i = 1, Spy.MapNoteLimit do
		Spy.MapNoteList[i].displayed = false
		Spy.MapNoteList[i].worldIcon:Hide()
		HBDP:RemoveMinimapIcon(self, Spy.MapNoteList[i].miniIcon)
	end
	Spy:SetCurrentList(1)
	if IsControlKeyDown() then
		Spy:EnableSpy(not Spy.db.profile.Enabled, false)
	end
	Spy:UpdateActiveCount()
end

function Spy:AddPlayerData(name, class, level, race, guild, isEnemy, isGuess)
	local info = {}
	info.name = name  --++ added to normalize data
	info.class = class
	if type(level) == "number" then info.level = level end
	info.race = race
	info.guild = guild
	info.isEnemy = isEnemy
	info.isGuess = isGuess
	SpyPerCharDB.PlayerData[name] = info
	return SpyPerCharDB.PlayerData[name]
end

function Spy:UpdatePlayerData(name, class, level, race, guild, isEnemy, isGuess)
	local detected = true
	local playerData = SpyPerCharDB.PlayerData[name]
	if not playerData then
		playerData = Spy:AddPlayerData(name, class, level, race, guild, isEnemy, isGuess)
	else
		if name ~= nil then playerData.name = name end  --++ added to merge addons
		if class ~= nil then playerData.class = class end
		if type(level) == "number" then playerData.level = level end
		if race ~= nil then playerData.race = race end
		if guild ~= nil then playerData.guild = guild end
		if isEnemy ~= nil then playerData.isEnemy = isEnemy end
		if isGuess ~= nil then playerData.isGuess = isGuess end
	end
	if playerData then
		playerData.time = time()
		if not Spy.ActiveList[name] then
			if (WorldMapFrame:IsVisible() and Spy.db.profile.SwitchToZone) then
				WorldMapFrame:SetMapID(C_Map.GetBestMapForUnit("player"))
			end
			if (nil == C_Map.GetBestMapForUnit("player")) or (nil == C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")) then -- 8.0 Changes
			local x,y = 0,0
				local InsName = GetInstanceInfo()
				playerData.zone = InsName
				playerData.subZone = ""
			else
				local mapX, mapY = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY() -- 8.0 Change			
					if mapX ~= 0 and mapY ~= 0 then
					mapX = math.floor(tonumber(mapX) * 100) / 100
					mapY = math.floor(tonumber(mapY) * 100) / 100
					playerData.mapX = mapX
					playerData.mapY = mapY
					playerData.zone = GetZoneText()
					playerData.mapID = C_Map.GetBestMapForUnit("player") --++8.0
					playerData.subZone = GetSubZoneText()
				else
					detected = false
				end
			end
		end	
	end
	return detected
end

function Spy:RemovePlayerData(name)
	SpyPerCharDB.PlayerData[name] = nil
end

function Spy:AddIgnoreData(name)
	SpyPerCharDB.IgnoreData[name] = true
end

function Spy:RemoveIgnoreData(name)
	if SpyPerCharDB.IgnoreData[name] then
		SpyPerCharDB.IgnoreData[name] = nil
	end
end

function Spy:AddKOSData(name)
	SpyPerCharDB.KOSData[name] = time()
--	SpyPerCharDB.PlayerData[name].kos = 1 
	if Spy.db.profile.ShareKOSBetweenCharacters then SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][name] = nil end
end

function Spy:RemoveKOSData(name)
	if SpyPerCharDB.KOSData[name] then
		local playerData = SpyPerCharDB.PlayerData[name]
		if playerData and playerData.reason then playerData.reason = nil end
		SpyPerCharDB.KOSData[name] = nil
		SpyPerCharDB.PlayerData[name].kos = nil		
		if Spy.db.profile.ShareKOSBetweenCharacters then SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][name] = time() end
	end
end

function Spy:SetKOSReason(name, reason, other)
	local playerData = SpyPerCharDB.PlayerData[name]
	if playerData then
		if not reason then
			playerData.reason = nil
		else
			if not playerData.reason then playerData.reason = {} end
			if reason == L["KOSReasonOther"] then
				if not other then 
					local dialog = StaticPopup_Show("Spy_SetKOSReasonOther", name)
					if dialog then dialog.playerName = name end
				else
					if other == "" then
						playerData.reason[L["KOSReasonOther"]] = nil
					else
						playerData.reason[L["KOSReasonOther"]] = other
					end
					Spy:RegenerateKOSCentralList(name)
				end
			else
				if playerData.reason[reason] then
					playerData.reason[reason] = nil
				else
					playerData.reason[reason] = true
				end
				Spy:RegenerateKOSCentralList(name)
			end
		end
	end
end

function Spy:AlertPlayer(player, source)
	local playerData = SpyPerCharDB.PlayerData[player]
	if SpyPerCharDB.KOSData[player] and Spy.db.profile.WarnOnKOS then
		if Spy.db.profile.DisplayWarningsInErrorsFrame then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["KOSWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)
		else
			if source ~= nil and source ~= Spy.CharacterName then
				Spy:ShowAlert("kosaway", player, source, Spy:GetPlayerLocation(playerData))
			else
				local reasonText = ""
				if playerData.reason then
					for reason in pairs(playerData.reason) do
						if reasonText ~= "" then reasonText = reasonText..", " end
						if reason == L["KOSReasonOther"] then
							reasonText = reasonText..playerData.reason[reason]
						else
							reasonText = reasonText..reason
						end
					end
				end
				Spy:ShowAlert("kos", player, nil, reasonText)
			end
		end
		if Spy.db.profile.EnableSound then
			if source ~= nil and source ~= Spy.CharacterName then
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosaway.mp3")
			else
				PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kos.mp3")
			end
		end
		if Spy.db.profile.ShareKOSBetweenCharacters then Spy:RegenerateKOSCentralList(player) end
	elseif Spy.db.profile.WarnOnKOSGuild then
		if playerData and playerData.guild and Spy.KOSGuild[playerData.guild] then
			if Spy.db.profile.DisplayWarningsInErrorsFrame then
				local text = Spy.db.profile.Colors.Warning["Warning Text"]
				local msg = L["KOSGuildWarning"].."<"..playerData.guild..">"
				UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)				
			else
				if source ~= nil and source ~= Spy.CharacterName then
					Spy:ShowAlert("kosguildaway", "<"..playerData.guild..">", source, Spy:GetPlayerLocation(playerData))
				else
					Spy:ShowAlert("kosguild", "<"..playerData.guild..">")
				end
			end
			if Spy.db.profile.EnableSound then
				if source ~= nil and source ~= Spy.CharacterName then
					PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosaway.mp3")
				else
					PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-kosguild.mp3")
				end
			end
		else
			if Spy.db.profile.EnableSound and not Spy.db.profile.OnlySoundKoS then 
				if source == nil or source == Spy.CharacterName then
					if playerData and Spy.db.profile.WarnOnRace and playerData.race == Spy.db.profile.SelectWarnRace then --++
						PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-race.mp3") 
					else
						PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-nearby.mp3")
					end
				end
			end
		end
	elseif Spy.db.profile.EnableSound and not Spy.db.profile.OnlySoundKoS then 	--++
		if source == nil or source == Spy.CharacterName then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-nearby.mp3")
		end
	end
end

function Spy:AlertStealthPlayer(player)
	if Spy.db.profile.WarnOnStealth then
		if Spy.db.profile.DisplayWarningsInErrorsFrame then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["StealthWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)						
		else
			Spy:ShowAlert("stealth", player)
		end
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-stealth.mp3")
		end
	end
end

function Spy:AlertProwlPlayer(player)
	if Spy.db.profile.WarnOnStealth then
		if Spy.db.profile.DisplayWarningsInErrorsFrame then
			local text = Spy.db.profile.Colors.Warning["Warning Text"]
			local msg = L["StealthWarning"]..player
			UIErrorsFrame:AddMessage(msg, text.r, text.g, text.b, 1.0, UIERRORS_HOLD_TIME)						
		else
			Spy:ShowAlert("prowl", player)
		end
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\detected-stealth.mp3")
		end
	end
end

function Spy:AnnouncePlayer(player, channel)
	if not Spy_IgnoreList[player] then
		local msg = ""
		local isKOS = SpyPerCharDB.KOSData[player]
		local playerData = SpyPerCharDB.PlayerData[player]

		local announce = Spy.db.profile.Announce  
		if channel or announce == "Self" or announce == "LocalDefense" or (announce == "Guild" and GetGuildInfo("player") ~= nil and not Spy.InInstance) or (announce == "Party" and GetNumGroupMembers() > 0) or (announce == "Raid" and UnitInRaid("player")) then --++
			if announce == "Self" and not channel then
				if isKOS then
					msg = msg..L["SpySignatureColored"]..L["KillOnSightDetectedColored"]..player.." "
				else
					msg = msg..L["SpySignatureColored"]..L["PlayerDetectedColored"]..player.." "
				end
			else
				if isKOS then
					msg = msg..L["KillOnSightDetected"]..player.." "
				else
					msg = msg..L["PlayerDetected"]..player.." "
				end
			end
			if playerData then
				if playerData.guild and playerData.guild ~= "" then
					msg = msg.."<"..playerData.guild.."> "
				end
				if playerData.level or playerData.race or (playerData.class and playerData.class ~= "") then
					msg = msg.."- "
					if playerData.level and playerData.isGuess == false then msg = msg..L["Level"].." "..playerData.level.." " end
					if playerData.race and playerData.race ~= "" then msg = msg..playerData.race.." " end
					if playerData.class and playerData.class ~= "" then msg = msg..L[playerData.class].." " end
				end
				if playerData.zone then
					if playerData.subZone and playerData.subZone ~= "" and playerData.subZone ~= playerData.zone then
						msg = msg.."- "..playerData.subZone..", "..playerData.zone
					else
						msg = msg.."- "..playerData.zone
					end
				end
				if playerData.mapX and playerData.mapY then msg = msg.." ("..math.floor(tonumber(playerData.mapX) * 100)..","..math.floor(tonumber(playerData.mapY) * 100)..")" end
			end

			if channel then
				-- announce to selected channel
				if (channel == "PARTY" and GetNumGroupMembers() > 0) or (channel == "RAID" and UnitInRaid("player")) or (channel == "GUILD" and GetGuildInfo("player") ~= nil) then --++
					SendChatMessage(msg, channel)
				elseif channel == "LOCAL" then
					SendChatMessage(msg, "CHANNEL", nil, GetChannelName(L["LocalDefenseChannelName"].." - "..GetZoneText()))
				end
			else
				-- announce to standard channel
				if isKOS or not Spy.db.profile.OnlyAnnounceKoS then
					if announce == "Self" then
						DEFAULT_CHAT_FRAME:AddMessage(msg)
					elseif announce == "LocalDefense" then
						SendChatMessage(msg, "CHANNEL", nil, GetChannelName(L["LocalDefenseChannelName"].." - "..GetZoneText()))
					else
						SendChatMessage(msg, strupper(announce))
					end
				end
			end
		end

		-- announce to other Spy users
		if Spy.db.profile.ShareData then
			local class, level, race, zone, subZone, mapX, mapY, guild, mapID = "", "", "", "", "", "", "", "", ""	 --++8.0			
			if playerData then
				if playerData.class then class = playerData.class end
				if playerData.level and playerData.isGuess == false then level = playerData.level end
				if playerData.race then race = playerData.race end
				if playerData.zone then zone = playerData.zone end
				if playerData.mapID then mapID = playerData.mapID end		--++8.0				
				if playerData.subZone then subZone = playerData.subZone end
				if playerData.mapX then mapX = playerData.mapX end
				if playerData.mapY then mapY = playerData.mapY end
				if playerData.guild then guild = playerData.guild end
			end
			local details = Spy.Version.."|"..player.."|"..class.."|"..level.."|"..race.."|"..zone.."|"..subZone.."|"..mapX.."|"..mapY.."|"..guild.."|"..mapID	 --++8.0
			if strlen(details) < 240 then
				if channel then
					if (channel == "PARTY" and GetNumGroupMembers() > 0) or (channel == "RAID" and UnitInRaid("player")) or (channel == "GUILD" and GetGuildInfo("player") ~= nil) then --++
						Spy:SendCommMessage(Spy.Signature, details, channel)
					end
				else
					if GetNumGroupMembers() > 0 then Spy:SendCommMessage(Spy.Signature, details, "PARTY") end --++
					if UnitInRaid("player") then Spy:SendCommMessage(Spy.Signature, details, "RAID") end
					if Spy.InInstance == false and GetGuildInfo("player") ~= nil then Spy:SendCommMessage(Spy.Signature, details, "GUILD") end
				end
			end
		end
	end	
end

function Spy:ToggleIgnorePlayer(ignore, player)
	if ignore then
		Spy:AddIgnoreData(player)
		Spy:RemoveKOSData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-add.mp3")
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerAddedToIgnoreColored"]..player)
	else
		Spy:RemoveIgnoreData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-remove.mp3")
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerRemovedFromIgnoreColored"]..player)
	end
	Spy:RegenerateKOSGuildList()
	if Spy.db.profile.ShareKOSBetweenCharacters then Spy:RegenerateKOSCentralList() end
	Spy:RefreshCurrentList()
end

function Spy:ToggleKOSPlayer(kos, player)
	if kos then
		Spy:AddKOSData(player)
		Spy:RemoveIgnoreData(player)
		if player ~= SpyPerCharDB.PlayerData[name] then --++
			Spy:UpdatePlayerData(player, nil, nil, nil, nil, true, nil) --++
			SpyPerCharDB.PlayerData[player].kos = 1 
		end	
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-add.mp3")
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerAddedToKOSColored"]..player)
	else
		Spy:RemoveKOSData(player)
		if Spy.db.profile.EnableSound then
			PlaySoundFile("Interface\\AddOns\\Spy\\Sounds\\list-remove.mp3")
		end
		DEFAULT_CHAT_FRAME:AddMessage(L["SpySignatureColored"]..L["PlayerRemovedFromKOSColored"]..player)
	end
	Spy:RegenerateKOSGuildList()
	if Spy.db.profile.ShareKOSBetweenCharacters then Spy:RegenerateKOSCentralList() end
	Spy:RefreshCurrentList()
end

function Spy:PurgeUndetectedData()
	local secondsPerDay = 60 * 60 * 24
	local timeout = 90 * secondsPerDay
	if Spy.db.profile.PurgeData == "OneDay" then
		timeout = secondsPerDay
	elseif Spy.db.profile.PurgeData == "FiveDays" then
		timeout = 5 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "TenDays" then
		timeout = 10 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "ThirtyDays" then
		timeout = 30 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "SixtyDays" then
		timeout = 60 * secondsPerDay
	elseif Spy.db.profile.PurgeData == "NinetyDays" then
		timeout = 90 * secondsPerDay
	end

	-- remove expired players held in character data
	local currentTime = time()
	for player in pairs(SpyPerCharDB.PlayerData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		if Spy.db.profile.PurgeWinLossData then -- Added v3.2.9
			if not playerData.time or (currentTime - playerData.time) > timeout or not playerData.isEnemy then
				Spy:RemoveIgnoreData(player)
				Spy:RemoveKOSData(player)
				SpyPerCharDB.PlayerData[player] = nil
			end
		else
			if ((playerData.loses == nil) and (playerData.wins == nil)) then -- Added v3.2.9
				if not playerData.time or (currentTime - playerData.time) > timeout or not playerData.isEnemy then
					Spy:RemoveIgnoreData(player)
					if Spy.db.profile.PurgeKoS then -- Added v3.2.9	
						Spy:RemoveKOSData(player)
						SpyPerCharDB.PlayerData[player] = nil
					else
						if (playerData.kos == nil) then
							SpyPerCharDB.PlayerData[player] = nil  -- Added v3.4.0
						end	
					end	
				end
			end
		end
	end
	
	-- remove expired kos players held in central data
	local kosData = SpyDB.kosData[Spy.RealmName][Spy.FactionName]
	for characterName in pairs(kosData) do
		local characterKosData = kosData[characterName]
		for player in pairs(characterKosData) do
			local kosPlayerData = characterKosData[player]
			if Spy.db.profile.PurgeKoS then -- Added v3.2.9
				if not kosPlayerData.time or (currentTime - kosPlayerData.time) > timeout or not kosPlayerData.isEnemy then
					SpyDB.kosData[Spy.RealmName][Spy.FactionName][characterName][player] = nil
					SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] = nil
				end
			end
		end
	end
	if not Spy.db.profile.AppendUnitNameCheck then 	
		Spy:AppendUnitNames() end
	if not Spy.db.profile.AppendUnitKoSCheck then
		Spy:AppendUnitKoS() end
end

function Spy:RegenerateKOSGuildList()
	Spy.KOSGuild = {}
	for player in pairs(SpyPerCharDB.KOSData) do
		local playerData = SpyPerCharDB.PlayerData[player]
		if playerData and playerData.guild then
			Spy.KOSGuild[playerData.guild] = true
		end
	end
end

function Spy:RemoveLocalKOSPlayers()
	for player in pairs(SpyPerCharDB.KOSData) do
		if SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] then
			Spy:RemoveKOSData(player)
		end
	end
end

function Spy:RegenerateKOSCentralList(player)
	if player then
		local playerData = SpyPerCharDB.PlayerData[player]
		SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = {}
		if playerData then SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = playerData end
		SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player].added = SpyPerCharDB.KOSData[player]
	else
		for player in pairs(SpyPerCharDB.KOSData) do
			local playerData = SpyPerCharDB.PlayerData[player]
			SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = {}
			if playerData then SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player] = playerData end
			SpyDB.kosData[Spy.RealmName][Spy.FactionName][Spy.CharacterName][player].added = SpyPerCharDB.KOSData[player]
		end
	end
end

function Spy:RegenerateKOSListFromCentral()
	local kosData = SpyDB.kosData[Spy.RealmName][Spy.FactionName]
	for characterName in pairs(kosData) do
		if characterName ~= Spy.CharacterName then
			local characterKosData = kosData[characterName]
			for player in pairs(characterKosData) do
				if not SpyDB.removeKOSData[Spy.RealmName][Spy.FactionName][player] then
					local playerData = SpyPerCharDB.PlayerData[player]
					if not playerData then
						playerData = Spy:AddPlayerData(player, class, level, race, guild, isEnemy, isGuess)
					end
					local kosPlayerData = characterKosData[player]
					if kosPlayerData.time and (not playerData.time or (playerData.time and playerData.time < kosPlayerData.time)) then
						playerData.time = kosPlayerData.time
						if kosPlayerData.class then playerData.class = kosPlayerData.class end
						if type(kosPlayerData.level) == "number" and (type(playerData.level) ~= "number" or playerData.level < kosPlayerData.level) then playerData.level = kosPlayerData.level end
						if kosPlayerData.race then playerData.race = kosPlayerData.race end
						if kosPlayerData.guild then playerData.guild = kosPlayerData.guild end
						if kosPlayerData.isEnemy then playerData.isEnemy = kosPlayerData.isEnemy end
						if kosPlayerData.isGuess then playerData.isGuess = kosPlayerData.isGuess end
						if type(kosPlayerData.wins) == "number" and (type(playerData.wins) ~= "number" or playerData.wins < kosPlayerData.wins) then playerData.wins = kosPlayerData.wins end
						if type(kosPlayerData.loses) == "number" and (type(playerData.loses) ~= "number" or playerData.loses < kosPlayerData.loses) then playerData.loses = kosPlayerData.loses end
						if kosPlayerData.mapX then playerData.mapX = kosPlayerData.mapX end
						if kosPlayerData.mapY then playerData.mapY = kosPlayerData.mapY end
						if kosPlayerData.zone then playerData.zone = kosPlayerData.zone end
						if kosPlayerData.mapID then playerData.mapID = kosPlayerData.mapID end			 --++8.0						
						if kosPlayerData.subZone then playerData.subZone = kosPlayerData.subZone end
						if kosPlayerData.reason then
							playerData.reason = {}
							for reason in pairs(kosPlayerData.reason) do
								playerData.reason[reason] = kosPlayerData.reason[reason]
							end
						end
					end
					local characterKOSPlayerData = SpyPerCharDB.KOSData[player]
					if kosPlayerData.added and (not characterKOSPlayerData or characterKOSPlayerData < kosPlayerData.added) then
						SpyPerCharDB.KOSData[player] = kosPlayerData.added
					end
				end
			end
		end
	end
end

function Spy:ButtonClicked(self, button)
	local name = Spy.ButtonName[self.id]
	if name and name ~= "" then
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				if SpyPerCharDB.KOSData[name] then
					Spy:ToggleKOSPlayer(false, name)
				else
					Spy:ToggleKOSPlayer(true, name)
				end
			elseif IsControlKeyDown() then
				if SpyPerCharDB.IgnoreData[name] then
					Spy:ToggleIgnorePlayer(false, name)
				else
					Spy:ToggleIgnorePlayer(true, name)
				end
			else
				if not InCombatLockdown() then
					self:SetAttribute("macrotext", "/targetexact "..name)
				end	
			end
		elseif button == "RightButton" then
			Spy:BarDropDownOpen(self)
			CloseDropDownMenus(1)
			ToggleDropDownMenu(1, nil, Spy_BarDropDownMenu)
		end
	end
end

function Spy:ParseMinimapTooltip(tooltip)
	local newTooltip = ""
	local newLine = false
	for text in string.gmatch(tooltip, "[^\n]*") do
		local name = text
		if string.len(text) > 0 then
			if strsub(text, 1, 2) == "|T" then
			name = strtrim(gsub(gsub(text, "|T.-|t", ""), "|r", ""))
			end
			local playerData = SpyPerCharDB.PlayerData[name]
			if not playerData then
				for index, v in pairs(Spy.LastHourList) do
					local realmSeparator = strfind(index, "-")
					if realmSeparator and realmSeparator > 1 and strsub(index, 1, realmSeparator - 1) == strsub(name, 1, realmSeparator - 1) then
						playerData = SpyPerCharDB.PlayerData[index]
						break
					end
				end
			end
			if playerData and playerData.isEnemy then
				local desc = ""
				if playerData.class and playerData.level then
					desc = L["MinimapClassText"..playerData.class].." ["..playerData.level.." "..L[playerData.class].."]|r"
				elseif playerData.class then
					desc = L["MinimapClassText"..playerData.class].." ["..L[playerData.class].."]|r"
				elseif playerData.level then
					desc = " ["..playerData.level.."]|r"
				end
				if (newTooltip and desc == "") then
					newTooltip = text 
				elseif (newTooltip == "") then	
					newTooltip = text.."|r"..desc
				else
					newTooltip = newTooltip.."\r"..text.."|r"..desc
				end	
				if not SpyPerCharDB.IgnoreData[name] and not Spy.InInstance then
					local detected = Spy:UpdatePlayerData(name, nil, nil, nil, nil, true, nil)
					if detected and Spy.db.profile.MinimapTracking then
						Spy:AddDetected(name, time(), false)
					end
				end
			else
				if (newTooltip == "") then
					newTooltip = text
				else	
					newTooltip = newTooltip.."\n"..text
				end
			end
			newLine = false
		elseif not newLine then
			newTooltip = newTooltip
			newLine = true
		end
	end
	return newTooltip
end

function Spy:ParseUnitAbility(analyseSpell, event, player, flags, spellId, spellName)
	local learnt = false
	if player then
		local class = nil
		local level = nil
		local race = nil
		local isEnemy = true
		local isGuess = true

		local playerData = SpyPerCharDB.PlayerData[player]
		if not playerData or playerData.isEnemy == nil then
			learnt = true
		end

		if analyseSpell then
			local abilityType = strsub(event, 1, 5)
			if abilityType == "SWING" or abilityType == "SPELL" or abilityType == "RANGE" then
--				local ability = Spy_AbilityList[spellName]
				local ability = Spy_AbilityList[spellId]				
				if ability then
					if ability.class and not (playerData and playerData.class) then
						class = ability.class
						learnt = true
					end
					if ability.level then
						local playerLevelNumber = nil
						if playerData and playerData.level then playerLevelNumber = tonumber(playerData.level) end
						if type(playerLevelNumber) ~= "number" or playerLevelNumber < ability.level then
							level = ability.level
							learnt = true
						end
					end
					if ability.race and not (playerData and playerData.race) then
						race = ability.race
						learnt = true
					end
				else	
--					print(spellId, " - ", spellName)
				end
				if class and race and level == Spy.MaximumPlayerLevel then
					isGuess = false
					learnt = true
				end
			end
		end

		Spy:UpdatePlayerData(player, class, level, race, nil, isEnemy, isGuess)
		return learnt, playerData
	end
	return learnt, nil
end

function Spy:ParseUnitDetails(player, class, level, race, zone, subZone, mapX, mapY, guild, mapID) --++ P8.0
	if player then
		local playerData = SpyPerCharDB.PlayerData[player]
		if not playerData then
			playerData = Spy:AddPlayerData(player, class, level, race, guild, true, true)
		else
			if not playerData.class then playerData.class = class end
			if level then
				local levelNumber = tonumber(level)
				if type(levelNumber) == "number" then
					if playerData.level then
						local playerLevelNumber = tonumber(playerData.level)
						if type(playerLevelNumber) == "number" and playerLevelNumber < levelNumber then playerData.level = levelNumber end
					else
						playerData.level = levelNumber
					end
				end
			end
			if not playerData.race then playerData.race = race end
			if not playerData.guild then playerData.guild = guild end
		end
		playerData.isEnemy = true
		playerData.time = time()
		playerData.zone = zone
		playerData.mapID = mapID --++ P8.0		
		playerData.subZone = subZone
		playerData.mapX = mapX
		playerData.mapY = mapY

		return true, playerData
	end
	return true, nil
end

function Spy:AddDetected(player, timestamp, learnt, source)
	if Spy.db.profile.ShowOnlyPvPFlagged then
		if UnitIsPVP("player") then
			Spy:AddDetectedToLists(player, timestamp, learnt, source)
		else
		end	
	else
		Spy:AddDetectedToLists(player, timestamp, learnt, source)
	end	
end

function Spy:AddDetectedToLists(player, timestamp, learnt, source)
	if not Spy.NearbyList[player] then
		if Spy.db.profile.ShowOnDetection and not Spy.db.profile.MainWindowVis then
			Spy:SetCurrentList(1)
			Spy:EnableSpy(true, true, true)
		end
		if Spy.db.profile.CurrentList ~= 1 and Spy.db.profile.MainWindowVis and Spy.db.profile.ShowNearbyList then
			Spy:SetCurrentList(1)
		end

		if source and source ~= Spy.CharacterName and not Spy.ActiveList[player] then
			Spy.NearbyList[player] = timestamp
			Spy.LastHourList[player] = timestamp
			Spy.InactiveList[player] = timestamp
		else
			Spy.NearbyList[player] = timestamp
			Spy.LastHourList[player] = timestamp
			Spy.ActiveList[player] = timestamp
			Spy.InactiveList[player] = nil
		end

		if Spy.db.profile.CurrentList == 1 then
			Spy:RefreshCurrentList(player, source)
			Spy:UpdateActiveCount()			
		else
			if not source or source ~= Spy.CharacterName then
				Spy:AlertPlayer(player, source)
				if not source then Spy:AnnouncePlayer(player) end
			end
		end
	elseif not Spy.ActiveList[player] then
		if Spy.db.profile.ShowOnDetection and not Spy.db.profile.MainWindowVis then
			Spy:SetCurrentList(1)
			Spy:EnableSpy(true, true, true)
		end
		if Spy.db.profile.CurrentList ~= 1 and Spy.db.profile.MainWindowVis and Spy.db.profile.ShowNearbyList then
			Spy:SetCurrentList(1)
		end

		Spy.LastHourList[player] = timestamp
		Spy.ActiveList[player] = timestamp
		Spy.InactiveList[player] = nil

		if Spy.PlayerCommList[player] ~= nil then
			if Spy.db.profile.CurrentList == 1 then
				Spy:RefreshCurrentList(player, source)
			else
				if not source or source ~= Spy.CharacterName then
					Spy:AlertPlayer(player, source)
					if not source then Spy:AnnouncePlayer(player) end
				end
			end
		else
			if Spy.db.profile.CurrentList == 1 then
				Spy:RefreshCurrentList()
				Spy:UpdateActiveCount()						
			end
		end
	else
		Spy.ActiveList[player] = timestamp
		Spy.LastHourList[player] = timestamp
		if learnt and Spy.db.profile.CurrentList == 1 then
			Spy:RefreshCurrentList()
			Spy:UpdateActiveCount()	
		end
	end
end

function Spy:AppendUnitNames()
	for key, unit in pairs(SpyPerCharDB.PlayerData) do	
		-- find any units without a name
		if not unit.name then			
			local name = key
		-- if unit.name does not exist update info
			if (not unit.name) and name then
				unit.name = key
			end		
		end
    end
	Spy.db.profile.AppendUnitNameCheck=true --sets profile so it only runs once
end

function Spy:AppendUnitKoS()
	for kosName, value in pairs(SpyPerCharDB.KOSData) do	
		if kosName then	
			local playerData = SpyPerCharDB.PlayerData[kosName]
			if not playerData then 
				Spy:UpdatePlayerData(kosName, nil, nil, nil, nil, true, nil) 
				SpyPerCharDB.PlayerData[kosName].kos = 1 
				SpyPerCharDB.PlayerData[kosName].time = value			
			end		
		end
    end
	Spy.db.profile.AppendUnitKoSCheck=true --sets profile so it only runs once
end

Spy.ListTypes = {
	{L["Nearby"], Spy.ManageNearbyList, Spy.ManageNearbyListExpirations},
	{L["LastHour"], Spy.ManageLastHourList, Spy.ManageLastHourListExpirations},
	{L["Ignore"], Spy.ManageIgnoreList},
	{L["KillOnSight"], Spy.ManageKillOnSightList},
}

Spy_AbilityList = {
--++ Racial Traits ++	
	[68976]={ race = "Worgen", level = 1, },
	[94293]={ race = "Worgen", level = 1, },
	[274738]={ race = "Mag'har Orc", level = 1, },
	[255663]={ race = "Nightborne", level = 1, },
	[154742]={ race = "Blood Elf", level = 1, },
	[28877]={ race = "Blood Elf", level = 1, },
	[260364]={ race = "Nightborne", level = 1, },
	[20592]={ race = "Gnome", level = 1, },
	[822]={ race = "Blood Elf", level = 1, },
	[255664]={ race = "Nightborne", level = 1, },
	[28730]={ race = "Blood Elf", level = 1, },
	[155145]={ race = "Blood Elf", level = 1, },
	[25046]={ race = "Blood Elf", level = 1, },
	[69179]={ race = "Blood Elf", level = 1, },
	[50613]={ race = "Blood Elf", level = 1, },
	[202719]={ race = "Blood Elf", level = 1, },
	[232633]={ race = "Blood Elf", level = 1, },
	[80483]={ race = "Blood Elf", level = 1, },
	[129597]={ race = "Blood Elf", level = 1, },
	[20557]={ race = "Troll", level = 1, },
	[26297]={ race = "Troll", level = 1, },
	[69044]={ race = "Goblin", level = 1, },
	[69045]={ race = "Goblin", level = 1, },
	[20572]={ race = "Orc", level = 1, },
	[33697]={ race = "Orc", level = 1, },
	[33702]={ race = "Orc", level = 1, },
	[107076]={ race = "Pandaren", level = 1, },
	[154743]={ race = "Tauren", level = 1, },
	[291628]={ race = "Kul Tiran", level = 1, },
	[291843]={ race = "Kul Tiran", level = 1, },
	[255654]={ race = "Highmountain Tauren", level = 1, },
	[20577]={ race = "Undead", level = 1, },
	[255661]={ race = "Nightborne", level = 1, },
	[291622]={ race = "Kul Tiran", level = 1, },
	[255668]={ race = "Void Elf", level = 1, },
	[291619]={ race = "Zandalari Troll", level = 1, },
	[20552]={ race = "Tauren", level = 1, },
	[58943]={ race = "Troll", level = 1, },
	[68992]={ race = "Worgen", level = 1, },
	[255653]={ race = "Lightforged Draenei", level = 1, },
	[20599]={ race = "Human", level = 1, },
	[265223]={ race = "Dark Iron Dwarf", level = 1, },
	[292359]={ race = "Zandalari Troll", level = 1, },
	[292360]={ race = "Zandalari Troll", level = 1, },
	[292362]={ race = "Zandalari Troll", level = 1, },
	[292363]={ race = "Zandalari Troll", level = 1, },
	[292364]={ race = "Zandalari Troll", level = 1, },
	[292361]={ race = "Zandalari Troll", level = 1, },
	[292492]={ race = "Zandalari Troll", level = 1, },
	[20550]={ race = "Tauren", level = 1, },
	[20593]={ race = "Gnome", level = 1, },
	[255669]={ race = "Void Elf", level = 1, },
	[256374]={ race = "Void Elf", level = 1, },
	[20589]={ race = "Gnome", level = 1, },
	[255667]={ race = "Void Elf", level = 1, },
	[59752]={ race = "Human", level = 1, },
	[20591]={ race = "Gnome", level = 1, },
	[154746]={ race = "Gnome", level = 1, },
	[227057]={ race = "Gnome", level = 1, },
	[154747]={ race = "Gnome", level = 1, },
	[154744]={ race = "Gnome", level = 1, },
	[92682]={ race = "Dwarf", level = 1, },
	[265221]={ race = "Dark Iron Dwarf", level = 1, },
	[68978]={ race = "Worgen", level = 1, },
	[259930]={ race = "Lightforged Draenei", level = 1, },
	[255650]={ race = "Lightforged Draenei", level = 1, },
	[265224]={ race = "Dark Iron Dwarf", level = 1, },
	[20596]={ race = "Dwarf", level = 1, },
	[28875]={ race = "Draenei", level = 1, },
	[28880]={ race = "Draenei", level = 1, },
	[121093]={ race = "Draenei", level = 1, },
	[59542]={ race = "Draenei", level = 1, },
	[59547]={ race = "Draenei", level = 1, },
	[59545]={ race = "Draenei", level = 1, },
	[59548]={ race = "Draenei", level = 1, },
	[59544]={ race = "Draenei", level = 1, },
	[59543]={ race = "Draenei", level = 1, },
	[107073]={ race = "Pandaren", level = 1, },
	[20573]={ race = "Orc", level = 1, },
	[287712]={ race = "Kul Tiran", level = 1, },
	[6562]={ race = "Draenei", level = 1, },
	[255651]={ race = "Lightforged Draenei", level = 1, },
	[107074]={ race = "Pandaren", level = 1, },
	[291442]={ race = "Kul Tiran", level = 1, },
	[131701]={ race = "Pandaren", level = 1, },
	[262438]={ race = "Nightborne", level = 1, },
	[262486]={ race = "Void Elf", level = 1, },
	[255647]={ race = "Lightforged Draenei", level = 1, },
	[255652]={ race = "Lightforged Draenei", level = 1, },
	[255665]={ race = "Nightborne", level = 1, },
	[265222]={ race = "Dark Iron Dwarf", level = 1, },
	[59224]={ race = "Dwarf", level = 1, },
	[265225]={ race = "Dark Iron Dwarf", level = 1, },
	[255658]={ race = "Highmountain Tauren", level = 1, },
	[20583]={ race = "Night Elf", level = 1, },
	[20551]={ race = "Tauren", level = 1, },
	[92680]={ race = "Gnome", level = 1, },
	[273216]={ race = "Mag'har Orc", level = 1, },
	[69046]={ race = "Goblin", level = 1, },
	[255670]={ race = "Void Elf", level = 1, },
	[255655]={ race = "Highmountain Tauren", level = 1, },
	[281954]={ race = "Zandalari Troll", level = 1, },
	[107079]={ race = "Pandaren", level = 1, },
	[20582]={ race = "Night Elf", level = 1, },
	[291944]={ race = "Zandalari Troll", level = 1, },
	[20555]={ race = "Troll", level = 1, },
	[291417]={ race = "Kul Tiran", level = 1, },
	[69041]={ race = "Goblin", level = 1, },
	[69070]={ race = "Goblin", level = 1, },
	[255659]={ race = "Highmountain Tauren", level = 1, },
	[87840]={ race = "Worgen", level = 1, },
	[273220]={ race = "Mag'har Orc", level = 1, },
	[20579]={ race = "Undead", level = 1, },
	[59221]={ race = "Draenei", level = 1, },
	[58984]={ race = "Night Elf", level = 1, },
	[256948]={ race = "Void Elf", level = 1, },
	[20594]={ race = "Dwarf", level = 1, },
	[273217]={ race = "Mag'har Orc", level = 1, },
	[20598]={ race = "Human", level = 1, },
	[69042]={ race = "Goblin", level = 1, },
	[154748]={ race = "Night Elf", level = 1, },
	[154796]={ race = "Night Elf", level = 1, },
	[154797]={ race = "Night Elf", level = 1, },
	[5227]={ race = "Undead", level = 1, },
	[68996]={ race = "Worgen", level = 1, },
	[68975]={ race = "Worgen", level = 1, },
	[20549]={ race = "Tauren", level = 1, },
	[255656]={ race = "Highmountain Tauren", level = 1, },
	[7744]={ race = "Undead", level = 1, },
	[20585]={ race = "Night Elf", level = 1, },
	
--++ Death Knight Abilities ++	
	[48778]={ class = "DEATHKNIGHT", level = 55, },
	[55078]={ class = "DEATHKNIGHT", level = 55, },
	[127344]={ class = "DEATHKNIGHT", level = 55, },
	[50977]={ class = "DEATHKNIGHT", level = 55, },
	[49576]={ class = "DEATHKNIGHT", level = 55, },
	[49998]={ class = "DEATHKNIGHT", level = 55, },
	[48265]={ class = "DEATHKNIGHT", level = 55, },
	[55095]={ class = "DEATHKNIGHT", level = 55, },
	[82246]={ class = "DEATHKNIGHT", level = 55, },
	[53343]={ class = "DEATHKNIGHT", level = 55, },
	[53428]={ class = "DEATHKNIGHT", level = 55, },
	[48707]={ class = "DEATHKNIGHT", level = 57, },
	[56222]={ class = "DEATHKNIGHT", level = 58, },
	[51986]={ class = "DEATHKNIGHT", level = 61, },
	[47528]={ class = "DEATHKNIGHT", level = 62, },
	[3714]={ class = "DEATHKNIGHT", level = 66, },
	[111673]={ class = "DEATHKNIGHT", level = 69, },
	[53344]={ class = "DEATHKNIGHT", level = 70, },
	[53365]={ class = "DEATHKNIGHT", level = 70, },
	[61999]={ class = "DEATHKNIGHT", level = 72, },
	[62158]={ class = "DEATHKNIGHT", level = 72, },
	[190780]={ class = "DEATHKNIGHT", level = 100, },
	[278107]={ class = "DEATHKNIGHT", level = 100, },
--++ Death Knight Artifact Traits ++	
	[220143]={ class = "DEATHKNIGHT", level = 100, },
	[205223]={ class = "DEATHKNIGHT", level = 100, },
	[205224]={ class = "DEATHKNIGHT", level = 100, },
	[190778]={ class = "DEATHKNIGHT", level = 100, },
--++ Death Knight Azerite Traits ++	
	[289339]={ class = "DEATHKNIGHT", level = 110, },
	[289347]={ class = "DEATHKNIGHT", level = 110, },
	[273088]={ class = "DEATHKNIGHT", level = 110, },
	[278484]={ class = "DEATHKNIGHT", level = 110, },
	[279502]={ class = "DEATHKNIGHT", level = 110, },
	[279503]={ class = "DEATHKNIGHT", level = 110, },
	[278482]={ class = "DEATHKNIGHT", level = 110, },
	[288424]={ class = "DEATHKNIGHT", level = 110, },
	[288425]={ class = "DEATHKNIGHT", level = 110, },
	[265145]={ class = "DEATHKNIGHT", level = 110, },
	[272684]={ class = "DEATHKNIGHT", level = 110, },
	[275917]={ class = "DEATHKNIGHT", level = 110, },
	[278479]={ class = "DEATHKNIGHT", level = 110, },
	[278534]={ class = "DEATHKNIGHT", level = 110, },
	[278543]={ class = "DEATHKNIGHT", level = 110, },
	[274081]={ class = "DEATHKNIGHT", level = 110, },
	[274373]={ class = "DEATHKNIGHT", level = 110, },
	[287283]={ class = "DEATHKNIGHT", level = 110, },
	[287303]={ class = "DEATHKNIGHT", level = 110, },
	[287321]={ class = "DEATHKNIGHT", level = 110, },
	[278487]={ class = "DEATHKNIGHT", level = 110, },
	[275929]={ class = "DEATHKNIGHT", level = 110, },
	[275930]={ class = "DEATHKNIGHT", level = 110, },
	[275931]={ class = "DEATHKNIGHT", level = 110, },
	[286832]={ class = "DEATHKNIGHT", level = 110, },
	[286834]={ class = "DEATHKNIGHT", level = 110, },
	[286835]={ class = "DEATHKNIGHT", level = 110, },
	[286836]={ class = "DEATHKNIGHT", level = 110, },
	[286978]={ class = "DEATHKNIGHT", level = 110, },
	[286979]={ class = "DEATHKNIGHT", level = 110, },
	[290814]={ class = "DEATHKNIGHT", level = 110, },
	[272718]={ class = "DEATHKNIGHT", level = 110, },
	[272719]={ class = "DEATHKNIGHT", level = 110, },
	[272721]={ class = "DEATHKNIGHT", level = 110, },
	[278480]={ class = "DEATHKNIGHT", level = 110, },
	[278603]={ class = "DEATHKNIGHT", level = 110, },
	[278489]={ class = "DEATHKNIGHT", level = 110, },
	[273093]={ class = "DEATHKNIGHT", level = 110, },
	[288417]={ class = "DEATHKNIGHT", level = 110, },
	[280011]={ class = "DEATHKNIGHT", level = 110, },
	[280143]={ class = "DEATHKNIGHT", level = 110, },
	[274057]={ class = "DEATHKNIGHT", level = 110, },
	[280010]={ class = "DEATHKNIGHT", level = 110, },
	[280132]={ class = "DEATHKNIGHT", level = 110, },
	[265147]={ class = "DEATHKNIGHT", level = 110, },
	[269357]={ class = "DEATHKNIGHT", level = 110, },
--++ Death Knight Specializations ++	
	[47541]={ class = "DEATHKNIGHT", level = 55, },
	[85948]={ class = "DEATHKNIGHT", level = 55, },
	[197147]={ class = "DEATHKNIGHT", level = 55, },
	[194310]={ class = "DEATHKNIGHT", level = 55, },
	[194311]={ class = "DEATHKNIGHT", level = 55, },
	[195757]={ class = "DEATHKNIGHT", level = 55, },
	[195621]={ class = "DEATHKNIGHT", level = 55, },
	[49143]={ class = "DEATHKNIGHT", level = 55, },
	[49184]={ class = "DEATHKNIGHT", level = 55, },
	[237680]={ class = "DEATHKNIGHT", level = 55, },
	[195182]={ class = "DEATHKNIGHT", level = 55, },
	[49020]={ class = "DEATHKNIGHT", level = 55, },
	[77575]={ class = "DEATHKNIGHT", level = 55, },
	[196782]={ class = "DEATHKNIGHT", level = 55, },
	[191587]={ class = "DEATHKNIGHT", level = 55, },
	[46584]={ class = "DEATHKNIGHT", level = 55, },
	[51462]={ class = "DEATHKNIGHT", level = 55, },
	[51460]={ class = "DEATHKNIGHT", level = 55, },
	[81229]={ class = "DEATHKNIGHT", level = 55, },
	[55090]={ class = "DEATHKNIGHT", level = 55, },
	[70890]={ class = "DEATHKNIGHT", level = 55, },
	[48263]={ class = "DEATHKNIGHT", level = 55, },
	[50842]={ class = "DEATHKNIGHT", level = 56, },
	[45524]={ class = "DEATHKNIGHT", level = 56, },
	[43265]={ class = "DEATHKNIGHT", level = 56, },
	[52212]={ class = "DEATHKNIGHT", level = 56, },
	[206930]={ class = "DEATHKNIGHT", level = 56, },
	[51124]={ class = "DEATHKNIGHT", level = 56, },
	[51128]={ class = "DEATHKNIGHT", level = 56, },
	[49028]={ class = "DEATHKNIGHT", level = 57, },
	[47568]={ class = "DEATHKNIGHT", level = 57, },
	[48792]={ class = "DEATHKNIGHT", level = 57, },
	[51271]={ class = "DEATHKNIGHT", level = 57, },
	[196770]={ class = "DEATHKNIGHT", level = 57, },
	[221562]={ class = "DEATHKNIGHT", level = 58, },
	[178819]={ class = "DEATHKNIGHT", level = 58, },
	[195292]={ class = "DEATHKNIGHT", level = 58, },
	[59057]={ class = "DEATHKNIGHT", level = 59, },
	[49530]={ class = "DEATHKNIGHT", level = 60, },
	[55233]={ class = "DEATHKNIGHT", level = 60, },
	[81136]={ class = "DEATHKNIGHT", level = 63, },
	[108199]={ class = "DEATHKNIGHT", level = 64, },
	[278223]={ class = "DEATHKNIGHT", level = 68, },
	[63560]={ class = "DEATHKNIGHT", level = 74, },
	[275699]={ class = "DEATHKNIGHT", level = 75, },
	[161797]={ class = "DEATHKNIGHT", level = 76, },
	[77513]={ class = "DEATHKNIGHT", level = 78, },
	[77515]={ class = "DEATHKNIGHT", level = 78, },
	[77514]={ class = "DEATHKNIGHT", level = 78, },
	[42650]={ class = "DEATHKNIGHT", level = 82, },
--++ Death Knight Talents ++	
	[194916]={ class = "DEATHKNIGHT", level = 56, },
	[206931]={ class = "DEATHKNIGHT", level = 56, },
	[207311]={ class = "DEATHKNIGHT", level = 56, },
	[281208]={ class = "DEATHKNIGHT", level = 56, },
	[281209]={ class = "DEATHKNIGHT", level = 56, },
	[221536]={ class = "DEATHKNIGHT", level = 56, },
	[194878]={ class = "DEATHKNIGHT", level = 56, },
	[253593]={ class = "DEATHKNIGHT", level = 56, },
	[253595]={ class = "DEATHKNIGHT", level = 56, },
	[207272]={ class = "DEATHKNIGHT", level = 56, },
	[210764]={ class = "DEATHKNIGHT", level = 56, },
	[207264]={ class = "DEATHKNIGHT", level = 57, },
	[274156]={ class = "DEATHKNIGHT", level = 57, },
	[207269]={ class = "DEATHKNIGHT", level = 57, },
	[273946]={ class = "DEATHKNIGHT", level = 57, },
	[57330]={ class = "DEATHKNIGHT", level = 57, },
	[207061]={ class = "DEATHKNIGHT", level = 57, },
	[194662]={ class = "DEATHKNIGHT", level = 57, },
	[207104]={ class = "DEATHKNIGHT", level = 57, },
	[115989]={ class = "DEATHKNIGHT", level = 57, },
	[108194]={ class = "DEATHKNIGHT", level = 58, },
	[207167]={ class = "DEATHKNIGHT", level = 58, },
	[276079]={ class = "DEATHKNIGHT", level = 58, },
	[206974]={ class = "DEATHKNIGHT", level = 58, },
	[219786]={ class = "DEATHKNIGHT", level = 58, },
	[219809]={ class = "DEATHKNIGHT", level = 58, },
	[205727]={ class = "DEATHKNIGHT", level = 60, },
	[207142]={ class = "DEATHKNIGHT", level = 60, },
	[207230]={ class = "DEATHKNIGHT", level = 60, },
	[194909]={ class = "DEATHKNIGHT", level = 60, },
	[276023]={ class = "DEATHKNIGHT", level = 60, },
	[194917]={ class = "DEATHKNIGHT", level = 60, },
	[194679]={ class = "DEATHKNIGHT", level = 60, },
	[130736]={ class = "DEATHKNIGHT", level = 60, },
	[206967]={ class = "DEATHKNIGHT", level = 60, },
	[48743]={ class = "DEATHKNIGHT", level = 75, },
	[273952]={ class = "DEATHKNIGHT", level = 75, },
	[207200]={ class = "DEATHKNIGHT", level = 75, },
	[207321]={ class = "DEATHKNIGHT", level = 75, },
	[206970]={ class = "DEATHKNIGHT", level = 75, },
	[212552]={ class = "DEATHKNIGHT", level = 75, },
	[195679]={ class = "DEATHKNIGHT", level = 90, },
	[152280]={ class = "DEATHKNIGHT", level = 90, },
	[207317]={ class = "DEATHKNIGHT", level = 90, },
	[212739]={ class = "DEATHKNIGHT", level = 90, },
	[215969]={ class = "DEATHKNIGHT", level = 90, },
	[279302]={ class = "DEATHKNIGHT", level = 90, },
	[194912]={ class = "DEATHKNIGHT", level = 90, },
	[194913]={ class = "DEATHKNIGHT", level = 90, },
	[206940]={ class = "DEATHKNIGHT", level = 90, },
	[277234]={ class = "DEATHKNIGHT", level = 90, },
	[273953]={ class = "DEATHKNIGHT", level = 90, },
	[276837]={ class = "DEATHKNIGHT", level = 100, },
	[194844]={ class = "DEATHKNIGHT", level = 100, },
	[152279]={ class = "DEATHKNIGHT", level = 100, },
	[207126]={ class = "DEATHKNIGHT", level = 100, },
	[281238]={ class = "DEATHKNIGHT", level = 100, },
	[114556]={ class = "DEATHKNIGHT", level = 100, },
	[205723]={ class = "DEATHKNIGHT", level = 100, },
	[49206]={ class = "DEATHKNIGHT", level = 100, },
	[207289]={ class = "DEATHKNIGHT", level = 100, },
--++ Death Knight PvP Talents ++	
	[51052]={ class = "DEATHKNIGHT", level = 57, },
	[233411]={ class = "DEATHKNIGHT", level = 57, },
	[201995]={ class = "DEATHKNIGHT", level = 57, },
	[204160]={ class = "DEATHKNIGHT", level = 57, },
	[305392]={ class = "DEATHKNIGHT", level = 57, },
	[77606]={ class = "DEATHKNIGHT", level = 57, },
	[287250]={ class = "DEATHKNIGHT", level = 57, },
	[203173]={ class = "DEATHKNIGHT", level = 57, },
	[204080]={ class = "DEATHKNIGHT", level = 57, },
	[199720]={ class = "DEATHKNIGHT", level = 57, },
	[233396]={ class = "DEATHKNIGHT", level = 57, },
	[199719]={ class = "DEATHKNIGHT", level = 57, },
	[233412]={ class = "DEATHKNIGHT", level = 57, },
	[287081]={ class = "DEATHKNIGHT", level = 57, },
	[288855]={ class = "DEATHKNIGHT", level = 57, },
	[207018]={ class = "DEATHKNIGHT", level = 57, },
	[199642]={ class = "DEATHKNIGHT", level = 57, },
	[214968]={ class = "DEATHKNIGHT", level = 57, },
	[223829]={ class = "DEATHKNIGHT", level = 57, },
	[210128]={ class = "DEATHKNIGHT", level = 57, },
	[47476]={ class = "DEATHKNIGHT", level = 57, },
	[288977]={ class = "DEATHKNIGHT", level = 57, },
	[202727]={ class = "DEATHKNIGHT", level = 57, },
	[202731]={ class = "DEATHKNIGHT", level = 57, },
	[288848]={ class = "DEATHKNIGHT", level = 57, },
	[288853]={ class = "DEATHKNIGHT", level = 57, },
--++ Demon Hunter Abilities ++	
	[162794]={ class = "DEMONHUNTER", level = 98, },
	[222031]={ class = "DEMONHUNTER", level = 98, },
	[193840]={ class = "DEMONHUNTER", level = 98, },
	[199547]={ class = "DEMONHUNTER", level = 98, },
	[221351]={ class = "DEMONHUNTER", level = 98, },
	[183752]={ class = "DEMONHUNTER", level = 98, },
	[196055]={ class = "DEMONHUNTER", level = 98, },
	[198013]={ class = "DEMONHUNTER", level = 98, },
	[198030]={ class = "DEMONHUNTER", level = 98, },
	[195072]={ class = "DEMONHUNTER", level = 98, },
	[192611]={ class = "DEMONHUNTER", level = 98, },
	[131347]={ class = "DEMONHUNTER", level = 98, },
	[203724]={ class = "DEMONHUNTER", level = 98, },
	[188501]={ class = "DEMONHUNTER", level = 98, },
	[188499]={ class = "DEMONHUNTER", level = 100, },
	[199552]={ class = "DEMONHUNTER", level = 100, },
	[200685]={ class = "DEMONHUNTER", level = 100, },
	[210152]={ class = "DEMONHUNTER", level = 100, },
	[198589]={ class = "DEMONHUNTER", level = 100, },
	[212800]={ class = "DEMONHUNTER", level = 100, },
	[255260]={ class = "DEMONHUNTER", level = 100, },
	[179057]={ class = "DEMONHUNTER", level = 100, },
	[217832]={ class = "DEMONHUNTER", level = 100, },
	[198793]={ class = "DEMONHUNTER", level = 100, },
	[278326]={ class = "DEMONHUNTER", level = 103, },
--++ Demon Hunter Artifact Traits ++	
	[201467]={ class = "DEMONHUNTER", level = 100, },
	[214743]={ class = "DEMONHUNTER", level = 100, },
	[207407]={ class = "DEMONHUNTER", level = 100, },
--++ Demon Hunter Azerite Traits ++	
	[288754]={ class = "DEMONHUNTER", level = 110, },
	[278502]={ class = "DEMONHUNTER", level = 110, },
	[278766]={ class = "DEMONHUNTER", level = 110, },
	[278769]={ class = "DEMONHUNTER", level = 110, },
	[278501]={ class = "DEMONHUNTER", level = 110, },
	[279449]={ class = "DEMONHUNTER", level = 110, },
	[279450]={ class = "DEMONHUNTER", level = 110, },
	[278500]={ class = "DEMONHUNTER", level = 110, },
	[279442]={ class = "DEMONHUNTER", level = 110, },
	[273231]={ class = "DEMONHUNTER", level = 110, },
	[288878]={ class = "DEMONHUNTER", level = 110, },
	[288880]={ class = "DEMONHUNTER", level = 110, },
	[288882]={ class = "DEMONHUNTER", level = 110, },
	[273236]={ class = "DEMONHUNTER", level = 110, },
	[273237]={ class = "DEMONHUNTER", level = 110, },
	[273238]={ class = "DEMONHUNTER", level = 110, },
	[273239]={ class = "DEMONHUNTER", level = 110, },
	[272983]={ class = "DEMONHUNTER", level = 110, },
	[272985]={ class = "DEMONHUNTER", level = 110, },
	[272986]={ class = "DEMONHUNTER", level = 110, },
	[279581]={ class = "DEMONHUNTER", level = 110, },
	[279582]={ class = "DEMONHUNTER", level = 110, },
	[279584]={ class = "DEMONHUNTER", level = 110, },
	[275350]={ class = "DEMONHUNTER", level = 110, },
	[275934]={ class = "DEMONHUNTER", level = 110, },
	[275935]={ class = "DEMONHUNTER", level = 110, },
	[275936]={ class = "DEMONHUNTER", level = 110, },
	[274345]={ class = "DEMONHUNTER", level = 110, },
	[278493]={ class = "DEMONHUNTER", level = 110, },
	[278736]={ class = "DEMONHUNTER", level = 110, },
	[288973]={ class = "DEMONHUNTER", level = 110, },
	[288997]={ class = "DEMONHUNTER", level = 110, },
--++ Demon Hunter Specializations ++	
	[162243]={ class = "DEMONHUNTER", level = 98, },
	[185164]={ class = "DEMONHUNTER", level = 98, },
	[178940]={ class = "DEMONHUNTER", level = 98, },
	[204254]={ class = "DEMONHUNTER", level = 98, },
	[185123]={ class = "DEMONHUNTER", level = 98, },
	[204157]={ class = "DEMONHUNTER", level = 98, },
	[212611]={ class = "DEMONHUNTER", level = 98, },
	[187827]={ class = "DEMONHUNTER", level = 99, },
	[191427]={ class = "DEMONHUNTER", level = 99, },
	[162264]={ class = "DEMONHUNTER", level = 99, },
	[200166]={ class = "DEMONHUNTER", level = 99, },
	[247121]={ class = "DEMONHUNTER", level = 99, },
	[227518]={ class = "DEMONHUNTER", level = 99, },
	[281242]={ class = "DEMONHUNTER", level = 100, },
	[196718]={ class = "DEMONHUNTER", level = 100, },
	[203720]={ class = "DEMONHUNTER", level = 100, },
	[203513]={ class = "DEMONHUNTER", level = 100, },
	[278386]={ class = "DEMONHUNTER", level = 100, },
	[204021]={ class = "DEMONHUNTER", level = 100, },
	[178740]={ class = "DEMONHUNTER", level = 100, },
	[258921]={ class = "DEMONHUNTER", level = 100, },
	[258922]={ class = "DEMONHUNTER", level = 100, },
	[178741]={ class = "DEMONHUNTER", level = 100, },
	[189110]={ class = "DEMONHUNTER", level = 100, },
	[203747]={ class = "DEMONHUNTER", level = 100, },
	[207197]={ class = "DEMONHUNTER", level = 100, },
	[203782]={ class = "DEMONHUNTER", level = 100, },
	[203783]={ class = "DEMONHUNTER", level = 100, },
	[204596]={ class = "DEMONHUNTER", level = 100, },
	[228477]={ class = "DEMONHUNTER", level = 100, },
	[228478]={ class = "DEMONHUNTER", level = 100, },
	[202137]={ class = "DEMONHUNTER", level = 101, },
	[207684]={ class = "DEMONHUNTER", level = 105, },
	[185245]={ class = "DEMONHUNTER", level = 110, },
	[281854]={ class = "DEMONHUNTER", level = 110, },
--++ Demon Hunter Talents ++	
	[207550]={ class = "DEMONHUNTER", level = 99, },
	[207548]={ class = "DEMONHUNTER", level = 99, },
	[203550]={ class = "DEMONHUNTER", level = 99, },
	[206478]={ class = "DEMONHUNTER", level = 99, },
	[232893]={ class = "DEMONHUNTER", level = 99, },
	[209400]={ class = "DEMONHUNTER", level = 99, },
	[207739]={ class = "DEMONHUNTER", level = 100, },
	[203555]={ class = "DEMONHUNTER", level = 100, },
	[227174]={ class = "DEMONHUNTER", level = 100, },
	[207697]={ class = "DEMONHUNTER", level = 100, },
	[258920]={ class = "DEMONHUNTER", level = 100, },
	[258876]={ class = "DEMONHUNTER", level = 100, },
	[264002]={ class = "DEMONHUNTER", level = 102, },
	[258925]={ class = "DEMONHUNTER", level = 102, },
	[192939]={ class = "DEMONHUNTER", level = 102, },
	[227322]={ class = "DEMONHUNTER", level = 102, },
	[258881]={ class = "DEMONHUNTER", level = 102, },
	[258883]={ class = "DEMONHUNTER", level = 102, },
	[205411]={ class = "DEMONHUNTER", level = 104, },
	[218612]={ class = "DEMONHUNTER", level = 104, },
	[263642]={ class = "DEMONHUNTER", level = 104, },
	[196555]={ class = "DEMONHUNTER", level = 104, },
	[204909]={ class = "DEMONHUNTER", level = 104, },
	[217996]={ class = "DEMONHUNTER", level = 104, },
	[207666]={ class = "DEMONHUNTER", level = 106, },
	[258887]={ class = "DEMONHUNTER", level = 106, },
	[258860]={ class = "DEMONHUNTER", level = 106, },
	[206416]={ class = "DEMONHUNTER", level = 106, },
	[209281]={ class = "DEMONHUNTER", level = 106, },
	[202138]={ class = "DEMONHUNTER", level = 106, },
	[212084]={ class = "DEMONHUNTER", level = 108, },
	[211881]={ class = "DEMONHUNTER", level = 108, },
	[264004]={ class = "DEMONHUNTER", level = 108, },
	[203556]={ class = "DEMONHUNTER", level = 108, },
	[213405]={ class = "DEMONHUNTER", level = 108, },
	[247454]={ class = "DEMONHUNTER", level = 108, },
	[206477]={ class = "DEMONHUNTER", level = 108, },
	[213410]={ class = "DEMONHUNTER", level = 110, },
	[209258]={ class = "DEMONHUNTER", level = 110, },
	[206476]={ class = "DEMONHUNTER", level = 110, },
	[206491]={ class = "DEMONHUNTER", level = 110, },
	[263648]={ class = "DEMONHUNTER", level = 110, },
	[268175]={ class = "DEMONHUNTER", level = 110, },
	[268178]={ class = "DEMONHUNTER", level = 110, },
--++ Demon Hunter PvP Talents ++	
	[205625]={ class = "DEMONHUNTER", level = 101, },
	[227635]={ class = "DEMONHUNTER", level = 101, },
	[235893]={ class = "DEMONHUNTER", level = 101, },
	[205629]={ class = "DEMONHUNTER", level = 101, },
	[205596]={ class = "DEMONHUNTER", level = 101, },
	[205626]={ class = "DEMONHUNTER", level = 101, },
	[206649]={ class = "DEMONHUNTER", level = 101, },
	[203468]={ class = "DEMONHUNTER", level = 101, },
	[205630]={ class = "DEMONHUNTER", level = 101, },
	[205627]={ class = "DEMONHUNTER", level = 101, },
	[203704]={ class = "DEMONHUNTER", level = 101, },
	[235903]={ class = "DEMONHUNTER", level = 101, },
	[206803]={ class = "DEMONHUNTER", level = 101, },
	[205604]={ class = "DEMONHUNTER", level = 101, },
	[211489]={ class = "DEMONHUNTER", level = 101, },
	[211509]={ class = "DEMONHUNTER", level = 101, },
	[207029]={ class = "DEMONHUNTER", level = 101, },
	[213480]={ class = "DEMONHUNTER", level = 101, },
--++ Druid Abilities ++	
	[5225]={ class = "DRUID", level = 1, },
	[8921]={ class = "DRUID", level = 3, },
	[164812]={ class = "DRUID", level = 3, },
	[8936]={ class = "DRUID", level = 5, },
	[125972]={ class = "DRUID", level = 6, },
	[768]={ class = "DRUID", level = 8, },
	[1850]={ class = "DRUID", level = 8, },
	[5221]={ class = "DRUID", level = 8, },
	[5487]={ class = "DRUID", level = 10, },
	[16870]={ class = "DRUID", level = 10, },
	[236716]={ class = "DRUID", level = 10, },
	[33917]={ class = "DRUID", level = 10, },
	[77758]={ class = "DRUID", level = 12, },
	[106830]={ class = "DRUID", level = 12, },
	[6795]={ class = "DRUID", level = 13, },
	[193753]={ class = "DRUID", level = 14, },
	[50769]={ class = "DRUID", level = 14, },
	[18960]={ class = "DRUID", level = 14, },
	[164815]={ class = "DRUID", level = 16, },
	[276012]={ class = "DRUID", level = 18, },
	[783]={ class = "DRUID", level = 18, },
	[40120]={ class = "DRUID", level = 18, },
	[165961]={ class = "DRUID", level = 18, },
	[339]={ class = "DRUID", level = 24, },
	[127757]={ class = "DRUID", level = 40, },
	[164862]={ class = "DRUID", level = 40, },
	[210053]={ class = "DRUID", level = 40, },
	[210065]={ class = "DRUID", level = 40, },
	[20484]={ class = "DRUID", level = 42, },
	[165962]={ class = "DRUID", level = 58, },
	[276029]={ class = "DRUID", level = 58, },
	[2637]={ class = "DRUID", level = 66, },
	[231437]={ class = "DRUID", level = 110, },
--++ Druid Artifact Traits ++	
	[210722]={ class = "DRUID", level = 100, },
	[208253]={ class = "DRUID", level = 100, },
	[202767]={ class = "DRUID", level = 100, },
	[200851]={ class = "DRUID", level = 100, },
	[219432]={ class = "DRUID", level = 100, },
--++ Druid Azerite Traits ++	
	[287773]={ class = "DRUID", level = 110, },
	[287784]={ class = "DRUID", level = 110, },
	[287790]={ class = "DRUID", level = 110, },
	[274432]={ class = "DRUID", level = 110, },
	[287247]={ class = "DRUID", level = 110, },
	[279524]={ class = "DRUID", level = 110, },
	[279525]={ class = "DRUID", level = 110, },
	[289314]={ class = "DRUID", level = 110, },
	[276152]={ class = "DRUID", level = 110, },
	[276153]={ class = "DRUID", level = 110, },
	[276154]={ class = "DRUID", level = 110, },
	[287251]={ class = "DRUID", level = 110, },
	[287253]={ class = "DRUID", level = 110, },
	[278510]={ class = "DRUID", level = 110, },
	[279536]={ class = "DRUID", level = 110, },
	[279778]={ class = "DRUID", level = 110, },
	[279779]={ class = "DRUID", level = 110, },
	[279793]={ class = "DRUID", level = 110, },
	[278511]={ class = "DRUID", level = 110, },
	[279540]={ class = "DRUID", level = 110, },
	[279541]={ class = "DRUID", level = 110, },
	[278509]={ class = "DRUID", level = 110, },
	[279468]={ class = "DRUID", level = 110, },
	[279471]={ class = "DRUID", level = 110, },
	[278505]={ class = "DRUID", level = 110, },
	[279070]={ class = "DRUID", level = 110, },
	[276021]={ class = "DRUID", level = 110, },
	[274424]={ class = "DRUID", level = 110, },
	[274425]={ class = "DRUID", level = 110, },
	[274426]={ class = "DRUID", level = 110, },
	[279552]={ class = "DRUID", level = 110, },
	[279642]={ class = "DRUID", level = 110, },
	[279646]={ class = "DRUID", level = 110, },
	[279647]={ class = "DRUID", level = 110, },
	[269379]={ class = "DRUID", level = 110, },
	[269380]={ class = "DRUID", level = 110, },
	[270611]={ class = "DRUID", level = 110, },
	[164547]={ class = "DRUID", level = 110, },
	[278507]={ class = "DRUID", level = 110, },
	[273344]={ class = "DRUID", level = 110, },
	[273367]={ class = "DRUID", level = 110, },
	[273389]={ class = "DRUID", level = 110, },
	[278515]={ class = "DRUID", level = 110, },
	[269498]={ class = "DRUID", level = 110, },
	[272871]={ class = "DRUID", level = 110, },
	[272872]={ class = "DRUID", level = 110, },
	[287805]={ class = "DRUID", level = 110, },
	[275906]={ class = "DRUID", level = 110, },
	[275908]={ class = "DRUID", level = 110, },
	[275909]={ class = "DRUID", level = 110, },
	[273338]={ class = "DRUID", level = 110, },
	[273339]={ class = "DRUID", level = 110, },
	[280161]={ class = "DRUID", level = 110, },
	[280165]={ class = "DRUID", level = 110, },
	[278513]={ class = "DRUID", level = 110, },
	[278958]={ class = "DRUID", level = 110, },
	[279527]={ class = "DRUID", level = 110, },
--++ Druid Specializations ++	
	[157447]={ class = "DRUID", level = 1, },
	[228545]={ class = "DRUID", level = 1, },
	[5176]={ class = "DRUID", level = 1, },
	[190984]={ class = "DRUID", level = 1, },
	[279729]={ class = "DRUID", level = 1, },
	[197911]={ class = "DRUID", level = 10, },
	[22568]={ class = "DRUID", level = 10, },
	[6807]={ class = "DRUID", level = 10, },
	[774]={ class = "DRUID", level = 10, },
	[78674]={ class = "DRUID", level = 10, },
	[279708]={ class = "DRUID", level = 12, },
	[194153]={ class = "DRUID", level = 12, },
	[1822]={ class = "DRUID", level = 12, },
	[155722]={ class = "DRUID", level = 12, },
	[18562]={ class = "DRUID", level = 12, },
	[106832]={ class = "DRUID", level = 12, },
	[5217]={ class = "DRUID", level = 13, },
	[24858]={ class = "DRUID", level = 16, },
	[5215]={ class = "DRUID", level = 16, },
	[93402]={ class = "DRUID", level = 16, },
	[192081]={ class = "DRUID", level = 20, },
	[33763]={ class = "DRUID", level = 20, },
	[1079]={ class = "DRUID", level = 20, },
	[88423]={ class = "DRUID", level = 22, },
	[2782]={ class = "DRUID", level = 22, },
	[231052]={ class = "DRUID", level = 25, },
	[22812]={ class = "DRUID", level = 26, },
	[99]={ class = "DRUID", level = 28, },
	[231050]={ class = "DRUID", level = 32, },
	[213764]={ class = "DRUID", level = 32, },
	[106785]={ class = "DRUID", level = 32, },
	[197524]={ class = "DRUID", level = 34, },
	[131768]={ class = "DRUID", level = 34, },
	[16931]={ class = "DRUID", level = 34, },
	[145108]={ class = "DRUID", level = 34, },
	[145109]={ class = "DRUID", level = 34, },
	[145110]={ class = "DRUID", level = 34, },
	[61336]={ class = "DRUID", level = 36, },
	[106951]={ class = "DRUID", level = 40, },
	[279526]={ class = "DRUID", level = 40, },
	[22842]={ class = "DRUID", level = 40, },
	[191034]={ class = "DRUID", level = 40, },
	[191037]={ class = "DRUID", level = 40, },
	[48438]={ class = "DRUID", level = 40, },
	[231064]={ class = "DRUID", level = 44, },
	[231063]={ class = "DRUID", level = 44, },
	[231283]={ class = "DRUID", level = 44, },
	[194223]={ class = "DRUID", level = 48, },
	[272873]={ class = "DRUID", level = 48, },
	[210706]={ class = "DRUID", level = 48, },
	[16864]={ class = "DRUID", level = 48, },
	[135700]={ class = "DRUID", level = 48, },
	[113043]={ class = "DRUID", level = 48, },
	[29166]={ class = "DRUID", level = 50, },
	[106898]={ class = "DRUID", level = 50, },
	[270100]={ class = "DRUID", level = 52, },
	[231040]={ class = "DRUID", level = 52, },
	[231055]={ class = "DRUID", level = 52, },
	[48484]={ class = "DRUID", level = 54, },
	[58180]={ class = "DRUID", level = 54, },
	[102342]={ class = "DRUID", level = 54, },
	[231042]={ class = "DRUID", level = 54, },
	[231070]={ class = "DRUID", level = 55, },
	[231057]={ class = "DRUID", level = 56, },
	[2908]={ class = "DRUID", level = 56, },
	[279619]={ class = "DRUID", level = 60, },
	[273048]={ class = "DRUID", level = 63, },
	[22570]={ class = "DRUID", level = 63, },
	[231065]={ class = "DRUID", level = 65, },
	[212040]={ class = "DRUID", level = 66, },
	[145205]={ class = "DRUID", level = 70, },
	[106839]={ class = "DRUID", level = 70, },
	[231021]={ class = "DRUID", level = 70, },
	[77495]={ class = "DRUID", level = 78, },
	[155783]={ class = "DRUID", level = 78, },
	[77493]={ class = "DRUID", level = 78, },
	[77492]={ class = "DRUID", level = 78, },
	[16974]={ class = "DRUID", level = 80, },
	[78675]={ class = "DRUID", level = 80, },
	[288826]={ class = "DRUID", level = 80, },
	[740]={ class = "DRUID", level = 80, },
	[301768]={ class = "DRUID", level = 85, },
--++ Druid Talents ++	
	[207383]={ class = "DRUID", level = 15, },
	[203962]={ class = "DRUID", level = 15, },
	[203953]={ class = "DRUID", level = 15, },
	[155835]={ class = "DRUID", level = 15, },
	[102351]={ class = "DRUID", level = 15, },
	[205636]={ class = "DRUID", level = 15, },
	[155580]={ class = "DRUID", level = 15, },
	[202430]={ class = "DRUID", level = 15, },
	[202021]={ class = "DRUID", level = 15, },
	[200383]={ class = "DRUID", level = 15, },
	[202031]={ class = "DRUID", level = 15, },
	[202425]={ class = "DRUID", level = 15, },
	[108238]={ class = "DRUID", level = 30, },
	[252216]={ class = "DRUID", level = 30, },
	[102793]={ class = "DRUID", level = 30, },
	[102401]={ class = "DRUID", level = 30, },
	[197488]={ class = "DRUID", level = 45, },
	[197632]={ class = "DRUID", level = 45, },
	[197490]={ class = "DRUID", level = 45, },
	[202155]={ class = "DRUID", level = 45, },
	[202157]={ class = "DRUID", level = 45, },
	[197491]={ class = "DRUID", level = 45, },
	[217615]={ class = "DRUID", level = 45, },
	[197492]={ class = "DRUID", level = 45, },
	[102359]={ class = "DRUID", level = 60, },
	[5211]={ class = "DRUID", level = 60, },
	[132469]={ class = "DRUID", level = 60, },
	[61391]={ class = "DRUID", level = 60, },
	[200390]={ class = "DRUID", level = 75, },
	[203964]={ class = "DRUID", level = 75, },
	[102560]={ class = "DRUID", level = 75, },
	[102558]={ class = "DRUID", level = 75, },
	[102543]={ class = "DRUID", level = 75, },
	[33891]={ class = "DRUID", level = 75, },
	[52610]={ class = "DRUID", level = 75, },
	[114107]={ class = "DRUID", level = 75, },
	[158476]={ class = "DRUID", level = 75, },
	[158477]={ class = "DRUID", level = 75, },
	[158478]={ class = "DRUID", level = 75, },
	[202345]={ class = "DRUID", level = 75, },
	[279709]={ class = "DRUID", level = 75, },
	[202028]={ class = "DRUID", level = 90, },
	[203974]={ class = "DRUID", level = 90, },
	[155578]={ class = "DRUID", level = 90, },
	[197073]={ class = "DRUID", level = 90, },
	[285381]={ class = "DRUID", level = 90, },
	[285564]={ class = "DRUID", level = 90, },
	[207385]={ class = "DRUID", level = 90, },
	[202354]={ class = "DRUID", level = 90, },
	[202461]={ class = "DRUID", level = 90, },
	[202347]={ class = "DRUID", level = 90, },
	[197061]={ class = "DRUID", level = 90, },
	[203965]={ class = "DRUID", level = 90, },
	[279620]={ class = "DRUID", level = 90, },
	[155672]={ class = "DRUID", level = 100, },
	[274837]={ class = "DRUID", level = 100, },
	[274838]={ class = "DRUID", level = 100, },
	[197721]={ class = "DRUID", level = 100, },
	[202770]={ class = "DRUID", level = 100, },
	[155675]={ class = "DRUID", level = 100, },
	[204066]={ class = "DRUID", level = 100, },
	[236068]={ class = "DRUID", level = 100, },
	[274281]={ class = "DRUID", level = 100, },
	[274902]={ class = "DRUID", level = 100, },
	[80313]={ class = "DRUID", level = 100, },
	[204053]={ class = "DRUID", level = 100, },
	[202342]={ class = "DRUID", level = 100, },
	[202497]={ class = "DRUID", level = 100, },
--++ Druid PvP Talents ++	
	[207017]={ class = "DRUID", level = 40, },
	[200726]={ class = "DRUID", level = 40, },
	[233754]={ class = "DRUID", level = 40, },
	[228431]={ class = "DRUID", level = 40, },
	[200567]={ class = "DRUID", level = 40, },
	[33786]={ class = "DRUID", level = 40, },
	[209753]={ class = "DRUID", level = 40, },
	[233755]={ class = "DRUID", level = 40, },
	[201664]={ class = "DRUID", level = 40, },
	[236180]={ class = "DRUID", level = 40, },
	[233673]={ class = "DRUID", level = 40, },
	[232546]={ class = "DRUID", level = 40, },
	[203624]={ class = "DRUID", level = 40, },
	[200931]={ class = "DRUID", level = 40, },
	[247543]={ class = "DRUID", level = 40, },
	[202226]={ class = "DRUID", level = 40, },
	[209749]={ class = "DRUID", level = 40, },
	[236020]={ class = "DRUID", level = 40, },
	[203553]={ class = "DRUID", level = 40, },
	[213200]={ class = "DRUID", level = 40, },
	[203224]={ class = "DRUID", level = 40, },
	[236019]={ class = "DRUID", level = 40, },
	[233752]={ class = "DRUID", level = 40, },
	[203052]={ class = "DRUID", level = 40, },
	[202626]={ class = "DRUID", level = 40, },
	[236012]={ class = "DRUID", level = 40, },
	[236147]={ class = "DRUID", level = 40, },
	[289318]={ class = "DRUID", level = 40, },
	[289237]={ class = "DRUID", level = 40, },
	[236144]={ class = "DRUID", level = 40, },
	[233750]={ class = "DRUID", level = 40, },
	[209740]={ class = "DRUID", level = 40, },
	[289022]={ class = "DRUID", level = 40, },
	[203651]={ class = "DRUID", level = 40, },
	[202246]={ class = "DRUID", level = 40, },
	[200549]={ class = "DRUID", level = 40, },
	[209730]={ class = "DRUID", level = 40, },
	[202043]={ class = "DRUID", level = 40, },
	[236153]={ class = "DRUID", level = 40, },
	[203399]={ class = "DRUID", level = 40, },
	[203242]={ class = "DRUID", level = 40, },
	[205673]={ class = "DRUID", level = 40, },
	[202110]={ class = "DRUID", level = 40, },
	[236696]={ class = "DRUID", level = 40, },
	[201259]={ class = "DRUID", level = 40, },
--++ Hunter Abilities ++	
	[229533]={ class = "HUNTER", level = 1, },
	[883]={ class = "HUNTER", level = 1, },
	[157443]={ class = "HUNTER", level = 1, },
	[982]={ class = "HUNTER", level = 1, },
	[1494]={ class = "HUNTER", level = 4, },
	[19878]={ class = "HUNTER", level = 4, },
	[19879]={ class = "HUNTER", level = 4, },
	[19880]={ class = "HUNTER", level = 4, },
	[19882]={ class = "HUNTER", level = 4, },
	[19885]={ class = "HUNTER", level = 4, },
	[19883]={ class = "HUNTER", level = 4, },
	[19884]={ class = "HUNTER", level = 4, },
	[93321]={ class = "HUNTER", level = 10, },
	[93322]={ class = "HUNTER", level = 10, },
	[2641]={ class = "HUNTER", level = 10, },
	[1462]={ class = "HUNTER", level = 13, },
	[83242]={ class = "HUNTER", level = 13, },
	[6991]={ class = "HUNTER", level = 13, },
	[136]={ class = "HUNTER", level = 13, },
	[1515]={ class = "HUNTER", level = 13, },
	[6197]={ class = "HUNTER", level = 16, },
	[186257]={ class = "HUNTER", level = 22, },
	[5384]={ class = "HUNTER", level = 28, },
	[210000]={ class = "HUNTER", level = 32, },
	[83243]={ class = "HUNTER", level = 34, },
	[272651]={ class = "HUNTER", level = 38, },
	[1543]={ class = "HUNTER", level = 38, },
	[61648]={ class = "HUNTER", level = 40, },
	[125050]={ class = "HUNTER", level = 40, },
	[127933]={ class = "HUNTER", level = 40, },
	[209997]={ class = "HUNTER", level = 40, },
	[83244]={ class = "HUNTER", level = 57, },
	[186265]={ class = "HUNTER", level = 70, },
	[83245]={ class = "HUNTER", level = 80, },
--++ Hunter Artifact Traits ++	
	[203413]={ class = "HUNTER", level = 100, },
	[203415]={ class = "HUNTER", level = 100, },
	[207068]={ class = "HUNTER", level = 100, },
	[204147]={ class = "HUNTER", level = 100, },
--++ Hunter Azerite Traits ++	
	[263814]={ class = "HUNTER", level = 110, },
	[263829]={ class = "HUNTER", level = 110, },
	[277653]={ class = "HUNTER", level = 110, },
	[277966]={ class = "HUNTER", level = 110, },
	[277969]={ class = "HUNTER", level = 110, },
	[274441]={ class = "HUNTER", level = 110, },
	[274442]={ class = "HUNTER", level = 110, },
	[274443]={ class = "HUNTER", level = 110, },
	[287093]={ class = "HUNTER", level = 110, },
	[287097]={ class = "HUNTER", level = 110, },
	[280169]={ class = "HUNTER", level = 110, },
	[278529]={ class = "HUNTER", level = 110, },
	[279607]={ class = "HUNTER", level = 110, },
	[269624]={ class = "HUNTER", level = 110, },
	[269625]={ class = "HUNTER", level = 110, },
	[270651]={ class = "HUNTER", level = 110, },
	[278531]={ class = "HUNTER", level = 110, },
	[279636]={ class = "HUNTER", level = 110, },
	[279637]={ class = "HUNTER", level = 110, },
	[273262]={ class = "HUNTER", level = 110, },
	[273263]={ class = "HUNTER", level = 110, },
	[264198]={ class = "HUNTER", level = 110, },
	[273283]={ class = "HUNTER", level = 110, },
	[273284]={ class = "HUNTER", level = 110, },
	[287938]={ class = "HUNTER", level = 110, },
	[287940]={ class = "HUNTER", level = 110, },
	[279806]={ class = "HUNTER", level = 110, },
	[279807]={ class = "HUNTER", level = 110, },
	[288570]={ class = "HUNTER", level = 110, },
	[288571]={ class = "HUNTER", level = 110, },
	[288573]={ class = "HUNTER", level = 110, },
	[269256]={ class = "HUNTER", level = 110, },
	[278530]={ class = "HUNTER", level = 110, },
	[263821]={ class = "HUNTER", level = 110, },
	[264195]={ class = "HUNTER", level = 110, },
	[269343]={ class = "HUNTER", level = 110, },
	[272717]={ class = "HUNTER", level = 110, },
	[274356]={ class = "HUNTER", level = 110, },
	[277651]={ class = "HUNTER", level = 110, },
	[277957]={ class = "HUNTER", level = 110, },
	[277959]={ class = "HUNTER", level = 110, },
	[287707]={ class = "HUNTER", level = 110, },
	[287711]={ class = "HUNTER", level = 110, },
	[274444]={ class = "HUNTER", level = 110, },
	[274445]={ class = "HUNTER", level = 110, },
	[274446]={ class = "HUNTER", level = 110, },
	[274590]={ class = "HUNTER", level = 110, },
	[263818]={ class = "HUNTER", level = 110, },
	[264199]={ class = "HUNTER", level = 110, },
	[278532]={ class = "HUNTER", level = 110, },
	[279589]={ class = "HUNTER", level = 110, },
	[272742]={ class = "HUNTER", level = 110, },
	[272743]={ class = "HUNTER", level = 110, },
	[185791]={ class = "HUNTER", level = 110, },
--++ Hunter Specializations ++	
	[193455]={ class = "HUNTER", level = 1, },
	[186270]={ class = "HUNTER", level = 1, },
	[56641]={ class = "HUNTER", level = 1, },
	[262837]={ class = "HUNTER", level = 3, },
	[5116]={ class = "HUNTER", level = 4, },
	[195645]={ class = "HUNTER", level = 4, },
	[781]={ class = "HUNTER", level = 8, },
	[185358]={ class = "HUNTER", level = 10, },
	[34026]={ class = "HUNTER", level = 10, },
	[259489]={ class = "HUNTER", level = 10, },
	[155228]={ class = "HUNTER", level = 10, },
	[164273]={ class = "HUNTER", level = 10, },
	[19434]={ class = "HUNTER", level = 12, },
	[217200]={ class = "HUNTER", level = 12, },
	[272790]={ class = "HUNTER", level = 12, },
	[259491]={ class = "HUNTER", level = 12, },
	[190925]={ class = "HUNTER", level = 14, },
	[257620]={ class = "HUNTER", level = 14, },
	[2643]={ class = "HUNTER", level = 16, },
	[187650]={ class = "HUNTER", level = 18, },
	[19574]={ class = "HUNTER", level = 20, },
	[186254]={ class = "HUNTER", level = 20, },
	[257044]={ class = "HUNTER", level = 20, },
	[185789]={ class = "HUNTER", level = 20, },
	[259495]={ class = "HUNTER", level = 20, },
	[109304]={ class = "HUNTER", level = 24, },
	[186387]={ class = "HUNTER", level = 26, },
	[19577]={ class = "HUNTER", level = 26, },
	[187708]={ class = "HUNTER", level = 28, },
	[147362]={ class = "HUNTER", level = 32, },
	[187707]={ class = "HUNTER", level = 32, },
	[260240]={ class = "HUNTER", level = 34, },
	[187698]={ class = "HUNTER", level = 36, },
	[193530]={ class = "HUNTER", level = 40, },
	[266779]={ class = "HUNTER", level = 40, },
	[288613]={ class = "HUNTER", level = 40, },
	[34477]={ class = "HUNTER", level = 42, },
	[56315]={ class = "HUNTER", level = 44, },
	[231546]={ class = "HUNTER", level = 48, },
	[115939]={ class = "HUNTER", level = 50, },
	[263186]={ class = "HUNTER", level = 50, },
	[257621]={ class = "HUNTER", level = 50, },
	[262838]={ class = "HUNTER", level = 52, },
	[262839]={ class = "HUNTER", level = 52, },
	[186289]={ class = "HUNTER", level = 54, },
	[231548]={ class = "HUNTER", level = 54, },
	[53270]={ class = "HUNTER", level = 65, },
	[231550]={ class = "HUNTER", level = 65, },
	[76657]={ class = "HUNTER", level = 78, },
	[193468]={ class = "HUNTER", level = 78, },
	[263135]={ class = "HUNTER", level = 78, },
	[231549]={ class = "HUNTER", level = 85, },
--++ Hunter Talents ++	
	[269737]={ class = "HUNTER", level = 15, },
	[267116]={ class = "HUNTER", level = 15, },
	[120679]={ class = "HUNTER", level = 15, },
	[273887]={ class = "HUNTER", level = 15, },
	[260309]={ class = "HUNTER", level = 15, },
	[271788]={ class = "HUNTER", level = 15, },
	[265895]={ class = "HUNTER", level = 15, },
	[268501]={ class = "HUNTER", level = 15, },
	[212436]={ class = "HUNTER", level = 30, },
	[260228]={ class = "HUNTER", level = 30, },
	[53209]={ class = "HUNTER", level = 30, },
	[212431]={ class = "HUNTER", level = 30, },
	[264332]={ class = "HUNTER", level = 30, },
	[260241]={ class = "HUNTER", level = 30, },
	[199528]={ class = "HUNTER", level = 30, },
	[193532]={ class = "HUNTER", level = 30, },
	[260243]={ class = "HUNTER", level = 30, },
	[199483]={ class = "HUNTER", level = 45, },
	[270581]={ class = "HUNTER", level = 45, },
	[199921]={ class = "HUNTER", level = 45, },
	[231390]={ class = "HUNTER", level = 45, },
	[260248]={ class = "HUNTER", level = 60, },
	[257284]={ class = "HUNTER", level = 60, },
	[193533]={ class = "HUNTER", level = 60, },
	[162488]={ class = "HUNTER", level = 60, },
	[260367]={ class = "HUNTER", level = 60, },
	[257944]={ class = "HUNTER", level = 60, },
	[257891]={ class = "HUNTER", level = 60, },
	[109248]={ class = "HUNTER", level = 75, },
	[266921]={ class = "HUNTER", level = 75, },
	[109215]={ class = "HUNTER", level = 75, },
	[120360]={ class = "HUNTER", level = 90, },
	[260402]={ class = "HUNTER", level = 90, },
	[269751]={ class = "HUNTER", level = 90, },
	[260393]={ class = "HUNTER", level = 90, },
	[259387]={ class = "HUNTER", level = 90, },
	[201430]={ class = "HUNTER", level = 90, },
	[199530]={ class = "HUNTER", level = 90, },
	[260285]={ class = "HUNTER", level = 90, },
	[191384]={ class = "HUNTER", level = 100, },
	[260331]={ class = "HUNTER", level = 100, },
	[260404]={ class = "HUNTER", level = 100, },
	[259391]={ class = "HUNTER", level = 100, },
	[199532]={ class = "HUNTER", level = 100, },
	[194595]={ class = "HUNTER", level = 100, },
	[198670]={ class = "HUNTER", level = 100, },
	[194407]={ class = "HUNTER", level = 100, },
	[271014]={ class = "HUNTER", level = 100, },
--++ Hunter PvP Talents ++	
	[203340]={ class = "HUNTER", level = 40, },
	[205691]={ class = "HUNTER", level = 40, },
	[208652]={ class = "HUNTER", level = 40, },
	[202589]={ class = "HUNTER", level = 40, },
	[236776]={ class = "HUNTER", level = 40, },
	[203235]={ class = "HUNTER", level = 40, },
	[248518]={ class = "HUNTER", level = 40, },
	[212640]={ class = "HUNTER", level = 40, },
	[248443]={ class = "HUNTER", level = 40, },
	[53480]={ class = "HUNTER", level = 40, },
	[213691]={ class = "HUNTER", level = 40, },
	[202900]={ class = "HUNTER", level = 40, },
	[203155]={ class = "HUNTER", level = 40, },
	[202914]={ class = "HUNTER", level = 40, },
	[203264]={ class = "HUNTER", level = 40, },
	[202746]={ class = "HUNTER", level = 40, },
	[212668]={ class = "HUNTER", level = 40, },
	[212638]={ class = "HUNTER", level = 40, },
	[203129]={ class = "HUNTER", level = 40, },
	[202797]={ class = "HUNTER", level = 40, },
	[204190]={ class = "HUNTER", level = 40, },
--++ Mage Abilities ++	
	[61780]={ class = "MAGE", level = 1, },
	[126819]={ class = "MAGE", level = 1, },
	[161353]={ class = "MAGE", level = 1, },
	[161354]={ class = "MAGE", level = 1, },
	[161355]={ class = "MAGE", level = 1, },
	[122]={ class = "MAGE", level = 5, },
	[118]={ class = "MAGE", level = 8, },
	[190336]={ class = "MAGE", level = 13, },
	[193759]={ class = "MAGE", level = 14, },
	[1953]={ class = "MAGE", level = 16, },
	[3565]={ class = "MAGE", level = 17, },
	[32271]={ class = "MAGE", level = 17, },
	[3562]={ class = "MAGE", level = 17, },
	[3567]={ class = "MAGE", level = 17, },
	[32272]={ class = "MAGE", level = 17, },
	[3561]={ class = "MAGE", level = 17, },
	[49359]={ class = "MAGE", level = 17, },
	[3566]={ class = "MAGE", level = 17, },
	[3563]={ class = "MAGE", level = 17, },
	[2139]={ class = "MAGE", level = 22, },
	[475]={ class = "MAGE", level = 28, },
	[130]={ class = "MAGE", level = 38, },
	[11419]={ class = "MAGE", level = 42, },
	[32266]={ class = "MAGE", level = 42, },
	[11416]={ class = "MAGE", level = 42, },
	[11417]={ class = "MAGE", level = 42, },
	[32267]={ class = "MAGE", level = 42, },
	[10059]={ class = "MAGE", level = 42, },
	[11420]={ class = "MAGE", level = 42, },
	[11418]={ class = "MAGE", level = 42, },
	[131784]={ class = "MAGE", level = 49, },
	[45438]={ class = "MAGE", level = 50, },
	[49361]={ class = "MAGE", level = 52, },
	[49358]={ class = "MAGE", level = 52, },
	[1459]={ class = "MAGE", level = 58, },
	[210086]={ class = "MAGE", level = 58, },
	[28271]={ class = "MAGE", level = 60, },
	[28272]={ class = "MAGE", level = 60, },
	[61305]={ class = "MAGE", level = 60, },
	[61721]={ class = "MAGE", level = 60, },
	[161372]={ class = "MAGE", level = 60, },
	[277787]={ class = "MAGE", level = 60, },
	[277792]={ class = "MAGE", level = 60, },
	[53140]={ class = "MAGE", level = 60, },
	[33690]={ class = "MAGE", level = 62, },
	[35715]={ class = "MAGE", level = 62, },
	[33691]={ class = "MAGE", level = 66, },
	[35717]={ class = "MAGE", level = 66, },
	[30449]={ class = "MAGE", level = 70, },
	[120145]={ class = "MAGE", level = 71, },
	[224871]={ class = "MAGE", level = 71, },
	[224869]={ class = "MAGE", level = 71, },
	[120146]={ class = "MAGE", level = 74, },
	[53142]={ class = "MAGE", level = 74, },
	[80353]={ class = "MAGE", level = 80, },
	[88345]={ class = "MAGE", level = 85, },
	[88346]={ class = "MAGE", level = 85, },
	[88342]={ class = "MAGE", level = 85, },
	[88344]={ class = "MAGE", level = 85, },
	[132620]={ class = "MAGE", level = 90, },
	[132626]={ class = "MAGE", level = 90, },
	[132621]={ class = "MAGE", level = 90, },
	[132627]={ class = "MAGE", level = 90, },
	[176246]={ class = "MAGE", level = 92, },
	[176244]={ class = "MAGE", level = 92, },
	[176248]={ class = "MAGE", level = 92, },
	[176242]={ class = "MAGE", level = 92, },
	[281400]={ class = "MAGE", level = 110, },
	[281402]={ class = "MAGE", level = 110, },
	[281403]={ class = "MAGE", level = 110, },
	[281404]={ class = "MAGE", level = 110, },
--++ Mage Artifact Traits ++	
	[224968]={ class = "MAGE", level = 100, },
	[194466]={ class = "MAGE", level = 100, },
	[214634]={ class = "MAGE", level = 100, },
--++ Mage Azerite Traits ++	
	[274594]={ class = "MAGE", level = 110, },
	[270669]={ class = "MAGE", level = 110, },
	[270670]={ class = "MAGE", level = 110, },
	[270671]={ class = "MAGE", level = 110, },
	[274596]={ class = "MAGE", level = 110, },
	[274597]={ class = "MAGE", level = 110, },
	[274598]={ class = "MAGE", level = 110, },
	[273326]={ class = "MAGE", level = 110, },
	[273327]={ class = "MAGE", level = 110, },
	[273329]={ class = "MAGE", level = 110, },
	[273330]={ class = "MAGE", level = 110, },
	[288466]={ class = "MAGE", level = 110, },
	[280173]={ class = "MAGE", level = 110, },
	[278538]={ class = "MAGE", level = 110, },
	[279084]={ class = "MAGE", level = 110, },
	[274379]={ class = "MAGE", level = 110, },
	[264351]={ class = "MAGE", level = 110, },
	[264352]={ class = "MAGE", level = 110, },
	[264353]={ class = "MAGE", level = 110, },
	[286027]={ class = "MAGE", level = 110, },
	[278537]={ class = "MAGE", level = 110, },
	[278539]={ class = "MAGE", level = 110, },
	[272932]={ class = "MAGE", level = 110, },
	[272933]={ class = "MAGE", level = 110, },
	[272934]={ class = "MAGE", level = 110, },
	[288164]={ class = "MAGE", level = 110, },
	[288204]={ class = "MAGE", level = 110, },
	[278542]={ class = "MAGE", level = 110, },
	[279684]={ class = "MAGE", level = 110, },
	[279685]={ class = "MAGE", level = 110, },
	[278536]={ class = "MAGE", level = 110, },
	[279080]={ class = "MAGE", level = 110, },
	[279081]={ class = "MAGE", level = 110, },
	[279854]={ class = "MAGE", level = 110, },
	[279855]={ class = "MAGE", level = 110, },
	[272968]={ class = "MAGE", level = 110, },
	[272969]={ class = "MAGE", level = 110, },
	[272970]={ class = "MAGE", level = 110, },
	[288121]={ class = "MAGE", level = 110, },
	[288125]={ class = "MAGE", level = 110, },
	[277656]={ class = "MAGE", level = 110, },
	[277663]={ class = "MAGE", level = 110, },
	[277902]={ class = "MAGE", level = 110, },
	[277904]={ class = "MAGE", level = 110, },
	[278541]={ class = "MAGE", level = 110, },
	[288755]={ class = "MAGE", level = 110, },
	[288795]={ class = "MAGE", level = 110, },
	[288800]={ class = "MAGE", level = 110, },
	[288803]={ class = "MAGE", level = 110, },
--++ Mage Specializations ++	
	[116]={ class = "MAGE", level = 1, },
	[228597]={ class = "MAGE", level = 1, },
	[108853]={ class = "MAGE", level = 3, },
	[44425]={ class = "MAGE", level = 10, },
	[30451]={ class = "MAGE", level = 10, },
	[117216]={ class = "MAGE", level = 10, },
	[133]={ class = "MAGE", level = 10, },
	[48107]={ class = "MAGE", level = 10, },
	[48108]={ class = "Mage", level = 10, },
	[30455]={ class = "MAGE", level = 10, },
	[5143]={ class = "MAGE", level = 12, },
	[11366]={ class = "MAGE", level = 12, },
	[31687]={ class = "MAGE", level = 12, },
	[195283]={ class = "MAGE", level = 14, },
	[2948]={ class = "MAGE", level = 14, },
	[12982]={ class = "MAGE", level = 14, },
	[1449]={ class = "MAGE", level = 18, },
	[190356]={ class = "MAGE", level = 18, },
	[231568]={ class = "MAGE", level = 18, },
	[12051]={ class = "MAGE", level = 20, },
	[2120]={ class = "MAGE", level = 20, },
	[44614]={ class = "MAGE", level = 20, },
	[112965]={ class = "MAGE", level = 24, },
	[235313]={ class = "MAGE", level = 26, },
	[11426]={ class = "MAGE", level = 26, },
	[235450]={ class = "MAGE", level = 26, },
	[190447]={ class = "MAGE", level = 28, },
	[31661]={ class = "MAGE", level = 32, },
	[231596]={ class = "MAGE", level = 32, },
	[31589]={ class = "MAGE", level = 32, },
	[231564]={ class = "MAGE", level = 34, },
	[120]={ class = "MAGE", level = 34, },
	[157642]={ class = "MAGE", level = 35, },
	[231582]={ class = "MAGE", level = 36, },
	[12042]={ class = "MAGE", level = 40, },
	[190319]={ class = "MAGE", level = 40, },
	[12472]={ class = "MAGE", level = 40, },
	[66]={ class = "MAGE", level = 42, },
	[231584]={ class = "MAGE", level = 48, },
	[195676]={ class = "MAGE", level = 48, },
	[231567]={ class = "MAGE", level = 48, },
	[86949]={ class = "MAGE", level = 52, },
	[235219]={ class = "MAGE", level = 52, },
	[205025]={ class = "MAGE", level = 54, },
	[231565]={ class = "MAGE", level = 56, },
	[84714]={ class = "MAGE", level = 57, },
	[84721]={ class = "MAGE", level = 57, },
	[236662]={ class = "MAGE", level = 63, },
	[231630]={ class = "MAGE", level = 65, },
	[110959]={ class = "MAGE", level = 65, },
	[76613]={ class = "MAGE", level = 78, },
	[205473]={ class = "MAGE", level = 78, },
	[12846]={ class = "MAGE", level = 78, },
	[190740]={ class = "MAGE", level = 78, },
--++ Mage Talents ++	
	[236628]={ class = "MAGE", level = 15, },
	[205022]={ class = "MAGE", level = 15, },
	[205027]={ class = "MAGE", level = 15, },
	[205766]={ class = "MAGE", level = 15, },
	[205026]={ class = "MAGE", level = 15, },
	[157997]={ class = "MAGE", level = 15, },
	[205024]={ class = "MAGE", level = 15, },
	[205020]={ class = "MAGE", level = 15, },
	[264354]={ class = "MAGE", level = 15, },
	[269644]={ class = "MAGE", level = 15, },
	[157981]={ class = "MAGE", level = 30, },
	[235365]={ class = "MAGE", level = 30, },
	[235297]={ class = "MAGE", level = 30, },
	[108839]={ class = "MAGE", level = 30, },
	[235463]={ class = "MAGE", level = 30, },
	[212653]={ class = "MAGE", level = 30, },
	[236457]={ class = "MAGE", level = 30, },
	[1463]={ class = "MAGE", level = 45, },
	[55342]={ class = "MAGE", level = 45, },
	[116011]={ class = "MAGE", level = 45, },
	[235870]={ class = "MAGE", level = 60, },
	[278309]={ class = "MAGE", level = 60, },
	[205032]={ class = "MAGE", level = 60, },
	[257537]={ class = "MAGE", level = 60, },
	[205029]={ class = "MAGE", level = 60, },
	[205030]={ class = "MAGE", level = 60, },
	[257541]={ class = "MAGE", level = 60, },
	[205028]={ class = "MAGE", level = 60, },
	[157980]={ class = "MAGE", level = 60, },
	[235711]={ class = "MAGE", level = 75, },
	[236058]={ class = "MAGE", level = 75, },
	[235224]={ class = "MAGE", level = 75, },
	[205036]={ class = "MAGE", level = 75, },
	[113724]={ class = "MAGE", level = 75, },
	[153595]={ class = "MAGE", level = 90, },
	[205023]={ class = "MAGE", level = 90, },
	[205037]={ class = "MAGE", level = 90, },
	[270233]={ class = "MAGE", level = 90, },
	[44457]={ class = "MAGE", level = 90, },
	[114923]={ class = "MAGE", level = 90, },
	[281482]={ class = "MAGE", level = 90, },
	[210725]={ class = "MAGE", level = 90, },
	[153626]={ class = "MAGE", level = 100, },
	[199786]={ class = "MAGE", level = 100, },
	[155148]={ class = "MAGE", level = 100, },
	[153561]={ class = "MAGE", level = 100, },
	[155147]={ class = "MAGE", level = 100, },
	[269650]={ class = "MAGE", level = 100, },
	[205021]={ class = "MAGE", level = 100, },
	[155149]={ class = "MAGE", level = 100, },
	[210805]={ class = "MAGE", level = 100, },
--++ Mage PvP Talents ++	
	[276741]={ class = "MAGE", level = 40, },
	[206431]={ class = "MAGE", level = 40, },
	[198126]={ class = "MAGE", level = 40, },
	[198148]={ class = "MAGE", level = 40, },
	[280450]={ class = "MAGE", level = 40, },
	[236788]={ class = "MAGE", level = 40, },
	[198123]={ class = "MAGE", level = 40, },
	[203283]={ class = "MAGE", level = 40, },
	[203284]={ class = "MAGE", level = 40, },
	[198120]={ class = "MAGE", level = 40, },
	[203286]={ class = "MAGE", level = 40, },
	[198144]={ class = "MAGE", level = 40, },
	[198100]={ class = "MAGE", level = 40, },
	[198158]={ class = "MAGE", level = 40, },
	[210476]={ class = "MAGE", level = 40, },
	[198062]={ class = "MAGE", level = 40, },
	[198064]={ class = "MAGE", level = 40, },
	[213220]={ class = "MAGE", level = 40, },
	[198111]={ class = "MAGE", level = 40, },
	[203275]={ class = "MAGE", level = 40, },
	[198151]={ class = "MAGE", level = 40, },
	[203280]={ class = "MAGE", level = 40, },
--++ Monk Abilities ++	
	[116812]={ class = "MONK", level = 1, },
	[100780]={ class = "MONK", level = 1, },
	[100784]={ class = "MONK", level = 3, },
	[109132]={ class = "MONK", level = 5, },
	[209525]={ class = "MONK", level = 10, },
	[115546]={ class = "MONK", level = 13, },
	[115178]={ class = "MONK", level = 14, },
	[126892]={ class = "MONK", level = 14, },
	[117952]={ class = "MONK", level = 18, },
	[115078]={ class = "MONK", level = 25, },
	[8647]={ class = "MONK", level = 26, },
	[126895]={ class = "MONK", level = 30, },
	[125883]={ class = "MONK", level = 70, },
	[101643]={ class = "MONK", level = 80, },
	[119996]={ class = "MONK", level = 80, },
--++ Monk Artifact Traits ++	
	[195650]={ class = "MONK", level = 110, },
	[196061]={ class = "MONK", level = 100, },
	[214326]={ class = "MONK", level = 100, },
	[205406]={ class = "MONK", level = 100, },
	[205320]={ class = "MONK", level = 100, },
--++ Monk Azerite Traits ++	
	[272792]={ class = "MONK", level = 110, },
	[272797]={ class = "MONK", level = 110, },
	[277667]={ class = "MONK", level = 110, },
	[287472]={ class = "MONK", level = 110, },
	[286585]={ class = "MONK", level = 110, },
	[286586]={ class = "MONK", level = 110, },
	[286587]={ class = "MONK", level = 110, },
	[278571]={ class = "MONK", level = 110, },
	[279605]={ class = "MONK", level = 110, },
	[289323]={ class = "MONK", level = 110, },
	[275892]={ class = "MONK", level = 110, },
	[279875]={ class = "MONK", level = 110, },
	[287055]={ class = "MONK", level = 110, },
	[288634]={ class = "MONK", level = 110, },
	[275975]={ class = "MONK", level = 110, },
	[276025]={ class = "MONK", level = 110, },
	[280386]={ class = "MONK", level = 110, },
	[279918]={ class = "MONK", level = 110, },
	[279921]={ class = "MONK", level = 110, },
	[279922]={ class = "MONK", level = 110, },
	[273328]={ class = "MONK", level = 110, },
	[273334]={ class = "MONK", level = 110, },
	[278577]={ class = "MONK", level = 110, },
	[278718]={ class = "MONK", level = 110, },
	[287829]={ class = "MONK", level = 110, },
	[287830]={ class = "MONK", level = 110, },
	[273464]={ class = "MONK", level = 110, },
	[273468]={ class = "MONK", level = 110, },
	[285958]={ class = "MONK", level = 110, },
	[274771]={ class = "MONK", level = 110, },
	[274774]={ class = "MONK", level = 110, },
	[273291]={ class = "MONK", level = 110, },
	[273292]={ class = "MONK", level = 110, },
	[273298]={ class = "MONK", level = 110, },
	[273299]={ class = "MONK", level = 110, },
	[275673]={ class = "MONK", level = 110, },
	[280182]={ class = "MONK", level = 110, },
	[280184]={ class = "MONK", level = 110, },
	[278569]={ class = "MONK", level = 110, },
	[278576]={ class = "MONK", level = 110, },
	[279603]={ class = "MONK", level = 110, },
--++ Monk Specializations ++	
	[157445]={ class = "MONK", level = 1, },
	[116670]={ class = "MONK", level = 8, },
	[205523]={ class = "MONK", level = 10, },
	[245013]={ class = "MONK", level = 10, },
	[121253]={ class = "MONK", level = 10, },
	[107428]={ class = "MONK", level = 10, },
	[185099]={ class = "MONK", level = 56, },
	[115175]={ class = "MONK", level = 10, },
	[261916]={ class = "MONK", level = 12, },
	[124682]={ class = "MONK", level = 12, },
	[116645]={ class = "MONK", level = 12, },
	[202090]={ class = "MONK", level = 12, },
	[231602]={ class = "MONK", level = 12, },
	[116095]={ class = "MONK", level = 16, },
	[115069]={ class = "MONK", level = 16, },
	[128595]={ class = "MONK", level = 20, },
	[113656]={ class = "MONK", level = 20, },
	[117418]={ class = "MONK", level = 20, },
	[287062]={ class = "MONK", level = 20, },
	[287063]={ class = "MONK", level = 20, },
	[115308]={ class = "MONK", level = 20, },
	[115151]={ class = "MONK", level = 20, },
	[119611]={ class = "MONK", level = 20, },
	[261917]={ class = "MONK", level = 22, },
	[115450]={ class = "MONK", level = 22, },
	[218164]={ class = "MONK", level = 22, },
	[169340]={ class = "MONK", level = 22, },
	[116092]={ class = "MONK", level = 28, },
	[119582]={ class = "MONK", level = 28, },
	[274586]={ class = "MONK", level = 28, },
	[231605]={ class = "MONK", level = 32, },
	[124502]={ class = "MONK", level = 32, },
	[115080]={ class = "MONK", level = 32, },
	[271232]={ class = "MONK", level = 32, },
	[116849]={ class = "MONK", level = 35, },
	[116705]={ class = "MONK", level = 35, },
	[262840]={ class = "MONK", level = 36, },
	[157411]={ class = "MONK", level = 38, },
	[115181]={ class = "MONK", level = 40, },
	[220357]={ class = "MONK", level = 40, },
	[191837]={ class = "MONK", level = 40, },
	[101546]={ class = "MONK", level = 40, },
	[137384]={ class = "MONK", level = 42, },
	[281231]={ class = "MONK", level = 42, },
	[101545]={ class = "MONK", level = 48, },
	[115072]={ class = "MONK", level = 50, },
	[137639]={ class = "MONK", level = 50, },
	[116680]={ class = "MONK", level = 50, },
	[119381]={ class = "MONK", level = 52, },
	[115203]={ class = "MONK", level = 55, },
	[243435]={ class = "MONK", level = 55, },
	[122470]={ class = "MONK", level = 55, },
	[231633]={ class = "MONK", level = 58, },
	[231876]={ class = "MONK", level = 63, },
	[115176]={ class = "MONK", level = 65, },
	[212051]={ class = "MONK", level = 66, },
	[216519]={ class = "MONK", level = 70, },
	[115310]={ class = "MONK", level = 70, },
	[231627]={ class = "MONK", level = 70, },
	[115636]={ class = "MONK", level = 78, },
	[117906]={ class = "MONK", level = 78, },
	[117907]={ class = "MONK", level = 78, },
--++ Monk Talents ++	
	[123986]={ class = "MONK", level = 15, },
	[115098]={ class = "MONK", level = 15, },
	[196607]={ class = "MONK", level = 15, },
	[197900]={ class = "MONK", level = 15, },
	[115173]={ class = "MONK", level = 30, },
	[115008]={ class = "MONK", level = 30, },
	[116841]={ class = "MONK", level = 30, },
	[115396]={ class = "MONK", level = 45, },
	[115399]={ class = "MONK", level = 45, },
	[115288]={ class = "MONK", level = 45, },
	[261947]={ class = "MONK", level = 45, },
	[197915]={ class = "MONK", level = 45, },
	[196721]={ class = "MONK", level = 45, },
	[197908]={ class = "MONK", level = 45, },
	[210802]={ class = "MONK", level = 45, },
	[242580]={ class = "MONK", level = 45, },
	[280195]={ class = "MONK", level = 60, },
	[116844]={ class = "MONK", level = 60, },
	[198898]={ class = "MONK", level = 60, },
	[115315]={ class = "MONK", level = 60, },
	[264348]={ class = "MONK", level = 60, },
	[280515]={ class = "MONK", level = 75, },
	[122278]={ class = "MONK", level = 75, },
	[122783]={ class = "MONK", level = 75, },
	[261767]={ class = "MONK", level = 75, },
	[196740]={ class = "MONK", level = 90, },
	[198664]={ class = "MONK", level = 90, },
	[132578]={ class = "MONK", level = 90, },
	[123904]={ class = "MONK", level = 90, },
	[196725]={ class = "MONK", level = 90, },
	[116847]={ class = "MONK", level = 90, },
	[196730]={ class = "MONK", level = 90, },
	[115313]={ class = "MONK", level = 90, },
	[196736]={ class = "MONK", level = 100, },
	[197895]={ class = "MONK", level = 100, },
	[115295]={ class = "MONK", level = 100, },
	[196737]={ class = "MONK", level = 100, },
	[274909]={ class = "MONK", level = 100, },
	[152173]={ class = "MONK", level = 100, },
	[280197]={ class = "MONK", level = 100, },
	[274963]={ class = "MONK", level = 100, },
	[152175]={ class = "MONK", level = 100, },
--++ Monk PvP Talents ++	
	[207025]={ class = "MONK", level = 40, },
	[287503]={ class = "MONK", level = 40, },
	[202162]={ class = "MONK", level = 40, },
	[202424]={ class = "MONK", level = 40, },
	[202428]={ class = "MONK", level = 40, },
	[213658]={ class = "MONK", level = 40, },
	[201769]={ class = "MONK", level = 40, },
	[202577]={ class = "MONK", level = 40, },
	[202335]={ class = "MONK", level = 40, },
	[205147]={ class = "MONK", level = 40, },
	[216255]={ class = "MONK", level = 40, },
	[201318]={ class = "MONK", level = 40, },
	[233759]={ class = "MONK", level = 40, },
	[202200]={ class = "MONK", level = 40, },
	[205234]={ class = "MONK", level = 40, },
	[202126]={ class = "MONK", level = 40, },
	[202272]={ class = "MONK", level = 40, },
	[202107]={ class = "MONK", level = 40, },
	[202370]={ class = "MONK", level = 40, },
	[232876]={ class = "MONK", level = 40, },
	[287599]={ class = "MONK", level = 40, },
	[202523]={ class = "MONK", level = 40, },
	[287771]={ class = "MONK", level = 40, },
	[201372]={ class = "MONK", level = 40, },
	[227344]={ class = "MONK", level = 40, },
	[247483]={ class = "MONK", level = 40, },
	[287681]={ class = "MONK", level = 40, },
	[216113]={ class = "MONK", level = 40, },
	[287506]={ class = "MONK", level = 40, },
	[209584]={ class = "MONK", level = 40, },
--++ Paladin Abilities ++	
	[123830]={ class = "PALADIN", level = 1, },
	[115675]={ class = "PALADIN", level = 1, },
	[35395]={ class = "PALADIN", level = 1, },
	[82242]={ class = "PALADIN", level = 1, },
	[62124]={ class = "PALADIN", level = 12, },
	[7328]={ class = "PALADIN", level = 14, },
	[642]={ class = "PALADIN", level = 18, },
	[270562]={ class = "PALADIN", level = 20, },
	[270564]={ class = "PALADIN", level = 20, },
	[73629]={ class = "PALADIN", level = 20, },
	[69820]={ class = "PALADIN", level = 20, },
	[34769]={ class = "PALADIN", level = 20, },
	[13819]={ class = "PALADIN", level = 20, },
	[190784]={ class = "PALADIN", level = 28, },
	[221883]={ class = "PALADIN", level = 28, },
	[1044]={ class = "PALADIN", level = 38, },
	[121183]={ class = "PALADIN", level = 40, },
	[23214]={ class = "PALADIN", level = 40, },
	[73630]={ class = "PALADIN", level = 40, },
	[69826]={ class = "PALADIN", level = 40, },
	[34767]={ class = "PALADIN", level = 40, },
	[32223]={ class = "PALADIN", level = 44, },
	[633]={ class = "PALADIN", level = 55, },
--++ Paladin Artifact Traits ++	
	[209202]={ class = "PALADIN", level = 100, },
	[200652]={ class = "PALADIN", level = 100, },
	[200654]={ class = "PALADIN", level = 100, },
	[205273]={ class = "PALADIN", level = 100, },
--++ Paladin Azerite Traits ++	
	[272904]={ class = "PALADIN", level = 110, },
	[278594]={ class = "PALADIN", level = 110, },
	[279406]={ class = "PALADIN", level = 110, },
	[272976]={ class = "PALADIN", level = 110, },
	[272977]={ class = "PALADIN", level = 110, },
	[272979]={ class = "PALADIN", level = 110, },
	[269243]={ class = "PALADIN", level = 110, },
	[275463]={ class = "PALADIN", level = 110, },
	[275466]={ class = "PALADIN", level = 110, },
	[275468]={ class = "PALADIN", level = 110, },
	[287730]={ class = "PALADIN", level = 110, },
	[286392]={ class = "PALADIN", level = 110, },
	[286393]={ class = "PALADIN", level = 110, },
	[273476]={ class = "PALADIN", level = 110, },
	[273481]={ class = "PALADIN", level = 110, },
	[273134]={ class = "PALADIN", level = 110, },
	[280189]={ class = "PALADIN", level = 110, },
	[287268]={ class = "PALADIN", level = 110, },
	[287269]={ class = "PALADIN", level = 110, },
	[287280]={ class = "PALADIN", level = 110, },
	[278784]={ class = "PALADIN", level = 110, },
	[278785]={ class = "PALADIN", level = 110, },
	[273142]={ class = "PALADIN", level = 110, },
	[273130]={ class = "PALADIN", level = 110, },
	[279387]={ class = "PALADIN", level = 110, },
	[278573]={ class = "PALADIN", level = 110, },
	[286229]={ class = "PALADIN", level = 110, },
	[286231]={ class = "PALADIN", level = 110, },
	[273027]={ class = "PALADIN", level = 110, },
	[273032]={ class = "PALADIN", level = 110, },
	[273034]={ class = "PALADIN", level = 110, },
	[278138]={ class = "PALADIN", level = 110, },
	[278142]={ class = "PALADIN", level = 110, },
	[278145]={ class = "PALADIN", level = 110, },
	[278147]={ class = "PALADIN", level = 110, },
	[273131]={ class = "PALADIN", level = 110, },
	[279201]={ class = "PALADIN", level = 110, },
	[279204]={ class = "PALADIN", level = 110, },
	[269245]={ class = "PALADIN", level = 110, },
	[287126]={ class = "PALADIN", level = 110, },
	[273140]={ class = "PALADIN", level = 110, },
	[278951]={ class = "PALADIN", level = 110, },
	[274391]={ class = "PALADIN", level = 110, },
	[269262]={ class = "PALADIN", level = 110, },
	[270596]={ class = "PALADIN", level = 110, },
--++ Paladin Specializations ++	
	[229976]={ class = "PALADIN", level = 1, },
	[20271]={ class = "PALADIN", level = 3, },
	[275773]={ class = "PALADIN", level = 3, },
	[275779]={ class = "PALADIN", level = 3, },
	[19750]={ class = "PALADIN", level = 5, },
	[853]={ class = "PALADIN", level = 8, },
	[31935]={ class = "PALADIN", level = 10, },
	[53595]={ class = "PALADIN", level = 10, },
	[20473]={ class = "PALADIN", level = 10, },
	[289941]={ class = "PALADIN", level = 10, },
	[25780]={ class = "PALADIN", level = 10, },
	[105805]={ class = "PALADIN", level = 10, },
	[85256]={ class = "PALADIN", level = 10, },
	[224266]={ class = "PALADIN", level = 10, },
	[26573]={ class = "PALADIN", level = 14, },
	[53563]={ class = "PALADIN", level = 20, },
	[184575]={ class = "PALADIN", level = 20, },
	[53600]={ class = "PALADIN", level = 20, },
	[132403]={ class = "PALADIN", level = 20, },
	[4987]={ class = "PALADIN", level = 22, },
	[213644]={ class = "PALADIN", level = 22, },
	[183218]={ class = "PALADIN", level = 24, },
	[85043]={ class = "PALADIN", level = 25, },
	[82326]={ class = "PALADIN", level = 25, },
	[231667]={ class = "PALADIN", level = 26, },
	[267344]={ class = "PALADIN", level = 28, },
	[105424]={ class = "PALADIN", level = 28, },
	[498]={ class = "PALADIN", level = 32, },
	[184662]={ class = "PALADIN", level = 32, },
	[272906]={ class = "PALADIN", level = 34, },
	[53576]={ class = "PALADIN", level = 35, },
	[96231]={ class = "PALADIN", level = 35, },
	[53385]={ class = "PALADIN", level = 40, },
	[224239]={ class = "PALADIN", level = 32, },
	[85222]={ class = "PALADIN", level = 40, },
	[184092]={ class = "PALADIN", level = 40, },
	[231665]={ class = "PALADIN", level = 42, },
	[231644]={ class = "PALADIN", level = 42, },
	[231657]={ class = "PALADIN", level = 42, },
	[231663]={ class = "PALADIN", level = 42, },
	[1022]={ class = "PALADIN", level = 48, },
	[31850]={ class = "PALADIN", level = 50, },
	[183998]={ class = "PALADIN", level = 50, },
	[231642]={ class = "PALADIN", level = 52, },
	[6940]={ class = "PALADIN", level = 56, },
	[203538]={ class = "PALADIN", level = 58, },
	[203539]={ class = "PALADIN", level = 65, },
	[161800]={ class = "PALADIN", level = 65, },
	[212056]={ class = "PALADIN", level = 66, },
	[31821]={ class = "PALADIN", level = 70, },
	[86659]={ class = "PALADIN", level = 70, },
	[183435]={ class = "PALADIN", level = 70, },
	[76671]={ class = "PALADIN", level = 78, },
	[267316]={ class = "PALADIN", level = 78, },
	[183997]={ class = "PALADIN", level = 78, },
	[31884]={ class = "PALADIN", level = 80, },
	[200327]={ class = "PALADIN", level = 85, },
--++ Paladin Talents ++	
	[223306]={ class = "PALADIN", level = 15, },
	[204019]={ class = "PALADIN", level = 15, },
	[196926]={ class = "PALADIN", level = 15, },
	[267798]={ class = "PALADIN", level = 15, },
	[152261]={ class = "PALADIN", level = 15, },
	[114158]={ class = "PALADIN", level = 15, },
	[280373]={ class = "PALADIN", level = 15, },
	[280375]={ class = "PALADIN", level = 15, },
	[267610]={ class = "PALADIN", level = 15, },
	[267611]={ class = "PALADIN", level = 15, },
	[269569]={ class = "PALADIN", level = 15, },
	[269571]={ class = "PALADIN", level = 15, },
	[269937]={ class = "PALADIN", level = 15, },
	[204035]={ class = "PALADIN", level = 30, },
	[231832]={ class = "PALADIN", level = 30, },
	[281178]={ class = "PALADIN", level = 30, },
	[230332]={ class = "PALADIN", level = 30, },
	[204023]={ class = "PALADIN", level = 30, },
	[203316]={ class = "PALADIN", level = 30, },
	[203776]={ class = "PALADIN", level = 30, },
	[24275]={ class = "PALADIN", level = 30, },
	[214202]={ class = "PALADIN", level = 30, },
	[114154]={ class = "PALADIN", level = 30, },
	[115750]={ class = "PALADIN", level = 45, },
	[198054]={ class = "PALADIN", level = 45, },
	[234299]={ class = "PALADIN", level = 45, },
	[20066]={ class = "PALADIN", level = 45, },
	[183415]={ class = "PALADIN", level = 60, },
	[183416]={ class = "PALADIN", level = 60, },
	[204018]={ class = "PALADIN", level = 60, },
	[205228]={ class = "PALADIN", level = 60, },
	[183425]={ class = "PALADIN", level = 60, },
	[210320]={ class = "PALADIN", level = 60, },
	[271580]={ class = "PALADIN", level = 60, },
	[203797]={ class = "PALADIN", level = 60, },
	[255937]={ class = "PALADIN", level = 60, },
	[205191]={ class = "PALADIN", level = 75, },
	[204077]={ class = "PALADIN", level = 75, },
	[213652]={ class = "PALADIN", level = 75, },
	[105809]={ class = "PALADIN", level = 75, },
	[114165]={ class = "PALADIN", level = 75, },
	[183778]={ class = "PALADIN", level = 75, },
	[196941]={ class = "PALADIN", level = 75, },
	[204150]={ class = "PALADIN", level = 90, },
	[216331]={ class = "PALADIN", level = 90, },
	[248033]={ class = "PALADIN", level = 90, },
	[204054]={ class = "PALADIN", level = 90, },
	[215661]={ class = "PALADIN", level = 90, },
	[53376]={ class = "PALADIN", level = 90, },
	[85804]={ class = "PALADIN", level = 90, },
	[114250]={ class = "PALADIN", level = 90, },
	[210191]={ class = "PALADIN", level = 90, },
	[156910]={ class = "PALADIN", level = 100, },
	[200025]={ class = "PALADIN", level = 100, },
	[231895]={ class = "PALADIN", level = 100, },
	[197646]={ class = "PALADIN", level = 100, },
	[223817]={ class = "PALADIN", level = 100, },
	[84963]={ class = "PALADIN", level = 100, },
	[203791]={ class = "PALADIN", level = 100, },
	[204074]={ class = "PALADIN", level = 100, },
	[152262]={ class = "PALADIN", level = 100, },
--++ Paladin PvP Talents ++	
	[199441]={ class = "PALADIN", level = 40, },
	[199454]={ class = "PALADIN", level = 40, },
	[210256]={ class = "PALADIN", level = 40, },
	[199330]={ class = "PALADIN", level = 40, },
	[236186]={ class = "PALADIN", level = 40, },
	[210378]={ class = "PALADIN", level = 40, },
	[210294]={ class = "PALADIN", level = 40, },
	[204914]={ class = "PALADIN", level = 40, },
	[199324]={ class = "PALADIN", level = 40, },
	[216855]={ class = "PALADIN", level = 40, },
	[228049]={ class = "PALADIN", level = 40, },
	[216868]={ class = "PALADIN", level = 40, },
	[247675]={ class = "PALADIN", level = 40, },
	[207028]={ class = "PALADIN", level = 40, },
	[216860]={ class = "PALADIN", level = 40, },
	[204979]={ class = "PALADIN", level = 40, },
	[204934]={ class = "PALADIN", level = 40, },
	[246806]={ class = "PALADIN", level = 40, },
	[216327]={ class = "PALADIN", level = 40, },
	[199428]={ class = "PALADIN", level = 40, },
	[216853]={ class = "PALADIN", level = 40, },
	[215652]={ class = "PALADIN", level = 40, },
	[199456]={ class = "PALADIN", level = 40, },
	[199542]={ class = "PALADIN", level = 40, },
	[287947]={ class = "PALADIN", level = 40, },
	[199452]={ class = "PALADIN", level = 40, },
	[199325]={ class = "PALADIN", level = 40, },
	[210323]={ class = "PALADIN", level = 40, },
	[210341]={ class = "PALADIN", level = 40, },
--++ Priest Abilities ++	
	[585]={ class = "PRIEST", level = 1, },
	[81782]={ class = "PRIEST", level = 5, },
	[2006]={ class = "PRIEST", level = 14, },
	[21562]={ class = "PRIEST", level = 22, },
	[9484]={ class = "PRIEST", level = 34, },
	[605]={ class = "PRIEST", level = 42, },
	[586]={ class = "PRIEST", level = 44, },
	[528]={ class = "PRIEST", level = 56, },
	[32375]={ class = "PRIEST", level = 80, },
--++ Priest Artifact Traits ++	
	[208065]={ class = "PRIEST", level = 100, },
	[207946]={ class = "PRIEST", level = 100, },
	[205065]={ class = "PRIEST", level = 100, },
--++ Priest Azerite Traits ++	
	[269561]={ class = "PRIEST", level = 110, },
	[270649]={ class = "PRIEST", level = 110, },
	[273313]={ class = "PRIEST", level = 110, },
	[278661]={ class = "PRIEST", level = 110, },
	[279572]={ class = "PRIEST", level = 110, },
	[278629]={ class = "PRIEST", level = 110, },
	[278902]={ class = "PRIEST", level = 110, },
	[278904]={ class = "PRIEST", level = 110, },
	[287717]={ class = "PRIEST", level = 110, },
	[287719]={ class = "PRIEST", level = 110, },
	[287722]={ class = "PRIEST", level = 110, },
	[278659]={ class = "PRIEST", level = 110, },
	[275541]={ class = "PRIEST", level = 110, },
	[275542]={ class = "PRIEST", level = 110, },
	[275544]={ class = "PRIEST", level = 110, },
	[278643]={ class = "PRIEST", level = 110, },
	[279245]={ class = "PRIEST", level = 110, },
	[277681]={ class = "PRIEST", level = 110, },
	[272775]={ class = "PRIEST", level = 110, },
	[272780]={ class = "PRIEST", level = 110, },
	[272782]={ class = "PRIEST", level = 110, },
	[275602]={ class = "PRIEST", level = 110, },
	[287336]={ class = "PRIEST", level = 110, },
	[287337]={ class = "PRIEST", level = 110, },
	[287340]={ class = "PRIEST", level = 110, },
	[274366]={ class = "PRIEST", level = 110, },
	[274368]={ class = "PRIEST", level = 110, },
	[274369]={ class = "PRIEST", level = 110, },
	[272788]={ class = "PRIEST", level = 110, },
	[277682]={ class = "PRIEST", level = 110, },
	[287355]={ class = "PRIEST", level = 110, },
	[287356]={ class = "PRIEST", level = 110, },
	[287360]={ class = "PRIEST", level = 110, },
	[288340]={ class = "PRIEST", level = 110, },
	[288342]={ class = "PRIEST", level = 110, },
	[288343]={ class = "PRIEST", level = 110, },
	[269555]={ class = "PRIEST", level = 110, },
	[273307]={ class = "PRIEST", level = 110, },
	[273308]={ class = "PRIEST", level = 110, },
	[275722]={ class = "PRIEST", level = 110, },
	[275725]={ class = "PRIEST", level = 110, },
	[275726]={ class = "PRIEST", level = 110, },
	[278645]={ class = "PRIEST", level = 110, },
--++ Priest Specializations ++	
	[137032]={ class = "PRIEST", level = 1, },
	[589]={ class = "PRIEST", level = 3, },
	[2061]={ class = "PRIEST", level = 5, },
	[17]={ class = "PRIEST", level = 8, },
	[6788]={ class = "PRIEST", level = 8, },
	[14914]={ class = "PRIEST", level = 10, },
	[2050]={ class = "PRIEST", level = 10, },
	[8092]={ class = "PRIEST", level = 10, },
	[15407]={ class = "PRIEST", level = 10, },
	[47540]={ class = "PRIEST", level = 10, },
	[139]={ class = "PRIEST", level = 12, },
	[232698]={ class = "PRIEST", level = 12, },
	[2096]={ class = "PRIEST", level = 13, },
	[88625]={ class = "PRIEST", level = 16, },
	[200196]={ class = "PRIEST", level = 16, },
	[262861]={ class = "PRIEST", level = 16, },
	[8122]={ class = "PRIEST", level = 18, },
	[81749]={ class = "PRIEST", level = 20, },
	[63733]={ class = "PRIEST", level = 20, },
	[228266]={ class = "PRIEST", level = 20, },
	[205448]={ class = "PRIEST", level = 20, },
	[228260]={ class = "PRIEST", level = 20, },
	[185916]={ class = "PRIEST", level = 20, },
	[228264]={ class = "PRIEST", level = 20, },
	[527]={ class = "PRIEST", level = 22, },
	[213634]={ class = "PRIEST", level = 22, },
	[2060]={ class = "PRIEST", level = 24, },
	[34914]={ class = "PRIEST", level = 24, },
	[19236]={ class = "PRIEST", level = 26, },
	[48045]={ class = "PRIEST", level = 26, },
	[49821]={ class = "PRIEST", level = 26, },
	[47585]={ class = "PRIEST", level = 28, },
	[596]={ class = "PRIEST", level = 28, },
	[186263]={ class = "PRIEST", level = 28, },
	[190719]={ class = "PRIEST", level = 28, },
	[15286]={ class = "PRIEST", level = 28, },
	[1706]={ class = "PRIEST", level = 32, },
	[20711]={ class = "PRIEST", level = 32, },
	[132157]={ class = "PRIEST", level = 33, },
	[231687]={ class = "PRIEST", level = 36, },
	[231682]={ class = "PRIEST", level = 36, },
	[231688]={ class = "PRIEST", level = 36, },
	[45243]={ class = "PRIEST", level = 38, },
	[45242]={ class = "PRIEST", level = 38, },
	[78203]={ class = "PRIEST", level = 38, },
	[34861]={ class = "PRIEST", level = 40, },
	[34433]={ class = "PRIEST", level = 40, },
	[47788]={ class = "PRIEST", level = 44, },
	[33206]={ class = "PRIEST", level = 48, },
	[33076]={ class = "PRIEST", level = 50, },
	[47536]={ class = "PRIEST", level = 50, },
	[194509]={ class = "PRIEST", level = 52, },
	[15487]={ class = "PRIEST", level = 52, },
	[285485]={ class = "PRIEST", level = 58, },
	[280752]={ class = "PRIEST", level = 58, },
	[199579]={ class = "PRIEST", level = 58, },
	[198068]={ class = "PRIEST", level = 58, },
	[73325]={ class = "PRIEST", level = 63, },
	[212036]={ class = "PRIEST", level = 66, },
	[64843]={ class = "PRIEST", level = 70, },
	[62618]={ class = "PRIEST", level = 70, },
	[77485]={ class = "PRIEST", level = 78, },
	[271534]={ class = "PRIEST", level = 78, },
	[77486]={ class = "PRIEST", level = 78, },
	[64901]={ class = "PRIEST", level = 85, },
--++ Priest Talents ++	
	[193134]={ class = "PRIEST", level = 15, },
	[200153]={ class = "PRIEST", level = 15, },
	[193155]={ class = "PRIEST", level = 15, },
	[193195]={ class = "PRIEST", level = 15, },
	[214621]={ class = "PRIEST", level = 15, },
	[205351]={ class = "PRIEST", level = 15, },
	[162452]={ class = "PRIEST", level = 15, },
	[124430]={ class = "PRIEST", level = 15, },
	[200128]={ class = "PRIEST", level = 15, },
	[265259]={ class = "PRIEST", level = 15, },
	[238100]={ class = "PRIEST", level = 30, },
	[121536]={ class = "PRIEST", level = 30, },
	[64129]={ class = "PRIEST", level = 30, },
	[65081]={ class = "PRIEST", level = 30, },
	[288733]={ class = "PRIEST", level = 30, },
	[193063]={ class = "PRIEST", level = 30, },
	[235189]={ class = "PRIEST", level = 30, },
	[199855]={ class = "PRIEST", level = 30, },
	[196707]={ class = "PRIEST", level = 45, },
	[238136]={ class = "PRIEST", level = 45, },
	[263346]={ class = "PRIEST", level = 45, },
	[200209]={ class = "PRIEST", level = 45, },
	[123040]={ class = "PRIEST", level = 45, },
	[238558]={ class = "PRIEST", level = 45, },
	[129250]={ class = "PRIEST", level = 45, },
	[197045]={ class = "PRIEST", level = 45, },
	[109142]={ class = "PRIEST", level = 45, },
	[123254]={ class = "PRIEST", level = 45, },
	[200199]={ class = "PRIEST", level = 60, },
	[205367]={ class = "PRIEST", level = 60, },
	[263716]={ class = "PRIEST", level = 60, },
	[205369]={ class = "PRIEST", level = 60, },
	[64044]={ class = "PRIEST", level = 60, },
	[196704]={ class = "PRIEST", level = 60, },
	[204263]={ class = "PRIEST", level = 60, },
	[155271]={ class = "PRIEST", level = 75, },
	[32546]={ class = "PRIEST", level = 75, },
	[204883]={ class = "PRIEST", level = 75, },
	[197419]={ class = "PRIEST", level = 75, },
	[204065]={ class = "PRIEST", level = 75, },
	[205385]={ class = "PRIEST", level = 75, },
	[32379]={ class = "PRIEST", level = 75, },
	[280391]={ class = "PRIEST", level = 75, },
	[109186]={ class = "PRIEST", level = 75, },
	[193157]={ class = "PRIEST", level = 90, },
	[110744]={ class = "PRIEST", level = 90, },
	[120517]={ class = "PRIEST", level = 90, },
	[199849]={ class = "PRIEST", level = 90, },
	[200174]={ class = "PRIEST", level = 90, },
	[204197]={ class = "PRIEST", level = 90, },
	[263165]={ class = "PRIEST", level = 90, },
	[200183]={ class = "PRIEST", level = 100, },
	[280711]={ class = "PRIEST", level = 100, },
	[246287]={ class = "PRIEST", level = 100, },
	[265202]={ class = "PRIEST", level = 100, },
	[193225]={ class = "PRIEST", level = 100, },
	[238063]={ class = "PRIEST", level = 100, },
	[196985]={ class = "PRIEST", level = 100, },
	[271466]={ class = "PRIEST", level = 100, },
	[193223]={ class = "PRIEST", level = 100, },
--++ Priest PvP Talents ++	
	[197862]={ class = "PRIEST", level = 40, },
	[197871]={ class = "PRIEST", level = 40, },
	[196611]={ class = "PRIEST", level = 40, },
	[196602]={ class = "PRIEST", level = 40, },
	[197590]={ class = "PRIEST", level = 40, },
	[199259]={ class = "PRIEST", level = 40, },
	[199408]={ class = "PRIEST", level = 40, },
	[213602]={ class = "PRIEST", level = 40, },
	[289666]={ class = "PRIEST", level = 40, },
	[213610]={ class = "PRIEST", level = 40, },
	[289657]={ class = "PRIEST", level = 40, },
	[199445]={ class = "PRIEST", level = 40, },
	[235587]={ class = "PRIEST", level = 40, },
	[209780]={ class = "PRIEST", level = 40, },
	[305498]={ class = "PRIEST", level = 40, },
	[199484]={ class = "PRIEST", level = 40, },
	[211522]={ class = "PRIEST", level = 40, },
	[196162]={ class = "PRIEST", level = 40, },
	[196439]={ class = "PRIEST", level = 40, },
	[196559]={ class = "PRIEST", level = 40, },
	[197268]={ class = "PRIEST", level = 40, },
	[215768]={ class = "PRIEST", level = 40, },
	[280750]={ class = "PRIEST", level = 40, },
	[215982]={ class = "PRIEST", level = 40, },
	[197535]={ class = "PRIEST", level = 40, },
	[214205]={ class = "PRIEST", level = 40, },
	[236499]={ class = "PRIEST", level = 40, },
	[228630]={ class = "PRIEST", level = 40, },
	[280749]={ class = "PRIEST", level = 40, },
	[108968]={ class = "PRIEST", level = 40, },
--++ Rogue Abilities ++	
	[157442]={ class = "ROGUE", level = 1, },
	[82245]={ class = "ROGUE", level = 1, },
	[185311]={ class = "ROGUE", level = 16, },
	[1766]={ class = "ROGUE", level = 18, },
	[1804]={ class = "ROGUE", level = 24, },
	[2983]={ class = "ROGUE", level = 32, },
	[2836]={ class = "ROGUE", level = 42, },
	[1966]={ class = "ROGUE", level = 44, },
	[56814]={ class = "ROGUE", level = 50, },
	[210108]={ class = "ROGUE", level = 50, },
	[31209]={ class = "ROGUE", level = 58, },
	[1860]={ class = "ROGUE", level = 62, },
	[114018]={ class = "ROGUE", level = 68, },
	[57934]={ class = "ROGUE", level = 70, },
	[31224]={ class = "ROGUE", level = 80, },
--++ Rogue Artifact Traits ++	
	[202665]={ class = "ROGUE", level = 100, },
	[209782]={ class = "ROGUE", level = 100, },
	[192759]={ class = "ROGUE", level = 100, },
--++ Rogue Azerite Traits ++	
	[278676]={ class = "ROGUE", level = 110, },
	[279712]={ class = "ROGUE", level = 110, },
	[279752]={ class = "ROGUE", level = 110, },
	[279754]={ class = "ROGUE", level = 110, },
	[277723]={ class = "ROGUE", level = 110, },
	[269308]={ class = "ROGUE", level = 110, },
	[270627]={ class = "ROGUE", level = 110, },
	[272935]={ class = "ROGUE", level = 110, },
	[272936]={ class = "ROGUE", level = 110, },
	[272940]={ class = "ROGUE", level = 110, },
	[273007]={ class = "ROGUE", level = 110, },
	[287649]={ class = "ROGUE", level = 110, },
	[287650]={ class = "ROGUE", level = 110, },
	[287653]={ class = "ROGUE", level = 110, },
	[274694]={ class = "ROGUE", level = 110, },
	[278683]={ class = "ROGUE", level = 110, },
	[279720]={ class = "ROGUE", level = 110, },
	[288979]={ class = "ROGUE", level = 110, },
	[288985]={ class = "ROGUE", level = 110, },
	[288988]={ class = "ROGUE", level = 110, },
	[273419]={ class = "ROGUE", level = 110, },
	[273424]={ class = "ROGUE", level = 110, },
	[286573]={ class = "ROGUE", level = 110, },
	[286579]={ class = "ROGUE", level = 110, },
	[286581]={ class = "ROGUE", level = 110, },
	[289467]={ class = "ROGUE", level = 110, },
	[278675]={ class = "ROGUE", level = 110, },
	[277719]={ class = "ROGUE", level = 110, },
	[277720]={ class = "ROGUE", level = 110, },
	[286130]={ class = "ROGUE", level = 110, },
	[280199]={ class = "ROGUE", level = 110, },
	[278666]={ class = "ROGUE", level = 110, },
	[275858]={ class = "ROGUE", level = 110, },
	[275863]={ class = "ROGUE", level = 110, },
	[269297]={ class = "ROGUE", level = 110, },
	[278681]={ class = "ROGUE", level = 110, },
	[273488]={ class = "ROGUE", level = 110, },
--++ Rogue Specializations ++	
	[199736]={ class = "ROGUE", level = 1, },
	[1752]={ class = "ROGUE", level = 1, },
	[196819]={ class = "ROGUE", level = 3, },
	[1784]={ class = "ROGUE", level = 5, },
	[115191]={ class = "ROGUE", level = 5, },
	[1833]={ class = "ROGUE", level = 8, },
	[53]={ class = "ROGUE", level = 10, },
	[61329]={ class = "ROGUE", level = 10, },
	[2823]={ class = "ROGUE", level = 10, },
	[2818]={ class = "ROGUE", level = 10, },
	[113780]={ class = "ROGUE", level = 10, },
	[2098]={ class = "ROGUE", level = 10, },
	[79152]={ class = "ROGUE", level = 10, },
	[14117]={ class = "ROGUE", level = 10, },
	[185763]={ class = "ROGUE", level = 10, },
	[185565]={ class = "ROGUE", level = 10, },
	[114014]={ class = "ROGUE", level = 10, },
	[193315]={ class = "ROGUE", level = 10, },
	[703]={ class = "ROGUE", level = 12, },
	[185438]={ class = "ROGUE", level = 12, },
	[279876]={ class = "ROGUE", level = 12, },
	[921]={ class = "ROGUE", level = 13, },
	[279877]={ class = "ROGUE", level = 13, },
	[6770]={ class = "ROGUE", level = 14, },
	[199804]={ class = "ROGUE", level = 20, },
	[51667]={ class = "ROGUE", level = 20, },
	[195452]={ class = "ROGUE", level = 20, },
	[1943]={ class = "ROGUE", level = 20, },
	[8676]={ class = "ROGUE", level = 22, },
	[195457]={ class = "ROGUE", level = 22, },
	[36554]={ class = "ROGUE", level = 22, },
	[2094]={ class = "ROGUE", level = 24, },
	[5277]={ class = "ROGUE", level = 26, },
	[199754]={ class = "ROGUE", level = 26, },
	[14161]={ class = "ROGUE", level = 28, },
	[14190]={ class = "ROGUE", level = 28, },
	[14189]={ class = "ROGUE", level = 28, },
	[196912]={ class = "ROGUE", level = 28, },
	[1776]={ class = "ROGUE", level = 34, },
	[408]={ class = "ROGUE", level = 34, },
	[32645]={ class = "ROGUE", level = 36, },
	[212283]={ class = "ROGUE", level = 36, },
	[3408]={ class = "ROGUE", level = 38, },
	[1725]={ class = "ROGUE", level = 38, },
	[1329]={ class = "ROGUE", level = 40, },
	[27576]={ class = "ROGUE", level = 40, },
	[5374]={ class = "ROGUE", level = 40, },
	[193316]={ class = "ROGUE", level = 40, },
	[193358]={ class = "ROGUE", level = 40, },
	[185313]={ class = "ROGUE", level = 40, },
	[277950]={ class = "ROGUE", level = 40, },
	[235484]={ class = "ROGUE", level = 42, },
	[231719]={ class = "ROGUE", level = 42, },
	[231718]={ class = "ROGUE", level = 42, },
	[1856]={ class = "ROGUE", level = 48, },
	[35551]={ class = "ROGUE", level = 50, },
	[58423]={ class = "ROGUE", level = 50, },
	[79096]={ class = "ROGUE", level = 50, },
	[79134]={ class = "ROGUE", level = 50, },
	[51637]={ class = "ROGUE", level = 50, },
	[231716]={ class = "ROGUE", level = 52, },
	[185314]={ class = "ROGUE", level = 54, },
	[8679]={ class = "ROGUE", level = 54, },
	[8680]={ class = "ROGUE", level = 54, },
	[13750]={ class = "ROGUE", level = 56, },
	[121471]={ class = "ROGUE", level = 56, },
	[79140]={ class = "ROGUE", level = 56, },
	[245751]={ class = "ROGUE", level = 61, },
	[13877]={ class = "ROGUE", level = 63, },
	[51723]={ class = "ROGUE", level = 63, },
	[197835]={ class = "ROGUE", level = 63, },
	[231691]={ class = "ROGUE", level = 66, },
	[76808]={ class = "ROGUE", level = 78, },
	[76806]={ class = "ROGUE", level = 78, },
	[76803]={ class = "ROGUE", level = 78, },
--++ Rogue Talents ++	
	[111240]={ class = "ROGUE", level = 15, },
	[193640]={ class = "ROGUE", level = 15, },
	[91023]={ class = "ROGUE", level = 15, },
	[196937]={ class = "ROGUE", level = 15, },
	[200758]={ class = "ROGUE", level = 15, },
	[196864]={ class = "ROGUE", level = 15, },
	[196938]={ class = "ROGUE", level = 15, },
	[193537]={ class = "ROGUE", level = 15, },
	[200733]={ class = "ROGUE", level = 15, },
	[196924]={ class = "ROGUE", level = 30, },
	[196922]={ class = "ROGUE", level = 30, },
	[255989]={ class = "ROGUE", level = 30, },
	[14062]={ class = "ROGUE", level = 30, },
	[256188]={ class = "ROGUE", level = 30, },
	[108209]={ class = "ROGUE", level = 30, },
	[108208]={ class = "ROGUE", level = 30, },
	[193531]={ class = "ROGUE", level = 45, },
	[137619]={ class = "ROGUE", level = 45, },
	[14983]={ class = "ROGUE", level = 45, },
	[31230]={ class = "ROGUE", level = 60, },
	[79008]={ class = "ROGUE", level = 60, },
	[193546]={ class = "ROGUE", level = 60, },
	[280716]={ class = "ROGUE", level = 60, },
	[200759]={ class = "ROGUE", level = 60, },
	[256165]={ class = "ROGUE", level = 75, },
	[108216]={ class = "ROGUE", level = 75, },
	[154904]={ class = "ROGUE", level = 75, },
	[196861]={ class = "ROGUE", level = 75, },
	[277953]={ class = "ROGUE", level = 75, },
	[131511]={ class = "ROGUE", level = 75, },
	[257505]={ class = "ROGUE", level = 75, },
	[193539]={ class = "ROGUE", level = 90, },
	[245687]={ class = "ROGUE", level = 90, },
	[238104]={ class = "ROGUE", level = 90, },
	[200806]={ class = "ROGUE", level = 90, },
	[256170]={ class = "ROGUE", level = 90, },
	[5171]={ class = "ROGUE", level = 90, },
	[245388]={ class = "ROGUE", level = 90, },
	[152152]={ class = "ROGUE", level = 90, },
	[271877]={ class = "ROGUE", level = 100, },
	[121411]={ class = "ROGUE", level = 100, },
	[272026]={ class = "ROGUE", level = 100, },
	[270061]={ class = "ROGUE", level = 100, },
	[51690]={ class = "ROGUE", level = 100, },
	[196976]={ class = "ROGUE", level = 100, },
	[255544]={ class = "ROGUE", level = 100, },
	[280719]={ class = "ROGUE", level = 100, },
	[277925]={ class = "ROGUE", level = 100, },
--++ Rogue PvP Talents ++	
	[209752]={ class = "ROGUE", level = 40, },
	[212035]={ class = "ROGUE", level = 40, },
	[213981]={ class = "ROGUE", level = 40, },
	[212217]={ class = "ROGUE", level = 40, },
	[198092]={ class = "ROGUE", level = 40, },
	[198675]={ class = "ROGUE", level = 40, },
	[269513]={ class = "ROGUE", level = 40, },
	[207777]={ class = "ROGUE", level = 40, },
	[212210]={ class = "ROGUE", level = 40, },
	[198128]={ class = "ROGUE", level = 40, },
	[198032]={ class = "ROGUE", level = 40, },
	[197007]={ class = "ROGUE", level = 40, },
	[197000]={ class = "ROGUE", level = 40, },
	[197050]={ class = "ROGUE", level = 40, },
	[206328]={ class = "ROGUE", level = 40, },
	[198529]={ class = "ROGUE", level = 40, },
	[207736]={ class = "ROGUE", level = 40, },
	[248744]={ class = "ROGUE", level = 40, },
	[197899]={ class = "ROGUE", level = 40, },
	[212182]={ class = "ROGUE", level = 40, },
	[198145]={ class = "ROGUE", level = 40, },
	[198265]={ class = "ROGUE", level = 40, },
	[221622]={ class = "ROGUE", level = 40, },
	[212081]={ class = "ROGUE", level = 40, },
	[198020]={ class = "ROGUE", level = 40, },
	[198952]={ class = "ROGUE", level = 40, },
--++ Shaman Abilities ++	
	[2484]={ class = "SHAMAN", level = 8, },
	[6196]={ class = "SHAMAN", level = 13, },
	[2008]={ class = "SHAMAN", level = 14, },
	[2645]={ class = "SHAMAN", level = 16, },
	[20608]={ class = "SHAMAN", level = 26, },
	[546]={ class = "SHAMAN", level = 32, },
	[51514]={ class = "SHAMAN", level = 42, },
	[210873]={ class = "SHAMAN", level = 42, },
	[211004]={ class = "SHAMAN", level = 42, },
	[211010]={ class = "SHAMAN", level = 42, },
	[211015]={ class = "SHAMAN", level = 42, },
	[269352]={ class = "SHAMAN", level = 42, },
	[277778]={ class = "SHAMAN", level = 42, },
	[277784]={ class = "SHAMAN", level = 42, },
	[556]={ class = "SHAMAN", level = 44, },
	[192058]={ class = "SHAMAN", level = 44, },
	[2825]={ class = "SHAMAN", level = 50, },
	[32182]={ class = "SHAMAN", level = 50, },
	[108271]={ class = "SHAMAN", level = 52, },
	[8143]={ class = "SHAMAN", level = 58, },
	[370]={ class = "SHAMAN", level = 63, },
--++ Shaman Artifact Traits ++	
	[204945]={ class = "SHAMAN", level = 100, },
	[278082]={ class = "SHAMAN", level = 100, },
	[205495]={ class = "SHAMAN", level = 100, },
--++ Shaman Azerite Traits ++	
	[263790]={ class = "SHAMAN", level = 110, },
	[277926]={ class = "SHAMAN", level = 110, },
	[287775]={ class = "SHAMAN", level = 110, },
	[287777]={ class = "SHAMAN", level = 110, },
	[287778]={ class = "SHAMAN", level = 110, },
	[263786]={ class = "SHAMAN", level = 110, },
	[275381]={ class = "SHAMAN", level = 110, },
	[264121]={ class = "SHAMAN", level = 110, },
	[264113]={ class = "SHAMAN", level = 110, },
	[269567]={ class = "SHAMAN", level = 110, },
	[279829]={ class = "SHAMAN", level = 110, },
	[279830]={ class = "SHAMAN", level = 110, },
	[273448]={ class = "SHAMAN", level = 110, },
	[273449]={ class = "SHAMAN", level = 110, },
	[273453]={ class = "SHAMAN", level = 110, },
	[275388]={ class = "SHAMAN", level = 110, },
	[275389]={ class = "SHAMAN", level = 110, },
	[275391]={ class = "SHAMAN", level = 110, },
	[275393]={ class = "SHAMAN", level = 110, },
	[263792]={ class = "SHAMAN", level = 110, },
	[278697]={ class = "SHAMAN", level = 110, },
	[277658]={ class = "SHAMAN", level = 110, },
	[278077]={ class = "SHAMAN", level = 110, },
	[278095]={ class = "SHAMAN", level = 110, },
	[280203]={ class = "SHAMAN", level = 110, },
	[280205]={ class = "SHAMAN", level = 110, },
	[272992]={ class = "SHAMAN", level = 110, },
	[273005]={ class = "SHAMAN", level = 110, },
	[273006]={ class = "SHAMAN", level = 110, },
	[278719]={ class = "SHAMAN", level = 110, },
	[274416]={ class = "SHAMAN", level = 110, },
	[274823]={ class = "SHAMAN", level = 110, },
	[278715]={ class = "SHAMAN", level = 110, },
	[279504]={ class = "SHAMAN", level = 110, },
	[263795]={ class = "SHAMAN", level = 110, },
	[273461]={ class = "SHAMAN", level = 110, },
	[273463]={ class = "SHAMAN", level = 110, },
	[273465]={ class = "SHAMAN", level = 110, },
	[269570]={ class = "SHAMAN", level = 110, },
	[278713]={ class = "SHAMAN", level = 110, },
	[279181]={ class = "SHAMAN", level = 110, },
	[277958]={ class = "SHAMAN", level = 110, },
	[286949]={ class = "SHAMAN", level = 110, },
	[287768]={ class = "SHAMAN", level = 110, },
	[287801]={ class = "SHAMAN", level = 110, },
	[287802]={ class = "SHAMAN", level = 110, },
	[287300]={ class = "SHAMAN", level = 110, },
	[287302]={ class = "SHAMAN", level = 110, },
	[272978]={ class = "SHAMAN", level = 110, },
	[272980]={ class = "SHAMAN", level = 110, },
	[272981]={ class = "SHAMAN", level = 110, },
--++ Shaman Specializations ++	
	[190493]={ class = "SHAMAN", level = 1, },
	[403]={ class = "SHAMAN", level = 1, },
	[187837]={ class = "SHAMAN", level = 1, },
	[188196]={ class = "SHAMAN", level = 1, },
	[188389]={ class = "SHAMAN", level = 3, },
	[188838]={ class = "SHAMAN", level = 3, },
	[190488]={ class = "SHAMAN", level = 3, },
	[8004]={ class = "SHAMAN", level = 5, },
	[188070]={ class = "SHAMAN", level = 5, },
	[157444]={ class = "SHAMAN", level = 10, },
	[8042]={ class = "SHAMAN", level = 10, },
	[60103]={ class = "SHAMAN", level = 10, },
	[187828]={ class = "SHAMAN", level = 10, },
	[61295]={ class = "SHAMAN", level = 10, },
	[193786]={ class = "SHAMAN", level = 10, },
	[193796]={ class = "SHAMAN", level = 12, },
	[51505]={ class = "SHAMAN", level = 12, },
	[5394]={ class = "SHAMAN", level = 14, },
	[57994]={ class = "SHAMAN", level = 18, },
	[1064]={ class = "SHAMAN", level = 20, },
	[231721]={ class = "SHAMAN", level = 20, },
	[17364]={ class = "SHAMAN", level = 20, },
	[51886]={ class = "SHAMAN", level = 22, },
	[77130]={ class = "SHAMAN", level = 22, },
	[77472]={ class = "SHAMAN", level = 24, },
	[51490]={ class = "SHAMAN", level = 24, },
	[33757]={ class = "SHAMAN", level = 24, },
	[205648]={ class = "SHAMAN", level = 24, },
	[421]={ class = "SHAMAN", level = 28, },
	[188443]={ class = "SHAMAN", level = 28, },
	[187874]={ class = "SHAMAN", level = 28, },
	[168534]={ class = "SHAMAN", level = 29, },
	[60188]={ class = "SHAMAN", level = 34, },
	[51533]={ class = "SHAMAN", level = 34, },
	[51564]={ class = "SHAMAN", level = 34, },
	[198103]={ class = "SHAMAN", level = 36, },
	[196840]={ class = "SHAMAN", level = 38, },
	[196834]={ class = "SHAMAN", level = 38, },
	[231725]={ class = "SHAMAN", level = 38, },
	[79206]={ class = "SHAMAN", level = 38, },
	[73920]={ class = "SHAMAN", level = 40, },
	[77756]={ class = "SHAMAN", level = 40, },
	[187880]={ class = "SHAMAN", level = 40, },
	[61882]={ class = "SHAMAN", level = 48, },
	[16196]={ class = "SHAMAN", level = 48, },
	[201845]={ class = "SHAMAN", level = 48, },
	[231780]={ class = "SHAMAN", level = 54, },
	[231723]={ class = "SHAMAN", level = 56, },
	[198067]={ class = "SHAMAN", level = 56, },
	[98008]={ class = "SHAMAN", level = 56, },
	[212048]={ class = "SHAMAN", level = 66, },
	[231722]={ class = "SHAMAN", level = 70, },
	[231785]={ class = "SHAMAN", level = 70, },
	[77226]={ class = "SHAMAN", level = 78, },
	[280609]={ class = "SHAMAN", level = 78, },
	[77223]={ class = "SHAMAN", level = 78, },
	[108280]={ class = "SHAMAN", level = 80, },
	[58875]={ class = "SHAMAN", level = 80, },
--++ Shaman Talents ++	
	[246035]={ class = "SHAMAN", level = 15, },
	[170374]={ class = "SHAMAN", level = 15, },
	[117014]={ class = "SHAMAN", level = 15, },
	[201900]={ class = "SHAMAN", level = 15, },
	[192106]={ class = "SHAMAN", level = 15, },
	[200072]={ class = "SHAMAN", level = 15, },
	[200071]={ class = "SHAMAN", level = 15, },
	[273221]={ class = "SHAMAN", level = 30, },
	[260897]={ class = "SHAMAN", level = 30, },
	[200076]={ class = "SHAMAN", level = 30, },
	[108283]={ class = "SHAMAN", level = 30, },
	[262647]={ class = "SHAMAN", level = 30, },
	[197992]={ class = "SHAMAN", level = 30, },
	[210643]={ class = "SHAMAN", level = 30, },
	[262395]={ class = "SHAMAN", level = 30, },
	[210657]={ class = "SHAMAN", level = 30, },
	[210660]={ class = "SHAMAN", level = 30, },
	[202188]={ class = "SHAMAN", level = 30, },
	[210651]={ class = "SHAMAN", level = 30, },
	[974]={ class = "SHAMAN", level = 45, },
	[51485]={ class = "SHAMAN", level = 45, },
	[260878]={ class = "SHAMAN", level = 45, },
	[260881]={ class = "SHAMAN", level = 45, },
	[265046]={ class = "SHAMAN", level = 45, },
	[207399]={ class = "SHAMAN", level = 60, },
	[207401]={ class = "SHAMAN", level = 60, },
	[198838]={ class = "SHAMAN", level = 60, },
	[210853]={ class = "SHAMAN", level = 60, },
	[192222]={ class = "SHAMAN", level = 60, },
	[16166]={ class = "SHAMAN", level = 60, },
	[210727]={ class = "SHAMAN", level = 60, },
	[192087]={ class = "SHAMAN", level = 60, },
	[192249]={ class = "SHAMAN", level = 60, },
	[108281]={ class = "SHAMAN", level = 75, },
	[196884]={ class = "SHAMAN", level = 75, },
	[192088]={ class = "SHAMAN", level = 75, },
	[30884]={ class = "SHAMAN", level = 75, },
	[192077]={ class = "SHAMAN", level = 75, },
	[157153]={ class = "SHAMAN", level = 90, },
	[192246]={ class = "SHAMAN", level = 90, },
	[207778]={ class = "SHAMAN", level = 90, },
	[280614]={ class = "SHAMAN", level = 90, },
	[197211]={ class = "SHAMAN", level = 90, },
	[210714]={ class = "SHAMAN", level = 90, },
	[117013]={ class = "SHAMAN", level = 90, },
	[197214]={ class = "SHAMAN", level = 90, },
	[262303]={ class = "SHAMAN", level = 90, },
	[114050]={ class = "SHAMAN", level = 100, },
	[114051]={ class = "SHAMAN", level = 100, },
	[114052]={ class = "SHAMAN", level = 100, },
	[188089]={ class = "SHAMAN", level = 100, },
	[262624]={ class = "SHAMAN", level = 100, },
	[157154]={ class = "SHAMAN", level = 100, },
	[191634]={ class = "SHAMAN", level = 100, },
	[260895]={ class = "SHAMAN", level = 100, },
	[197995]={ class = "SHAMAN", level = 100, },
--++ Shaman PvP Talents ++	
	[290254]={ class = "SHAMAN", level = 40, },
	[290250]={ class = "SHAMAN", level = 40, },
	[204393]={ class = "SHAMAN", level = 40, },
	[204331]={ class = "SHAMAN", level = 40, },
	[204398]={ class = "SHAMAN", level = 40, },
	[206642]={ class = "SHAMAN", level = 40, },
	[204385]={ class = "SHAMAN", level = 40, },
	[210918]={ class = "SHAMAN", level = 40, },
	[204336]={ class = "SHAMAN", level = 40, },
	[204437]={ class = "SHAMAN", level = 40, },
	[305483]={ class = "SHAMAN", level = 40, },
	[204247]={ class = "SHAMAN", level = 40, },
	[289874]={ class = "SHAMAN", level = 40, },
	[193876]={ class = "SHAMAN", level = 40, },
	[204330]={ class = "SHAMAN", level = 40, },
	[204261]={ class = "SHAMAN", level = 40, },
	[204293]={ class = "SHAMAN", level = 40, },
	[204264]={ class = "SHAMAN", level = 40, },
	[204366]={ class = "SHAMAN", level = 40, },
	[236501]={ class = "SHAMAN", level = 40, },
	[204403]={ class = "SHAMAN", level = 40, },
	[204268]={ class = "SHAMAN", level = 40, },
--++ Warlock Abilities ++	
	[115746]={ class = "WARLOCK", level = 1, },
	[688]={ class = "WARLOCK", level = 5, },
	[93375]={ class = "WARLOCK", level = 10, },
	[117198]={ class = "WARLOCK", level = 10, },
	[246985]={ class = "WARLOCK", level = 10, },
	[5782]={ class = "WARLOCK", level = 16, },
	[118699]={ class = "WARLOCK", level = 16, },
	[6201]={ class = "WARLOCK", level = 18, },
	[5784]={ class = "WARLOCK", level = 20, },
	[697]={ class = "WARLOCK", level = 20, },
	[755]={ class = "WARLOCK", level = 22, },
	[126]={ class = "WARLOCK", level = 24, },
	[5697]={ class = "WARLOCK", level = 24, },
	[712]={ class = "WARLOCK", level = 28, },
	[710]={ class = "WARLOCK", level = 32, },
	[108370]={ class = "WARLOCK", level = 34, },
	[108366]={ class = "WARLOCK", level = 34, },
	[691]={ class = "WARLOCK", level = 36, },
	[119898]={ class = "WARLOCK", level = 38, },
	[23161]={ class = "WARLOCK", level = 40, },
	[698]={ class = "WARLOCK", level = 42, },
	[20707]={ class = "WARLOCK", level = 44, },
	[104773]={ class = "WARLOCK", level = 54, },
	[1098]={ class = "WARLOCK", level = 56, },
	[288843]={ class = "WARLOCK", level = 63, },
	[29893]={ class = "WARLOCK", level = 66, },
	[111771]={ class = "WARLOCK", level = 80, },
--++ Warlock Artifact Traits ++	
	[196586]={ class = "WARLOCK", level = 100, },
	[216698]={ class = "WARLOCK", level = 100, },
	[211714]={ class = "WARLOCK", level = 100, },
--++ Warlock Azerite Traits ++	
	[279911]={ class = "WARLOCK", level = 110, },
	[279913]={ class = "WARLOCK", level = 110, },
	[275376]={ class = "WARLOCK", level = 110, },
	[287637]={ class = "WARLOCK", level = 110, },
	[287656]={ class = "WARLOCK", level = 110, },
	[287658]={ class = "WARLOCK", level = 110, },
	[278748]={ class = "WARLOCK", level = 110, },
	[279672]={ class = "WARLOCK", level = 110, },
	[279673]={ class = "WARLOCK", level = 110, },
	[277705]={ class = "WARLOCK", level = 110, },
	[277706]={ class = "WARLOCK", level = 110, },
	[278737]={ class = "WARLOCK", level = 110, },
	[280207]={ class = "WARLOCK", level = 110, },
	[278727]={ class = "WARLOCK", level = 110, },
	[279650]={ class = "WARLOCK", level = 110, },
	[273521]={ class = "WARLOCK", level = 110, },
	[273522]={ class = "WARLOCK", level = 110, },
	[273525]={ class = "WARLOCK", level = 110, },
	[274419]={ class = "WARLOCK", level = 110, },
	[269594]={ class = "WARLOCK", level = 110, },
	[270647]={ class = "WARLOCK", level = 110, },
	[289364]={ class = "WARLOCK", level = 110, },
	[278747]={ class = "WARLOCK", level = 110, },
	[272944]={ class = "WARLOCK", level = 110, },
	[278721]={ class = "WARLOCK", level = 110, },
	[279879]={ class = "WARLOCK", level = 110, },
	[287822]={ class = "WARLOCK", level = 110, },
	[273524]={ class = "WARLOCK", level = 110, },
	[273526]={ class = "WARLOCK", level = 110, },
	[272891]={ class = "WARLOCK", level = 110, },
	[272892]={ class = "WARLOCK", level = 110, },
	[272893]={ class = "WARLOCK", level = 110, },
--++ Warlock Specializations ++	
	[686]={ class = "WARLOCK", level = 1, },
	[232670]={ class = "WARLOCK", level = 1, },
	[172]={ class = "WARLOCK", level = 3, },
	[980]={ class = "WARLOCK", level = 10, },
	[17962]={ class = "WARLOCK", level = 10, },
	[105174]={ class = "WARLOCK", level = 10, },
	[348]={ class = "WARLOCK", level = 10, },
	[157736]={ class = "WARLOCK", level = 10, },
	[116858]={ class = "WARLOCK", level = 12, },
	[30146]={ class = "WARLOCK", level = 12, },
	[234153]={ class = "WARLOCK", level = 13, },
	[196406]={ class = "WARLOCK", level = 14, },
	[117828]={ class = "WARLOCK", level = 14, },
	[104316]={ class = "WARLOCK", level = 14, },
	[193332]={ class = "WARLOCK", level = 14, },
	[193331]={ class = "WARLOCK", level = 14, },
	[29722]={ class = "WARLOCK", level = 14, },
	[30108]={ class = "WARLOCK", level = 14, },
	[264178]={ class = "WARLOCK", level = 22, },
	[5740]={ class = "WARLOCK", level = 26, },
	[231791]={ class = "WARLOCK", level = 26, },
	[267102]={ class = "WARLOCK", level = 30, },
	[27243]={ class = "WARLOCK", level = 38, },
	[80240]={ class = "WARLOCK", level = 40, },
	[196277]={ class = "WARLOCK", level = 46, },
	[231792]={ class = "WARLOCK", level = 52, },
	[231793]={ class = "WARLOCK", level = 52, },
	[108415]={ class = "WARLOCK", level = 52, },
	[205180]={ class = "WARLOCK", level = 58, },
	[1122]={ class = "WARLOCK", level = 58, },
	[30283]={ class = "WARLOCK", level = 60, },
	[231811]={ class = "WARLOCK", level = 70, },
	[77220]={ class = "WARLOCK", level = 78, },
	[77219]={ class = "WARLOCK", level = 78, },
	[77215]={ class = "WARLOCK", level = 78, },
	[265187]={ class = "WARLOCK", level = 80, },
--++ Warlock Talents ++	
	[267211]={ class = "WARLOCK", level = 15, },
	[264106]={ class = "WARLOCK", level = 15, },
	[267171]={ class = "WARLOCK", level = 15, },
	[198590]={ class = "WARLOCK", level = 15, },
	[264078]={ class = "WARLOCK", level = 15, },
	[196412]={ class = "WARLOCK", level = 15, },
	[267115]={ class = "WARLOCK", level = 15, },
	[108558]={ class = "WARLOCK", level = 15, },
	[6353]={ class = "WARLOCK", level = 15, },
	[196103]={ class = "WARLOCK", level = 30, },
	[205145]={ class = "WARLOCK", level = 30, },
	[265412]={ class = "WARLOCK", level = 30, },
	[266134]={ class = "WARLOCK", level = 30, },
	[264130]={ class = "WARLOCK", level = 30, },
	[205148]={ class = "WARLOCK", level = 30, },
	[17877]={ class = "WARLOCK", level = 30, },
	[196102]={ class = "WARLOCK", level = 30, },
	[111400]={ class = "WARLOCK", level = 45, },
	[108416]={ class = "WARLOCK", level = 45, },
	[219272]={ class = "WARLOCK", level = 45, },
	[152108]={ class = "WARLOCK", level = 60, },
	[196408]={ class = "WARLOCK", level = 60, },
	[267170]={ class = "WARLOCK", level = 60, },
	[270545]={ class = "WARLOCK", level = 60, },
	[205179]={ class = "WARLOCK", level = 60, },
	[264057]={ class = "WARLOCK", level = 60, },
	[196226]={ class = "WARLOCK", level = 60, },
	[264119]={ class = "WARLOCK", level = 60, },
	[278350]={ class = "WARLOCK", level = 60, },
	[264874]={ class = "WARLOCK", level = 75, },
	[268358]={ class = "WARLOCK", level = 75, },
	[6789]={ class = "WARLOCK", level = 75, },
	[108503]={ class = "WARLOCK", level = 90, },
	[266086]={ class = "WARLOCK", level = 90, },
	[111898]={ class = "WARLOCK", level = 90, },
	[48181]={ class = "WARLOCK", level = 90, },
	[267216]={ class = "WARLOCK", level = 90, },
	[205184]={ class = "WARLOCK", level = 90, },
	[196447]={ class = "WARLOCK", level = 100, },
	[264000]={ class = "WARLOCK", level = 100, },
	[113858]={ class = "WARLOCK", level = 100, },
	[113860]={ class = "WARLOCK", level = 100, },
	[267215]={ class = "WARLOCK", level = 100, },
	[267217]={ class = "WARLOCK", level = 100, },
	[267214]={ class = "WARLOCK", level = 100, },
	[215941]={ class = "WARLOCK", level = 100, },
--++ Warlock PvP Talents ++	
	[200546]={ class = "WARLOCK", level = 40, },
	[212459]={ class = "WARLOCK", level = 40, },
	[212619]={ class = "WARLOCK", level = 40, },
	[201996]={ class = "WARLOCK", level = 40, },
	[221703]={ class = "WARLOCK", level = 40, },
	[212282]={ class = "WARLOCK", level = 40, },
	[199954]={ class = "WARLOCK", level = 40, },
	[234877]={ class = "WARLOCK", level = 40, },
	[199890]={ class = "WARLOCK", level = 40, },
	[199892]={ class = "WARLOCK", level = 40, },
	[285933]={ class = "WARLOCK", level = 40, },
	[213400]={ class = "WARLOCK", level = 40, },
	[305391]={ class = "WARLOCK", level = 40, },
	[233581]={ class = "WARLOCK", level = 40, },
	[221711]={ class = "WARLOCK", level = 40, },
	[200586]={ class = "WARLOCK", level = 40, },
	[233577]={ class = "WARLOCK", level = 40, },
	[248855]={ class = "WARLOCK", level = 40, },
	[212628]={ class = "WARLOCK", level = 40, },
	[212295]={ class = "WARLOCK", level = 40, },
	[212618]={ class = "WARLOCK", level = 40, },
	[212371]={ class = "WARLOCK", level = 40, },
	[212623]={ class = "WARLOCK", level = 40, },
	[212356]={ class = "WARLOCK", level = 40, },
--++ Warrior Abilities ++	
	[88163]={ class = "WARRIOR", level = 1, },
	[123829]={ class = "WARRIOR", level = 1, },
	[115767]={ class = "WARRIOR", level = 1, },
	[3127]={ class = "WARRIOR", level = 1, },
	[195707]={ class = "WARRIOR", level = 1, },
	[100]={ class = "WARRIOR", level = 3, },
	[355]={ class = "WARRIOR", level = 13, },
	[57755]={ class = "WARRIOR", level = 17, },
	[6552]={ class = "WARRIOR", level = 24, },
	[6544]={ class = "WARRIOR", level = 26, },
	[52174]={ class = "WARRIOR", level = 26, },
	[6673]={ class = "WARRIOR", level = 42, },
--++ Warrior Artifact Traits ++	
	[203524]={ class = "WARRIOR", level = 100, },
	[205545]={ class = "WARRIOR", level = 100, },
	[209577]={ class = "WARRIOR", level = 100, },
--++ Warrior Azerite Traits ++	
	[287377]={ class = "WARRIOR", level = 110, },
	[287378]={ class = "WARRIOR", level = 110, },
	[279172]={ class = "WARRIOR", level = 110, },
	[279193]={ class = "WARRIOR", level = 110, },
	[278122]={ class = "WARRIOR", level = 110, },
	[278124]={ class = "WARRIOR", level = 110, },
	[274570]={ class = "WARRIOR", level = 110, },
	[280211]={ class = "WARRIOR", level = 110, },
	[278760]={ class = "WARRIOR", level = 110, },
	[278991]={ class = "WARRIOR", level = 110, },
	[278999]={ class = "WARRIOR", level = 110, },
	[288080]={ class = "WARRIOR", level = 110, },
	[288084]={ class = "WARRIOR", level = 110, },
	[288085]={ class = "WARRIOR", level = 110, },
	[288087]={ class = "WARRIOR", level = 110, },
	[278824]={ class = "WARRIOR", level = 110, },
	[278826]={ class = "WARRIOR", level = 110, },
	[272824]={ class = "WARRIOR", level = 110, },
	[279006]={ class = "WARRIOR", level = 110, },
	[273409]={ class = "WARRIOR", level = 110, },
	[273412]={ class = "WARRIOR", level = 110, },
	[288091]={ class = "WARRIOR", level = 110, },
	[278130]={ class = "WARRIOR", level = 110, },
	[288642]={ class = "WARRIOR", level = 110, },
	[279141]={ class = "WARRIOR", level = 110, },
	[278752]={ class = "WARRIOR", level = 110, },
	[279202]={ class = "WARRIOR", level = 110, },
	[279203]={ class = "WARRIOR", level = 110, },
	[280209]={ class = "WARRIOR", level = 110, },
	[275632]={ class = "WARRIOR", level = 110, },
	[275670]={ class = "WARRIOR", level = 110, },
	[275672]={ class = "WARRIOR", level = 110, },
	[279632]={ class = "WARRIOR", level = 110, },
	[283810]={ class = "WARRIOR", level = 110, },
	[278495]={ class = "WARRIOR", level = 110, },
	[278757]={ class = "WARRIOR", level = 110, },
	[278840]={ class = "WARRIOR", level = 110, },
	[278841]={ class = "WARRIOR", level = 110, },
	[288452]={ class = "WARRIOR", level = 110, },
	[275529]={ class = "WARRIOR", level = 110, },
	[275531]={ class = "WARRIOR", level = 110, },
	[275532]={ class = "WARRIOR", level = 110, },
	[288056]={ class = "WARRIOR", level = 110, },
	[288060]={ class = "WARRIOR", level = 110, },
--++ Warrior Specializations ++	
	[279423]={ class = "WARRIOR", level = 1, },
	[1464]={ class = "WARRIOR", level = 1, },
	[71]={ class = "WARRIOR", level = 1, },
	[34428]={ class = "WARRIOR", level = 5, },
	[32216]={ class = "WARRIOR", level = 5, },
	[5308]={ class = "WARRIOR", level = 8, },
	[163201]={ class = "WARRIOR", level = 8, },
	[23881]={ class = "WARRIOR", level = 10, },
	[273428]={ class = "WARRIOR", level = 10, },
	[20243]={ class = "WARRIOR", level = 10, },
	[12294]={ class = "WARRIOR", level = 10, },
	[23922]={ class = "WARRIOR", level = 10, },
	[46917]={ class = "WARRIOR", level = 10, },
	[184367]={ class = "WARRIOR", level = 12, },
	[201363]={ class = "WARRIOR", level = 12, },
	[201364]={ class = "WARRIOR", level = 12, },
	[209694]={ class = "WARRIOR", level = 12, },
	[184361]={ class = "WARRIOR", level = 14, },
	[6343]={ class = "WARRIOR", level = 14, },
	[7384]={ class = "WARRIOR", level = 20, },
	[85288]={ class = "WARRIOR", level = 20, },
	[96103]={ class = "WARRIOR", level = 20, },
	[2565]={ class = "WARRIOR", level = 20, },
	[6572]={ class = "WARRIOR", level = 22, },
	[260708]={ class = "WARRIOR", level = 22, },
	[231827]={ class = "WARRIOR", level = 28, },
	[231830]={ class = "WARRIOR", level = 28, },
	[198304]={ class = "WARRIOR", level = 28, },
	[1715]={ class = "WARRIOR", level = 32, },
	[12975]={ class = "WARRIOR", level = 32, },
	[12323]={ class = "WARRIOR", level = 32, },
	[231834]={ class = "WARRIOR", level = 34, },
	[184783]={ class = "WARRIOR", level = 34, },
	[118038]={ class = "WARRIOR", level = 36, },
	[184364]={ class = "WARRIOR", level = 36, },
	[190456]={ class = "WARRIOR", level = 36, },
	[231847]={ class = "WARRIOR", level = 38, },
	[1680]={ class = "WARRIOR", level = 40, },
	[190411]={ class = "WARRIOR", level = 40, },
	[199667]={ class = "WARRIOR", level = 40, },
	[280715]={ class = "WARRIOR", level = 40, },
	[44949]={ class = "WARRIOR", level = 40, },
	[18499]={ class = "WARRIOR", level = 44, },
	[1160]={ class = "WARRIOR", level = 48, },
	[167105]={ class = "WARRIOR", level = 50, },
	[1719]={ class = "WARRIOR", level = 50, },
	[46968]={ class = "WARRIOR", level = 50, },
	[262304]={ class = "WARRIOR", level = 55, },
	[262115]={ class = "WARRIOR", level = 55, },
	[871]={ class = "WARRIOR", level = 55, },
	[12950]={ class = "WARRIOR", level = 55, },
	[227847]={ class = "WARRIOR", level = 65, },
	[50622]={ class = "WARRIOR", level = 65, },
	[5246]={ class = "WARRIOR", level = 70, },
	[23920]={ class = "WARRIOR", level = 70, },
	[76857]={ class = "WARRIOR", level = 78, },
	[262111]={ class = "WARRIOR", level = 78, },
	[76856]={ class = "WARRIOR", level = 78, },
	[97462]={ class = "WARRIOR", level = 80, },
--++ Warrior Talents ++	
	[202296]={ class = "WARRIOR", level = 15, },
	[280283]={ class = "WARRIOR", level = 15, },
	[215568]={ class = "WARRIOR", level = 15, },
	[202168]={ class = "WARRIOR", level = 15, },
	[202603]={ class = "WARRIOR", level = 15, },
	[275334]={ class = "WARRIOR", level = 15, },
	[260643]={ class = "WARRIOR", level = 15, },
	[29725]={ class = "WARRIOR", level = 15, },
	[262231]={ class = "WARRIOR", level = 15, },
	[202163]={ class = "WARRIOR", level = 30, },
	[202164]={ class = "WARRIOR", level = 30, },
	[203201]={ class = "WARRIOR", level = 30, },
	[103827]={ class = "WARRIOR", level = 30, },
	[223657]={ class = "WARRIOR", level = 30, },
	[107570]={ class = "WARRIOR", level = 30, },
	[202560]={ class = "WARRIOR", level = 45, },
	[202316]={ class = "WARRIOR", level = 45, },
	[100130]={ class = "WARRIOR", level = 45, },
	[215573]={ class = "WARRIOR", level = 45, },
	[281001]={ class = "WARRIOR", level = 45, },
	[772]={ class = "WARRIOR", level = 45, },
	[280721]={ class = "WARRIOR", level = 45, },
	[275336]={ class = "WARRIOR", level = 45, },
	[280001]={ class = "WARRIOR", level = 60, },
	[197690]={ class = "WARRIOR", level = 60, },
	[202224]={ class = "WARRIOR", level = 60, },
	[202095]={ class = "WARRIOR", level = 60, },
	[202561]={ class = "WARRIOR", level = 60, },
	[29838]={ class = "WARRIOR", level = 60, },
	[208154]={ class = "WARRIOR", level = 60, },
	[202922]={ class = "WARRIOR", level = 75, },
	[845]={ class = "WARRIOR", level = 75, },
	[268243]={ class = "WARRIOR", level = 75, },
	[215571]={ class = "WARRIOR", level = 75, },
	[206315]={ class = "WARRIOR", level = 75, },
	[275338]={ class = "WARRIOR", level = 75, },
	[275339]={ class = "WARRIOR", level = 75, },
	[262161]={ class = "WARRIOR", level = 75, },
	[107574]={ class = "WARRIOR", level = 90, },
	[46924]={ class = "WARRIOR", level = 90, },
	[202743]={ class = "WARRIOR", level = 90, },
	[262228]={ class = "WARRIOR", level = 90, },
	[236279]={ class = "WARRIOR", level = 90, },
	[118000]={ class = "WARRIOR", level = 90, },
	[248621]={ class = "WARRIOR", level = 90, },
	[280392]={ class = "WARRIOR", level = 90, },
	[202572]={ class = "WARRIOR", level = 90, },
	[152278]={ class = "WARRIOR", level = 100, },
	[262150]={ class = "WARRIOR", level = 100, },
	[203177]={ class = "WARRIOR", level = 100, },
	[152277]={ class = "WARRIOR", level = 100, },
	[228920]={ class = "WARRIOR", level = 100, },
	[202751]={ class = "WARRIOR", level = 100, },
	[280772]={ class = "WARRIOR", level = 100, },
--++ Warrior PvP Talents ++	
	[280745]={ class = "WARRIOR", level = 40, },
	[213857]={ class = "WARRIOR", level = 40, },
	[213871]={ class = "WARRIOR", level = 40, },
	[198500]={ class = "WARRIOR", level = 40, },
	[199261]={ class = "WARRIOR", level = 40, },
	[236077]={ class = "WARRIOR", level = 40, },
	[206572]={ class = "WARRIOR", level = 40, },
	[236273]={ class = "WARRIOR", level = 40, },
	[198877]={ class = "WARRIOR", level = 40, },
	[213915]={ class = "WARRIOR", level = 40, },
	[235941]={ class = "WARRIOR", level = 40, },
	[199023]={ class = "WARRIOR", level = 40, },
	[205800]={ class = "WARRIOR", level = 40, },
	[198807]={ class = "WARRIOR", level = 40, },
	[198817]={ class = "WARRIOR", level = 40, },
	[198912]={ class = "WARRIOR", level = 40, },
	[280747]={ class = "WARRIOR", level = 40, },
	[216890]={ class = "WARRIOR", level = 40, },
	[236308]={ class = "WARRIOR", level = 40, },
	[199127]={ class = "WARRIOR", level = 40, },
	[199202]={ class = "WARRIOR", level = 40, },
	[199045]={ class = "WARRIOR", level = 40, },
	[236320]={ class = "WARRIOR", level = 40, },
	[199086]={ class = "WARRIOR", level = 40, },
	
--++ Azerite Traits ++	
	[279926]={ level = 110, },
	[264108]={ level = 110, },
	[267665]={ level = 110, },
	[267879]={ level = 110, },
	[279899]={ level = 110, },
	[279902]={ level = 110, },
	[263987]={ level = 110, },
	[271685]={ level = 110, },
	[271686]={ level = 110, },
	[271540]={ level = 110, },
	[271536]={ level = 110, },
	[267671]={ level = 110, },
	[269214]={ level = 110, },
	[267683]={ level = 110, },
	[271546]={ level = 110, },
	[271557]={ level = 110, },
	[271559]={ level = 110, },
	[267892]={ level = 110, },
	[267886]={ level = 110, },
	[272572]={ level = 110, },
	[267889]={ level = 110, },
	[267884]={ level = 110, },
	[267882]={ level = 110, },
	[267883]={ level = 110, },
	[267880]={ level = 110, },
	[279955]={ level = 110, },
	[279956]={ level = 110, },
	[279958]={ level = 110, },
	[266937]={ level = 110, },
	[269031]={ level = 110, },
	[263984]={ level = 110, },
	[268953]={ level = 110, },
	[268956]={ level = 110, },
	[268955]={ level = 110, },
	[266180]={ level = 110, },
	[271711]={ level = 110, },
	[268599]={ level = 110, },
	[269238]={ level = 110, },
	[269239]={ level = 110, },
	[268596]={ level = 110, },
	[268437]={ level = 110, },
	[270117]={ level = 110, },
	[268594]={ level = 110, },
	[263962]={ level = 110, },
	[269279]={ level = 110, },
	[268600]={ level = 110, },
	[270661]={ level = 110, },
	[268435]={ level = 110, },
	[268595]={ level = 110, },
	[270657]={ level = 110, },
	[280555]={ level = 120, },
	[280709]={ level = 120, },
	[280559]={ level = 120, },
	[280407]={ level = 110, },
	[273834]={ level = 110, },
	[280410]={ level = 110, },
	[280412]={ level = 110, },
	[273790]={ level = 110, },
	[273794]={ level = 110, },
	[273823]={ level = 110, },
	[273150]={ level = 110, },
	[280429]={ level = 110, },
	[280383]={ level = 110, },
	[280402]={ level = 110, },
	[280403]={ level = 110, },
	[280404]={ level = 110, },
	[273829]={ level = 110, },
	[273682]={ level = 110, },
	[280284]={ level = 110, },
	[280286]={ level = 110, },
	[281841]={ level = 110, },
	[281843]={ level = 110, },
	[281514]={ level = 120, },
	[281515]={ level = 120, },
	[280713]={ level = 110, },
	[287604]={ level = 120, },
	[287471]={ level = 120, },
	[287631]={ level = 120, },
	[287662]={ level = 120, },
	[288839]={ level = 120, },
	[288841]={ level = 120, },
	[288802]={ level = 120, },
	[288804]={ level = 120, },
	[289190]={ level = 120, },
	[288777]={ level = 120, },
	[288784]={ level = 120, },
	[288989]={ level = 120, },
	[288981]={ level = 120, },
	[303007]={ level = 120, },
	[303008]={ level = 120, },
	[303006]={ level = 120, },
	[303211]={ level = 120, },
	[300168]={ level = 120, },
	[300170]={ level = 120, },
	[287700]={ level = 110, },
	[287821]={ level = 110, },
	[287827]={ level = 110, },
	[287825]={ level = 110, },
	[280628]={ level = 110, },
	[280627]={ level = 110, },
	[280855]={ level = 110, },
	[282720]={ level = 110, },
	[280626]={ level = 120, },
	[280851]={ level = 110, },
	[280624]={ level = 110, },
	[280625]={ level = 110, },
	[280598]={ level = 110, },
	[280582]={ level = 110, },
	[280581]={ level = 120, },
	[280577]={ level = 110, },
	[280579]={ level = 110, },
	[280848]={ level = 110, },
	[298168]={ level = 120, },
	[299273]={ level = 120, },
	[299275]={ level = 120, },
	[298193]={ level = 120, },
	[299274]={ level = 120, },
	[299277]={ level = 120, },
	[294926]={ level = 120, },
	[300002]={ level = 120, },
	[300003]={ level = 120, },
	[294964]={ level = 120, },
	[300004]={ level = 120, },
	[300005]={ level = 120, },
	[296094]={ level = 120, },
	[299882]={ level = 120, },
	[299883]={ level = 120, },
	[296081]={ level = 120, },
	[299885]={ level = 120, },
	[299887]={ level = 120, },
	[293019]={ level = 120, },
	[298080]={ level = 120, },
	[298081]={ level = 120, },
	[294668]={ level = 120, },
	[298082]={ level = 120, },
	[298083]={ level = 120, },
	[297108]={ level = 120, },
	[298273]={ level = 120, },
	[298277]={ level = 120, },
	[297147]={ level = 120, },
	[297162]={ level = 120, },
	[298274]={ level = 120, },
	[298275]={ level = 120, },
	[295840]={ level = 120, },
	[299355]={ level = 120, },
	[299358]={ level = 120, },
	[295834]={ level = 120, },
	[299354]={ level = 120, },
	[299357]={ level = 120, },
	[303823]={ level = 120, },
	[304088]={ level = 120, },
	[304121]={ level = 120, },
	[304081]={ level = 120, },
	[304089]={ level = 120, },
	[304123]={ level = 120, },
	[295258]={ level = 120, },
	[299336]={ level = 120, },
	[299338]={ level = 120, },
	[295246]={ level = 120, },
	[299335]={ level = 120, },
	[299337]={ level = 120, },
	[293032]={ level = 120, },
	[299943]={ level = 120, },
	[299944]={ level = 120, },
	[296207]={ level = 120, },
	[299939]={ level = 120, },
	[299940]={ level = 120, },
	[298357]={ level = 120, },
	[299372]={ level = 120, },
	[299374]={ level = 120, },
	[298268]={ level = 120, },
	[298318]={ level = 120, },
	[298321]={ level = 120, },
	[298328]={ level = 120, },
	[299371]={ level = 120, },
	[299373]={ level = 120, },
	[304632]={ level = 120, },
	[295746]={ level = 120, },
	[300015]={ level = 120, },
	[300016]={ level = 120, },
	[295750]={ level = 120, },
	[300018]={ level = 120, },
	[300020]={ level = 120, },
	[295337]={ level = 120, },
	[299345]={ level = 120, },
	[299347]={ level = 120, },
	[295293]={ level = 120, },
	[299343]={ level = 120, },
	[299346]={ level = 120, },
	[302731]={ level = 120, },
	[302982]={ level = 120, },
	[302983]={ level = 120, },
	[302916]={ level = 120, },
	[302952]={ level = 120, },
	[302984]={ level = 120, },
	[302985]={ level = 120, },
	[293031]={ level = 120, },
	[300009]={ level = 120, },
	[300010]={ level = 120, },
	[294910]={ level = 120, },
	[300012]={ level = 120, },
	[300013]={ level = 120, },
	[295373]={ level = 120, },
	[295374]={ level = 120, },
	[295378]={ level = 120, },
	[299349]={ level = 120, },
	[299353]={ level = 120, },
	[295365]={ level = 120, },
	[299348]={ level = 120, },
	[299350]={ level = 120, },
	[295367]={ level = 120, },
	[303380]={ level = 120, },
	[296072]={ level = 120, },
	[299875]={ level = 120, },
	[299876]={ level = 120, },
	[296050]={ level = 120, },
	[296059]={ level = 120, },
	[299878]={ level = 120, },
	[299879]={ level = 120, },
	[298452]={ level = 120, },
	[299376]={ level = 120, },
	[299378]={ level = 120, },
	[298407]={ level = 120, },
	[299375]={ level = 120, },
	[299377]={ level = 120, },
	[302917]={ level = 120, },
	[296197]={ level = 120, },
	[299932]={ level = 120, },
	[299933]={ level = 120, },
	[296136]={ level = 120, },
	[299935]={ level = 120, },
	[299936]={ level = 120, },
	[296325]={ level = 120, },
	[299368]={ level = 120, },
	[299370]={ level = 120, },
	[296320]={ level = 120, },
	[299367]={ level = 120, },
	[299369]={ level = 120, },
	[296230]={ level = 120, },
	[299958]={ level = 120, },
	[299959]={ level = 120, },
	[303448]={ level = 120, },
	[303474]={ level = 120, },
	[303476]={ level = 120, },
	[295186]={ level = 120, },
	[298628]={ level = 120, },
	[299334]={ level = 120, },
	[295078]={ level = 120, },
	[298627]={ level = 120, },
	[299333]={ level = 120, },
	
--++++++++++	
	[2580]={ level = 1, },
	[8388]={ level = 1, },
	[43308]={ level = 1, },
	[2383]={ level = 1, },
	[167898]={ level = 1, },
	[281215]={ level = 1, },
	[214027]={ level = 20, },
	[208683]={ level = 20, },
	[196029]={ level = 20, },
	[72968]={ level = 80, },
	[176151]={ level = 90, },
	[242551]={ level = 101, },
	[227723]={ level = 110, },
	[268534]={ level = 110, },
	[268536]={ level = 110, },
	[277179]={ level = 110, },
	[277181]={ level = 110, },
	[293142]={ level = 120, },
	[293664]={ level = 120, },
	[288304]={ level = 120, },
	[288305]={ level = 120, },
	[288024]={ level = 120, },
	[268194]={ level = 120, },
	[271103]={ level = 120, },
	[290244]={ level = 120, },
	[285470]={ level = 120, },
	[288756]={ level = 120, },
	[289523]={ level = 120, },
	[284275]={ level = 120, },
	[299661]={ level = 120, },
	[256460]={ level = 120, },
	[256451]={ level = 120, },
	[256434]={ level = 120, },
	[299664]={ level = 120, },
	[256452]={ level = 120, },
	[256455]={ level = 120, },
	[284277]={ level = 120, },
	[256459]={ level = 120, },
	[299662]={ level = 120, },
	[256456]={ level = 120, },
	[256453]={ level = 120, },
	[302021]={ level = 120, },
};