local RESOURCE_INVENTORY = "qb-inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:HasItem(name, amount)
	end,

	GetImagePath = function()
		return "qb-inventory/html/images"
	end,

	OpenInventory = function(inventoryType, data)
		TriggerServerEvent("inventory:server:OpenInventory", inventoryType, data and data.id, data)
		return true
	end,
}

return provider
