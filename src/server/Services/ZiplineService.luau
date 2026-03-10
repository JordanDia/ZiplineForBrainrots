local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SpeedService
local DurationService

local ZiplineService = Knit.CreateService {
	Name = "ZiplineService",

	Client = {
		-- Fires to the client when they trigger a zipline prompt.
		-- Args: startPos: Vector3, endPos: Vector3, topSpeed: number, duration: number
		MountZipline = Knit.CreateSignal(),
	},
}

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

	local startPrompt = Instance.new("ProximityPrompt")
	startPrompt.RequiresLineOfSight = false
	startPrompt.ActionText = "Use Zipline"
	startPrompt.ObjectText = "Zipline"
	startPrompt.Parent = startPart
	startPrompt.Triggered:Connect(function(player)
		local speed    = SpeedService:GetSpeed(player)
		local duration = DurationService:GetDuration(player)
		self.Client.MountZipline:Fire(player, startAtt.WorldPosition, endAtt.WorldPosition, speed, duration)
	end)

	local endPrompt = Instance.new("ProximityPrompt")
	endPrompt.RequiresLineOfSight = false
	endPrompt.ActionText = "Use Zipline"
	endPrompt.ObjectText = "Zipline"
	endPrompt.Parent = endPart
	endPrompt.Triggered:Connect(function(player)
		local speed    = SpeedService:GetSpeed(player)
		local duration = DurationService:GetDuration(player)
		self.Client.MountZipline:Fire(player, endAtt.WorldPosition, startAtt.WorldPosition, speed, duration)
	end)
end

return ZiplineService
