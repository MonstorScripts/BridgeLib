---@class BridgeLib.Inventory.Client
local schema = {
	---@param name string
	---@param amount number?
	---@return boolean
	HasItem = function(name, amount) end,
}

---@type BridgeLib.Module
return {
	name = "inventory",
	context = "client",
	providers = {
		"qb-inventory",
		"ox_inventory",
	},
	required = {
		"HasItem",
	},
	schema = schema,
}
