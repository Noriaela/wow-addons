﻿local E, L, V, P, G = unpack(ElvUI)
local AB = E:GetModule("ActionBars")
local ACD = E.Libs.AceConfigDialog
local group

local _G = _G
local pairs = pairs

local SetCVar = SetCVar
local GameTooltip = _G["GameTooltip"]
local FONT_SIZE = FONT_SIZE
local NONE, COLOR, COLORS = NONE, COLOR, COLORS
local SHIFT_KEY, ALT_KEY, CTRL_KEY = SHIFT_KEY, ALT_KEY, CTRL_KEY
local OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN = OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN
local LOCK_ACTIONBAR_TEXT = LOCK_ACTIONBAR_TEXT
local PICKUP_ACTION_KEY_TEXT = PICKUP_ACTION_KEY_TEXT

local points = {
	["TOPLEFT"] = "TOPLEFT",
	["TOPRIGHT"] = "TOPRIGHT",
	["BOTTOMLEFT"] = "BOTTOMLEFT",
	["BOTTOMRIGHT"] = "BOTTOMRIGHT",
}

local function BuildABConfig()
	group["general"] = {
		order = 1,
		type = "group",
		name = L["General Options"],
		childGroups = "tab",
		disabled = function() return not E.ActionBars end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["General Options"]
			},
			toggleKeybind = {
				order = 2,
				type = "execute",
				name = L["Keybind Mode"],
				func = function() AB:ActivateBindMode() E:ToggleConfig() GameTooltip:Hide() end
			},
			spacer = {
				order = 3,
				type = "description",
				name = ""
			},
			macrotext = {
				order = 4,
				type = "toggle",
				name = L["Macro Text"],
				desc = L["Display macro names on action buttons."]
			},
			hotkeytext = {
				order = 5,
				type = "toggle",
				name = L["Keybind Text"],
				desc = L["Display bind names on action buttons."]
			},
			useRangeColorText = {
				order = 6,
				type = "toggle",
				name = L["Color Keybind Text"],
				desc = L["Color Keybind Text when Out of Range, instead of the button."],
			},
			rightClickSelfCast = {
				order = 7,
				type = "toggle",
				name = L["RightClick Self-Cast"],
				set = function(info, value)
					E.db.actionbar.rightClickSelfCast = value
					for _, bar in pairs(AB.handledBars) do
						AB:UpdateButtonConfig(bar, bar.bindButtons)
					end
				end
			},
			keyDown = {
				order = 8,
				type = "toggle",
				name = L["Key Down"],
				desc = OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN
			},
			lockActionBars = {
				order = 9,
				type = "toggle",
				name = LOCK_ACTIONBAR_TEXT,
				desc = L["If you unlock actionbars then trying to move a spell might instantly cast it if you cast spells on key press instead of key release."],
				set = function(info, value)
					E.db.actionbar[ info[#info] ] = value
					AB:UpdateButtonSettings()
					SetCVar("lockActionBars", (value == true and 1 or 0))
					LOCK_ACTIONBAR = (value == true and "1" or "0")
				end
			},
			addNewSpells = {
				order = 10,
				type = "toggle",
				name = L["Auto Add New Spells"],
				desc = L["Allow newly learned spells to be automatically placed on an empty actionbar slot."],
				set = function(info, value) E.db.actionbar.addNewSpells = value AB:IconIntroTracker_Toggle() end
			},
			desaturateOnCooldown = {
				order = 11,
				type = "toggle",
				name = L["Desaturate On Cooldown"],
				set = function(info, value)
					E.db.actionbar.desaturateOnCooldown = value
					AB:ToggleDesaturation(value)
				end
			},
			movementModifier = {
				order = 12,
				type = "select",
				name = PICKUP_ACTION_KEY_TEXT,
				desc = L["The button you must hold down in order to drag an ability to another action button."],
				disabled = function() return (not E.private.actionbar.enable or not E.db.actionbar.lockActionBars) end,
				values = {
					["NONE"] = NONE,
					["SHIFT"] = SHIFT_KEY,
					["ALT"] = ALT_KEY,
					["CTRL"] = CTRL_KEY
				}
			},
			globalFadeAlpha = {
				order = 13,
				type = "range",
				name = L["Global Fade Transparency"],
				desc = L["Transparency level when not in combat, no target exists, full health, not casting, and no focus target exists."],
				min = 0, max = 1, step = 0.01,
				isPercent = true,
				set = function(info, value) E.db.actionbar[ info[#info] ] = value AB.fadeParent:SetAlpha(1-value) end
			},
			colorGroup = {
				order = 14,
				type = "group",
				name = COLORS,
				guiInline = true,
				get = function(info)
					local t = E.db.actionbar[ info[#info] ]
					local d = P.actionbar[info[#info]]
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					local t = E.db.actionbar[ info[#info] ]
					t.r, t.g, t.b = r, g, b
					AB:UpdateButtonSettings()
				end,
				args = {
					noRangeColor = {
						order = 1,
						type = "color",
						name = L["Out of Range"],
						desc = L["Color of the actionbutton when out of range."]
					},
					noPowerColor = {
						order = 2,
						type = "color",
						name = L["Out of Power"],
						desc = L["Color of the actionbutton when out of power (Mana, Rage, Focus, Holy Power)."]
					},
					usableColor = {
						order = 3,
						type = "color",
						name = L["Usable"],
						desc = L["Color of the actionbutton when usable."]
					},
					notUsableColor = {
						order = 4,
						type = "color",
						name = L["Not Usable"],
						desc = L["Color of the actionbutton when not usable."]
					}
				}
			},
			fontGroup = {
				order = 15,
				type = "group",
				guiInline = true,
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
						min = 4, max = 32, step = 1
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
					},
					fontColor = {
						order = 7,
						type = "color",
						name = COLOR,
						get = function(info)
							local t = E.db.actionbar[ info[#info] ]
							local d = P.actionbar[info[#info]]
							return t.r, t.g, t.b, t.a, d.r, d.g, d.b
						end,
						set = function(info, r, g, b)
							local t = E.db.actionbar[ info[#info] ]
							t.r, t.g, t.b = r, g, b
							AB:UpdateButtonSettings()
						end
					},
					textPosition = {
						order = 8,
						type = "group",
						name = L["Text Position"],
						guiInline = true,
						args = {
							countTextPosition = {
								order = 1,
								type = "select",
								name = L["Stack Text Position"],
								values = {
									["BOTTOMRIGHT"] = "BOTTOMRIGHT",
									["BOTTOMLEFT"] = "BOTTOMLEFT",
									["TOPRIGHT"] = "TOPRIGHT",
									["TOPLEFT"] = "TOPLEFT",
									["BOTTOM"] = "BOTTOM",
									["TOP"] = "TOP"
								}
							},
							countTextXOffset = {
								order = 2,
								type = "range",
								name = L["Stack Text X-Offset"],
								min = -10, max = 10, step = 1
							},
							countTextYOffset = {
								order = 3,
								type = "range",
								name = L["Stack Text Y-Offset"],
								min = -10, max = 10, step = 1
							},
							hotkeyTextPosition  = {
								order = 4,
								type = "select",
								name = L["Hotkey Text Position"],
								values = {
									["BOTTOMRIGHT"] = "BOTTOMRIGHT",
									["BOTTOMLEFT"] = "BOTTOMLEFT",
									["TOPRIGHT"] = "TOPRIGHT",
									["TOPLEFT"] = "TOPLEFT",
									["BOTTOM"] = "BOTTOM",
									["TOP"] = "TOP"
								}
							},
							hotkeyTextXOffset = {
								order = 5,
								type = "range",
								name = L["Hotkey Text X-Offset"],
								min = -10, max = 10, step = 1
							},
							hotkeyTextYOffset = {
								order = 6,
								type = "range",
								name = L["Hotkey Text Y-Offset"],
								min = -10, max = 10, step = 1
							}
						}
					}
				}
			},
			masque = {
				order = 16,
				type = "group",
				guiInline = true,
				name = L["Masque Support"],
				get = function(info) return E.private.actionbar.masque[info[#info]] end,
				set = function(info, value) E.private.actionbar.masque[info[#info]] = value E:StaticPopup_Show("PRIVATE_RL") end,
				args = {
					actionbars = {
						order = 1,
						type = "toggle",
						name = L["ActionBars"],
						desc = L["Allow Masque to handle the skinning of this element."]
					},
					petBar = {
						order = 2,
						type = "toggle",
						name = L["Pet Bar"],
						desc = L["Allow Masque to handle the skinning of this element."]
					},
					stanceBar = {
						order = 3,
						type = "toggle",
						name = L["Stance Bar"],
						desc = L["Allow Masque to handle the skinning of this element."]
					}
				}
			}
		}
	}
	group["barPet"] = {
		order = 2,
		type = "group",
		name = L["Pet Bar"],
		guiInline = false,
		disabled = function() return not E.ActionBars end,
		get = function(info) return E.db.actionbar.barPet[ info[#info] ] end,
		set = function(info, value) E.db.actionbar.barPet[ info[#info] ] = value AB:PositionAndSizeBarPet() end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Pet Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			restorePosition = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				buttonElvUI = true,
				func = function() E:CopyTable(E.db.actionbar.barPet, P.actionbar.barPet) E:ResetMovers("Pet Bar") AB:PositionAndSizeBarPet() end,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			backdrop = {
				order = 5,
				type = "toggle",
				name = L["Backdrop"],
				desc = L["Toggles the display of the actionbars backdrop."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			mouseover = {
				order = 6,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			inheritGlobalFade = {
				order = 7,
				type = "toggle",
				name = L["Inherit Global Fade"],
				desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			point = {
				order = 8,
				type = "select",
				name = L["Anchor Point"],
				desc = L["The first button anchors itself to this point on the bar."],
				values = points,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttons = {
				order = 9,
				type = "range",
				name = L["Buttons"],
				desc = L["The amount of buttons to display."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonsPerRow = {
				order = 10,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonsize = {
				order = 11,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			buttonspacing = {
				order = 12,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 20, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			backdropSpacing = {
				order = 13,
				type = "range",
				name = L["Backdrop Spacing"],
				desc = L["The spacing between the backdrop and the buttons."],
				min = 0, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			heightMult = {
				order = 14,
				type = "range",
				name = L["Height Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			widthMult = {
				order = 15,
				type = "range",
				name = L["Width Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			alpha = {
				order = 16,
				type = "range",
				name = L["Alpha"],
				isPercent = true,
				min = 0, max = 1, step = 0.01,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			},
			visibility = {
				order = 17,
				type = "input",
				name = L["Visibility State"],
				desc = L["This works like a macro, you can run different situations to get the actionbar to show/hide differently.\n Example: '[combat] show;hide'"],
				width = "full",
				multiline = true,
				set = function(info, value)
					if value and value:match("[\n\r]") then
						value = value:gsub("[\n\r]","")
					end
					E.db.actionbar.barPet.visibility = value
					AB:UpdateButtonSettings()
				end,
				disabled = function() return not E.db.actionbar.barPet.enabled end
			}
		}
	}
	group["stanceBar"] = {
		order = 3,
		type = "group",
		name = L["Stance Bar"],
		guiInline = false,
		disabled = function() return not E.ActionBars end,
		get = function(info) return E.db.actionbar.stanceBar[ info[#info] ] end,
		set = function(info, value) E.db.actionbar.stanceBar[ info[#info] ] = value AB:PositionAndSizeBarShapeShift() end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Stance Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"]
			},
			restorePosition = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				buttonElvUI = true,
				func = function() E:CopyTable(E.db.actionbar.stanceBar, P.actionbar.stanceBar) E:ResetMovers(L["Stance Bar"]) AB:PositionAndSizeBarShapeShift() end,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			backdrop = {
				order = 5,
				type = "toggle",
				name = L["Backdrop"],
				desc = L["Toggles the display of the actionbars backdrop."],
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			mouseover = {
				order = 6,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			usePositionOverride = {
				order = 7,
				type = "toggle",
				name = L["Use Position Override"],
				desc = L["When enabled it will use the Anchor Point setting to determine growth direction, otherwise it will be determined by where the bar is positioned."],
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			inheritGlobalFade = {
 				order = 8,
				type = "toggle",
				name = L["Inherit Global Fade"],
				desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			point = {
				order = 9,
				type = "select",
				name = L["Anchor Point"],
				desc = L["The first button anchors itself to this point on the bar."],
				values = {
					["TOPLEFT"] = "TOPLEFT",
					["TOPRIGHT"] = "TOPRIGHT",
					["BOTTOMLEFT"] = "BOTTOMLEFT",
					["BOTTOMRIGHT"] = "BOTTOMRIGHT",
					["BOTTOM"] = "BOTTOM",
					["TOP"] = "TOP"
				},
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			buttons = {
				order = 10,
				type = "range",
				name = L["Buttons"],
				desc = L["The amount of buttons to display."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			buttonsPerRow = {
				order = 11,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			buttonsize = {
				order = 12,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			buttonspacing = {
				order = 13,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			backdropSpacing = {
				order = 14,
				type = "range",
				name = L["Backdrop Spacing"],
				desc = L["The spacing between the backdrop and the buttons."],
				min = 0, max = 10, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			heightMult = {
				order = 15,
				type = "range",
				name = L["Height Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			widthMult = {
				order = 16,
				type = "range",
				name = L["Width Multiplier"],
				desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
				min = 1, max = 5, step = 1,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			alpha = {
				order = 17,
				type = "range",
				name = L["Alpha"],
				isPercent = true,
				min = 0, max = 1, step = 0.01,
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			style = {
				order = 18,
				type = "select",
				name = L["Style"],
				desc = L["This setting will be updated upon changing stances."],
				values = {
					["darkenInactive"] = L["Darken Inactive"],
					["classic"] = L["Classic"]
				},
				disabled = function() return not E.db.actionbar.stanceBar.enabled end
			},
			visibility = {
				order = 19,
				type = "input",
				name = L["Visibility State"],
				desc = L["This works like a macro, you can run different situations to get the actionbar to show/hide differently.\n Example: '[combat] show;hide'"],
				width = "full",
				multiline = true,
				set = function(info, value)
					if value and value:match("[\n\r]") then
						value = value:gsub("[\n\r]","")
					end
					E.db.actionbar.stanceBar.visibility = value
					AB:UpdateButtonSettings()
				end
 			}
		}
	}
	group["microbar"] = {
		order = 5,
		type = "group",
		name = L["Micro Bar"],
		disabled = function() return not E.ActionBars end,
		get = function(info) return E.db.actionbar.microbar[ info[#info] ] end,
		set = function(info, value) E.db.actionbar.microbar[ info[#info] ] = value AB:UpdateMicroPositionDimensions() end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Micro Bar"]
			},
			enabled = {
				order = 2,
				type = "toggle",
				name = L["Enable"],
			},
			restoreMicrobar = {
				order = 3,
				type = "execute",
				name = L["Restore Bar"],
				desc = L["Restore the actionbars default settings"],
				buttonElvUI = true,
				func = function() E:CopyTable(E.db.actionbar.microbar, P.actionbar.microbar) E:ResetMovers(L["Micro Bar"]) AB:UpdateMicroPositionDimensions() end,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			spacer = {
				order = 4,
				type = "description",
				name = " "
			},
			mouseover = {
				order = 5,
				type = "toggle",
				name = L["Mouse Over"],
				desc = L["The frame is not shown unless you mouse over the frame."],
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			buttonSize = {
				order = 6,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			buttonSpacing = {
				order = 7,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 20, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			buttonsPerRow = {
				order = 8,
				type = "range",
				name = L["Buttons Per Row"],
				desc = L["The amount of buttons to display per row."],
				min = 1, max = 12, step = 1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			alpha = {
				order = 9,
				type = "range",
				name = L["Alpha"],
				isPercent = true,
				desc = L["Change the alpha level of the frame."],
				min = 0, max = 1, step = 0.1,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			},
			visibility = {
				order = 10,
				type = "input",
				name = L["Visibility State"],
				desc = L["This works like a macro, you can run different situations to get the actionbar to show/hide differently.\n Example: '[combat] show;hide'"],
				width = "full",
				multiline = true,
				set = function(info, value)
					if value and value:match("[\n\r]") then
						value = value:gsub("[\n\r]","")
					end
					E.db.actionbar.microbar.visibility = value
					AB:UpdateMicroPositionDimensions()
				end,
				disabled = function() return not E.db.actionbar.microbar.enabled end
			}
		}
	}
	group["extraActionButton"] = {
		order = 5,
		type = "group",
		name = L["Boss Button"],
		disabled = function() return not E.ActionBars end,
		get = function(info) return E.db.actionbar.extraActionButton[ info[#info] ] end,
		args = {
			info = {
				order = 1,
				type = "header",
				name = L["Boss Button"]
			},
			alpha = {
				order = 2,
				type = "range",
				name = L["Alpha"],
				desc = L["Change the alpha level of the frame."],
				isPercent = true,
				min = 0, max = 1, step = 0.01,
				set = function(info, value) E.db.actionbar.extraActionButton[ info[#info] ] = value AB:Extra_SetAlpha() end
			},
			scale = {
				order = 3,
				type = "range",
				name = L["Scale"],
				isPercent = true,
				min = 0.2, max = 2, step = 0.01,
				set = function(info, value) E.db.actionbar.extraActionButton[ info[#info] ] = value AB:Extra_SetScale() end
			}
		}
	}
	for i = 1, 6 do
		local name = L["Bar "]..i
		group["bar"..i] = {
			order = 6 + i,
			type = "group",
			name = name,
			guiInline = false,
			disabled = function() return not E.ActionBars end,
			get = function(info) return E.db.actionbar["bar"..i][ info[#info] ] end,
			set = function(info, value) E.db.actionbar["bar"..i][ info[#info] ] = value AB:PositionAndSizeBar("bar"..i) end,
			args = {
				info = {
					order = 1,
					type = "header",
					name = name
				},
				enabled = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					set = function(info, value)
						E.db.actionbar["bar"..i][ info[#info] ] = value
						AB:PositionAndSizeBar("bar"..i)
					end
				},
				restorePosition = {
					order = 3,
					type = "execute",
					name = L["Restore Bar"],
					desc = L["Restore the actionbars default settings"],
					buttonElvUI = true,
					func = function() E:CopyTable(E.db.actionbar["bar"..i], P.actionbar["bar"..i]) E:ResetMovers("Bar "..i) AB:PositionAndSizeBar("bar"..i) end,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				spacer = {
					order = 4,
					type = "description",
					name = " "
				},
				backdrop = {
					order = 5,
					type = "toggle",
					name = L["Backdrop"],
					desc = L["Toggles the display of the actionbars backdrop."],
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				showGrid = {
					order = 6,
					type = "toggle",
					name = L["Show Empty Buttons"],
					set = function(info, value) E.db.actionbar["bar"..i][ info[#info] ] = value AB:UpdateButtonSettingsForBar("bar"..i) end,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				point = {
					order = 5,
					type = "select",
					name = L["Anchor Point"],
					desc = L["The first button anchors itself to this point on the bar."],
					values = points,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				mouseover = {
					order = 7,
					type = "toggle",
					name = L["Mouse Over"],
					desc = L["The frame is not shown unless you mouse over the frame."],
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				inheritGlobalFade = {
					order = 8,
					type = "toggle",
					name = L["Inherit Global Fade"],
					desc = L["Inherit the global fade, mousing over, targetting, setting focus, losing health, entering combat will set the remove transparency. Otherwise it will use the transparency level in the general actionbar settings for global fade alpha."],
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				point = {
					order = 9,
					type = "select",
					name = L["Anchor Point"],
					desc = L["The first button anchors itself to this point on the bar."],
					values = points,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				flyoutDirection = {
					order = 10,
					type = "select",
					name = L["Flyout Direction"],
					set = function(info, value) E.db.actionbar["bar"..i][ info[#info] ] = value AB:PositionAndSizeBar("bar"..i) AB:UpdateButtonSettingsForBar("bar"..i) end,
					values = {
						["UP"] = L["Up"],
						["DOWN"] = L["Down"],
						["LEFT"] = L["Left"],
						["RIGHT"] = L["Right"],
						["AUTOMATIC"] = L["Automatic"]
					},
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				buttons = {
					order = 11,
					type = "range",
					name = L["Buttons"],
					desc = L["The amount of buttons to display."],
					min = 1, max = NUM_ACTIONBAR_BUTTONS, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				buttonsPerRow = {
					order = 12,
					type = "range",
					name = L["Buttons Per Row"],
					desc = L["The amount of buttons to display per row."],
					min = 1, max = NUM_ACTIONBAR_BUTTONS, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				buttonsize = {
					order = 13,
					type = "range",
					name = L["Button Size"],
					desc = L["The size of the action buttons."],
					min = 15, max = 60, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				buttonspacing = {
					order = 14,
					type = "range",
					name = L["Button Spacing"],
					desc = L["The spacing between buttons."],
					min = -1, max = 20, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				backdropSpacing = {
					order = 15,
					type = "range",
					name = L["Backdrop Spacing"],
					desc = L["The spacing between the backdrop and the buttons."],
					min = 0, max = 10, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				heightMult = {
					order = 16,
					type = "range",
					name = L["Height Multiplier"],
					desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
					min = 1, max = 5, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				widthMult = {
					order = 17,
					type = "range",
					name = L["Width Multiplier"],
					desc = L["Multiply the backdrops height or width by this value. This is usefull if you wish to have more than one bar behind a backdrop."],
					min = 1, max = 5, step = 1,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				alpha = {
					order = 18,
					type = "range",
					name = L["Alpha"],
					isPercent = true,
					min = 0, max = 1, step = 0.01,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				paging = {
					order = 19,
					type = "input",
					name = L["Action Paging"],
					desc = L["This works like a macro, you can run different situations to get the actionbar to page differently.\n Example: '[combat] 2;'"],
					width = "full",
					multiline = true,
					get = function(info) return E.db.actionbar["bar"..i].paging[E.myclass] end,
					set = function(info, value)
						if value and value:match("[\n\r]") then
							value = value:gsub("[\n\r]","")
						end

						if not E.db.actionbar["bar"..i].paging[E.myclass] then
							E.db.actionbar["bar"..i].paging[E.myclass] = {}
						end

						E.db.actionbar["bar"..i].paging[E.myclass] = value
						AB:UpdateButtonSettings()
					end,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				},
				visibility = {
					order = 20,
					type = "input",
					name = L["Visibility State"],
					desc = L["This works like a macro, you can run different situations to get the actionbar to show/hide differently.\n Example: '[combat] show;hide'"],
					width = "full",
					multiline = true,
					set = function(info, value)
						if value and value:match("[\n\r]") then
							value = value:gsub("[\n\r]","")
						end
						E.db.actionbar["bar"..i].visibility = value
						AB:UpdateButtonSettings()
					end,
					disabled = function() return not E.db.actionbar["bar"..i].enabled end
				}
			}
		}

		if i == 6 then
			group["bar"..i].args.enabled.set = function(info, value)
				E.db.actionbar["bar"..i].enabled = value
				AB:PositionAndSizeBar("bar6")
				AB:UpdateBar1Paging()
				AB:PositionAndSizeBar("bar1")
			end
		end
	end
end

E.Options.args.actionbar = {
	type = "group",
	name = L["ActionBars"],
	childGroups = "tree",
	get = function(info) return E.db.actionbar[ info[#info] ] end,
	set = function(info, value) E.db.actionbar[ info[#info] ] = value AB:UpdateButtonSettings() end,
	args = {
		enable = {
			order = 1,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.actionbar[ info[#info] ] end,
			set = function(info, value) E.private.actionbar[ info[#info] ] = value E:StaticPopup_Show("PRIVATE_RL") end
		},
		intro = {
			order = 2,
			type = "description",
			name = L["ACTIONBARS_DESC"]
		},
		header = {
			order = 3,
			type = "header",
			name = L["Shortcuts"]
		},
		spacer1 = {
			order = 4,
			type = "description",
			name = " "
		},
		generalShortcut = {
			order = 5,
			type = "execute",
			name = L["General"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "general") end,
			disabled = function() return not E.ActionBars end
		},
		petBarShortcut = {
			order = 6,
			type = "execute",
			name = L["Pet Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "barPet") end,
			disabled = function() return not E.ActionBars end
		},
		stanceBarShortcut = {
			order = 7,
			type = "execute",
			name = L["Stance Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "stanceBar") end,
			disabled = function() return not E.ActionBars end
		},
		spacer2 = {
			order = 8,
			type = "description",
			name = " "
		},
		microbarShortcut = {
			order = 9,
			type = "execute",
			name = L["Micro Bar"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "microbar") end,
			disabled = function() return not E.ActionBars end
		},
		extraActionButtonShortcut = {
			order = 10,
			type = "execute",
			name = L["Boss Button"],
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "extraActionButton") end,
			disabled = function() return not E.ActionBars end
		},
		bar1Shortcut = {
			order = 11,
			type = "execute",
			name = L["Bar "]..1,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar1") end,
			disabled = function() return not E.ActionBars end
		},
		spacer3 = {
			order = 12,
			type = "description",
			name = " "
		},
		bar2Shortcut = {
			order = 13,
			type = "execute",
			name = L["Bar "]..2,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar2") end,
			disabled = function() return not E.ActionBars end
		},
		bar3Shortcut = {
			order = 14,
			type = "execute",
			name = L["Bar "]..3,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar3") end,
			disabled = function() return not E.ActionBars end
		},
		bar4Shortcut = {
			order = 15,
			type = "execute",
			name = L["Bar "]..4,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar4") end,
			disabled = function() return not E.ActionBars end
		},
		spacer4 = {
			order = 16,
			type = "description",
			name = " "
		},
		bar5Shortcut = {
			order = 17,
			type = "execute",
			name = L["Bar "]..5,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar5") end,
			disabled = function() return not E.ActionBars end
		},
		bar6Shortcut = {
			order = 18,
			type = "execute",
			name = L["Bar "]..6,
			buttonElvUI = true,
			func = function() ACD:SelectGroup("ElvUI", "actionbar", "bar6") end,
			disabled = function() return not E.ActionBars end
		}
	}
}
group = E.Options.args.actionbar.args
BuildABConfig()