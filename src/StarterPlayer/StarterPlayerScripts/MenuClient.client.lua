--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Client = ReplicatedStorage:WaitForChild("Client")
local RemotesRoot = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(Shared:WaitForChild("Config"))

local menuFolder = RemotesRoot:WaitForChild(Config.Remotes.MenuFolderName)
local queueRequest = menuFolder:WaitForChild(Config.Remotes.QueueRequest) :: RemoteEvent
local queueStatus = menuFolder:WaitForChild(Config.Remotes.QueueStatus) :: RemoteEvent

local MenuApp = require(Client:WaitForChild("MenuUI"):WaitForChild("MenuApp"))

local app = MenuApp.mount(playerGui, {
	onSelectMode = function(modeId: string)
		queueRequest:FireServer({ action = "SelectMode", modeId = modeId })
	end,
	onReadyUp = function()
		queueRequest:FireServer({ action = "ReadyUp" })
	end,
	onCancel = function()
		queueRequest:FireServer({ action = "Cancel" })
	end,
})

queueStatus.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	app:setQueueStatus(payload)
end)
