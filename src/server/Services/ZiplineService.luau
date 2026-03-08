local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)


local ZiplineService = Knit.CreateService {
	Name = "ZiplineService",
	Client = {},
}

local SpeedService
local DurationService

function ZiplineService:KnitStart()
	SpeedService    = Knit.GetService("SpeedService")
	DurationService = Knit.GetService("DurationService")

	local ziplinesFolder = Workspace:WaitForChild("Ziplines")
	for _, child in ziplinesFolder:GetChildren() do
		if child:IsA("Model") then
			self:_SetupZipline(child)
		end
	end
end

function ZiplineService:_SetupZipline(ziplineModel: Model)
	
	local startPart = ziplineModel:WaitForChild("ZiplineStart")
	local endPart   = ziplineModel:WaitForChild("ZiplineEnd")
	local startAtt  = startPart:WaitForChild("AttachmentStart")
	local endAtt    = endPart:WaitForChild("AttachmentEnd")

	-- Start → End
	local startPrompt = Instance.new("ProximityPrompt")
	startPrompt.RequiresLineOfSight = false
	startPrompt.ActionText = "Use Zipline"
	startPrompt.ObjectText = "Zipline"
	startPrompt.Parent = startPart
	startPrompt.Triggered:Connect(function(player)
		self:_RideZipline(player, startAtt, endAtt)
	end)

	-- End → Start
	local endPrompt = Instance.new("ProximityPrompt")
	endPrompt.RequiresLineOfSight = false
	endPrompt.ActionText = "Use Zipline"
	endPrompt.ObjectText = "Zipline"
	endPrompt.Parent = endPart
	endPrompt.Triggered:Connect(function(player)
		self:_RideZipline(player, endAtt, startAtt)
	end)
end

function ZiplineService:_RideZipline(player: Player, fromAtt: Attachment, toAtt: Attachment)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	local speed    = SpeedService:GetSpeed(player)
	local duration = DurationService:GetDuration(player)

	local playerAtt = Instance.new("Attachment")
	playerAtt.Parent = hrp

	local direction = (toAtt.WorldPosition - fromAtt.WorldPosition).Unit
	local lookCFrame = CFrame.lookAt(Vector3.zero, direction)

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = playerAtt
	alignOrientation.CFrame = lookCFrame
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 200
	alignOrientation.Parent = hrp

	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = playerAtt
	align.Position = toAtt.WorldPosition
	align.MaxForce = math.huge
	align.MaxVelocity = speed
	align.Responsiveness = 200
	align.Parent = hrp

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	task.spawn(function()
		local goal = toAtt.WorldPosition
		local startTime = os.clock()
		while true do
			task.wait(0.1)

			if os.clock() - startTime >= duration then break end

			local dist = (hrp.Position - goal).Magnitude
			if dist < 20 then
				align.MaxVelocity = math.max(10, speed * (dist / 20))
			end
			if dist < 3 then break end
		end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		align:Destroy()
		alignOrientation:Destroy()
		playerAtt:Destroy()
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end)
end

return ZiplineService
