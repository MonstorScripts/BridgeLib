---@type BridgeLib.Doorlock.Server
local provider = {
	SetDoorState = function(data)
		TriggerEvent("qb-doorlock:server:updateState", data.id, data.locked, false, false, data.enableSounds, false, false)
	end,
}

return provider
