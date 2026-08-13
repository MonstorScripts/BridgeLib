local RESOURCE_ZONES = "ox_lib"

---Height given to a zone that declared no bounds, standing in for PolyZone's unbounded default.
local UNBOUNDED_THICKNESS = 10000.0

---@param options BridgeLib.Zones.Options
---@return number centre, number thickness
local function resolvePlane(options)
	local minZ, maxZ = options.minZ, options.maxZ
	if minZ and maxZ then
		return (minZ + maxZ) / 2, maxZ - minZ
	end
	return minZ or maxZ or 0.0, UNBOUNDED_THICKNESS
end

---@param point vector2|vector3|table
---@param z number
---@return vector3
local function toVector3(point, z)
	if type(point) == "vector3" then
		return point
	end
	return vector3(point.x, point.y, z)
end

---@param options BridgeLib.Zones.Options
---@param isPointInside boolean
---@return function?
local function inOutHandler(options, isPointInside)
	if not options.onPlayerInOut then
		return nil
	end
	return function(self)
		options.onPlayerInOut(isPointInside, self and self.coords or nil)
	end
end

---@param zone table
---@return BridgeLib.Zones.Zone
local function wrap(zone)
	return {
		id = zone,
		resource = RESOURCE_ZONES,
		remove = function(self)
			self.id:remove()
		end,
	}
end

---@type BridgeLib.Zones.Client
local provider = {
	AddPolyZone = function(points, options)
		options = options or {}
		local centre, thickness = resolvePlane(options)

		local converted = {}
		for index, point in ipairs(points) do
			converted[index] = toVector3(point, centre)
		end

		return wrap(lib.zones.poly({
			name = options.name,
			points = converted,
			thickness = thickness,
			debug = options.debug,
			onEnter = inOutHandler(options, true),
			onExit = inOutHandler(options, false),
		}))
	end,

	AddCircleZone = function(coords, radius, options)
		options = options or {}

		return wrap(lib.zones.sphere({
			name = options.name,
			coords = coords,
			radius = radius,
			debug = options.debug,
			onEnter = inOutHandler(options, true),
			onExit = inOutHandler(options, false),
		}))
	end,

	DestroyZone = function(zone)
		if type(zone) == "table" and zone.remove then
			zone:remove()
		end
	end,
}

return provider
