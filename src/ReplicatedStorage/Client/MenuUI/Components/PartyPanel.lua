--!strict

local Players = game:GetService("Players")

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))
local UiUtil = require(menuRoot:WaitForChild("Util"):WaitForChild("UiUtil"))
local TweenUtil = require(menuRoot:WaitForChild("Util"):WaitForChild("TweenUtil"))

export type PartyMember = {
	userId: number,
	name: string,
	isLeader: boolean?,
}

export type Api = {
	getFrame: (self: Api) -> Frame,
	setMembers: (self: Api, members: { PartyMember }) -> (),
}

local PartyPanel = {}

local function createHeader(parent: Instance, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.Font = Theme.FontBold
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = text
	label.Parent = parent
	return label
end

local function createRow(parent: Instance): (Frame, Frame)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Theme.Colors.Panel2
	row.BackgroundTransparency = Theme.Alpha.ButtonIdle
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = parent
	UiUtil.createCorner(Theme.CornerSmall).Parent = row
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = row
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = row

	local hover = Instance.new("Frame")
	hover.Name = "Hover"
	hover.BackgroundColor3 = Theme.Colors.Accent
	hover.BackgroundTransparency = 1
	hover.BorderSizePixel = 0
	hover.Size = UDim2.fromScale(1, 1)
	hover.ZIndex = 2
	hover.Parent = row
	UiUtil.createCorner(Theme.CornerSmall).Parent = hover

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.BackgroundTransparency = 1
	avatar.Position = UDim2.fromOffset(8, 6)
	avatar.Size = UDim2.fromOffset(32, 32)
	avatar.Parent = row
	UiUtil.createCorner(16).Parent = avatar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Theme.Colors.Text
	nameLabel.Font = Theme.FontSemi
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.fromOffset(48, 7)
	nameLabel.Size = UDim2.new(1, -56, 0, 16)
	nameLabel.Text = ""
	nameLabel.Parent = row

	local metaLabel = Instance.new("TextLabel")
	metaLabel.Name = "Meta"
	metaLabel.BackgroundTransparency = 1
	metaLabel.TextColor3 = Theme.Colors.Muted
	metaLabel.Font = Theme.Font
	metaLabel.TextSize = 12
	metaLabel.TextXAlignment = Enum.TextXAlignment.Left
	metaLabel.Position = UDim2.fromOffset(48, 23)
	metaLabel.Size = UDim2.new(1, -56, 0, 14)
	metaLabel.Text = ""
	metaLabel.Parent = row

	local function setHover(a: number)
		hover.BackgroundTransparency = a
	end

	row.MouseEnter:Connect(function()
		TweenUtil.tween(hover, Theme.Anim.Fast, { BackgroundTransparency = 0.92 })
	end)
	row.MouseLeave:Connect(function()
		TweenUtil.tween(hover, Theme.Anim.Fast, { BackgroundTransparency = 1 })
	end)

	setHover(1)
	return row, hover
end

function PartyPanel.create(parent: Instance, initialMembers: { PartyMember }?): Api
	local frame = Instance.new("Frame")
	frame.Name = "PartyPanel"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Parent = parent

	local header = createHeader(frame, "PARTY")
	header.Position = UDim2.fromOffset(0, 0)

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Theme.Colors.Subtle
	sub.Font = Theme.Font
	sub.TextSize = 12
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Position = UDim2.fromOffset(0, 22)
	sub.Size = UDim2.new(1, 0, 0, 16)
	sub.Text = "Invite + party syncing ships next phase."
	sub.Parent = frame

	local listHost = Instance.new("Frame")
	listHost.Name = "ListHost"
	listHost.BackgroundTransparency = 1
	listHost.Position = UDim2.fromOffset(0, 44)
	listHost.Size = UDim2.new(1, 0, 1, -94)
	listHost.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = listHost

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "Invite"
	inviteBtn.AutoButtonColor = false
	inviteBtn.BackgroundColor3 = Theme.Colors.Panel2
	inviteBtn.BackgroundTransparency = Theme.Alpha.ButtonIdle
	inviteBtn.BorderSizePixel = 0
	inviteBtn.Size = UDim2.new(1, 0, 0, 40)
	inviteBtn.AnchorPoint = Vector2.new(0, 1)
	inviteBtn.Position = UDim2.new(0, 0, 1, 0)
	inviteBtn.Text = "INVITE"
	inviteBtn.Font = Theme.FontSemi
	inviteBtn.TextSize = 14
	inviteBtn.TextColor3 = Theme.Colors.Subtle
	inviteBtn.Selectable = true
	inviteBtn.Parent = frame
	UiUtil.createCorner(Theme.CornerSmall).Parent = inviteBtn
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = inviteBtn

	local inviteHint = Instance.new("TextLabel")
	inviteHint.BackgroundTransparency = 1
	inviteHint.TextColor3 = Theme.Colors.Subtle
	inviteHint.Font = Theme.Font
	inviteHint.TextSize = 11
	inviteHint.TextXAlignment = Enum.TextXAlignment.Right
	inviteHint.AnchorPoint = Vector2.new(1, 0.5)
	inviteHint.Position = UDim2.new(1, -10, 0.5, 0)
	inviteHint.Size = UDim2.fromOffset(110, 14)
	inviteHint.Text = "soon"
	inviteHint.Parent = inviteBtn

	inviteBtn.MouseEnter:Connect(function()
		TweenUtil.tween(inviteBtn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonHover })
	end)
	inviteBtn.MouseLeave:Connect(function()
		TweenUtil.tween(inviteBtn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonIdle })
	end)

	local rows: { Frame } = {}

	local function clearRows()
		for i = #rows, 1, -1 do
			rows[i]:Destroy()
			rows[i] = nil
		end
	end

	local function setMembers(members: { PartyMember })
		clearRows()
		for i, m in ipairs(members) do
			local row = createRow(listHost)
			row.LayoutOrder = i

			local avatar = row:FindFirstChild("Avatar") :: ImageLabel
			local nameLabel = row:FindFirstChild("Name") :: TextLabel
			local metaLabel = row:FindFirstChild("Meta") :: TextLabel

			nameLabel.Text = m.name
			metaLabel.Text = (m.isLeader and "Leader") or "Member"
			if m.isLeader then
				metaLabel.TextColor3 = Theme.Colors.Accent
			else
				metaLabel.TextColor3 = Theme.Colors.Muted
			end

			task.spawn(function()
				local ok, img = pcall(function()
					return UiUtil.getHeadshot(m.userId)
				end)
				if ok and typeof(img) == "string" and avatar.Parent then
					avatar.Image = img
				end
			end)

			table.insert(rows, row)
		end
	end

	if initialMembers then
		setMembers(initialMembers)
	else
		local localPlayer = Players.LocalPlayer
		setMembers({
			{ userId = localPlayer.UserId, name = localPlayer.Name, isLeader = true },
		})
	end

	local api: Api = {} :: any
	function api:getFrame()
		return frame
	end
	function api:setMembers(members: { PartyMember })
		setMembers(members)
	end

	return api
end

return PartyPanel
