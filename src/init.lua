--!strict

type GeneralOptions = {
	worldRoot: WorldRoot?,
	instances: { Instance }?,
	filterType: Enum.RaycastFilterType?,
	ignoreWater: boolean?,
	collisionGroup: string?,
	respectCanCollide: boolean?,
	callback: ((RaycastResult, () -> ()) -> boolean)?,
}

export type RaycastOptions = GeneralOptions & {
	origin: Vector3,
	direction: Vector3,
}

export type BlockcastOptions = GeneralOptions & {
	origin: CFrame,
	size: Vector3,
	direction: Vector3,
}

export type SpherecastOptions = GeneralOptions & {
	origin: Vector3,
	radius: number,
	direction: Vector3,
}

local module = {}

-- Private

local function convertToInclusionFilter(rayParams: RaycastParams)
	-- it's very hard to support callback filtering on the inclusion filter type
	-- instead, we opt to convert to an exclusion list that automatically filters
	-- any result that are not part of the inclusion list

	local inclusionInstances: { Instance } = table.clone(rayParams.FilterDescendantsInstances)

	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {}

	local function isDescendantOfIncluded(descendant: Instance)
		for _, included in inclusionInstances do
			if descendant == included or descendant:IsDescendantOf(included) then
				return true
			end
		end
		return false
	end

	local function isAncestorOfIncluded(ancestor: Instance)
		for _, included in inclusionInstances do
			if ancestor == included or included:IsDescendantOf(ancestor) then
				return true
			end
		end
		return false
	end

	local function findLargestExcludedAncestor(instance: Instance)
		local ancestor = instance
		while ancestor ~= game and ancestor.Parent and not isAncestorOfIncluded(ancestor.Parent) do
			ancestor = ancestor.Parent
		end
		return ancestor
	end

	return function(rayResult: RaycastResult): Instance?
		local hit = rayResult.Instance
		if not isDescendantOfIncluded(hit) then
			return findLargestExcludedAncestor(hit)
		end
		return nil
	end
end

local function cast(options: GeneralOptions, castMethod: (WorldRoot, RaycastParams) -> RaycastResult?): RaycastResult?
	local callback = options.callback
	local worldRoot = options.worldRoot or workspace

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = options.instances or {}
	rayParams.FilterType = options.filterType or Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = options.ignoreWater or false
	rayParams.CollisionGroup = options.collisionGroup or "Default"
	rayParams.RespectCanCollide = options.respectCanCollide or false

	if not callback then
		return castMethod(worldRoot, rayParams)
	end

	local isCancelled = false
	local function cancel()
		isCancelled = true
	end

	local inclusionFilter = nil
	if rayParams.FilterType == Enum.RaycastFilterType.Include then
		inclusionFilter = convertToInclusionFilter(rayParams)
	end

	local result: RaycastResult?
	while true do
		local rayResult = castMethod(worldRoot, rayParams)

		if not rayResult then
			break
		end

		local filterInstance
		if inclusionFilter then
			filterInstance = inclusionFilter(rayResult)
		end

		local callbackResult = false
		if not filterInstance then
			callbackResult = callback(rayResult, cancel)
			filterInstance = rayResult.Instance
		end

		if isCancelled then
			break
		elseif callbackResult then
			result = rayResult
			break
		else
			rayParams:AddToFilter(filterInstance :: Instance)
		end
	end

	return result
end

-- Public

function module.castRay(options: RaycastOptions)
	return cast(options, function(worldRoot, rayParams)
		-- selene: allow (incorrect_standard_library_use)
		return workspace.Raycast(worldRoot, options.origin, options.direction, rayParams)
	end)
end

function module.castBlock(options: BlockcastOptions)
	return cast(options, function(worldRoot, rayParams)
		-- selene: allow (incorrect_standard_library_use)
		return workspace.Blockcast(worldRoot, options.origin, options.size, options.direction, rayParams)
	end)
end

function module.castSphere(options: SpherecastOptions)
	return cast(options, function(worldRoot, rayParams)
		-- selene: allow (incorrect_standard_library_use)
		return workspace.Spherecast(worldRoot, options.origin, options.radius, options.direction, rayParams)
	end)
end

return module
