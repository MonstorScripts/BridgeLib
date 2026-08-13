---Optional module: with no status resource running, feeding a player is a no-op.
---
---Both values are percentages, 0 to 100, whatever scale the resource underneath keeps them on.
---@class BridgeLib.PlayerStatus.Server
local schema = {
	---Tops a player up, rather than setting them to a level. Points are added and capped at 100, so a
	---meal is worth the same whether the player was full or starving.
	---@param src number
	---@param hunger number Points to add, 0 to leave hunger alone.
	---@param thirst number Points to add, 0 to leave thirst alone.
	AddPlayerStatus = function(src, hunger, thirst) end,
}

---@type BridgeLib.Module
return {
	name = "playerstatus",
	context = "server",
	providers = {
		"esx_status",
		"qb-core",
	},
	required = {
		"AddPlayerStatus",
	},
	schema = schema,
}
