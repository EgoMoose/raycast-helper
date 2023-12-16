--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaycastHelper = require(ReplicatedStorage.Packages.RaycastHelper)

local function getMouseRay(): Ray
	local mousePos = UserInputService:GetMouseLocation()
	return workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
end

local function mustBeFullyVisible(result: RaycastResult)
	local hit = result.Instance :: BasePart
	return hit.Transparency == 0
end

local function onClickExclude()
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			table.insert(characters, character)
		end
	end

	local mouseRay = getMouseRay()
	local result = RaycastHelper.castRay({
		origin = mouseRay.Origin,
		direction = mouseRay.Direction * 999,

		filterType = Enum.RaycastFilterType.Exclude,
		instances = characters,

		callback = mustBeFullyVisible,
	})

	return result
end

local function onClickInclude()
	local mouseRay = getMouseRay()
	local result = RaycastHelper.castRay({
		origin = mouseRay.Origin,
		direction = mouseRay.Direction * 999,

		filterType = Enum.RaycastFilterType.Include,
		instances = { workspace.Model },

		callback = mustBeFullyVisible,
	})

	return result
end

local function callAndPrint(callback: (...any) -> ...any, ...)
	local funcName = debug.info(callback, "n")
	local result = callback(...)
	print(funcName, result and (result.Instance :: BasePart).BrickColor.Name)
end

UserInputService.InputBegan:Connect(function(input, shouldSink)
	if shouldSink then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		callAndPrint(onClickExclude)
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		callAndPrint(onClickInclude)
	end
end)
