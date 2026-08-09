local RESOURCE_INVENTORY = "origen_inventory"

---@param name string
---@return number
local function countItem(name)
	local inventory = exports[RESOURCE_INVENTORY]:GetInventory()
	if type(inventory) ~= "table" then
		return 0
	end

	local total = 0
	for _, slot in pairs(inventory) do
		if slot and tostring(slot.name) == name then
			total = total + (slot.amount or 0)
		end
	end

	return total
end

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return countItem(name) >= (amount or 1)
	end,

	GetImagePath = function()
		return "origen_inventory/html/images"
	end,

	OpenInventory = function(inventoryType, data)
		exports[RESOURCE_INVENTORY]:openInventory(inventoryType, data and data.id, data)
		return true
	end,
}

return provider
