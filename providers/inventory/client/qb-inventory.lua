local RESOURCE_INVENTORY = "qb-inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:HasItem(name, amount)
	end,
}

return provider
