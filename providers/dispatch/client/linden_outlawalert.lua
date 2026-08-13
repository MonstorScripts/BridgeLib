---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("wf-alerts:svNotify", {
				dispatchData = {
					displayCode = data.code,
					description = data.description or data.title,
					isImportant = 0,
					recipientList = data.jobs or { "police" },
					length = "10000",
					infoM = "fa-info-circle",
					info = data.message,
				},
				caller = "Citizen",
				coords = info.coords,
			})
		end,
	}
end
