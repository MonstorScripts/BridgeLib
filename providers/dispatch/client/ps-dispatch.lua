---ps-dispatch groups its recipients by job type rather than by job name.
local DEFAULT_TYPES = { "leo" }

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("ps-dispatch:server:notify", {
				message = data.title,
				codeName = data.codeName,
				code = data.code,
				icon = "fas fa-info-circle",
				priority = data.priority or 2,
				coords = info.coords,
				gender = info.sex,
				street = info.street,
				jobs = data.jobs or DEFAULT_TYPES,
			})
		end,
	}
end
