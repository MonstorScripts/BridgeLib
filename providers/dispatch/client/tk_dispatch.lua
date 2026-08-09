local RESOURCE_DISPATCH = "tk_dispatch"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			exports[RESOURCE_DISPATCH]:addCall({
				title = data.title,
				code = data.code,
				message = data.message,
				coords = info.coords,
				jobs = data.jobs or { "police" },
				blip = {
					sprite = data.sprite or 431,
					scale = data.scale or 1.2,
					colour = data.colour or 3,
					text = data.blipText or data.title,
				},
				playSound = true,
			})
		end,
	}
end
