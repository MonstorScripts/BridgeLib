---Optional module: with no phone resource running, `FormatNumber` falls back to `tostring` and
---`CreateCall` is a no-op.
---@class BridgeLib.Phone.Client
local schema = {
	---@param number string|number
	---@return string
	FormatNumber = function(number)
		return tostring(number)
	end,

	---Places a call from the local player.
	---@param number string|number
	CreateCall = function(number) end,
}

---@type BridgeLib.Module
return {
	name = "phone",
	context = "client",
	providers = {
		"lb-phone",
		"npwd",
	},
	schema = schema,
}
