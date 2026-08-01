local RESOURCE_FUEL = "LegacyFuel"

---@type BridgeLib.Fuel.Client
local provider = {
	SetVehicleFuel = function(vehicle, level)
		return exports[RESOURCE_FUEL]:SetFuel(vehicle, level)
	end,
}

return provider
