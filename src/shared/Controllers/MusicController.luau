local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SafeZone     = Workspace:WaitForChild("SafeZone") :: BasePart
local TrackSafe    = SoundService:WaitForChild("Relaxed Scene") :: Sound
local TrackOutside = SoundService:WaitForChild("No More")       :: Sound

local FADE_TIME   = 1.5  -- seconds to cross-fade between tracks
local CHECK_RATE  = 0.25 -- seconds between zone checks

local MusicController = Knit.CreateController({ Name = "MusicController" })

local _inSafeZone: boolean? = nil  -- nil = not yet determined
local _fadeGen = 0  -- incremented on every crossfade to invalidate stale callbacks

local function _isInsideSafeZone(position: Vector3): boolean
	local localPos = SafeZone.CFrame:PointToObjectSpace(position)
	local half = SafeZone.Size * 0.5
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

local function _crossfadeTo(incoming: Sound, outgoing: Sound)
	_fadeGen += 1
	local gen = _fadeGen

	-- Bring incoming up
	if not incoming.IsPlaying then
		incoming.Volume = 0
		incoming.Looped = true
		incoming:Play()
	end
	TweenService:Create(incoming, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine), { Volume = 1 }):Play()

	-- Bring outgoing down, then stop — but only if no newer crossfade has
	-- started since, otherwise the :Stop() would kill the wrong track.
	local fadeOut = TweenService:Create(outgoing, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine), { Volume = 0 })
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		if _fadeGen == gen then
			outgoing:Stop()
		end
	end)
end

function MusicController:KnitStart()
	local LocalPlayer = Players.LocalPlayer

	-- Start with Relaxed Scene — the correct default for players who spawn
	-- in the safe zone. The first zone check will instantly correct it if
	-- they happen to spawn outside, with no crossfade delay.
	TrackSafe.Looped = true
	TrackSafe.Volume = 1
	TrackSafe:Play()

	local function applyInitialTrack()
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if not hrp then return end

		local inside = _isInsideSafeZone(hrp.Position)
		_inSafeZone = inside
		if not inside then
			-- Correct without a fade so there is no audible blip
			TrackSafe:Stop()
			TrackSafe.Volume = 0
			TrackOutside.Volume = 1
			TrackOutside.Looped = true
			TrackOutside:Play()
		end
	end
	task.spawn(applyInitialTrack)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < CHECK_RATE then return end
		elapsed = 0

		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		local inside = _isInsideSafeZone(hrp.Position)
		if inside == _inSafeZone then return end
		_inSafeZone = inside

		if inside then
			_crossfadeTo(TrackSafe, TrackOutside)
		else
			_crossfadeTo(TrackOutside, TrackSafe)
		end
	end)
end

return MusicController
