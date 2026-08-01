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
	},
	schema = schema,
}
