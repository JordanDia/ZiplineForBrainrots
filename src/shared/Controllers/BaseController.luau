local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BaseController = Knit.CreateController({ Name = "BaseController" })

BaseController._StandPrompts = {} :: { [Instance]: ProximityPrompt }

function BaseController:KnitStart()
	local player = Players.LocalPlayer
	local BaseService = Knit.GetService("BaseService")
	local BrainrotService = Knit.GetService("BrainrotService")

	-- Get our assigned base folder
	local baseName = BaseService:GetBase()
	if not baseName then
		warn("[BaseController] No base assigned to this player")
		return
	end

	local baseFolder = Workspace:WaitForChild("Bases"):WaitForChild(baseName)
	local standsFolder = baseFolder:WaitForChild("Stands")

	local function onCharacterAdded(character: Model)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child:GetAttribute("BrainrotName") then
				self:_ShowStandPrompts(standsFolder, child, BrainrotService)
			end
		end)

		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child:GetAttribute("BrainrotName") then
				self:_HideStandPrompts()
			end
		end)
	end

	local character = player.Character or player.CharacterAdded:Wait()
	onCharacterAdded(character)
	player.CharacterAdded:Connect(onCharacterAdded)
end

function BaseController:_ShowStandPrompts(standsFolder: Folder, tool: Tool, BrainrotService)
	self:_HideStandPrompts()

	local brainrotName = tool:GetAttribute("BrainrotName")

	for _, stand in standsFolder:GetChildren() do
		if stand:GetAttribute("Occupied") then continue end

		local center = stand:FindFirstChild("Center")
		if not center then continue end

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Stand"
		prompt.ActionText = "Place " .. brainrotName
		prompt.RequiresLineOfSight = false
		prompt.Parent = center

		prompt.Triggered:Connect(function()
			self:_HideStandPrompts()
			BrainrotService:PlaceBrainrot(stand)
		end)

		self._StandPrompts[stand] = prompt
	end
end

function BaseController:_HideStandPrompts()
	for _, prompt in self._StandPrompts do
		prompt:Destroy()
	end
	table.clear(self._StandPrompts)
end

return BaseController
