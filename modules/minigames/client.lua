---Optional module: a minigame whose resource is not running reports failure to its callback rather
---than blocking, so a caller always hears back.
---@class BridgeLib.Minigames.Client
local schema = {
	---Names of every minigame the library knows, whether or not its resource is running.
	---@return string[]
	GetHacks = function()
		return {}
	end,

	---Whether the resource behind a minigame is running.
	---@param kind string
	---@return boolean
	HasHack = function(kind) end,

	---Starts a minigame, calling back with whether the player beat it.
	---@param kind string One of `GetHacks`, e.g. "ps-circle" or "gl-brute-force".
	---@param callback fun(success: boolean)
	---@param ... any Arguments the minigame takes, forwarded verbatim.
	StartHack = function(kind, callback, ...) end,
}

---@type BridgeLib.Module
return {
	name = "minigames",
	context = "client",
	---Every minigame names its own resource, so unlike the other modules this one is not a choice
	---between interchangeable resources and the library hosts the whole catalog itself.
	providers = {
		{ adapter = "BridgeLib" },
	},
	required = {
		"GetHacks",
		"HasHack",
		"StartHack",
	},
	schema = schema,
}
