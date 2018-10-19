local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local GetItemQualityColor = GetItemQualityColor
local GetTradePlayerItemInfo = GetTradePlayerItemInfo
local GetTradeTargetItemInfo = GetTradeTargetItemInfo
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.trade ~= true then return end

	E:StripTextures(TradeFrame, true)
	E:Width(TradeFrame, 400)
	E:CreateBackdrop(TradeFrame, "Transparent")
	E:Point(TradeFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(TradeFrame.backdrop, "BOTTOMRIGHT", -28, 48)

	S:HandleCloseButton(TradeFrameCloseButton, TradeFrame.backdrop)

	S:HandleEditBox(TradePlayerInputMoneyFrameGold)
	S:HandleEditBox(TradePlayerInputMoneyFrameSilver)
	S:HandleEditBox(TradePlayerInputMoneyFrameCopper)

	for i = 1, MAX_TRADE_ITEMS do
		local player = _G["TradePlayerItem"..i]
		local recipient = _G["TradeRecipientItem"..i]
		local playerButton = _G["TradePlayerItem"..i.."ItemButton"]
		local playerButtonIcon = _G["TradePlayerItem"..i.."ItemButtonIconTexture"]
		local recipientButton = _G["TradeRecipientItem"..i.."ItemButton"]
		local recipientButtonIcon = _G["TradeRecipientItem"..i.."ItemButtonIconTexture"]
		local playerNameFrame = _G["TradePlayerItem"..i.."NameFrame"]
		local recipientNameFrame = _G["TradeRecipientItem"..i.."NameFrame"]

		E:StripTextures(player)
		E:StripTextures(recipient)

		E:StripTextures(playerButton)
		E:StyleButton(playerButton)
		E:SetTemplate(playerButton, "Default", true)

		E:SetInside(playerButtonIcon)
		playerButtonIcon:SetTexCoord(unpack(E.TexCoords))

		E:StripTextures(recipientButton)
		E:StyleButton(recipientButton)
		E:SetTemplate(recipientButton, "Default", true)

		E:SetInside(recipientButtonIcon)
		recipientButtonIcon:SetTexCoord(unpack(E.TexCoords))

		playerButton.bg = CreateFrame("Frame", nil, playerButton)
		E:SetTemplate(playerButton.bg, "Default")
		E:Point(playerButton.bg, "TOPLEFT", playerButton, "TOPRIGHT", 4, 0)
		E:Point(playerButton.bg, "BOTTOMRIGHT", playerNameFrame, "BOTTOMRIGHT", -5, 14)
		playerButton.bg:SetFrameLevel(playerButton:GetFrameLevel() - 4)

		recipientButton.bg = CreateFrame("Frame", nil, recipientButton)
		E:SetTemplate(recipientButton.bg, "Default")
		E:Point(recipientButton.bg, "TOPLEFT", recipientButton, "TOPRIGHT", 4, 0)
		E:Point(recipientButton.bg, "BOTTOMRIGHT", recipientNameFrame, "BOTTOMRIGHT", -5, 14)
		recipientButton.bg:SetFrameLevel(recipientButton:GetFrameLevel() - 4)
	end

	E:Point(TradePlayerItem1, "TOPLEFT", 24, -104)

	TradeHighlightPlayerTop:SetTexture(0, 1, 0, 0.2)
	TradeHighlightPlayerBottom:SetTexture(0, 1, 0, 0.2)
	TradeHighlightPlayerMiddle:SetTexture(0, 1, 0, 0.2)

	TradeHighlightPlayerEnchantTop:SetTexture(0, 1, 0, 0.2)
	TradeHighlightPlayerEnchantBottom:SetTexture(0, 1, 0, 0.2)
	TradeHighlightPlayerEnchantMiddle:SetTexture(0, 1, 0, 0.2)

	TradeHighlightRecipientTop:SetTexture(0, 1, 0, 0.2)
	TradeHighlightRecipientBottom:SetTexture(0, 1, 0, 0.2)
	TradeHighlightRecipientMiddle:SetTexture(0, 1, 0, 0.2)

	TradeHighlightRecipientEnchantTop:SetTexture(0, 1, 0, 0.2)
	TradeHighlightRecipientEnchantBottom:SetTexture(0, 1, 0, 0.2)
	TradeHighlightRecipientEnchantMiddle:SetTexture(0, 1, 0, 0.2)

	S:HandleButton(TradeFrameTradeButton)
	E:Point(TradeFrameTradeButton, "BOTTOMRIGHT", -120, 55)

	S:HandleButton(TradeFrameCancelButton)

	hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
		local tradeItemButton = _G["TradePlayerItem"..id.."ItemButton"]
		local tradeItemName = _G["TradePlayerItem"..id.."Name"]

		local name = GetTradePlayerItemInfo(id)
		if name then
			local _, _, _, quality = GetTradePlayerItemInfo(id)
			tradeItemName:SetTextColor(GetItemQualityColor(quality))
			if quality then
				tradeItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
			end
		else
			tradeItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)

	hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
		local tradeItemButton = _G["TradeRecipientItem"..id.."ItemButton"]
		local tradeItemName = _G["TradeRecipientItem"..id.."Name"]

		local name = GetTradeTargetItemInfo(id)
		if name then
			local _, _, _, quality = GetTradeTargetItemInfo(id)
			tradeItemName:SetTextColor(GetItemQualityColor(quality))
			if quality then
				tradeItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
			end
		else
			tradeItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)
end

S:AddCallback("Trade", LoadSkin)