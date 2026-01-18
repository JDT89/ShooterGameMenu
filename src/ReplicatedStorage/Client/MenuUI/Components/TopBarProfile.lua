--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))
local UiUtil = require(script.Parent.Parent.Util:WaitForChild("UiUtil"))

local ProfileConstants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProfileConstants"))

export type Api = {
	setExp: (self: Api, level: number, exp: number, expToNext: number) -> (),
	setAvatar: (self: Api, image: string) -> (),
	getFrame: (self: Api) -> Frame,
}

local TopBarProfile = {}

function TopBarProfile.create(parent: Instance, player: Player): Api
	local frame = Instance.new("Frame")
	frame.Name = "TopBarProfile"
	frame.BorderSizePixel = 0
	UiUtil.setBg(frame, Theme.Colors.Panel, Theme.Alpha.Panel)
	frame.Size = UDim2.fromOffset(360, 48)
	frame.Parent = parent

	UiUtil.createCorner(Theme.Corner).Parent = frame
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = frame
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel, 90).Parent = frame

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.BackgroundTransparency = 1
	avatar.Size = UDim2.fromOffset(40, 40)
	avatar.Position = UDim2.fromOffset(6, 4)
	avatar.Image = UiUtil.getHeadshot(player.UserId)
	avatar.Parent = frame
	UiUtil.createCorner(Theme.CornerPill).Parent = avatar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Theme.Colors.Text
	nameLabel.Font = Theme.FontSemi
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Position = UDim2.fromOffset(54, 6)
	nameLabel.Size = UDim2.new(1, -60, 0, 18)
	nameLabel.Text = player.Name
	nameLabel.Parent = frame

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "Level"
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = Theme.Colors.Muted
	levelLabel.Font = Theme.Font
	levelLabel.TextSize = 12
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Position = UDim2.fromOffset(54, 24)
	levelLabel.Size = UDim2.new(1, -60, 0, 16)
	levelLabel.Text = "Lv. 1"
	levelLabel.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Name = "ExpBarBg"
	barBg.BorderSizePixel = 0
	UiUtil.setBg(barBg, Theme.Colors.Panel3, 0.25)
	barBg.Position = UDim2.fromOffset(54, 40)
	barBg.Size = UDim2.new(1, -64, 0, 6)
	barBg.Parent = frame
	UiUtil.createCorner(Theme.CornerPill).Parent = barBg
	UiUtil.createStroke(Theme.Colors.Stroke, 0.92, 1).Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "ExpBarFill"
	barFill.BorderSizePixel = 0
	UiUtil.setBg(barFill, Theme.Colors.Accent, 0)
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.Parent = barBg
	UiUtil.createCorner(Theme.CornerPill).Parent = barFill
	UiUtil.createGradient2(Theme.Colors.Accent, Theme.Colors.AccentSoft, 0).Parent = barFill

	local function readAttrs()
		local attrs = ProfileConstants.Attributes
		local level = player:GetAttribute(attrs.Level)
		local exp = player:GetAttribute(attrs.Exp)
		local expToNext = player:GetAttribute(attrs.ExpToNext)

		if typeof(level) ~= "number" then
			level = 1
		end
		if typeof(exp) ~= "number" then
			exp = 0
		end
		if typeof(expToNext) ~= "number" or expToNext <= 0 then
			expToNext = 100
		end

		return level :: number, exp :: number, expToNext :: number
	end

	local function apply(level: number, exp: number, expToNext: number)
		levelLabel.Text = ("Lv. %d  •  %d/%d XP"):format(level, exp, expToNext)
		local ratio = UiUtil.clamp01(exp / math.max(1, expToNext))
		barFill.Size = UDim2.new(ratio, 0, 1, 0)
	end

	apply(readAttrs())

	player:GetAttributeChangedSignal(ProfileConstants.Attributes.Level):Connect(function()
		apply(readAttrs())
	end)
	player:GetAttributeChangedSignal(ProfileConstants.Attributes.Exp):Connect(function()
		apply(readAttrs())
	end)
	player:GetAttributeChangedSignal(ProfileConstants.Attributes.ExpToNext):Connect(function()
		apply(readAttrs())
	end)

	local api: Api = {} :: any
	function api:setExp(level: number, exp: number, expToNext: number)
		apply(level, exp, expToNext)
	end

	function api:setAvatar(image: string)
		avatar.Image = image
	end

	function api:getFrame()
		return frame
	end

	return api
end

return TopBarProfile
