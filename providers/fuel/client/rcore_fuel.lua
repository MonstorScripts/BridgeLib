local RESOURCE_FUEL = "rcore_fuel"

---@type BridgeLib.Fuel.Client
local provider = {
	SetVehicleFuel = function(vehicle, level)
		return exports[RESOURCE_FUEL]:SetVehicleFuel(vehicle, level)
	end,
}

return provider
