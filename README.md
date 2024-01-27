# Raycast Helper

A simple module for ray and shape casting with complex filtering.

Get it here:

* [Wally](https://wally.run/package/egomoose/raycast-helper)
* [Releases](https://github.com/EgoMoose/raycast-helper/releases)

## Raycast callbacks

Every cast function in the module allows for an optional "callback" argument. This function can be used to write custom filters for a specific cast in addition to the built in functionality from `Enum.RaycastFilterType`.

```Lua
local CollectionService = game:GetService("CollectionService")

local function exampleFilter(result: RaycastResult, cancel: () -> ())
	local hit = result.Instance :: BasePart

	if CollectionService:HasTag(hit, "castCancel") then
		-- at any point we can cancel the cast attempt which leaves the final result as nil
		-- you don't explicitly need to return, but it exits the function early which may avoid
		-- any extra calls / operations
		return cancel()
	end

	-- otherwise, return a boolean
	-- if true, we will accept this raycast result
	-- if false, we will not accept this raycast result and will add the instance and its descendants to the exclusion list
	return hit.CanCollide
end
```

## Example

In this example a ray is casted and only parts that have `Transparency == 0` are considered as valid candidates for the ray to hit.

```Lua
local function mustBeFullyVisible(result: RaycastResult)
	local hit = result.Instance :: BasePart
	return hit.Transparency == 0
end

local mouseRay = getMouseRay()
local result = RaycastHelper.castRay({
	origin = mouseRay.Origin,
	direction = mouseRay.Direction * 999,

	filterType = Enum.RaycastFilterType.Exclude,
	instances = {},

	filterCallback = mustBeFullyVisible,
})
```

## API

```Lua
type GeneralOptions = {
	worldRoot: WorldRoot?,
	instances: { Instance }?,
	filterType: Enum.RaycastFilterType?,
	ignoreWater: boolean?,
	collisionGroup: string?,
	respectCanCollide: boolean?,
	filterCallback: ((RaycastResult, () -> ()) -> boolean)?,
}

type RaycastOptions = GeneralOptions & {
	origin: Vector3,
	direction: Vector3,
}

type BlockcastOptions = GeneralOptions & {
	origin: CFrame,
	size: Vector3,
	direction: Vector3,
}

type SpherecastOptions = GeneralOptions & {
	origin: Vector3,
	radius: number,
	direction: Vector3,
}

type ShapecastOptions = GeneralOptions & {
	part: BasePart,
	cframe: CFrame?,
	direction: Vector3,
}

function module.castRay(options: RaycastOptions): RaycastResult?
function module.castBlock(options: BlockcastOptions): RaycastResult?
function module.castSphere(options: SpherecastOptions): RaycastResult?
function module.castShape(options: ShapecastOptions): RaycastResult?
```