local RESOURCE_PHONE = "npwd"

---@type BridgeLib.Phone.Client
local provider = {
	---npwd stores and passes numbers raw, formatting them only in its own interface.
	FormatNumber = function(number)
		return tostring(number)
	end,

	CreateCall = function(number)
		return exports[RESOURCE_PHONE]:startPhoneCall(tostring(number), false)
	end,
}

return provider
