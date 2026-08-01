---@class BridgeLib.Inventory.Server
local schema = {
	HasItem = function(...) end,
	SetItemData = function(...) end,
	CreateInventory = function(...) end,
	GetInventory = function(...) end,
	OpenInventory = function(...) end,
	AddItem = function(...) end,
	RemoveItem = function(...) end,
	CanAddItem = function(...) end,
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
