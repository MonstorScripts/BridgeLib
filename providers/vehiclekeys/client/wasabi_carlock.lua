local RESOURCE_VEHICLEKEYS = "wasabi_carlock"

---@type BridgeLib.VehicleKeys.Client
local provider = {
	GiveVehicleKeys = function(_, plate)
		return exports[RESOURCE_VEHICLEKEYS]:GiveKey(plate)
	end,
}

return provider
