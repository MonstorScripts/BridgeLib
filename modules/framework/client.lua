---Events a framework client adapter emits through `bridge:Emit`.
---@alias BridgeLib.Framework.ClientEvent
---| "playerLoaded" # The local player finished loading. ESX passes its xPlayer, qb-core passes nothing.
---| "playerUnloaded" # The local player logged out.
---| "jobUpdated" # `(job: table)`, fired both on job change and on any player data change.
---| "playerDataUpdated" # `(playerData: table)`, the framework's whole player data table.

---The subset of framework player data the library normalises across frameworks.
---@class BridgeLib.PlayerData
---@field job table? The framework's raw job table.
---@field grade number? Job grade level, flattened out of the framework's nesting.

---@class BridgeLib.Framework.Client
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@return BridgeLib.PlayerData
	GetLocalPlayerData = function() end,

	---@param message string
	---@param type string? Framework notification style, typically "success", "error" or "primary".
	---@param length number? Milliseconds to display for.
	LocalNotify = function(message, type, length) end,

	---Runs a blocking progress bar. Providers differ on whether they return the outcome, so treat
	---`onFinish` and `onCancel` as the reliable way to observe it.
	---@param name string Identifier for the action, used by the underlying progress resource.
	---@param label string Text shown to the player.
	---@param duration number Milliseconds.
	---@param useWhileDead boolean
	---@param canCancel boolean
	---@param disableControls table Control groups to block, in the shape the progress resource expects.
	---@param animation table? Animation descriptor, in the shape the progress resource expects.
	---@param prop table? Prop attached for the duration.
	---@param propTwo table? Second prop, ignored by providers that support only one.
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
