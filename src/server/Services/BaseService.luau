local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

local scope = Fusion.scoped(Fusion)

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(55,  185,  55),
	Rare      = Color3.fromRGB(40,  120, 255),
	Epic      = Color3.fromRGB(160,  32, 240),
	Legendary = Color3.fromRGB(255, 215,   0),
	Mythic    = Color3.fromRGB(220,  40,  40),
}


local BasesFolder = Workspace:WaitForChild("Bases")

local CurrencyService

local BaseService = Knit.CreateService({
	Name = "BaseService",
	Client = {},

	_PlayerBases = {} :: { [Player]: Folder },
	_BaseOwners  = {} :: { [Folder]: Player },

	-- Populated directly by BrainrotService when a brainrot is placed/removed.
	-- [stand] -> { Rate, Stored, LastUpdate, DisplayLabel?, CollectConn? }
	Generators = {} :: { [Instance]: any },
})

function BaseService:KnitInit()
	CurrencyService = Knit.GetService("CurrencyService")
end

-- ────────────────────────────────────────────────────────────────────────────
-- Player / base assignment
-- ────────────────────────────────────────────────────────────────────────────

function BaseService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_AssignBase(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_ReleaseBase(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_AssignBase(player)
	end

	self:_StartGenerators()
end

function BaseService:_AssignBase(player: Player)
	local bases = BasesFolder:GetChildren()

	local freeBase: Folder? = nil
	for _, base in bases do
		if not self._BaseOwners[base] then
			freeBase = base
			break
		end
	end

	if not freeBase then
		warn(`[BaseService] No free base available for {player.Name}`)
		return
	end

	self._PlayerBases[player] = freeBase
	self._BaseOwners[freeBase] = player

	player.CharacterAdded:Connect(function(character)
		self:_SpawnAtBase(character, freeBase)
	end)

	if player.Character then
		self:_SpawnAtBase(player.Character, freeBase)
	end

	print(`[BaseService] Assigned base "{freeBase.Name}" to {player.Name}`)
end

function BaseService:_SpawnAtBase(character: Model, base: Folder)
	local spawnPart = base:FindFirstChild("Spawn")
	if not spawnPart then
		warn(`[BaseService] No Spawn part found in base "{base.Name}"`)
		return
	end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end

	humanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
end

function BaseService:_ReleaseBase(player: Player)
	local base = self._PlayerBases[player]
	if base then
		self._BaseOwners[base] = nil
		self._PlayerBases[player] = nil
		print(`[BaseService] Released base "{base.Name}" from {player.Name}`)
	end
end

function BaseService:GetBase(player: Player): Folder?
	return self._PlayerBases[player]
end

function BaseService.Client:GetBase(player: Player): string?
	local base = self.Server:GetBase(player)
	return if base then base.Name else nil
end

-- ────────────────────────────────────────────────────────────────────────────
-- Generator system
-- Generators[stand] is set directly by BrainrotService on place/pickup.
-- The Heartbeat loop handles display updates and lazily wires up the
-- EarningDisplay SurfaceGui + Touched collection the first time it sees a stand.
-- ────────────────────────────────────────────────────────────────────────────

-- Called by BrainrotService when a brainrot is picked up.
-- Cleans up the SurfaceGui and Touched connection, then removes the entry.
function BaseService:RemoveGenerator(stand: Instance)
	local genData = self.Generators[stand]
	if not genData then return end

	if genData.CollectConn then
		genData.CollectConn:Disconnect()
	end

	if genData.BillboardGui and genData.BillboardGui.Parent then
		genData.BillboardGui:Destroy()
	end

	local earningsDisplay = stand:FindFirstChild("EarningsDisplay")
	if earningsDisplay then
		local sg = earningsDisplay:FindFirstChild("EarningGui")
		if sg then
			sg:Destroy()
		end
	end

	self.Generators[stand] = nil
end

function BaseService:_StartGenerators()
	RunService.Heartbeat:Connect(function()
		for stand, genData in self.Generators do
			if not stand.Parent then
				-- Stand removed from world; clean up
				if genData.CollectConn then
					genData.CollectConn:Disconnect()
				end
				self.Generators[stand] = nil
				continue
			end
			
			
			-- Lazy first-time setup of BillboardGui + EarningsDisplay SurfaceGui + Touched
			if not genData.CollectConn then
				-- Above-head BillboardGui
				local model = stand:FindFirstChildWhichIsA("Model")
				if model and not genData.BillboardGui then
					local brainrotName = model:GetAttribute("BrainrotName") or "Unknown"
					local rarity = model:GetAttribute("Rarity") or "Common"
					local rarityColor = RARITY_COLORS[rarity] or RARITY_COLORS.Common
					local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")

					if rootPart then
						genData.BillboardGui = scope:New "BillboardGui" {
							Size = UDim2.fromScale(8, 8),
							StudsOffset = Vector3.new(0, 9, 0),
							AlwaysOnTop = false,
							LightInfluence = 0,
							MaxDistance = 80,
							Parent = rootPart,
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
										scope:New "TextLabel" {
											LayoutOrder = 1,
											Size = UDim2.fromScale(1, 0.18),
											BackgroundTransparency = 1,
											Text = "LEVEL 1",
											TextColor3 = Color3.fromRGB(0, 200, 255),
											FontFace = Font.fromName("FredokaOne"),
											TextScaled = true,
											TextStrokeTransparency = 0,
											TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
										},
										scope:New "TextLabel" {
											LayoutOrder = 2,
											Size = UDim2.fromScale(1, 0.35),
											BackgroundTransparency = 1,
											Text = "$" .. FormatNumber(genData.Rate) .. "/s",
											TextColor3 = Color3.fromRGB(255, 220, 40),
											FontFace = Font.fromName("FredokaOne"),
											TextScaled = true,
											TextStrokeTransparency = 0,
											TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
										},
										scope:New "TextLabel" {
											LayoutOrder = 3,
											Size = UDim2.fromScale(1, 0.30),
											BackgroundTransparency = 1,
											Text = string.upper(brainrotName),
											TextColor3 = Color3.fromRGB(255, 255, 255),
											FontFace = Font.fromName("FredokaOne"),
											TextScaled = true,
											TextStrokeTransparency = 0,
											TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
										},
										scope:New "TextLabel" {
											LayoutOrder = 4,
											Size = UDim2.fromScale(1, 0.17),
											BackgroundTransparency = 1,
											Text = string.upper(rarity),
											TextColor3 = rarityColor,
											FontFace = Font.fromName("FredokaOne"),
											TextScaled = true,
											TextStrokeTransparency = 0,
											TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
										},
									},
								},
							},
						}
					end
				end

				local earningsDisplay = stand:FindFirstChild("EarningsDisplay") :: BasePart?
				if earningsDisplay then
					local label = scope:New "TextLabel" {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "$0",
						FontFace = Font.fromName("FredokaOne"),
						TextScaled = true,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextStrokeTransparency = 0,
						TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
						Parent = scope:New "SurfaceGui" {
							Name = "EarningGui",
							Face = Enum.NormalId.Top,
							LightInfluence = 0,
							AlwaysOnTop = true,
							Parent = earningsDisplay,
						},
					}

					genData.DisplayLabel = label

					genData.CollectConn = earningsDisplay.Touched:Connect(function(hit)
						local character = hit.Parent
						local player = Players:GetPlayerFromCharacter(character)
						if not player then return end

						local baseFolder = stand.Parent and stand.Parent.Parent
						if not baseFolder or self._BaseOwners[baseFolder] ~= player then return end

						local collected = math.floor(genData.Stored)
						if collected <= 0 then return end

						genData.Stored -= collected
						CurrencyService:AddCash(player, collected)
					end)

					print("Setup earnings display")
				end
			end

			-- Accumulate cash
			local now = os.clock()
			local elapsed = now - genData.LastUpdate
			genData.LastUpdate = now
			genData.Stored += genData.Rate * elapsed

			-- Update EarningsDisplay label
			if genData.DisplayLabel and genData.DisplayLabel.Parent then
				genData.DisplayLabel.Text = "$" .. FormatNumber(math.floor(genData.Stored))
			end
		end
	end)
end

return BaseService
