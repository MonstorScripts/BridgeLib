---@class BridgeLib.Doorlock.State
---@field id string|number Door id as the doorlock resource keys it, which is a name on ox_doorlock and doors_creator.
---@field locked boolean
---@field enableSounds boolean? Whether the doorlock plays its own lock sound.
---@field src number? Server only, cd_doorlock only. The client to change the door for, defaulting to every client.
---@field location vector3? Server only, cd_doorlock only. Position of the door.

---Optional module: with no doorlock resource running, state changes are dropped.
---
---ox_doorlock, cd_doorlock and doors_creator all resolve or push the door from the server, so they
---appear only in the server context. A client on one of those calls the server bridge instead.
---@class BridgeLib.Doorlock.Client
local schema = {
	---@param data BridgeLib.Doorlock.State
	SetDoorState = function(data) end,
}

---@type BridgeLib.Module
return {
	name = "doorlock",
	context = "client",
	providers = {
		"qb-doorlock",
		"nui-doorlock",
	},
	required = {
		"SetDoorState",
	},
	schema = schema,
}
