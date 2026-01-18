--!strict

local Players = game:GetService("Players")

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))
local UiUtil = require(menuRoot:WaitForChild("Util"):WaitForChild("UiUtil"))

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
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.Font = Theme.FontBold
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = text
	label.Parent = parent
	return label
end

local function createRow(parent: Instance): Frame
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 0.55
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = parent
	UiUtil.createCorner(Theme.CornerSmall).Parent = row

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
	nameLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
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
	metaLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	metaLabel.Font = Theme.Font
	metaLabel.TextSize = 12
	metaLabel.TextXAlignment = Enum.TextXAlignment.Left
	metaLabel.Position = UDim2.fromOffset(48, 23)
	metaLabel.Size = UDim2.new(1, -56, 0, 14)
	metaLabel.Text = ""
	metaLabel.Parent = row

	return row
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
	sub.TextColor3 = Color3.fromRGB(180, 180, 180)
	sub.Font = Theme.Font
	sub.TextSize = 12
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Position = UDim2.fromOffset(0, 22)
	sub.Size = UDim2.new(1, 0, 0, 16)
	sub.Text = "Party features will expand next phase."
	sub.Parent = frame

	local listHost = Instance.new("Frame")
	listHost.Name = "ListHost"
	listHost.BackgroundTransparency = 1
	listHost.Position = UDim2.fromOffset(0, 44)
	listHost.Size = UDim2.new(1, 0, 1, -90)
	listHost.Parent = frame

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = listHost

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "Invite"
	inviteBtn.AutoButtonColor = false
	inviteBtn.BackgroundTransparency = 0.65
	inviteBtn.BorderSizePixel = 0
	inviteBtn.Size = UDim2.new(1, 0, 0, 40)
	inviteBtn.AnchorPoint = Vector2.new(0, 1)
	inviteBtn.Position = UDim2.new(0, 0, 1, 0)
	inviteBtn.Text = "INVITE (soon)"
	inviteBtn.Font = Theme.FontSemi
	inviteBtn.TextSize = 14
	inviteBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
	inviteBtn.Selectable = true
	inviteBtn.Parent = frame
	UiUtil.createCorner(Theme.CornerSmall).Parent = inviteBtn

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

			-- Thumbnail fetch can yield; do it off-thread.
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

	-- default: solo
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
