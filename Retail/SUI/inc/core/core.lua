-- REMOVING UGLY PARTS OF UI
local event_frame = CreateFrame("Frame")
local errormessage_blocks = {
	"Ability is not ready yet",
	"Another action is in progress",
	"Can't attack while mounted",
	"Can't do that while moving",
	"Item is not ready yet",
	"Not enough",
	"Nothing to attack",
	"Spell is not ready yet",
	"You have no target",
	"You can't do that yet"
}
local enable
local onevent
local uierrorsframe_addmessage
local old_uierrosframe_addmessage
function enable()
	old_uierrosframe_addmessage = UIErrorsFrame.AddMessage
	UIErrorsFrame.AddMessage = uierrorsframe_addmessage
end

function uierrorsframe_addmessage(frame, text, red, green, blue, id)
	for i, v in ipairs(errormessage_blocks) do
		if text and text:match(v) then
			return
		end
	end
	old_uierrosframe_addmessage(frame, text, red, green, blue, id)
end

function onevent(frame, event, ...)
	if event == "PLAYER_LOGIN" then
		enable()
	end
end
event_frame:SetScript("OnEvent", onevent)
event_frame:RegisterEvent("PLAYER_LOGIN")

-- SLASH COMMANDS
SlashCmdList["RELOAD"] = function()
	ReloadUI()
end
SLASH_RELOAD1 = "/rl"

-- HIDE ORDERHALLBAR
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript(
	"OnEvent",
	function(self, event, addon)
		if not SUIDB.A_ORDERHALLBAR == true then
			if addon == "Blizzard_OrderHallUI" then
				OrderHallCommandBar:Hide()
				OrderHallCommandBar.Show = function()
				end
			end
		end
	end
)

-- HIDE TALKHEAD
local f = CreateFrame("Frame")
function f:OnEvent(event, addon)
	if not SUIDB.A_TALKINGHEAD == true then
		if addon == "Blizzard_TalkingHeadUI" then
			hooksecurefunc(
				"TalkingHeadFrame_PlayCurrent",
				function()
					TalkingHeadFrame:Hide()
				end
			)
			self:UnregisterEvent(event)
		end
	end
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

--[[ COORDS

local f = CreateFrame("Frame", nil, WorldMapFrame)
f:SetParent(WorldMapScrollFrame)

f.Player = f:CreateFontString(nil, "OVERLAY")
f.Player:SetFont("Fonts\\ARIALN.ttf", 13, "THINOUTLINE")
f.Player:SetJustifyH("LEFT")
f.Player:SetPoint("BOTTOMLEFT", WorldMapScrollFrame, "BOTTOMLEFT", 5, 5)
f.Player:SetTextColor(1, 0.82, 0)

f.Cursor = f:CreateFontString(nil, "OVERLAY")
f.Cursor:SetFont("Fonts\\ARIALN.ttf", 13, "THINOUTLINE")
f.Cursor:SetJustifyH("LEFT")
f.Cursor:SetPoint("BOTTOMLEFT", WorldMapScrollFrame, "BOTTOMLEFT", 115, 5)
f.Cursor:SetTextColor(1, 0.82, 0)

f:SetScript(
	"OnUpdate",
	function(self, elapsed)
		if SUIDB.COORDS == true then
			local width = WorldMapDetailFrame:GetWidth()
			local height = WorldMapDetailFrame:GetHeight()
			local mx, my = WorldMapDetailFrame:GetCenter()
			local px, py = GetPlayerMapPosition("player")
			local cx, cy = GetCursorPosition()

			if (px) then
				mx = ((cx / WorldMapDetailFrame:GetEffectiveScale()) - (mx - width / 2)) / width
				my = ((my + height / 2) - (cy / WorldMapDetailFrame:GetEffectiveScale())) / height

				if (mx >= 0 and my >= 0 and mx <= 1 and my <= 1) then
					f.Cursor:SetText(MOUSE_LABEL .. format(": %.0f x %.0f", mx * 100, my * 100))
				else
					f.Cursor:SetText("")
				end

				if (px ~= 0 and py ~= 0) then
					f.Player:SetText(UnitName("player") .. format(": %.0f x %.0f", px * 100, py * 100))
				else
					f.Player:SetText("")
				end
			else
				f.Cursor:SetText("")
				f.Player:SetText("")
			end
		end
	end
)
]]

-- COLORING FRAMES
local CF = CreateFrame("Frame")
CF:RegisterEvent("PLAYER_ENTERING_WORLD")
CF:RegisterEvent("GROUP_ROSTER_UPDATE")

function ColorRaid()
	for g = 1, NUM_RAID_GROUPS do
		local group = _G["CompactRaidGroup" .. g .. "BorderFrame"]
		if group then
			for _, region in pairs({group:GetRegions()}) do
				if region:IsObjectType("Texture") then
					region:SetVertexColor(.15, .15, .15)
				end
			end
		end
		for m = 1, 5 do
			local frame = _G["CompactRaidGroup" .. g .. "Member" .. m]
			if frame then
				groupcolored = true
				for _, region in pairs({frame:GetRegions()}) do
					if region:GetName():find("Border") then
						region:SetVertexColor(.15, .15, .15)
					end
				end
			end
			local frame = _G["CompactRaidFrame" .. m]
			if frame then
				singlecolored = true
				for _, region in pairs({frame:GetRegions()}) do
					if region:GetName():find("Border") then
						region:SetVertexColor(.15, .15, .15)
					end
				end
			end
		end
	end
	for _, region in pairs({CompactRaidFrameContainerBorderFrame:GetRegions()}) do
		if region:IsObjectType("Texture") then
			region:SetVertexColor(.15, .15, .15)
		end
	end
end

CF:SetScript(
	"OnEvent",
	function(self, event)
		if SUIDB.A_DARKFRAMES == true then
			ColorRaid()
			CF:SetScript(
				"OnUpdate",
				function()
					if CompactRaidGroup1 and not groupcolored == true then
						ColorRaid()
					end
					if CompactRaidFrame1 and not singlecolored == true then
						ColorRaid()
					end
				end
			)
			if event == "GROUP_ROSTER_UPDATE" then
				return
			end
			if
				not (IsAddOnLoaded("Shadowed Unit Frames") or IsAddOnLoaded("PitBull Unit Frames 4.0") or
					IsAddOnLoaded("X-Perl UnitFrames"))
			 then
				for i, v in pairs(
					{
						PlayerFrameTexture,
						TargetFrameTextureFrameTexture,
						PlayerFrameAlternateManaBarBorder,
						PlayerFrameAlternateManaBarLeftBorder,
						PlayerFrameAlternateManaBarRightBorder,
						PaladinPowerBarFrameBG,
						PaladinPowerBarFrameBankBG,
						ComboPointPlayerFrame.Background,
						ComboPointPlayerFrame.Combo1.PointOff,
						ComboPointPlayerFrame.Combo2.PointOff,
						ComboPointPlayerFrame.Combo3.PointOff,
						ComboPointPlayerFrame.Combo4.PointOff,
						ComboPointPlayerFrame.Combo5.PointOff,
						ComboPointPlayerFrame.Combo6.PointOff,
						AlternatePowerBarBorder,
						AlternatePowerBarLeftBorder,
						AlternatePowerBarRightBorder,
						PetFrameTexture,
						PartyMemberFrame1Texture,
						PartyMemberFrame2Texture,
						PartyMemberFrame3Texture,
						PartyMemberFrame4Texture,
						PartyMemberFrame1PetFrameTexture,
						PartyMemberFrame2PetFrameTexture,
						PartyMemberFrame3PetFrameTexture,
						PartyMemberFrame4PetFrameTexture,
						FocusFrameTextureFrameTexture,
						TargetFrameToTTextureFrameTexture,
						FocusFrameToTTextureFrameTexture,
						Boss1TargetFrameTextureFrameTexture,
						Boss2TargetFrameTextureFrameTexture,
						Boss3TargetFrameTextureFrameTexture,
						Boss4TargetFrameTextureFrameTexture,
						Boss5TargetFrameTextureFrameTexture,
						Boss1TargetFrameSpellBar.Border,
						Boss2TargetFrameSpellBar.Border,
						Boss3TargetFrameSpellBar.Border,
						Boss4TargetFrameSpellBar.Border,
						Boss5TargetFrameSpellBar.Border,
						CastingBarFrame.Border,
						FocusFrameSpellBar.Border,
						TargetFrameSpellBar.Border,
						StatusTrackingBarManager.SingleBarLargeUpper,
						StatusTrackingBarManager.SingleBarSmallUpper,
					}
				) do
					v:SetVertexColor(.15, .15, .15)
				end

				for _, region in pairs({StopwatchFrame:GetRegions()}) do
					region:SetVertexColor(.15, .15, .15)
				end

				for _, region in pairs({CompactRaidFrameManager:GetRegions()}) do
					if region:IsObjectType("Texture") then
						region:SetVertexColor(.15, .15, .15)
					end
				end
				for _, region in pairs({CompactRaidFrameManagerContainerResizeFrame:GetRegions()}) do
					if region:GetName():find("Border") then
						region:SetVertexColor(.15, .15, .15)
					end
				end
				CompactRaidFrameManagerToggleButton:SetNormalTexture(
					"Interface\\AddOns\\SUI\\inc\\media\\raid\\RaidPanel-Toggle"
				)

				for i, v in pairs(
					{
						PlayerPVPIcon,
						TargetFrameTextureFramePVPIcon,
						FocusFrameTextureFramePVPIcon
					}
				) do
					v:SetAlpha(0)
				end
				for i = 1, 4 do
					_G["PartyMemberFrame" .. i .. "PVPIcon"]:SetAlpha(0)
					_G["PartyMemberFrame" .. i .. "NotPresentIcon"]:Hide()
					_G["PartyMemberFrame" .. i .. "NotPresentIcon"].Show = function()
					end
				end
				PlayerFrameGroupIndicator:SetAlpha(0)
				PlayerHitIndicator:SetText(nil)
				PlayerHitIndicator.SetText = function()
				end
				PetHitIndicator:SetText(nil)
				PetHitIndicator.SetText = function()
				end
				for _, child in pairs({WarlockPowerFrame:GetChildren()}) do
					for _, region in pairs({child:GetRegions()}) do
						if region:GetDrawLayer() == "BORDER" then
							region:SetVertexColor(.15, .15, .15)
						end
					end
				end
			else
				CastingBarFrameBorder:SetVertexColor(.15, .15, .15)
			end

			-- COLORING THE MAIN BAR
			for i, v in pairs(
				{
					MicroButtonAndBagsBar.MicroBagBar,
					MainMenuBarArtFrameBackground.BackgroundLarge,
					MainMenuBarArtFrameBackground.BackgroundSmall,
					StatusTrackingBarManager.SingleBarLarge,
					StatusTrackingBarManager.SingleBarSmall,
					SlidingActionBarTexture0,
					SlidingActionBarTexture1,
					MainMenuBarTexture0,
					MainMenuBarTexture1,
					MainMenuBarTexture2,
					MainMenuBarTexture3,
					MainMenuMaxLevelBar0,
					MainMenuMaxLevelBar1,
					MainMenuMaxLevelBar2,
					MainMenuMaxLevelBar3,
					MainMenuXPBarTextureLeftCap,
					MainMenuXPBarTextureRightCap,
					MainMenuXPBarTextureMid,
					ReputationWatchBarTexture0,
					ReputationWatchBarTexture1,
					ReputationWatchBarTexture2,
					ReputationWatchBarTexture3,
					ReputationXPBarTexture0,
					ReputationXPBarTexture1,
					ReputationXPBarTexture2,
					ReputationXPBarTexture3,
				}
			) do
				v:SetVertexColor(.15, .15, .15)
			end
			--[[for i = 1, 19 do
				_G["MainMenuXPBarDiv" .. i]:SetTexture(Empty_Art)
			end
			ArtifactWatchBar.Tick.Normal:SetVertexColor(0.4, 0.4, 0.4)
			ExhaustionTick:SetAlpha(0)]]
			for i, v in pairs(
				{
					MainMenuBarArtFrame.LeftEndCap,
					MainMenuBarArtFrame.RightEndCap,
					StanceBarLeft,
					StanceBarMiddle,
					StanceBarRight
				}
			) do
				v:SetVertexColor(.2, .2, .2)
			end
		end
	end
)

-- COLORING ARENA FRAMES
local CF = CreateFrame("Frame")
local _, instanceType = IsInInstance()
CF:RegisterEvent("ADDON_LOADED")
CF:RegisterEvent("PLAYER_ENTERING_WORLD")
CF:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
CF:SetScript(
	"OnEvent",
	function(self, event, addon)
		if SUIDB.A_DARKFRAMES == true then
			if addon == "Blizzard_ArenaUI" and not (IsAddOnLoaded("Shadowed Unit Frames")) then
				for i, v in pairs(
					{
						ArenaEnemyFrame1Texture,
						ArenaEnemyFrame2Texture,
						ArenaEnemyFrame3Texture,
						ArenaEnemyFrame4Texture,
						ArenaEnemyFrame5Texture,
						ArenaEnemyFrame1SpecBorder,
						ArenaEnemyFrame2SpecBorder,
						ArenaEnemyFrame3SpecBorder,
						ArenaEnemyFrame4SpecBorder,
						ArenaEnemyFrame5SpecBorder,
						ArenaEnemyFrame1PetFrameTexture,
						ArenaEnemyFrame2PetFrameTexture,
						ArenaEnemyFrame3PetFrameTexture,
						ArenaEnemyFrame4PetFrameTexture,
						ArenaEnemyFrame5PetFrameTexture
					}
				) do
					v:SetVertexColor(.15, .15, .15)
				end
			elseif
				event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or (event == "PLAYER_ENTERING_WORLD" and instanceType == "arena")
			 then
				for i, v in pairs(
					{
						ArenaPrepFrame1Texture,
						ArenaPrepFrame2Texture,
						ArenaPrepFrame3Texture,
						ArenaPrepFrame4Texture,
						ArenaPrepFrame5Texture,
						ArenaPrepFrame1SpecBorder,
						ArenaPrepFrame2SpecBorder,
						ArenaPrepFrame3SpecBorder,
						ArenaPrepFrame4SpecBorder,
						ArenaPrepFrame5SpecBorder
					}
				) do
					v:SetVertexColor(.15, .15, .15)
				end
			end

			if IsAddOnLoaded("Blizzard_ArenaUI") then
				for i, v in pairs(
					{
						ArenaEnemyFrame1Texture,
						ArenaEnemyFrame2Texture,
						ArenaEnemyFrame3Texture,
						ArenaEnemyFrame4Texture,
						ArenaEnemyFrame5Texture,
						ArenaEnemyFrame1SpecBorder,
						ArenaEnemyFrame2SpecBorder,
						ArenaEnemyFrame3SpecBorder,
						ArenaEnemyFrame4SpecBorder,
						ArenaEnemyFrame5SpecBorder,
						ArenaEnemyFrame1PetFrameTexture,
						ArenaEnemyFrame2PetFrameTexture,
						ArenaEnemyFrame3PetFrameTexture,
						ArenaEnemyFrame4PetFrameTexture,
						ArenaEnemyFrame5PetFrameTexture
					}
				) do
					v:SetVertexColor(.15, .15, .15)
				end
			end
		end
	end
)
