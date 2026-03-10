local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local FormatNumber = require(ReplicatedStorage.Packages.FormatNumber).Simple.FormatCompact

local DataService

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",

	-- Fires (player: Player, newCash: number) whenever cash changes
	CashChanged = Signal.new(),


	Client = {

		CashChanged = Knit.CreateSignal()
	},

})

function CurrencyService:KnitStart()
	DataService = Knit.GetService("DataService")

	self.CashChanged:Connect(function(player: Player, newCash: number)
		self.Client.CashChanged:Fire(player, newCash)
	end)

end

function CurrencyService:GetCash(player: Player): number
	local data = DataService:GetData(player)
	if not data then return 0 end
	return data.Cash
end

function CurrencyService:AddCash(player: Player, amount: number)
	local data = DataService:GetData(player)
	if not data then return end
	data.Cash += amount
	self.CashChanged:Fire(player, data.Cash)
end

function CurrencyService:SetCash(player: Player, amount: number)
	local data = DataService:GetData(player)
	if not data then return end
	data.Cash = amount
	self.CashChanged:Fire(player, data.Cash)
end

-- Returns false if the player can't afford it; true and deducts on success.
function CurrencyService:RemoveCash(player: Player, amount: number): boolean
	local data = DataService:GetData(player)
	if not data then return false end
	if data.Cash < amount then return false end
	data.Cash -= amount
	self.CashChanged:Fire(player, data.Cash)
	return true
end

function CurrencyService:FormatCurrency(amount: number): string
	return FormatNumber(amount)
end

-- Client functions

function CurrencyService.Client:GetCash(player: Player): number
	return self.Server:GetCash(player)
end

function CurrencyService.Client:AddCash(player: Player, amount: number)
	self.Server:AddCash(player, amount)
end

function CurrencyService.Client:RemoveCash(player: Player, amount: number): boolean
	return self.Server:RemoveCash(player, amount)
end

return CurrencyService
