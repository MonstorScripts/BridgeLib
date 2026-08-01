---@class BridgeLib.Player
---@field UniqueId string
---@field JobName string
---@field JobOnDuty boolean
---@field SetOnDuty fun(onDuty: boolean)

---@class BridgeLib.Framework.Server
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@param src number
	---@return BridgeLib.Player?
	GetPlayer = function(src) end,

	---@param src number
	---@param message string
	---@param type string?
	---@param length number?
	Notify = function(src, message, type, length) end,

	---@param items table
	---@return boolean
	AddItems = function(items) end,

	---@param itemName string
	---@param callback fun(source: number, item: table)
	CreateUseableItem = function(itemName, callback) end,
}

---@type BridgeLib.Module
return {
	name = "framework",
	context = "server",
	providers = {
		"qb-core",
		"es_extended",
	},
	events = {
		"playerLoaded",
	},
	required = {
		"InitNetworkEvents",
		"GetPlayer",
		"Notify",
		"AddItems",
		"CreateUseableItem",
	},
	schema = schema,
}
