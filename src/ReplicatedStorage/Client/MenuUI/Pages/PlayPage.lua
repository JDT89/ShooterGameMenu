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
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Theme.FontBold
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(0, 0)
	title.Size = UDim2.new(1, 0, 0, 38)
	title.Text = "PLAY"
	title.Parent = frame

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "ModeScroller"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromOffset(0, 50)
	scroller.Size = UDim2.new(1, 0, 1, -50)
	scroller.CanvasSize = UDim2.fromOffset(0, 0)
	scroller.ScrollBarThickness = 6
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

	local cardUpdaters: { [string]: (boolean) -> () } = {}

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

		local paddingX = 12 -- approximate padding+scrollbar
		local spacing = 14
		local available = math.max(320, width - paddingX)
		local cellW = (available - ((columns - 1) * spacing)) / columns
		cellW = clamp(cellW, 280, 380)
		local cellH = clamp(math.floor(cellW * 0.6), 170, 220)
		grid.CellSize = UDim2.fromOffset(cellW, cellH)
	end

	local function setSelected(modeId: string)
		activeModeId = modeId
		for id, fn in pairs(cardUpdaters) do
			fn(id == modeId)
		end
	end

	local function makeCard(mode)
		local card = Instance.new("TextButton")
		card.Name = "ModeCard_" .. mode.id
		card.AutoButtonColor = false
		card.BackgroundTransparency = 0.18
		card.BorderSizePixel = 0
		card.Text = ""
		card.Parent = scroller
		card.Selectable = true

		UiUtil.createCorner(Theme.Corner).Parent = card

		local header = Instance.new("TextLabel")
		header.BackgroundTransparency = 1
		header.TextColor3 = Color3.fromRGB(245, 245, 245)
		header.Font = Theme.FontBold
		header.TextSize = 22
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Position = UDim2.fromOffset(14, 12)
		header.Size = UDim2.new(1, -28, 0, 26)
		header.Text = mode.displayName
		header.Parent = card

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.TextColor3 = Color3.fromRGB(210, 210, 210)
		sub.Font = Theme.Font
		sub.TextSize = 14
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Position = UDim2.fromOffset(14, 42)
		sub.Size = UDim2.new(1, -28, 0, 18)
		sub.Text = mode.subtitle or ""
		sub.Parent = card

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(180, 180, 180)
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
		footer.TextColor3 = Color3.fromRGB(200, 200, 200)
		footer.Font = Theme.FontSemi
		footer.TextSize = 12
		footer.TextXAlignment = Enum.TextXAlignment.Left
		footer.Position = UDim2.fromOffset(14, -18)
		footer.AnchorPoint = Vector2.new(0, 1)
		footer.Size = UDim2.new(1, -28, 0, 16)
		footer.Text = string.format("%d-%d players", mode.minPlayers, mode.maxPlayers)
		footer.Parent = card

		local lock = Instance.new("TextLabel")
		lock.Name = "Lock"
		lock.BackgroundTransparency = 1
		lock.TextColor3 = Color3.fromRGB(255, 255, 255)
		lock.Font = Theme.FontBold
		lock.TextSize = 16
		lock.Text = "🔒 COMING SOON"
		lock.Position = UDim2.fromOffset(14, -18)
		lock.AnchorPoint = Vector2.new(0, 1)
		lock.Size = UDim2.new(1, -28, 0, 16)
		lock.Visible = (mode.comingSoon == true) or (mode.enabled == false)
		lock.Parent = card

		local function applyActive(isActive: boolean)
			TweenUtil.tween(card, Theme.Anim.Fast, {
				BackgroundTransparency = isActive and 0.06 or 0.18,
			})
		end

		applyActive(mode.id == activeModeId)

		card.MouseButton1Click:Connect(function()
			if mode.enabled == false or mode.comingSoon == true then
				return
			end
			setSelected(mode.id)
			onSelectMode(mode.id)
		end)

		return card, applyActive
	end

	local function rebuild()
		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		cardUpdaters = {}

		local modes = ModeCatalog.getAll()
		for _, mode in ipairs(modes) do
			local _, applyActive = makeCard(mode)
			cardUpdaters[mode.id] = applyActive
		end

		updateCanvas()
	end

	-- Live canvas sizing
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
		setSelected(modeId)
	end

	return api
end

return PlayPage
