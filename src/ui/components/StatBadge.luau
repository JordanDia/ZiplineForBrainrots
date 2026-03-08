local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

-- Props:
--   Icon    (string)         asset id for the icon image
--   Count   (Value<number>)  reactive count to display
return function(scope, props)
	return scope:New "Frame" {
		Name = "StatBadge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.40, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BorderSizePixel = 0,
		[Fusion.Children] = {
			scope:New "UIGradient" {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0,   1),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1,   1),
				}),
			},
		
			scope:New "UIListLayout" {
				FillDirection     = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder         = Enum.SortOrder.LayoutOrder,
				Padding           = UDim.new(0.1, 0),
			},

			-- Circular icon
			scope:New "ImageLabel" {
				Name = "Icon",
				LayoutOrder = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.3, 0.8),
				Position = UDim2.fromScale(0.2, 0.5),
				BackgroundTransparency = 1,
				Image = props.Icon or "",
				ScaleType = Enum.ScaleType.Fit,
				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" {
						AspectRatio  = 1,
						DominantAxis = Enum.DominantAxis.Height,
					},
					
				},
			},

			-- Count
			scope:New "TextLabel" {
				Name = "CountLabel",
				LayoutOrder = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return FormatNumber(use(props.Count))
				end),
				FontFace = Font.fromName("FredokaOne", Enum.FontWeight.Bold),
				TextScaled = false,
				TextSize = 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeTransparency = 0.3,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			},

			-- Plus button
			scope:New "ImageButton" {
				Name = "PlusButton",
				LayoutOrder = 3,
				Size = UDim2.fromScale(0.6, 0.6),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = "rbxassetid://89430781599798",
				ScaleType = Enum.ScaleType.Fit,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				[Fusion.Children] = {
					scope:New "UIAspectRatioConstraint" {
						AspectRatio  = 1,
						DominantAxis = Enum.DominantAxis.Height,
					},
					scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
				},
			},
		},
	}
end
