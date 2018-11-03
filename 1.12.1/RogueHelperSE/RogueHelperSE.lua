--[[
	RogueHelperSE
	-------------

	by kathar

	based on RogueHelper by sarf

	This WoW mod gives the user a little window that shows energy and combo points when playing a rogue.
   ]]




function RogueHelper_OnLoad()
	-- events
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	-- slashcommands
	SlashCmdList["ROGUEHELPERSLASHENABLE"] = RogueHelper_Main_ChatCommandHandler;
	SLASH_ROGUEHELPERSLASHENABLE1 = "/roguehelperse";
	SLASH_ROGUEHELPERSLASHENABLE2 = "/rhse";
	-- startmessage
	if( DEFAULT_CHAT_FRAME ) then
		RogueHelper_Print("RogueHelperSE:  /rhse");
	end
end



function RogueHelper_Main_ChatCommandHandler(msg)
	if ( ROGUEHELPER_STATE == 0 ) then
		return;
	else
		if( msg ) then
			local command = string.lower(msg);
			if( command == "on" ) then
				if ( ROGUEHELPER_STATE == 1 ) then
					ROGUEHELPER_STATE = ROGUEHELPER_Save.state;
					RogueHelperFrame:Show();
					RogueHelper_Print(ROGUEHELPER_CHAT_ENABLED);
			end
			elseif ( command == "off" ) then
				if ( ROGUEHELPER_STATE ~= 1 ) then
					RogueHelper_SetState(1);
					RogueHelper_Print(ROGUEHELPER_CHAT_DISABLED);
				end
			elseif ( command == "lock" ) then
				if ( ROGUEHELPER_STATE ~= 1 ) then
					RogueHelper_SetState(2);
					RogueHelper_Print(ROGUEHELPER_CHAT_LOCKED);
				end
			elseif ( command == "unlock" ) then
				if ( ROGUEHELPER_STATE ~= 1 ) then
					RogueHelper_SetState(3);
					RogueHelper_Print(ROGUEHELPER_CHAT_UNLOCKED);
				end
			elseif ( command == "back on" ) then
				RogueHelper_SetBack(1);
				RogueHelper_Print(ROGUEHELPER_CHAT_BACKON);
			elseif ( command == "back off" ) then
				RogueHelper_SetBack(0);
				RogueHelper_Print(ROGUEHELPER_CHAT_BACKOFF);
			elseif ( command == "reset" ) then
				ROGUEHELPER_Save = nil;
				RogueHelper_LoadVariables();
				RogueHelper_SetState(ROGUEHELPER_STATE);
				RogueHelper_SetBack(ROGUEHELPER_BACK);
				RogueHelperFrame:ClearAllPoints();
				RogueHelperFrame:SetPoint( "CENTER", (RogueHelperFrame:GetParent()):GetName(), "CENTER", 0, 0 );
				RogueHelper_Print(ROGUEHELPER_CHAT_RESET);
			else
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP1);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP2);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP3);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP4);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP5);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP6);
				RogueHelper_Print(ROGUEHELPER_CHAT_HELP7);
			end
		end
	end
end



function RogueHelper_OnEvent()
	if ( ROGUEHELPER_STATE == 0 ) then
		return;
	else
		if ( event == "PLAYER_ENTERING_WORLD" ) then
			local lcl,uscl = UnitClass("player");
			if ( uscl ~= "ROGUE" ) then
				this:UnregisterEvent("VARIABLES_LOADED");
				this:UnregisterEvent("PLAYER_ENTERING_WORLD");
				RogueHelper_SetState(0);
				RogueHelper_Print(ROGUEHELPER_CHAT_DISABLED);
			end
		elseif ( event == "VARIABLES_LOADED" ) then
			-- initial state and background
			RogueHelper_LoadVariables();
			RogueHelper_SetState(ROGUEHELPER_STATE);
			RogueHelper_SetBack(ROGUEHELPER_BACK);
		end
	end
end



function RogueHelper_UpdateWindow_OnLoad()
	if ( ROGUEHELPER_STATE == 0 ) then
		return;
	else
		this:RegisterForDrag("LeftButton");
		this:RegisterEvent("PLAYER_COMBO_POINTS");
	end
end



function RogueHelper_UpdateWindow_OnEvent()
	if ( ROGUEHELPER_STATE == 0 ) then
		return;
	else
		if ( event == "PLAYER_COMBO_POINTS") then
			RogueHelper_UpdateWindow_UpdateValues();
		end
	end
end



function RogueHelper_UpdateWindow_UpdateValues()
	local baseName = "RogueHelperFrameText";
	name = baseName.."Upper";
	obj = getglobal(name);
	if ( obj ) then
		obj:SetText(RogueHelper_GetComboPointsText());
	end
end



function RogueHelper_UpdateWindow_GetDragFrame()
	if ( ( not this.isLocked ) or ( this.isLocked == 0 ) ) then
		return this;
	else
		return nil;
	end
end



function RogueHelper_UpdateWindow_OnDragStop()
	local dragFrame = RogueHelper_UpdateWindow_GetDragFrame();
	if ( dragFrame ) then
		dragFrame:StopMovingOrSizing();
		dragFrame.isMoving = false;
	end
	if ( ( this ) and ( this ~= dragFrame )) then
		this:StopMovingOrSizing();
		this.isMoving = false;
	end
end



function RogueHelper_UpdateWindow_OnDragStart()
	local dragFrame = RogueHelper_UpdateWindow_GetDragFrame();
	if ( dragFrame ) then
		dragFrame:StartMoving();
		dragFrame.isMoving = true;
		if ( dragFrame ~= this ) then
			this:StartMoving();
			this.isMoving = true;
		end
	end
end



function RogueHelper_LoadVariables()
	if ( not ROGUEHELPER_Save ) then
  		ROGUEHELPER_Save = {};
		ROGUEHELPER_Save.state = 3;
		ROGUEHELPER_Save.back = 1;
	end
	ROGUEHELPER_STATE = ROGUEHELPER_Save.state;
	ROGUEHELPER_BACK = ROGUEHELPER_Save.back;
end



-- state meanings:
--   0  RogueHelperSE is off and locked and can not be activated (for example if players isn't a rogue)
--   1  RogueHelperSE is off and locked but can be activated
--   2  RogueHelperSE is on and locked
--   3  RogueHelperSE is on and unlocked
function RogueHelper_SetState(stateid)
	if (stateid == 0) then
		ROGUEHELPER_STATE=0;
		RogueHelperFrame:Hide();
	elseif (stateid == 1) then
		ROGUEHELPER_Save.state = ROGUEHELPER_STATE;
		ROGUEHELPER_STATE = 1;
		RogueHelperFrame:Hide();
	elseif (stateid == 2) then
		ROGUEHELPER_STATE = 2;
		ROGUEHELPER_Save.state = ROGUEHELPER_STATE;
		RogueHelper_LockWindow();
	elseif (stateid == 3) then
		ROGUEHELPER_STATE = 3;
		ROGUEHELPER_Save.state = ROGUEHELPER_STATE;
		RogueHelper_UnlockWindow();
	else
	end
end



-- back meanings:
--   0  windowbackground invisible
--   1  windowbackground visible
function RogueHelper_SetBack(backid)
	if (backid == 0) then
		ROGUEHELPER_BACK=0;
		ROGUEHELPER_Save.back = ROGUEHELPER_BACK;
		RogueHelperFrame:SetBackdropColor(1, 1, 1, 0);
		RogueHelperFrame:SetBackdropBorderColor(1, 1, 1, 0);
	elseif (backid == 1) then
		ROGUEHELPER_BACK=1;
		ROGUEHELPER_Save.back = ROGUEHELPER_BACK;
		RogueHelperFrame:SetBackdropColor(1, 1, 1, 1);
		RogueHelperFrame:SetBackdropBorderColor(1, 1, 1, 1);
	else
	end
end



function RogueHelper_LockWindow()
	local obj = getglobal("RogueHelperFrame");
	if ( obj ) then
		obj.isLocked = 1;
	end
end



function RogueHelper_UnlockWindow()
	local obj = getglobal("RogueHelperFrame");
	if ( obj ) then
		obj.isLocked = 0;
	end
end



function RogueHelper_FixColorValue(value)
	if ( value > 1 ) then
		value = 1;
	elseif ( value < 0 ) then
		value = 0;
	end
	return value;
end



function RogueHelper_GetComboPointsText()
	local text = "";
	text = GetComboPoints().."/"..MAX_COMBO_POINTS;
	return text;
end



function RogueHelper_GetByteValue(pValue)
	local value = tonumber(pValue);
	if ( value <= 0 ) then return 0; end
	if ( value >= 255 ) then return 255; end
	return value;
end



function RogueHelper_GetColorFormatString(a, r, g, b)
	local percent = false;
	if ( ( ( not b ) or ( b <= 1 ) ) and ( a <= 1 ) and ( r <= 1 ) and ( g <= 1) ) then percent = true; end
	if ( ( not b ) and ( a ) and ( r ) and ( g ) ) then b = g; g = r; r = a; if ( percent ) then a = 1; else a = 255; end end
	if ( percent ) then a = a * 255; r = r * 255; g = g * 255; b = b * 255; end
	a = RogueHelper_GetByteValue(a); r = RogueHelper_GetByteValue(r); g = RogueHelper_GetByteValue(g); b = RogueHelper_GetByteValue(b);

	return format("|c%02X%02X%02X%02X%%s|r", a, r, g, b);
end



function RogueHelper_Print(msg)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end
