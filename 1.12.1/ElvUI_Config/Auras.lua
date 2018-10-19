local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local A = E:GetModule("Auras");

--Cache global variables
--Lua functions
local format = string.format
local getn = table.getn
--WoW API / Variables
local FONT_SIZE, GENERAL, NAME, NONE = FONT_SIZE, GENERAL, NAME, NONE

local function GetAuraOptions(headerName)
	local auraOptions = {
		header = {
			order = 0,
			type = "header",
			name = headerName
		},
		size = {
			order = 1,
			type = "range",
			name = L["Size"],
			desc = L["Set the size of the individual auras."],
			min = 16, max = 60, step = 2
		},
		growthDirection = {
			order = 2,
			type = "select",
			name = L["Growth Direction"],
			desc = L["The direction the auras will grow and then the direction they will grow after they reach the wrap after limit."],
			values = {
				DOWN_RIGHT = format(L["%s and then %s"], L["Down"], L["Right"]),
				DOWN_LEFT = format(L["%s and then %s"], L["Down"], L["Left"]),
				UP_RIGHT = format(L["%s and then %s"], L["Up"], L["Right"]),
				UP_LEFT = format(L["%s and then %s"], L["Up"], L["Left"]),
				RIGHT_DOWN = format(L["%s and then %s"], L["Right"], L["Down"]),
				RIGHT_UP = format(L["%s and then %s"], L["Right"], L["Up"]),
				LEFT_DOWN = format(L["%s and then %s"], L["Left"], L["Down"]),
				LEFT_UP = format(L["%s and then %s"], L["Left"], L["Up"])
			}
		},
		wrapAfter = {
			order = 3,
			type = "range",
			name = L["Wrap After"],
			desc = L["Begin a new row or column after this many auras."],
			min = 1, max = 32, step = 1
		},
		maxWraps = {
			order = 4,
			type = "range",
			name = L["Max Wraps"],
			desc = L["Limit the number of rows or columns."],
			min = 1, max = 32, step = 1
		},
		horizontalSpacing = {
			order = 5,
			type = "range",
			name = L["Horizontal Spacing"],
			min = 0, max = 50, step = 1
		},
		verticalSpacing = {
			order = 6,
			type = "range",
			name = L["Vertical Spacing"],
			min = 0, max = 50, step = 1
		},
		sortMethod = {
			order = 7,
			type = "select",
			name = L["Sort Method"],
			desc = L["Defines how the group is sorted."],
			values = {
				["INDEX"] = L["Index"],
				["TIME"] = L["Time"],
				["NAME"] = NAME
			}
		},
		sortDir = {
			order = 8,
			type = "select",
			name = L["Sort Direction"],
			desc = L["Defines the sort order of the selected sort method."],
			values = {
				["+"] = L["Ascending"],
				["-"] = L["Descending"]
			}
		},
		seperateOwn = {
			order = 9,
			type = "select",
			name = L["Seperate"],
			desc = L["Indicate whether buffs you cast yourself should be separated before or after."],
			values = {
				[-1] = L["Other's First"],
				[0] = L["No Sorting"],
				[1] = L["Your Auras First"]
			}
		}
	}
	return auraOptions
end

E.Options.args.auras = {
	type = "group",
	name = L["Buffs and Debuffs"],
	childGroups = "tab",
	get = function(info) return E.db.auras[ info[getn(info)] ] end,
	set = function(info, value) E.db.auras[ info[getn(info)] ] = value; A:UpdateHeader(ElvUIPlayerBuffs); A:UpdateHeader(ElvUIPlayerDebuffs) end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["AURAS_DESC"]
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.auras[ info[getn(info)] ] end,
			set = function(info, value)
				E.private.auras[ info[getn(info)] ] = value
				E:StaticPopup_Show("PRIVATE_RL")
			end,
		},
		disableBlizzard = {
			order = 3,
			type = "toggle",
			name = L["Disabled Blizzard"],
			get = function(info) return E.private.auras[ info[getn(info)] ] end,
			set = function(info, value)
				E.private.auras[ info[getn(info)] ] = value
				E:StaticPopup_Show("PRIVATE_RL")
			end
		},
		general = {
			order = 4,
			type = "group",
			name = GENERAL,
			args = {
				header = {
					order = 0,
					type = "header",
					name = GENERAL
				},
				fadeThreshold = {
					order = 1,
					type = "range",
					name = L["Fade Threshold"],
					desc = L["Threshold before text changes red, goes into decimal form, and the icon will fade. Set to -1 to disable."],
					min = -1, max = 30, step = 1
				},
				font = {
					order = 2,
					type = "select", dialogControl = "LSM30_Font",
					name = L["Font"],
					values = AceGUIWidgetLSMlists.font
				},
				fontSize = {
					order = 3,
					name = FONT_SIZE,
					type = "range",
					min = 6, max = 33, step = 1
				},
				fontOutline = {
					order = 4,
					name = L["Font Outline"],
					desc = L["Set the font outline."],
					type = "select",
					values = {
						["NONE"] = NONE,
						["OUTLINE"] = "OUTLINE",
						["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
						["THICKOUTLINE"] = "THICKOUTLINE"
					}
				},
				timeXOffset = {
					order = 5,
					type = "range",
					name = L["Time xOffset"],
					min = -60, max = 60, step = 1
				},
				timeYOffset = {
					order = 6,
					type = "range",
					name = L["Time yOffset"],
					min = -60, max = 60, step = 1
				},
				countXOffset = {
					order = 7,
					type = "range",
					name = L["Count xOffset"],
					min = -60, max = 60, step = 1
				},
				countYOffset = {
					order = 8,
					name = L["Count yOffset"],
					type = "range",
					min = -60, max = 60, step = 1
				},
				lbf = {
					order = 9,
					type = "group",
					guiInline = true,
					name = L["LBF Support"],
					get = function(info) return E.private.auras.lbf[info[getn(info)]] end,
					set = function(info, value) E.private.auras.lbf[info[getn(info)]] = value; E:StaticPopup_Show("PRIVATE_RL") end,
					disabled = function() return not E.private.auras.enable end,
					args = {
						enable = {
							order = 1,
							type = "toggle",
							name = L["Enable"],
							desc = L["Allow LBF to handle the skinning of this element."]
						}
					}
				}
			}
		},
		buffs = {
			order = 5,
			type = "group",
			name = L["Buffs"],
			get = function(info) return E.db.auras.buffs[ info[getn(info)] ] end,
			set = function(info, value) E.db.auras.buffs[ info[getn(info)] ] = value; A:UpdateHeader(ElvUIPlayerBuffs) end,
			args = GetAuraOptions(L["Buffs"])
		},
		debuffs = {
			order = 6,
			type = "group",
			name = L["Debuffs"],
			get = function(info) return E.db.auras.debuffs[ info[getn(info)] ] end,
			set = function(info, value) E.db.auras.debuffs[ info[getn(info)] ] = value; A:UpdateHeader(ElvUIPlayerDebuffs) end,
			args = GetAuraOptions(L["Debuffs"])
		}
	}
}