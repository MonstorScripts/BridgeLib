local RESOURCE_INVENTORY = "codem-inventory"

---@param inv BridgeLib.Inventory.Id
---@param item string
---@return number
local function itemCount(inv, item)
	return exports[RESOURCE_INVENTORY]:GetItemsTotalAmount(inv, item) or 0
end

---codem reads players by source and standalone inventories by stash id, through separate exports.
---@param inv BridgeLib.Inventory.Id
---@param item string
---@return table[]
local function slotsHolding(inv, item)
	local found = type(inv) == "number" and exports[RESOURCE_INVENTORY]:GetItemsByName(inv, item)
		or exports[RESOURCE_INVENTORY]:GetStashItems(inv)

	if type(found) ~= "table" then
		return {}
	end

	if found.name then
		return { found }
	end

	local wanted = tostring(item):lower()
	local slots = {}

	for _, entry in pairs(found) do
		if entry and entry.name and tostring(entry.name):lower() == wanted then
			slots[#slots + 1] = entry
		end
	end

	return slots
end

---@type BridgeLib.Inventory.Server
local provider = {
	HasItem = function(inv, item, count)
		return itemCount(inv, item) >= (count or 1)
	end,

	GetItemCount = itemCount,

	AddItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:AddItem(inv, item, count or 1, slot or false, metadata or false)
	end,

	RemoveItem = function(inv, item, count, metadata, slot)
		return exports[RESOURCE_INVENTORY]:RemoveItem(inv, item, count or 1, slot or false)
	end,

	---codem-inventory exposes no capacity check, so it accepts whatever it is handed.
	CanAddItem = function()
		return true
	end,

	CanCarryItem = function()
		return true
	end,

	GetItemData = function(item)
		local items = exports[RESOURCE_INVENTORY]:GetItemList()
		return items and (items[item] or items[tostring(item):lower()])
	end,

	---codem writes metadata only, so any key but "info" becomes a field inside the slot's metadata.
	SetItemData = function(inv, item, key, value)
		local held = slotsHolding(inv, item)[1]

		if not held then
			return false
		end

		local metadata = held.info or {}

		if key == "info" then
			metadata = value
		else
			metadata[key] = value
		end

		exports[RESOURCE_INVENTORY]:SetItemMetadata(inv, tonumber(held.slot), metadata)

		return true
	end,

	GetItemSlots = function(inv, item)
		local slots = {}

		for _, entry in pairs(slotsHolding(inv, item)) do
			slots[#slots + 1] = {
				slot = tonumber(entry.slot),
				count = entry.amount or 1,
				metadata = entry.info,
			}
		end

		return slots
	end,

	GetInventory = function(id)
		return exports[RESOURCE_INVENTORY]:GetStashItems(id)
	end,

	---codem reads whole inventories by stash id only, so a player source returns nothing.
	GetInventoryItems = function(id)
		return exports[RESOURCE_INVENTORY]:GetStashItems(id) or {}
	end,

	ClearInventory = function(inv)
		exports[RESOURCE_INVENTORY]:ClearInventory(inv)
		return true
	end,
}

return provider
