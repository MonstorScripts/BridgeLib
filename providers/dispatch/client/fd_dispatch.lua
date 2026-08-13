---Milliseconds fd_dispatch keeps the blip on the map for.
local BLIP_TIME = 15 * 1000

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("fd_dispatch:events:addAlert", {
				title = data.title,
				description = data.description or data.message,
				blip = {
					sprite = data.sprite or 52,
					color = data.colour or 1,
					scale = data.scale or 1.0,
					time = BLIP_TIME,
				},
				groups = data.jobs or { "police" },
				priority = data.priority or 1,
				code = data.code or "10-99",
				location = info.street,
				metadata = { { content = info.sex, icon = "fas fa-user" } },
				isEmergency = false,
			})
		end,
	}
end
