---Optional module: with no boss menu resource running, the stub is a no-op.
---@class BridgeLib.BossMenu.Client
local schema = {
	---Opens the boss menu for a job, when the local player is allowed to manage it.
	---@param jobName string
	OpenBossMenu = function(jobName) end,
}

---@type BridgeLib.Module
return {
	name = "bossmenu",
	context = "client",
	providers = {
		"monstor-bossmenu",
	},
	required = {
		"OpenBossMenu",
	},
	schema = schema,
}
