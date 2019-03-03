local E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")

local random = math.random

local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsConnected = UnitIsConnected

function UF:Construct_RoleIcon(frame)
 	local tex = frame.RaisedElementParent.TextureParent:CreateTexture(nil, "ARTWORK")
	tex:Size(17)
	tex:Point("BOTTOM", frame.Health, "BOTTOM", 0, 2)
	tex.Override = UF.UpdateRoleIcon

	return tex
end

local roleIconTextures = {
	TANK = [[Interface\AddOns\ElvUI\media\textures\tank]],
	HEALER = [[Interface\AddOns\ElvUI\media\textures\healer]],
	DAMAGER = [[Interface\AddOns\ElvUI\media\textures\dps]]
}

function UF:UpdateRoleIcon()
	local lfdrole = self.GroupRoleIndicator
	if not self.db then return end
	local db = self.db.roleIcon

	if (not db) or (db and not db.enable) then
		lfdrole:Hide()
		return
	end

	local role = UnitGroupRolesAssigned(self.unit)

	if self.isForced and role == 'NONE' then
		local rnd = random(1, 3)
		role = rnd == 1 and "TANK" or (rnd == 2 and "HEALER" or (rnd == 3 and "DAMAGER"))
	end

	if (self.isForced or UnitIsConnected(self.unit)) and ((role == "DAMAGER" and db.damager) or (role == "HEALER" and db.healer) or (role == "TANK" and db.tank)) then
		lfdrole:SetTexture(roleIconTextures[role])
		lfdrole:Show()
	else
		lfdrole:Hide()
	end
end

function UF:Configure_RoleIcon(frame)
	local role = frame.GroupRoleIndicator
	local db = frame.db

	if db.roleIcon.enable then
		frame:EnableElement("GroupRoleIndicator")
		local attachPoint = self:GetObjectAnchorPoint(frame, db.roleIcon.attachTo)

		role:ClearAllPoints()
		role:Point(db.roleIcon.position, attachPoint, db.roleIcon.position, db.roleIcon.xOffset, db.roleIcon.yOffset)
		role:Size(db.roleIcon.size)
	else
		frame:DisableElement("GroupRoleIndicator")
		role:Hide()
	end
end