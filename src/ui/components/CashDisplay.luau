local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

-- Props:
--   Cash (Value<number>)
return function(scope, props)
	return scope:New "TextLabel" {
		Name = "CashDisplay",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.15),
		Size = UDim2.fromScale(0.1, 0.1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = scope:Computed(function(use)
			return "$" .. FormatNumber(use(props.Cash), ".##")
		end),
		FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
		TextSize = 36,
		TextScaled = false,
		TextColor3 = Color3.fromRGB(85, 220, 85),
		[Fusion.Children] = {
			scope:New "UIStroke" {
				Color     = Color3.fromRGB(0, 0, 0),
				Thickness = 4,
			},
		},
	}
end
