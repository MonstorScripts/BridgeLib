---Handle for a registered zone. qb-target keys zones by name, ox_target returns a numeric id.
---@alias BridgeLib.Target.ZoneId string|number

---One entry in a target's context menu.
---@class BridgeLib.Target.Option
---@field label string
---@field icon string? Font Awesome class, e.g. "fas fa-box".
---@field action fun(entity: number)?
---@field canInteract fun(entity: number, distance: number, data: table)?
---@field job string|string[]? Jobs allowed to see the option.
---@field item string|string[]? Items required to see the option.
---@field distance number? Overrides the group's interaction distance.

---@class BridgeLib.Target.Options
---@field options BridgeLib.Target.Option[]
---@field distance number? Default interaction distance for the group.

---Box geometry, in qb-target's vocabulary. ox_target derives its own box height from minZ and maxZ.
---@class BridgeLib.Target.ZoneOptions
---@field name string?
---@field heading number?
---@field minZ number
---@field maxZ number
---@field debugPoly boolean?

---@class BridgeLib.Target.Client
local schema = {
	---@param name string
	---@param coords vector3|table Centre of the box, as a vector or an `{x, y, z}` table.
	---@param width number
	---@param length number
	---@param options BridgeLib.Target.ZoneOptions
	---@param targetOptions BridgeLib.Target.Options?
	---@return BridgeLib.Target.ZoneId zoneId
	AddBoxZone = function(name, coords, width, length, options, targetOptions) end,

	---@param zoneId BridgeLib.Target.ZoneId
	RemoveZone = function(zoneId) end,

	---@param entity number
	---@param options BridgeLib.Target.Options
	AddTargetEntity = function(entity, options) end,

	---@param entity number
	RemoveTargetEntity = function(entity) end,
}

---@type BridgeLib.Module
return {
	name = "target",
	context = "client",
	providers = {
		"qb-target",
		"ox_target",
	},
	required = {
		"AddBoxZone",
		"RemoveZone",
		"AddTargetEntity",
		"RemoveTargetEntity",
	},
	schema = schema,
}
