---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			local code = data.code and (data.code .. " - " .. data.title) or data.title
			TriggerServerEvent("rcore_dispatch:server:sendAlert", {
				code = code,
				default_priority = data.priority or "low",
				coords = info.coords,
				job = data.jobs or { "police" },
				text = data.message,
				type = "alerts",
				blip_time = 180,
				blip = {
					sprite = data.sprite or 431,
					colour = data.colour or 3,
					scale = data.scale or 1.2,
					text = data.blipText or code,
					flashes = false,
				},
			})
		end,
	}
end
