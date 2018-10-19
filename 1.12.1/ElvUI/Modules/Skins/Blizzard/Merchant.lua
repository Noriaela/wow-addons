local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local match = string.match
--WoW API / Variables
local GetBuybackItemInfo = GetBuybackItemInfo
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetMerchantItemLink = GetMerchantItemLink
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.merchant ~= true then return end

	E:StripTextures(MerchantFrame, true)
	E:CreateBackdrop(MerchantFrame, "Transparent")
	E:Point(MerchantFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(MerchantFrame.backdrop, "BOTTOMRIGHT", -28, 60)

	MerchantFrame:EnableMouseWheel(true)
	MerchantFrame:SetScript("OnMouseWheel", function()
		if arg1 > 0 then
			if MerchantPrevPageButton:IsShown() and MerchantPrevPageButton:IsEnabled() == 1 then
				MerchantPrevPageButton_OnClick()
			end
		else
			if MerchantNextPageButton:IsShown() and MerchantNextPageButton:IsEnabled() == 1 then
				MerchantNextPageButton_OnClick()
			end	
		end
	end)

	S:HandleCloseButton(MerchantFrameCloseButton, MerchantFrame.backdrop)

	for i = 1, 12 do
		local item = _G["MerchantItem"..i]
		local itemButton = _G["MerchantItem"..i.."ItemButton"]
		local iconTexture = _G["MerchantItem"..i.."ItemButtonIconTexture"]

		E:StripTextures(item, true)
		E:CreateBackdrop(item, "Default")

		E:StripTextures(itemButton)
		E:StyleButton(itemButton)
		E:SetTemplate(itemButton, "Default", true)
		E:Point(itemButton, "TOPLEFT", item, "TOPLEFT", 4, -4)

		iconTexture:SetTexCoord(unpack(E.TexCoords))
		E:SetInside(iconTexture)

		_G["MerchantItem"..i.."MoneyFrame"]:ClearAllPoints()
		E:Point(_G["MerchantItem"..i.."MoneyFrame"], "BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 3, 0)
	end

	S:HandleNextPrevButton(MerchantNextPageButton)
	S:HandleNextPrevButton(MerchantPrevPageButton)

	E:StyleButton(MerchantRepairItemButton)
	E:SetTemplate(MerchantRepairItemButton, "Default", true)

	for _, region in ipairs({MerchantRepairItemButton:GetRegions()}) do
		if region:GetObjectType() == "Texture" then
			region:SetTexCoord(0.04, 0.24, 0.06, 0.5)
			E:SetInside(region)
		end
	end

	--[[for i = 1, MerchantRepairItemButton:GetNumRegions() do
		local region = select(i, MerchantRepairItemButton:GetRegions())
		if region:GetObjectType() == "Texture" then
			region:SetTexCoord(0.04, 0.24, 0.06, 0.5)
			E:SetInside(region)
		end
	end--]]

	E:StyleButton(MerchantRepairAllButton)
	E:SetTemplate(MerchantRepairAllButton, "Default", true)
	MerchantRepairAllIcon:SetTexCoord(0.34, 0.1, 0.34, 0.535, 0.535, 0.1, 0.535, 0.535)
	E:SetInside(MerchantRepairAllIcon)

	E:StripTextures(MerchantBuyBackItem, true)
	E:CreateBackdrop(MerchantBuyBackItem, "Transparent")
	E:Point(MerchantBuyBackItem.backdrop, "TOPLEFT", -6, 6)
	E:Point(MerchantBuyBackItem.backdrop, "BOTTOMRIGHT", 6, -6)

	E:StripTextures(MerchantBuyBackItemItemButton)
	E:StyleButton(MerchantBuyBackItemItemButton)
	E:SetTemplate(MerchantBuyBackItemItemButton, "Default", true)
	MerchantBuyBackItemItemButtonIconTexture:SetTexCoord(unpack(E.TexCoords))
	E:SetInside(MerchantBuyBackItemItemButtonIconTexture)

	for i = 1, 2 do
		S:HandleTab(_G["MerchantFrameTab"..i])
	end

	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
		local numMerchantItems = GetMerchantNumItems()
		for i = 1, MERCHANT_ITEMS_PER_PAGE do
			local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)
			local itemButton = _G["MerchantItem"..i.."ItemButton"]
			local itemName = _G["MerchantItem"..i.."Name"]

			if index <= numMerchantItems then
				local itemLink = GetMerchantItemLink(index)
				if itemLink then
					local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
					if quality then
						itemName:SetTextColor(GetItemQualityColor(quality))
						itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
					else
						itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					end
				else
					itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end

			HookScript(MerchantBuyBackItemItemButton, "OnEvent", function()
				this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end)

			local buybackName = GetBuybackItemInfo(GetNumBuybackItems())
			if buybackName then
				local _, _, quality = GetItemInfoByName(buybackName)
				if quality then
					MerchantBuyBackItemName:SetTextColor(GetItemQualityColor(quality))
					MerchantBuyBackItemItemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
				else
					MerchantBuyBackItemItemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				end
			end
		end
	end)

	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
		local numBuybackItems = GetNumBuybackItems()
		for i = 1, BUYBACK_ITEMS_PER_PAGE do
			local itemButton = _G["MerchantItem"..i.."ItemButton"]
			local itemName = _G["MerchantItem"..i.."Name"]

			if i <= numBuybackItems then
				local buybackName = GetBuybackItemInfo(i)
				if buybackName then
					local _, _, quality = GetItemInfoByName(buybackName)
					if quality then
						itemName:SetTextColor(GetItemQualityColor(quality))
						itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
					else
						itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
					end
				end
			end
		end
	end)
end

S:AddCallback("Merchant", LoadSkin)