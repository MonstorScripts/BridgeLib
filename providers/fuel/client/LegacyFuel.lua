local RESOURCE_FUEL = "LegacyFuel"

---@return BridgeLib.Fuel.Client
return {
	SetVehicleFuel = function(vehicle, level)
		return exports[RESOURCE_FUEL]:SetFuel(vehicle, level)
	end,
}
