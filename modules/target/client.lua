---@class BridgeLib.Target.Client
local schema = {
	---@param name string
	---@param coords vector3
	---@param width number
	---@param length number
	---@param options table
	---@param targetOptions table?
	---@return any zoneId
	AddBoxZone = function(name, coords, width, length, options, targetOptions) end,

	---@param zoneId any
	RemoveZone = function(zoneId) end,

	---@param entity number
	---@param options table
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
