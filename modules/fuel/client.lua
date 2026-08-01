---Optional module: with no fuel resource running, the stub is a no-op.
---@class BridgeLib.Fuel.Client
local schema = {
	---@param vehicle number
	---@param level number Fuel percentage, 0-100.
	SetVehicleFuel = function(vehicle, level) end,
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
