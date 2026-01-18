--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local menuRoot = script.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))

local utilRoot = menuRoot:WaitForChild("Util")
local UiUtil = require(utilRoot:WaitForChild("UiUtil"))
local TweenUtil = require(utilRoot:WaitForChild("TweenUtil"))

local componentsRoot = menuRoot:WaitForChild("Components")
local NavRail = require(componentsRoot:WaitForChild("NavRail"))

local pagesRoot = menuRoot:WaitForChild("Pages")
local PlaceholderPage = require(pagesRoot:WaitForChild("PlaceholderPage"))
local PlayPage = require(pagesRoot:WaitForChild("PlayPage"))

local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))

export type App = {
	setQueueStatus: (self: App, payload: any) -> (),
}

export type MountOptions = {
	onSelectMode: (modeId: string) -> (),
	onReadyUp: () -> (),
	onCancel: () -> (),
}

local MenuApp = {}

local NAV_ITEMS = {
	{ id = "play", label = "PLAY", iconText = "▶" },
	{ id = "armory", label = "ARMORY", iconText = "⟡" },
	{ id = "cosmetics", label = "COSMETICS", iconText = "✦" },
	{ id = "clans", label = "CLANS", iconText = "⌁" },
	{ id = "friends", label = "FRIENDS", iconText = "☺" },
	{ id = "profile", label = "PROFILE", iconText = "👤" },
	{ id = "settings", label = "SETTINGS", iconText = "⚙" },
	{ id = "patch", label = "PATCH NOTES", iconText = "!" },
}

local function stylePanel(frame: Frame, strong: boolean)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BackgroundTransparency = strong and Theme.Alpha.PanelStrong or Theme.Alpha.Panel
	UiUtil.createCorner(Theme.Corner).Parent = frame
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = frame
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel, 90).Parent = frame
end

local function styleButtonPrimary(btn: TextButton)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.BackgroundColor3 = Theme.Colors.Accent
	btn.BackgroundTransparency = 0.05
	btn.TextColor3 = Theme.Colors.Text
	btn.Font = Theme.FontBold
	btn.TextSize = 14
	UiUtil.createCorner(Theme.CornerSmall).Parent = btn
	UiUtil.createStroke(Theme.Colors.Accent, 0.35, 1).Parent = btn
	UiUtil.createGradient2(Theme.Colors.Accent, Theme.Colors.AccentSoft, 90).Parent = btn
end

local function styleButtonSecondary(btn: TextButton)
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.BackgroundColor3 = Theme.Colors.Panel2
	btn.BackgroundTransparency = Theme.Alpha.ButtonIdle
	btn.TextColor3 = Theme.Colors.Text
	btn.Font = Theme.FontSemi
	btn.TextSize = 14
	UiUtil.createCorner(Theme.CornerSmall).Parent = btn
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = btn
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = btn
end

local function styleButtonHover(btn: TextButton, baseAlpha: number, hoverAlpha: number)
	btn.MouseEnter:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = hoverAlpha })
	end)
	btn.MouseLeave:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = baseAlpha })
	end)
	btn.MouseButton1Down:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
	end)
	btn.MouseButton1Up:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = hoverAlpha })
	end)
end

local function getModeDisplayName(modeId: string): string
	local mode = ModeCatalog.getById(modeId)
	if mode and typeof(mode.displayName) == "string" then
		return mode.displayName
	end
	return modeId
end

function MenuApp.mount(playerGui: PlayerGui, opts: MountOptions): App
	local player = Players.LocalPlayer

	local existing = playerGui:FindFirstChild("ShooterMenu")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ShooterMenu"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- Root surface
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BorderSizePixel = 0
	root.BackgroundColor3 = Theme.Colors.Background
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	-- Background gradient + subtle vignette
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = Theme.Colors.Background2
	bg.BackgroundTransparency = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = root
	UiUtil.createGradient2(Theme.Colors.Background2, Theme.Colors.Background, 90).Parent = bg

	local vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.BorderSizePixel = 0
	vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	vignette.BackgroundTransparency = 0.65
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Parent = root
	local vg = Instance.new("UIGradient")
	vg.Rotation = 90
	vg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.75),
	})
	vg.Parent = vignette

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BorderSizePixel = 0
	topBar.BackgroundColor3 = Theme.Colors.Panel
	topBar.BackgroundTransparency = Theme.Alpha.PanelStrong
	topBar.Size = UDim2.new(1, 0, 0, 64)
	topBar.Parent = root
	UiUtil.createStroke(Theme.Colors.Stroke, 0.92, 1).Parent = topBar
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel, 90).Parent = topBar

	local hamburger = Instance.new("TextButton")
	hamburger.Name = "Hamburger"
	hamburger.AutoButtonColor = false
	hamburger.BorderSizePixel = 0
	hamburger.BackgroundColor3 = Theme.Colors.Panel2
	hamburger.BackgroundTransparency = Theme.Alpha.ButtonIdle
	hamburger.Size = UDim2.fromOffset(44, 44)
	hamburger.Position = UDim2.fromOffset(12, 10)
	hamburger.Text = "≡"
	hamburger.TextColor3 = Theme.Colors.Text
	hamburger.Font = Theme.FontBold
	hamburger.TextSize = 20
	hamburger.Visible = false
	hamburger.Parent = topBar
	UiUtil.createCorner(Theme.CornerSmall).Parent = hamburger
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = hamburger
	styleButtonHover(hamburger, hamburger.BackgroundTransparency, Theme.Alpha.ButtonHover)

	-- Profile card (top-right)
	local profileCard = Instance.new("Frame")
	profileCard.Name = "ProfileCard"
	profileCard.AnchorPoint = Vector2.new(1, 0.5)
	profileCard.Position = UDim2.new(1, -14, 0.5, 0)
	profileCard.Size = UDim2.fromOffset(440, 52)
	profileCard.Parent = topBar
	stylePanel(profileCard, true)

	local pPad = Instance.new("UIPadding")
	pPad.PaddingLeft = UDim.new(0, 12)
	pPad.PaddingRight = UDim.new(0, 12)
	pPad.PaddingTop = UDim.new(0, 8)
	pPad.PaddingBottom = UDim.new(0, 8)
	pPad.Parent = profileCard

	local headshot = Instance.new("ImageLabel")
	headshot.Name = "Avatar"
	headshot.BackgroundTransparency = 1
	headshot.Size = UDim2.fromOffset(34, 34)
	headshot.Image = UiUtil.getHeadshot(player.UserId)
	headshot.Parent = profileCard
	UiUtil.createCorner(Theme.CornerSmall).Parent = headshot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Theme.Colors.Text
	nameLabel.Font = Theme.FontSemi
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.fromOffset(44, 0)
	nameLabel.Size = UDim2.new(1, -44, 0, 18)
	nameLabel.Text = player.DisplayName
	nameLabel.Parent = profileCard

	local lvlLabel = Instance.new("TextLabel")
	lvlLabel.Name = "Level"
	lvlLabel.BackgroundTransparency = 1
	lvlLabel.TextColor3 = Theme.Colors.Muted
	lvlLabel.Font = Theme.Font
	lvlLabel.TextSize = 12
	lvlLabel.TextXAlignment = Enum.TextXAlignment.Left
	lvlLabel.Position = UDim2.fromOffset(44, 18)
	lvlLabel.Size = UDim2.new(1, -44, 0, 16)
	lvlLabel.Text = "Lv. 1 • 0/100 XP"
	lvlLabel.Parent = profileCard

	local xpBar = Instance.new("Frame")
	xpBar.Name = "XpBar"
	xpBar.BorderSizePixel = 0
	xpBar.BackgroundColor3 = Theme.Colors.Panel2
	xpBar.BackgroundTransparency = 0.15
	xpBar.Position = UDim2.new(0, 44, 1, -10)
	xpBar.Size = UDim2.new(1, -56, 0, 6)
	xpBar.Parent = profileCard
	UiUtil.createCorner(Theme.CornerPill).Parent = xpBar

	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.BorderSizePixel = 0
	xpFill.BackgroundColor3 = Theme.Colors.Accent
	xpFill.BackgroundTransparency = 0.05
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.Parent = xpBar
	UiUtil.createCorner(Theme.CornerPill).Parent = xpFill
	UiUtil.createGradient2(Theme.Colors.Accent, Theme.Colors.AccentSoft, 90).Parent = xpFill

	local function updateProfileFromAttributes()
		local lvl = player:GetAttribute("AccountLevel")
		local xp = player:GetAttribute("AccountXp")
		local xpToNext = player:GetAttribute("AccountXpToNext")

		local levelNum = (typeof(lvl) == "number" and math.max(1, math.floor(lvl))) or 1
		local xpNum = (typeof(xp) == "number" and math.max(0, math.floor(xp))) or 0
		local toNextNum = (typeof(xpToNext) == "number" and math.max(1, math.floor(xpToNext))) or 100

		lvlLabel.Text = ("Lv. %d • %d/%d XP"):format(levelNum, xpNum, toNextNum)
		local pct = math.clamp(xpNum / toNextNum, 0, 1)
		xpFill.Size = UDim2.fromScale(pct, 1)
	end

	updateProfileFromAttributes()
	player:GetAttributeChangedSignal("AccountLevel"):Connect(updateProfileFromAttributes)
	player:GetAttributeChangedSignal("AccountXp"):Connect(updateProfileFromAttributes)
	player:GetAttributeChangedSignal("AccountXpToNext"):Connect(updateProfileFromAttributes)

	-- Main area
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.BorderSizePixel = 0
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromOffset(0, 64)
	main.Size = UDim2.new(1, 0, 1, -64)
	main.Parent = root

	-- Nav host
	local navHost = Instance.new("Frame")
	navHost.Name = "NavHost"
	navHost.BackgroundTransparency = 1
	navHost.Position = UDim2.fromOffset(0, 0)
	navHost.Size = UDim2.new(0, Config.UI.Nav.RailWidthExpanded, 1, 0)
	navHost.Parent = main

	-- Content host + container (IMPORTANT: pages mount into contentContainer; we do NOT ClearAllChildren on contentHost)
	local contentHost = Instance.new("Frame")
	contentHost.Name = "ContentHost"
	contentHost.BackgroundTransparency = 1
	contentHost.Position = UDim2.fromOffset(Config.UI.Nav.RailWidthExpanded, 0)
	contentHost.Size = UDim2.new(1, -(Config.UI.Nav.RailWidthExpanded + Config.UI.RightPanel.Width), 1, 0)
	contentHost.Parent = main

	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.BackgroundTransparency = 1
	contentContainer.Size = UDim2.fromScale(1, 1)
	contentContainer.Parent = contentHost

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 18)
	contentPad.PaddingRight = UDim.new(0, 18)
	contentPad.PaddingTop = UDim.new(0, 18)
	contentPad.PaddingBottom = UDim.new(0, 18)
	contentPad.Parent = contentContainer

	-- Right panel
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.AnchorPoint = Vector2.new(1, 0)
	rightPanel.Position = UDim2.new(1, 0, 0, 0)
	rightPanel.Size = UDim2.fromOffset(Config.UI.RightPanel.Width, 0)
	rightPanel.Parent = main
	stylePanel(rightPanel, false)

	local rightPad = Instance.new("UIPadding")
	rightPad.PaddingTop = UDim.new(0, 14)
	rightPad.PaddingLeft = UDim.new(0, 14)
	rightPad.PaddingRight = UDim.new(0, 14)
	rightPad.PaddingBottom = UDim.new(0, 14)
	rightPad.Parent = rightPanel

	-- Bottom queue bar (mobile/compact)
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.AnchorPoint = Vector2.new(0, 1)
	bottomBar.Position = UDim2.new(0, 0, 1, 0)
	bottomBar.Size = UDim2.new(1, 0, 0, 76)
	bottomBar.Visible = false
	bottomBar.Parent = main
	stylePanel(bottomBar, false)

	local bottomPad = Instance.new("UIPadding")
	bottomPad.PaddingLeft = UDim.new(0, 14)
	bottomPad.PaddingRight = UDim.new(0, 14)
	bottomPad.PaddingTop = UDim.new(0, 12)
	bottomPad.PaddingBottom = UDim.new(0, 12)
	bottomPad.Parent = bottomBar

	local bottomLeft = Instance.new("Frame")
	bottomLeft.BackgroundTransparency = 1
	bottomLeft.Size = UDim2.new(1, -220, 1, 0)
	bottomLeft.Parent = bottomBar

	local bottomTitle = Instance.new("TextLabel")
	bottomTitle.BackgroundTransparency = 1
	bottomTitle.TextColor3 = Theme.Colors.Text
	bottomTitle.Font = Theme.FontBold
	bottomTitle.TextSize = 14
	bottomTitle.TextXAlignment = Enum.TextXAlignment.Left
	bottomTitle.Size = UDim2.new(1, 0, 0, 18)
	bottomTitle.Text = "QUEUE"
	bottomTitle.Parent = bottomLeft

	local bottomStatus = Instance.new("TextLabel")
	bottomStatus.BackgroundTransparency = 1
	bottomStatus.TextColor3 = Theme.Colors.Muted
	bottomStatus.Font = Theme.Font
	bottomStatus.TextSize = 13
	bottomStatus.TextXAlignment = Enum.TextXAlignment.Left
	bottomStatus.Position = UDim2.fromOffset(0, 20)
	bottomStatus.Size = UDim2.new(1, 0, 0, 18)
	bottomStatus.Text = "Idle"
	bottomStatus.Parent = bottomLeft

	local bottomButtons = Instance.new("Frame")
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
	bottomReady.Size = UDim2.fromOffset(120, 44)
	bottomReady.Text = "READY"
	bottomReady.Selectable = true
	bottomReady.Parent = bottomButtons
	styleButtonPrimary(bottomReady)

	local bottomCancel = Instance.new("TextButton")
	bottomCancel.Size = UDim2.fromOffset(90, 44)
	bottomCancel.Text = "CANCEL"
	bottomCancel.Selectable = true
	bottomCancel.Parent = bottomButtons
	styleButtonSecondary(bottomCancel)
	styleButtonHover(bottomCancel, bottomCancel.BackgroundTransparency, Theme.Alpha.ButtonHover)

	-- Drawer overlay (mobile)
	local drawerOverlay = Instance.new("Frame")
	drawerOverlay.Name = "DrawerOverlay"
	drawerOverlay.BackgroundTransparency = 1
	drawerOverlay.Visible = false
	drawerOverlay.Size = UDim2.fromScale(1, 1)
	drawerOverlay.ZIndex = 50
	drawerOverlay.Parent = root

	local dim = Instance.new("Frame")
	dim.BorderSizePixel = 0
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 50
	dim.Parent = drawerOverlay

	local dimButton = Instance.new("TextButton")
	dimButton.BackgroundTransparency = 1
	dimButton.Text = ""
	dimButton.AutoButtonColor = false
	dimButton.Size = UDim2.fromScale(1, 1)
	dimButton.ZIndex = 51
	dimButton.Parent = drawerOverlay

	local drawer = Instance.new("Frame")
	drawer.Name = "Drawer"
	drawer.BorderSizePixel = 0
	drawer.BackgroundColor3 = Theme.Colors.Panel
	drawer.BackgroundTransparency = Theme.Alpha.PanelStrong
	drawer.Size = UDim2.new(0, Config.UI.Nav.RailWidthDrawer, 1, 0)
	drawer.Position = UDim2.fromOffset(-Config.UI.Nav.RailWidthDrawer, 0)
	drawer.ZIndex = 52
	drawer.Parent = drawerOverlay
	UiUtil.createCorner(Theme.Corner).Parent = drawer
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = drawer
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel, 90).Parent = drawer

	local drawerPad = Instance.new("UIPadding")
	drawerPad.PaddingTop = UDim.new(0, 10)
	drawerPad.PaddingBottom = UDim.new(0, 10)
	drawerPad.PaddingLeft = UDim.new(0, 10)
	drawerPad.PaddingRight = UDim.new(0, 10)
	drawerPad.Parent = drawer

	local drawerTitle = Instance.new("TextLabel")
	drawerTitle.BackgroundTransparency = 1
	drawerTitle.TextColor3 = Theme.Colors.Text
	drawerTitle.Font = Theme.FontBold
	drawerTitle.TextSize = 16
	drawerTitle.TextXAlignment = Enum.TextXAlignment.Left
	drawerTitle.Size = UDim2.new(1, 0, 0, 20)
	drawerTitle.ZIndex = 53
	drawerTitle.Text = Config.GameName
	drawerTitle.Parent = drawer

	local drawerNavHost = Instance.new("Frame")
	drawerNavHost.BackgroundTransparency = 1
	drawerNavHost.Position = UDim2.fromOffset(0, 28)
	drawerNavHost.Size = UDim2.new(1, 0, 1, -28)
	drawerNavHost.ZIndex = 53
	drawerNavHost.Parent = drawer

	-- Queue + party content (right panel)
	local queueSection = Instance.new("Frame")
	queueSection.BackgroundTransparency = 1
	queueSection.Size = UDim2.new(1, 0, 0, 220)
	queueSection.Parent = rightPanel

	local rpTitle = Instance.new("TextLabel")
	rpTitle.BackgroundTransparency = 1
	rpTitle.TextColor3 = Theme.Colors.Text
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
	selectedModeLabel.TextColor3 = Theme.Colors.Muted
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
	statusLabel.TextColor3 = Theme.Colors.Muted
	statusLabel.Font = Theme.Font
	statusLabel.TextSize = 13
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Position = UDim2.fromOffset(0, 46)
	statusLabel.Size = UDim2.new(1, 0, 0, 18)
	statusLabel.Text = "Idle"
	statusLabel.Parent = queueSection

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyUp"
	readyBtn.Size = UDim2.new(1, 0, 0, 54)
	readyBtn.Position = UDim2.fromOffset(0, 78)
	readyBtn.Text = "READY UP"
	readyBtn.Selectable = true
	readyBtn.Parent = queueSection
	styleButtonPrimary(readyBtn)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.Size = UDim2.new(1, 0, 0, 46)
	cancelBtn.Position = UDim2.fromOffset(0, 140)
	cancelBtn.Text = "CANCEL"
	cancelBtn.Selectable = true
	cancelBtn.Parent = queueSection
	styleButtonSecondary(cancelBtn)
	styleButtonHover(cancelBtn, cancelBtn.BackgroundTransparency, Theme.Alpha.ButtonHover)

	-- Party section (placeholder)
	local partySection = Instance.new("Frame")
	partySection.BackgroundTransparency = 1
	partySection.Position = UDim2.fromOffset(0, 246)
	partySection.Size = UDim2.new(1, 0, 1, -246)
	partySection.Parent = rightPanel

	local partyTitle = Instance.new("TextLabel")
	partyTitle.BackgroundTransparency = 1
	partyTitle.TextColor3 = Theme.Colors.Text
	partyTitle.Font = Theme.FontBold
	partyTitle.TextSize = 18
	partyTitle.TextXAlignment = Enum.TextXAlignment.Left
	partyTitle.Position = UDim2.fromOffset(0, 0)
	partyTitle.Size = UDim2.new(1, 0, 0, 22)
	partyTitle.Text = "PARTY"
	partyTitle.Parent = partySection

	local partySub = Instance.new("TextLabel")
	partySub.BackgroundTransparency = 1
	partySub.TextColor3 = Theme.Colors.Subtle
	partySub.Font = Theme.Font
	partySub.TextSize = 12
	partySub.TextXAlignment = Enum.TextXAlignment.Left
	partySub.Position = UDim2.fromOffset(0, 26)
	partySub.Size = UDim2.new(1, 0, 0, 16)
	partySub.Text = "Invite + party syncing ships next phase."
	partySub.Parent = partySection

	local memberCard = Instance.new("Frame")
	memberCard.Name = "MemberCard"
	memberCard.Position = UDim2.fromOffset(0, 54)
	memberCard.Size = UDim2.new(1, 0, 0, 52)
	memberCard.Parent = partySection
	stylePanel(memberCard, true)

	local mPad = Instance.new("UIPadding")
	mPad.PaddingLeft = UDim.new(0, 12)
	mPad.PaddingRight = UDim.new(0, 12)
	mPad.PaddingTop = UDim.new(0, 8)
	mPad.PaddingBottom = UDim.new(0, 8)
	mPad.Parent = memberCard

	local mName = Instance.new("TextLabel")
	mName.BackgroundTransparency = 1
	mName.TextColor3 = Theme.Colors.Text
	mName.Font = Theme.FontSemi
	mName.TextSize = 14
	mName.TextXAlignment = Enum.TextXAlignment.Left
	mName.Size = UDim2.new(1, 0, 0, 18)
	mName.Text = player.DisplayName
	mName.Parent = memberCard

	local mRole = Instance.new("TextLabel")
	mRole.BackgroundTransparency = 1
	mRole.TextColor3 = Theme.Colors.Accent
	mRole.Font = Theme.Font
	mRole.TextSize = 12
	mRole.TextXAlignment = Enum.TextXAlignment.Left
	mRole.Position = UDim2.fromOffset(0, 18)
	mRole.Size = UDim2.new(1, 0, 0, 16)
	mRole.Text = "Leader"
	mRole.Parent = memberCard

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "Invite"
	inviteBtn.AnchorPoint = Vector2.new(0, 1)
	inviteBtn.Position = UDim2.new(0, 0, 1, 0)
	inviteBtn.Size = UDim2.new(1, 0, 0, 46)
	inviteBtn.Text = "INVITE"
	inviteBtn.Selectable = false
	inviteBtn.Parent = partySection
	styleButtonSecondary(inviteBtn)
	inviteBtn.TextTransparency = 0.35
	inviteBtn.BackgroundTransparency = 0.45

	-- State / page routing
	local selectedModeId = ""
	local currentPage: Frame? = nil
	local playPageApi: any = nil

	local function setSelectedMode(modeId: string)
		selectedModeId = modeId
		local modeName = getModeDisplayName(modeId)
		selectedModeLabel.Text = "Selected: " .. modeName
		bottomTitle.Text = "QUEUE • " .. modeName
		if playPageApi and typeof(playPageApi.setSelectedMode) == "function" then
			playPageApi:setSelectedMode(modeId)
		end
	end

	local function setQueueText(text: string, color: Color3?)
		statusLabel.Text = text
		bottomStatus.Text = text
		statusLabel.TextColor3 = color or Theme.Colors.Muted
		bottomStatus.TextColor3 = color or Theme.Colors.Muted
	end

	local function setPage(newPage: Frame)
		if currentPage and currentPage.Parent then
			local old = currentPage
			TweenUtil.tween(old, Theme.Anim.Med, { Position = UDim2.fromOffset(-20, 0) })
			task.delay(Theme.Anim.Med, function()
				if old.Parent then
					old:Destroy()
				end
			end)
		end

		currentPage = newPage
		newPage.Position = UDim2.fromOffset(20, 0)
		newPage.Parent = contentContainer
		TweenUtil.tween(newPage, Theme.Anim.Med, { Position = UDim2.fromOffset(0, 0) })
	end

	local function mountRoute(routeId: string)
		playPageApi = nil

		if routeId == "play" then
			local pageApi = PlayPage.create(contentContainer, function(modeId: string)
				setSelectedMode(modeId)
				opts.onSelectMode(modeId)
			end)
			playPageApi = pageApi
			setPage(pageApi:getFrame())
			if selectedModeId ~= "" then
				pageApi:setSelectedMode(selectedModeId)
			end
		else
			setPage(PlaceholderPage.create(contentContainer, string.upper(routeId)))
		end
	end

	-- Drawer logic
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
	nav:getFrame().Size = UDim2.fromScale(1, 1)

	-- Queue buttons
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

	-- Responsive
	local function applyResponsive()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local w = vp.X

		local showRight = w >= Config.UI.RightPanel.MinWidthToShow
		rightPanel.Visible = showRight
		bottomBar.Visible = not showRight
		local bottomH = (not showRight) and 76 or 0

		local rightW = showRight and Config.UI.RightPanel.Width or 0
		rightPanel.Size = UDim2.new(0, Config.UI.RightPanel.Width, 1, -bottomH)

		local newDrawerMode = w < Config.UI.Nav.IconOnlyMinWidth
		isDrawerMode = newDrawerMode

		if isDrawerMode then
			hamburger.Visible = true
			navHost.Visible = false
			nav:getFrame().Parent = drawerNavHost
			nav:setMode("Expanded")

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

	-- Initial route + selection
	nav:setActive("play")
	mountRoute("play")
	setSelectedMode("1v1")
	setQueueText("Idle", Theme.Colors.Muted)

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

		local color = Theme.Colors.Muted
		local s = string.lower(state)
		if s == "searching" then
			color = Theme.Colors.Accent
		elseif s == "found" then
			color = Theme.Colors.Success
		elseif s == "teleporting" then
			color = Theme.Colors.Warning
		elseif s == "error" then
			color = Theme.Colors.Danger
		end

		setQueueText(text, color)
	end

	return app
end

return MenuApp
