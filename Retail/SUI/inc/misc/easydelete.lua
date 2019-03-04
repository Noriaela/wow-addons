local SUI=CreateFrame("Frame")
SUI:RegisterEvent("PLAYER_LOGIN")
SUI:SetScript("OnEvent", function(self, event)

if not SUIDB.A_EASYDELETE == true then return end

hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"],"OnShow",function(s)
    s.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)

end)