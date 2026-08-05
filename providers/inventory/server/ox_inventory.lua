local RESOURCE_INVENTORY = "ox_inventory"

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(...)
		return exports[RESOURCE_INVENTORY]:HasItem(...)
	end,
	SetItemData = function(...)
		return exports[RESOURCE_INVENTORY]:SetItemData(...)
	end,
	CreateInventory = function(...)
		return exports[RESOURCE_INVENTORY]:CreateInventory(...)
	end,
	GetInventory = function(...)
		return exports[RESOURCE_INVENTORY]:GetInventory(...)
	end,
	OpenInventory = function(...)
		return exports[RESOURCE_INVENTORY]:OpenInventory(...)
	end,
	AddItem = function(...)
		return exports[RESOURCE_INVENTORY]:AddItem(...)
	end,
	RemoveItem = function(...)
		return exports[RESOURCE_INVENTORY]:RemoveItem(...)
	end,
	CanAddItem = function(...)
		return exports[RESOURCE_INVENTORY]:CanAddItem(...)
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
