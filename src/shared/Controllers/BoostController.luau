local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BoostController = Knit.CreateController({ Name = "BoostController" })

function BoostController:InviteFriends()
	pcall(function()
		SocialService:PromptGameInvite(Players.LocalPlayer)
	end)
end

return BoostController
