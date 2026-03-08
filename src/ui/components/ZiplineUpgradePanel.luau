local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local DARK_BG = Color3.fromRGB(18, 13, 7)
local GOLD    = Color3.fromRGB(255, 220, 40)
local GREEN   = Color3.fromRGB(55, 185, 55)
local WHITE   = Color3.fromRGB(255, 255, 255)
local STROKE  = Color3.fromRGB(70, 50, 20)

-- Props:
--   Visible          (Value<boolean>)
--   Speed            (Value<number>)
--   Duration         (Value<number>)
--   OnUpgradeSpeed   (function)
--   OnUpgradeDuration (function)
--   OnClose          (function)
return function(scope, props)
	local closeBtn = scope:New "TextButton" {
		Name = "CloseBtn",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(26, 26),
		BackgroundTransparency = 1,
		Text = "✕",
		FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
		TextSize = 18,
		TextColor3 = Color3.fromRGB(180, 180, 180),
	}
	closeBtn.Activated:Connect(props.OnClose)

	local upgradeSpeedBtn = scope:New "TextButton" {
		Name = "UpgradeSpeedBtn",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(220, 46),
		BackgroundColor3 = GREEN,
		BorderSizePixel = 0,
		Text = "Upgrade Speed  (+5 studs/s)",
		FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
		TextSize = 16,
		TextColor3 = WHITE,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
		},
	}
	upgradeSpeedBtn.Activated:Connect(props.OnUpgradeSpeed)

	local upgradeDurationBtn = scope:New "TextButton" {
		Name = "UpgradeDurationBtn",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 218),
		Size = UDim2.fromOffset(220, 46),
		BackgroundColor3 = GREEN,
		BorderSizePixel = 0,
		Text = "Upgrade Duration  (+2s)",
		FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
		TextSize = 16,
		TextColor3 = WHITE,
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 8) },
		},
	}
	upgradeDurationBtn.Activated:Connect(props.OnUpgradeDuration)

	return scope:New "Frame" {
		Name = "ZiplineUpgradePanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 290),
		Visible = scope:Computed(function(use) return use(props.Visible) end),
		BackgroundColor3 = DARK_BG,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,

		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 14) },
			scope:New "UIStroke" { Color = STROKE, Thickness = 2 },

			-- Title
			scope:New "TextLabel" {
				Position = UDim2.new(0, 0, 0, 14),
				Size = UDim2.new(1, -44, 0, 28),
				BackgroundTransparency = 1,
				Text = "Zipline Upgrades",
				FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
				TextSize = 20,
				TextColor3 = GOLD,
				TextXAlignment = Enum.TextXAlignment.Center,
			},

			closeBtn,

			-- Divider
			scope:New "Frame" {
				Position = UDim2.new(0, 16, 0, 50),
				Size = UDim2.new(1, -32, 0, 1),
				BackgroundColor3 = STROKE,
				BorderSizePixel = 0,
			},

			-- Speed stat
			scope:New "TextLabel" {
				Position = UDim2.new(0, 0, 0, 66),
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return "Speed:  " .. use(props.Speed) .. " studs/s"
				end),
				FontFace = Font.fromName("GothamSSm", Enum.FontWeight.SemiBold),
				TextSize = 16,
				TextColor3 = WHITE,
				TextXAlignment = Enum.TextXAlignment.Center,
			},

			upgradeSpeedBtn,

			-- Divider
			scope:New "Frame" {
				Position = UDim2.fromOffset(16, 178),
				Size = UDim2.new(1, -32, 0, 1),
				BackgroundColor3 = STROKE,
				BorderSizePixel = 0,
			},

			-- Duration stat
			scope:New "TextLabel" {
				Position = UDim2.fromOffset(0, 184),
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return "Duration:  " .. use(props.Duration) .. "s"
				end),
				FontFace = Font.fromName("GothamSSm", Enum.FontWeight.SemiBold),
				TextSize = 16,
				TextColor3 = WHITE,
				TextXAlignment = Enum.TextXAlignment.Center,
			},

			upgradeDurationBtn,
		},
	}
end
