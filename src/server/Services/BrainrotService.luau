local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact
local BrainrotConfig = require(ReplicatedStorage.Shared.Configs.BrainrotConfig)

local scope = Fusion.scoped(Fusion)

local BrainrotsFolder = ServerStorage:WaitForChild("Brainrots")
local SafeZone = Workspace:WaitForChild("SafeZone") :: BasePart

local SPAWN_INTERVAL  = 5
local HOVER_HEIGHT    = 7   -- studs above HumanoidRootPart
local DESPAWN_TIME    = 30  -- seconds before uncollected brainrot despawns

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(80,  200, 80),
	Rare      = Color3.fromRGB(60,  130, 255),
	Epic      = Color3.fromRGB(180, 80,  255),
	Legendary = Color3.fromRGB(255, 170, 0),
}

-- ────────────────────────────────────────────────────────────────────────────
-- Luck / rarity weights
-- ────────────────────────────────────────────────────────────────────────────

-- Base weight for each rarity at 1x luck
local RARITY_BASE_WEIGHTS = {
	Common    = 1000,
	Uncommon  = 200,
	Rare      = 50,
	Epic      = 10,
	Legendary = 2,
}

-- How much each rarity benefits from the luck multiplier.
-- weight = base * (luck ^ exponent)
-- Common is unchanged; higher rarities scale more aggressively.
local RARITY_LUCK_EXPONENTS = {
	Common    = 0,
	Uncommon  = 0.5,
	Rare      = 1.0,
	Epic      = 1.5,
	Legendary = 2.0,
}

-- Inserts spaces before uppercase letters that follow lowercase ones.
-- "FrigoCamelo" → "Frigo Camelo", "TalpaDiFerro" → "Talpa Di Ferro"
local function _SplitPascalCase(s: string): string
	return (s:gsub("(%l)(%u)", "%1 %2"))
end

local function _PickConfig(luck: number): any
	local pool = {}
	local totalWeight = 0

	for rarity, configs in BrainrotConfig do
		local base     = RARITY_BASE_WEIGHTS[rarity] or 0
		local exp      = RARITY_LUCK_EXPONENTS[rarity] or 0
		local weight   = base * (luck ^ exp)

		for _, cfg in configs do
			table.insert(pool, { Config = cfg, Weight = weight })
			totalWeight += weight
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in pool do
		cumulative += entry.Weight
		if roll <= cumulative then
			return entry.Config
		end
	end
	return pool[#pool].Config
end

-- ────────────────────────────────────────────────────────────────────────────

local BaseService -- resolved in KnitInit

local BrainrotService = Knit.CreateService({
	Name = "BrainrotService",
	Client = {},

	_HoveringBrainrots = {} :: { [Player]: { Model: Model, Config: any, Weld: Weld } },
})

function BrainrotService:KnitInit()
	BaseService = Knit.GetService("BaseService")
end

-- ────────────────────────────────────────────────────────────────────────────
-- Spawn loop
-- ────────────────────────────────────────────────────────────────────────────

function BrainrotService:KnitStart()
	-- Find all Luck* models in Workspace and start an independent spawn loop for each
	for _, obj in Workspace:GetChildren() do
		local luck = tonumber(obj.Name:match("^Luck(%d+)$"))
		if not luck then continue end
		local platform = obj:FindFirstChild("Platform")
		if not platform or not platform:IsA("BasePart") then continue end

		local p = platform :: BasePart
		task.spawn(function()
			while true do
				task.wait(SPAWN_INTERVAL)
				self:_SpawnBrainrot(p, luck)
			end
		end)
		print(`[BrainrotService] Registered Luck{luck} platform`)
	end

	SafeZone.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local hoverData = self._HoveringBrainrots[player]
		if not hoverData then return end

		self:_ConvertToTool(player, hoverData)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_ClearHover(player, true)
	end)
end

-- Spawns a brainrot on `platform` using `luck` to weight rarity selection.
-- luck = 1   → common platform (no boost)
-- luck = 5   → 5x luck platform (uncommon odds ~2x, rare ~5x, epic ~11x, legendary ~25x)
-- luck = 25  → 25x luck platform, etc.
function BrainrotService:_SpawnBrainrot(platform: BasePart, luck: number)
	local config = _PickConfig(luck)

	local template = BrainrotsFolder:FindFirstChild(config.Name)
	if not template then
		warn(`[BrainrotService] Model not found in ServerStorage.Brainrots: "{config.Name}"`)
		return
	end

	local clone = template:Clone()

	for _, part in clone:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.Anchored = true
		end
	end
	clone:ScaleTo(0.3)
	clone.Parent = Workspace

	local halfX = platform.Size.X * 0.4
	local halfZ = platform.Size.Z * 0.4
	local spawnX = platform.Position.X + (math.random() * 2 - 1) * halfX
	local spawnZ = platform.Position.Z + (math.random() * 2 - 1) * halfZ
	local surfaceY = platform.Position.Y + platform.Size.Y / 2

	clone:MoveTo(CFrame.new(spawnX, surfaceY, spawnZ).Position)
	clone:PivotTo(clone:GetPivot() * CFrame.Angles(0, 0, math.random(0, 360)))

	local promptPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
	if not promptPart then
		warn(`[BrainrotService] "{config.Name}" has no BasePart for ProximityPrompt`)
		return
	end

	-- BillboardGui shown while on ground and while hovering
	local rarityColor = RARITY_COLORS[config.Rarity] or Color3.fromRGB(255, 255, 255)

	local timerLabel = scope:New "TextLabel" {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0.75, 1),
		BackgroundTransparency = 1,
		Text = DESPAWN_TIME .. "s",
		TextColor3 = Color3.fromRGB(255, 60, 60),
		FontFace = Font.fromName("FredokaOne"),
		TextScaled = true,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}

	scope:New "BillboardGui" {
		Size = UDim2.fromScale(8, 8),
		StudsOffset = Vector3.new(0, 10, 0),
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = 80,
		Parent = promptPart,
		[Fusion.Children] = {
			scope:New "Frame" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[Fusion.Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 0),
					},

					-- Name
					scope:New "TextLabel" {
						LayoutOrder = 1,
						Size = UDim2.fromScale(1, 0.30),
						BackgroundTransparency = 1,
						Text = _SplitPascalCase(config.Name),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						FontFace = Font.fromName("FredokaOne"),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					},

					-- Level
					scope:New "TextLabel" {
						LayoutOrder = 2,
						Size = UDim2.fromScale(1, 0.12),
						BackgroundTransparency = 1,
						Text = "Lv.1",
						TextColor3 = Color3.fromRGB(0, 200, 255),
						FontFace = Font.fromName("FredokaOne"),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					},

					-- Rarity
					scope:New "TextLabel" {
						LayoutOrder = 3,
						Size = UDim2.fromScale(1, 0.12),
						BackgroundTransparency = 1,
						Text = config.Rarity,
						TextColor3 = rarityColor,
						FontFace = Font.fromName("FredokaOne"),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					},

					-- Rate
					scope:New "TextLabel" {
						LayoutOrder = 4,
						Size = UDim2.fromScale(1, 0.28),
						BackgroundTransparency = 1,
						Text = "$" .. FormatNumber(config.Rate) .. "/s",
						TextColor3 = Color3.fromRGB(255, 220, 40),
						FontFace = Font.fromName("FredokaOne"),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					},

					-- Timer row: clock icon + countdown
					scope:New "Frame" {
						LayoutOrder = 5,
						Size = UDim2.fromScale(0.5, 0.18),
						BackgroundTransparency = 1,
						[Fusion.Children] = {
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0.04, 0),
							},
							scope:New "ImageLabel" {
								LayoutOrder = 1,
								Size = UDim2.fromScale(0.22, 1),
								BackgroundTransparency = 1,
								Image = "rbxassetid://126340774874320",
								ScaleType = Enum.ScaleType.Fit,
							},
							timerLabel,
						},
					},
				},
			},
		},
	}

	local despawnCancelled = false
	task.spawn(function()
		local timeLeft = DESPAWN_TIME
		while true do
			if timerLabel.Parent then
				timerLabel.Text = timeLeft .. "s"
			end
			if timeLeft <= 0 then
				if not despawnCancelled then
					clone:Destroy()
				end
				return
			end
			task.wait(1)
			timeLeft -= 1
		end
	end)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = config.Name
	prompt.ActionText = "Collect"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		if self._HoveringBrainrots[player] then return end
		despawnCancelled = true
		prompt:Destroy()
		self:_StartHovering(player, clone, config)
	end)

	print(`[BrainrotService] Spawned {config.Rarity} "{config.Name}" at {luck}x luck (rate: {config.Rate}/s)`)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Hover system
-- ────────────────────────────────────────────────────────────────────────────

function BrainrotService:_StartHovering(player: Player, model: Model, config: any)
	if not player.Character then
		model:Destroy()
		return
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		model:Destroy()
		return
	end

	local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not rootPart then
		model:Destroy()
		return
	end

	-- Unanchor, disable collisions, make massless
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	-- Weld all other parts to rootPart so the whole model moves as one unit
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= rootPart then
			local w = Instance.new("WeldConstraint")
			w.Part0 = rootPart
			w.Part1 = part
			w.Parent = rootPart
		end
	end

	-- Weld rootPart to HRP offset HOVER_HEIGHT above
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = rootPart
	weld.C0 = CFrame.new(0, HOVER_HEIGHT, 0)
	weld.Parent = hrp

	self._HoveringBrainrots[player] = { Model = model, Config = config, Weld = weld }

	local charConn
	charConn = player.CharacterRemoving:Connect(function()
		charConn:Disconnect()
		self:_ClearHover(player, true)
	end)
end

function BrainrotService:_ClearHover(player: Player, destroyModel: boolean)
	local hoverData = self._HoveringBrainrots[player]
	if not hoverData then return end

	hoverData.Weld:Destroy()
	self._HoveringBrainrots[player] = nil

	if destroyModel and hoverData.Model and hoverData.Model.Parent then
		hoverData.Model:Destroy()
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Tool helpers
-- ────────────────────────────────────────────────────────────────────────────

-- Wraps an anchored brainrot model into a Tool and gives it to the player.
function BrainrotService:_MakeToolFromModel(model: Model, config: any): Tool
	local tool = Instance.new("Tool")
	tool.Name = config.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.1, 0.1, 0.1)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Anchored = false
	handle.Parent = tool

	local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if rootPart then
		handle.CFrame = rootPart.CFrame

		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.CanCollide = false
			end
		end

		model.Parent = tool

		local rootWeld = Instance.new("WeldConstraint")
		rootWeld.Part0 = handle
		rootWeld.Part1 = rootPart
		rootWeld.Parent = handle

		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") and desc ~= rootPart then
				local w = Instance.new("WeldConstraint")
				w.Part0 = rootPart
				w.Part1 = desc
				w.Parent = rootPart
			end
		end
	else
		model.Parent = tool
	end

	tool.GripPos = Vector3.new(0, 2, 0)
	tool:SetAttribute("BrainrotName", config.Name)
	tool:SetAttribute("Rate", config.Rate)
	tool:SetAttribute("Rarity", config.Rarity)

	return tool
end

function BrainrotService:_ConvertToTool(player: Player, hoverData: any)
	self:_ClearHover(player, false)
	local tool = self:_MakeToolFromModel(hoverData.Model, hoverData.Config)
	tool.Parent = player.Backpack
	print(`[BrainrotService] {player.Name} received {hoverData.Config.Name} as a tool`)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Base placement (client → server)
-- ────────────────────────────────────────────────────────────────────────────

function BrainrotService.Client:PlaceBrainrot(player: Player, stand: Instance)
	-- Validate stand belongs to this player's base
	local playerBase = BaseService:GetBase(player)
	if not playerBase then return end
	local standsFolder = stand.Parent
	if not standsFolder or standsFolder.Parent ~= playerBase then
		warn(`[BrainrotService] {player.Name} tried to place on a stand outside their base`)
		return
	end
	if stand:GetAttribute("Occupied") then return end

	-- Find the equipped brainrot tool
	local character = player.Character
	if not character then return end

	local tool: Tool? = nil
	for _, item in character:GetChildren() do
		if item:IsA("Tool") and item:GetAttribute("BrainrotName") then
			tool = item :: Tool
			break
		end
	end
	if not tool then return end

	local config = {
		Name = tool:GetAttribute("BrainrotName"),
		Rate = tool:GetAttribute("Rate"),
		Rarity = tool:GetAttribute("Rarity"),
	}

	-- Pull the model out of the tool before destroying it
	local model = tool:FindFirstChildWhichIsA("Model")
	if not model then return end

	model.Parent = Workspace
	tool:Destroy()

	-- Re-anchor and remove old tool welds
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
		end
		if desc:IsA("WeldConstraint") or desc:IsA("BillboardGui") then
			desc:Destroy()
		end
	end

	-- Place 3 studs above stand.Center
	local center = stand:FindFirstChild("Center") :: BasePart
	if not center then
		warn(`[BrainrotService] Stand "{stand.Name}" has no Center part`)
		model:Destroy()
		return
	end

	local placementPos = center.Position + Vector3.new(0, 3, 0)
	local earningsDisplay = stand:FindFirstChild("EarningsDisplay") :: BasePart?
	local placementCF
	if earningsDisplay then
		local dir = earningsDisplay.Position - placementPos
		local lookDir = Vector3.new(dir.X, 0, dir.Z)
		if lookDir.Magnitude > 0.1 then
			placementCF = CFrame.new(placementPos, placementPos + lookDir)
		else
			placementCF = CFrame.new(placementPos)
		end
	else
		placementCF = CFrame.new(placementPos)
	end
	model:PivotTo(placementCF)
	model.Parent = stand
	model:SetAttribute("BrainrotName", config.Name)
	model:SetAttribute("Rate", config.Rate)
	model:SetAttribute("Rarity", config.Rarity)

	stand:SetAttribute("Occupied", true)
	BaseService.Generators[stand] = {
		Rate       = config.Rate,
		Stored     = 0,
		LastUpdate = os.clock(),
	}

	-- Pick Up prompt on the placed model
	local promptPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if promptPart then
		local pickupPrompt = Instance.new("ProximityPrompt")
		pickupPrompt.ObjectText = config.Name
		pickupPrompt.ActionText = "Pick Up"
		pickupPrompt.RequiresLineOfSight = false
		pickupPrompt.Parent = promptPart

		pickupPrompt.Triggered:Connect(function(trigPlayer)
			-- Only the base owner can pick up
			if BaseService:GetBase(trigPlayer) ~= playerBase then return end

			pickupPrompt:Destroy()
			stand:SetAttribute("Occupied", false)
			BaseService:RemoveGenerator(stand)

			model.Parent = Workspace
			local pickupTool = self.Server:_MakeToolFromModel(model, config)
			pickupTool.Parent = trigPlayer.Backpack
			print(`[BrainrotService] {trigPlayer.Name} picked up {config.Name}`)
		end)
	end

	print(`[BrainrotService] {player.Name} placed {config.Name} on {stand.Name}`)
end

return BrainrotService
