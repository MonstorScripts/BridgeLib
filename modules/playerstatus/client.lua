---Optional module: with no status resource running, a player reads as neither hungry nor thirsty.
---
---Both values are percentages, 0 to 100, whatever scale the resource underneath keeps them on.
---@class BridgeLib.PlayerStatus.Client
local schema = {
	---@return number hunger, number thirst
	GetPlayerStatus = function()
		return 0, 0
	end,
}

---@type BridgeLib.Module
return {
	name = "playerstatus",
	context = "client",
	providers = {
		"esx_status",
		"qb-core",
	},
	required = {
		"GetPlayerStatus",
	},
	schema = schema,
}
