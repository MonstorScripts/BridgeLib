local RESOURCE_INVENTORY = "origen_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:getItemCount(inv, item, false, false) or 0
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
		return exports[RESOURCE_INVENTORY]:addItem(inv, item, count or 1, metadata, slot)
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:removeItem(inv, item, count or 1, metadata, slot)
	end,
}

return provider
