local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames");

function UF:Construct_RaidIcon(frame)
	local tex = frame.RaisedElementParent.TextureParent:CreateTexture(nil, "OVERLAY")
	tex:SetTexture([[Interface\AddOns\ElvUI\media\textures\raidicons]])
	tex:SetWidth(18)
	tex:SetHeight(18)
	tex:SetPoint("CENTER", frame.Health, "TOP", 0, 2)
	tex.SetTexture = E.noop

	return tex
end

function UF:Configure_RaidIcon(frame)
	local RI = frame.RaidTargetIndicator
	local db = frame.db

	if db.raidicon.enable then
		frame:EnableElement("RaidTargetIndicator")
		RI:Show()
		RI:SetWidth(db.raidicon.size)
		RI:SetHeight(db.raidicon.size)

		local attachPoint = self:GetObjectAnchorPoint(frame, db.raidicon.attachToObject)
		RI:ClearAllPoints()
		RI:SetPoint(db.raidicon.attachTo, attachPoint, db.raidicon.attachTo, db.raidicon.xOffset, db.raidicon.yOffset)
	else
		frame:DisableElement("RaidTargetIndicator")
		RI:Hide()
	end
end