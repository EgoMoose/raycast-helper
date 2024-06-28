--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ringTemplate = ReplicatedStorage:WaitForChild("Ring") :: BasePart

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

		filterCallback = mustBeFullyVisible,
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

		filterCallback = mustBeFullyVisible,
	})

	return result
end

local function onClickShapecast()
	local mouseRay = getMouseRay()
	local originCFrame = CFrame.lookAt(mouseRay.Origin, mouseRay.Origin + mouseRay.Direction)
	local result = RaycastHelper.castShape({
		part = ringTemplate,
		cframe = originCFrame,
		direction = mouseRay.Direction * 999,

		filterType = Enum.RaycastFilterType.Include,
		instances = { workspace.Model },

		filterCallback = mustBeFullyVisible,
	})

	if result then
		local ring = ringTemplate:Clone()
		ring.CFrame = originCFrame + mouseRay.Direction * result.Distance
		ring.Parent = workspace
	end

	return result
end

local function callAndPrint(callback: (...any) -> ...any, ...)
	local funcName = debug.info(callback, "n")
	local result = callback(...)
	print(funcName, result and (result.Instance :: BasePart).BrickColor.Name)
end

local click3Count = 0
UserInputService.InputBegan:Connect(function(input, shouldSink)
	if shouldSink then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		callAndPrint(onClickShapecast)
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		click3Count = click3Count + 1
		if click3Count % 2 == 0 then
			callAndPrint(onClickInclude)
		else
			callAndPrint(onClickExclude)
		end
	end
end)
