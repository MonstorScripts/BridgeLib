---Optional module: with no vehicle key resource running, the stub is a no-op.
---@class BridgeLib.VehicleKeys.Client
local schema = {
	---@param vehicle number Entity handle. Providers that key off the plate alone ignore it.
	---@param plate string
	GiveVehicleKeys = function(vehicle, plate) end,
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
