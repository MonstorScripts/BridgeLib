local RESOURCE_INVENTORY = "core_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@param count number?
---@return boolean
local function hasItem(inv, item, count)
	return exports[RESOURCE_INVENTORY]:hasItem(inv, item, count or 1) and true or false
end

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = hasItem,

	---core_inventory only answers whether an amount is held, not how much, so a count reads as 1.
	GetItemCount = function(inv, item)
		return hasItem(inv, item, 1) and 1 or 0
	end,

	CanAddItem = function(inv, item, count)
		return exports[RESOURCE_INVENTORY]:canCarry(inv, count or 1) and true or false
	end,

	CanCarryItem = function(inv, item, count)
		return exports[RESOURCE_INVENTORY]:canCarry(inv, count or 1) and true or false
	end,

	AddItem = function(inv, item, count, metadata)
		return exports[RESOURCE_INVENTORY]:addItem(inv, item, count or 1, metadata) ~= false
	end,

	RemoveItem = function(inv, item, count, metadata)
		return exports[RESOURCE_INVENTORY]:removeItem(inv, item, count or 1, metadata) ~= false
	end,
}

return provider
