--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Client = ReplicatedStorage:WaitForChild("Client")

local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local MenuApp = require(Client:WaitForChild("MenuUI"):WaitForChild("MenuApp"))

local TAG = "MenuClient"

-- IMPORTANT:
-- Do NOT hard-block the UI on Remotes existing. If the server scripts aren't synced
-- (common with Rojo/project mapping issues), WaitForChild would hang forever and the
-- menu would never appear. Instead, mount UI immediately and wire remotes asynchronously.

local queueRequest: RemoteEvent? = nil
local queueStatus: RemoteEvent? = nil

local function safeSetStatus(app, state: string, message: string?)
	app:setQueueStatus({
		state = state,
		message = message,
	})
end

local app = MenuApp.mount(playerGui, {
	onSelectMode = function(modeId: string)
		if queueRequest then
			queueRequest:FireServer({ action = "SelectMode", modeId = modeId })
		else
			safeSetStatus(app, "error", "Server not ready (no remotes).")
		end
	end,
	onReadyUp = function()
		if queueRequest then
			queueRequest:FireServer({ action = "ReadyUp" })
		else
			safeSetStatus(app, "error", "Server not ready (no remotes).")
		end
	end,
	onCancel = function()
		if queueRequest then
			queueRequest:FireServer({ action = "Cancel" })
		else
			safeSetStatus(app, "idle", "Offline")
		end
	end,
})

safeSetStatus(app, "idle", "Connecting…")

local function waitForInstance(parent: Instance, childName: string, timeoutSec: number): Instance?
	local start = os.clock()
	local inst = parent:FindFirstChild(childName)
	while not inst and (os.clock() - start) < timeoutSec do
		task.wait(0.1)
		inst = parent:FindFirstChild(childName)
	end
	return inst
end

task.spawn(function()
	local remotesRoot = waitForInstance(ReplicatedStorage, Config.Remotes.FolderName, 10)
	if not (remotesRoot and remotesRoot:IsA("Folder")) then
		Logger.warn(TAG, "Remotes folder not found. Is MenuServer.server.lua running/synced?")
		safeSetStatus(app, "error", "Menu server not running.")
		return
	end

	local menuFolder = waitForInstance(remotesRoot, Config.Remotes.MenuFolderName, 10)
	if not (menuFolder and menuFolder:IsA("Folder")) then
		Logger.warn(TAG, "Menu remotes folder not found.")
		safeSetStatus(app, "error", "Menu remotes missing.")
		return
	end

	local qr = waitForInstance(menuFolder, Config.Remotes.QueueRequest, 10)
	local qs = waitForInstance(menuFolder, Config.Remotes.QueueStatus, 10)

	if not (qr and qr:IsA("RemoteEvent")) or not (qs and qs:IsA("RemoteEvent")) then
		Logger.warn(TAG, "QueueRequest/QueueStatus RemoteEvents missing.")
		safeSetStatus(app, "error", "Queue remotes missing.")
		return
	end

	queueRequest = qr
	queueStatus = qs

	Logger.debug(Config.Debug, TAG, "Remotes connected")
	safeSetStatus(app, "idle", "Ready")

	queueStatus.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		app:setQueueStatus(payload)
	end)
end)
