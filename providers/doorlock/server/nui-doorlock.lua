---@type BridgeLib.Doorlock.Server
local provider = {
	SetDoorState = function(data)
		TriggerEvent("nui_doorlock:server:updateState", data.id, data.locked, false, false, data.enableSounds)
	end,
}

return provider
