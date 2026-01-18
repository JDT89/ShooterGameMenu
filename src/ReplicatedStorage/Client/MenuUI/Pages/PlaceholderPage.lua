--!strict

local Theme = require(script.Parent.Parent:WaitForChild("Theme"))

local PlaceholderPage = {}

function PlaceholderPage.create(parent: Instance, titleText: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = "PlaceholderPage_" .. titleText
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
	title.Text = titleText
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(190, 190, 190)
	body.Font = Theme.Font
	body.TextSize = 14
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Position = UDim2.fromOffset(0, 50)
	body.Size = UDim2.new(1, 0, 1, -50)
	body.TextWrapped = true
	body.Text = "This page has real layout scaffolding coming next. For now, the router + nav are wired."
	body.Parent = frame

	return frame
end

return PlaceholderPage
