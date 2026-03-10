local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

local Knit   = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CHECK_INTERVAL = 0.15

-- Returns true if `pos` is within the XZ footprint of `part` and within
-- `yTopBuffer` studs above its top surface.
local function _inPartRegion(pos: Vector3, part: BasePart, yTopBuffer: number): boolean
	local localPos = part.CFrame:PointToObjectSpace(pos)
	local half     = part.Size * 0.5
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Z) <= half.Z
		and localPos.Y > -(half.Y + 1)
		and localPos.Y < half.Y + yTopBuffer
end

-- ── Controller ────────────────────────────────────────────────────────────────

local ZoneController = Knit.CreateController({ Name = "ZoneController" })

ZoneController.IsInSafeZone  = true  -- assume safe on first frame
ZoneController.LuckMultiplier = 0    -- 0 = not standing on any luck platform
ZoneController.HeldBrainrot  = nil   -- string? name of currently hovering brainrot

ZoneController.SafeZoneChanged = Signal.new()  -- fires (inSafe: boolean)
ZoneController.LuckChanged     = Signal.new()  -- fires (multiplier: number)
ZoneController.HeldChanged     = Signal.new()  -- fires (name: string?)

function ZoneController:KnitStart()
	local BrainrotService = Knit.GetService("BrainrotService")

	-- Mirror held-brainrot state from the server signal.
	BrainrotService.BrainrotHeld:Connect(function(name: string?)
		if self.HeldBrainrot ~= name then
			self.HeldBrainrot = name
			self.HeldChanged:Fire(name)
		end
	end)

	-- Find SafeZone part (already used server-side as well).
	local safeZonePart = Workspace:WaitForChild("SafeZone", 10) :: BasePart?
	if not safeZonePart then
		warn("[ZoneController] workspace.SafeZone not found — safe-zone detection disabled")
	end

	-- Collect all Luck{N} platforms present at startup.
	-- Structure: workspace.Luck5  → .Platform (BasePart)
	local luckPlatforms: { { Part: BasePart, Mult: number } } = {}
	for _, obj in Workspace:GetChildren() do
		local mult = tonumber(obj.Name:match("^Luck(%d+)$"))
		if not mult then continue end
		local platform = obj:FindFirstChild("Platform")
		if platform and platform:IsA("BasePart") then
			table.insert(luckPlatforms, { Part = platform :: BasePart, Mult = mult })
		end
	end

	-- Heartbeat polling loop
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then return end
		elapsed = 0

		local char = Players.LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end
		local pos = hrp.Position

		-- Safe zone check
		if safeZonePart then
			local inSafe = _inPartRegion(pos, safeZonePart, 40)
			if inSafe ~= self.IsInSafeZone then
				self.IsInSafeZone = inSafe
				self.SafeZoneChanged:Fire(inSafe)
			end
		end

		-- Luck platform check
		local newLuck = 0
		for _, entry in luckPlatforms do
			if _inPartRegion(pos, entry.Part, 30) then
				newLuck = entry.Mult
				break
			end
		end
		if newLuck ~= self.LuckMultiplier then
			self.LuckMultiplier = newLuck
			self.LuckChanged:Fire(newLuck)
		end
	end)
end

return ZoneController
