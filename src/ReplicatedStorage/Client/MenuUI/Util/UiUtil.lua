--!strict

local Players = game:GetService("Players")

local UiUtil = {}

function UiUtil.createCorner(radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	return c
end

function UiUtil.getHeadshot(userId: number): string
	local content, _ = Players:GetUserThumbnailAsync(
		userId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)
	return content
end

function UiUtil.clamp01(x: number): number
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

return UiUtil
