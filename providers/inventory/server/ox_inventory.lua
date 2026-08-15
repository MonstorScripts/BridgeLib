local RESOURCE_INVENTORY = "ox_inventory"

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(inv, item, count)
		local held = exports[RESOURCE_INVENTORY]:GetItemCount(inv, item, nil, false) or 0

		return held >= (count or 1)
	end,

	SetItemData = function(inv, item, key, value)
		local slotIds = exports[RESOURCE_INVENTORY]:GetSlotIdsWithItem(inv, item, nil, false)
		local slotId = slotIds and slotIds[1]

		if not slotId then return false end

		local slot = exports[RESOURCE_INVENTORY]:GetSlot(inv, slotId)
		local metadata = slot and slot.metadata or {}

		metadata[key] = value

		exports[RESOURCE_INVENTORY]:SetMetadata(inv, slotId, metadata)

		return true
	end,

	CreateInventory = function(id, data)
		data = data or {}

		return exports[RESOURCE_INVENTORY]:RegisterStash(
			id,
			data.label,
			data.slots,
			data.maxweight,
			data.owner,
			data.groups,
			data.coords
		)
	end,

	GetInventory = function(...)
		return exports[RESOURCE_INVENTORY]:GetInventory(...)
	end,

	OpenInventory = function(src, id)
		local inventoryType = type(id) == "number" and "player" or "stash"
		return exports[RESOURCE_INVENTORY]:forceOpenInventory(src, inventoryType, id)
	end,

	AddItem = function(...)
		return exports[RESOURCE_INVENTORY]:AddItem(...)
	end,
	RemoveItem = function(...)
		return exports[RESOURCE_INVENTORY]:RemoveItem(...)
	end,

	CanAddItem = function(inv, item, count)
		return exports[RESOURCE_INVENTORY]:CanCarryItem(inv, item, count or 1) and true or false
	end,

	GetItemCount = function(inv, item)
		return exports[RESOURCE_INVENTORY]:GetItemCount(inv, item) or 0
	end,

	CanCarryItem = function(inv, item, count)
		return exports[RESOURCE_INVENTORY]:CanCarryItem(inv, item, count or 1) and true or false
	end,

	GetItemData = function(item)
		return exports[RESOURCE_INVENTORY]:Items(item)
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:RegisterStash(stashId, label, slots, maxWeight, owner, groups)
	end,

	GetInventoryItems = function(id)
		return exports[RESOURCE_INVENTORY]:GetInventoryItems(id) or {}
	end,

	GetItemSlots = function(inv, item)
		local slotIds = exports[RESOURCE_INVENTORY]:GetSlotIdsWithItem(inv, item, {}, false) or {}
		local slots = {}

		for _, slotId in ipairs(slotIds) do
			local slot = exports[RESOURCE_INVENTORY]:GetSlot(inv, slotId)
			if slot then
				slots[#slots + 1] = {
					slot = slotId,
					count = slot.count or 1,
					metadata = slot.metadata,
				}
			end
		end

		return slots
	end,

	ClearInventory = function(inv)
		local cleared = pcall(function()
			exports[RESOURCE_INVENTORY]:ClearInventory(inv)
		end)

		return cleared
	end,
}

return provider
