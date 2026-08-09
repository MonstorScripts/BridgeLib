local RESOURCE_INVENTORY = "codem-inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:GetItemsTotalAmount(inv, item) or 0
end

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(inv, item, count)
		return itemCount(inv, item) >= (count or 1)
	end,

	GetItemCount = itemCount,

	AddItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, slot or false)
	end,

	---codem-inventory exposes no capacity check, so it accepts whatever it is handed.
	CanAddItem = function()
		return true
	end,

	CanCarryItem = function()
		return true
	end,
}

return provider
