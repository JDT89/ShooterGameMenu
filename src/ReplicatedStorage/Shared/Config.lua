--!strict
local Config = {}

Config.Debug = true
Config.GameName = "RivalsLike"

-- PlaceIds can be defined per mode in ModeCatalog (recommended).
-- Keep these for global/fallback use if needed.
Config.DefaultPlaceIds = {
	Lobby = 0,
}

Config.Remotes = {
	FolderName = "Remotes",
	MenuFolderName = "Menu",

	-- Client -> Server (request to queue / cancel / select mode)
	QueueRequest = "QueueRequest",

	-- Server -> Client (push status updates: searching/found/teleporting/errors)
	QueueStatus = "QueueStatus",
}

Config.UI = {
	Nav = {
		-- Responsive breakpoints (screen width in px)
		ExpandedMinWidth = 1100, -- icons + labels
		IconOnlyMinWidth = 760,  -- icons only
		-- below this: drawer mode (hamburger)

		RailWidthExpanded = 260,
		RailWidthIconOnly = 72,
		RailWidthDrawer = 320,
	},

	RightPanel = {
		Width = 320,
		MinWidthToShow = 900, -- hide/collapse party panel under this width
	},
}

Config.Network = {
	QueueRequestRateLimit = {
		Capacity = 8,
		RefillPerSecond = 1.25, -- tokens/sec per player
	},
}

return Config
