---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("SendAlert:police", {
				coords = info.coords,
				title = data.message,
				type = data.code,
				message = data.description or data.title,
				job = (data.jobs or { "police" })[1],
			})
		end,
	}
end
