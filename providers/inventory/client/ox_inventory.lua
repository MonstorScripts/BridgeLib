local RESOURCE_INVENTORY = "ox_inventory"

---Totals an ox_inventory Search result, which is either a plain count, a map of
---item name to count, or a list of matching slots.
---@param result number|table|nil
---@return number
local function totalCount(result)
	if type(result) == "number" then
		return result
	end

	if type(result) ~= "table" then
		return 0
	end

	local total = 0
	for _, entry in pairs(result) do
		if type(entry) == "number" then
			total = total + entry
		elseif type(entry) == "table" then
			total = total + (entry.count or entry.amount or 0)
		end
	end

	return total
end

---@return BridgeLib.Inventory.Client
return function()
	return {
		HasItem = function(name, amount)
			return totalCount(exports[RESOURCE_INVENTORY]:Search("count", name)) >= (amount or 1)
		end,

		GetImagePath = function()
			return "ox_inventory/web/images"
		end,

		OpenInventory = function(inventoryType, data)
			return exports[RESOURCE_INVENTORY]:openInventory(inventoryType, data) and true or false
		end,
	}
end
