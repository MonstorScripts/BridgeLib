---@class BridgeLib.VehicleKeys.Client
local schema = {
	---@param vehicle number
	---@param plate string
	GiveVehicleKeys = function() end,
}

---@type BridgeLib.Module
return {
	name = "vehiclekeys",
	context = "client",
	providers = {
		"qb-vehiclekeys",
	},
	schema = schema,
}
