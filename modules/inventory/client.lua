---@class BridgeLib.Inventory.Client
local schema = {
	---@param name string
	---@param amount number? Defaults to 1.
	---@return boolean
	HasItem = function(name, amount) end,

	---NUI path the inventory serves its item images from, for resources that render their own slots.
	---@return string? path nil from an inventory whose image layout the library does not know.
	GetImagePath = function() end,

	---@param inventoryType string Inventory kind, e.g. "stash" or "shop".
	---@param data table Identity of the inventory, in the shape the inventory resource expects.
	---@return boolean opened Falsy from an inventory that exposes no client side open.
	OpenInventory = function(inventoryType, data) end,
}

---@type BridgeLib.Module
return {
	name = "inventory",
	context = "client",
	providers = {
		"qb-inventory",
		"ox_inventory",
		"codem-inventory",
		"qs-inventory-pro",
		"qs-inventory",
		"origen_inventory",
		"lj-inventory",
		"ps-inventory",
		"tgiann-inventory",
		"jaksam_inventory",
		"core_inventory",
		"one_inventory",
	},
	required = {
		"HasItem",
	},
	schema = schema,
}
