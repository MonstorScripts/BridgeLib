local RESOURCE_PHONE = "lb-phone"

---@return BridgeLib.Phone.Client
return {
	FormatNumber = function(number)
		return exports[RESOURCE_PHONE]:FormatNumber(number)
	end,

	CreateCall = function(number)
		return exports[RESOURCE_PHONE]:CreateCall({ number = tostring(number) })
	end,
}
