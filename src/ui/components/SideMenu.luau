local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local LABEL_COLOR = Color3.fromRGB(255, 255, 255)
local STROKE      = Color3.fromRGB(65, 48, 20)

local BUTTONS = {
	{ id = "124627397416655", label = "Index"   },
	{ id = "70872911169333",  label = "Boost"   },
	{ id = "140733726940903", label = "Rebirth" },
	{ id = "104871659073352", label = "Shop"    },
}

local function Button(scope, assetId, label)
	return scope:New "ImageButton" {
		Name = label,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://" .. assetId,
		ScaleType = Enum.ScaleType.Fit,
		[Fusion.Children] = {
			scope:New "UIAspectRatioConstraint" { AspectRatio = 1 },
			scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
			
			-- Label sits at the bottom of the image
			scope:New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(1, 0.30),
				BackgroundTransparency = 1,
				Text = label,
				FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
				TextScaled = true,
				TextColor3 = LABEL_COLOR,
				TextStrokeTransparency = 0.3,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

				[Fusion.Children] = {

					scope:New "UIStroke" { Color = STROKE, Thickness = 3 },

				}
			},
		},
	}
end

return function(scope, _props)
	local buttons = {}
	for _, data in BUTTONS do
		table.insert(buttons, Button(scope, data.id, data.label))
	end

	return scope:New "Frame" {
		Name = "SideMenu",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.008, 0.4),
		Size = UDim2.fromScale(0.16, 0.30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		[Fusion.Children] = {
			scope:New "UIGridLayout" {
				CellSize = UDim2.fromScale(0.46, 0.46),
				CellPadding = UDim2.fromScale(0.08, 0.08),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			table.unpack(buttons),
		},
	}
end
