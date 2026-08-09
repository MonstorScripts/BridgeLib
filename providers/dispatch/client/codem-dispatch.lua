local RESOURCE_DISPATCH = "codem-dispatch"

---@type BridgeLib.Dispatch.Client
local provider = {
	SendPoliceAlert = function(data)
		exports[RESOURCE_DISPATCH]:CustomDispatch({
			type = "Illegal",
			header = data.title,
			text = data.message,
			code = data.code,
		})
	end,
}

return provider
