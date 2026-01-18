--!strict
local Config = {}

Config.Debug = true
Config.GameName = "RivalsLike"

Config.DefaultPlaceIds = {
	Lobby = 0,
}

Config.Remotes = {
	FolderName = "Remotes",
	MenuFolderName = "Menu",
	QueueRequest = "QueueRequest",
	QueueStatus = "QueueStatus",
}

Config.UI = {
	-- Lobby/menu is designed to feel like a full-screen product.
	-- Set to false if you want Roblox's default topbar/chat visible.
	HideCoreGui = true,

	-- Adds subtle Blur/ColorCorrection in Lighting (3D only).
	UseLightingEffects = true,

	Nav = {
		ExpandedMinWidth = 1100,
		IconOnlyMinWidth = 760,

		RailWidthExpanded = 260,
		RailWidthIconOnly = 72,
		RailWidthDrawer = 320,
	},

	RightPanel = {
		Width = 320,
		MinWidthToShow = 900,
	},
}

Config.Network = {
	QueueRequestRateLimit = {
		Capacity = 8,
		RefillPerSecond = 1.25,
	},
}

return Config
