-- CoinsFrame.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

return function(scope, props)
	return scope:New "Frame" {
		Name = "ExampleComponent",
		Size = UDim2.fromOffset(210, 52),
		Position = UDim2.new(0, 16, 1, -16),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(22, 16, 6),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,

		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },

			scope:New "UIStroke" {
				Color = Color3.fromRGB(255, 185, 30),
				Thickness = 2,
				Transparency = 0.35,
			},

			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			},

			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},

			scope:New "ImageLabel" {
				Name = "CoinIcon",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(34, 34),
				BackgroundTransparency = 1,
				Image = "rbxassetid://113050439162696",
				ScaleType = Enum.ScaleType.Fit,
			},

			scope:New "TextLabel" {
				Name = "CoinsLabel",
				LayoutOrder = 2,
				Size = UDim2.new(1, -42, 1, 0),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return FormatNumber(use(props.Coins))
				end),
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				TextScaled = true,
				TextColor3 = Color3.fromRGB(255, 210, 50),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextStrokeTransparency = 0.4,
				TextStrokeColor3 = Color3.fromRGB(120, 60, 0),
				[Fusion.Children] = {
					scope:New "UITextSizeConstraint" { MaxTextSize = 26 },
				},
			},
		},
	}
end
