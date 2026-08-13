local RESOURCE_INVENTORY = "jaksam_inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:getTotalItemAmount(inv, item) or 0
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
		return exports[RESOURCE_INVENTORY]:hasItem(inv, item, count or 1) and true or false
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

	SetItemData = function(inv, item, key, value)
		local slot, slotId = exports[RESOURCE_INVENTORY]:getItemByName(inv, item)

		if not slot or not slotId then
			return false
		end

		local metadata = slot.metadata or {}
		metadata[key] = value

		return exports[RESOURCE_INVENTORY]:setItemMetadataInSlot(inv, slotId, metadata) ~= false
	end,

	CreateInventory = function(id, data)
		data = data or {}

		return exports[RESOURCE_INVENTORY]:createInventory(id, data.label or id, {
			maxWeight = data.maxweight,
			maxSlots = data.slots,
			coords = data.coords,
		}, data.items)
	end,

	GetInventory = function(id)
		return exports[RESOURCE_INVENTORY]:getInventory(id)
	end,

	OpenInventory = function(src, id)
		return exports[RESOURCE_INVENTORY]:forceOpenInventory(src, id)
	end,

	---jaksam_inventory exposes no item definition getter, so only the label is resolvable.
	GetItemData = function(item)
		local label = exports[RESOURCE_INVENTORY]:getItemLabel(item)
		return label and { name = item, label = label } or nil
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

	GetInventoryItems = function(id)
		local inventory = exports[RESOURCE_INVENTORY]:getInventory(id)
		return inventory and inventory.items or {}
	end,

	GetItemSlots = function(inv, item)
		local found = exports[RESOURCE_INVENTORY]:getItemsByName(inv, item) or {}
		local slots = {}

		for _, entry in pairs(found) do
			slots[#slots + 1] = {
				slot = entry.slot,
				count = entry.amount or 1,
				metadata = entry.metadata,
			}
		end

		return slots
	end,

	ClearInventory = function(inv)
		return exports[RESOURCE_INVENTORY]:clearInventory(inv) ~= false
	end,
}

return provider
