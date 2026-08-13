---@class BridgeLib.Framework.Shared
local schema = {
	---@param item string
	---@return string label Falls back to a placeholder or the item name when the item is unknown.
	GetItemDisplayName = function(item) end,

	---@param name string
	---@return string label Falls back to a placeholder or the job name when the job is unknown.
	GetJobName = function(name) end,

	---@param name string
	---@return boolean exists Whether the framework knows about a job with this name.
	DoesJobExist = function(name) end,
}

---@type BridgeLib.Module
return {
	name = "framework",
	context = "shared",
	providers = {
		"qb-core",
		"es_extended",
	},
	required = {
		"GetItemDisplayName",
		"GetJobName",
		"DoesJobExist",
	},
	schema = schema,
}
