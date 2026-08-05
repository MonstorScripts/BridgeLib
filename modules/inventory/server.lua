---A player source, or the identifier of a standalone inventory such as a stash or shop.
---@alias BridgeLib.Inventory.Id string|number

---Definition for a standalone inventory. Providers read the fields they support and ignore the rest.
---@class BridgeLib.Inventory.Definition
---@field name string?
---@field label string?
---@field slots number?
---@field maxweight number?
---@field coords vector3|table? Position, for inventories that are tied to a location.
---@field items table? Starting contents, in the shape the inventory resource expects.

---One occupied slot, normalised across inventory resources.
---@class BridgeLib.ItemSlot
---@field slot number
---@field count number
---@field metadata table? Per-slot data: ox_inventory's metadata, qb-inventory's info.

---Every provider forwards its arguments verbatim, so the trailing options each one accepts differ.
---Only the leading arguments named here are portable.
---@class BridgeLib.Inventory.Server
local schema = {
	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param count number? Defaults to 1.
	---@return boolean
	HasItem = function(inv, item, count) end,

	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param key string Metadata field to write, conventionally "info".
	---@param value any
	SetItemData = function(inv, item, key, value) end,

	---@param id BridgeLib.Inventory.Id
	---@param data BridgeLib.Inventory.Definition
	CreateInventory = function(id, data) end,

	---@param id BridgeLib.Inventory.Id
	---@return table? inventory nil when no inventory exists under that id.
	GetInventory = function(id) end,

	---@param src number
	---@param id BridgeLib.Inventory.Id
	OpenInventory = function(src, id) end,

	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param count number? Defaults to 1.
	---@return boolean
	AddItem = function(inv, item, count) end,

	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param count number? Defaults to 1.
	---@return boolean
	RemoveItem = function(inv, item, count) end,

	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param count number? Defaults to 1.
	---@return boolean
	CanAddItem = function(inv, item, count) end,

	---Total of an item held, across every slot.
	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@return number count 0 when none is held.
	GetItemCount = function(inv, item) end,

	---Whether the weight and slot budget leaves room for the item.
	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@param count number? Defaults to 1.
	---@return boolean
	CanCarryItem = function(inv, item, count) end,

	---Static definition of an item, independent of any inventory.
	---@param item string
	---@return table? data nil when the item is unknown.
	GetItemData = function(item) end,

	---Declares a stash, so it exists before anyone opens it.
	---@param stashId string
	---@param label string
	---@param slots number
	---@param maxWeight number
	---@param owner string? Identifier the stash is private to, or nil for a shared stash.
	---@param groups table? Jobs and minimum grades allowed in, as `{ [job] = grade }`.
	RegisterStash = function(stashId, label, slots, maxWeight, owner, groups) end,

	---@param id BridgeLib.Inventory.Id
	---@return table items Empty when the inventory does not exist.
	GetInventoryItems = function(id) end,

	---Every slot holding the named item, so callers can read per-slot metadata.
	---@param inv BridgeLib.Inventory.Id
	---@param item string
	---@return BridgeLib.ItemSlot[]
	GetItemSlots = function(inv, item) end,

	---Removes every item from an inventory, leaving the inventory itself in place.
	---@param inv BridgeLib.Inventory.Id
	---@return boolean
	ClearInventory = function(inv) end,
}

---@type BridgeLib.Module
return {
	name = "inventory",
	context = "server",
	providers = {
		"qb-inventory",
		"ox_inventory",
	},
	required = {
		"HasItem",
		"SetItemData",
		"CreateInventory",
		"GetInventory",
		"OpenInventory",
		"AddItem",
		"RemoveItem",
		"CanAddItem",
		"GetItemCount",
		"CanCarryItem",
		"GetItemData",
		"RegisterStash",
		"GetInventoryItems",
		"GetItemSlots",
		"ClearInventory",
	},
	schema = schema,
}
