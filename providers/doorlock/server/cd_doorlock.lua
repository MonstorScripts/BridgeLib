---@type BridgeLib.Doorlock.Server
local provider = {
	SetDoorState = function(data)
		TriggerClientEvent("cd_doorlock:SetDoorState_name", data.src or -1, data.locked, data.id, data.location)
	end,
}

return provider
