local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit   = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local IndexController = Knit.CreateController({ Name = "IndexController" })

-- Current set of unlocked brainrot names for the local player.
IndexController.Unlocked = {} :: { [string]: boolean }

-- Fires (name: string) locally whenever a new brainrot is unlocked.
IndexController.BrainrotUnlocked = Signal.new()

function IndexController:KnitStart()
	local IndexService = Knit.GetService("IndexService")

	-- Fetch the player's current unlocked set from the server.
	task.spawn(function()
		self.Unlocked = IndexService:GetUnlocked()
	end)

	-- Keep in sync as new brainrots are unlocked during the session.
	IndexService.BrainrotUnlocked:Connect(function(name: string)
		self.Unlocked[name] = true
		self.BrainrotUnlocked:Fire(name)
	end)
end

return IndexController
