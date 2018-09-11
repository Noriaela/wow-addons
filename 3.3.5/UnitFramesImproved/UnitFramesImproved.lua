local UnitFramesImproved = CreateFrame('Button', 'UnitFramesImproved');

function UnitFramesImproved:VARIABLES_LOADED()
	EnableUnitFramesImproved();
end

function EnableUnitFramesImproved()
	hooksecurefunc("TargetFrame_CheckFaction", UnitFramesImproved_TargetFrame_CheckFaction);
	hooksecurefunc("TargetFrame_CheckClassification", UnitFramesImproved_TargetFrame_CheckClassification);
	hooksecurefunc("TextStatusBar_UpdateTextString", UnitFramesImproved_TextStatusBar_UpdateTextString);
	hooksecurefunc("PlayerFrame_ToPlayerArt", PlayerFrameImpoved_PlayerFrame_ToPlayerArt);
	hooksecurefunc("PlayerFrame_ToVehicleArt", UnitFramesImproved_PlayerFrame_ToVehicleArt);
	hooksecurefunc("TargetFrame_Update", UnitFramesImproved_TargetFrame_Update);
	
	PlayerFrameHealthBar.capNumericDisplay = true;
	
	PlayerFrameHealthBar:SetWidth(119);
	PlayerFrameHealthBar:SetHeight(29);
	PlayerFrameHealthBar:SetPoint("TOPLEFT",106,-22);
	PlayerFrameHealthBar.lockColor = true
	PlayerFrameHealthBarText:SetPoint("CENTER",50,6);
	PlayerFrameTexture:SetTexture("Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame.blp");
	PlayerStatusTexture:SetTexture("Interface\\Addons\\UnitFramesImproved\\UI-Player-Status.blp");
	PlayerFrameHealthBar:SetStatusBarColor(UnitColor("player"));
end

--function UnitFramesImprovedPanel_OnLoad(self)
--	panel.name = "UnitFramesImproved "..GetAddOnMetadata("UnitFramesImproved", "Version");
--	panel.okay = function(self) UnitFramesImprovedPanel_Close(); end;
--	panel.cancel = function(self) UnitFramesImprovedPanel_CancelOrLoad();  end;
--
--	InterfaceOptions_AddCategory(panel);
--end

function UnitFramesImproved_TextStatusBar_UpdateTextString(textStatusBar)
	local textString = textStatusBar.TextString;
	if(textString) then
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();

		if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( textStatusBar.pauseUpdates ) ) then
			textStatusBar:Show();
			if ( value and valueMax > 0 and ( GetCVarBool("statusTextPercentage") or textStatusBar.showPercentage ) and not textStatusBar.showNumeric) then
				if ( value == 0 and textStatusBar.zeroText ) then
					textString:SetText(textStatusBar.zeroText);
					textStatusBar.isZero = 1;
					textString:Show();
					return;
				end
				value = tostring(math.ceil((value / valueMax) * 100)) .. "%";
				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix .. " " .. value);
				else
					textString:SetText(value);
				end
			elseif ( value == 0 and textStatusBar.zeroText ) then
				textString:SetText(textStatusBar.zeroText);
				textStatusBar.isZero = 1;
				textString:Show();
				return;
			else
				textStatusBar.isZero = nil;
				if ( textStatusBar.capNumericDisplay ) then
					value = UnitFramesImproved_CapDisplayOfNumericValue(value);
					valueMax = UnitFramesImproved_CapDisplayOfNumericValue(valueMax);
				end
				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix.." "..value.."/"..valueMax);
				else
					textString:SetText(value.."/"..valueMax);
				end
			end
			
			if ( (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) or textStatusBar.forceShow ) then
				textString:Show();
			elseif ( textStatusBar.lockShow > 0 and (not textStatusBar.forceHideText) ) then
				textString:Show();
			else
				textString:Hide();
			end
		else
			textString:Hide();
			textString:SetText("");
			if ( not textStatusBar.alwaysShow ) then
				textStatusBar:Hide();
			else
				textStatusBar:SetValue(0);
			end
		end
	end
end

function PlayerFrameImpoved_PlayerFrame_ToPlayerArt(self)
	PlayerFrameHealthBar:SetWidth(119);
	PlayerFrameHealthBar:SetHeight(29);
	PlayerFrameHealthBar:SetPoint("TOPLEFT",106,-22);
	PlayerFrameHealthBarText:SetPoint("CENTER",50,6);
	PlayerFrameTexture:SetTexture("Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame.blp");
	PlayerStatusTexture:SetTexture("Interface\\Addons\\UnitFramesImproved\\UI-Player-Status.blp");
	PlayerFrameHealthBar:SetStatusBarColor(UnitColor("player"));
end

function UnitFramesImproved_PlayerFrame_ToVehicleArt(self)
	PlayerFrameHealthBar:SetHeight(12);
	PlayerFrameHealthBarText:SetPoint("CENTER",50,3);
end

function UnitFramesImproved_TargetFrame_Update(self)
	local thisName = self:GetName();
	self.healthbar.lockColor = true
	self.healthbar:SetWidth(119);
	self.healthbar:SetHeight(29);
	self.healthbar:SetPoint("TOPLEFT",7,-22);
	self.healthbar:SetStatusBarColor(UnitColor(self.healthbar.unit));
	_G[thisName.."TextureFrameHealthBarText"]:SetPoint("CENTER",-50,6);
	self.deadText:SetPoint("CENTER",-50,6);
	self.nameBackground:Hide();
end

function UnitFramesImproved_CapDisplayOfNumericValue(value)
	local strLen = strlen(value);
	local retString = value;
	if (true) then
		if ( strLen >= 10 ) then
			retString = string.sub(value, 1, -10).."."..string.sub(value, -9, -9).."G";
		elseif ( strLen >= 7 ) then
			retString = string.sub(value, 1, -7).."."..string.sub(value, -6, -6).."M";
		elseif ( strLen >= 4 ) then
			retString = string.sub(value, 1, -4).."."..string.sub(value, -3, -3).."k";
		end
	else
		if ( strLen >= 10 ) then
			retString = string.sub(value, 1, -10).."G";
		elseif ( strLen >= 7 ) then
			retString = string.sub(value, 1, -7).."M";
		elseif ( strLen >= 4 ) then
			retString = string.sub(value, 1, -4).."k";
		end
	end
	return retString;
end

function UnitFramesImproved_TargetFrame_CheckClassification(self, forceNormalTexture)
	local texture;
	local classification = UnitClassification(self.unit);
	if ( classification == "worldboss" or classification == "elite" ) then
		texture = "Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame-Elite";
	elseif ( classification == "rareelite" ) then
		texture = "Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame-Rare-Elite";
	elseif ( classification == "rare" ) then
		texture = "Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame-Rare";
	end
	if ( texture and not forceNormalTexture) then
		self.borderTexture:SetTexture(texture);
		self.haveElite = true;
		if ( self.threatIndicator ) then
			self.threatIndicator:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
			self.threatIndicator:SetWidth(242);
			self.threatIndicator:SetHeight(112);
			self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -22, 9);
		end		
	else
		self.borderTexture:SetTexture("Interface\\Addons\\UnitFramesImproved\\UI-TargetingFrame");
		self.haveElite = nil;
		if ( self.threatIndicator ) then
			self.threatIndicator:SetTexCoord(0, 0.9453125, 0, 0.181640625);
			self.threatIndicator:SetWidth(242);
			self.threatIndicator:SetHeight(93);
			self.threatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", -24, 0);
		end	
	end
end

function UnitFramesImproved_TargetFrame_CheckFaction(self)
	local factionGroup = UnitFactionGroup(self.unit);
	if ( UnitIsPVPFreeForAll(self.unit) ) then
		self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		self.pvpIcon:Show();
	elseif ( factionGroup and UnitIsPVP(self.unit) and UnitIsEnemy("player", self.unit) ) then
		self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		self.pvpIcon:Show();
	elseif ( factionGroup ) then
		self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		self.pvpIcon:Show();
	else
		self.pvpIcon:Hide();
	end
end

function UnitColor(unit)
	local r, g, b;
	if ( ( not UnitIsConnected(unit) ) or ( UnitIsDeadOrGhost(unit) ) ) then
		--Color it gray
		r, g, b = 0.5, 0.5, 0.5;
	elseif ( UnitIsPlayer(unit) ) then
		--Try to color it by class.
		local localizedClass, englishClass = UnitClass(unit);
		local classColor = RAID_CLASS_COLORS[englishClass];
		if ( classColor ) then
			r, g, b = classColor.r, classColor.g, classColor.b;
		else
			if ( UnitIsFriend("player", unit) ) then
				r, g, b = 0.0, 1.0, 0.0;
			else
				r, g, b = 1.0, 0.0, 0.0;
			end
		end
	else
		r, g, b = UnitSelectionColor(unit);
	end
	
	return r, g, b;
end

function UnitFramesImproved_StartUp(self)
	self:SetScript('OnEvent', function(self, event) self[event](self) end);
	self:RegisterEvent('VARIABLES_LOADED');
end

UnitFramesImproved_StartUp(UnitFramesImproved);
