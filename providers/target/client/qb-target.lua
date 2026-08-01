local RESOURCE_TARGET = "qb-target"

---@return BridgeLib.Target.Client
return {
	AddBoxZone = function(name, ...)
		exports[RESOURCE_TARGET]:AddBoxZone(name, ...)
		return name
	end,

	RemoveZone = function(...)
		return exports[RESOURCE_TARGET]:RemoveZone(...)
	end,

	AddTargetEntity = function(...)
		return exports[RESOURCE_TARGET]:AddTargetEntity(...)
	end,

	RemoveTargetEntity = function(...)
		return exports[RESOURCE_TARGET]:RemoveTargetEntity(...)
	end,
}
