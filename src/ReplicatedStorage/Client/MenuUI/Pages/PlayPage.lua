--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local UiUtil = require(script.Parent.Parent.Util:WaitForChild("UiUtil"))
local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))

export type Api = {
	getFrame: (self: Api) -> Frame,
	setSelectedMode: (self: Api, modeId: string) -> (),
}

local PlayPage = {}

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

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(14, 14)
	grid.CellSize = UDim2.fromOffset(320, 190)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroller

	local pad = Instance.new("UIPadding")
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = scroller

	local activeModeId = ""

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
		footer.Position = UDim2.fromOffset(14, 150)
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
		lock.Position = UDim2.fromOffset(14, 150)
		lock.Size = UDim2.new(1, -28, 0, 16)
		lock.Visible = (mode.comingSoon == true) or (mode.enabled == false)
		lock.Parent = card

		local function applyActive(isActive: boolean)
			card.BackgroundTransparency = isActive and 0.06 or 0.18
		end

		applyActive(mode.id == activeModeId)

		card.MouseButton1Click:Connect(function()
			if mode.enabled == false or mode.comingSoon == true then
				return
			end
			activeModeId = mode.id
			onSelectMode(mode.id)
		end)

		return card, applyActive
	end

	local cardUpdaters: { [string]: (boolean) -> () } = {}

	local function rebuild()
		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		cardUpdaters = {}

		local modes = ModeCatalog.getAll()
		for _, mode in ipairs(modes) do
			local card, applyActive = makeCard(mode)
			cardUpdaters[mode.id] = applyActive
		end

		task.defer(function()
			scroller.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 20)
		end)
	end

	rebuild()

	local api: Api = {} :: any
	function api:getFrame()
		return frame
	end

	function api:setSelectedMode(modeId: string)
		activeModeId = modeId
		for id, fn in pairs(cardUpdaters) do
			fn(id == modeId)
		end
	end

	return api
end

return PlayPage
