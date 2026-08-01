---@class BridgeLib.Fuel.Client
local schema = {
	---@param vehicle number
	---@param level number
	SetVehicleFuel = function() end,
}

---@type BridgeLib.Module
return {
	name = "fuel",
	context = "client",
	providers = {
		"rcore_fuel",
		"LegacyFuel",
	},
	schema = schema,
}
