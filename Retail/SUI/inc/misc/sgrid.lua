--[[SUI SGRID v1.0]]

local CF=CreateFrame("Frame")
CF:RegisterEvent("PLAYER_LOGIN")
CF:SetScript("OnEvent", function(self, event)

if not SUIDB.A_SGRID == true then return end 

SLASH_SGRIDA1 = "/sgrid"

local frame
local w
local h

SlashCmdList["SGRIDA"] = function(msg, editbox)
	if frame then
		frame:Hide()
		frame = nil
	else
		if msg == "128" then
			w = 128
			h = 72
		elseif msg == "96" then
			w = 96
			h = 54
		elseif msg == "64" then
			w = 64
			h = 36
		elseif msg == "32" then
			w = 32
			h = 18
		else
			w = nil
			w = nil
		end

		if w == nil then
			print("Usage: '/sgrid <value>' Value options are 32/64/96/128")
		else
			local lines_w = GetScreenWidth() / w
			local lines_h = GetScreenHeight() / h

			frame = CreateFrame("Frame", nil, UIParent)
			frame:SetAllPoints(UIParent)

			for i = 0, w do
				local line_texture = frame:CreateTexture(nil, "BACKGROUND")
				if i == w / 2 then
					line_texture:SetColorTexture(1, 0, 0, 0.5)
				else
					line_texture:SetColorTexture(0, 0, 0, 0.1)
				end
				line_texture:SetPoint("TOPLEFT", frame, "TOPLEFT", i * lines_w - 1, 0)
				line_texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", i * lines_w + 1, 0)
			end

			for i = 0, h do
				local line_texture = frame:CreateTexture(nil, "BACKGROUND")
				if i == h / 2 then
					line_texture:SetColorTexture(1, 0, 0, 0.5)
				else
					line_texture:SetColorTexture(0, 0, 0, 0.5)
				end
				line_texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -i * lines_h + 1)
				line_texture:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -i * lines_h - 1)
			end
		end
	end
end

end)