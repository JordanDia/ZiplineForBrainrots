local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local REBIRTH_START_SPEED = 50
local REBIRTH_SPEED_INC   = 40
local RESET_CASH          = 500

local DataService
local CurrencyService
local SpeedService

local RebirthService = Knit.CreateService({
	Name = "RebirthService",
	Client = {
		-- Fires (newRebirths: number, cashMultiplier: number) to the rebirthing player.
		RebirthCompleted = Knit.CreateSignal(),
	},
})

function RebirthService:KnitStart()
	DataService    = Knit.GetService("DataService")
	CurrencyService = Knit.GetService("CurrencyService")
	SpeedService   = Knit.GetService("SpeedService")
end

function RebirthService:GetRebirths(player: Player): number
	local data = DataService:GetData(player)
	if not data then return 0 end
	return data.Rebirths or 0
end

-- Speed required for the player's next rebirth.
function RebirthService:GetRequiredSpeed(player: Player): number
	local rebirths = self:GetRebirths(player)
	return REBIRTH_START_SPEED + rebirths * REBIRTH_SPEED_INC
end

-- Cash multiplier the player currently has. (1 + rebirths * 0.5)
function RebirthService:GetCashMultiplier(player: Player): number
	local rebirths = self:GetRebirths(player)
	return 1 + rebirths * 0.5
end

-- Attempt a rebirth. Returns { success: boolean, message: string, newRebirths: number? }
function RebirthService:Rebirth(player: Player): { success: boolean, message: string, newRebirths: number? }
	local data = DataService:GetData(player)
	if not data then
		return { success = false, message = "Data not loaded." }
	end

	local currentSpeed   = data.ZiplineSpeed or 20
	local requiredSpeed  = self:GetRequiredSpeed(player)

	if currentSpeed < requiredSpeed then
		return {
			success = false,
			message = "Need " .. (requiredSpeed - currentSpeed) .. " more speed.",
		}
	end

	-- Perform rebirth
	data.Rebirths = (data.Rebirths or 0) + 1
	CurrencyService:SetCash(player, RESET_CASH)

	local newRebirths = data.Rebirths
	local newMult     = 1 + newRebirths * 0.5

	self.Client.RebirthCompleted:Fire(player, newRebirths, newMult)

	return { success = true, message = "Rebirth successful!", newRebirths = newRebirths }
end

-- ── Client remotes ────────────────────────────────────────────────────────────

function RebirthService.Client:GetRebirths(player: Player): number
	return self.Server:GetRebirths(player)
end

function RebirthService.Client:Rebirth(player: Player): { success: boolean, message: string, newRebirths: number? }
	return self.Server:Rebirth(player)
end

return RebirthService
