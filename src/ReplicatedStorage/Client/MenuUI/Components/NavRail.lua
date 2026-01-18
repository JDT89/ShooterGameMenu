--!strict

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))

local utilRoot = menuRoot:WaitForChild("Util")
local UiUtil = require(utilRoot:WaitForChild("UiUtil"))
local TweenUtil = require(utilRoot:WaitForChild("TweenUtil"))

export type NavItem = {
	id: string,
	label: string,
	iconText: string, -- simple fallback icon (we can swap to images later)
}

export type NavRailApi = {
	setMode: (self: NavRailApi, mode: "Expanded" | "IconOnly") -> (),
	setActive: (self: NavRailApi, id: string) -> (),
	getFrame: (self: NavRailApi) -> Frame,
	getButton: (self: NavRailApi, id: string) -> TextButton?,
	getFirstButton: (self: NavRailApi) -> TextButton?,
}

local NavRail = {}

local ACTIVE_TRANSPARENCY = 0.06
local HOVER_TRANSPARENCY = 0.18
local IDLE_TRANSPARENCY = 0.62

function NavRail.create(parent: Instance, items: { NavItem }, onSelect: (id: string) -> ()): NavRailApi
	local frame = Instance.new("Frame")
	frame.Name = "NavRail"
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	UiUtil.createCorner(Theme.Corner).Parent = frame

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

	local function isActive(btn: TextButton): boolean
		return btn:GetAttribute("IsActive") == true
	end

	local function setActive(id: string)
		activeId = id
		for bid, btn in pairs(buttons) do
			local active = bid == id
			btn:SetAttribute("IsActive", active)
			if active then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = ACTIVE_TRANSPARENCY })
			else
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = IDLE_TRANSPARENCY })
			end
		end
	end

	for i, item in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Name = "NavButton_" .. item.id
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1, 0, 0, 44)
		btn.AutoButtonColor = false
		btn.BackgroundTransparency = IDLE_TRANSPARENCY
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.Parent = frame
		btn.Selectable = true

		UiUtil.createCorner(Theme.CornerSmall).Parent = btn

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

		btn.MouseEnter:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = HOVER_TRANSPARENCY })
			end
		end)

		btn.MouseLeave:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = IDLE_TRANSPARENCY })
			end
		end)

		btn.MouseButton1Down:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = 0.12 })
			end
		end)

		btn.MouseButton1Up:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = HOVER_TRANSPARENCY })
			end
		end)

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

	function api:getButton(id: string)
		return buttons[id]
	end

	function api:getFirstButton()
		local first = items[1]
		if not first then
			return nil
		end
		return buttons[first.id]
	end

	return api
end

return NavRail
