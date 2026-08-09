local RESOURCE_INVENTORY = "tgiann-inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:HasItem(name, amount or 1) and true or false
	end,

	GetImagePath = function()
		return "tgiann-inventory/html/images"
	end,

	OpenInventory = function(inventoryType, data)
		return exports[RESOURCE_INVENTORY]:OpenInventory(inventoryType, data and data.id or data) and true or false
	end,
}

return provider
