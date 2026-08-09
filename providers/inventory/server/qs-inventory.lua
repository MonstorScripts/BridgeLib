local RESOURCE_INVENTORY = "qs-inventory"

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

---qs-inventory reads players and stashes through different exports, so a numeric id is a player.
---@param id BridgeLib.Inventory.Id
---@return table
local function inventoryItems(id)
	if type(id) == "number" then
		return exports[RESOURCE_INVENTORY]:GetInventory(id) or {}
	end

	return exports[RESOURCE_INVENTORY]:GetStashItems(id) or {}
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return table[]
local function slotsHolding(inv, item)
	local wanted = tostring(item):lower()
	local found = {}

	for slotId, slot in pairs(inventoryItems(inv)) do
		if slot and slot.name and tostring(slot.name):lower() == wanted then
			found[#found + 1] = {
				slot = slot.slot or slotId,
				count = slot.amount or 1,
				metadata = slot.info,
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
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	SetItemData = function(inv, item, key, value)
		local held = slotsHolding(inv, item)[1]

		if not held then
			return false
		end

		local metadata = held.metadata or {}
		metadata[key] = value

		return exports[RESOURCE_INVENTORY]:SetItemMetadata(inv, held.slot, metadata) ~= false
	end,

	GetItemData = function(item)
		local items = exports[RESOURCE_INVENTORY]:GetItemList()
		return items and items[item:lower()]
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:RegisterStash(type(owner) == "number" and owner or nil, stashId, slots or 50, maxWeight or 100000)
	end,

	CreateInventory = function(id, data)
		data = data or {}
		return exports[RESOURCE_INVENTORY]:RegisterStash(nil, id, data.slots or 50, data.maxweight or 100000)
	end,

	GetInventory = function(id)
		return inventoryItems(id)
	end,

	GetInventoryItems = inventoryItems,
	GetItemSlots = slotsHolding,

	---qs-inventory only clears standalone inventories, never a player's own.
	ClearInventory = function(inv)
		if type(inv) == "number" then
			return false
		end

		return exports[RESOURCE_INVENTORY]:ClearOtherInventory("stash", inv) ~= false
	end,
}

return provider
