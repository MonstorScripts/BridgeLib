local RESOURCE_INVENTORY = "qs-inventory-pro"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:GetItemTotalAmount(inv, item) or 0
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

	AddItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:RegisterStash(stashId, slots or 50, maxWeight or 100000)
	end,
}

return provider
