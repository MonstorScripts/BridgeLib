local RESOURCE_INVENTORY = "codem-inventory"

---@param name string
---@return number
local function countItem(name)
	local inventory = exports[RESOURCE_INVENTORY]:getUserInventory()
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
		return "codem-inventory/html/itemimages"
	end,

	OpenInventory = function(inventoryType, data)
		if inventoryType == "shop" then
			TriggerEvent("codem-inventory:openshop", data and (data.id or data.name) or data)
			return true
		end

		TriggerServerEvent(
			"codem-inventory:server:openstash",
			data and (data.id or data.name) or data,
			data and data.slots,
			data and data.maxweight,
			data and data.label
		)

		return true
	end,
}

return provider
