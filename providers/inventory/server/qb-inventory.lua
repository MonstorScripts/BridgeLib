local RESOURCE_INVENTORY = "qb-inventory"
local RESOURCE_CORE = "qb-core"

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
		local found = exports[RESOURCE_INVENTORY]:GetItemByName(inv, item)
		return found and found.amount or 0
	end,

	CanCarryItem = function(inv, item, count)
		return exports[RESOURCE_INVENTORY]:CanAddItem(inv, item, count or 1) and true or false
	end,

	GetItemData = function(item)
		local QBCore = exports[RESOURCE_CORE]:GetCoreObject()
		return QBCore.Shared.Items[item:lower()]
	end,

	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups)
		return exports[RESOURCE_INVENTORY]:CreateInventory(stashId, {
			label = label,
			slots = slots,
			maxweight = maxWeight,
			owner = owner,
			groups = groups,
		})
	end,

	GetInventoryItems = function(id)
		local inventory = exports[RESOURCE_INVENTORY]:GetInventory(id)
		return inventory and inventory.items or {}
	end,

	GetItemSlots = function(inv, item)
		local found = exports[RESOURCE_INVENTORY]:GetItemsByName(inv, item) or {}
		local slots = {}

		for _, entry in pairs(found) do
			slots[#slots + 1] = {
				slot = entry.slot,
				count = entry.amount or 1,
				metadata = entry.info,
			}
		end

		return slots
	end,
}

return provider
