local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))

local RootUI = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("RootUI"))
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

Knit.AddControllersDeep(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Controllers"))

Knit.Start({ServicePromises = false}):catch(warn):await()

RootUI(PlayerGui)