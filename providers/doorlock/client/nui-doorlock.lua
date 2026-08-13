---@type BridgeLib.Doorlock.Client
local provider = {
	SetDoorState = function(data)
		TriggerServerEvent("nui_doorlock:server:updateState", data.id, data.locked, false, false, data.enableSounds)
	end,
}

return provider
