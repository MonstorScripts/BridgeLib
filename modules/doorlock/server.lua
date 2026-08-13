---Optional module: with no doorlock resource running, state changes are dropped.
---@class BridgeLib.Doorlock.Server
local schema = {
	---@param data BridgeLib.Doorlock.State
	SetDoorState = function(data) end,
}

---@type BridgeLib.Module
return {
	name = "doorlock",
	context = "server",
	providers = {
		"ox_doorlock",
		"qb-doorlock",
		"nui-doorlock",
		"cd_doorlock",
		"doors_creator",
	},
	required = {
		"SetDoorState",
	},
	schema = schema,
}
