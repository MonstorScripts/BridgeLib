local RESOURCE_VEHICLEKEYS = "qs-vehiclekeys"

---@type BridgeLib.VehicleKeys.Client
local provider = {
	GiveVehicleKeys = function(vehicle, plate)
		local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
		return exports[RESOURCE_VEHICLEKEYS]:GiveKeys(plate, model, true)
	end,
}

return provider
