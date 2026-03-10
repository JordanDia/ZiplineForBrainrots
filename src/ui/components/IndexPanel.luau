local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Fusion       = require(ReplicatedStorage.Packages.Fusion)
local BrainrotConfig = require(ReplicatedStorage.Shared.Configs.BrainrotConfig)

-- ── Colours (matches ZiplineUpgradePanel palette) ─────────────────────────
local C_PANEL  = Color3.fromRGB(12, 12, 18)
local C_HEADER = Color3.fromRGB(35, 185, 215)
local C_CARD   = Color3.fromRGB(20, 20, 28)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_DARK   = Color3.fromRGB(8, 8, 14)
local STROKE   = Color3.fromRGB(70, 70, 95)

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(80,  200,  80),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(180,  80, 255),
	Legendary = Color3.fromRGB(255, 170,   0),
}

-- ── Flatten config into ordered list ──────────────────────────────────────
local ALL_BRAINROTS = {}
for _, rarity in { "Common", "Uncommon", "Rare", "Epic", "Legendary" } do
	if BrainrotConfig[rarity] then
		for _, cfg in BrainrotConfig[rarity] do
			table.insert(ALL_BRAINROTS, cfg)
		end
	end
end

-- Insert spaces before each capital that follows a lowercase letter.
-- "FrigoCamelo" → "Frigo Camelo"
local function _splitPascal(s: string): string
	return (s:gsub("(%l)(%u)", "%1 %2"))
end

-- ── Props ─────────────────────────────────────────────────────────────────
-- Props:
--   UnlockedSet   { [string]: boolean }  initial unlocked table (by ref from controller)
--   UnlockSignal  Signal                 fires (name) when a new one is unlocked
--   OnClose       function
return function(scope, props)
	local BrainrotsRepo = ReplicatedStorage:FindFirstChild("Brainrots")

	-- ── Per-brainrot unlock state (Fusion Values for reactivity) ─────────────
	local unlockedValues = {} :: { [string]: any }
	for _, cfg in ALL_BRAINROTS do
		unlockedValues[cfg.Name] = scope:Value(props.UnlockedSet[cfg.Name] == true)
	end

	-- Listen for newly unlocked brainrots during this session.
	props.UnlockSignal:Connect(function(name: string)
		if unlockedValues[name] then
			unlockedValues[name]:set(true)
		end
	end)

	-- ── Spinning entries (updated in Heartbeat) ───────────────────────────────
	-- Each entry: { Model = Model, IsUnlockedVal = Value<bool> }
	local spinnableModels = {}

	-- ── Build one viewport card ───────────────────────────────────────────────
	local function _card(cfg, layoutOrder: number)
		local isUnlockedVal = unlockedValues[cfg.Name]
		local rarityColor   = RARITY_COLORS[cfg.Rarity] or C_WHITE

		-- Viewport lighting: black when locked, normal when unlocked.
		local vpLight = scope:Computed(function(use)
			return if use(isUnlockedVal) then Color3.fromRGB(140, 140, 140) else Color3.new(0, 0, 0)
		end)
		local vpAmbient = scope:Computed(function(use)
			return if use(isUnlockedVal) then Color3.fromRGB(200, 200, 200) else Color3.new(0, 0, 0)
		end)

		-- Clone model into a WorldModel for the ViewportFrame.
		local worldModel = scope:New "WorldModel" {}
		local camera     = Instance.new("Camera")
		camera.FieldOfView = 40

		if BrainrotsRepo then
			local template = BrainrotsRepo:FindFirstChild(cfg.Name)
			if template then
				local modelClone = template:Clone()
				modelClone.Parent = worldModel

				-- Centre the model at the world origin so the camera math is simple.
				modelClone:PivotTo(CFrame.new(0, 0, 0))
				local cf, size = modelClone:GetBoundingBox()
				local center   = cf.Position
				local maxDim   = math.max(size.X, size.Y, size.Z)
				local dist     = maxDim * 2.5
				camera.CFrame = CFrame.new(
					center + Vector3.new(0, size.Y * 0.1, dist),
					center
				)

				table.insert(spinnableModels, {
					Model        = modelClone,
					IsUnlockedVal = isUnlockedVal,
				})
			end
		end

		return scope:New "Frame" {
			LayoutOrder      = layoutOrder,
			BackgroundColor3 = C_CARD,
			BorderSizePixel  = 0,
			[Fusion.Children] = {
				scope:New "UIStroke" { Color = STROKE, Thickness = 1.5 },

				-- Viewport (fills card, acts as background)
				scope:New "ViewportFrame" {
					Size                   = UDim2.fromScale(1, 1),
					BackgroundColor3       = C_DARK,
					BorderSizePixel        = 0,
					LightColor             = vpLight,
					Ambient                = vpAmbient,
					CurrentCamera          = camera,
					[Fusion.Children]      = { worldModel },
				},

				-- Rarity badge — top-right corner overlay
				scope:New "Frame" {
					AnchorPoint      = Vector2.new(1, 0),
					Position         = UDim2.fromScale(1, 0),
					Size             = UDim2.fromScale(0.5, 0.12),
					BackgroundColor3 = C_PANEL,
					BorderSizePixel  = 0,
					[Fusion.Children] = {
						scope:New "UIStroke" { Color = STROKE, Thickness = 1 },
						scope:New "TextLabel" {
							Size                   = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text                   = string.upper(cfg.Rarity),
							TextColor3             = rarityColor,
							FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
							TextScaled             = true,
						},
					},
				},

				-- Name label — bottom overlay
				scope:New "Frame" {
					AnchorPoint      = Vector2.new(0, 1),
					Position         = UDim2.fromScale(0, 1),
					Size             = UDim2.fromScale(1, 0.2),
					BackgroundColor3 = C_PANEL,
					BorderSizePixel  = 0,
					BackgroundTransparency = 0.2,
					[Fusion.Children] = {
						scope:New "TextLabel" {
							Size                   = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text                   = string.upper(_splitPascal(cfg.Name)),
							TextColor3             = C_WHITE,
							FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
							TextScaled             = true,
						},
					},
				},
			},
		}
	end

	-- ── Build card list ───────────────────────────────────────────────────────
	local cards = {}
	for i, cfg in ALL_BRAINROTS do
		table.insert(cards, _card(cfg, i))
	end

	-- ── Reactive unlocked counter ─────────────────────────────────────────────
	local totalCount = #ALL_BRAINROTS
	local unlockedCount = scope:Computed(function(use)
		local n = 0
		for _, cfg in ALL_BRAINROTS do
			if use(unlockedValues[cfg.Name]) then
				n += 1
			end
		end
		return n
	end)
	local headerCount = scope:Computed(function(use)
		return "UNLOCKED: " .. use(unlockedCount) .. "/" .. totalCount
	end)

	-- ── Close button ─────────────────────────────────────────────────────────
	local closeBtn = scope:New "ImageButton" {
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.fromScale(0.98, 0.5),
		Size                   = UDim2.fromScale(0.08, 0.8),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Image                  = "rbxassetid://108990027053707",
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" {},
		},
		[Fusion.OnEvent "Activated"] = props.OnClose,
	}

	-- ── Assemble panel ────────────────────────────────────────────────────────
	local panelFrame = scope:New "Frame" {
		Name             = "IndexPanel",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0.5, 1.5),
		Size             = UDim2.fromScale(0.65, 0.85),
		Visible          = false,
		BackgroundColor3 = C_PANEL,
		BorderSizePixel  = 0,
		[Fusion.Children] = {
			scope:New "UIStroke" { Color = STROKE, Thickness = 2 },

			-- Header
			scope:New "Frame" {
				Size             = UDim2.fromScale(1, 0.1),
				BackgroundColor3 = C_HEADER,
				BorderSizePixel  = 0,
				[Fusion.Children] = {
					scope:New "UIStroke" { Color = STROKE, Thickness = 2 },

					-- Book icon
					scope:New "ImageLabel" {
						AnchorPoint            = Vector2.new(0, 0.5),
						Position               = UDim2.fromScale(0.01, 0.5),
						Size                   = UDim2.fromScale(0.055, 0.8),
						BackgroundTransparency = 1,
						Image                  = "rbxassetid://74753957626091",
						ScaleType              = Enum.ScaleType.Fit,
						[Fusion.Children] = {
							scope:New "UIAspectRatioConstraint" {},
						},
					},

					-- "INDEX" title
					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(0, 0.5),
						Position               = UDim2.fromScale(0.08, 0.5),
						Size                   = UDim2.fromScale(0.2, 0.7),
						BackgroundTransparency = 1,
						Text                   = "INDEX",
						TextColor3             = C_WHITE,
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled             = true,
						TextXAlignment         = Enum.TextXAlignment.Left,
					},

					-- Unlocked counter
					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(0.5, 0.5),
						Position               = UDim2.fromScale(0.5, 0.5),
						Size                   = UDim2.fromScale(0.4, 0.65),
						BackgroundTransparency = 1,
						Text                   = headerCount,
						TextColor3             = C_WHITE,
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled             = true,
					},

					closeBtn,
				},
			},

			-- Scrolling grid body
			scope:New "ScrollingFrame" {
				Position               = UDim2.fromScale(0, 0.1),
				Size                   = UDim2.fromScale(1, 0.9),
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				CanvasSize             = UDim2.fromScale(0, 0),
				AutomaticCanvasSize    = Enum.AutomaticSize.Y,
				ScrollBarThickness     = 6,
				ScrollBarImageColor3   = Color3.fromRGB(70, 70, 95),
				[Fusion.Children] = {
					scope:New "UIPadding" {
						PaddingLeft   = UDim.new(0.01, 0),
						PaddingRight  = UDim.new(0.01, 0),
						PaddingTop    = UDim.new(0.01, 0),
						PaddingBottom = UDim.new(0.01, 0),
					},
					scope:New "UIGridLayout" {
						CellSize                = UDim2.fromScale(0.235, 0.38),
						CellPadding             = UDim2.fromScale(0.01, 0.01),
						SortOrder               = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment     = Enum.HorizontalAlignment.Left,
						FillDirection           = Enum.FillDirection.Horizontal,
					},
					table.unpack(cards),
				},
			},
		},
	}

	-- ── Spinning loop (only runs while panel is visible) ─────────────────────
	local peek = Fusion.peek
	RunService.Heartbeat:Connect(function(dt)
		if not panelFrame.Visible then return end
		for _, entry in spinnableModels do
			if peek(entry.IsUnlockedVal) then
				entry.Model:PivotTo(entry.Model:GetPivot() * CFrame.Angles(0, dt * math.pi, 0))
			end
		end
	end)

	return panelFrame
end
