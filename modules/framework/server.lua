---Events a framework server adapter emits through `bridge:Emit`.
---@alias BridgeLib.Framework.ServerEvent
---| "playerLoaded" # `(src: number)`, a player finished loading.

---A player, reduced to the fields that mean the same thing on every framework.
---@class BridgeLib.Player
---@field UniqueId string Persistent identifier: citizenid on qb-core, identifier on ESX.
---@field JobName string
---@field JobOnDuty boolean
---@field SetOnDuty fun(onDuty: boolean)

---@class BridgeLib.Framework.Server
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@param src number
	---@return BridgeLib.Player? player nil when no player is loaded for that source.
	GetPlayer = function(src) end,

	---@param src number
	---@param message string
	---@param type string? Framework notification style, typically "success", "error" or "primary".
	---@param length number? Milliseconds to display for.
	Notify = function(src, message, type, length) end,

	---Registers item definitions with the framework at runtime.
	---@param items table Item definitions, in the shape the framework expects.
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
