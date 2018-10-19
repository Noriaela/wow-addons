local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule("NamePlates");

--Cache global variables
--Lua functions
local getn = table.getn
--WoW API / Variables
local COLOR, FACTION_STANDING_LABEL4 = COLOR, FACTION_STANDING_LABEL4
local FILTER, FILTERS, GENERAL, HEALTH, HIDE, LEVEL, NAME, NONE = FILTER, FILTERS, GENERAL, HEALTH, HIDE, LEVEL, NAME, NONE

local selectedFilter
local filters

local positionValues = {
	TOPLEFT = "TOPLEFT",
	LEFT = "LEFT",
	BOTTOMLEFT = "BOTTOMLEFT",
	RIGHT = "RIGHT",
	TOPRIGHT = "TOPRIGHT",
	BOTTOMRIGHT = "BOTTOMRIGHT",
	CENTER = "CENTER",
	TOP = "TOP",
	BOTTOM = "BOTTOM"
}

local function UpdateFilterGroup()
	if not selectedFilter or not E.global["nameplates"]["filter"][selectedFilter] then
		E.Options.args.nameplate.args.generalGroup.args.filters.args.filterGroup = nil
		return
	end

	E.Options.args.nameplate.args.generalGroup.args.filters.args.filterGroup = {
		type = "group",
		name = selectedFilter,
		guiInline = true,
		order = -10,
		get = function(info) return E.global["nameplates"]["filter"][selectedFilter][ info[getn(info) ]] end,
		set = function(info, value) E.global["nameplates"]["filter"][selectedFilter][ info[getn(info) ]] = value; NP:ForEachPlate("CheckFilter"); NP:ConfigureAll(); UpdateFilterGroup() end,
		args = {
			enable = {
				type = "toggle",
				order = 1,
				name = L["Enable"],
				desc = L["Use this filter."],
			},
			hide = {
				type = "toggle",
				order = 2,
				name = HIDE,
				desc = L["Prevent any nameplate with this unit name from showing."],
			},
			customColor = {
				type = "toggle",
				order = 3,
				name = L["Custom Color"],
				desc = L["Disable threat coloring for this plate and use the custom color."],
			},
			color = {
				type = "color",
				order = 4,
				name = COLOR,
				get = function(info)
					local t = E.global["nameplates"]["filter"][selectedFilter][ info[getn(info) ]]
					if t then
						return t.r, t.g, t.b, t.a
					end
				end,
				set = function(info, r, g, b)
					E.global["nameplates"]["filter"][selectedFilter][ info[getn(info) ]] = {}
					local t = E.global["nameplates"]["filter"][selectedFilter][ info[getn(info) ]]
					if t then
						t.r, t.g, t.b = r, g, b
						UpdateFilterGroup()
						NP:ForEachPlate("CheckFilter")
						NP:ConfigureAll()
					end
				end
			},
			customScale = {
				type = "range",
				name = L["Custom Scale"],
				desc = L["Set the scale of the nameplate."],
				min = 0.67, max = 2, step = 0.01
			}
		}
	}
end

local ORDER = 100
local function GetUnitSettings(unit, name)
	local copyValues = {}
	for x, y in pairs(NP.db.units) do
		if(type(y) == "table" and x ~= unit) then
			copyValues[x] = L[x]
		end
	end
	local group = {
		order = ORDER,
		type = "group",
		name = name,
		childGroups = "tab",
		get = function(info) return E.db.nameplates.units[unit][ info[getn(info) ]] end,
		set = function(info, value) E.db.nameplates.units[unit][ info[getn(info) ]] = value; NP:ConfigureAll() end,
		args = {
			copySettings = {
				order = -10,
				type = "select",
				name = L["Copy Settings From"],
				desc = L["Copy settings from another unit."],
				values = copyValues,
				get = function() return "" end,
				set = function(info, value)
					NP:CopySettings(value, unit)
					NP:ConfigureAll()
				end
			},
			defaultSettings = {
				order = -9,
				type = "execute",
				name = L["Default Settings"],
				desc = L["Set Settings to Default"],
				func = function(info, value)
					NP:ResetSettings(unit)
					NP:ConfigureAll()
				end
			},
			healthGroup = {
				order = 1,
				name = HEALTH,
				type = "group",
				get = function(info) return E.db.nameplates.units[unit].healthbar[ info[getn(info) ]] end,
				set = function(info, value) E.db.nameplates.units[unit].healthbar[ info[getn(info) ]] = value; NP:ConfigureAll() end,
				args = {
					header = {
						order = 0,
						type = "header",
						name = HEALTH
					},
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"]
					},
					height = {
						order = 2,
						type = "range",
						name = L["Height"],
						min = 4, max = 20, step = 1
					},
					width = {
						order = 3,
						type = "range",
						name = L["Width"],
						min = 50, max = 200, step = 1
					},
					textGroup = {
						order = 100,
						type = "group",
						name = L["Text"],
						guiInline = true,
						get = function(info) return E.db.nameplates.units[unit].healthbar.text[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].healthbar.text[ info[getn(info) ]] = value; NP:ConfigureAll() end,
						args = {
							enable = {
								order = 1,
								type = "toggle",
								name = L["Enable"]
							},
							format = {
								order = 2,
								name = L["Format"],
								type = "select",
								values = {
									["CURRENT"] = L["Current"],
									["CURRENT_MAX"] = L["Current / Max"],
									["CURRENT_PERCENT"] = L["Current - Percent"],
									["CURRENT_MAX_PERCENT"] = L["Current - Max | Percent"],
									["PERCENT"] = L["Percent"],
									["DEFICIT"] = L["Deficit"]
								}
							}
						}
					}
				}
			},
			castGroup = {
				order = 3,
				name = L["Cast Bar"],
				type = "group",
				get = function(info) return E.db.nameplates.units[unit].castbar[ info[getn(info) ]] end,
				set = function(info, value) E.db.nameplates.units[unit].castbar[ info[getn(info) ]] = value; NP:ConfigureAll() end,
				args = {
					header = {
						order = 0,
						type = "header",
						name = L["Cast Bar"]
					},
					enable = {
						order = 1,
						name = L["Enable"],
						type = "toggle",
					},
					hideSpellName = {
						order = 2,
						type = "toggle",
						name = L["Hide Spell Name"]
					},
					hideTime = {
						order = 3,
						type = "toggle",
						name = L["Hide Time"]
					},
					height = {
						order = 4,
						type = "range",
						name = L["Height"],
						min = 4, max = 20, step = 1
					},
					offset = {
						order = 5,
						type = "range",
						name = L["Offset"],
						min = 0, max = 30, step = 1
					},
					castTimeFormat = {
						order = 6,
						type = "select",
						name = L["Cast Time Format"],
						values = {
							["CURRENT"] = L["Current"],
							["CURRENT_MAX"] = L["Current / Max"],
							["REMAINING"] = L["Remaining"]
						}
					},
					channelTimeFormat = {
						order = 7,
						type = "select",
						name = L["Channel Time Format"],
						values = {
							["CURRENT"] = L["Current"],
							["CURRENT_MAX"] = L["Current / Max"],
							["REMAINING"] = L["Remaining"]
						}
					},
					timeToHold = {
						order = 8,
						type = "range",
						name = L["Time To Hold"],
						desc = L["How many seconds the castbar should stay visible after the cast failed or was interrupted."],
						min = 0, max = 4, step = 0.1
					}
				}
			},
			buffsGroup = {
				order = 4,
				name = L["Buffs"],
				type = "group",
				get = function(info) return E.db.nameplates.units[unit].buffs.filters[ info[getn(info) ]] end,
				set = function(info, value) E.db.nameplates.units[unit].buffs.filters[ info[getn(info) ]] = value; NP:ConfigureAll() end,
				disabled = function() return not E.db.nameplates.units[unit].healthbar.enable end,
				args = {
					header = {
						order = 0,
						type = "header",
						name = L["Buffs"]
					},
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
						get = function(info) return E.db.nameplates.units[unit].buffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].buffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					numAuras = {
						order = 2,
						type = "range",
						name = L["# Displayed Auras"],
						desc = L["Controls how many auras are displayed, this will also affect the size of the auras."],
						min = 1, max = 8, step = 1,
						get = function(info) return E.db.nameplates.units[unit].buffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].buffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					baseHeight = {
						order = 3,
						type = "range",
						name = L["Icon Base Height"],
						desc = L["Base Height for the Aura Icon"],
						min = 6, max = 60, step = 1,
						get = function(info) return E.db.nameplates.units[unit].buffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].buffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					filtersGroup = {
						name = FILTERS,
						order = 4,
						type = "group",
						guiInline = true,
						args = {
							personal = {
								order = 1,
								type = "toggle",
								name = L["Personal Auras"]
							},
							maxDuration = {
								order = 2,
								type = "range",
								name = L["Maximum Duration"],
								min = 5, max = 3000, step = 1
							},
							filter = {
								order = 3,
								type = "select",
								name = FILTER,
								values = function()
									local filters = {}
									filters[""] = NONE
									for filter in pairs(E.global.unitframe["aurafilters"]) do
										filters[filter] = filter
									end
									return filters
								end
							}
						}
					}
				}
			},
			debuffsGroup = {
				order = 5,
				name = L["Debuffs"],
				type = "group",
				get = function(info) return E.db.nameplates.units[unit].debuffs.filters[ info[getn(info) ]] end,
				set = function(info, value) E.db.nameplates.units[unit].debuffs.filters[ info[getn(info) ]] = value; NP:ConfigureAll() end,
				disabled = function() return not E.db.nameplates.units[unit].healthbar.enable end,
				args = {
					header = {
						order = 0,
						type = "header",
						name = L["Debuffs"]
					},
					enable = {
						order = 1,
						type = "toggle",
						name = L["Enable"],
						get = function(info) return E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					numAuras = {
						order = 2,
						type = "range",
						name = L["# Displayed Auras"],
						desc = L["Controls how many auras are displayed, this will also affect the size of the auras."],
						min = 1, max = 8, step = 1,
						get = function(info) return E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					baseHeight = {
						order = 3,
						type = "range",
						name = L["Icon Base Height"],
						desc = L["Base Height for the Aura Icon"],
						min = 6, max = 60, step = 1,
						get = function(info) return E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] end,
						set = function(info, value) E.db.nameplates.units[unit].debuffs[ info[getn(info) ]] = value; NP:ConfigureAll() end
					},
					filtersGroup = {
						name = FILTERS,
						order = 4,
						type = "group",
						guiInline = true,
						args = {
							personal = {
								order = 1,
								type = "toggle",
								name = L["Personal Auras"]
							},
							maxDuration = {
								order = 2,
								type = "range",
								name = L["Maximum Duration"],
								min = 5, max = 3000, step = 1
							},
							filter = {
								order = 3,
								type = "select",
								name = FILTER,
								values = function()
									local filters = {}
									filters[""] = NONE
									for filter in pairs(E.global.unitframe["aurafilters"]) do
										filters[filter] = filter
									end
									return filters
								end
							}
						}
					}
				}
			},
			levelGroup = {
				order = 6,
				name = LEVEL,
				type = "group",
				args = {
					header = {
						order = 0,
						type = "header",
						name = LEVEL
					},
					enable = {
						order = 1,
						name = L["Enable"],
						type = "toggle",
						get = function(info) return E.db.nameplates.units[unit].showLevel end,
						set = function(info, value) E.db.nameplates.units[unit].showLevel = value; NP:ConfigureAll() end
					}
				}
			},
			nameGroup = {
				order = 7,
				name = NAME,
				type = "group",
				get = function(info) return E.db.nameplates.units[unit].name[ info[getn(info) ]] end,
				set = function(info, value) E.db.nameplates.units[unit].name[ info[getn(info) ]] = value; NP:ConfigureAll() end,
				args = {
					header = {
						order = 0,
						type = "header",
						name = NAME
					},
					enable = {
						order = 1,
						name = L["Enable"],
						type = "toggle",
						get = function(info) return E.db.nameplates.units[unit].showName end,
						set = function(info, value) E.db.nameplates.units[unit].showName = value; NP:ConfigureAll() end
					}
				}
			}
		}
	}

	if (unit == "FRIENDLY_PLAYER" or unit == "ENEMY_PLAYER") then
		group.args.healthGroup.args.useClassColor = {
			order = 4,
			type = "toggle",
			name = L["Use Class Color"],
			desc = L["Depends on Class Caching module!"],
			disabled = function() return not E.private.general.classCache end
		}
		group.args.nameGroup.args.useClassColor = {
			order = 3,
			type = "toggle",
			name = L["Use Class Color"],
			desc = L["Depends on Class Caching module!"],
			disabled = function() return not E.private.general.classCache end
		}
	elseif (unit == "ENEMY_NPC" or unit == "FRIENDLY_NPC") then
		group.args.eliteIcon = {
			order = 10,
			name = L["Elite Icon"],
			type = "group",
			get = function(info) return E.db.nameplates.units[unit].eliteIcon[ info[getn(info) ]] end,
			set = function(info, value) E.db.nameplates.units[unit].eliteIcon[ info[getn(info) ]] = value; NP:ConfigureAll() end,
			args = {
				header = {
					order = 0,
					type = "header",
					name = L["Elite Icon"]
				},
				enable = {
					order = 1,
					type = "toggle",
					name = L["Enable"]
				},
				position = {
					order = 2,
					type = "select",
					name = L["Position"],
					values = {
						["LEFT"] = L["Left"],
						["RIGHT"] = L["Right"],
						["TOP"] = L["Top"],
						["BOTTOM"] = L["Bottom"],
						["CENTER"] = L["Center"]
					}
				},
				size = {
					order = 3,
					type = "range",
					name = L["Size"],
					min = 12, max = 42, step = 1
				},
				xOffset = {
					order = 4,
					type = "range",
					name = L["X-Offset"],
					min = -100, max = 100, step = 1
				},
				yOffset = {
					order = 5,
					type = "range",
					name = L["Y-Offset"],
					min = -100, max = 100, step = 1
				}
			}
		}
	end

	ORDER = ORDER + 100
	return group
end

E.Options.args.nameplate = {
	type = "group",
	name = L["Nameplates"],
	childGroups = "tree",
	get = function(info) return E.db.nameplates[ info[getn(info) ]] end,
	set = function(info, value) E.db.nameplates[ info[getn(info) ]] = value; NP:ConfigureAll() end,
	args = {
		enable = {
			order = 1,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.nameplates[ info[getn(info) ]] end,
			set = function(info, value) E.private.nameplates[ info[getn(info) ]] = value; E:StaticPopup_Show("PRIVATE_RL") end
		},
		intro = {
			order = 2,
			type = "description",
			name = L["NAMEPLATE_DESC"]
		},
		header = {
			order = 3,
			type = "header",
			name = L["Shortcuts"]
		},
		spacer1 = {
			order = 4,
			type = "description",
			name = " ",
		},
		generalShortcut = {
			order = 5,
			type = "execute",
			name = L["General"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "generalGroup", "general") end,
			disabled = function() return not E.NamePlates; end,
		},
		fontsShortcut = {
			order = 6,
			type = "execute",
			name = L["Fonts"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "generalGroup", "fontGroup") end,
			disabled = function() return not E.NamePlates; end,
		},
		spacer2 = {
			order = 7,
			type = "description",
			name = " ",
		},
		friendlyPlayerShortcut = {
			order = 8,
			type = "execute",
			name = L["Friendly Player Frames"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "friendlyPlayerGroup") end,
			disabled = function() return not E.NamePlates; end,
		},
		enemyPlayerShortcut = {
			order = 9,
			type = "execute",
			name = L["Enemy Player Frames"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "enemyPlayerGroup") end,
			disabled = function() return not E.NamePlates; end,
		},
		spacer5 = {
			order = 10,
			type = "description",
			name = " ",
		},
		friendlyNPCShortcut = {
			order = 11,
			type = "execute",
			name = L["Friendly NPC Frames"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "friendlyNPCGroup") end,
			disabled = function() return not E.NamePlates; end,
		},
		enemyNPCShortcut = {
			order = 12,
			type = "execute",
			name = L["Enemy NPC Frames"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "enemyNPCGroup") end,
			disabled = function() return not E.NamePlates; end,
		},
--[[		filtersShortcut = {
			order = 13,
			type = "execute",
			name = L["Style Filter"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "nameplate", "filters") end,
			disabled = function() return not E.NamePlates; end,
		},]]
		generalGroup = {
			order = 14,
			type = "group",
			name = GENERAL,
			childGroups = "tab",
			disabled = function() return not E.NamePlates end,
			args = {
				general = {
					order = 1,
					type = "group",
					name = GENERAL,
					args = {
						statusbar = {
							order = 0,
							type = "select",
							dialogControl = "LSM30_Statusbar",
							name = L["StatusBar Texture"],
							values = AceGUIWidgetLSMlists.statusbar
						},
						motionType = {
							order = 1,
							type = "select",
							name = "UNIT_NAMEPLATES_TYPES",
							desc = L["Set to either stack nameplates vertically or allow them to overlap."],
							values = {
								["STACKED"] = "STACKED",
								["OVERLAP"] = "OVERLAP"
							},
							set = function(info, value) E.db.nameplates.motionType = value; E:StaticPopup_Show("CONFIG_RL") end,
						},
						lowHealthThreshold = {
							order = 2,
							name = L["Low Health Threshold"],
							desc = L["Make the unitframe glow yellow when it is below this percent of health, it will glow red when the health value is half of this value."],
							type = "range",
							isPercent = true,
							min = 0, max = 1, step = 0.01
						},
						showEnemyCombat = {
							order = 10,
							type = "select",
							name = L["Enemy Combat Toggle"],
							desc = L["Control enemy nameplates toggling on or off when in combat."],
							values = {
								["DISABLED"] = L["Disabled"],
								["TOGGLE_ON"] = L["Toggle On While In Combat"],
								["TOGGLE_OFF"] = L["Toggle Off While In Combat"],
							},
							set = function(info, value)
								E.db.nameplates[ info[getn(info) ]] = value
								NP:PLAYER_REGEN_ENABLED()
							end,
						},
						showFriendlyCombat = {
							order = 11,
							type = "select",
							name = L["Friendly Combat Toggle"],
							desc = L["Control friendly nameplates toggling on or off when in combat."],
							values = {
								["DISABLED"] = L["Disabled"],
								["TOGGLE_ON"] = L["Toggle On While In Combat"],
								["TOGGLE_OFF"] = L["Toggle Off While In Combat"],
							},
							set = function(info, value)
								E.db.nameplates[ info[getn(info) ]] = value
								NP:PLAYER_REGEN_ENABLED()
							end
						},
						clickableWidth = {
							order = 10,
							type = "range",
							name = L["Clickable Width"],
							desc = L["Controls how big of an area on the screen will accept clicks to target unit."],
							min = 50, max = 200, step = 1,
							set = function(info, value) E.db.nameplates.clickableWidth = value; E:StaticPopup_Show("CONFIG_RL") end,
						},
						clickableHeight = {
							order = 11,
							type = "range",
							name = L["Clickable Height"],
							desc = L["Controls how big of an area on the screen will accept clicks to target unit."],
							min = 10, max = 75, step = 1,
							set = function(info, value) E.db.nameplates.clickableHeight = value; E:StaticPopup_Show("CONFIG_RL") end,
						},
						resetFilters = {
							order = 12,
							name = L["Reset Aura Filters"],
							type = "execute",
							func = function(info)
								E:StaticPopup_Show("RESET_NP_AF") --reset nameplate aurafilters
							end,
						},
						nameColoredGlow = {
							order = 13,
							type = "toggle",
							name = L["Name Colored Glow"],
							desc = L["Use the Name Color of the unit for the Name Glow."],
						},
						comboPoints = {
  							order = 12,
							type = "toggle",
							name = L["Combobar"]
						},
						targetedNamePlate = {
							order = 14,
							type = "group",
							guiInline = true,
							name = L["Targeted Nameplate"],
							get = function(info) return E.db.nameplates[ info[getn(info)] ] end,
							set = function(info, value) E.db.nameplates[ info[getn(info)] ] = value; NP:ConfigureAll() end,
							args = {
								useTargetScale = {
									order = 1,
									type = "toggle",
									name = L["Use Target Scale"],
									desc = L["Enable/Disable the scaling of targetted nameplates."],
								},
								targetScale = {
									order = 2,
									type = "range",
									isPercent = true,
									name = L["Target Scale"],
									desc = L["Scale of the nameplate that is targetted."],
									min = 0.3, max = 2, step = 0.01,
									disabled = function() return E.db.nameplates.useTargetScale ~= true end,
								},
								nonTargetTransparency = {
									order = 3,
									type = "range",
									isPercent = true,
									name = L["Non-Target Transparency"],
									desc = L["Set the transparency level of nameplates that are not the target nameplate."],
									min = 0, max = 1, step = 0.01,
								},
								spacer1 = {
									order = 4,
									type = 'description',
									name = ' ',
								},
								glowColor = {
									name = L["Target Indicator Color"],
									type = 'color',
									order = 5,
									hasAlpha = true,
									get = function(info)
										local t = E.db.nameplates.glowColor
										local d = P.nameplates.glowColor
										return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
									end,
									set = function(info, r, g, b, a)
										local t = E.db.nameplates.glowColor
										t.r, t.g, t.b, t.a = r, g, b, a
										NP:ConfigureAll()
									end,
								},
								targetGlow = {
									order = 6,
									type = "select",
									--customWidth = 225,
									name = L["Target Indicator"],
									get = function(info) return E.db.nameplates.targetGlow end,
									set = function(info, value) E.db.nameplates.targetGlow = value; NP:ConfigureAll() end,
									values = {
										['none'] = NONE,
										['style1'] = L["Border Glow"],
										['style2'] = L["Background Glow"],
										['style3'] = L["Top Arrow"],
										['style4'] = L["Side Arrows"],
										['style5'] = L["Border Glow"].." + "..L["Top Arrow"],
										['style6'] = L["Background Glow"].." + "..L["Top Arrow"],
										['style7'] = L["Border Glow"].." + "..L["Side Arrows"],
										['style8'] = L["Background Glow"].." + "..L["Side Arrows"],
									},
								},
								alwaysShowTargetHealth = {
									order = 7,
									type = "toggle",
									name = L["Always Show Target Health"],
								--	customWidth = 200,
								},
							},
						},
						clickThrough = {
							order = 15,
							type = "group",
							guiInline = true,
							name = L["Click Through"],
							get = function(info) return E.db.nameplates.clickThrough[ info[getn(info)] ] end,
							set = function(info, value) E.db.nameplates.clickThrough[ info[getn(info)] ] = value; NP:ConfigureAll() end,
							args = {
								friendly = {
									order = 2,
									type = "toggle",
									name = L["Friendly"],
								},
								enemy = {
									order = 3,
									type = "toggle",
									name = L["Enemy"],
								},
							},
						},
					},
				},
				fontGroup = {
					order = 100,
					type = "group",
					name = L["Fonts"],
					args = {
						font = {
							order = 4,
							type = "select", dialogControl = "LSM30_Font",
							name = L["Font"],
							values = AceGUIWidgetLSMlists.font
						},
						fontSize = {
							order = 5,
							type = "range",
							name = FONT_SIZE,
							min = 4, max = 34, step = 1,
						},
						fontOutline = {
							order = 6,
							type = "select",
							name = L["Font Outline"],
							desc = L["Set the font outline."],
							values = {
								["NONE"] = NONE,
								["OUTLINE"] = "OUTLINE",
								["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
								["THICKOUTLINE"] = "THICKOUTLINE"
							}
						}
					}
				},
				threatGroup = {
					order = 150,
					type = "group",
					name = L["Threat"],
					-- TODO
					hidden = true,
					get = function(info)
						local t = E.db.nameplates.threat[ info[getn(info) ]]
						local d = P.nameplates.threat[ info[getn(info) ]]
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.nameplates.threat[ info[getn(info) ]]
						t.r, t.g, t.b = r, g, b
					end,
					args = {
						useThreatColor = {
							order = 1,
							type = "toggle",
							name = L["Use Threat Color"],
							get = function(info) return E.db.nameplates.threat.useThreatColor end,
							set = function(info, value) E.db.nameplates.threat.useThreatColor = value end
						},
						goodColor = {
							order = 2,
							type = "color",
							name = L["Good Color"],
							hasAlpha = false,
							disabled = function() return not E.db.nameplates.threat.useThreatColor end
						},
						badColor = {
							order = 3,
							type = "color",
							name = L["Bad Color"],
							hasAlpha = false,
							disabled = function() return not E.db.nameplates.threat.useThreatColor end
						},
						goodTransition = {
							order = 4,
							type = "color",
							name = L["Good Transition Color"],
							hasAlpha = false,
							disabled = function() return not E.db.nameplates.threat.useThreatColor end
						},
						badTransition = {
							order = 5,
							type = "color",
							name = L["Bad Transition Color"],
							hasAlpha = false,
							disabled = function() return not E.db.nameplates.threat.useThreatColor end
						},
						beingTankedByTank = {
							order = 6,
							type = "toggle",
							name = L["Color Tanked"],
							desc = L["Use Tanked Color when a nameplate is being effectively tanked by another tank."],
							get = function(info) return E.db.nameplates.threat[ info[getn(info) ]] end,
							set = function(info, value) E.db.nameplates.threat[ info[getn(info) ]] = value end,
							disabled = function() return not E.db.nameplates.threat.useThreatColor end
						},
						beingTankedByTankColor = {
							order = 7,
							type = "color",
							name = L["Tanked Color"],
							hasAlpha = false,
							disabled = function() return (not E.db.nameplates.threat.beingTankedByTank or not E.db.nameplates.threat.useThreatColor) end
						},
						goodScale = {
							order = 8,
							type = "range",
							name = L["Good Scale"],
							get = function(info) return E.db.nameplates.threat[ info[getn(info) ]] end,
							set = function(info, value) E.db.nameplates.threat[ info[getn(info) ]] = value end,
							min = 0.3, max = 2, step = 0.01,
							isPercent = true
						},
						badScale = {
							order = 9,
							type = "range",
							name = L["Bad Scale"],
							get = function(info) return E.db.nameplates.threat[ info[getn(info) ]] end,
							set = function(info, value) E.db.nameplates.threat[ info[getn(info) ]] = value end,
							min = 0.3, max = 2, step = 0.01,
							isPercent = true
						}
					}
				},
				castGroup = {
					order = 175,
					type = "group",
					name = L["Cast Bar"],
					get = function(info)
						local t = E.db.nameplates[ info[getn(info) ]]
						local d = P.nameplates[ info[getn(info) ]]
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.nameplates[ info[getn(info) ]]
						t.r, t.g, t.b = r, g, b
						NP:ForEachPlate("ConfigureElement_CastBar")
					end,
					args = {
						castColor = {
							order = 1,
							type = "color",
							name = L["Cast Color"],
							hasAlpha = false
						}
					}
				},
				reactions = {
					order = 200,
					type = "group",
					name = L["Reaction Colors"],
					get = function(info)
						local t = E.db.nameplates.reactions[ info[getn(info) ]]
						local d = P.nameplates.reactions[ info[getn(info) ]]
						return t.r, t.g, t.b, t.a, d.r, d.g, d.b
					end,
					set = function(info, r, g, b)
						local t = E.db.nameplates.reactions[ info[getn(info) ]]
						t.r, t.g, t.b = r, g, b
						NP:ConfigureAll()
					end,
					args = {
						bad = {
							order = 1,
							type = "color",
							name = L["Enemy"],
							hasAlpha = false
						},
						neutral = {
							order = 2,
							type = "color",
							name = FACTION_STANDING_LABEL4,
							hasAlpha = false
						},
						good = {
							order = 3,
							type = "color",
							name = L["Friendly NPC"],
							hasAlpha = false
						},
						tapped = {
							order = 4,
							type = "color",
							name = L["Tagged NPC"],
							hasAlpha = false
						},
						friendlyPlayer = {
							order = 5,
							type = "color",
							name = L["Friendly Player"],
							hasAlpha = false
						}
					}
				},
				filters = {
					order = 300,
					type = "group",
					name = FILTERS,
					args = {
						addname = {
							order = 2,
							type = "input",
							name = L["Add Name"],
							get = function(info) return "" end,
							set = function(info, value)
								if E.global["nameplates"]["filter"][value] then
									E:Print(L["Filter already exists!"])
									return
								end

								E.global["nameplates"]["filter"][value] = {
									["enable"] = true,
									["hide"] = false,
									["customColor"] = false,
									["customScale"] = 1,
									["color"] = {r = 104/255, g = 138/255, b = 217/255}
								}
								UpdateFilterGroup()
								NP:ConfigureAll()
							end
						},
						deletename = {
							order = 3,
							type = "input",
							name = L["Remove Name"],
							get = function(info) return "" end,
							set = function(info, value)
								if G["nameplates"]["filter"][value] then
									E.global["nameplates"]["filter"][value].enable = false
									E:Print(L["You can't remove a default name from the filter, disabling the name."])
								else
									E.global["nameplates"]["filter"][value] = nil
									E.Options.args.nameplates.args.filters.args.filterGroup = nil
								end
								UpdateFilterGroup()
								NP:ConfigureAll()
							end
						},
						selectFilter = {
							order = 3,
							type = "select",
							name = L["Select Filter"],
							get = function(info) return selectedFilter end,
							set = function(info, value) selectedFilter = value; UpdateFilterGroup() end,
							values = function()
								filters = {}
								for filter in pairs(E.global["nameplates"]["filter"]) do
									filters[filter] = filter
								end
								return filters
							end
						}
					}
				}
			}
		},
		friendlyPlayerGroup = GetUnitSettings("FRIENDLY_PLAYER", L["Friendly Player Frames"]),
		enemyPlayerGroup = GetUnitSettings("ENEMY_PLAYER", L["Enemy Player Frames"]),
		friendlyNPCGroup = GetUnitSettings("FRIENDLY_NPC", L["Friendly NPC Frames"]),
		enemyNPCGroup = GetUnitSettings("ENEMY_NPC", L["Enemy NPC Frames"])
	}
}