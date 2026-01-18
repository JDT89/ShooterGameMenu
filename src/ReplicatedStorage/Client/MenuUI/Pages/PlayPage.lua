--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))
local utilRoot = menuRoot:WaitForChild("Util")
local UiUtil = require(utilRoot:WaitForChild("UiUtil"))
local TweenUtil = require(utilRoot:WaitForChild("TweenUtil"))
local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))

export type Api = {
	getFrame: (self: Api) -> Frame,
	setSelectedMode: (self: Api, modeId: string) -> (),
}

local PlayPage = {}

local function clamp(n: number, lo: number, hi: number): number
	if n < lo then
		return lo
	end
	if n > hi then
		return hi
	end
	return n
end

function PlayPage.create(parent: Instance, onSelectMode: (modeId: string) -> ()): Api
	local frame = Instance.new("Frame")
	frame.Name = "PlayPage"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Theme.Colors.Text
	title.Font = Theme.FontBold
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(0, 0)
	title.Size = UDim2.new(1, 0, 0, 38)
	title.Text = "PLAY"
	title.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Theme.Colors.Subtle
	hint.Font = Theme.Font
	hint.TextSize = 13
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Position = UDim2.fromOffset(0, 36)
	hint.Size = UDim2.new(1, 0, 0, 18)
	hint.Text = "Select a mode to queue. More modes can be added any time via ModeCatalog."
	hint.Parent = frame

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "ModeScroller"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromOffset(0, 64)
	scroller.Size = UDim2.new(1, 0, 1, -64)
	scroller.CanvasSize = UDim2.fromOffset(0, 0)
	scroller.ScrollBarThickness = 6
	scroller.ScrollBarImageTransparency = 0.55
	scroller.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = scroller

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(14, 14)
	grid.CellSize = UDim2.fromOffset(320, 190)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroller

	local activeModeId = ""

	type CardParts = {
		button: TextButton,
		stroke: UIStroke,
		focus: Frame,
		lockPill: Frame?,
	}

	local cards: { [string]: CardParts } = {}

	local function updateCanvas()
		scroller.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 20)
	end

	local function updateGridForWidth(width: number)
		-- Responsive columns. Keeps cards readable across PC/console/mobile landscape.
		local columns = 1
		if width >= 1100 then
			columns = 3
		elseif width >= 720 then
			columns = 2
		end

		local paddingX = 12
		local spacing = 14
		local available = math.max(300, width - paddingX)
		local cellW = (available - ((columns - 1) * spacing)) / columns
		cellW = clamp(cellW, 280, 390)
		local cellH = clamp(math.floor(cellW * 0.62), 172, 236)
		grid.CellSize = UDim2.fromOffset(cellW, cellH)
	end

	local function setSelected(modeId: string)
		activeModeId = modeId
		for id, parts in pairs(cards) do
			local isActive = (id == modeId)
			if isActive then
				TweenUtil.tween(parts.button, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
				parts.stroke.Color = Theme.Colors.Accent
				parts.stroke.Transparency = 0.35
			else
				TweenUtil.tween(parts.button, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonIdle })
				parts.stroke.Color = Theme.Colors.Stroke
				parts.stroke.Transparency = Theme.Alpha.Stroke
			end
		end
	end

	local function createPill(parentInst: Instance, text: string, bg: Color3, fg: Color3)
		local pill = Instance.new("Frame")
		pill.Name = "Pill"
		pill.BackgroundColor3 = bg
		pill.BackgroundTransparency = 0.12
		pill.BorderSizePixel = 0
		pill.AnchorPoint = Vector2.new(1, 0)
		pill.Position = UDim2.new(1, -12, 0, 12)
		pill.Size = UDim2.fromOffset(124, 26)
		pill.Parent = parentInst
		UiUtil.createCorner(Theme.CornerPill).Parent = pill
		UiUtil.createStroke(Theme.Colors.Stroke, 0.90, 1).Parent = pill

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.TextColor3 = fg
		label.Font = Theme.FontBold
		label.TextSize = 12
		label.Text = text
		label.Size = UDim2.fromScale(1, 1)
		label.Parent = pill

		return pill
	end

	local function makeCard(mode): CardParts
		local card = Instance.new("TextButton")
		card.Name = "ModeCard_" .. mode.id
		card.AutoButtonColor = false
		card.BackgroundColor3 = Theme.Colors.Panel2
		card.BackgroundTransparency = Theme.Alpha.ButtonIdle
		card.BorderSizePixel = 0
		card.Text = ""
		card.Parent = scroller
		card.Selectable = true

		UiUtil.createCorner(Theme.Corner).Parent = card
		UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = card

		local stroke = UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1)
		stroke.Parent = card

		-- Focus ring (controller navigation)
		local focus = Instance.new("Frame")
		focus.Name = "FocusRing"
		focus.BackgroundTransparency = 1
		focus.BorderSizePixel = 0
		focus.Size = UDim2.fromScale(1, 1)
		focus.Visible = false
		focus.Parent = card
		UiUtil.createCorner(Theme.Corner).Parent = focus
		UiUtil.createStroke(Theme.Colors.Accent, 0.30, 2).Parent = focus

		local header = Instance.new("TextLabel")
		header.BackgroundTransparency = 1
		header.TextColor3 = Theme.Colors.Text
		header.Font = Theme.FontBold
		header.TextSize = 22
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Position = UDim2.fromOffset(14, 12)
		header.Size = UDim2.new(1, -28, 0, 26)
		header.Text = mode.displayName
		header.Parent = card

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.TextColor3 = Theme.Colors.Muted
		sub.Font = Theme.FontSemi
		sub.TextSize = 14
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Position = UDim2.fromOffset(14, 42)
		sub.Size = UDim2.new(1, -28, 0, 18)
		sub.Text = mode.subtitle or ""
		sub.Parent = card

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Theme.Colors.Subtle
		desc.Font = Theme.Font
		desc.TextSize = 13
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Position = UDim2.fromOffset(14, 70)
		desc.Size = UDim2.new(1, -28, 0, 64)
		desc.TextWrapped = true
		desc.Text = mode.description or ""
		desc.Parent = card

		local footer = Instance.new("TextLabel")
		footer.BackgroundTransparency = 1
		footer.TextColor3 = Theme.Colors.Muted
		footer.Font = Theme.FontSemi
		footer.TextSize = 12
		footer.TextXAlignment = Enum.TextXAlignment.Left
		footer.AnchorPoint = Vector2.new(0, 1)
		footer.Position = UDim2.new(0, 14, 1, -12)
		footer.Size = UDim2.new(1, -28, 0, 16)
		footer.Text = string.format("%d-%d players", mode.minPlayers, mode.maxPlayers)
		footer.Parent = card

		local lockPill: Frame? = nil
		local locked = (mode.comingSoon == true) or (mode.enabled == false)
		if locked then
			lockPill = createPill(card, "COMING SOON", Theme.Colors.Warning, Color3.fromRGB(20, 14, 8))
		end

		local function setHover(isHover: boolean)
			if activeModeId == mode.id then
				return
			end
			TweenUtil.tween(card, Theme.Anim.Fast, {
				BackgroundTransparency = isHover and Theme.Alpha.ButtonHover or Theme.Alpha.ButtonIdle,
			})
		end

		card.MouseEnter:Connect(function()
			setHover(true)
		end)
		card.MouseLeave:Connect(function()
			setHover(false)
		end)

		card.SelectionGained:Connect(function()
			focus.Visible = true
			setHover(true)
		end)
		card.SelectionLost:Connect(function()
			focus.Visible = false
			setHover(false)
		end)

		card.MouseButton1Click:Connect(function()
			if locked then
				return
			end
			setSelected(mode.id)
			onSelectMode(mode.id)
		end)

		return {
			button = card,
			stroke = stroke,
			focus = focus,
			lockPill = lockPill,
		}
	end

	local function rebuild()
		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		cards = {}

		local modes = ModeCatalog.getAll()
		for _, mode in ipairs(modes) do
			local parts = makeCard(mode)
			cards[mode.id] = parts
		end

		updateCanvas()
	end

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateGridForWidth(scroller.AbsoluteSize.X)
	end)
	updateGridForWidth(scroller.AbsoluteSize.X)

	rebuild()

	local api: Api = {} :: any
	function api:getFrame()
		return frame
	end

	function api:setSelectedMode(modeId: string)
		if cards[modeId] then
			setSelected(modeId)
		end
	end

	return api
end

return PlayPage
