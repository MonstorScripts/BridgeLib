local RESOURCE_INVENTORY = "jaksam_inventory"

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return exports[RESOURCE_INVENTORY]:hasEnoughOfItem(name, amount or 1) and true or false
	end,

	GetImagePath = function()
		return "jaksam_inventory/html/images"
	end,

	OpenInventory = function(_, data)
		return exports[RESOURCE_INVENTORY]:openInventory(data and data.id or data) and true or false
	end,
}

return provider
