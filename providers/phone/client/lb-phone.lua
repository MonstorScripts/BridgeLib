local RESOURCE_PHONE = "lb-phone"

---@type BridgeLib.Phone.Client
local provider = {
	FormatNumber = function(number)
		return exports[RESOURCE_PHONE]:FormatNumber(number)
	end,

	CreateCall = function(number)
		return exports[RESOURCE_PHONE]:CreateCall({ number = tostring(number) })
	end,
}

return provider
