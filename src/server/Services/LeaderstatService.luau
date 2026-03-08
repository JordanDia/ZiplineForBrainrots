local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService
local CurrencyService

local LeaderstatService = Knit.CreateService({
	Name = "LeaderstatService",
	Client = {},
})

function LeaderstatService:KnitInit()
	DataService = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")
end

function LeaderstatService:KnitStart()
	-- Build leaderstats when a profile finishes loading
	DataService.ProfileLoaded:Connect(function(player: Player, profile)
		self:_SetupLeaderstats(player, profile.Data)
	end)

	-- Keep the Cash leaderstat in sync whenever cash changes
	CurrencyService.CashChanged:Connect(function(player: Player, newCash: number)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
		local cashVal = leaderstats:FindFirstChild("Cash")
		if cashVal then
			cashVal.Value = newCash
		end
	end)
end

function LeaderstatService:_SetupLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashVal = Instance.new("NumberValue")
	cashVal.Name = "Cash"
	cashVal.Value = data.Cash
	cashVal.Parent = leaderstats
end

return LeaderstatService
