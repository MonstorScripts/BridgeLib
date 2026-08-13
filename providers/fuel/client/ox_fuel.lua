---ox_fuel keeps the level in a state bag rather than behind an export, and only the entity's owner
---may write it.
---@type BridgeLib.Fuel.Client
local provider = {
	SetVehicleFuel = function(vehicle, level)
		Entity(vehicle).state.fuel = level
	end,
}

return provider
