# Raycast Helper

A simple module for ray and shape casting with complex filtering.

Get it here:

* [Wally](https://wally.run/package/egomoose/raycast-helper)
* [Releases](https://github.com/EgoMoose/raycast-helper/releases)

## Raycast callbacks

Every cast function in the module allows for an optional "filter" argument. This function can be used to write custom filters for a specific cast in addition to the built in functionality from `Enum.RaycastFilterType`.

```Luau
local CollectionService = game:GetService("CollectionService")

local function exampleFilter(result: RaycastResult, cancel: () -> ())
	local hit = result.Instance :: BasePart

	if CollectionService:HasTag(hit, "castCancel") then
		-- at any point we can cancel the cast attempt which closes the thread and leaves the final result as nil
		cancel()
	end

	-- otherwise, return a boolean
	-- if true, we will accept this raycast result
	-- if false, we will not accept this raycast result and will add the instance and its descendants to the exclusion list
	return hit.CanCollide
end
```

## Example

In this example a ray is casted and only parts that have `Transparency == 0` are considered as valid candidates for the ray to hit.

```Luau
local function mustBeFullyVisible(result: RaycastResult)
	local hit = result.Instance :: BasePart
	return hit.Transparency == 0
end

local mouseRay = getMouseRay()
local result = RaycastHelper.raycast({
	origin = mouseRay.Origin,
	direction = mouseRay.Direction * 999,

	rayParams = RaycastHelper.rayParams({
		filterType = Enum.RaycastFilterType.Include,
		instances = {},
	})

	filter = mustBeFullyVisible,
})
```

## API

```Luau
export type FilterCallback = (RaycastResult, () -> ()) -> boolean

type GeneralCastOptions = {
	worldRoot: WorldRoot?,
	rayParams: RaycastParams?,
	filter: FilterCallback?,
}

export type RaycastOptions = GeneralCastOptions & {
	origin: Vector3,
	direction: Vector3,
}

export type BlockcastOptions = GeneralCastOptions & {
	cframe: CFrame,
	size: Vector3,
	direction: Vector3,
}

export type SpherecastOptions = GeneralCastOptions & {
	position: Vector3,
	radius: number,
	direction: Vector3,
}

export type ShapecastOptions = GeneralCastOptions & {
	part: BasePart,
	cframe: CFrame?,
	direction: Vector3,
}

function module.raycast(options: RaycastOptions): RaycastResult?
function module.blockcast(options: BlockcastOptions): RaycastResult?
function module.spherecast(options: SpherecastOptions): RaycastResult?
function module.shapecast(options: ShapecastOptions): RaycastResult?

export type RaycastParamOptions = {
	instances: { Instance }?,
	filterType: Enum.RaycastFilterType?,
	ignoreWater: boolean?,
	collisionGroup: string?,
	respectCanCollide: boolean?,
	bruteForceAllSlow: boolean?,
}

function module.params(options: RaycastParamOptions): RaycastParams
```