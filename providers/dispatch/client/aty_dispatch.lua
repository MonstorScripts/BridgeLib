---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("aty_dispatch:server:customDispatch", data.title, data.code, info.street, info.coords, nil, nil, nil, nil, data.sprite or 431, data.jobs or { "police" })
		end,
	}
end
