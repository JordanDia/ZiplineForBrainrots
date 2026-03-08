local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local scoped = Fusion.scoped

local StatBadge           = require("../components/StatBadge")
local CashDisplay         = require("../components/CashDisplay")
local SideMenu            = require("../components/SideMenu")
local ZiplineUpgradePanel = require("../components/ZiplineUpgradePanel")

return function(parent)
	local scope = scoped(Fusion, {
		StatBadge           = StatBadge,
		CashDisplay         = CashDisplay,
		SideMenu            = SideMenu,
		ZiplineUpgradePanel = ZiplineUpgradePanel,
	})

	local DataService = Knit.GetService("DataService")
	local CurrencyService = Knit.GetService("CurrencyService")
	local SpeedService = Knit.GetService("SpeedService")
	local DurationService = Knit.GetService("DurationService")

	-- Placeholder state — wire these up to services later
	local cash        = scope:Value(CurrencyService:GetCash())

	-- ── Zipline upgrade panel state ─────────────────────────────────────────
	local panelOpen      = scope:Value(false)
	local ziplineSpeed    = scope:Value(20)
	local ziplineDuration = scope:Value(5)

	-- Fetch real values from SpeedService and DurationService
	task.spawn(function()
		ziplineSpeed:set(SpeedService:GetSpeed())
		ziplineDuration:set(DurationService:GetDuration())
	end)

	local function onUpgradeSpeed()
		task.spawn(function()
			local newSpeed = SpeedService:Upgrade()
			ziplineSpeed:set(newSpeed)
		end)
	end

	local function onUpgradeDuration()
		task.spawn(function()
			local newDuration = DurationService:Upgrade()
			ziplineDuration:set(newDuration)
		end)
	end

	CurrencyService.CashChanged:Connect(function(newCash: number)
		cash:set(newCash)
		

	end)

	local function OnDataLoaded(data)
		cash:set(data.Cash)
		ziplineSpeed:set(data.ZiplineSpeed)
		ziplineDuration:set(data.ZiplineDuration)
	end
	DataService.DataLoaded:Connect(OnDataLoaded)
	local data = DataService:GetData()
	if data then
		OnDataLoaded(data)
	end

	-- ── Zipline side button ─────────────────────────────────────────────────
	local ziplineBtn = scope:New "TextButton" {
		Name = "ZiplineBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(68, 68),
		BackgroundColor3 = Color3.fromRGB(18, 13, 7),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = "",
		[Fusion.Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 12) },
			scope:New "UIStroke" { Color = Color3.fromRGB(70, 50, 20), Thickness = 1.5 },
			scope:New "TextLabel" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Zipline",
				FontFace = Font.fromName("GothamSSm", Enum.FontWeight.Bold),
				TextSize = 13,
				TextColor3 = Color3.fromRGB(255, 220, 40),
				TextXAlignment = Enum.TextXAlignment.Center,
			},
		},
	}
	ziplineBtn.Activated:Connect(function()
		panelOpen:set(not Fusion.peek(panelOpen))
	end)

	local screenGui = scope:New "ScreenGui" {
		Parent = parent,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,

		[Fusion.Children] = {

			-- Top-center stat badges row
			scope:New "Frame" {
				Name = "TopStats",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.05),
				Size = UDim2.fromScale(0.2, 0.08),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 8),
					},
					scope:StatBadge { Icon = "rbxassetid://121441312069242", Count = ziplineSpeed },
					scope:StatBadge { Icon = "rbxassetid://126340774874320", Count = ziplineDuration },
				},
			},

			-- Cash display
			scope:CashDisplay {
				Cash = cash,
			},

			-- Left-side menu
			scope:SideMenu {},

			-- Right-side zipline upgrade button
			ziplineBtn,

			-- Zipline upgrade panel (center screen, toggled by side button)
			scope:ZiplineUpgradePanel {
				Visible           = panelOpen,
				Speed             = ziplineSpeed,
				Duration          = ziplineDuration,
				OnUpgradeSpeed    = onUpgradeSpeed,
				OnUpgradeDuration = onUpgradeDuration,
				OnClose           = function() panelOpen:set(false) end,
			},

		},
	}

	return screenGui
end
