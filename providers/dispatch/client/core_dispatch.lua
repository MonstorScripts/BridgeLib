---Milliseconds core_dispatch keeps a call on screen for.
local CALL_LENGTH = 10000

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Dispatch.Client
return function(bridge)
	return {
		SendPoliceAlert = function(data)
			local info = bridge.exports.GetAlertPlayerInfo()
			TriggerServerEvent(
				"core_dispatch:addCall",
				data.code,
				data.description or data.title,
				{ { icon = "fa-info-circle", info = data.message } },
				{ info.coords.x, info.coords.y, info.coords.z },
				data.jobs or { "police" },
				CALL_LENGTH,
				data.sprite or 431,
				data.colour or 3
			)
		end,
	}
end
