local RESOURCE_TARGET = "qb-target"

---@type BridgeLib.Target.Client
local provider = {
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

return provider
