---@type BridgeLib.VehicleKeys.Client
local provider = {
	GiveVehicleKeys = function(_, plate)
		TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", plate)
	end,
}

return provider
