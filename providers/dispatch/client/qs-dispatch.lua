---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent("qs-dispatch:server:CreateDispatchCall", {
				job = data.jobs or { "police" },
				callLocation = info.coords,
				callCode = { code = data.code, snippet = data.description or data.title },
				message = data.message,
				flashes = false,
				blip = {
					sprite = data.sprite or 431,
					scale = data.scale or 1.2,
					colour = data.colour or 3,
					flashes = true,
					text = data.blipText or data.title,
					time = 6 * 60 * 1000,
				},
			})
		end,
	}
end
