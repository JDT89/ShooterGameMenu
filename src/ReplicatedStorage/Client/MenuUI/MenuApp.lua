--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script:WaitForChild("Theme"))
local TweenUtil = require(script.Util:WaitForChild("TweenUtil"))

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local NavRail = require(script.Components:WaitForChild("NavRail"))
local TopBarProfile = require(script.Components:WaitForChild("TopBarProfile"))
local PlayPage = require(script.Pages:WaitForChild("PlayPage"))
local PlaceholderPage = require(script.Pages:WaitForChild("PlaceholderPage"))

export type MountOptions = {
	onSelectMode: (modeId: string) -> (),
	onReadyUp: () -> (),
	onCancel: () -> (),
}

export type App = {
	setQueueStatus: (self: App, payload: any) -> (),
}

local MenuApp = {}

local NAV_ITEMS: { NavRail.NavItem } = {
	{ id = "play", label = "PLAY", iconText = "▶" },
	{ id = "armory", label = "ARMORY", iconText = "⛭" },
	{ id = "cosmetics", label = "COSMETICS", iconText = "✦" },
	{ id = "clans", label = "CLANS", iconText = "☰" },
	{ id = "friends", label = "FRIENDS", iconText = "☺" },
	{ id = "profile", label = "PROFILE", iconText = "👤" },
	{ id = "settings", label = "SETTINGS", iconText = "⚙" },
	{ id = "patch", label = "PATCH NOTES", iconText = "!" },
}

function MenuApp.mount(playerGui: PlayerGui, opts: MountOptions): App
	local player = Players.LocalPlayer

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = screenGui

	-- subtle overlay
	local overlay = Instance.new("Frame")
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Parent = root

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BackgroundTransparency = 0.2
	topBar.BorderSizePixel = 0
	topBar.Size = UDim2.new(1, 0, 0, 64)
	topBar.Parent = root

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Theme.FontBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(16, 0)
	title.Size = UDim2.new(1, -400, 1, 0)
	title.Text = Config.GameName
	title.Parent = topBar

	local profile = TopBarProfile.create(topBar, player)
	profile:getFrame().AnchorPoint = Vector2.new(1, 0.5)
	profile:getFrame().Position = UDim2.new(1, -12, 0.5, 0)

	-- Main layout
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromOffset(0, 64)
	main.Size = UDim2.new(1, 0, 1, -64)
	main.Parent = root

	local navHost = Instance.new("Frame")
	navHost.Name = "NavHost"
	navHost.BackgroundTransparency = 1
	navHost.Size = UDim2.fromOffset(Config.UI.Nav.RailWidthExpanded, 0)
	navHost.Parent = main

	local contentHost = Instance.new("Frame")
	contentHost.Name = "ContentHost"
	contentHost.BackgroundTransparency = 1
	contentHost.Position = UDim2.fromOffset(Config.UI.Nav.RailWidthExpanded, 0)
	contentHost.Size = UDim2.new(1, -(Config.UI.Nav.RailWidthExpanded + Config.UI.RightPanel.Width), 1, 0)
	contentHost.Parent = main

	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.BackgroundTransparency = 0.18
	rightPanel.BorderSizePixel = 0
	rightPanel.AnchorPoint = Vector2.new(1, 0)
	rightPanel.Position = UDim2.new(1, 0, 0, 0)
	rightPanel.Size = UDim2.fromOffset(Config.UI.RightPanel.Width, 0)
	rightPanel.Parent = main

	-- Right panel content: queue block (party panel next phase)
	local rpTitle = Instance.new("TextLabel")
	rpTitle.BackgroundTransparency = 1
	rpTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	rpTitle.Font = Theme.FontBold
	rpTitle.TextSize = 18
	rpTitle.TextXAlignment = Enum.TextXAlignment.Left
	rpTitle.Position = UDim2.fromOffset(14, 14)
	rpTitle.Size = UDim2.new(1, -28, 0, 22)
	rpTitle.Text = "QUEUE"
	rpTitle.Parent = rightPanel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "QueueStatus"
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Font = Theme.Font
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Position = UDim2.fromOffset(14, 44)
	statusLabel.Size = UDim2.new(1, -28, 0, 18)
	statusLabel.Text = "Idle"
	statusLabel.Parent = rightPanel

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyUp"
	readyBtn.AutoButtonColor = false
	readyBtn.BackgroundTransparency = 0.05
	readyBtn.BorderSizePixel = 0
	readyBtn.Size = UDim2.new(1, -28, 0, 48)
	readyBtn.Position = UDim2.new(0, 14, 0, 80)
	readyBtn.Text = "READY UP"
	readyBtn.Font = Theme.FontBold
	readyBtn.TextSize = 16
	readyBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
	readyBtn.Parent = rightPanel
	readyBtn.Selectable = true

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.AutoButtonColor = false
	cancelBtn.BackgroundTransparency = 0.6
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Size = UDim2.new(1, -28, 0, 40)
	cancelBtn.Position = UDim2.new(0, 14, 0, 136)
	cancelBtn.Text = "CANCEL"
	cancelBtn.Font = Theme.FontSemi
	cancelBtn.TextSize = 14
	cancelBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
	cancelBtn.Parent = rightPanel
	cancelBtn.Selectable = true

	readyBtn.MouseButton1Click:Connect(function()
		opts.onReadyUp()
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		opts.onCancel()
	end)

	-- Pages
	local currentPage: Frame? = nil

	local function setPage(newPage: Frame)
		if currentPage then
			local old = currentPage
			TweenUtil.tween(old, Theme.Anim.Med, { Position = UDim2.fromOffset(-20, 0), BackgroundTransparency = 1 })
			task.delay(Theme.Anim.Med, function()
				if old.Parent then old:Destroy() end
			end)
		end

		currentPage = newPage
		newPage.Position = UDim2.fromOffset(20, 0)
		newPage.Parent = contentHost
		TweenUtil.tween(newPage, Theme.Anim.Med, { Position = UDim2.fromOffset(0, 0) })
	end

	local function mountRoute(routeId: string)
		contentHost:ClearAllChildren()

		if routeId == "play" then
			local pageApi = PlayPage.create(contentHost, function(modeId: string)
				opts.onSelectMode(modeId)
			end)
			setPage(pageApi:getFrame())
		else
			setPage(PlaceholderPage.create(contentHost, string.upper(routeId)))
		end
	end

	-- Nav
	local nav = NavRail.create(navHost, NAV_ITEMS, function(id: string)
		mountRoute(id)
	end)

	-- Responsive: Expanded vs IconOnly + right panel collapse
	local function applyResponsive()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local w = vp.X

		local showRight = w >= Config.UI.RightPanel.MinWidthToShow
		rightPanel.Visible = showRight

		local railMode: "Expanded" | "IconOnly" = "Expanded"
		local railWidth = Config.UI.Nav.RailWidthExpanded

		if w < Config.UI.Nav.ExpandedMinWidth then
			railMode = "IconOnly"
			railWidth = Config.UI.Nav.RailWidthIconOnly
		end

		nav:setMode(railMode)
		navHost.Size = UDim2.fromOffset(railWidth, 0)
		contentHost.Position = UDim2.fromOffset(railWidth, 0)

		local rightW = showRight and Config.UI.RightPanel.Width or 0
		contentHost.Size = UDim2.new(1, -(railWidth + rightW), 1, 0)
	end

	if workspace.CurrentCamera then
		applyResponsive()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
	end

	-- initial route
	nav:setActive("play")
	mountRoute("play")

	local app: App = {} :: any
	function app:setQueueStatus(payload: any)
		local state = payload.state
		local msg = payload.message
		if typeof(state) ~= "string" then
			return
		end

		local text = state
		if typeof(msg) == "string" and #msg > 0 then
			text = state .. " • " .. msg
		end

		statusLabel.Text = text
	end

	return app
end

return MenuApp
