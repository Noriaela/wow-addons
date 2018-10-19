local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins");

--Cache global variables
--Lua functions
local _G = _G
local unpack = unpack
local match = string.match
--WoW API / Variables
local GetItemQualityColor = GetItemQualityColor
local GetContainerItemLink = GetContainerItemLink
local BANK_CONTAINER = BANK_CONTAINER
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES

function S:ContainerFrame_Update()
	local id = this:GetID()
	local name = this:GetName()
	local _, itemButton, itemLink, quality

	for i = 1, this.size, 1 do
		itemButton = _G[name.."Item"..i]

		itemLink = GetContainerItemLink(id, itemButton:GetID())
		if itemLink then
			_, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
			if quality and quality > 1 then
				itemButton:SetBackdropBorderColor(GetItemQualityColor(quality))
				itemButton.ignoreBorderColors = true
			else
				itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				itemButton.ignoreBorderColors = true
			end
		else
			itemButton:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			itemButton.ignoreBorderColors = true
		end
	end
end

function S:BankFrameItemButton_OnUpdate()
	if not this.isBag then
		local itemLink = GetContainerItemLink(BANK_CONTAINER, this:GetID())
		if itemLink then
			local _, _, quality = GetItemInfo(match(itemLink, "item:(%d+)"))
			if quality and quality > 1 then
				this:SetBackdropBorderColor(GetItemQualityColor(quality))
				this.ignoreBorderColors = true
			else
				this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
				this.ignoreBorderColors = true
			end
		else
			this:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			this.ignoreBorderColors = true
		end
	end
end

local function LoadSkin()
	if not E.private.skins.blizzard.enable and E.private.skins.blizzard.bags and not E.private.bags.enable then return end

	-- ContainerFrame
	local containerFrame, containerFrameClose
	for i = 1, NUM_CONTAINER_FRAMES, 1 do
		containerFrame = _G["ContainerFrame"..i]
		containerFrameClose = _G["ContainerFrame"..i.."CloseButton"]

		E:StripTextures(containerFrame, true)
		E:CreateBackdrop(containerFrame, "Transparent")
		E:Point(containerFrame.backdrop, "TOPLEFT", 9, -4)
		E:Point(containerFrame.backdrop, "BOTTOMRIGHT", -4, 2)

		S:HandleCloseButton(containerFrameClose)

		S:SecureHookScript(containerFrame, "OnShow", "ContainerFrame_Update")

		local itemButton, itemButtonIcon, itemButtonCooldown
		for k = 1, MAX_CONTAINER_ITEMS, 1 do
			itemButton = _G["ContainerFrame"..i.."Item"..k]
			itemButtonIcon = _G["ContainerFrame"..i.."Item"..k.."IconTexture"]
			itemButtonCooldown = _G["ContainerFrame"..i.."Item"..k.."Cooldown"]

			itemButton:SetNormalTexture("")

			E:SetTemplate(itemButton, "Default", true)
			E:StyleButton(itemButton)

			E:SetInside(itemButtonIcon)
			itemButtonIcon:SetTexCoord(unpack(E.TexCoords))

			if itemButtonCooldown then
				E:RegisterCooldown(itemButtonCooldown)
			end
		end
	end

	S:SecureHook("ContainerFrame_Update")

	-- BankFrame
	E:CreateBackdrop(BankFrame, "Transparent")
	E:Point(BankFrame.backdrop, "TOPLEFT", 10, -11)
	E:Point(BankFrame.backdrop, "BOTTOMRIGHT", -26, 93)

	E:StripTextures(BankFrame, true)

	S:HandleCloseButton(BankCloseButton, BankFrame.backdrop)

	local button, buttonIcon
	for i = 1, NUM_BANKGENERIC_SLOTS, 1 do
		button = _G["BankFrameItem"..i]
		buttonIcon = _G["BankFrameItem"..i.."IconTexture"]

		button:SetNormalTexture("")

		E:SetTemplate(button, "Default", true)
		E:StyleButton(button)

		E:SetInside(buttonIcon)
		buttonIcon:SetTexCoord(unpack(E.TexCoords))
	end

	BankFrame.itemBackdrop = CreateFrame("Frame", "BankFrameItemBackdrop", BankFrame)
	E:SetTemplate(BankFrame.itemBackdrop, "Default")
	E:Point(BankFrame.itemBackdrop, "TOPLEFT", BankFrameItem1, "TOPLEFT", -6, 6)
	E:Point(BankFrame.itemBackdrop, "BOTTOMRIGHT", BankFrameItem24, "BOTTOMRIGHT", 6, -6)
	BankFrame.itemBackdrop:SetFrameLevel(BankFrame:GetFrameLevel())

	for i = 1, NUM_BANKBAGSLOTS, 1 do
		button = _G["BankFrameBag"..i]
		buttonIcon = _G["BankFrameBag"..i.."IconTexture"]

		button:SetNormalTexture("")

		E:SetTemplate(button, "Default", true)
		E:StyleButton(button)

		E:SetInside(buttonIcon)
		buttonIcon:SetTexCoord(unpack(E.TexCoords))

		E:SetInside(_G["BankFrameBag"..i.."HighlightFrameTexture"])
		_G["BankFrameBag"..i.."HighlightFrameTexture"]:SetTexture(unpack(E["media"].rgbvaluecolor), 0.3)
	end

	BankFrame.bagBackdrop = CreateFrame("Frame", "BankFrameBagBackdrop", BankFrame)
	E:SetTemplate(BankFrame.bagBackdrop, "Default")
	E:Point(BankFrame.bagBackdrop, "TOPLEFT", BankFrameBag1, "TOPLEFT", -6, 6)
	E:Point(BankFrame.bagBackdrop, "BOTTOMRIGHT", BankFrameBag6, "BOTTOMRIGHT", 6, -6)
	BankFrame.bagBackdrop:SetFrameLevel(BankFrame:GetFrameLevel())

	S:HandleButton(BankFramePurchaseButton)

	S:SecureHook("BankFrameItemButton_OnUpdate")
end

S:AddCallback("SkinBags", LoadSkin)