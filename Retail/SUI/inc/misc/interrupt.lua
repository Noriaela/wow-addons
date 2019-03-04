--[[SUI INTERRUPT v1.0]]

local CF=CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

if not SUIDB.A_INTERRUPT == true then return end 

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript(
	"OnEvent",
	function(self, _, ...)
		local _, event, _, sourceGUID, _, _, _, _, destName, _, _, _, _, _, spellID = ...
		if not (event == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player")) then
			return
		end

		SendChatMessage("Interrupted: " .. (GetSpellLink(spellID)), "PARTY")
	end
)

end)
