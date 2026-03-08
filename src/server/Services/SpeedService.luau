local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BASE_SPEED     = 20
local UPGRADE_AMOUNT = 5

local DataService

local SpeedService = Knit.CreateService({
	Name = "SpeedService",
	Client = {},

	_Speeds = {} :: { [Player]: number },
})

function SpeedService:KnitInit()
	DataService = Knit.GetService("DataService")
end

function SpeedService:KnitStart()
	DataService.ProfileLoaded:Connect(function(player: Player, profile)
		self._Speeds[player] = profile.Data.ZiplineSpeed
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._Speeds[player] = nil
	end)
end

function SpeedService:GetSpeed(player: Player): number
	return self._Speeds[player] or BASE_SPEED
end

function SpeedService:Upgrade(player: Player)
	local data = DataService:GetData(player)
	if not data then return end
	data.ZiplineSpeed += UPGRADE_AMOUNT
	self._Speeds[player] = data.ZiplineSpeed
end

function SpeedService.Client:GetSpeed(player: Player): number
	return self.Server:GetSpeed(player)
end

function SpeedService.Client:Upgrade(player: Player): number
	self.Server:Upgrade(player)
	return self.Server:GetSpeed(player)
end

return SpeedService
