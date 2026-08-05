---Events a framework server adapter emits through `bridge:Emit`.
---@alias BridgeLib.Framework.ServerEvent
---| "playerLoaded" # `(src: number)`, a player finished loading.
---| "playerUnloaded" # `(src: number)`, a player logged out.
---| "jobUpdated" # `(src: number, job: BridgeLib.LiveJob, lastJob: BridgeLib.LiveJob?)`.

---One grade of a job, normalised out of the framework's own grade table.
---@class BridgeLib.Grade
---@field grade number Grade level.
---@field name string Short grade name.
---@field label string Display label, falling back to `name`.
---@field salary number Pay for the grade, 0 when the framework tracks none.

---A job as the framework's catalog describes it.
---@class BridgeLib.Job
---@field name string
---@field label string
---@field grades table<string, BridgeLib.Grade> Keyed by grade level as a string, on either framework.
---@field supportsDuty boolean Whether the framework tracks a duty state for this job. True on qb-core
---jobs that carry `defaultDuty`, always false on ESX, which models off duty as a separate `off_` job.

---A player, reduced to the fields that mean the same thing on every framework.
---@class BridgeLib.Player
---@field UniqueId string Persistent identifier: citizenid on qb-core, identifier on ESX.
---@field Source number Server id of the player this snapshot was taken for.
---@field Name string Character name, falling back to the connection name.
---@field JobName string
---@field JobLabel string
---@field JobGrade number Grade level, flattened out of the framework's nesting.
---@field JobGradeName string
---@field JobGradeSalary number
---@field JobOnDuty boolean
---@field SetOnDuty fun(onDuty: boolean)
---@field SetJob fun(jobName: string, grade: number, onDuty: boolean?)
---@field GetAccountMoney fun(account: string): number Account names are ESX's; qb-core maps them.
---@field AddAccountMoney fun(account: string, amount: number, reason: string?)
---@field RemoveAccountMoney fun(account: string, amount: number, reason: string?)

---@class BridgeLib.Framework.Server
local schema = {
	---Registers the framework's player lifecycle events and forwards them to `bridge:Emit`.
	InitNetworkEvents = function() end,

	---@param src number
	---@return BridgeLib.Player? player nil when no player is loaded for that source.
	GetPlayer = function(src) end,

	---@param identifier string
	---@return BridgeLib.Player? player nil when that identifier is not currently connected.
	GetPlayerByIdentifier = function(identifier) end,

	---Every player currently loaded.
	---@return BridgeLib.Player[]
	GetPlayers = function() end,

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

	---@param item string
	---@return string label Falls back to the item name when the item is unknown.
	GetItemDisplayName = function(item) end,

	---The framework's whole job catalog, keyed by job name.
	---@return table<string, BridgeLib.Job>
	GetJobs = function() end,

	---Rebuilds the framework's job cache. A no-op on frameworks that keep none.
	RefreshJobs = function() end,

	---Character name of a player who is not currently connected.
	---@param identifier string
	---@return string name "Unknown" when the identifier is not on record.
	GetOfflinePlayerName = function(identifier) end,

	---Writes a job straight onto a player who is not currently connected. Needs oxmysql loaded by
	---the consuming resource, since it reaches past the framework into its player table.
	---@param identifier string
	---@param jobName string
	---@param grade number
	---@return boolean written
	SetOfflinePlayerJob = function(identifier, jobName, grade) end,
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
		"playerUnloaded",
		"jobUpdated",
	},
	required = {
		"InitNetworkEvents",
		"GetPlayer",
		"GetPlayerByIdentifier",
		"GetPlayers",
		"Notify",
		"AddItems",
		"CreateUseableItem",
		"GetItemDisplayName",
		"GetJobs",
		"RefreshJobs",
		"GetOfflinePlayerName",
		"SetOfflinePlayerJob",
	},
	schema = schema,
}
