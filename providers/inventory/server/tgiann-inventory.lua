local RESOURCE_INVENTORY = "tgiann-inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:GetItem(inv, item, false, true) or 0
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@param count number?
---@return boolean
local function canCarry(inv, item, count)
	return exports[RESOURCE_INVENTORY]:CanCarryItem(inv, item, count or 1) and true or false
end

---tgiann-inventory splits reads by inventory type, so a numeric id is a player and anything else is a stash.
---@param id BridgeLib.Inventory.Id
---@return table
local function inventoryItems(id)
	if type(id) == "number" then
		return exports[RESOURCE_INVENTORY]:GetPlayerItems(id) or {}
	end

	return exports[RESOURCE_INVENTORY]:GetSecondaryInventoryItems("stash", id) or {}
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
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, slot, metadata) ~= false
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, slot, metadata) ~= false
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:RegisterStash(stashId, label or stashId, slots or 50, maxWeight or 100000, owner and true or false, false)
	end,

	SetItemData = function(inv, item, key, value)
		local slot = exports[RESOURCE_INVENTORY]:GetItemByName(inv, item)

		if not slot or not slot.slot then
			return false
		end

		local metadata = slot.info or slot.metadata or {}
		metadata[key] = value

		return exports[RESOURCE_INVENTORY]:UpdateItemMetadata(inv, item, slot.slot, metadata) ~= false
	end,

	CreateInventory = function(id, data)
		data = data or {}

		local created = exports[RESOURCE_INVENTORY]:RegisterStash({
			stashName = id,
			label = data.label or id,
			slots = data.slots,
			maxWeight = data.maxweight,
			coords = data.coords,
		})

		if data.items then
			exports[RESOURCE_INVENTORY]:CreateCustomStashWithItem(id, data.items)
		end

		return created
	end,

	GetInventory = function(id)
		return { id = id, items = inventoryItems(id) }
	end,

	OpenInventory = function(src, id)
		if type(id) == "number" then
			return exports[RESOURCE_INVENTORY]:OpenInventoryById(src, id)
		end

		return exports[RESOURCE_INVENTORY]:OpenInventory(src, "stash", id)
	end,

	GetItemData = function(item)
		return exports[RESOURCE_INVENTORY]:GetItemList(item)
	end,

	GetInventoryItems = inventoryItems,

	GetItemSlots = function(inv, item)
		local found = exports[RESOURCE_INVENTORY]:GetItemsByName(inv, item) or {}
		local slots = {}

		for _, entry in pairs(found) do
			slots[#slots + 1] = {
				slot = entry.slot,
				count = entry.amount or entry.count or 1,
				metadata = entry.info or entry.metadata,
			}
		end

		return slots
	end,

	ClearInventory = function(inv)
		return exports[RESOURCE_INVENTORY]:ClearInventory(inv) ~= false
	end,
}

return provider
