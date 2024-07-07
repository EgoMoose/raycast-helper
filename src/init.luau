--!strict

local module = {}

local WORLD_ROOT = workspace :: WorldRoot

-- Internal Types

type RaycastFilterCallback = (RaycastResult, () -> ()) -> boolean

type GeneralCastOptions = {
	worldRoot: WorldRoot?,
	rayParams: RaycastParams?,
	filter: RaycastFilterCallback?,
}

-- Private

local function cloneRaycastParams(rayParams: RaycastParams)
	local rayParamsCopy = RaycastParams.new()
	rayParamsCopy.FilterDescendantsInstances = rayParams.FilterDescendantsInstances
	rayParamsCopy.FilterType = rayParams.FilterType
	rayParamsCopy.IgnoreWater = rayParams.IgnoreWater
	rayParamsCopy.CollisionGroup = rayParams.CollisionGroup
	rayParamsCopy.RespectCanCollide = rayParams.RespectCanCollide
	rayParamsCopy.BruteForceAllSlow = rayParams.BruteForceAllSlow
	return rayParamsCopy
end

local function createInclusionFilter(inclusionInstances: { Instance })
	-- it's very hard to support callback filtering on the inclusion filter type
	-- instead, we opt to convert to an exclusion list that automatically filters
	-- any result that are not part of the inclusion list
	inclusionInstances = table.clone(inclusionInstances)

	local function isRelatedToIncluded(instance: Instance, relation: (Instance, Instance) -> boolean)
		for _, included in inclusionInstances do
			if instance == included or relation(instance, included) then
				return true
			end
		end
		return false
	end

	local function findLargestExcludedAncestor(instance: Instance)
		local ancestor = instance
		while
			ancestor ~= game
			and ancestor.Parent
			and not isRelatedToIncluded(ancestor.Parent, workspace.IsAncestorOf)
		do
			ancestor = ancestor.Parent
		end
		return ancestor
	end

	return function(rayResult: RaycastResult): Instance?
		local hit = rayResult.Instance
		if not isRelatedToIncluded(hit, workspace.IsDescendantOf) then
			return findLargestExcludedAncestor(hit)
		end
		return nil
	end
end

local function cast(rayParams: RaycastParams, filter: RaycastFilterCallback?, method: (RaycastParams) -> RaycastResult?)
	if not filter then
		return method(rayParams)
	end

	rayParams = cloneRaycastParams(rayParams)

	local inclusionFilter = nil
	if rayParams.FilterType == Enum.RaycastFilterType.Include then
		inclusionFilter = createInclusionFilter(rayParams.FilterDescendantsInstances)

		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {}
	end

	local taskCoroutine: thread
	local isCancelled = false
	local function cancel()
		isCancelled = true
		coroutine.yield()
		coroutine.close(taskCoroutine)
	end

	taskCoroutine = coroutine.create(function()
		local result: RaycastResult?
		while true do
			local rayResult = method(rayParams)

			if not rayResult then
				break
			end

			local filterInstance
			if inclusionFilter then
				filterInstance = inclusionFilter(rayResult)
			end

			local filterCallbackResult = false
			if not filterInstance then
				filterCallbackResult = filter(rayResult, cancel)
				filterInstance = rayResult.Instance
			end

			if filterCallbackResult then
				result = rayResult
				break
			elseif filterInstance then
				rayParams:AddToFilter(filterInstance)
			end
		end

		return result
	end)

	local ok, result = coroutine.resume(taskCoroutine)
	if not ok then
		-- there was an error in the filter function
		error(tostring(result), 0)
	elseif not isCancelled and coroutine.status(taskCoroutine) ~= "dead" then
		-- the filter function was yielding
		local fileName, lineNumber = debug.info(taskCoroutine, 1, "sl")
		error(`{fileName}:{lineNumber} Attempted to yield!`, 0)
	end

	return result
end

-- Public

export type RaycastParamOptions = {
	instances: { Instance }?,
	filterType: Enum.RaycastFilterType?,
	ignoreWater: boolean?,
	collisionGroup: string?,
	respectCanCollide: boolean?,
	bruteForceAllSlow: boolean?,
}

function module.params(options: RaycastParamOptions)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = options.instances or {}
	rayParams.FilterType = options.filterType or Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = options.ignoreWater or false
	rayParams.CollisionGroup = options.collisionGroup or "Default"
	rayParams.RespectCanCollide = options.respectCanCollide or false
	rayParams.BruteForceAllSlow = options.bruteForceAllSlow or false
	return rayParams
end

export type RaycastOptions = GeneralCastOptions & {
	origin: Vector3,
	direction: Vector3,
}

function module.raycast(options: RaycastOptions)
	local worldRoot = options.worldRoot or workspace
	local origin = options.origin
	local direction = options.direction
	local rayParams = options.rayParams or RaycastParams.new()
	local filter = options.filter

	return cast(rayParams, filter, function(tmpParams)
		return WORLD_ROOT.Raycast(worldRoot, origin, direction, tmpParams)
	end)
end

export type BlockcastOptions = GeneralCastOptions & {
	cframe: CFrame,
	size: Vector3,
	direction: Vector3,
}

function module.blockcast(options: BlockcastOptions)
	local worldRoot = options.worldRoot or workspace
	local cframe = options.cframe
	local size = options.size
	local direction = options.direction
	local rayParams = options.rayParams or RaycastParams.new()
	local filter = options.filter

	return cast(rayParams, filter, function(tmpParams)
		return WORLD_ROOT.Blockcast(worldRoot, cframe, size, direction, tmpParams)
	end)
end

export type SpherecastOptions = GeneralCastOptions & {
	position: Vector3,
	radius: number,
	direction: Vector3,
}

function module.spherecast(options: SpherecastOptions)
	local worldRoot = options.worldRoot or workspace
	local position = options.position
	local radius = options.radius
	local direction = options.direction
	local rayParams = options.rayParams or RaycastParams.new()
	local filter = options.filter

	return cast(rayParams, filter, function(tmpParams)
		return WORLD_ROOT.Spherecast(worldRoot, position, radius, direction, tmpParams)
	end)
end

export type ShapecastOptions = GeneralCastOptions & {
	part: BasePart,
	cframe: CFrame?,
	direction: Vector3,
}

function module.shapecast(options: ShapecastOptions)
	local worldRoot = options.worldRoot or workspace
	local part = options.part
	local cframe = options.cframe
	local direction = options.direction
	local rayParams = options.rayParams or RaycastParams.new()
	local filter = options.filter

	if cframe then
		part = part:Clone()
		part.CFrame = cframe
	end

	local result
	local success, err = pcall(function()
		result = cast(rayParams, filter, function(tmpParams)
			return WORLD_ROOT.Shapecast(worldRoot, part, direction, tmpParams)
		end)
	end)

	if cframe then
		part:Destroy()
	end

	if not success then
		error(err, 0)
	end

	return result
end

--

return module
