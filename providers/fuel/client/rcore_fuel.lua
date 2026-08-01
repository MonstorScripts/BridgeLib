local RESOURCE_FUEL = "rcore_fuel"

---@return BridgeLib.Fuel.Client
return {
	SetVehicleFuel = function(vehicle, level)
		return exports[RESOURCE_FUEL]:SetVehicleFuel(vehicle, level)
	end,
}
