--!strict

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local UiUtil = require(script.Parent.Parent.Util:WaitForChild("UiUtil"))

export type NavItem = {
	id: string,
	label: string,
	iconText: string, -- simple fallback icon (we can swap to images later)
}

export type NavRailApi = {
	setMode: (self: NavRailApi, mode: "Expanded" | "IconOnly") -> (),
	setActive: (self: NavRailApi, id: string) -> (),
	getFrame: (self: NavRailApi) -> Frame,
}

local NavRail = {}

function NavRail.create(parent: Instance, items: { NavItem }, onSelect: (id: string) -> ()): NavRailApi
	local frame = Instance.new("Frame")
	frame.Name = "NavRail"
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = frame

	local buttons: { [string]: TextButton } = {}
	local activeId = items[1] and items[1].id or ""
	local mode: "Expanded" | "IconOnly" = "Expanded"

	local function applyButtonLayout(btn: TextButton, item: NavItem)
		local icon = btn:FindFirstChild("Icon") :: TextLabel
		local text = btn:FindFirstChild("Label") :: TextLabel

		if mode == "IconOnly" then
			text.Visible = false
			icon.Position = UDim2.fromOffset(0, 0)
			icon.Size = UDim2.new(1, 0, 1, 0)
		else
			text.Visible = true
			icon.Position = UDim2.fromOffset(12, 0)
			icon.Size = UDim2.new(0, 24, 1, 0)
		end

		icon.Text = item.iconText
		text.Text = item.label
	end

	local function setActive(id: string)
		activeId = id
		for bid, btn in pairs(buttons) do
			if bid == id then
				btn.BackgroundTransparency = 0.05
				btn.TextTransparency = 0
			else
				btn.BackgroundTransparency = 0.6
			end
		end
	end

	for i, item in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Name = "NavButton_" .. item.id
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1, 0, 0, 44)
		btn.AutoButtonColor = false
		btn.BackgroundTransparency = 0.6
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.Parent = frame
		btn.Selectable = true

		local corner = UiUtil.createCorner(Theme.CornerSmall)
		corner.Parent = btn

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.TextColor3 = Color3.fromRGB(235, 235, 235)
		icon.Font = Theme.FontBold
		icon.TextSize = 18
		icon.TextXAlignment = Enum.TextXAlignment.Center
		icon.TextYAlignment = Enum.TextYAlignment.Center
		icon.Parent = btn

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(235, 235, 235)
		label.Font = Theme.FontSemi
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Position = UDim2.fromOffset(44, 0)
		label.Size = UDim2.new(1, -52, 1, 0)
		label.Parent = btn

		applyButtonLayout(btn, item)

		btn.MouseButton1Click:Connect(function()
			onSelect(item.id)
			setActive(item.id)
		end)

		buttons[item.id] = btn
	end

	setActive(activeId)

	local api: NavRailApi = {} :: any
	function api:setMode(newMode)
		mode = newMode
		for _, item in ipairs(items) do
			local btn = buttons[item.id]
			if btn then
				applyButtonLayout(btn, item)
			end
		end
	end

	function api:setActive(id: string)
		if buttons[id] then
			setActive(id)
		end
	end

	function api:getFrame()
		return frame
	end

	return api
end

return NavRail
