--!strict

export type ModeId = string

export type GameMode = {
	id: ModeId,

	-- UI presentation
	displayName: string,
	subtitle: string?,
	description: string?,
	sortOrder: number,
	category: string?, -- e.g. "Core", "Ranked", "Limited", "Custom"
	tags: { string }?,

	-- Requirements / availability
	enabled: boolean,
	comingSoon: boolean?,
	minLevel: number?, -- optional account level requirement
	minPlayers: number,
	maxPlayers: number,
	teamSize: number?, -- nil for FFA

	-- Teleport destination (sub-place)
	placeId: number?, -- nil if not wired yet (then treated as comingSoon)

	-- Optional art hooks (asset ids)
	iconImage: string?,       -- "rbxassetid://123"
	backgroundImage: string?, -- "rbxassetid://123"
}

local ModeCatalog = {}

local modes: { GameMode } = {
	{
		id = "1v1",
		displayName = "1v1 Duel",
		subtitle = "Solo Battles",
		description = "Test your skills against another player. First to 6 eliminations wins.",
		sortOrder = 10,
		category = "Core",
		enabled = true,
		comingSoon = false,
		minPlayers = 2,
		maxPlayers = 2,
		teamSize = nil,
		placeId = nil, -- set to your sub-place PlaceId when ready
	},

	{
		id = "ffa",
		displayName = "Free-For-All",
		subtitle = "Every Player for Themselves",
		description = "Fast-paced chaos. Highest eliminations wins.",
		sortOrder = 20,
		category = "Core",
		enabled = true,
		comingSoon = false,
		minPlayers = 2,
		maxPlayers = 12,
		teamSize = nil,
		placeId = nil,
	},

	{
		id = "tdm",
		displayName = "Team Deathmatch",
		subtitle = "4v4 Team Combat",
		description = "Work with your team to outscore the enemy.",
		sortOrder = 30,
		category = "Core",
		enabled = false,
		comingSoon = true,
		minPlayers = 4,
		maxPlayers = 8,
		teamSize = 4,
		placeId = nil,
	},
}

local function shallowCopy<T>(t: { T }): { T }
	local out: { T } = table.create(#t)
	for i = 1, #t do
		out[i] = t[i]
	end
	return out
end

local function isValidModeId(id: any): boolean
	return typeof(id) == "string" and #id > 0 and #id <= 32
end

local function normalize(mode: GameMode): GameMode
	-- Treat missing placeId as comingSoon unless explicitly enabled without place
	if mode.placeId == nil and mode.comingSoon == nil then
		mode.comingSoon = true
	end
	return mode
end

function ModeCatalog.getAll(): { GameMode }
	local copy = shallowCopy(modes)
	table.sort(copy, function(a, b)
		return a.sortOrder < b.sortOrder
	end)
	for i = 1, #copy do
		copy[i] = normalize(copy[i])
	end
	return copy
end

function ModeCatalog.getById(id: ModeId): GameMode?
	if not isValidModeId(id) then
		return nil
	end

	for _, mode in ipairs(modes) do
		if mode.id == id then
			return normalize(mode)
		end
	end
	return nil
end

function ModeCatalog.getPlayable(): { GameMode }
	local all = ModeCatalog.getAll()
	local playable: { GameMode } = {}

	for _, mode in ipairs(all) do
		if mode.enabled and not mode.comingSoon and mode.placeId ~= nil then
			table.insert(playable, mode)
		end
	end

	return playable
end

function ModeCatalog.canQueue(modeId: any, playerLevel: number?): (boolean, string?)
	if not isValidModeId(modeId) then
		return false, "Invalid mode."
	end

	local mode = ModeCatalog.getById(modeId :: string)
	if not mode then
		return false, "Mode not found."
	end

	if not mode.enabled then
		return false, "Mode disabled."
	end

	if mode.comingSoon then
		return false, "Coming soon."
	end

	if mode.placeId == nil then
		return false, "Mode not configured."
	end

	if mode.minLevel ~= nil and playerLevel ~= nil and playerLevel < mode.minLevel then
		return false, ("Requires level %d."):format(mode.minLevel)
	end

	return true, nil
end

-- Utility: replace mode list at runtime (optional; useful for live-ops)
function ModeCatalog.setModes(newModes: { GameMode })
	-- Defensive: validate shape minimally
	local validated: { GameMode } = {}

	for _, mode in ipairs(newModes) do
		if isValidModeId(mode.id) and typeof(mode.displayName) == "string" then
			if typeof(mode.sortOrder) ~= "number" then
				mode.sortOrder = 999
			end
			if typeof(mode.enabled) ~= "boolean" then
				mode.enabled = false
			end
			if typeof(mode.minPlayers) ~= "number" then
				mode.minPlayers = 2
			end
			if typeof(mode.maxPlayers) ~= "number" then
				mode.maxPlayers = mode.minPlayers
			end
			table.insert(validated, mode)
		end
	end

	modes = validated
end

return ModeCatalog
