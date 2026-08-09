local RESOURCE_INVENTORY = "jaksam_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	local slot = exports[RESOURCE_INVENTORY]:getItemByName(inv, item)
	return slot and (slot.amount or slot.count) or 0
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@param count number?
---@return boolean
local function canCarry(inv, item, count)
	return exports[RESOURCE_INVENTORY]:canCarryItem(inv, item, count or 1) and true or false
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
		return exports[RESOURCE_INVENTORY]:addItem(inv, item, count or 1, metadata) ~= false
	end,

	RemoveItem = function(inv, item, count, metadata)
		return exports[RESOURCE_INVENTORY]:removeItem(inv, item, count or 1, metadata) ~= false
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:registerStash({
			id = stashId,
			label = label or stashId,
			maxSlots = slots or 100,
			maxWeight = maxWeight or 100000,
			isPrivate = owner and true or false,
			allowedJobs = groups,
			runtimeOnly = false,
		})
	end,
}

return provider
