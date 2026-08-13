local RESOURCE_INVENTORY = "core_inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:hasItem(name, amount or 1) and true or false
	end,

	GetImagePath = function()
		return "core_inventory/html/images"
	end,

	OpenInventory = function(inventoryType, data)
		TriggerServerEvent("core_inventory:server:openInventory", data and data.id, inventoryType)
		return true
	end,
}

return provider
