--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaycastHelper = require(ReplicatedStorage.Packages.RaycastHelper)

local function getMouseRay(): Ray
	local mousePos = UserInputService:GetMouseLocation()
	return workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
end

local function ignoreCharactersFilter(result: RaycastResult, _cancel: () -> ())
	local hit = result.Instance :: BasePart
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and hit:IsDescendantOf(character) then
			return false
		end
	end
	return true
end

local function ignoreTransparencyFilter(result: RaycastResult, _cancel: () -> ())
	local hit = result.Instance :: BasePart
	return hit.Transparency == 0
end

local function blockTransparent(result: RaycastResult, cancel: () -> ())
	local hit = result.Instance :: BasePart
	if hit.Transparency > 0 then
		cancel()
	end
	return true
end

UserInputService.InputBegan:Connect(function(input, shouldSink)
	if shouldSink then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local rayParams = RaycastHelper.params({
			filterType = Enum.RaycastFilterType.Include,
			instances = { workspace.Model },
		})

		local mouseRay = getMouseRay()
		local result = RaycastHelper.raycast({
			origin = mouseRay.Origin,
			direction = mouseRay.Direction * 999,
			rayParams = rayParams,
			filter = blockTransparent,
		})

		local hit = result and result.Instance :: BasePart
		print(hit and hit.BrickColor.Name)
	end
end)
