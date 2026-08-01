local RESOURCE_INVENTORY = "qb-inventory"

---@return BridgeLib.Inventory.Client
return {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:HasItem(name, amount)
	end,
}
