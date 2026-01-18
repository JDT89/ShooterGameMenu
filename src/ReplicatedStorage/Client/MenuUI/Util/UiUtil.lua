--!strict

local Players = game:GetService("Players")

local UiUtil = {}

function UiUtil.createCorner(radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	return c
end

function UiUtil.createStroke(color: Color3, transparency: number, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = transparency
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

function UiUtil.createGradient2(top: Color3, bottom: Color3, rotation: number?): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(1, bottom),
	})
	g.Rotation = rotation or 90
	return g
end

function UiUtil.setBg(gui: GuiObject, color: Color3, transparency: number)
	gui.BackgroundColor3 = color
	gui.BackgroundTransparency = transparency
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
	if x < 0 then
		return 0
	end
	if x > 1 then
		return 1
	end
	return x
end

return UiUtil
