local RESOURCE_CORE = "qb-core"

---Totals every slot, unlike qb-inventory's HasItem, which reads a split stack as not enough.
---@param name string
---@return number
local function countItem(name)
	local QBCore = exports[RESOURCE_CORE]:GetCoreObject()
	local playerData = QBCore.Functions.GetPlayerData()
	local items = playerData and playerData.items

	if type(items) ~= "table" then
		return 0
	end

	local wanted = tostring(name):lower()
	local total = 0

	for _, slot in pairs(items) do
		if slot and slot.name and tostring(slot.name):lower() == wanted then
			total = total + (slot.amount or 0)
		end
	end

	return total
end

---@type BridgeLib.Inventory.Client
local provider = {
	HasItem = function(name, amount)
		return countItem(name) >= (amount or 1)
	end,

	GetImagePath = function()
		return "qb-inventory/html/images"
	end,

	OpenInventory = function(inventoryType, data)
		TriggerServerEvent("inventory:server:OpenInventory", inventoryType, data and data.id, data)
		return true
	end,
}

return provider
