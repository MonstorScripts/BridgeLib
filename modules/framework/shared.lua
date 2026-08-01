---@class BridgeLib.Framework.Shared
local schema = {
	---@param item string
	---@return string label
	GetItemDisplayName = function(item) end,

	---@param name string
	---@return string label
	GetJobName = function(name) end,
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
	},
	schema = schema,
}
