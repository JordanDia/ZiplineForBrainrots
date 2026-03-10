local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit   = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RebirthController = Knit.CreateController({ Name = "RebirthController" })

-- Current rebirth count for the local player.
RebirthController.Rebirths = 0

-- Fires (newRebirths: number, cashMultiplier: number) when a rebirth completes.
RebirthController.RebirthCompleted = Signal.new()

function RebirthController:KnitStart()
	local RebirthService = Knit.GetService("RebirthService")

	task.spawn(function()
		self.Rebirths = RebirthService:GetRebirths()
	end)

	RebirthService.RebirthCompleted:Connect(function(newRebirths: number, cashMultiplier: number)
		self.Rebirths = newRebirths
		self.RebirthCompleted:Fire(newRebirths, cashMultiplier)
	end)
end

return RebirthController
