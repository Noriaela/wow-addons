local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:GetModule("Bags");

--Cache global variables
--Lua functions
local gsub, match = string.gsub, string.match
local getn = table.getn
--WoW API / Variables
local COLOR, GENERAL, NONE = COLOR, GENERAL, NONE

E.Options.args.bags = {
	type = "group",
	name = L["Bags"],
	childGroups = "tab",
	get = function(info) return E.db.bags[ info[getn(info)] ] end,
	set = function(info, value) E.db.bags[ info[getn(info)] ] = value end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["BAGS_DESC"]
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Enable"],
			desc = L["Enable/Disable the all-in-one bag."],
			get = function(info) return E.private.bags.enable end,
			set = function(info, value) E.private.bags.enable = value; E:StaticPopup_Show("PRIVATE_RL") end
		},
		general = {
			order = 3,
			type = "group",
			name = GENERAL,
			disabled = function() return not E.bags end,
			args = {
				header = {
					order = 0,
					type = "header",
					name = GENERAL
				},
				moneyFormat = {
					order = 1,
					type = "select",
					name = L["Money Format"],
					desc = L["The display format of the money text that is shown at the top of the main bag."],
					values = {
						["SMART"] = L["Smart"],
						["FULL"] = L["Full"],
						["SHORT"] = L["Short"],
						["SHORTINT"] = L["Short (Whole Numbers)"],
						["CONDENSED"] = L["Condensed"],
						["BLIZZARD"] = L["Blizzard Style"]
					},
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:UpdateGoldText() end
				},
				clearSearchOnClose = {
					order = 2,
					type = "toggle",
					name = L["Clear Search On Close"],
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value end
				},
				reverseSlots = {
					order = 3,
					type = "toggle",
					name = L["Reverse Bag Slots"],
					set = function(info, value) E.db.bags[info[getn(info)]] = value B:UpdateAll() end,
				},
				disableBagSort = {
					order = 4,
					type = "toggle",
					name = L["Disable Bag Sort"],
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:ToggleSortButtonState(false) end
				},
				disableBankSort = {
					order = 5,
					type = "toggle",
					name = L["Disable Bank Sort"],
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:ToggleSortButtonState(true) end
				},
				countGroup = {
					order = 6,
					type = "group",
					name = L["Item Count Font"],
					guiInline = true,
					args = {
						countFont = {
							order = 1,
							type = "select",
							dialogControl = "LSM30_Font",
							name = L["Font"],
							values = AceGUIWidgetLSMlists.font,
							set = function(info, value) E.db.bags.countFont = value; B:UpdateCountDisplay() end
						},
						countFontSize = {
							order = 2,
							type = "range",
							name = FONT_SIZE,
							min = 4, max = 22, step = 1,
							set = function(info, value) E.db.bags.countFontSize = value; B:UpdateCountDisplay() end
						},
						countFontOutline = {
							order = 3,
							type = "select",
							name = L["Font Outline"],
							set = function(info, value) E.db.bags.countFontOutline = value; B:UpdateCountDisplay() end,
							values = {
								["NONE"] = NONE,
								["OUTLINE"] = "OUTLINE",
								["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
								["THICKOUTLINE"] = "THICKOUTLINE"
							}
						},
						countFontColor = {
							order = 4,
							type = "color",
							name = COLOR,
							get = function(info)
								local t = E.db.bags[ info[getn(info)] ]
								local d = P.bags[ info[getn(info)] ]
								return t.r, t.g, t.b, t.a, d.r, d.g, d.b
							end,
							set = function(info, r, g, b)
								local t = E.db.bags[ info[getn(info)] ]
								t.r, t.g, t.b = r, g, b
								B:UpdateCountDisplay()
							end
						}
					}
				},
				itemLevelGroup = {
					order = 7,
					type = "group",
					name = L["Item Level"],
					guiInline = true,
					args = {
						itemLevel = {
							order = 1,
							type = "toggle",
							name = L["Display Item Level"],
							desc = L["Displays item level on equippable items."],
							set = function(info, value) E.db.bags.itemLevel = value; B:UpdateItemLevelDisplay() end
						},
						itemLevelThreshold = {
							order = 2,
							name = L["Item Level Threshold"],
							desc = L["The minimum item level required for it to be shown."],
							type = "range",
							min = 1, max = 1000, step = 1,
							disabled = function() return not E.db.bags.itemLevel end,
							set = function(info, value) E.db.bags.itemLevelThreshold = value; B:UpdateItemLevelDisplay() end
						},
						spacer = {
							order = 3,
							type = "description",
							name = " "
						},
						itemLevelFont = {
							order = 4,
							type = "select",
							dialogControl = "LSM30_Font",
							name = L["Font"],
							values = AceGUIWidgetLSMlists.font,
							disabled = function() return not E.db.bags.itemLevel end,
							set = function(info, value) E.db.bags.itemLevelFont = value; B:UpdateItemLevelDisplay() end
						},
						itemLevelFontSize = {
							order = 5,
							type = "range",
							name = FONT_SIZE,
							min = 6, max = 33, step = 1,
							disabled = function() return not E.db.bags.itemLevel end,
							set = function(info, value) E.db.bags.itemLevelFontSize = value; B:UpdateItemLevelDisplay() end
						},
						itemLevelFontOutline = {
							order = 6,
							type = "select",
							name = L["Font Outline"],
							disabled = function() return not E.db.bags.itemLevel end,
							set = function(info, value) E.db.bags.itemLevelFontOutline = value; B:UpdateItemLevelDisplay() end,
							values = {
								["NONE"] = NONE,
								["OUTLINE"] = "OUTLINE",
								["MONOCHROMEOUTLINE"] = "MONOCROMEOUTLINE",
								["THICKOUTLINE"] = "THICKOUTLINE"
							}
						}
					}
				}
			}
		},
		sizeGroup = {
			order = 4,
			type = "group",
			name = L["Size"],
			disabled = function() return not E.bags end,
			args = {
				header = {
					order = 0,
					type = "header",
					name = L["Size and Positions"]
				},
				bagSize = {
					order = 1,
					type = "range",
					name = L["Button Size (Bag)"],
					desc = L["The size of the individual buttons on the bag frame."],
					min = 15, max = 45, step = 1,
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:Layout() end
				},
				bankSize = {
					order = 2,
					type = "range",
					name = L["Button Size (Bank)"],
					desc = L["The size of the individual buttons on the bank frame."],
					min = 15, max = 45, step = 1,
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:Layout(true) end
				},
				spacer = {
					order = 3,
					type = "description",
					name = " "
				},
				bagWidth = {
					order = 4,
					type = "range",
					name = L["Panel Width (Bags)"],
					desc = L["Adjust the width of the bag frame."],
					min = 150, max = 1400, step = 1,
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:Layout() end
				},
				bankWidth = {
					order = 5,
					type = "range",
					name = L["Panel Width (Bank)"],
					desc = L["Adjust the width of the bank frame."],
					min = 150, max = 1400, step = 1,
					set = function(info, value) E.db.bags[ info[getn(info)] ] = value; B:Layout(true) end
				}
			}
		},
		bagBar = {
			order = 5,
			type = "group",
			name = L["Bag-Bar"],
			get = function(info) return E.db.bags.bagBar[ info[getn(info)] ] end,
			set = function(info, value) E.db.bags.bagBar[ info[getn(info)] ] = value; B:SizeAndPositionBagBar() end,
			args = {
				header = {
					order = 0,
					type = "header",
					name = L["Bag-Bar"]
				},
				enable = {
					order = 1,
					type = "toggle",
					name = L["Enable"],
					desc = L["Enable/Disable the Bag-Bar."],
					get = function(info) return E.private.bags.bagBar end,
					set = function(info, value) E.private.bags.bagBar = value; E:StaticPopup_Show("PRIVATE_RL") end
				},
				showBackdrop = {
					order = 2,
					type = "toggle",
					name = L["Backdrop"]
				},
				mouseover = {
					order = 3,
					name = L["Mouse Over"],
					desc = L["The frame is not shown unless you mouse over the frame."],
					type = "toggle"
				},
				size = {
					order = 4,
					type = "range",
					name = L["Button Size"],
					desc = L["Set the size of your bag buttons."],
					min = 24, max = 60, step = 1
				},
				spacing = {
					order = 5,
					type = "range",
					name = L["Button Spacing"],
					desc = L["The spacing between buttons."],
					min = 1, max = 10, step = 1
				},
				backdropSpacing = {
					order = 6,
					type = "range",
					name = L["Backdrop Spacing"],
					desc = L["The spacing between the backdrop and the buttons."],
					min = 0, max = 10, step = 1
				},
				sortDirection = {
					order = 7,
					type = "select",
					name = L["Sort Direction"],
					desc = L["The direction that the bag frames will grow from the anchor."],
					values = {
						["ASCENDING"] = L["Ascending"],
						["DESCENDING"] = L["Descending"]
					}
				},
				growthDirection = {
					order = 7,
					type = "select",
					name = L["Bar Direction"],
					desc = L["The direction that the bag frames be (Horizontal or Vertical)."],
					values = {
						["VERTICAL"] = L["Vertical"],
						["HORIZONTAL"] = L["Horizontal"]
					}
				}
			}
		},
		split = {
			order = 6,
			type = "group",
			name = L["Split"],
			get = function(info) return E.db.bags.split[ info[getn(info)] ] end,
			set = function(info, value) E.db.bags.split[ info[getn(info)] ] = value B:UpdateAll() end,
			disabled = function() return not E.bags end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Split"]
				},
				bagSpacing = {
					order = 2,
					type = "range",
					name = L["Bag Spacing"],
					min = 0, max = 20, step = 1
				},
				player = {
					order = 3,
					type = "toggle",
					set = function(info, value) E.db.bags.split[ info[getn(info)] ] = value B:Layout() end,
					name = L["Bag"]
				},
				bank = {
					order = 4,
					type = "toggle",
					set = function(info, value) E.db.bags.split[ info[getn(info)] ] = value B:Layout(true) end,
					name = L["Bank"]
				},
				splitbags = {
					order = 5,
					type = "group",
					name = L["Player"],
					get = function(info) return E.db.bags.split[ info[getn(info)] ] end,
					set = function(info, value) E.db.bags.split[ info[getn(info)] ] = value B:Layout() end,
					disabled = function() return not E.db.bags.split.player end,
					guiInline = true,
					args = {
						bag1 = {
							order = 2,
							type = "toggle",
							name = L["Bag 1"]
						},
						bag2 = {
							order = 3,
							type = "toggle",
							name = L["Bag 2"]
						},
						bag3 = {
							order = 4,
							type = "toggle",
							name = L["Bag 3"]
						},
						bag4 = {
							order = 5,
							type = "toggle",
							name = L["Bag 4"]
						}
					}
				},
				splitbank = {
					order = 6,
					type = "group",
					name = L["Bank"],
					get = function(info) return E.db.bags.split[ info[getn(info)] ] end,
					set = function(info, value) E.db.bags.split[ info[getn(info)] ] = value B:Layout(true) end,
					disabled = function() return not E.db.bags.split.bank end,
					guiInline = true,
					args = {
						bag5 = {
							order = 2,
							type = "toggle",
							name = L["Bank 1"]
						},
						bag6 = {
							order = 3,
							type = "toggle",
							name = L["Bank 2"]
						},
						bag7 = {
							order = 4,
							type = "toggle",
							name = L["Bank 3"]
						},
						bag8 = {
							order = 5,
							type = "toggle",
							name = L["Bank 4"]
						},
						bag9 = {
							order = 6,
							type = "toggle",
							name = L["Bank 5"]
						},
						bag10 = {
							order = 7,
							type = "toggle",
							name = L["Bank 6"]
						},
						bag11 = {
							order = 8,
							type = "toggle",
							name = L["Bank 7"]
						}
					}
				}
			}
		},
		vendorGrays = {
			order = 7,
			type = "group",
			name = L["Vendor Grays"],
			get = function(info) return E.db.bags.vendorGrays[ info[getn(info)] ] end,
			set = function(info, value) E.db.bags.vendorGrays[ info[getn(info)] ] = value end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Vendor Grays"]
				},
				enable = {
					order = 2,
					type = "toggle",
					name = L["Enable"],
					desc = L["Automatically vendor gray items when visiting a vendor."]
				},
				interval = {
					order = 3,
					type = "range",
					name = L["Sell Interval"],
					desc = L["Will attempt to sell another item in set interval after previous one was sold."],
					min = 0.1, max = 1, step = 0.1
				},
				details = {
					order = 4,
					type = "toggle",
					name = L["Vendor Gray Detailed Report"],
					desc = L["Displays a detailed report of every item sold when enabled."]
				}
			}
		},
		bagSortingGroup = {
			order = 8,
			type = "group",
			name = L["Bag Sorting"],
			disabled = function() return not E.bags end,
			args = {
				header = {
					order = 0,
					type = "header",
					name = L["Bag Sorting"],
				},
				sortInverted = {
					order = 1,
					type = "toggle",
					name = L["Sort Inverted"],
					desc = L["Direction the bag sorting will use to allocate the items."]
				},
				spacer = {
					order = 2,
					type = "description",
					name = " "
				},
				description = {
					order = 3,
					type = "description",
					name = L["Here you can add items or search terms that you want to be excluded from sorting. To remove an item just click on its name in the list."]
				},
				addEntryGroup = {
					order = 4,
					type = "group",
					name = L["Add Item or Search Syntax"],
					guiInline = true,
					args = {
						addEntryProfile = {
							order = 1,
							type = "input",
							name = L["Profile"],
							desc = L["Add an item or search syntax to the ignored list. Items matching the search syntax will be ignored."],
							get = function(info) return "" end,
							set = function(info, value)
								if value == "" or gsub(value, "%s+", "") == "" then return end

								local itemID = match(value, "item:(%d+)")
								E.db.bags.ignoredItems[(itemID or value)] = value
							end
						},
						spacer = {
							order = 2,
							type = "description",
							name = " ",
							width = "normal"
						},
						addEntryGlobal = {
							order = 3,
							type = "input",
							name = L["Global"],
							desc = L["Add an item or search syntax to the ignored list. Items matching the search syntax will be ignored."],
							get = function(info) return "" end,
							set = function(info, value)
								if (value == "" or gsub(value, "%s+", "") == "") then return end

								local itemID = match(value, "item:(%d+)")
								E.global.bags.ignoredItems[(itemID or value)] = value

								if E.db.bags.ignoredItems[(itemID or value)] then
									E.db.bags.ignoredItems[(itemID or value)] = nil
								end
							end
						}
					}
				},
				ignoredEntriesProfile = {
					order = 5,
					type = "multiselect",
					name = L["Ignored Items and Search Syntax (Profile)"],
					values = function() return E.db.bags.ignoredItems end,
					get = function(info, value)	return E.db.bags.ignoredItems[value] end,
					set = function(info, value)
						E.db.bags.ignoredItems[value] = nil
						GameTooltip:Hide()
					end
				},
				--[[ignoredEntriesGlobal = {
					order = 6,
					type = "multiselect",
					name = L["Ignored Items and Search Syntax (Global)"],
					values = function() return E.global.bags.ignoredItems end,
					get = function(info, value)	return E.global.bags.ignoredItems[value] end,
					set = function(info, value)
						E.global.bags.ignoredItems[value] = nil
						GameTooltip:Hide()
					end
				}--]]
			}
		},
		search_syntax = {
			order = 9,
			type = "group",
			name = L["Search Syntax"],
			disabled = function() return not E.bags end,
			args = {
				header = {
					order = 1,
					type = "header",
					name = L["Search Syntax"]
				},
				text = {
					order = 2,
					type = "input",
					multiline = 30,
					width = "full",
					name = L["Search Syntax"],
					get = function(info) return L["SEARCH_SYNTAX_DESC"] end,
					set = function(info, value) value = L["SEARCH_SYNTAX_DESC"] end
				}
			}
		}
	}
}