local RESOURCE_TARGET = "qtarget"

---@type BridgeLib.Target.Client
local provider = {
	AddBoxZone = function(name, coords, width, length, options, targetOptions)
		exports[RESOURCE_TARGET]:AddBoxZone(name, coords, width, length, {
			name = options.name or name,
			heading = options.heading or 0,
			debugPoly = options.debugPoly,
			minZ = options.minZ,
			maxZ = options.maxZ,
		}, {
			options = targetOptions and targetOptions.options or {},
			distance = targetOptions and targetOptions.distance or 2.5,
		})
		return name
	end,

	RemoveZone = function(...)
		return exports[RESOURCE_TARGET]:RemoveZone(...)
	end,

	AddTargetEntity = function(entity, options)
		return exports[RESOURCE_TARGET]:AddTargetEntity(entity, {
			options = options.options or {},
			distance = options.distance or 2.5,
		})
	end,

	RemoveTargetEntity = function(entity)
		return exports[RESOURCE_TARGET]:RemoveTargetEntity(entity)
	end,
}

return provider
