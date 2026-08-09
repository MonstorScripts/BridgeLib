local RESOURCE_FUEL = "cdn-fuel"

---@type BridgeLib.Fuel.Client
local provider = {
	SetVehicleFuel = function(vehicle, level)
		return exports[RESOURCE_FUEL]:SetFuel(vehicle, level)
	end,
}

return provider
