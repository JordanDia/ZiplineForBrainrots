local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion      = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

local C_PANEL   = Color3.fromRGB(12, 12, 18)
local C_HEADER  = Color3.fromRGB(35, 185, 215)
local C_CARD    = Color3.fromRGB(20, 20, 28)
local C_STAT_BG = Color3.fromRGB(14, 14, 20)
local C_ICON_BG = Color3.fromRGB(30, 30, 44)
local C_WHITE   = Color3.fromRGB(255, 255, 255)
local C_CYAN    = Color3.fromRGB(30, 215, 255)
local C_GREEN   = Color3.fromRGB(85, 210, 40)
local C_RED     = Color3.fromRGB(215, 48, 48)
local C_YELLOW  = Color3.fromRGB(255, 220, 40)
local C_PURPLE  = Color3.fromRGB(148, 40, 220)
local STROKE    = Color3.fromRGB(70, 70, 95)

local SPEED_ICON    = "rbxassetid://121441312069242"
local DURATION_ICON = "rbxassetid://126340774874320"
local CARRY_ICON    = "rbxassetid://121441312069242"
local ARROW_IMG     = "rbxassetid://74753957626091"

local SPEED_TIERS = {
	{ Inc = 1,  Cost = 100,  Robux = 4  },
	{ Inc = 5,  Cost = 500,  Robux = 9  },
	{ Inc = 10, Cost = 2000, Robux = 19 },
}
local DURATION_TIERS = {
	{ Inc = 1, Cost = 150,  Robux = 4  },
	{ Inc = 2, Cost = 600,  Robux = 9  },
	{ Inc = 3, Cost = 2500, Robux = 19 },
}
local CARRY_COST  = 500
local CARRY_ROBUX = 9

-- Props:
--   Speed          (Value<number>)
--   Duration       (Value<number>)
--   CarryAmount    (Value<number>)
--   Cash           (Value<number>)
--   OnUpgradeSpeed    (function)
--   OnUpgradeDuration (function)
--   OnUpgradeCarry    (function)
--   OnClose           (function)
return function(scope, props)

	local function _stroke(thickness: number?)
		return scope:New "UIStroke" { Color = STROKE, Thickness = thickness or 2 }
	end

	-- ── Card ───────────────────────────────────────────────────────────────────
	-- cardSize: Size of the outermost TextButton; caller sets half-width or full-width.
	local function _card(image, incLabel, curText, nxtText, cashCost, robuxCost, cardSize, onCash)
		local cashColor = scope:Computed(function(use)
			return if use(props.Cash) >= cashCost then C_GREEN else C_RED
		end)

		local btn = scope:New "TextButton" {
			Size             = cardSize,
			BackgroundColor3 = C_CARD,
			BorderSizePixel  = 0,
			Text             = "",
			[Fusion.Children] = {
				_stroke(1.5),

				-- Icon image with increment label at bottom
				scope:New "ImageLabel" {
					AnchorPoint      = Vector2.new(0, 0.5),
					Position         = UDim2.fromScale(0.01, 0.5),
					Size             = UDim2.fromScale(0.13, 0.85),
					BackgroundColor3 = C_ICON_BG,
					BorderSizePixel  = 0,
					Image            = image,
					ScaleType        = Enum.ScaleType.Fit,
					[Fusion.Children] = {
						scope:New "TextLabel" {
							AnchorPoint            = Vector2.new(0.5, 1),
							Position               = UDim2.fromScale(0.5, 1),
							Size                   = UDim2.fromScale(1, 0.34),
							BackgroundTransparency = 1,
							Text                   = incLabel,
							TextColor3             = C_YELLOW,
							FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
							TextScaled             = true,
							[Fusion.Children] = {
								scope:New "UIStroke" {
									Color     = Color3.new(0, 0, 0),
									Thickness = 2,
								},
							},
						},
					},
				},

				-- Current stat frame
				scope:New "Frame" {
					AnchorPoint      = Vector2.new(0, 0.5),
					Position         = UDim2.fromScale(0.16, 0.5),
					Size             = UDim2.fromScale(0.21, 0.78),
					BackgroundColor3 = C_STAT_BG,
					BorderSizePixel  = 0,
					[Fusion.Children] = {
						_stroke(1.5),
						scope:New "TextLabel" {
							Size                   = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text                   = curText,
							TextColor3             = C_WHITE,
							FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
							TextScaled             = true,
						},
					},
				},

				-- Arrow image
				scope:New "ImageLabel" {
					AnchorPoint            = Vector2.new(0.5, 0.5),
					Position               = UDim2.fromScale(0.41, 0.5),
					Size                   = UDim2.fromScale(0.055, 0.45),
					BackgroundTransparency = 1,
					Image                  = ARROW_IMG,
					ScaleType              = Enum.ScaleType.Fit,
				},

				-- Next stat frame (blue text)
				scope:New "Frame" {
					AnchorPoint      = Vector2.new(0, 0.5),
					Position         = UDim2.fromScale(0.445, 0.5),
					Size             = UDim2.fromScale(0.21, 0.78),
					BackgroundColor3 = C_STAT_BG,
					BorderSizePixel  = 0,
					[Fusion.Children] = {
						_stroke(1.5),
						scope:New "TextLabel" {
							Size                   = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text                   = nxtText,
							TextColor3             = C_CYAN,
							FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
							TextScaled             = true,
						},
					},
				},

				-- Price buttons: cash (top) + robux (bottom)
				scope:New "Frame" {
					AnchorPoint            = Vector2.new(1, 0.5),
					Position               = UDim2.fromScale(0.99, 0.5),
					Size                   = UDim2.fromScale(0.27, 0.9),
					BackgroundTransparency = 1,
					[Fusion.Children] = {
						scope:New "UIListLayout" {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder     = Enum.SortOrder.LayoutOrder,
							Padding       = UDim.new(0.05, 0),
						},
						scope:New "Frame" {
							LayoutOrder      = 1,
							Size             = UDim2.fromScale(1, 0.475),
							BackgroundColor3 = cashColor,
							BorderSizePixel  = 0,
							[Fusion.Children] = {
								_stroke(1.5),
								scope:New "TextLabel" {
									Size                   = UDim2.fromScale(1, 1),
									BackgroundTransparency = 1,
									Text                   = "$" .. FormatNumber(cashCost),
									TextColor3             = C_WHITE,
									FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
									TextScaled             = true,
								},
							},
						},
						scope:New "Frame" {
							LayoutOrder      = 2,
							Size             = UDim2.fromScale(1, 0.475),
							BackgroundColor3 = C_PURPLE,
							BorderSizePixel  = 0,
							[Fusion.Children] = {
								_stroke(1.5),
								scope:New "TextLabel" {
									Size                   = UDim2.fromScale(1, 1),
									BackgroundTransparency = 1,
									Text                   = "R$ " .. robuxCost,
									TextColor3             = C_WHITE,
									FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
									TextScaled             = true,
								},
							},
						},
					},
				},
			},
		}
		btn.Activated:Connect(onCash or function() end)
		return btn
	end

	-- ── 3 upgrade rows (speed left, duration right) ────────────────────────────

	local upgradeRows = {}
	for i = 1, 3 do
		local sTier = SPEED_TIERS[i]
		local dTier = DURATION_TIERS[i]

		local curSpeed = scope:Computed(function(use)
			return use(props.Speed) .. " SPEED"
		end)
		local nxtSpeed = scope:Computed(function(use)
			return (use(props.Speed) + sTier.Inc) .. " SPEED"
		end)
		local curDur = scope:Computed(function(use)
			return use(props.Duration) .. "s DURATION"
		end)
		local nxtDur = scope:Computed(function(use)
			return (use(props.Duration) + dTier.Inc) .. "s DURATION"
		end)

		upgradeRows[i] = scope:New "Frame" {
			LayoutOrder            = i,
			Size                   = UDim2.fromScale(1, 0.225),
			BackgroundTransparency = 1,
			[Fusion.Children] = {
				scope:New "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder     = Enum.SortOrder.LayoutOrder,
					Padding       = UDim.new(0.02, 0),
				},
				_card(SPEED_ICON,    "+" .. sTier.Inc,        curSpeed, nxtSpeed, sTier.Cost, sTier.Robux, UDim2.fromScale(0.49, 1), props.OnUpgradeSpeed),
				_card(DURATION_ICON, "+" .. dTier.Inc .. "s", curDur,   nxtDur,   dTier.Cost, dTier.Robux, UDim2.fromScale(0.49, 1), props.OnUpgradeDuration),
			},
		}
	end

	-- ── Full-width carry row ───────────────────────────────────────────────────

	local curCarry = scope:Computed(function(use)
		return use(props.CarryAmount) .. " CARRY"
	end)
	local nxtCarry = scope:Computed(function(use)
		return (use(props.CarryAmount) + 1) .. " CARRY"
	end)

	local carryRow = scope:New "Frame" {
		LayoutOrder            = 4,
		Size                   = UDim2.fromScale(1, 0.2),
		BackgroundTransparency = 1,
		[Fusion.Children] = {
			_card(CARRY_ICON, "+1", curCarry, nxtCarry, CARRY_COST, CARRY_ROBUX, UDim2.fromScale(1, 1), props.OnUpgradeCarry),
		},
	}

	-- ── Header close button ────────────────────────────────────────────────────

	local closeBtn = scope:New "ImageButton" {
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = UDim2.fromScale(0.85, 0.5),
		Size             = UDim2.fromScale(0.15, 1),
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		Image = "rbxassetid://108990027053707",

		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" {},
		},

		[Fusion.OnEvent "Activated"] = props.OnClose,
	}

	-- ── Main panel ─────────────────────────────────────────────────────────────

	return scope:New "Frame" {
		Name             = "ZiplineUpgradePanel",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0.5, 1.5),
		Size             = UDim2.fromScale(0.55, 0.75),
		Visible          = false,
		BackgroundColor3 = C_PANEL,
		BorderSizePixel  = 0,
		[Fusion.Children] = {
			_stroke(2),

			-- Header
			scope:New "Frame" {
				Size             = UDim2.fromScale(1, 0.12),
				BackgroundColor3 = C_HEADER,
				BorderSizePixel  = 0,
				[Fusion.Children] = {
					_stroke(2),
					scope:New "Frame" {
						AnchorPoint      = Vector2.new(0, 0.5),
						Position         = UDim2.fromScale(0.02, 0.5),
						Size             = UDim2.fromScale(0.06, 0.7),
						BackgroundColor3 = Color3.fromRGB(58, 200, 48),
						BorderSizePixel  = 0,
						[Fusion.Children] = {
							_stroke(1.5),
							scope:New "TextLabel" {
								Size                   = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								Text                   = "▲",
								TextColor3             = C_WHITE,
								FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
								TextScaled             = true,
							},
						},
					},
					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(0, 0.5),
						Position               = UDim2.fromScale(0.1, 0.5),
						Size                   = UDim2.fromScale(0.35, 0.65),
						BackgroundTransparency = 1,
						Text                   = "Upgrades",
						TextColor3             = C_WHITE,
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled             = true,
						TextXAlignment         = Enum.TextXAlignment.Left,
					},
					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(1, 0.5),
						Position               = UDim2.fromScale(0.88, 0.5),
						Size                   = UDim2.fromScale(0.35, 0.65),
						BackgroundTransparency = 1,
						Text                   = scope:Computed(function(use)
							return "$" .. FormatNumber(use(props.Cash))
						end),
						TextColor3             = C_GREEN,
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled             = true,
						TextXAlignment         = Enum.TextXAlignment.Right,
					},
					closeBtn,
				},
			},

			-- Body
			scope:New "Frame" {
				Position               = UDim2.fromScale(0, 0.12),
				Size                   = UDim2.fromScale(1, 0.88),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "UIPadding" {
						PaddingLeft   = UDim.new(0.015, 0),
						PaddingRight  = UDim.new(0.015, 0),
						PaddingTop    = UDim.new(0.02, 0),
						PaddingBottom = UDim.new(0.02, 0),
					},
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder     = Enum.SortOrder.LayoutOrder,
						Padding       = UDim.new(0.015, 0),
					},
					upgradeRows[1],
					upgradeRows[2],
					upgradeRows[3],
					carryRow,
				},
			},
		},
	}
end
