local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BASE_DURATION  = 5
local UPGRADE_AMOUNT = 2

local DataService

local DurationService = Knit.CreateService({
	Name = "DurationService",
	Client = {},

	_Durations = {} :: { [Player]: number },
})

function DurationService:KnitInit()
	DataService = Knit.GetService("DataService")
end

function DurationService:KnitStart()
	DataService.ProfileLoaded:Connect(function(player: Player, profile)
		self._Durations[player] = profile.Data.ZiplineDuration
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._Durations[player] = nil
	end)
end

function DurationService:GetDuration(player: Player): number
	return self._Durations[player] or BASE_DURATION
end

function DurationService:Upgrade(player: Player)
	local data = DataService:GetData(player)
	if not data then return end
	data.ZiplineDuration += UPGRADE_AMOUNT
	self._Durations[player] = data.ZiplineDuration
end

function DurationService.Client:GetDuration(player: Player): number
	return self.Server:GetDuration(player)
end

function DurationService.Client:Upgrade(player: Player): number
	self.Server:Upgrade(player)
	return self.Server:GetDuration(player)
end

return DurationService
