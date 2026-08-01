---@type BridgeLib.VehicleKeys.Client
local provider = {
	GiveVehicleKeys = function(_, plate)
		TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
	end,
}

return provider
