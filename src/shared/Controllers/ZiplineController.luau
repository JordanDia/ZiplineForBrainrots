local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit   = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local ZiplineSound = SoundService:WaitForChild("Zipline") :: Sound

-- studs/s² — how quickly speed changes when holding W or S
local ACCELERATION = 50

local ZiplineController = Knit.CreateController({ Name = "ZiplineController" })

-- Fires (isMounted: boolean) when the player mounts or dismounts a zipline.
ZiplineController.MountChanged = Signal.new()

-- Readable state for the progress bar UI.
ZiplineController.TimeLeft      = 0
ZiplineController.TotalDuration = 0

-- ── State ─────────────────────────────────────────────────────────────────────
local _mounted       = false
local _speed         = 0   -- current speed along the line (negative = backwards)
local _topSpeed      = 0
local _timeLeft      = 0
local _totalDuration = 0
local _lineDir    = Vector3.zero
local _lineStart  = Vector3.zero
local _lineLength = 0
local _heartbeat: RBXScriptConnection? = nil
local _jumpConn:  RBXScriptConnection? = nil
local _linVel:    LinearVelocity?      = nil
local _linVelAtt: Attachment?          = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Returns -1, 0, or 1 based on W/S keys (keyboard + gamepad + mobile joystick).
local function _getThrottle(humanoid: Humanoid): number
	local fwd = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
	local bwd = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
	if fwd and not bwd then return 1 end
	if bwd and not fwd then return -1 end

	-- Mobile joystick / gamepad: project humanoid move direction onto zipline
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0.1 then
		local dot = moveDir:Dot(_lineDir)
		if dot > 0.2 then return 1 end
		if dot < -0.2 then return -1 end
	end

	return 0
end

local function _dismount()
	if not _mounted then return end
	_mounted = false
	_speed = 0

	if _heartbeat then
		_heartbeat:Disconnect()
		_heartbeat = nil
	end
	if _jumpConn then
		_jumpConn:Disconnect()
		_jumpConn = nil
	end
	if _linVel then
		_linVel:Destroy()
		_linVel = nil
	end
	if _linVelAtt then
		_linVelAtt:Destroy()
		_linVelAtt = nil
	end

	local char = Players.LocalPlayer.Character
	if not char then return end

	local hrp      = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char:FindFirstChild("Humanoid") :: Humanoid?

	if hrp then
		hrp.AssemblyLinearVelocity  = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		humanoid.AutoRotate = true
	end

	ZiplineSound:Stop()
	ZiplineSound.Volume = 0

	ZiplineController.TimeLeft      = 0
	ZiplineController.TotalDuration = 0
	ZiplineController.MountChanged:Fire(false)
end

-- ── Controller ────────────────────────────────────────────────────────────────

function ZiplineController:KnitStart()
	local LocalPlayer    = Players.LocalPlayer
	local ZiplineService = Knit.GetService("ZiplineService")

	LocalPlayer.CharacterRemoving:Connect(_dismount)

	ZiplineService.MountZipline:Connect(function(startPos: Vector3, endPos: Vector3, topSpeed: number, duration: number)
		if _mounted then return end

		local char = LocalPlayer.Character
		if not char then return end
		local hrp      = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = char:FindFirstChild("Humanoid") :: Humanoid?
		if not hrp or not humanoid then return end

		_mounted       = true
		_speed         = 0
		_topSpeed      = topSpeed
		_totalDuration = duration
		_timeLeft      = duration
		_lineStart  = startPos
		_lineDir    = (endPos - startPos).Unit
		_lineLength = (endPos - startPos).Magnitude

		ZiplineController.TotalDuration = duration
		ZiplineController.TimeLeft      = duration
		ZiplineController.MountChanged:Fire(true)

		-- Teleport to the start attachment and face toward the end.
		-- This clears ground contact so the LinearVelocity constraint
		-- isn't fighting floor collision from the first frame.
		hrp.CFrame = CFrame.lookAt(startPos, startPos + _lineDir)
		hrp.AssemblyLinearVelocity  = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		-- HumanoidStateType.Physics hands full control to physics constraints
		-- and works correctly whether the player is grounded or airborne,
		-- unlike PlatformStand which ragdolls the character on the ground.
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.AutoRotate = false

		-- LinearVelocity constraint drives movement and counteracts gravity
		_linVelAtt = Instance.new("Attachment")
		_linVelAtt.Parent = hrp

		_linVel = Instance.new("LinearVelocity")
		_linVel.Attachment0            = _linVelAtt
		_linVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		_linVel.RelativeTo             = Enum.ActuatorRelativeTo.World
		_linVel.VectorVelocity         = Vector3.zero
		_linVel.MaxForce               = math.huge
		_linVel.Parent                 = hrp

		ZiplineSound.Volume = 0
		ZiplineSound.Looped = true
		ZiplineSound:Play()

		_jumpConn = UserInputService.JumpRequest:Connect(_dismount)

		_heartbeat = RunService.Heartbeat:Connect(function(dt: number)
			local c = LocalPlayer.Character
			if not c then
				_dismount()
				return
			end
			local h   = c:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = c:FindFirstChild("Humanoid") :: Humanoid?
			if not h or not hum then
				_dismount()
				return
			end

			-- Duration countdown
			_timeLeft -= dt
			ZiplineController.TimeLeft = math.max(_timeLeft, 0)
			if _timeLeft <= 0 then
				_dismount()
				return
			end

			local throttle = _getThrottle(hum)
			if throttle > 0 then
				_speed = math.min(_speed + ACCELERATION * dt, _topSpeed)
			elseif throttle < 0 then
				_speed = math.max(_speed - ACCELERATION * dt, -_topSpeed)
			end

			if _linVel then
				_linVel.VectorVelocity = _lineDir * _speed
			end

			ZiplineSound.Volume = math.abs(_speed) / _topSpeed

			local progress = (h.Position - _lineStart):Dot(_lineDir)
			if progress >= _lineLength - 1 or progress < -1 then
				_dismount()
			end
		end)
	end)
end

return ZiplineController
