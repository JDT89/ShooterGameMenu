--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Client = ReplicatedStorage:WaitForChild("Client")

local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local TAG = "MenuClient"

local function tryHideCoreUi()
	if not (Config.UI and Config.UI.HideCoreGui) then
		return
	end

	pcall(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)

	local coreTypes = {
		Enum.CoreGuiType.Chat,
		Enum.CoreGuiType.PlayerList,
		Enum.CoreGuiType.Backpack,
		Enum.CoreGuiType.EmotesMenu,
		Enum.CoreGuiType.Health,
		Enum.CoreGuiType.SelfView,
	}

	for _, coreType in ipairs(coreTypes) do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, false)
		end)
	end
end

-- In Studio + on first load, SetCore can fail until CoreScripts finish booting.
-- We retry a few times so Roblox's top bar/chat don't pop back in and ruin the premium menu.
local function hideCoreUiWithRetries()
	if not (Config.UI and Config.UI.HideCoreGui) then
		return
	end

	for _ = 1, 12 do
		tryHideCoreUi()
		task.wait(0.25)
	end
end

local function ensureLightingEffect(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

local function applyMenuLighting()
	if not (Config.UI and Config.UI.UseLightingEffects) then
		return
	end

	local blur = ensureLightingEffect("BlurEffect", "MenuUI_Blur") :: BlurEffect
	blur.Enabled = true
	blur.Size = 10

	local cc = ensureLightingEffect("ColorCorrectionEffect", "MenuUI_ColorCorrection") :: ColorCorrectionEffect
	cc.Enabled = true
	cc.Brightness = -0.02
	cc.Contrast = 0.12
	cc.Saturation = -0.05
	cc.TintColor = Color3.fromRGB(235, 240, 255)
end

task.defer(function()
	task.spawn(hideCoreUiWithRetries)
	applyMenuLighting()
end)

local function showFatalUi(errorText: string)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuLoadError"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	bg.BorderSizePixel = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Text = "Menu failed to load"
	title.Size = UDim2.new(1, -48, 0, 28)
	title.Position = UDim2.fromOffset(24, 24)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bg

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(200, 200, 200)
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Size = UDim2.new(1, -48, 1, -72)
	body.Position = UDim2.fromOffset(24, 56)

	local trimmed = errorText
	if #trimmed > 1400 then
		trimmed = trimmed:sub(1, 1400) .. "\n…(trimmed)"
	end
	body.Text = trimmed
	body.Parent = bg
end

local okRequire, MenuAppOrErr = pcall(function()
	return require(Client:WaitForChild("MenuUI"):WaitForChild("MenuApp"))
end)

if not okRequire then
	Logger.warn(TAG, "Failed to require MenuApp:", MenuAppOrErr)
	showFatalUi("Require(MenuApp) error:\n" .. tostring(MenuAppOrErr))
	return
end

local MenuApp = MenuAppOrErr :: any

local queueRequest: RemoteEvent? = nil
local queueStatus: RemoteEvent? = nil

local app: any = nil

local function safeSetStatus(state: string, message: string?)
	if not app then
		return
	end
	if typeof(app.setQueueStatus) ~= "function" then
		return
	end

	app:setQueueStatus({
		state = state,
		message = message,
	})
end

local okMount, appOrErr = pcall(function()
	return MenuApp.mount(playerGui, {
		onSelectMode = function(modeId: string)
			if queueRequest then
				queueRequest:FireServer({ action = "SelectMode", modeId = modeId })
			else
				safeSetStatus("error", "Server not ready (no remotes).")
			end
		end,
		onReadyUp = function()
			if queueRequest then
				queueRequest:FireServer({ action = "ReadyUp" })
			else
				safeSetStatus("error", "Server not ready (no remotes).")
			end
		end,
		onCancel = function()
			if queueRequest then
				queueRequest:FireServer({ action = "Cancel" })
			else
				safeSetStatus("idle", "Offline")
			end
		end,
	})
end)

if not okMount then
	Logger.warn(TAG, "MenuApp.mount failed:", appOrErr)
	showFatalUi("MenuApp.mount error:\n" .. tostring(appOrErr))
	return
end

app = appOrErr
safeSetStatus("idle", "Connecting…")

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
		Logger.warn(TAG, "Remotes folder not found. Is MenuServer.server.lua running?")
		safeSetStatus("error", "Menu server not running.")
		return
	end

	local menuFolder = waitForInstance(remotesRoot, Config.Remotes.MenuFolderName, 10)
	if not (menuFolder and menuFolder:IsA("Folder")) then
		Logger.warn(TAG, "Menu remotes folder not found.")
		safeSetStatus("error", "Menu remotes missing.")
		return
	end

	local qr = waitForInstance(menuFolder, Config.Remotes.QueueRequest, 10)
	local qs = waitForInstance(menuFolder, Config.Remotes.QueueStatus, 10)

	if not (qr and qr:IsA("RemoteEvent")) or not (qs and qs:IsA("RemoteEvent")) then
		Logger.warn(TAG, "QueueRequest/QueueStatus RemoteEvents missing.")
		safeSetStatus("error", "Queue remotes missing.")
		return
	end

	queueRequest = qr
	queueStatus = qs

	Logger.debug(Config.Debug, TAG, "Remotes connected")

	queueStatus.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		app:setQueueStatus(payload)
	end)

	queueRequest:FireServer({ action = "Sync" })
end)
