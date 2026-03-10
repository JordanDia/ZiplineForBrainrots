local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BOOST_PER_FRIEND = 0.05

local BoostService = Knit.CreateService({
	Name = "BoostService",
	_FriendCounts = {} :: { [Player]: number },
	Client = {},
})

-- Recalculates friend counts when a player joins or leaves.
function BoostService:_UpdateFriendCounts(changedPlayer: Player, joining: boolean)
	if joining then
		self._FriendCounts[changedPlayer] = self._FriendCounts[changedPlayer] or 0
	end

	for _, other in Players:GetPlayers() do
		if other == changedPlayer then continue end

		local areFriends = false
		local ok, result = pcall(function()
			return changedPlayer:IsFriendsWithAsync(other.UserId)
		end)
		if ok then
			areFriends = result
		end

		if areFriends then
			if joining then
				self._FriendCounts[changedPlayer] = (self._FriendCounts[changedPlayer] or 0) + 1
				self._FriendCounts[other]         = (self._FriendCounts[other] or 0) + 1
			else
				self._FriendCounts[other] = math.max(0, (self._FriendCounts[other] or 0) - 1)
			end
		end
	end
end

function BoostService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_UpdateFriendCounts(player, true)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_UpdateFriendCounts(player, false)
		self._FriendCounts[player] = nil
	end)

	-- Handle players already in-server when this runs
	for _, player in Players:GetPlayers() do
		self:_UpdateFriendCounts(player, true)
	end
end

-- Returns the cash multiplier for this player (1 + friends * 5%).
function BoostService:GetMultiplier(player: Player): number
	local friends = self._FriendCounts[player] or 0
	return 1 + friends * BOOST_PER_FRIEND
end

-- Lets the client query how many friends are boosting them.
function BoostService.Client:GetFriendCount(player: Player): number
	return self.Server._FriendCounts[player] or 0
end

return BoostService
