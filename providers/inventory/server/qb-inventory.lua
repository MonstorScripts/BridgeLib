local RESOURCE_INVENTORY = "qb-inventory"
local RESOURCE_CORE = "qb-core"

---Every slot of an inventory holding the item. qb-inventory's GetItemsByName only
---resolves players, so standalone inventories are read straight off their items.
---@param inv BridgeLib.Inventory.Id
---@param item string
---@return table[]
local function slotsHolding(inv, item)
	local found = exports[RESOURCE_INVENTORY]:GetItemsByName(inv, item)

	if not found then
		local inventory = exports[RESOURCE_INVENTORY]:GetInventory(inv)
		local wanted = tostring(item):lower()
		found = {}

		for _, slot in pairs(inventory and inventory.items or {}) do
			if slot and slot.name and tostring(slot.name):lower() == wanted then
				found[#found + 1] = slot
			end
		end
	end

	return found
end

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function countHeld(inv, item)
	local total = 0

	for _, slot in pairs(slotsHolding(inv, item)) do
		total = total + (slot.amount or 0)
	end

	return total
end

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(inv, item, count)
		return countHeld(inv, item) >= (count or 1)
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
	RemoveItem = function(inv, item, count, slot, reason)
		count = count or 1

		if slot then
			return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count, slot, reason) and true or false
		end

		local held = slotsHolding(inv, item)
		local total = 0
		for _, entry in pairs(held) do
			total = total + (entry.amount or 0)
		end

		if total < count then
			return false
		end

		local remaining = count

		for _, entry in pairs(held) do
			if remaining <= 0 then
				break
			end

			local take = math.min(remaining, entry.amount or 0)
			if take > 0 then
				if not exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, take, entry.slot, reason) then
					return false
				end
				remaining = remaining - take
			end
		end

		return remaining <= 0
	end,
	CanAddItem = function(...)
		return exports[RESOURCE_INVENTORY]:CanAddItem(...)
	end,

	GetItemCount = function(inv, item)
		return countHeld(inv, item)
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
		local found = slotsHolding(inv, item)
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

	ClearInventory = function(inv)
		local cleared = pcall(function()
			exports[RESOURCE_INVENTORY]:ClearInventory(inv)
		end)

		if cleared then
			return true
		end

		local inventory = exports[RESOURCE_INVENTORY]:GetInventory(inv)

		for _, slot in pairs(inventory and inventory.items or {}) do
			if slot and slot.name then
				exports[RESOURCE_INVENTORY]:RemoveItem(inv, slot.name, slot.amount or 1, slot.slot, "bridgelib-clear")
			end
		end

		return true
	end,
}

return provider
