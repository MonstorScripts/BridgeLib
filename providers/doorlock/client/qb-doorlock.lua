---@type BridgeLib.Doorlock.Client
local provider = {
	SetDoorState = function(data)
		TriggerServerEvent("qb-doorlock:server:updateState", data.id, data.locked, false, false, data.enableSounds, false, false)
	end,
}

return provider
