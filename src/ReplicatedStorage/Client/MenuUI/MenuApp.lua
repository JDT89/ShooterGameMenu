--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local menuRoot = script.Parent

local Theme = require(menuRoot:WaitForChild("Theme"))
local TweenUtil = require(menuRoot:WaitForChild("Util"):WaitForChild("TweenUtil"))

local NavRail = require(menuRoot:WaitForChild("Components"):WaitForChild("NavRail"))
local TopBarProfile = require(menuRoot:WaitForChild("Components"):WaitForChild("TopBarProfile"))
local PartyPanel = require(menuRoot:WaitForChild("Components"):WaitForChild("PartyPanel"))
local PlayPage = require(menuRoot:WaitForChild("Pages"):WaitForChild("PlayPage"))
local PlaceholderPage = require(menuRoot:WaitForChild("Pages"):WaitForChild("PlaceholderPage"))

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))

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

local function getModeDisplayName(modeId: string): string
	local mode = ModeCatalog.getById(modeId)
	if mode and typeof(mode.displayName) == "string" then
		return mode.displayName
	end
	return modeId
end

function MenuApp.mount(playerGui: PlayerGui, opts: MountOptions): App
	local player = Players.LocalPlayer

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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

	local topLeft = Instance.new("Frame")
	topLeft.Name = "TopLeft"
	topLeft.BackgroundTransparency = 1
	topLeft.Position = UDim2.fromOffset(12, 0)
	topLeft.Size = UDim2.new(1, -380, 1, 0)
	topLeft.Parent = topBar

	local topLeftLayout = Instance.new("UIListLayout")
	topLeftLayout.FillDirection = Enum.FillDirection.Horizontal
	topLeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	topLeftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLeftLayout.Padding = UDim.new(0, 10)
	topLeftLayout.Parent = topLeft

	local hamburger = Instance.new("TextButton")
	hamburger.Name = "Hamburger"
	hamburger.AutoButtonColor = false
	hamburger.BackgroundTransparency = 0.65
	hamburger.BorderSizePixel = 0
	hamburger.Size = UDim2.fromOffset(40, 40)
	hamburger.Text = "≡"
	hamburger.Font = Theme.FontBold
	hamburger.TextSize = 20
	hamburger.TextColor3 = Color3.fromRGB(245, 245, 245)
	hamburger.Visible = false
	hamburger.Selectable = true
	hamburger.Parent = topLeft
	local hamburgerCorner = Instance.new("UICorner")
	hamburgerCorner.CornerRadius = UDim.new(0, Theme.CornerSmall)
	hamburgerCorner.Parent = hamburger

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Theme.FontBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Text = Config.GameName
	title.Parent = topLeft

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

	-- Bottom queue bar (shown when right panel is collapsed; mobile/tablet/console friendly)
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.BackgroundTransparency = 0.18
	bottomBar.BorderSizePixel = 0
	bottomBar.AnchorPoint = Vector2.new(0, 1)
	bottomBar.Position = UDim2.new(0, 0, 1, 0)
	bottomBar.Size = UDim2.new(1, 0, 0, 76)
	bottomBar.Visible = false
	bottomBar.Parent = main
	local bottomCorner = Instance.new("UICorner")
	bottomCorner.CornerRadius = UDim.new(0, Theme.Corner)
	bottomCorner.Parent = bottomBar

	local bottomPad = Instance.new("UIPadding")
	bottomPad.PaddingLeft = UDim.new(0, 14)
	bottomPad.PaddingRight = UDim.new(0, 14)
	bottomPad.PaddingTop = UDim.new(0, 12)
	bottomPad.PaddingBottom = UDim.new(0, 12)
	bottomPad.Parent = bottomBar

	local bottomLeft = Instance.new("Frame")
	bottomLeft.Name = "BottomLeft"
	bottomLeft.BackgroundTransparency = 1
	bottomLeft.Size = UDim2.new(1, -220, 1, 0)
	bottomLeft.Parent = bottomBar

	local bottomTitle = Instance.new("TextLabel")
	bottomTitle.Name = "BottomTitle"
	bottomTitle.BackgroundTransparency = 1
	bottomTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	bottomTitle.Font = Theme.FontBold
	bottomTitle.TextSize = 14
	bottomTitle.TextXAlignment = Enum.TextXAlignment.Left
	bottomTitle.Size = UDim2.new(1, 0, 0, 18)
	bottomTitle.Text = "QUEUE"
	bottomTitle.Parent = bottomLeft

	local bottomStatus = Instance.new("TextLabel")
	bottomStatus.Name = "BottomStatus"
	bottomStatus.BackgroundTransparency = 1
	bottomStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
	bottomStatus.Font = Theme.Font
	bottomStatus.TextSize = 13
	bottomStatus.TextXAlignment = Enum.TextXAlignment.Left
	bottomStatus.Position = UDim2.fromOffset(0, 20)
	bottomStatus.Size = UDim2.new(1, 0, 0, 18)
	bottomStatus.Text = "Idle"
	bottomStatus.Parent = bottomLeft

	local bottomButtons = Instance.new("Frame")
	bottomButtons.Name = "BottomButtons"
	bottomButtons.BackgroundTransparency = 1
	bottomButtons.AnchorPoint = Vector2.new(1, 0)
	bottomButtons.Position = UDim2.new(1, 0, 0, 0)
	bottomButtons.Size = UDim2.new(0, 220, 1, 0)
	bottomButtons.Parent = bottomBar

	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bottomLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Padding = UDim.new(0, 10)
	bottomLayout.Parent = bottomButtons

	local bottomReady = Instance.new("TextButton")
	bottomReady.Name = "ReadyUp"
	bottomReady.AutoButtonColor = false
	bottomReady.BackgroundTransparency = 0.05
	bottomReady.BorderSizePixel = 0
	bottomReady.Size = UDim2.fromOffset(120, 44)
	bottomReady.Text = "READY"
	bottomReady.Font = Theme.FontBold
	bottomReady.TextSize = 14
	bottomReady.TextColor3 = Color3.fromRGB(245, 245, 245)
	bottomReady.Selectable = true
	bottomReady.Parent = bottomButtons
	local bottomReadyCorner = Instance.new("UICorner")
	bottomReadyCorner.CornerRadius = UDim.new(0, Theme.CornerSmall)
	bottomReadyCorner.Parent = bottomReady

	local bottomCancel = Instance.new("TextButton")
	bottomCancel.Name = "Cancel"
	bottomCancel.AutoButtonColor = false
	bottomCancel.BackgroundTransparency = 0.6
	bottomCancel.BorderSizePixel = 0
	bottomCancel.Size = UDim2.fromOffset(90, 44)
	bottomCancel.Text = "CANCEL"
	bottomCancel.Font = Theme.FontSemi
	bottomCancel.TextSize = 13
	bottomCancel.TextColor3 = Color3.fromRGB(235, 235, 235)
	bottomCancel.Selectable = true
	bottomCancel.Parent = bottomButtons
	local bottomCancelCorner = Instance.new("UICorner")
	bottomCancelCorner.CornerRadius = UDim.new(0, Theme.CornerSmall)
	bottomCancelCorner.Parent = bottomCancel

	-- Drawer overlay (mobile landscape)
	local drawerOverlay = Instance.new("Frame")
	drawerOverlay.Name = "DrawerOverlay"
	drawerOverlay.BackgroundTransparency = 1
	drawerOverlay.Visible = false
	drawerOverlay.Size = UDim2.fromScale(1, 1)
	drawerOverlay.ZIndex = 50
	drawerOverlay.Parent = root

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 50
	dim.Parent = drawerOverlay

	local dimButton = Instance.new("TextButton")
	dimButton.Name = "DimButton"
	dimButton.BackgroundTransparency = 1
	dimButton.Text = ""
	dimButton.AutoButtonColor = false
	dimButton.Size = UDim2.fromScale(1, 1)
	dimButton.ZIndex = 51
	dimButton.Parent = drawerOverlay

	local drawer = Instance.new("Frame")
	drawer.Name = "Drawer"
	drawer.BackgroundTransparency = 0.08
	drawer.BorderSizePixel = 0
	drawer.Size = UDim2.new(0, Config.UI.Nav.RailWidthDrawer, 1, 0)
	drawer.Position = UDim2.fromOffset(-Config.UI.Nav.RailWidthDrawer, 0)
	drawer.ZIndex = 52
	drawer.Parent = drawerOverlay
	local drawerCorner = Instance.new("UICorner")
	drawerCorner.CornerRadius = UDim.new(0, Theme.Corner)
	drawerCorner.Parent = drawer

	local drawerPad = Instance.new("UIPadding")
	drawerPad.PaddingTop = UDim.new(0, 10)
	drawerPad.PaddingBottom = UDim.new(0, 10)
	drawerPad.PaddingLeft = UDim.new(0, 10)
	drawerPad.PaddingRight = UDim.new(0, 10)
	drawerPad.Parent = drawer

	local drawerTitle = Instance.new("TextLabel")
	drawerTitle.BackgroundTransparency = 1
	drawerTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	drawerTitle.Font = Theme.FontBold
	drawerTitle.TextSize = 16
	drawerTitle.TextXAlignment = Enum.TextXAlignment.Left
	drawerTitle.Size = UDim2.new(1, 0, 0, 20)
	drawerTitle.ZIndex = 53
	drawerTitle.Text = Config.GameName
	drawerTitle.Parent = drawer

	local drawerNavHost = Instance.new("Frame")
	drawerNavHost.Name = "DrawerNavHost"
	drawerNavHost.BackgroundTransparency = 1
	drawerNavHost.Position = UDim2.fromOffset(0, 28)
	drawerNavHost.Size = UDim2.new(1, 0, 1, -28)
	drawerNavHost.ZIndex = 53
	drawerNavHost.Parent = drawer

	-- Right panel content: queue + party
	local rightPad = Instance.new("UIPadding")
	rightPad.PaddingTop = UDim.new(0, 14)
	rightPad.PaddingLeft = UDim.new(0, 14)
	rightPad.PaddingRight = UDim.new(0, 14)
	rightPad.PaddingBottom = UDim.new(0, 14)
	rightPad.Parent = rightPanel

	local queueSection = Instance.new("Frame")
	queueSection.Name = "QueueSection"
	queueSection.BackgroundTransparency = 1
	queueSection.Position = UDim2.fromOffset(0, 0)
	queueSection.Size = UDim2.new(1, 0, 0, 220)
	queueSection.Parent = rightPanel

	local rpTitle = Instance.new("TextLabel")
	rpTitle.BackgroundTransparency = 1
	rpTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	rpTitle.Font = Theme.FontBold
	rpTitle.TextSize = 18
	rpTitle.TextXAlignment = Enum.TextXAlignment.Left
	rpTitle.Position = UDim2.fromOffset(0, 0)
	rpTitle.Size = UDim2.new(1, 0, 0, 22)
	rpTitle.Text = "QUEUE"
	rpTitle.Parent = queueSection

	local selectedModeLabel = Instance.new("TextLabel")
	selectedModeLabel.Name = "SelectedMode"
	selectedModeLabel.BackgroundTransparency = 1
	selectedModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	selectedModeLabel.Font = Theme.Font
	selectedModeLabel.TextSize = 13
	selectedModeLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedModeLabel.Position = UDim2.fromOffset(0, 26)
	selectedModeLabel.Size = UDim2.new(1, 0, 0, 16)
	selectedModeLabel.Text = "Selected: --"
	selectedModeLabel.Parent = queueSection

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "QueueStatus"
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Font = Theme.Font
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Position = UDim2.fromOffset(0, 46)
	statusLabel.Size = UDim2.new(1, 0, 0, 18)
	statusLabel.Text = "Idle"
	statusLabel.Parent = queueSection

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyUp"
	readyBtn.AutoButtonColor = false
	readyBtn.BackgroundTransparency = 0.05
	readyBtn.BorderSizePixel = 0
	readyBtn.Size = UDim2.new(1, 0, 0, 48)
	readyBtn.Position = UDim2.new(0, 0, 0, 76)
	readyBtn.Text = "READY UP"
	readyBtn.Font = Theme.FontBold
	readyBtn.TextSize = 16
	readyBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
	readyBtn.Parent = queueSection
	readyBtn.Selectable = true
	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, Theme.CornerSmall)
	readyCorner.Parent = readyBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.AutoButtonColor = false
	cancelBtn.BackgroundTransparency = 0.6
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Size = UDim2.new(1, 0, 0, 40)
	cancelBtn.Position = UDim2.new(0, 0, 0, 130)
	cancelBtn.Text = "CANCEL"
	cancelBtn.Font = Theme.FontSemi
	cancelBtn.TextSize = 14
	cancelBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
	cancelBtn.Parent = queueSection
	cancelBtn.Selectable = true
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, Theme.CornerSmall)
	cancelCorner.Parent = cancelBtn

	local partySection = Instance.new("Frame")
	partySection.Name = "PartySection"
	partySection.BackgroundTransparency = 1
	partySection.Position = UDim2.fromOffset(0, 232)
	partySection.Size = UDim2.new(1, 0, 1, -232)
	partySection.Parent = rightPanel

	local partyPanel = PartyPanel.create(partySection)
	partyPanel:getFrame().Size = UDim2.fromScale(1, 1)

	readyBtn.MouseButton1Click:Connect(function()
		opts.onReadyUp()
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		opts.onCancel()
	end)

	bottomReady.MouseButton1Click:Connect(function()
		opts.onReadyUp()
	end)
	bottomCancel.MouseButton1Click:Connect(function()
		opts.onCancel()
	end)

	-- Pages
	local currentPage: Frame? = nil
	local playPageApi: any = nil
	local selectedModeId = ""

	local function setSelectedMode(modeId: string)
		selectedModeId = modeId
		local modeName = getModeDisplayName(modeId)
		selectedModeLabel.Text = "Selected: " .. modeName
		bottomTitle.Text = "QUEUE • " .. modeName
		if playPageApi and typeof(playPageApi.setSelectedMode) == "function" then
			playPageApi:setSelectedMode(modeId)
		end
	end

	local function setQueueText(text: string)
		statusLabel.Text = text
		bottomStatus.Text = text
	end

	local function setPage(newPage: Frame)
		if currentPage then
			local old = currentPage
			TweenUtil.tween(old, Theme.Anim.Med, {
				Position = UDim2.fromOffset(-20, 0),
				BackgroundTransparency = 1,
			})
			task.delay(Theme.Anim.Med, function()
				if old.Parent then
					old:Destroy()
				end
			end)
		end

		currentPage = newPage
		newPage.Position = UDim2.fromOffset(20, 0)
		newPage.Parent = contentHost
		TweenUtil.tween(newPage, Theme.Anim.Med, { Position = UDim2.fromOffset(0, 0) })
	end

	local function mountRoute(routeId: string)
		contentHost:ClearAllChildren()
		playPageApi = nil

		if routeId == "play" then
			local pageApi = PlayPage.create(contentHost, function(modeId: string)
				setSelectedMode(modeId)
				opts.onSelectMode(modeId)
			end)
			playPageApi = pageApi
			setPage(pageApi:getFrame())
			if selectedModeId ~= "" then
				pageApi:setSelectedMode(selectedModeId)
			end
		else
			setPage(PlaceholderPage.create(contentHost, string.upper(routeId)))
		end
	end

	local isDrawerMode = false
	local drawerOpen = false

	local function closeDrawer()
		if not drawerOpen then
			return
		end
		drawerOpen = false
		TweenUtil.tween(drawer, Theme.Anim.Med, { Position = UDim2.fromOffset(-Config.UI.Nav.RailWidthDrawer, 0) })
		task.delay(Theme.Anim.Med, function()
			if not drawerOpen then
				drawerOverlay.Visible = false
			end
		end)
	end

	local function openDrawer()
		if drawerOpen then
			return
		end
		drawerOpen = true
		drawerOverlay.Visible = true
		drawer.Position = UDim2.fromOffset(-Config.UI.Nav.RailWidthDrawer, 0)
		TweenUtil.tween(drawer, Theme.Anim.Med, { Position = UDim2.fromOffset(0, 0) })
	end

	dimButton.MouseButton1Click:Connect(closeDrawer)
	hamburger.MouseButton1Click:Connect(function()
		if drawerOpen then
			closeDrawer()
		else
			openDrawer()
		end
	end)

	-- Nav
	local nav = NavRail.create(navHost, NAV_ITEMS, function(id: string)
		mountRoute(id)
		if isDrawerMode then
			closeDrawer()
		end
	end)

	-- Ensure nav fills its host
	nav:getFrame().Size = UDim2.fromScale(1, 1)

	-- Responsive: Expanded vs IconOnly vs Drawer + right panel collapse
	local function applyResponsive()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local w = vp.X

		local showRight = w >= Config.UI.RightPanel.MinWidthToShow
		rightPanel.Visible = showRight
		bottomBar.Visible = not showRight
		local bottomH = (not showRight) and 76 or 0
		bottomBar.Position = UDim2.new(0, 0, 1, 0)
		local rightW = showRight and Config.UI.RightPanel.Width or 0
		rightPanel.Size = UDim2.new(0, Config.UI.RightPanel.Width, 1, -bottomH)
		rightPanel.Position = UDim2.new(1, 0, 0, 0)

		local newDrawerMode = w < Config.UI.Nav.IconOnlyMinWidth
		isDrawerMode = newDrawerMode

		if isDrawerMode then
			hamburger.Visible = true
			navHost.Visible = false
			-- Re-parent nav into drawer host (expanded)
			nav:getFrame().Parent = drawerNavHost
			nav:setMode("Expanded")

			navHost.Size = UDim2.new(0, 0, 1, -bottomH)
			contentHost.Position = UDim2.fromOffset(0, 0)
			contentHost.Size = UDim2.new(1, -rightW, 1, -bottomH)
		else
			hamburger.Visible = false
			closeDrawer()

			navHost.Visible = true
			nav:getFrame().Parent = navHost
			nav:getFrame().Size = UDim2.fromScale(1, 1)

			local railMode: "Expanded" | "IconOnly" = "Expanded"
			local railWidth = Config.UI.Nav.RailWidthExpanded

			if w < Config.UI.Nav.ExpandedMinWidth then
				railMode = "IconOnly"
				railWidth = Config.UI.Nav.RailWidthIconOnly
			end

			nav:setMode(railMode)
			navHost.Size = UDim2.new(0, railWidth, 1, -bottomH)
			contentHost.Position = UDim2.fromOffset(railWidth, 0)
			contentHost.Size = UDim2.new(1, -(railWidth + rightW), 1, -bottomH)
		end
	end

	local function bindCamera()
		if not workspace.CurrentCamera then
			return
		end
		applyResponsive()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
	end

	if workspace.CurrentCamera then
		bindCamera()
	else
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			if workspace.CurrentCamera then
				bindCamera()
			end
		end)
	end

	-- Controller UX: auto-select first nav button on gamepad
	GuiService.AutoSelectGuiEnabled = true
	local function tryAutoSelect()
		if not UserInputService.GamepadEnabled then
			return
		end
		local first = nav:getFirstButton()
		if first then
			GuiService.SelectedObject = first
		end
	end
	tryAutoSelect()

	-- initial route
	nav:setActive("play")
	mountRoute("play")
	setSelectedMode("1v1")

	-- App surface
	local app: App = {} :: any
	function app:setQueueStatus(payload: any)
		local state = payload.state
		local msg = payload.message
		if typeof(state) ~= "string" then
			return
		end

		if typeof(payload.modeId) == "string" then
			setSelectedMode(payload.modeId)
		end

		local text = state
		if typeof(msg) == "string" and #msg > 0 then
			text = state .. " • " .. msg
		end
		setQueueText(text)
	end

	return app
end

return MenuApp
