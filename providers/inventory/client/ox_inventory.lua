local RESOURCE_INVENTORY = "ox_inventory"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Inventory.Client
return function(bridge)
	return {
		HasItem = function(name, amount)
			local hasItemMaybeTable = exports[RESOURCE_INVENTORY]:Search("count", name)
			if type(hasItemMaybeTable) == "table" then
				bridge:Fatal("ox_inventory returned a table for HasItem, which is not supported.")
				return false
			else
				return hasItemMaybeTable >= (amount or 1)
			end
		end,
	}
end
