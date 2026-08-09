---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("Opto_dispatch:Server:SendAlert", data.jobs or { "police" }, data.title, data.message, info.coords, false, GetPlayerServerId(PlayerId()))
		end,
	}
end
