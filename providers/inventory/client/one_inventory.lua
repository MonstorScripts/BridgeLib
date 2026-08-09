local RESOURCE_INVENTORY = "one_inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		local item = exports[RESOURCE_INVENTORY]:GetItem(name)
		return (item and (item.count or item.amount) or 0) >= (amount or 1)
	end,

	GetImagePath = function()
		return "one_inventory/html/images"
	end,
}

return provider
