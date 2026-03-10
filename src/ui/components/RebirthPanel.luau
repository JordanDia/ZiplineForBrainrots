local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- ── Palette ──────────────────────────────────────────────────────────────────
local C_PANEL  = Color3.fromRGB(12, 10, 20)
local C_HEADER = Color3.fromRGB(95, 28, 175)
local C_CARD   = Color3.fromRGB(22, 16, 38)
local C_DARK   = Color3.fromRGB(8, 5, 14)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_GOLD   = Color3.fromRGB(255, 200, 0)
local C_CYAN   = Color3.fromRGB(80, 200, 255)
local C_GREEN  = Color3.fromRGB(40, 185, 75)
local C_RED    = Color3.fromRGB(180, 45, 45)
local C_PURPLE = Color3.fromRGB(130, 50, 220)
local C_MUTED  = Color3.fromRGB(160, 140, 200)
local STROKE   = Color3.fromRGB(80, 45, 130)

local REBIRTH_START_SPEED = 50
local REBIRTH_SPEED_INC   = 40
local SKIP_ROBUX          = 99

local function _stroke(scope, thickness)
	return scope:New "UIStroke" { Color = STROKE, Thickness = thickness }
end

-- ── Props ─────────────────────────────────────────────────────────────────────
-- Props:
--   Rebirths  Value<number>  current rebirth count
--   Speed     Value<number>  current zipline speed (reactive)
--   OnRebirth function       called when the Rebirth button is pressed
--   OnClose   function
return function(scope, props)
	local rebirths = props.Rebirths
	local speed    = props.Speed

	-- ── Derived state ─────────────────────────────────────────────────────────
	local requiredSpeed = scope:Computed(function(use)
		return REBIRTH_START_SPEED + use(rebirths) * REBIRTH_SPEED_INC
	end)

	local cashMultText = scope:Computed(function(use)
		return string.format("%.1fx", 1 + use(rebirths) * 0.5)
	end)

	local nextCashMultText = scope:Computed(function(use)
		return string.format("%.1fx", 1 + (use(rebirths) + 1) * 0.5)
	end)

	local canRebirth = scope:Computed(function(use)
		return use(speed) >= use(requiredSpeed)
	end)

	local rebirthBtnColor = scope:Computed(function(use)
		return if use(canRebirth) then C_GREEN else C_RED
	end)

	local rebirthBtnText = scope:Computed(function(use)
		if use(canRebirth) then
			return "REBIRTH"
		end
		local needed = use(requiredSpeed) - math.floor(use(speed))
		return "NEED +" .. needed .. " SPEED"
	end)

	local rebirthsLabel = scope:Computed(function(use)
		return "REBIRTH  #" .. (use(rebirths) + 1)
	end)

	local progressBarSize = scope:Computed(function(use)
		local req = use(requiredSpeed)
		local p   = math.min(1, use(speed) / req)
		return UDim2.fromScale(math.max(0.01, p), 1)
	end)

	local progressBarColor = scope:Computed(function(use)
		local req = use(requiredSpeed)
		local p   = math.min(1, use(speed) / req)
		if p >= 1 then
			return C_GREEN
		elseif p >= 0.5 then
			return Color3.fromRGB(200, 150, 0)
		else
			return Color3.fromRGB(180, 60, 40)
		end
	end)

	local progressText = scope:Computed(function(use)
		return use(speed) .. " / " .. use(requiredSpeed) .. " SPEED"
	end)

	-- ── Close button ──────────────────────────────────────────────────────────
	local closeBtn = scope:New "ImageButton" {
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.fromScale(0.98, 0.5),
		Size                   = UDim2.fromScale(0.09, 0.78),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Image                  = "rbxassetid://108990027053707",
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" {},
		},
		[Fusion.OnEvent "Activated"] = props.OnClose,
	}

	-- ── Stat comparison card ──────────────────────────────────────────────────
	local function _statCard(titleStr, multVal, accent, layoutOrder)
		return scope:New "Frame" {
			LayoutOrder      = layoutOrder,
			Size             = UDim2.fromScale(0.38, 1),
			BackgroundColor3 = C_CARD,
			BorderSizePixel  = 0,
			[Fusion.Children] = {
				_stroke(scope, 1.5),
				scope:New "UIListLayout" {
					FillDirection       = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment   = Enum.VerticalAlignment.Center,
					SortOrder           = Enum.SortOrder.LayoutOrder,
					Padding             = UDim.new(0.02, 0),
				},
				scope:New "TextLabel" {
					LayoutOrder            = 1,
					Size                   = UDim2.fromScale(1, 0.22),
					BackgroundTransparency = 1,
					Text                   = titleStr,
					TextColor3             = C_MUTED,
					FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
					TextScaled             = true,
				},
				scope:New "TextLabel" {
					LayoutOrder            = 2,
					Size                   = UDim2.fromScale(1, 0.38),
					BackgroundTransparency = 1,
					Text                   = multVal,
					TextColor3             = accent,
					FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
					TextScaled             = true,
				},
				scope:New "TextLabel" {
					LayoutOrder            = 3,
					Size                   = UDim2.fromScale(1, 0.22),
					BackgroundTransparency = 1,
					Text                   = "CASH MULT",
					TextColor3             = Color3.fromRGB(130, 120, 160),
					FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
					TextScaled             = true,
				},
			},
		}
	end

	-- ── Assemble panel ────────────────────────────────────────────────────────
	local panelFrame = scope:New "Frame" {
		Name             = "RebirthPanel",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(0.5, 1.5),
		Size             = UDim2.fromScale(0.44, 0.62),
		Visible          = false,
		BackgroundColor3 = C_PANEL,
		BorderSizePixel  = 0,
		[Fusion.Children] = {
			_stroke(scope, 2),

			-- ── Header ────────────────────────────────────────────────────────
			scope:New "Frame" {
				Size             = UDim2.fromScale(1, 0.13),
				BackgroundColor3 = C_HEADER,
				BorderSizePixel  = 0,
				[Fusion.Children] = {
					_stroke(scope, 2),

					scope:New "ImageLabel" {
						AnchorPoint            = Vector2.new(0, 0.5),
						Position               = UDim2.fromScale(0.03, 0.5),
						Size                   = UDim2.fromScale(0.065, 0.72),
						BackgroundTransparency = 1,
						Image                  = "rbxassetid://74753957626091",
						ScaleType              = Enum.ScaleType.Fit,
						[Fusion.Children] = {
							scope:New "UIAspectRatioConstraint" {},
						},
					},

					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(0, 0.5),
						Position               = UDim2.fromScale(0.12, 0.5),
						Size                   = UDim2.fromScale(0.35, 0.68),
						BackgroundTransparency = 1,
						Text                   = "REBIRTH",
						TextColor3             = C_WHITE,
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled             = true,
						TextXAlignment         = Enum.TextXAlignment.Left,
					},

					scope:New "TextLabel" {
						AnchorPoint            = Vector2.new(0.5, 0.5),
						Position               = UDim2.fromScale(0.58, 0.5),
						Size                   = UDim2.fromScale(0.28, 0.62),
						BackgroundTransparency = 1,
						Text                   = rebirthsLabel,
						TextColor3             = Color3.fromRGB(210, 175, 255),
						FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
						TextScaled             = true,
					},

					closeBtn,
				},
			},

			-- ── Body ─────────────────────────────────────────────────────────
			scope:New "Frame" {
				Position               = UDim2.fromScale(0, 0.13),
				Size                   = UDim2.fromScale(1, 0.87),
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
				[Fusion.Children] = {
					scope:New "UIPadding" {
						PaddingLeft   = UDim.new(0.04, 0),
						PaddingRight  = UDim.new(0.04, 0),
						PaddingTop    = UDim.new(0.04, 0),
						PaddingBottom = UDim.new(0.04, 0),
					},
					scope:New "UIListLayout" {
						FillDirection       = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder           = Enum.SortOrder.LayoutOrder,
						Padding             = UDim.new(0.03, 0),
					},

					-- ── Comparison row ────────────────────────────────────────
					scope:New "Frame" {
						LayoutOrder            = 1,
						Size                   = UDim2.fromScale(1, 0.37),
						BackgroundTransparency = 1,
						BorderSizePixel        = 0,
						[Fusion.Children] = {
							scope:New "UIListLayout" {
								FillDirection       = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment   = Enum.VerticalAlignment.Center,
								SortOrder           = Enum.SortOrder.LayoutOrder,
								Padding             = UDim.new(0.02, 0),
							},

							_statCard("CURRENT", cashMultText, C_GOLD, 1),

							scope:New "ImageLabel" {
								LayoutOrder            = 2,
								Size                   = UDim2.fromScale(0.14, 0.55),
								BackgroundTransparency = 1,
								Image                  = "rbxassetid://74753957626091",
								ScaleType              = Enum.ScaleType.Fit,
								[Fusion.Children] = {
									scope:New "UIAspectRatioConstraint" {},
								},
							},

							_statCard("NEXT", nextCashMultText, C_CYAN, 3),
						},
					},

					-- ── Speed progress ────────────────────────────────────────
					scope:New "Frame" {
						LayoutOrder      = 2,
						Size             = UDim2.fromScale(1, 0.28),
						BackgroundColor3 = C_CARD,
						BorderSizePixel  = 0,
						[Fusion.Children] = {
							_stroke(scope, 1.5),
							scope:New "UIPadding" {
								PaddingLeft   = UDim.new(0.04, 0),
								PaddingRight  = UDim.new(0.04, 0),
								PaddingTop    = UDim.new(0.06, 0),
								PaddingBottom = UDim.new(0.06, 0),
							},
							scope:New "UIListLayout" {
								FillDirection       = Enum.FillDirection.Vertical,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment   = Enum.VerticalAlignment.Center,
								SortOrder           = Enum.SortOrder.LayoutOrder,
								Padding             = UDim.new(0.05, 0),
							},

							scope:New "TextLabel" {
								LayoutOrder            = 1,
								Size                   = UDim2.fromScale(1, 0.25),
								BackgroundTransparency = 1,
								Text                   = "SPEED REQUIREMENT",
								TextColor3             = C_MUTED,
								FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
								TextScaled             = true,
							},

							-- Progress bar
							scope:New "Frame" {
								LayoutOrder      = 2,
								Size             = UDim2.fromScale(1, 0.32),
								BackgroundColor3 = C_DARK,
								BorderSizePixel  = 0,
								[Fusion.Children] = {
									_stroke(scope, 1),
									scope:New "Frame" {
										AnchorPoint      = Vector2.new(0, 0.5),
										Position         = UDim2.fromScale(0, 0.5),
										Size             = progressBarSize,
										BackgroundColor3 = progressBarColor,
										BorderSizePixel  = 0,
									},
								},
							},

							scope:New "TextLabel" {
								LayoutOrder            = 3,
								Size                   = UDim2.fromScale(1, 0.25),
								BackgroundTransparency = 1,
								Text                   = progressText,
								TextColor3             = C_WHITE,
								FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
								TextScaled             = true,
							},
						},
					},

					-- ── Buttons ───────────────────────────────────────────────
					scope:New "Frame" {
						LayoutOrder            = 3,
						Size                   = UDim2.fromScale(1, 0.2),
						BackgroundTransparency = 1,
						BorderSizePixel        = 0,
						[Fusion.Children] = {
							scope:New "UIListLayout" {
								FillDirection       = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment   = Enum.VerticalAlignment.Center,
								SortOrder           = Enum.SortOrder.LayoutOrder,
								Padding             = UDim.new(0.04, 0),
							},

							-- Rebirth button
							scope:New "TextButton" {
								LayoutOrder      = 1,
								Size             = UDim2.fromScale(0.55, 0.85),
								BackgroundColor3 = rebirthBtnColor,
								BorderSizePixel  = 0,
								Text             = rebirthBtnText,
								TextColor3       = C_WHITE,
								FontFace         = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
								TextScaled       = true,
								[Fusion.Children] = {
									_stroke(scope, 1.5),
								},
								[Fusion.OnEvent "Activated"] = function()
									if Fusion.peek(canRebirth) then
										props.OnRebirth()
									end
								end,
							},

							-- Skip / Robux button
							scope:New "TextButton" {
								LayoutOrder      = 2,
								Size             = UDim2.fromScale(0.35, 0.85),
								BackgroundColor3 = C_PURPLE,
								BorderSizePixel  = 0,
								Text             = "SKIP  R$" .. SKIP_ROBUX,
								TextColor3       = C_WHITE,
								FontFace         = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
								TextScaled       = true,
								[Fusion.Children] = {
									_stroke(scope, 1.5),
								},
							},
						},
					},
				},
			},
		},
	}

	return panelFrame
end
