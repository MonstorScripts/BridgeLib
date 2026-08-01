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
}

return provider
