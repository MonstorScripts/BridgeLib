local RESOURCE_INVENTORY = "one_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	local slot = exports[RESOURCE_INVENTORY]:GetItem(inv, item, nil)
	return slot and (slot.count or slot.amount) or 0
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@param count number?
---@return boolean
local function canCarry(inv, item, count)
	return exports[RESOURCE_INVENTORY]:CanCarryItem(inv, item, count or 1) and true or false
end

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(inv, item, count)
		return itemCount(inv, item) >= (count or 1)
	end,

	GetItemCount = itemCount,
	CanAddItem = canCarry,
	CanCarryItem = canCarry,

	AddItem = function(inv, item, count, metadata)
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, metadata) ~= false
	end,

	RemoveItem = function(inv, item, count, metadata)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, metadata) ~= false
	end,
}

return provider
