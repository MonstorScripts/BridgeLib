---@class BridgeLib.PlayerData
---@field job table
---@field grade number?

---@class BridgeLib.Framework.Client
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@return BridgeLib.PlayerData
	GetLocalPlayerData = function() end,

	---@param message string
	---@param type string?
	---@param length number?
	LocalNotify = function(message, type, length) end,

	---@param name string
	---@param label string
	---@param duration number
	---@param useWhileDead boolean
	---@param canCancel boolean
	---@param disableControls table
	---@param animation table?
	---@param prop table?
	---@param propTwo table?
	---@param onFinish function?
	---@param onCancel function?
	Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel) end,
}

---@type BridgeLib.Module
return {
	name = "framework",
	context = "client",
	providers = {
		"qb-core",
		"es_extended",
	},
	events = {
		"playerLoaded",
		"playerUnloaded",
		"jobUpdated",
		"playerDataUpdated",
	},
	required = {
		"InitNetworkEvents",
		"GetLocalPlayerData",
		"LocalNotify",
		"Progressbar",
	},
	schema = schema,
}
