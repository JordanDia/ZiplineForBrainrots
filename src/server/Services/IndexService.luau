local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BrainrotsFolder = ServerStorage:WaitForChild("Brainrots")

local IndexService = Knit.CreateService({
	Name   = "IndexService",
	Client = {
		-- Fires (name: string) to the specific client when they unlock a new brainrot.
		BrainrotUnlocked = Knit.CreateSignal(),
	},
})

local DataService

function IndexService:KnitStart()
	DataService = Knit.GetService("DataService")

	-- Mirror every brainrot model into ReplicatedStorage so the client can
	-- clone them into ViewportFrames without needing server access.
	local dest = Instance.new("Folder")
	dest.Name   = "Brainrots"
	dest.Parent = ReplicatedStorage

	for _, model in BrainrotsFolder:GetChildren() do
		model:Clone().Parent = dest
	end
end

-- ── Public API ─────────────────────────────────────────────────────────────

-- Called by BrainrotService when a player first picks up a brainrot.
function IndexService:UnlockBrainrot(player: Player, name: string)
	local profile = DataService:GetProfile(player)
	if not profile then return end

	local unlocked = profile.Data.UnlockedBrainrots
	if unlocked[name] then return end -- already discovered

	unlocked[name] = true
	self.Client.BrainrotUnlocked:Fire(player, name)
end

function IndexService:GetUnlocked(player: Player): { [string]: boolean }
	local profile = DataService:GetProfile(player)
	if not profile then return {} end
	return profile.Data.UnlockedBrainrots
end

function IndexService.Client:GetUnlocked(player: Player): { [string]: boolean }
	return self.Server:GetUnlocked(player)
end

return IndexService
