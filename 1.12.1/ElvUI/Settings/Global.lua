local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB

--Global Settings
G["general"] = {
	["autoScale"] = true,
	["minUiScale"] = 0.64,
	["eyefinity"] = false,
	["smallerWorldMap"] = true,
	["WorldMapCoordinates"] = {
		["enable"] = true,
		["position"] = "BOTTOMLEFT",
		["xOffset"] = 0,
		["yOffset"] = 0
	},
	["versionCheck"] = true
}

G["classCache"] = {}

G["classtimer"] = {}

G["nameplates"] = {}

G["unitframe"] = {
	["specialFilters"] = {},
	["aurafilters"] = {}
}

G["chat"] = {
	["classColorMentionExcludedNames"] = {}
}

G["bags"] = {
	["ignoredItems"] = {}
}