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

---origen reads players and standalone inventories through different exports, so a numeric id is a player.
---@param id BridgeLib.Inventory.Id
---@return table
local function inventoryItems(id)
	if type(id) == "number" then
		return exports[RESOURCE_INVENTORY]:GetInventoryItems(id) or {}
	end

	return exports[RESOURCE_INVENTORY]:getInventory(id) or {}
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return BridgeLib.ItemSlot[]
local function slotsHolding(inv, item)
	local wanted = tostring(item):lower()
	local found = {}

	for slotId, slot in pairs(inventoryItems(inv)) do
		if slot and slot.name and tostring(slot.name):lower() == wanted then
			found[#found + 1] = {
				slot = slot.slot or slotId,
				count = slot.amount or slot.count or 1,
				metadata = slot.metadata or slot.info,
			}
		end
	end

	return found
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

	SetItemData = function(inv, item, key, value)
		local held = slotsHolding(inv, item)[1]

		if not held then
			return false
		end

		local metadata = held.metadata or {}
		metadata[key] = value

		return exports[RESOURCE_INVENTORY]:setMetadata(inv, held.slot, metadata) ~= false
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:registerStash(stashId, label or stashId, slots or 50, maxWeight or 100000)
	end,

	CreateInventory = function(id, data)
		data = data or {}
		return exports[RESOURCE_INVENTORY]:registerStash(id, data.label or id, data.slots or 50, data.maxweight or 100000)
	end,

	GetInventory = inventoryItems,
	GetInventoryItems = inventoryItems,
	GetItemSlots = slotsHolding,

	ClearInventory = function(inv)
		return exports[RESOURCE_INVENTORY]:ClearInventory(inv) ~= false
	end,
}

return provider
