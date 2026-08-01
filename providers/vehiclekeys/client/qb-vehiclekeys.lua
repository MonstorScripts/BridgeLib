---@return BridgeLib.VehicleKeys.Client
return {
	GiveVehicleKeys = function(_, plate)
		TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
	end,
}
