--!strict

local Theme = {}

-- Typography
Theme.Font = Enum.Font.Gotham
Theme.FontBold = Enum.Font.GothamBold
Theme.FontSemi = Enum.Font.GothamSemibold

-- Radii
Theme.Corner = 14
Theme.CornerSmall = 10
Theme.CornerPill = 999

-- Animation timing (seconds)
Theme.Anim = {
	Fast = 0.12,
	Med = 0.18,
	Slow = 0.24,
}

-- Modern dark palette (premium, high-contrast)
Theme.Colors = {
	Background = Color3.fromRGB(9, 10, 14),
	Background2 = Color3.fromRGB(13, 15, 22),

	Panel = Color3.fromRGB(18, 20, 28),
	Panel2 = Color3.fromRGB(24, 27, 38),
	Panel3 = Color3.fromRGB(32, 36, 50),

	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(246, 247, 250),
	Muted = Color3.fromRGB(182, 188, 200),
	Subtle = Color3.fromRGB(134, 142, 156),

	Accent = Color3.fromRGB(88, 176, 255),
	AccentSoft = Color3.fromRGB(48, 124, 196),
	Warning = Color3.fromRGB(255, 183, 77),
	Success = Color3.fromRGB(108, 230, 168),
	Danger = Color3.fromRGB(255, 106, 106),
}

-- Common transparencies
Theme.Alpha = {
	Panel = 0.10,
	PanelStrong = 0.06,
	PanelWeak = 0.16,
	Stroke = 0.88,
	StrokeStrong = 0.78,
	ButtonIdle = 0.28,
	ButtonHover = 0.18,
	ButtonDown = 0.10,
}

return Theme
