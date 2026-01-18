--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Logger = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logger"))
local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))
local ProfileConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProfileConstants"))
local PlayerProfile = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerProfile"))
local TokenBucket = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TokenBucket"))

local TAG = "MenuServer"

type QueueStatusPayload = {
	state: string, -- "idle" | "searching" | "found" | "teleporting" | "error"
	modeId: string?,
	message: string?,
}

type QueueRequestPayload = {
	action: string, -- "SelectMode" | "ReadyUp" | "Cancel"
	modeId: string?,
}

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateRemoteEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = parent
	return re
end

local remotesRoot = getOrCreateFolder(ReplicatedStorage, Config.Remotes.FolderName)
local menuFolder = getOrCreateFolder(remotesRoot, Config.Remotes.MenuFolderName)

local queueRequest = getOrCreateRemoteEvent(menuFolder, Config.Remotes.QueueRequest)
local queueStatus = getOrCreateRemoteEvent(menuFolder, Config.Remotes.QueueStatus)

local rateLimitByPlayer: { [Player]: TokenBucket.Bucket } = {}
local selectedModeByPlayer: { [Player]: string } = {}
local queuedByPlayer: { [Player]: boolean } = {}

local function setProfileDefaults(player: Player)
	local attrs = ProfileConstants.Attributes
	local defaults = ProfileConstants.Defaults

	local level = player:GetAttribute(attrs.Level)
	local exp = player:GetAttribute(attrs.Exp)

	if typeof(level) ~= "number" then
		level = defaults.Level
		player:SetAttribute(attrs.Level, level)
	end

	if typeof(exp) ~= "number" then
		exp = defaults.Exp
		player:SetAttribute(attrs.Exp, exp)
	end

	local expToNext = PlayerProfile.getExpToNext(level :: number)
	player:SetAttribute(attrs.ExpToNext, expToNext)
end

local function pushStatus(player: Player, payload: QueueStatusPayload)
	queueStatus:FireClient(player, payload)
end

local function canPassRateLimit(player: Player): boolean
	local bucket = rateLimitByPlayer[player]
	if not bucket then
		bucket = TokenBucket.new(
			Config.Network.QueueRequestRateLimit.Capacity,
			Config.Network.QueueRequestRateLimit.RefillPerSecond
		)
		rateLimitByPlayer[player] = bucket
	end
	return TokenBucket.consume(bucket, 1)
end

Players.PlayerAdded:Connect(function(player)
	rateLimitByPlayer[player] = TokenBucket.new(
		Config.Network.QueueRequestRateLimit.Capacity,
		Config.Network.QueueRequestRateLimit.RefillPerSecond
	)

	setProfileDefaults(player)

	selectedModeByPlayer[player] = "1v1"
	queuedByPlayer[player] = false

	pushStatus(player, { state = "idle", modeId = selectedModeByPlayer[player] })
	Logger.debug(Config.Debug, TAG, "PlayerAdded init", player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	rateLimitByPlayer[player] = nil
	selectedModeByPlayer[player] = nil
	queuedByPlayer[player] = nil
end)

local function getPlayerLevel(player: Player): number
	local level = player:GetAttribute(ProfileConstants.Attributes.Level)
	if typeof(level) == "number" then
		return math.max(1, math.floor(level))
	end
	return ProfileConstants.Defaults.Level
end

queueRequest.OnServerEvent:Connect(function(player: Player, payload: any)
	if not canPassRateLimit(player) then
		return
	end

	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.action
	if typeof(action) ~= "string" then
		return
	end

	local modeId = payload.modeId
	if modeId ~= nil and typeof(modeId) ~= "string" then
		return
	end

	if action == "SelectMode" then
		if not modeId then
			return
		end

		local mode = ModeCatalog.getById(modeId)
		if not mode then
			pushStatus(player, { state = "error", message = "Mode not found." })
			return
		end

		selectedModeByPlayer[player] = modeId
		queuedByPlayer[player] = false

		pushStatus(player, { state = "idle", modeId = modeId })
		return
	end

	if action == "Cancel" then
		queuedByPlayer[player] = false
		pushStatus(player, { state = "idle", modeId = selectedModeByPlayer[player] })
		return
	end

	if action == "ReadyUp" then
		local chosen = selectedModeByPlayer[player]
		if typeof(chosen) ~= "string" then
			pushStatus(player, { state = "error", message = "No mode selected." })
			return
		end

		local level = getPlayerLevel(player)
		local ok, reason = ModeCatalog.canQueue(chosen, level)

		-- Dev convenience: allow “searching” UI even if no placeId configured
		-- (still blocks comingSoon/disabled)
		if not ok and Config.Debug then
			local mode = ModeCatalog.getById(chosen)
			if mode and mode.enabled and not mode.comingSoon then
				ok = true
				reason = nil
			end
		end

		if not ok then
			pushStatus(player, { state = "error", modeId = chosen, message = reason or "Can't queue." })
			return
		end

		queuedByPlayer[player] = true
		pushStatus(player, { state = "searching", modeId = chosen })

		-- Stub “match found” flow (real matchmaking comes later)
		task.delay(1.5, function()
			if not player.Parent then
				return
			end
			if not queuedByPlayer[player] then
				return
			end
			pushStatus(player, { state = "found", modeId = chosen })
		end)

		task.delay(2.5, function()
			if not player.Parent then
				return
			end
			if not queuedByPlayer[player] then
				return
			end

			-- In a later phase: Teleport to mode.placeId via TeleportService
			pushStatus(player, { state = "teleporting", modeId = chosen, message = "Teleport will be wired when sub-places are ready." })
		end)

		return
	end
end)
