local RESOURCE_INVENTORY = "core_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@param count number?
---@return boolean
local function hasItem(inv, item, count)
	return exports[RESOURCE_INVENTORY]:hasItem(inv, item, count or 1) and true or false
end

---@param id BridgeLib.Inventory.Id
---@return table
local function inventoryItems(id)
	return exports[RESOURCE_INVENTORY]:getInventory(id) or {}
end

---core_inventory names an item's field `item` in some payloads and `name` in others.
---@param inv BridgeLib.Inventory.Id
---@param item string
---@return BridgeLib.ItemSlot[]
local function slotsHolding(inv, item)
	local wanted = tostring(item):lower()
	local found = {}

	for slotId, slot in pairs(inventoryItems(inv)) do
		local name = slot and (slot.name or slot.item)

		if name and tostring(name):lower() == wanted then
			found[#found + 1] = {
				slot = slot.slot or slotId,
				count = slot.count or slot.amount or 1,
				metadata = slot.metadata or slot.info,
			}
		end
	end

	return found
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

	---core_inventory writes a whole slot at a time, so the slot is read back before it is written.
	SetItemData = function(inv, item, key, value)
		local held = slotsHolding(inv, item)[1]

		if not held then
			return false
		end

		local slot = exports[RESOURCE_INVENTORY]:getItemBySlot(inv, held.slot)

		if not slot then
			return false
		end

		local metadata = held.metadata or {}
		metadata[key] = value

		exports[RESOURCE_INVENTORY]:setItem(inv, slot.item or slot.name, slot.count or slot.amount, metadata)

		return true
	end,

	GetInventory = inventoryItems,
	GetInventoryItems = inventoryItems,
	GetItemSlots = slotsHolding,

	---core_inventory keys its standalone inventories with a `stash-` prefix.
	ClearInventory = function(inv)
		exports[RESOURCE_INVENTORY]:clearInventory(type(inv) == "number" and inv or ("stash-" .. inv))
		return true
	end,
}

return provider
