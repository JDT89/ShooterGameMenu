--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local menuRoot = script.Parent.Parent
local Theme = require(menuRoot:WaitForChild("Theme"))
local utilRoot = menuRoot:WaitForChild("Util")
local UiUtil = require(utilRoot:WaitForChild("UiUtil"))
local TweenUtil = require(utilRoot:WaitForChild("TweenUtil"))
local ModeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeCatalog"))

export type Api = {
	getFrame: (self: Api) -> Frame,
	setSelectedMode: (self: Api, modeId: string) -> (),
}

local PlayPage = {}

local function clamp(n: number, lo: number, hi: number): number
	if n < lo then
		return lo
	end
	if n > hi then
		return hi
	end
	return n
end

local function safeLower(s: any): string
	if typeof(s) ~= "string" then
		return ""
	end
	return string.lower(s)
end

local function getCategory(mode: any): string
	local cat = mode.category
	if typeof(cat) == "string" and #cat > 0 then
		return cat
	end
	return "Other"
end

local function buildCategories(modes: { any }): { string }
	local seen: { [string]: boolean } = {}
	local categories: { string } = {}

	for _, mode in ipairs(modes) do
		local cat = getCategory(mode)
		if not seen[cat] then
			seen[cat] = true
			table.insert(categories, cat)
		end
	end

	table.sort(categories, function(a, b)
		if a == "Core" and b ~= "Core" then
			return true
		end
		if b == "Core" and a ~= "Core" then
			return false
		end
		return a < b
	end)

	-- Always include All at the front
	table.insert(categories, 1, "All")
	return categories
end

local function pickFeaturedMode(modes: { any }): any?
	for _, mode in ipairs(modes) do
		if getCategory(mode) == "Core" then
			return mode
		end
	end
	return modes[1]
end

local function styleSurface(frame: Frame, alpha: number, cornerRadius: number)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Theme.Colors.Panel2
	frame.BackgroundTransparency = alpha
	UiUtil.createCorner(cornerRadius).Parent = frame
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = frame
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = frame
end

local function styleChip(btn: TextButton, isActive: boolean)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = isActive and Theme.Colors.AccentSoft or Theme.Colors.Panel2
	btn.BackgroundTransparency = isActive and 0 or 0.20
	btn.TextColor3 = Theme.Colors.Text
	btn.Font = Theme.FontSemi
	btn.TextSize = 13
	UiUtil.createCorner(Theme.CornerPill).Parent = btn
	UiUtil.createStroke(Theme.Colors.Stroke, isActive and 0.78 or Theme.Alpha.Stroke, 1).Parent = btn

	if isActive then
		UiUtil.createGradient2(Theme.Colors.Accent, Theme.Colors.AccentSoft, 90).Parent = btn
	else
		UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = btn
	end
end

local function setButtonHover(btn: TextButton, baseAlpha: number, hoverAlpha: number)
	btn.MouseEnter:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = hoverAlpha })
	end)
	btn.MouseLeave:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = baseAlpha })
	end)
	btn.MouseButton1Down:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
	end)
	btn.MouseButton1Up:Connect(function()
		TweenUtil.tween(btn, Theme.Anim.Fast, { BackgroundTransparency = hoverAlpha })
	end)
end

function PlayPage.create(parent: Instance, onSelectMode: (modeId: string) -> ()): Api
	local frame = Instance.new("Frame")
	frame.Name = "PlayPage"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent

	local headerRow = Instance.new("Frame")
	headerRow.Name = "HeaderRow"
	headerRow.BackgroundTransparency = 1
	headerRow.Size = UDim2.new(1, 0, 0, 44)
	headerRow.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Theme.Colors.Text
	title.Font = Theme.FontBold
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -320, 1, 0)
	title.Position = UDim2.fromOffset(0, 0)
	title.Text = "PLAY"
	title.Parent = headerRow

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "Search"
	searchBox.AnchorPoint = Vector2.new(1, 0.5)
	searchBox.Position = UDim2.new(1, 0, 0.5, 0)
	searchBox.Size = UDim2.fromOffset(300, 36)
	searchBox.ClearTextOnFocus = false
	searchBox.Text = ""
	searchBox.PlaceholderText = "Search modes…"
	searchBox.Font = Theme.Font
	searchBox.TextSize = 14
	searchBox.TextColor3 = Theme.Colors.Text
	searchBox.PlaceholderColor3 = Theme.Colors.Subtle
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.BorderSizePixel = 0
	searchBox.BackgroundColor3 = Theme.Colors.Panel2
	searchBox.BackgroundTransparency = 0.18
	searchBox.Parent = headerRow
	UiUtil.createCorner(Theme.CornerSmall).Parent = searchBox
	UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1).Parent = searchBox
	UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = searchBox

	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 12)
	searchPad.PaddingRight = UDim.new(0, 12)
	searchPad.Parent = searchBox

	local chipsScroller = Instance.new("ScrollingFrame")
	chipsScroller.Name = "CategoryScroller"
	chipsScroller.BackgroundTransparency = 1
	chipsScroller.BorderSizePixel = 0
	chipsScroller.Position = UDim2.fromOffset(0, 48)
	chipsScroller.Size = UDim2.new(1, 0, 0, 38)
	chipsScroller.ScrollingDirection = Enum.ScrollingDirection.X
	chipsScroller.CanvasSize = UDim2.fromOffset(0, 0)
	chipsScroller.ScrollBarThickness = 0
	chipsScroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	chipsScroller.Parent = frame

	local chipsList = Instance.new("UIListLayout")
	chipsList.FillDirection = Enum.FillDirection.Horizontal
	chipsList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	chipsList.VerticalAlignment = Enum.VerticalAlignment.Center
	chipsList.SortOrder = Enum.SortOrder.LayoutOrder
	chipsList.Padding = UDim.new(0, 10)
	chipsList.Parent = chipsScroller

	local chipsPad = Instance.new("UIPadding")
	chipsPad.PaddingLeft = UDim.new(0, 2)
	chipsPad.PaddingRight = UDim.new(0, 2)
	chipsPad.Parent = chipsScroller

	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(0, 92)
	body.Size = UDim2.new(1, 0, 1, -92)
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.CanvasSize = UDim2.fromOffset(0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollBarThickness = 6
	body.ScrollBarImageTransparency = 0.55
	body.Parent = frame

	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingBottom = UDim.new(0, 8)
	bodyPad.PaddingRight = UDim.new(0, 12)
	bodyPad.Parent = body

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = body

	local vList = Instance.new("UIListLayout")
	vList.FillDirection = Enum.FillDirection.Vertical
	vList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	vList.SortOrder = Enum.SortOrder.LayoutOrder
	vList.Padding = UDim.new(0, 14)
	vList.Parent = content

	local allModes = ModeCatalog.getAll()
	local categories = buildCategories(allModes)
	local featuredMode = pickFeaturedMode(allModes)

	local selectedCategory = "All"
	local query = ""
	local activeModeId = ""

	-- Category chips
	local chipButtons: { [string]: TextButton } = {}

	local function setCategory(newCategory: string)
		selectedCategory = newCategory
		for cat, btn in pairs(chipButtons) do
			btn:Destroy()
			chipButtons[cat] = nil
		end

		for _, cat in ipairs(categories) do
			local isActive = (cat == selectedCategory)
			local chip = Instance.new("TextButton")
			chip.Name = "Chip_" .. cat
			chip.Size = UDim2.fromOffset(math.max(72, (string.len(cat) * 9) + 26), 30)
			chip.Text = cat
			chip.Selectable = true
			chip.Parent = chipsScroller
			styleChip(chip, isActive)

			if not isActive then
				setButtonHover(chip, chip.BackgroundTransparency, 0.12)
			end

			chip.MouseButton1Click:Connect(function()
				selectedCategory = cat
				setCategory(cat)
			end)

			chipButtons[cat] = chip
		end
	end

	-- Featured hero
	local hero = Instance.new("Frame")
	hero.Name = "FeaturedHero"
	hero.LayoutOrder = 1
	hero.Size = UDim2.new(1, 0, 0, 240)
	hero.Parent = content
	styleSurface(hero, Theme.Alpha.PanelStrong, Theme.Corner)

	local heroBgImage = Instance.new("ImageLabel")
	heroBgImage.Name = "HeroImage"
	heroBgImage.BackgroundTransparency = 1
	heroBgImage.Size = UDim2.fromScale(1, 1)
	heroBgImage.ImageTransparency = 0.55
	heroBgImage.ScaleType = Enum.ScaleType.Crop
	heroBgImage.Visible = false
	heroBgImage.Parent = hero
	UiUtil.createCorner(Theme.Corner).Parent = heroBgImage

	local heroOverlay = Instance.new("Frame")
	heroOverlay.BackgroundTransparency = 0.35
	heroOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	heroOverlay.BorderSizePixel = 0
	heroOverlay.Size = UDim2.fromScale(1, 1)
	heroOverlay.Parent = hero
	UiUtil.createCorner(Theme.Corner).Parent = heroOverlay
	UiUtil.createGradient2(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0), 0).Parent = heroOverlay

	local heroPad = Instance.new("UIPadding")
	heroPad.PaddingTop = UDim.new(0, 18)
	heroPad.PaddingBottom = UDim.new(0, 18)
	heroPad.PaddingLeft = UDim.new(0, 18)
	heroPad.PaddingRight = UDim.new(0, 18)
	heroPad.Parent = hero

	local heroLeft = Instance.new("Frame")
	heroLeft.BackgroundTransparency = 1
	heroLeft.Size = UDim2.new(1, -220, 1, 0)
	heroLeft.Parent = hero

	local heroName = Instance.new("TextLabel")
	heroName.BackgroundTransparency = 1
	heroName.TextColor3 = Theme.Colors.Text
	heroName.Font = Theme.FontBold
	heroName.TextSize = 26
	heroName.TextXAlignment = Enum.TextXAlignment.Left
	heroName.Size = UDim2.new(1, 0, 0, 30)
	heroName.Text = "Featured"
	heroName.Parent = heroLeft

	local heroSubtitle = Instance.new("TextLabel")
	heroSubtitle.BackgroundTransparency = 1
	heroSubtitle.TextColor3 = Theme.Colors.Muted
	heroSubtitle.Font = Theme.FontSemi
	heroSubtitle.TextSize = 14
	heroSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	heroSubtitle.Position = UDim2.fromOffset(0, 34)
	heroSubtitle.Size = UDim2.new(1, 0, 0, 18)
	heroSubtitle.Text = ""
	heroSubtitle.Parent = heroLeft

	local heroDesc = Instance.new("TextLabel")
	heroDesc.BackgroundTransparency = 1
	heroDesc.TextColor3 = Theme.Colors.Subtle
	heroDesc.Font = Theme.Font
	heroDesc.TextSize = 13
	heroDesc.TextXAlignment = Enum.TextXAlignment.Left
	heroDesc.TextYAlignment = Enum.TextYAlignment.Top
	heroDesc.Position = UDim2.fromOffset(0, 60)
	heroDesc.Size = UDim2.new(1, 0, 0, 70)
	heroDesc.TextWrapped = true
	heroDesc.Text = ""
	heroDesc.Parent = heroLeft

	local heroMeta = Instance.new("TextLabel")
	heroMeta.BackgroundTransparency = 1
	heroMeta.TextColor3 = Theme.Colors.Muted
	heroMeta.Font = Theme.FontSemi
	heroMeta.TextSize = 12
	heroMeta.TextXAlignment = Enum.TextXAlignment.Left
	heroMeta.AnchorPoint = Vector2.new(0, 1)
	heroMeta.Position = UDim2.new(0, 0, 1, 0)
	heroMeta.Size = UDim2.new(1, 0, 0, 16)
	heroMeta.Text = ""
	heroMeta.Parent = heroLeft

	local heroRight = Instance.new("Frame")
	heroRight.BackgroundTransparency = 1
	heroRight.AnchorPoint = Vector2.new(1, 0)
	heroRight.Position = UDim2.new(1, 0, 0, 0)
	heroRight.Size = UDim2.new(0, 200, 1, 0)
	heroRight.Parent = hero

	local heroCta = Instance.new("TextButton")
	heroCta.Name = "HeroCTA"
	heroCta.AnchorPoint = Vector2.new(1, 1)
	heroCta.Position = UDim2.new(1, 0, 1, 0)
	heroCta.Size = UDim2.fromOffset(200, 46)
	heroCta.Text = "SELECT"
	heroCta.Font = Theme.FontBold
	heroCta.TextSize = 15
	heroCta.TextColor3 = Theme.Colors.Text
	heroCta.Selectable = true
	heroCta.Parent = heroRight
	heroCta.BorderSizePixel = 0
	heroCta.AutoButtonColor = false
	heroCta.BackgroundColor3 = Theme.Colors.AccentSoft
	heroCta.BackgroundTransparency = 0
	UiUtil.createCorner(Theme.CornerSmall).Parent = heroCta
	UiUtil.createStroke(Theme.Colors.Stroke, 0.86, 1).Parent = heroCta
	UiUtil.createGradient2(Theme.Colors.Accent, Theme.Colors.AccentSoft, 90).Parent = heroCta

	-- Section header
	local sectionHeader = Instance.new("TextLabel")
	sectionHeader.Name = "AllModesHeader"
	sectionHeader.BackgroundTransparency = 1
	sectionHeader.TextColor3 = Theme.Colors.Text
	sectionHeader.Font = Theme.FontBold
	sectionHeader.TextSize = 16
	sectionHeader.TextXAlignment = Enum.TextXAlignment.Left
	sectionHeader.Size = UDim2.new(1, 0, 0, 20)
	sectionHeader.Text = "ALL MODES"
	sectionHeader.LayoutOrder = 2
	sectionHeader.Parent = content

	local gridHost = Instance.new("Frame")
	gridHost.Name = "GridHost"
	gridHost.BackgroundTransparency = 1
	gridHost.Size = UDim2.new(1, 0, 0, 0)
	gridHost.AutomaticSize = Enum.AutomaticSize.Y
	gridHost.LayoutOrder = 3
	gridHost.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(14, 14)
	grid.CellSize = UDim2.fromOffset(320, 190)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridHost

	local emptyState = Instance.new("Frame")
	emptyState.Name = "EmptyState"
	emptyState.BackgroundTransparency = 1
	emptyState.Size = UDim2.new(1, 0, 0, 90)
	emptyState.LayoutOrder = 4
	emptyState.Visible = false
	emptyState.Parent = content

	local emptyTitle = Instance.new("TextLabel")
	emptyTitle.BackgroundTransparency = 1
	emptyTitle.TextColor3 = Theme.Colors.Text
	emptyTitle.Font = Theme.FontBold
	emptyTitle.TextSize = 16
	emptyTitle.TextXAlignment = Enum.TextXAlignment.Left
	emptyTitle.Size = UDim2.new(1, 0, 0, 22)
	emptyTitle.Text = "No modes found"
	emptyTitle.Parent = emptyState

	local emptyBody = Instance.new("TextLabel")
	emptyBody.BackgroundTransparency = 1
	emptyBody.TextColor3 = Theme.Colors.Subtle
	emptyBody.Font = Theme.Font
	emptyBody.TextSize = 13
	emptyBody.TextXAlignment = Enum.TextXAlignment.Left
	emptyBody.TextWrapped = true
	emptyBody.Position = UDim2.fromOffset(0, 24)
	emptyBody.Size = UDim2.new(1, 0, 0, 46)
	emptyBody.Text = "Try a different search term or category."
	emptyBody.Parent = emptyState

	-- Cards
	type CardParts = {
		button: TextButton,
		stroke: UIStroke,
		focus: Frame,
	}

	local cards: { [string]: CardParts } = {}

	local function updateGridForWidth(width: number)
		local columns = 1
		if width >= 1100 then
			columns = 3
		elseif width >= 720 then
			columns = 2
		end

		local paddingX = 12
		local spacing = 14
		local available = math.max(300, width - paddingX)
		local cellW = (available - ((columns - 1) * spacing)) / columns
		cellW = clamp(cellW, 280, 410)
		local cellH = clamp(math.floor(cellW * 0.62), 172, 248)
		grid.CellSize = UDim2.fromOffset(cellW, cellH)

		-- Hero sizing (keeps premium proportions)
		local heroH = clamp(math.floor(width * 0.24), 200, 280)
		hero.Size = UDim2.new(1, 0, 0, heroH)
	end

	local function setSelected(modeId: string)
		activeModeId = modeId
		for id, parts in pairs(cards) do
			local isActive = (id == modeId)
			if isActive then
				TweenUtil.tween(parts.button, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonDown })
				parts.stroke.Color = Theme.Colors.Accent
				parts.stroke.Transparency = 0.35
			else
				TweenUtil.tween(parts.button, Theme.Anim.Fast, { BackgroundTransparency = Theme.Alpha.ButtonIdle })
				parts.stroke.Color = Theme.Colors.Stroke
				parts.stroke.Transparency = Theme.Alpha.Stroke
			end
		end
	end

	local function createPill(parentInst: Instance, text: string, bg: Color3, fg: Color3): Frame
		local pill = Instance.new("Frame")
		pill.Name = "Pill"
		pill.BackgroundColor3 = bg
		pill.BackgroundTransparency = 0.10
		pill.BorderSizePixel = 0
		pill.AnchorPoint = Vector2.new(1, 0)
		pill.Position = UDim2.new(1, -12, 0, 12)
		pill.Size = UDim2.fromOffset(132, 26)
		pill.Parent = parentInst
		UiUtil.createCorner(Theme.CornerPill).Parent = pill
		UiUtil.createStroke(Theme.Colors.Stroke, 0.90, 1).Parent = pill

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.TextColor3 = fg
		label.Font = Theme.FontBold
		label.TextSize = 12
		label.Text = text
		label.Size = UDim2.fromScale(1, 1)
		label.Parent = pill

		return pill
	end

	local function makeCard(mode: any): CardParts
		local card = Instance.new("TextButton")
		card.Name = "ModeCard_" .. tostring(mode.id)
		card.AutoButtonColor = false
		card.BackgroundColor3 = Theme.Colors.Panel2
		card.BackgroundTransparency = Theme.Alpha.ButtonIdle
		card.BorderSizePixel = 0
		card.Text = ""
		card.Parent = gridHost
		card.Selectable = true

		UiUtil.createCorner(Theme.Corner).Parent = card
		UiUtil.createGradient2(Theme.Colors.Panel3, Theme.Colors.Panel2, 90).Parent = card

		local stroke = UiUtil.createStroke(Theme.Colors.Stroke, Theme.Alpha.Stroke, 1)
		stroke.Parent = card

		local focus = Instance.new("Frame")
		focus.Name = "FocusRing"
		focus.BackgroundTransparency = 1
		focus.BorderSizePixel = 0
		focus.Size = UDim2.fromScale(1, 1)
		focus.Visible = false
		focus.Parent = card
		UiUtil.createCorner(Theme.Corner).Parent = focus
		UiUtil.createStroke(Theme.Colors.Accent, 0.30, 2).Parent = focus

		local header = Instance.new("TextLabel")
		header.BackgroundTransparency = 1
		header.TextColor3 = Theme.Colors.Text
		header.Font = Theme.FontBold
		header.TextSize = 20
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Position = UDim2.fromOffset(14, 12)
		header.Size = UDim2.new(1, -28, 0, 24)
		header.Text = tostring(mode.displayName)
		header.Parent = card

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.TextColor3 = Theme.Colors.Muted
		sub.Font = Theme.FontSemi
		sub.TextSize = 13
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Position = UDim2.fromOffset(14, 40)
		sub.Size = UDim2.new(1, -28, 0, 18)
		sub.Text = tostring(mode.subtitle or "")
		sub.Parent = card

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Theme.Colors.Subtle
		desc.Font = Theme.Font
		desc.TextSize = 13
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Position = UDim2.fromOffset(14, 66)
		desc.Size = UDim2.new(1, -28, 0, 64)
		desc.TextWrapped = true
		desc.Text = tostring(mode.description or "")
		desc.Parent = card

		local footer = Instance.new("TextLabel")
		footer.BackgroundTransparency = 1
		footer.TextColor3 = Theme.Colors.Muted
		footer.Font = Theme.FontSemi
		footer.TextSize = 12
		footer.TextXAlignment = Enum.TextXAlignment.Left
		footer.AnchorPoint = Vector2.new(0, 1)
		footer.Position = UDim2.new(0, 14, 1, -12)
		footer.Size = UDim2.new(1, -28, 0, 16)
		footer.Text = string.format("%d-%d players", tonumber(mode.minPlayers) or 2, tonumber(mode.maxPlayers) or 2)
		footer.Parent = card

		local locked = (mode.comingSoon == true) or (mode.enabled == false)
		if locked then
			createPill(card, "COMING SOON", Theme.Colors.Warning, Color3.fromRGB(20, 14, 8))
		end

		local function setHover(isHover: boolean)
			if activeModeId == mode.id then
				return
			end
			TweenUtil.tween(card, Theme.Anim.Fast, {
				BackgroundTransparency = isHover and Theme.Alpha.ButtonHover or Theme.Alpha.ButtonIdle,
			})
		end

		card.MouseEnter:Connect(function()
			setHover(true)
		end)
		card.MouseLeave:Connect(function()
			setHover(false)
		end)

		card.SelectionGained:Connect(function()
			focus.Visible = true
			setHover(true)
		end)
		card.SelectionLost:Connect(function()
			focus.Visible = false
			setHover(false)
		end)

		card.MouseButton1Click:Connect(function()
			if locked then
				return
			end
			setSelected(tostring(mode.id))
			onSelectMode(tostring(mode.id))
		end)

		return {
			button = card,
			stroke = stroke,
			focus = focus,
		}
	end

	local function matchesFilter(mode: any): boolean
		if selectedCategory ~= "All" then
			if getCategory(mode) ~= selectedCategory then
				return false
			end
		end

		local q = query
		if q == "" then
			return true
		end

		local hay = safeLower(mode.displayName) .. "\n" .. safeLower(mode.subtitle) .. "\n" .. safeLower(mode.description)
		if string.find(hay, q, 1, true) then
			return true
		end

		if typeof(mode.tags) == "table" then
			for _, tag in ipairs(mode.tags) do
				if string.find(safeLower(tag), q, 1, true) then
					return true
				end
			end
		end

		return false
	end

	local function clearGrid()
		for _, child in ipairs(gridHost:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		cards = {}
	end

	local function rebuild()
		clearGrid()

		local filtered: { any } = {}
		local all = ModeCatalog.getAll()
		for _, mode in ipairs(all) do
			if matchesFilter(mode) then
				table.insert(filtered, mode)
			end
		end

		emptyState.Visible = (#filtered == 0)

		for _, mode in ipairs(filtered) do
			local parts = makeCard(mode)
			cards[tostring(mode.id)] = parts
		end

		-- Restore selection visuals after rebuild
		if activeModeId ~= "" then
			setSelected(activeModeId)
		end

		-- Update header with count
		sectionHeader.Text = string.format("ALL MODES (%d)", #filtered)
	end

	-- Featured mode content (always first Core mode per your choice)
	local function applyFeatured()
		if not featuredMode then
			heroName.Text = "Featured"
			heroSubtitle.Text = ""
			heroDesc.Text = ""
			heroMeta.Text = ""
			heroCta.Text = "SELECT"
			heroCta.Active = false
			heroCta.AutoButtonColor = false
			heroCta.BackgroundTransparency = 0.6
			heroBgImage.Visible = false
			return
		end

		heroName.Text = tostring(featuredMode.displayName)
		heroSubtitle.Text = tostring(featuredMode.subtitle or "")
		heroDesc.Text = tostring(featuredMode.description or "")
		heroMeta.Text = string.format("%d-%d players • %s", tonumber(featuredMode.minPlayers) or 2, tonumber(featuredMode.maxPlayers) or 2, getCategory(featuredMode))
		heroCta.Text = "SELECT"

		local locked = (featuredMode.comingSoon == true) or (featuredMode.enabled == false)
		heroCta.Active = not locked
		heroCta.AutoButtonColor = false
		heroCta.BackgroundTransparency = locked and 0.65 or 0

		local bg = featuredMode.backgroundImage
		if typeof(bg) == "string" and #bg > 0 then
			heroBgImage.Image = bg
			heroBgImage.Visible = true
		else
			heroBgImage.Visible = false
		end
	end

	heroCta.MouseButton1Click:Connect(function()
		if not featuredMode then
			return
		end
		if (featuredMode.comingSoon == true) or (featuredMode.enabled == false) then
			return
		end
		local id = tostring(featuredMode.id)
		setSelected(id)
		onSelectMode(id)
	end)

	-- Search debounce
	local searchToken = 0
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchToken += 1
		local token = searchToken
		local raw = searchBox.Text
		query = safeLower(raw)
		task.delay(0.10, function()
			if token ~= searchToken then
				return
			end
			rebuild()
		end)
	end)

	setCategory("All")
	applyFeatured()
	rebuild()

	-- Responsive sizing
	local function onSizeChanged()
		updateGridForWidth(body.AbsoluteSize.X)
	end

	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(onSizeChanged)
	onSizeChanged()

	local api: Api = {} :: any
	function api:getFrame()
		return frame
	end

	function api:setSelectedMode(modeId: string)
		setSelected(modeId)
	end

	return api
end

return PlayPage
