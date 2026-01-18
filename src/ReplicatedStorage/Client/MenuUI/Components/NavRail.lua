--!strict

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))

local utilRoot = menuRoot:WaitForChild("Util")
local UiUtil = require(utilRoot:WaitForChild("UiUtil"))
local TweenUtil = require(utilRoot:WaitForChild("TweenUtil"))

export type NavItem = {
	id: string,
	label: string,
	iconText: string,
}

export type NavRailApi = {
	setMode: (self: NavRailApi, mode: "Expanded" | "IconOnly") -> (),
	setActive: (self: NavRailApi, id: string) -> (),
	getFrame: (self: NavRailApi) -> Frame,
	getButton: (self: NavRailApi, id: string) -> TextButton?,
	getFirstButton: (self: NavRailApi) -> TextButton?,
}

local NavRail = {}

function NavRail.create(parent: Instance, items: { NavItem }, onSelect: (id: string) -> ()) : NavRailApi
	local frame = Instance.new("Frame")
	frame.Name = "NavRail"
	frame.BorderSizePixel = 0
	UiUtil.setBg(frame, Theme.Colors.Panel, Theme.Alpha.Panel)
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	UiUtil.createCorner(Theme.Corner).Parent = frame
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = frame
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel, 90).Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = frame

	local buttons: { [string]: TextButton } = {}
	local partsById: {
		[string]: {
			indicator: Frame,
			icon: TextLabel,
			label: TextLabel,
			bgStroke: UIStroke,
			focusRing: Frame,
		},
	} = {}

	local activeId = items[1] and items[1].id or ""
	local mode: "Expanded" | "IconOnly" = "Expanded"

	local function applyButtonLayout(btn: TextButton, item: NavItem)
		local parts = partsById[item.id]
		if not parts then
			return
		end

		local icon = parts.icon
		local text = parts.label

		if mode == "IconOnly" then
			text.Visible = false
			icon.Position = UDim2.fromOffset(0, 0)
			icon.Size = UDim2.new(1, 0, 1, 0)
			icon.TextXAlignment = Enum.TextXAlignment.Center
		else
			text.Visible = true
			icon.Position = UDim2.fromOffset(14, 0)
			icon.Size = UDim2.new(0, 24, 1, 0)
			icon.TextXAlignment = Enum.TextXAlignment.Center
		end

		icon.Text = item.iconText
		text.Text = item.label
	end

	local function isActive(btn: TextButton): boolean
		return btn:GetAttribute("IsActive") == true
	end

	local function setVisual(id: string, state: "Idle" | "Hover" | "Active")
		local btn = buttons[id]
		local parts = partsById[id]
		if not (btn and parts) then
			return
		end

		if state == "Active" then
			btn:SetAttribute("IsActive", true)
			parts.indicator.Visible = true
			parts.indicator.BackgroundTransparency = 0
			parts.icon.TextColor3 = Theme.Colors.Accent
			parts.label.TextColor3 = Theme.Colors.Text
			parts.bgStroke.Color = Theme.Colors.Accent
			parts.bgStroke.Transparency = 0.55
			TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
		elseif state == "Hover" then
			btn:SetAttribute("IsActive", false)
			parts.indicator.Visible = true
			parts.indicator.BackgroundTransparency = 0.35
			parts.icon.TextColor3 = Theme.Colors.Text
			parts.label.TextColor3 = Theme.Colors.Text
			parts.bgStroke.Color = Theme.Colors.Stroke
			parts.bgStroke.Transparency = Theme.Alpha.StrokeStrong
			TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonHover })
		else
			btn:SetAttribute("IsActive", false)
			parts.indicator.Visible = false
			parts.icon.TextColor3 = Theme.Colors.Muted
			parts.label.TextColor3 = Theme.Colors.Muted
			parts.bgStroke.Color = Theme.Colors.Stroke
			parts.bgStroke.Transparency = Theme.Alpha.Stroke
			TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonIdle })
		end
	end

	local function setActive(id: string)
		activeId = id
		for _, item in ipairs(items) do
			if item.id == id then
				setVisual(item.id, "Active")
			else
				setVisual(item.id, "Idle")
			end
		end
	end

	for i, item in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Name = "NavButton_" .. item.id
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1, 0, 0, 46)
		btn.AutoButtonColor = false
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.Selectable = true
		UiUtil.setBg(btn, Theme.Colors.Panel2, Theme.Alpha.ButtonIdle)
		btn.Parent = frame

		UiUtil.createCorner(Theme.CornerSmall).Parent = btn
		local bgStroke = UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1)
		bgStroke.Parent = btn

		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.BorderSizePixel = 0
		indicator.Size = UDim2.fromOffset(3, 20)
		indicator.Position = UDim2.new(0, 8, 0.5, 0)
		indicator.AnchorPoint = Vector2.new(0, 0.5)
		indicator.BackgroundColor3 = Theme.Colors.Accent
		indicator.BackgroundTransparency = 1
		indicator.Visible = false
		indicator.Parent = btn
		UiUtil.createCorner(Theme.CornerPill).Parent = indicator

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.TextColor3 = Theme.Colors.Muted
		icon.Font = Theme.FontBold
		icon.TextSize = 18
		icon.TextXAlignment = Enum.TextXAlignment.Center
		icon.TextYAlignment = Enum.TextYAlignment.Center
		icon.Parent = btn

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.TextColor3 = Theme.Colors.Muted
		label.Font = Theme.FontSemi
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Position = UDim2.fromOffset(48, 0)
		label.Size = UDim2.new(1, -56, 1, 0)
		label.Parent = btn

		local focusRing = Instance.new("Frame")
		focusRing.Name = "FocusRing"
		focusRing.BackgroundTransparency = 1
		focusRing.Size = UDim2.fromScale(1, 1)
		focusRing.Visible = false
		focusRing.Parent = btn
		UiUtil.createCorner(Theme.CornerSmall).Parent = focusRing
		UiUtil.createStroke(Theme.Colors.Accent, 0.35, 2).Parent = focusRing

		buttons[item.id] = btn
		partsById[item.id] = {
			indicator = indicator,
			icon = icon,
			label = label,
			bgStroke = bgStroke,
			focusRing = focusRing,
		}

		applyButtonLayout(btn, item)

		btn.MouseEnter:Connect(function()
			if not isActive(btn) then
				setVisual(item.id, "Hover")
			end
		end)

		btn.MouseLeave:Connect(function()
			if not isActive(btn) then
				setVisual(item.id, "Idle")
			end
		end)

		btn.MouseButton1Down:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
			end
		end)

		btn.MouseButton1Up:Connect(function()
			if not isActive(btn) then
				TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonHover })
			end
		end)

		btn.MouseButton1Click:Connect(function()
			onSelect(item.id)
			setActive(item.id)
		end)

		btn.SelectionGained:Connect(function()
			local parts = partsById[item.id]
			if parts then
				parts.focusRing.Visible = true
			end
			if not isActive(btn) then
				setVisual(item.id, "Hover")
			end
		end)

		btn.SelectionLost:Connect(function()
			local parts = partsById[item.id]
			if parts then
				parts.focusRing.Visible = false
			end
			if not isActive(btn) then
				setVisual(item.id, "Idle")
			end
		end)
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
