local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit   = require(ReplicatedStorage.Packages.Knit)

local scoped = Fusion.scoped

local StatBadge           = require("../components/StatBadge")
local CashDisplay         = require("../components/CashDisplay")
local SideMenu            = require("../components/SideMenu")
local ZiplineUpgradePanel = require("../components/ZiplineUpgradePanel")
local IndexPanel          = require("../components/IndexPanel")
local RebirthPanel        = require("../components/RebirthPanel")

-- Panel tween targets and timing
local PANEL_OPEN_POS  = UDim2.fromScale(0.5, 0.5)
local PANEL_CLOSE_POS = UDim2.fromScale(0.5, 1.5)
local OPEN_INFO       = TweenInfo.new(0.4,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_INFO      = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- XZ distance from UpgradeZone.Base center that triggers the panel
local ZONE_RADIUS = 6

return function(parent)
	local scope = scoped(Fusion, {
		StatBadge   = StatBadge,
		CashDisplay = CashDisplay,
		SideMenu    = SideMenu,
	})

	local DataService        = Knit.GetService("DataService")
	local CurrencyService    = Knit.GetService("CurrencyService")
	local SpeedService       = Knit.GetService("SpeedService")
	local DurationService    = Knit.GetService("DurationService")
	local RebirthService     = Knit.GetService("RebirthService")
	local BrainrotService    = Knit.GetService("BrainrotService")
	local BaseService        = Knit.GetService("BaseService")
	local IndexController    = Knit.GetController("IndexController")
	local RebirthController  = Knit.GetController("RebirthController")
	local ZoneController     = Knit.GetController("ZoneController")
	local BoostController    = Knit.GetController("BoostController")
	local ZiplineController  = Knit.GetController("ZiplineController")

	local cash            = scope:Value(CurrencyService:GetCash())
	local ziplineSpeed    = scope:Value(20)
	local ziplineDuration = scope:Value(5)
	local carryAmount     = scope:Value(1)
	local rebirths        = scope:Value(0)

	-- ── Zone state ────────────────────────────────────────────────────────────
	local isInSafeZone  = scope:Value(ZoneController.IsInSafeZone)
	local luckMult      = scope:Value(ZoneController.LuckMultiplier)
	local heldBrainrot  = scope:Value(ZoneController.HeldBrainrot)

	ZoneController.SafeZoneChanged:Connect(function(v: boolean)
		isInSafeZone:set(v)
	end)
	ZoneController.LuckChanged:Connect(function(v: number)
		luckMult:set(v)
	end)
	ZoneController.HeldChanged:Connect(function(v: string?)
		heldBrainrot:set(v)
	end)

	local luckVisible = scope:Computed(function(use)
		return use(luckMult) > 0
	end)
	local luckText = scope:Computed(function(use)
		return "x" .. use(luckMult) .. " LUCK"
	end)
	local outsideNoHeld = scope:Computed(function(use)
		return not use(isInSafeZone) and use(heldBrainrot) == nil
	end)
	local outsideHasHeld = scope:Computed(function(use)
		return not use(isInSafeZone) and use(heldBrainrot) ~= nil
	end)

	-- ── Zipline progress bar state ────────────────────────────────────────────
	local ziplineBarVisible = scope:Value(false)
	local ziplineProgress   = scope:Value(1) -- 0–1, 1 = full

	local _progressConn: RBXScriptConnection? = nil

	ZiplineController.MountChanged:Connect(function(isMounted: boolean)
		if isMounted then
			ziplineBarVisible:set(true)
			_progressConn = RunService.Heartbeat:Connect(function()
				local total = ZiplineController.TotalDuration
				if total <= 0 then return end
				ziplineProgress:set(math.clamp(ZiplineController.TimeLeft / total, 0, 1))
			end)
		else
			if _progressConn then
				_progressConn:Disconnect()
				_progressConn = nil
			end
			ziplineProgress:set(1)
			ziplineBarVisible:set(false)
		end
	end)

	local ziplineBarColor = scope:Computed(function(use)
		local p = use(ziplineProgress)
		if p > 0.5 then
			-- green → yellow as p goes 1 → 0.5
			return Color3.fromRGB(50, 210, 50):Lerp(Color3.fromRGB(255, 200, 0), (1 - p) * 2)
		else
			-- yellow → red as p goes 0.5 → 0
			return Color3.fromRGB(255, 200, 0):Lerp(Color3.fromRGB(220, 40, 40), (0.5 - p) * 2)
		end
	end)

	local ziplineFillSize = scope:Computed(function(use)
		return UDim2.fromScale(use(ziplineProgress), 1)
	end)

	local function onReturn()
		task.spawn(function()
			BaseService:ReturnToBase()
		end)
	end

	local function onDrop()
		task.spawn(function()
			BrainrotService:DropBrainrot()
		end)
	end

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
		carryAmount:set(data.CarryAmount or 1)
		rebirths:set(data.Rebirths or 0)
	end
	DataService.DataLoaded:Connect(OnDataLoaded)
	local data = DataService:GetData()
	if data then
		OnDataLoaded(data)
	end

	RebirthController.RebirthCompleted:Connect(function(newRebirths: number)
		rebirths:set(newRebirths)
	end)

	-- ── Panel tween state ─────────────────────────────────────────────────────
	local _panelOpen  = false
	local _activeTween: Tween?               = nil
	local _closeConn:   RBXScriptConnection? = nil
	local panelFrame: Frame  -- assigned after the functions that reference it

	local function openPanel()
		if _panelOpen then return end
		_panelOpen = true
		if _activeTween then
			_activeTween:Cancel()
			_activeTween = nil
		end
		if _closeConn then
			_closeConn:Disconnect()
			_closeConn = nil
		end
		panelFrame.Visible = true
		local t = TweenService:Create(panelFrame, OPEN_INFO, { Position = PANEL_OPEN_POS })
		_activeTween = t
		t:Play()
	end

	local function closePanel()
		if not _panelOpen then return end
		_panelOpen = false
		if _activeTween then
			_activeTween:Cancel()
			_activeTween = nil
		end
		if _closeConn then
			_closeConn:Disconnect()
			_closeConn = nil
		end
		local t = TweenService:Create(panelFrame, CLOSE_INFO, { Position = PANEL_CLOSE_POS })
		_activeTween = t
		t:Play()
		_closeConn = t.Completed:Connect(function()
			_closeConn = nil
			if not _panelOpen then
				panelFrame.Visible = false
			end
		end)
	end

	-- Create the panel frame (starts off-screen; position/visibility driven by tweens)
	panelFrame = ZiplineUpgradePanel(scope, {
		Speed             = ziplineSpeed,
		Duration          = ziplineDuration,
		CarryAmount       = carryAmount,
		Cash              = cash,
		OnUpgradeSpeed    = onUpgradeSpeed,
		OnUpgradeDuration = onUpgradeDuration,
		OnClose           = closePanel,
	})

	-- ── Upgrade zone proximity detection ─────────────────────────────────────
	local upgradeModel    = Workspace:FindFirstChild("Upgrade")
	local upgradeZone     = upgradeModel and upgradeModel:FindFirstChild("UpgradeZone")
	local upgradeZonePart = upgradeZone  and upgradeZone:FindFirstChild("Base") :: BasePart?

	if upgradeZonePart then
		local lastInZone = false
		local elapsed    = 0
		RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 0.2 then return end
			elapsed = 0

			local char = Players.LocalPlayer.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then return end

			local dx = hrp.Position.X - upgradeZonePart.Position.X
			local dz = hrp.Position.Z - upgradeZonePart.Position.Z
			local inZone = (dx * dx + dz * dz) < ZONE_RADIUS * ZONE_RADIUS

			if inZone ~= lastInZone then
				lastInZone = inZone
				if inZone then
					openPanel()
				else
					closePanel()
				end
			end
		end)
	else
		warn("[Hud] Workspace.Upgrade.UpgradeZone.Base not found — zone detection disabled")
	end

	-- ── Index panel ───────────────────────────────────────────────────────────
	local _indexOpen  = false
	local _indexTween: Tween?               = nil
	local _indexConn:  RBXScriptConnection? = nil
	local indexFrame: Frame

	local function openIndex()
		if _indexOpen then return end
		_indexOpen = true
		if _indexTween then
			_indexTween:Cancel()
		end
		if _indexConn then
			_indexConn:Disconnect()
			_indexConn = nil
		end
		indexFrame.Visible = true
		local t = TweenService:Create(indexFrame, OPEN_INFO, { Position = PANEL_OPEN_POS })
		_indexTween = t
		t:Play()
	end

	local function closeIndex()
		if not _indexOpen then return end
		_indexOpen = false
		if _indexTween then
			_indexTween:Cancel()
		end
		if _indexConn then
			_indexConn:Disconnect()
			_indexConn = nil
		end
		local t = TweenService:Create(indexFrame, CLOSE_INFO, { Position = PANEL_CLOSE_POS })
		_indexTween = t
		t:Play()
		_indexConn = t.Completed:Connect(function()
			_indexConn = nil
			if not _indexOpen then
				indexFrame.Visible = false
			end
		end)
	end

	indexFrame = IndexPanel(scope, {
		UnlockedSet  = IndexController.Unlocked,
		UnlockSignal = IndexController.BrainrotUnlocked,
		OnClose      = closeIndex,
	})

	-- ── Rebirth panel ─────────────────────────────────────────────────────────
	local _rebirthOpen  = false
	local _rebirthTween: Tween?               = nil
	local _rebirthConn:  RBXScriptConnection? = nil
	local rebirthFrame: Frame

	local function openRebirth()
		if _rebirthOpen then return end
		_rebirthOpen = true
		if _rebirthTween then
			_rebirthTween:Cancel()
		end
		if _rebirthConn then
			_rebirthConn:Disconnect()
			_rebirthConn = nil
		end
		rebirthFrame.Visible = true
		local t = TweenService:Create(rebirthFrame, OPEN_INFO, { Position = PANEL_OPEN_POS })
		_rebirthTween = t
		t:Play()
	end

	local function closeRebirth()
		if not _rebirthOpen then return end
		_rebirthOpen = false
		if _rebirthTween then
			_rebirthTween:Cancel()
		end
		if _rebirthConn then
			_rebirthConn:Disconnect()
			_rebirthConn = nil
		end
		local t = TweenService:Create(rebirthFrame, CLOSE_INFO, { Position = PANEL_CLOSE_POS })
		_rebirthTween = t
		t:Play()
		_rebirthConn = t.Completed:Connect(function()
			_rebirthConn = nil
			if not _rebirthOpen then
				rebirthFrame.Visible = false
			end
		end)
	end

	local function onRebirth()
		task.spawn(function()
			local result = RebirthService:Rebirth()
			if result.success and result.newRebirths then
				rebirths:set(result.newRebirths)
			end
		end)
	end

	rebirthFrame = RebirthPanel(scope, {
		Rebirths  = rebirths,
		Speed     = ziplineSpeed,
		OnRebirth = onRebirth,
		OnClose   = closeRebirth,
	})

	-- ── Zipline side button ───────────────────────────────────────────────────
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
		if _panelOpen then
			closePanel()
		else
			openPanel()
		end
	end)

	-- ── Screen GUI ────────────────────────────────────────────────────────────
	local screenGui = scope:New "ScreenGui" {
		Parent = parent,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,

		[Fusion.Children] = {

			-- Top-center stat badges — clicking toggles the upgrade panel
			scope:New "TextButton" {
				Name = "TopStats",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.05),
				Size = UDim2.fromScale(0.2, 0.08),
				BackgroundTransparency = 1,
				Text = "",
				Visible = isInSafeZone,
				[Fusion.OnEvent "Activated"] = function()
					if _panelOpen then
						closePanel()
					else
						openPanel()
					end
				end,
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

			scope:CashDisplay { Cash = cash, Visible = isInSafeZone },
			-- ── Luck label ─────────────────────────────────────────────────────────────────
			scope:New "TextLabel" {
				Name                   = "LuckLabel",
				AnchorPoint            = Vector2.new(0.5, 0),
				Position               = UDim2.fromScale(0.5, 0.04),
				Size                   = UDim2.fromScale(0.35, 0.1),
				BackgroundTransparency = 1,
				Visible                = luckVisible,
				Text                   = luckText,
				TextColor3             = Color3.fromRGB(255, 255, 255),
				FontFace               = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
				TextScaled             = true,
				[Fusion.Children] = {
					scope:New "UIStroke" { Color = Color3.fromRGB(0, 0, 0), Thickness = 4 },
				},
			},

			-- ── Outside-zone bottom buttons ──────────────────────────────────────────

			-- No brainrot: single RETURN button
			scope:New "TextButton" {
				Name             = "ReturnBtn",
				AnchorPoint      = Vector2.new(0.5, 1),
				Position         = UDim2.fromScale(0.5, 0.92),
				Size             = UDim2.fromScale(0.22, 0.07),
				BackgroundColor3 = Color3.fromRGB(200, 40, 40),
				BorderSizePixel  = 0,
				Text             = "RETURN",
				TextColor3       = Color3.fromRGB(255, 255, 255),
				FontFace         = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
				TextScaled       = true,
				Visible          = outsideNoHeld,
				[Fusion.Children] = {
					scope:New "UIStroke" { Color = Color3.fromRGB(255, 100, 100), Thickness = 2 },
				},
				[Fusion.OnEvent "Activated"] = onReturn,
			},

			-- Has brainrot: DROP + RETURN R$49 buttons
			scope:New "Frame" {
				Name             = "HeldBtns",
				AnchorPoint      = Vector2.new(0.5, 1),
				Position         = UDim2.fromScale(0.5, 0.92),
				Size             = UDim2.fromScale(0.38, 0.07),
				BackgroundTransparency = 1,
				BorderSizePixel  = 0,
				Visible          = outsideHasHeld,
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						FillDirection       = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment   = Enum.VerticalAlignment.Center,
						SortOrder           = Enum.SortOrder.LayoutOrder,
						Padding             = UDim.new(0.03, 0),
					},
					scope:New "TextButton" {
						LayoutOrder      = 1,
						Size             = UDim2.fromScale(0.42, 1),
						BackgroundColor3 = Color3.fromRGB(200, 100, 20),
						BorderSizePixel  = 0,
						Text             = "DROP",
						TextColor3       = Color3.fromRGB(255, 255, 255),
						FontFace         = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled       = true,
						[Fusion.Children] = {
							scope:New "UIStroke" { Color = Color3.fromRGB(255, 160, 60), Thickness = 2 },
						},
						[Fusion.OnEvent "Activated"] = onDrop,
					},
					scope:New "TextButton" {
						LayoutOrder      = 2,
						Size             = UDim2.fromScale(0.55, 1),
						BackgroundColor3 = Color3.fromRGB(130, 50, 220),
						BorderSizePixel  = 0,
						Text             = "RETURN  R$49",
						TextColor3       = Color3.fromRGB(255, 255, 255),
						FontFace         = Font.fromName("GothamSSm", Enum.FontWeight.Heavy),
						TextScaled       = true,
						[Fusion.Children] = {
							scope:New "UIStroke" { Color = Color3.fromRGB(180, 100, 255), Thickness = 2 },
						},
					},
				},
			},
			-- ── Zipline duration bar ─────────────────────────────────────────────
			scope:New "Frame" {
				Name            = "ZiplineBarBg",
				AnchorPoint     = Vector2.new(0.5, 1),
				Position        = UDim2.fromScale(0.5, 0.8),
				Size            = UDim2.fromScale(0.36, 0.028),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderSizePixel = 0,
				Visible         = ziplineBarVisible,
				[Fusion.Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
					scope:New "UIStroke" { Color = Color3.fromRGB(60, 60, 60), Thickness = 1.5 },
					scope:New "Frame" {
						Name             = "Fill",
						AnchorPoint      = Vector2.new(0, 0.5),
						Position         = UDim2.fromScale(0, 0.5),
						Size             = ziplineFillSize,
						BackgroundColor3 = ziplineBarColor,
						BorderSizePixel  = 0,
						[Fusion.Children] = {
							scope:New "UICorner" { CornerRadius = UDim.new(1, 0) },
						},
					},
				},
			},

			scope:SideMenu {
				OnIndex = function()
					if _indexOpen then
						closeIndex()
					else
						openIndex()
					end
				end,
				OnBoost = function()
					BoostController:InviteFriends()
				end,
				OnRebirth = function()
					if _rebirthOpen then
						closeRebirth()
					else
						openRebirth()
					end
				end,
			},

			indexFrame,
			rebirthFrame,

			-- Upgrade panel — positioned and shown/hidden via tweens
			panelFrame,
		},
	}

	return screenGui
end
