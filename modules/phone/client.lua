---@class BridgeLib.Phone.Client
local schema = {
	---@param number string|number
	---@return string
	FormatNumber = function(number)
		return tostring(number)
	end,

	---@param number string|number
	CreateCall = function() end,
}

---@type BridgeLib.Module
return {
	name = "phone",
	context = "client",
	providers = {
		"lb-phone",
	},
	schema = schema,
}
